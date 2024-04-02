// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// The sandbox2::Comms class uses AF_UNIX sockets (man 7 unix) to send pieces of
// data between processes. It uses the TLV encoding and provides some useful
// helpers.
//
// The endianess is platform-specific, but as it can be used over abstract
// sockets only, that's not a problem. Is some poor soul decides to rewrite it
// to work over AF_INET(6), the endianess will have to be dealt with (somehow).

#ifndef SANDBOXED_API_SANDBOX2_COMMS_H_
#define SANDBOXED_API_SANDBOX2_COMMS_H_

#include <sys/un.h>
#include <unistd.h>

#include <cstddef>
#include <cstdint>
#include <limits>
#include <memory>
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include "absl/base/attributes.h"
#include "absl/status/status.h"
#include "absl/status/statusor.h"
#include "absl/strings/string_view.h"
#include "google/protobuf/message_lite.h"
#include "sandboxed_api/util/fileops.h"

namespace proto2 {
class Message;
}  // namespace proto2

namespace sandbox2 {

class Client;
class ListeningComms;

class Comms {
 public:
  struct DefaultConnectionTag {};

  // Default tags, custom tags should be <0x80000000.
  static constexpr uint32_t kTagBool = 0x80000001;
  static constexpr uint32_t kTagInt8 = 0x80000002;
  static constexpr uint32_t kTagUint8 = 0x80000003;
  static constexpr uint32_t kTagInt16 = 0x80000004;
  static constexpr uint32_t kTagUint16 = 0x80000005;
  static constexpr uint32_t kTagInt32 = 0x80000006;
  static constexpr uint32_t kTagUint32 = 0x80000007;
  static constexpr uint32_t kTagInt64 = 0x80000008;
  static constexpr uint32_t kTagUint64 = 0x80000009;
  static constexpr uint32_t kTagString = 0x80000100;
  static constexpr uint32_t kTagBytes = 0x80000101;
  static constexpr uint32_t kTagProto2 = 0x80000102;
  static constexpr uint32_t kTagFd = 0X80000201;

  // Any payload size above this limit will LOG(WARNING).
  static constexpr size_t kWarnMsgSize = (256ULL << 20);

  // A high file descriptor number to be used with certain fork server request
  // modes to map the target executable. This is considered to be an
  // implementation detail.
  // This number is chosen so that low FD numbers are not interfered with.
  static constexpr int kSandbox2TargetExecFD = 1022;

  // Sandbox2-specific convention where FD=1023 is always passed to the
  // sandboxed process as a communication channel (encapsulated in the
  // sandbox2::Comms object at the server-side).
  static constexpr int kSandbox2ClientCommsFD = 1023;

  // Within SendTLV, a stack-allocated buffer is created to contiguously store
  // the TLV in order to perform one call to Send.
  // If the TLV is larger than the size below, two calls to Send are
  // used.
  static constexpr size_t kSendTLVTempBufferSize = 1024;

  static constexpr DefaultConnectionTag kDefaultConnection = {};

  static constexpr const char* kSandbox2CommsFDEnvVar = "SANDBOX2_COMMS_FD";

  static absl::StatusOr<Comms> Connect(const std::string& socket_name,
                                       bool abstract_uds = true);

  Comms(Comms&& other) { *this = std::move(other); }
  Comms& operator=(Comms&& other) {
    if (this != &other) {
      using std::swap;
      swap(*this, other);
      other.Terminate();
    }
    return *this;
  }

  Comms(const Comms&) = delete;
  Comms& operator=(const Comms&) = delete;

  // Instantiates a pre-connected object.
  // Takes ownership over fd, which will be closed on object's destruction.
  explicit Comms(int fd, absl::string_view name = "");

  // Instantiates a pre-connected object using the default connection params.
  explicit Comms(DefaultConnectionTag);

  ~Comms();

  // Terminates all underlying file descriptors, and sets the status of the
  // Comms object to TERMINATED.
  void Terminate();

  // Returns the already connected FD.
  int GetConnectionFD() const;

  bool IsConnected() const { return state_ == State::kConnected; }
  bool IsTerminated() const { return state_ == State::kTerminated; }

