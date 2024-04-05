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

#include "sandboxed_api/util/raw_logging.h"

#include <unistd.h>

#include <cstdlib>
#include <limits>

#include "absl/strings/numbers.h"

#ifndef SAPI_USE_ABSL_RAW_LOG
#include <syscall.h>

#include <cstdarg>
#include <cstdio>
#include <cstring>

#include "absl/base/attributes.h"
#include "absl/base/log_severity.h"

#ifdef __ANDROID__
#include "android/log.h"
#endif

namespace {
static const char kTruncated[] = " ... (message truncated)\n";

// sprintf the format to the buffer, adjusting *buf and *size to reflect the
// consumed bytes, and return whether the message fit without truncation.  If
// truncation occurred, if possible leave room in the buffer for the message
// kTruncated[].
inline static bool VADoRawLog(char** buf, int* size, const char* format,
                              va_list ap) ABSL_PRINTF_ATTRIBUTE(3, 0);
inline static bool VADoRawLog(char** buf, int* size, const char* format,
                              va_list ap) {
  int n = vsnprintf(*buf, *size, format, ap);
  bool result = true;
  if (n < 0 || n > *size) {
    result = false;
    if (static_cast<size_t>(*size) > sizeof(kTruncated)) {
      n = *size - sizeof(kTruncated);  // room for truncation message
    } else {
      n = 0;  // no room for truncation message
    }
  }
  *size -= n;
  *buf += n;
  return result;
}

// CAVEAT: vsnprintf called from *DoRawLog below has some (exotic) code paths
// that invoke malloc() and getenv() that might acquire some locks.

// Helper for RawLog below.
// *DoRawLog writes to *buf of *size and move them past the written portion.
// It returns true iff there was no overflow or error.
bool DoRawLog(char** buf, int* size, const char* format, ...)
    ABSL_PRINTF_ATTRIBUTE(3, 4);
bool DoRawLog(char** buf, int* size, const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  int n = vsnprintf(*buf, *size, format, ap);
  va_end(ap);
  if (n < 0 || n > *size) return false;
  *size -= n;
  *buf += n;
  return true;
}

#ifdef __ANDROID__
android_LogPriority ConvertSeverity(absl::LogSeverity severity) {
  switch (severity) {
    case absl::LogSeverity::kInfo:
      return ANDROID_LOG_INFO;
    case absl::LogSeverity::kWarning:
      return ANDROID_LOG_WARN;
    case absl::LogSeverity::kError:
      return ANDROID_LOG_ERROR;
    case absl::LogSeverity::kFatal:
      return ANDROID_LOG_FATAL;
    default:
      return ANDROID_LOG_INFO;
  }
}
#endif

// Writes the provided buffer directly to stderr, in a safe, low-level manner.
//
// In POSIX this means calling write(), which is async-signal safe and does
// not malloc.  If the platform supports the SYS_write syscall, we invoke that
// directly to side-step any libc interception.
void SafeWriteToStderr(const char* s, size_t len) {
  syscall(SYS_write, STDERR_FILENO, s, len);
}

void RawLogVA(absl::LogSeverity severity, const char* file, int line,
              const char* format, va_list ap) ABSL_PRINTF_ATTRIBUTE(4, 0);
void RawLogVA(absl::LogSeverity severity, const char* file, int line,
              const char* format, va_list ap) {
  char buffer[sapi::raw_logging_internal::kLogBufSize];
  char* buf = buffer;
  int size = sizeof(buffer);

  DoRawLog(&buf, &size, "[%s : %d] RAW: ", file, line);

  bool no_chop = VADoRawLog(&buf, &size, format, ap);
  if (no_chop) {
    DoRawLog(&buf, &size, "\n");
  } else {
    DoRawLog(&buf, &size, "%s", kTruncated);
  }
#ifndef __ANDROID__
  SafeWriteToStderr(buffer, strlen(buffer));
#else
  // Logs to Android's logcat with the TAG SAPI and the log line containing
  // the code location and the log output.
  __android_log_print(ConvertSeverity(severity), "SAPI", "%s", buffer);
#endif

  // Abort the process after logging a FATAL message, even if the output itself
  // was suppressed.
  if (severity == absl::LogSeverity::kFatal) {
    abort();
  }
}

}  // namespace
#endif

namespace sapi::raw_logging_internal {

#ifndef SAPI_USE_ABSL_RAW_LOG
void RawLog(absl::LogSeverity severity, const char* file, int line,
            const char* format, ...) ABSL_PRINTF_ATTRIBUTE(4, 5);
void RawLog(absl::LogSeverity severity, const char* file, int line,
            const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  RawLogVA(severity, file, line, format, ap);
  va_end(ap);
}
#endif

bool VLogIsOn(int verbose_level) {
  static int external_verbose_level = [] {
    int external_verbose_level = std::numeric_limits<int>::min();
    char* env_var = getenv("SAPI_VLOG_LEVEL");
    if (!env_var) {
      return external_verbose_level;
    }
    SAPI_RAW_CHECK(absl::SimpleAtoi(env_var, &external_verbose_level) &&
                       external_verbose_level >= 0,
                   "SAPI_VLOG_LEVEL needs to be an integer >= 0");
    return external_verbose_level;
  }();
  return verbose_level <= external_verbose_level;
}

}  // namespace sapi::raw_logging_internal
