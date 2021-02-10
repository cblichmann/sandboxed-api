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

set(SAPI_BENCHMARK_GIT_REPOSITORY https://github.com/google/benchmark.git
                                  CACHE STRING "")
set(SAPI_BENCHMARK_GIT_TAG 56898e9a92fba537671d5462df9c5ef2ea6a823a
                           CACHE STRING "") # 2020-04-23

if(SAPI_GOOGLETEST_PROVIDER STREQUAL "fetch")
  FetchContent_Declare(benchmark
    GIT_REPOSITORY "${SAPI_BENCHMARK_GIT_REPOSITORY}"
    GIT_TAG        "${SAPI_BENCHMARK_GIT_TAG}"
  )
elseif(SAPI_GOOGLETEST_PROVIDER STREQUAL "superbuild")
  set(SAPI_BENCHMARK_POPULATE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/benchmark-populate" CACHE STRING "")
  set(SAPI_BENCHMARK_SOURCE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/benchmark-src" CACHE STRING "")
  set(SAPI_BENCHMARK_BINARY_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/benchmark-build" CACHE STRING "")
  file(WRITE "${SAPI_BENCHMARK_POPULATE_DIR}/CMakeLists.txt" "\
cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(benchmark-populate NONE)
include(ExternalProject)
ExternalProject_Add(benchmark
  GIT_REPOSITORY    \"${SAPI_BENCHMARK_GIT_REPOSITORY}\"
  GIT_TAG           \"${SAPI_BENCHMARK_GIT_TAG}\"
  SOURCE_DIR        \"${SAPI_BENCHMARK_SOURCE_DIR}\"
  BINARY_DIR        \"${SAPI_BENCHMARK_BINARY_DIR}\"
  CONFIGURE_COMMAND \"\"
  BUILD_COMMAND     \"\"
  INSTALL_COMMAND   \"\"
  TEST_COMMAND      \"\"
)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_BENCHMARK_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "CMake step for ${PROJECT_NAME} failed: ${error}")
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} --build .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_BENCHMARK_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "Build step for ${PROJECT_NAME} failed: ${error}")
  endif()
endif()

if(SAPI_BENCHMARK_PROVIDER STREQUAL "package")
  find_package(benchmark REQUIRED CONFIG)
else()
  set(BENCHMARK_ENABLE_TESTING OFF)
  set(BENCHMARK_ENABLE_EXCEPTIONS OFF)
  set(BENCHMARK_ENABLE_GTEST_TESTS OFF)

  if(SAPI_BENCHMARK_PROVIDER STREQUAL "fetch")
    FetchContent_MakeAvailable(benchmark)
  elseif(SAPI_BENCHMARK_PROVIDER STREQUAL "superbuild")
    add_subdirectory("${SAPI_BENCHMARK_SOURCE_DIR}"
                     "${SAPI_BENCHMARK_BINARY_DIR}" EXCLUDE_FROM_ALL)
  endif()
endif()

sapi_check_target(benchmark)
