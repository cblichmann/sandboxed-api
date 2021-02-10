# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(SAPI_PROTOBUF_GIT_REPOSITORY
  https://github.com/protocolbuffers/protobuf.git
  CACHE STRING "")
set(SAPI_PROTOBUF_GIT_TAG v3.14.0 CACHE STRING "") # 2020-11-14
set(SAPI_PROTOBUF_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/protobuf-src"
                             CACHE STRING "")
set(SAPI_PROTOBUF_BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/protobuf-build"
                             CACHE STRING "")

if(SAPI_PROTOBUF_PROVIDER STREQUAL "fetch")
  FetchContent_Declare(protobuf
    GIT_REPOSITORY "${SAPI_PROTOBUF_GIT_REPOSITORY}"
    GIT_TAG        "${SAPI_PROTOBUF_GIT_TAG}"
    GIT_SUBMODULES cmake # Workaround for CMake #20579
    SOURCE_SUBDIR  cmake
  )
else()
  set(SAPI_PROTOBUF_POPULATE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/protobuf-populate" CACHE STRING "")
  set(SAPI_PROTOBUF_SOURCE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/protobuf-src" CACHE STRING "")
  set(SAPI_PROTOBUF_BINARY_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/protobuf-build" CACHE STRING "")
  file(WRITE "${SAPI_PROTOBUF_POPULATE_DIR}/CMakeLists.txt" "\
cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(protobuf-populate NONE)
include(ExternalProject)
ExternalProject_Add(protobuf
  GIT_REPOSITORY    \"${SAPI_PROTOBUF_GIT_REPOSITORY}\"
  GIT_TAG           \"${SAPI_PROTOBUF_GIT_TAG}\"
  GIT_SUBMODULES    \"cmake\" # Workaround for CMake #20579
  SOURCE_DIR        \"${SAPI_PROTOBUF_SOURCE_DIR}\"
  BINARY_DIR        \"${SAPI_PROTOBUF_BINARY_DIR}\"
  CONFIGURE_COMMAND \"\"
  BUILD_COMMAND     \"\"
  INSTALL_COMMAND   \"\"
  TEST_COMMAND      \"\"
)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_PROTOBUF_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "CMake step for ${PROJECT_NAME} failed: ${error}")
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} --build .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_PROTOBUF_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "Build step for ${PROJECT_NAME} failed: ${error}")
  endif()
endif()

if(SAPI_PROTOBUF_PROVIDER STREQUAL "package")
  find_package(Protobuf REQUIRED)
else()
  set(protobuf_BUILD_TESTS FALSE CACHE BOOL "")
  set(protobuf_BUILD_SHARED_LIBS FALSE CACHE BOOL "")
  set(protobuf_WITH_ZLIB FALSE CACHE BOOL "")

  if(SAPI_ABSL_PROVIDER STREQUAL "fetch")
    FetchContent_MakeAvailable(protobuf)
  elseif(SAPI_ABSL_PROVIDER STREQUAL "superbuild")
    add_subdirectory("${SAPI_PROTOBUF_SOURCE_DIR}/cmake"
                     "${SAPI_PROTOBUF_BINARY_DIR}" EXCLUDE_FROM_ALL)
  endif()

  get_property(Protobuf_INCLUDE_DIRS TARGET protobuf::libprotobuf
                                     PROPERTY INCLUDE_DIRECTORIES)

  sapi_check_target(protobuf::libprotobuf)
  sapi_check_target(protobuf::protoc)
endif()
