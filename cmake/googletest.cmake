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

set(SAPI_GOOGLETEST_GIT_REPOSITORY https://github.com/google/googletest.git
                                   CACHE STRING "")
set(SAPI_GOOGLETEST_GIT_TAG dcc92d0ab6c4ce022162a23566d44f673251eee4
                            CACHE STRING "") # 2020-04-16

if(SAPI_GOOGLETEST_PROVIDER STREQUAL "fetch")
  FetchContent_Declare(googletest
    GIT_REPOSITORY "${SAPI_GOOGLETEST_GIT_REPOSITORY}"
    GIT_TAG        "${SAPI_GOOGLETEST_GIT_TAG}"
  )
elseif(SAPI_GOOGLETEST_PROVIDER STREQUAL "superbuild")
  set(SAPI_GOOGLETEST_POPULATE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/googletest-populate" CACHE STRING "")
  set(SAPI_GOOGLETEST_SOURCE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/googletest-src" CACHE STRING "")
  set(SAPI_GOOGLETEST_BINARY_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/googletest-build" CACHE STRING "")
  file(WRITE "${SAPI_GOOGLETEST_POPULATE_DIR}/CMakeLists.txt" "\
cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(googletest-populate NONE)
include(ExternalProject)
ExternalProject_Add(googletest
  GIT_REPOSITORY    \"${SAPI_GOOGLETEST_GIT_REPOSITORY}\"
  GIT_TAG           \"${SAPI_GOOGLETEST_GIT_TAG}\"
  SOURCE_DIR        \"${SAPI_GOOGLETEST_SOURCE_DIR}\"
  BINARY_DIR        \"${SAPI_GOOGLETEST_BINARY_DIR}\"
  CONFIGURE_COMMAND \"\"
  BUILD_COMMAND     \"\"
  INSTALL_COMMAND   \"\"
  TEST_COMMAND      \"\"
)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_GOOGLETEST_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "CMake step for ${PROJECT_NAME} failed: ${error}")
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} --build .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_GOOGLETEST_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "Build step for ${PROJECT_NAME} failed: ${error}")
  endif()
endif()

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

if(SAPI_GOOGLETEST_PROVIDER STREQUAL "fetch")
  FetchContent_MakeAvailable(googletest)
elseif(SAPI_GOOGLETEST_PROVIDER STREQUAL "superbuild")
  add_subdirectory("${SAPI_GOOGLETEST_SOURCE_DIR}"
                   "${SAPI_GOOGLETEST_BINARY_DIR}" EXCLUDE_FROM_ALL)
elseif(SAPI_GOOGLETEST_PROVIDER STREQUAL "package")
  find_package(GTest REQUIRED)
endif()

sapi_check_target(gtest)
sapi_check_target(gtest_main)
sapi_check_target(gmock)