  // Returns the maximum size of a message that can be send over the comms
  // channel.
  // Note: The actual size is "unlimited", although the Buffer API is more
  // efficient for large transfers. There is an arbitrary limit to ~2GiB to
  // avoid protobuf serialization issues.
  size_t GetMaxMsgSize() const { return std::numeric_limits<int32_t>::max(); }

  bool SendTLV(uint32_t tag, size_t length, const void* value);
  // Receive a TLV structure, the memory for the value will be allocated
  // by std::vector.
  bool RecvTLV(uint32_t* tag, std::vector<uint8_t>* value);
  // Receive a TLV structure, the memory for the value will be allocated
  // by std::string.
  bool RecvTLV(uint32_t* tag, std::string* value);
  // Receives a TLV value into a specified buffer without allocating memory.
  bool RecvTLV(uint32_t* tag, size_t* length, void* buffer, size_t buffer_size);

  // Sends/receives various types of data.
  bool RecvUint8(uint8_t* v) { return RecvIntGeneric(v, kTagUint8); }
  bool SendUint8(uint8_t v) { return SendGeneric(v, kTagUint8); }
  bool RecvInt8(int8_t* v) { return RecvIntGeneric(v, kTagInt8); }
  bool SendInt8(int8_t v) { return SendGeneric(v, kTagInt8); }
  bool RecvUint16(uint16_t* v) { return RecvIntGeneric(v, kTagUint16); }
  bool SendUint16(uint16_t v) { return SendGeneric(v, kTagUint16); }
  bool RecvInt16(int16_t* v) { return RecvIntGeneric(v, kTagInt16); }
  bool SendInt16(int16_t v) { return SendGeneric(v, kTagInt16); }
  bool RecvUint32(uint32_t* v) { return RecvIntGeneric(v, kTagUint32); }
  bool SendUint32(uint32_t v) { return SendGeneric(v, kTagUint32); }
  bool RecvInt32(int32_t* v) { return RecvIntGeneric(v, kTagInt32); }
  bool SendInt32(int32_t v) { return SendGeneric(v, kTagInt32); }
  bool RecvUint64(uint64_t* v) { return RecvIntGeneric(v, kTagUint64); }
  bool SendUint64(uint64_t v) { return SendGeneric(v, kTagUint64); }
  bool RecvInt64(int64_t* v) { return RecvIntGeneric(v, kTagInt64); }
  bool SendInt64(int64_t v) { return SendGeneric(v, kTagInt64); }
  bool RecvBool(bool* v) { return RecvIntGeneric(v, kTagBool); }
  bool SendBool(bool v) { return SendGeneric(v, kTagBool); }
  bool RecvString(std::string* v);
  bool SendString(const std::string& v);

  bool RecvBytes(std::vector<uint8_t>* buffer);
  bool SendBytes(const uint8_t* v, size_t len);
  bool SendBytes(const std::vector<uint8_t>& buffer);

  // Receives remote process credentials.
  bool RecvCreds(pid_t* pid, uid_t* uid, gid_t* gid);

  // Receives/sends file descriptors.
  bool RecvFD(int* fd);
  bool SendFD(int fd);

  // Receives/sends protobufs.
  bool RecvProtoBuf(google::protobuf::MessageLite* message);
  bool SendProtoBuf(const google::protobuf::MessageLite& message);

  // Receives/sends Status objects.
  bool RecvStatus(absl::Status* status);
  bool SendStatus(const absl::Status& status);

  void Swap(Comms& other) {
    if (this == &other) {
      return;
    }
    using std::swap;
    swap(name_, other.name_);
    swap(abstract_uds_, other.abstract_uds_);
    swap(raw_comms_, other.raw_comms_);
    swap(state_, other.state_);
    swap(listening_comms_, other.listening_comms_);
  }

  friend void swap(Comms& x, Comms& y) { return x.Swap(y); }

