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

# This option should be only enabled for embedded and resource-constrained
# environments
option(SAPI_ENABLE_SHARED_LIBS
       "Build SAPI shared libs (implies 'package' providers)" OFF)

# The options below determine whether CMake should download the libraries that
# Sandboxed API depends on at configure time.
# The CMake script SapiDeps.cmake checks for the presence of certain build
# targets to determine whether a library can be used. Setting the options
# below enables embedding projects to selectively override/replace these
# dependencies. This is useful for cases where embedding projects already
# depend on some of these libraries (e.g. Abseil, Googletest).

# Providers for third-party dependencies (SAPI_*_PROVIDER properties):
# - "fetch": Build the dependency using sources from FetchContent()
#   To to selectively override package sources, set FETCHCONTENT_SOURCE_DIR_*
#   on the command-line. Use set FETCHCONTENT_FULLY_DISCONNECTED=ON to perform
#   offline builds.
# - "superbuild": Build the dependency using sources from ExternalProject_add()
# - "package": Use CMake's find_package() functionality to locate a
#   pre-installed dependency
if(SAPI_ENABLE_SHARED_LIBS)
  set(_sapi_default_provider "package")
elseif(SAPI_HAVE_FETCHCONTENT)
  set(_sapi_default_provider "fetch")
else() # Use ExternalProject_Add() instead
  set(_sapi_default_provider "superbuild")
endif()

set(SAPI_ABSL_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of absl library")
set(SAPI_GOOGLETEST_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of googletest library")
set(SAPI_BENCHMARK_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of benchmark library")
set(SAPI_GFLAGS_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of gflags library")
set(SAPI_GLOG_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of glog library")
set(SAPI_PROTOBUF_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of protobuf library")
set(SAPI_LIBUNWIND_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of libunwind library")
set(SAPI_LIBCAP_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of libcap library")
set(SAPI_LIBFFI_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of libffi library")
set(SAPI_ZLIB_PROVIDER "${_sapi_default_provider}" CACHE
    STRING "Provider of zlib library (used with SAPI_ENABLE_EXAMPLES)")

# Options for building examples
option(SAPI_ENABLE_EXAMPLES "Build example code" ON)

option(SAPI_ENABLE_TESTS "Build unit tests" ON)
option(SAPI_ENABLE_GENERATOR "Build Clang based code generator from source" OFF)

option(SAPI_HARDENED_SOURCE "Build with hardening compiler options" OFF)

option(SAPI_FORCE_COLOR_OUTPUT "Force colored compiler diagnostics when using Ninja" ON)

# Set choices for the providers. These are displayed in the CMake GUI.
foreach(_sapi_lib IN ITEMS ABSL
                           BENCHMARK
                           GFLAGS
                           GLOG
                           GOOGLETEST
                           LIBCAP
                           LIBFFI
                           LIBUNWIND
                           PROTOBUF
                           ZLIB)
  set_property(CACHE SAPI_${_sapi_lib}_PROVIDER PROPERTY
               STRINGS "fetch" "superbuild" "package")
endforeach()

