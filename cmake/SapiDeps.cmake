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

# Checks whether a given target exists. Aborts the CMake run otherwise.
function(sapi_check_target target)
  if(NOT TARGET ${target})
    message(FATAL_ERROR "Compiling Sandboxed API requires TARGET ${target} \
in your project")
  endif()
endfunction()

# Use static libraries
set(_sapi_saved_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
if (SAPI_ENABLE_SHARED_LIBS)
  set(SAPI_LIB_TYPE SHARED)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
  # Imply linking with system-wide libs
  set(SAPI_LIBCAP_PROVIDER "package" CACHE BOOL "" FORCE)
  set(SAPI_LIBFFI_PROVIDER "package" CACHE BOOL "" FORCE)
  set(SAPI_PROTOBUF_PROVIDER "package" CACHE BOOL "" FORCE)
  set(SAPI_ZLIB_PROVIDER "package" CACHE BOOL "" FORCE)
  add_compile_definitions(SAPI_LIB_IS_SHARED=1)
else()
  set(SAPI_LIB_TYPE STATIC)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

if(SAPI_ENABLE_TESTS)
  include(cmake/googletest.cmake)
  include(cmake/benchmark.cmake)
endif()

include(cmake/abseil-cpp.cmake)
include(cmake/libcap.cmake)
include(cmake/libffi.cmake)
include(cmake/libunwind.cmake)
include(cmake/gflags.cmake)
include(cmake/glog.cmake)
include(cmake/protobuf.cmake)

if(SAPI_ENABLE_EXAMPLES)
  include(cmake/zlib.cmake)
endif()

find_package(Threads REQUIRED)

if(NOT SAPI_ENABLE_GENERATOR)
  # Find Python 3 and add its location to the cache so that its available in
  # the add_sapi_library() macro in embedding projects.
  find_package(Python3 COMPONENTS Interpreter REQUIRED)
  set(SAPI_PYTHON3_EXECUTABLE "${Python3_EXECUTABLE}" CACHE INTERNAL "" FORCE)
endif()

# Undo global change
set(CMAKE_FIND_LIBRARY_SUFFIXES ${_sapi_saved_CMAKE_FIND_LIBRARY_SUFFIXES})