 protected:
  class RawComms {
   public:
    virtual ~RawComms() {};
    virtual int GetConnectionFD() const = 0;
    virtual void MoveToAnotherFd() = 0;
    virtual ssize_t RawSend(const void* data, size_t len) = 0;
    virtual ssize_t RawRecv(void* data, size_t len) = 0;
    virtual ssize_t RawSendMsg(const void* msg) = 0;
    virtual ssize_t RawRecvMsg(void* msg) = 0;
  };

  class RawCommsFdImpl : public RawComms {
   public:
    RawCommsFdImpl(int fd) : connection_fd_(fd) {}
    int GetConnectionFD() const override;
    void MoveToAnotherFd() override;
    ssize_t RawSend(const void* data, size_t len) override;
    ssize_t RawRecv(void* data, size_t len) override;
    ssize_t RawSendMsg(const void* msg) override;
    ssize_t RawRecvMsg(void* msg) override;

   private:
    sapi::file_util::fileops::FDCloser connection_fd_;
  };

 private:
  friend class Client;

  // State of the channel
  enum class State {
    kUnconnected = 0,
    kConnected,
    kTerminated,
  };

  // Connection parameters.
  std::string name_;
  bool abstract_uds_ = true;
  std::variant<std::unique_ptr<RawComms>, RawCommsFdImpl> raw_comms_;

  std::unique_ptr<ListeningComms> listening_comms_;

  // State of the channel (enum), socket will have to be connected later on.
  State state_ = State::kUnconnected;

  // Special struct for passing credentials or FDs.
  // When passing credentials or FDs, it inlines the value. This is important as
  // the data is transmitted using sendmsg/recvmsg instead of send/recv.
  // It is also used when sending/receiving through SendTLV/RecvTLV to reduce
  // writes/reads, although the value is written/read separately.
  struct ABSL_ATTRIBUTE_PACKED InternalTLV {
    uint32_t tag;
    size_t len;
  };

  Comms(std::unique_ptr<RawComms> raw_comms)
      : raw_comms_(std::move(raw_comms)) {
    state_ = State::kConnected;
  }

  RawComms* GetRawComms() {
    RawComms* raw_comms = std::get_if<RawCommsFdImpl>(&raw_comms_);
    if (!raw_comms) {
      raw_comms = std::get<std::unique_ptr<RawComms>>(raw_comms_).get();
    }
    return raw_comms;
  }

  const RawComms* GetRawComms() const {
    const RawComms* raw_comms = std::get_if<RawCommsFdImpl>(&raw_comms_);
    if (!raw_comms) {
      raw_comms = std::get<std::unique_ptr<RawComms>>(raw_comms_).get();
    }
    return raw_comms;
  }

  // Moves the comms fd to an other free file descriptor.
  void MoveToAnotherFd();

  // Support for EINTR and size completion.
  bool Send(const void* data, size_t len);
  bool Recv(void* data, size_t len);

  // Receives tag and length.
  bool RecvTL(uint32_t* tag, size_t* length);

  // T has to be a ContiguousContainer
  template <typename T>
  bool RecvTLVGeneric(uint32_t* tag, T* value);

  // Receives arbitrary integers.
  bool RecvInt(void* buffer, size_t len, uint32_t tag);

  template <typename T>
  bool RecvIntGeneric(T* output, uint32_t tag) {
    return RecvInt(output, sizeof(T), tag);
  }

  template <typename T>
  bool SendGeneric(T value, uint32_t tag) {
    return SendTLV(tag, sizeof(T), &value);
  }
};

class ListeningComms {
 public:
  static absl::StatusOr<ListeningComms> Create(absl::string_view socket_name,
                                               bool abstract_uds = true);

  ListeningComms(ListeningComms&& other) = default;
  ListeningComms& operator=(ListeningComms&& other) = default;
  ~ListeningComms() = default;
  absl::StatusOr<Comms> Accept();

 private:
  ListeningComms(absl::string_view socket_name, bool abstract_uds)
      : socket_name_(socket_name), abstract_uds_(abstract_uds), bind_fd_(-1) {}
  absl::Status Listen();

  std::string socket_name_;
  bool abstract_uds_;
  sapi::file_util::fileops::FDCloser bind_fd_;
};

}  // namespace sandbox2

#endif  // SANDBOXED_API_SANDBOX2_COMMS_H_
