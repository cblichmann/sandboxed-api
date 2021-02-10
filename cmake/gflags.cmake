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

set(SAPI_GFLAGS_GIT_REPOSITORY https://github.com/gflags/gflags.git
                               CACHE STRING "")
set(SAPI_GFLAGS_GIT_TAG addd749114fab4f24b7ea1e0f2f837584389e52c
                        CACHE STRING "") # 2020-03-18

if(SAPI_GFLAGS_PROVIDER STREQUAL "fetch")
  FetchContent_Declare(gflags
    GIT_REPOSITORY "${SAPI_GFLAGS_GIT_REPOSITORY}"
    GIT_TAG        "${SAPI_GFLAGS_GIT_TAG}"
  )
elseif(SAPI_GFLAGS_PROVIDER STREQUAL "superbuild")
  set(SAPI_GFLAGS_POPULATE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/gflags-populate" CACHE STRING "")
  set(SAPI_GFLAGS_SOURCE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/gflags-src" CACHE STRING "")
  set(SAPI_GFLAGS_BINARY_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/gflags-build" CACHE STRING "")
  file(WRITE "${SAPI_GFLAGS_POPULATE_DIR}/CMakeLists.txt" "\
cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(gflags-populate NONE)
include(ExternalProject)
ExternalProject_Add(gflags
  GIT_REPOSITORY    \"${SAPI_GFLAGS_GIT_REPOSITORY}\"
  GIT_TAG           \"${SAPI_GFLAGS_GIT_TAG}\"
  SOURCE_DIR        \"${SAPI_GFLAGS_SOURCE_DIR}\"
  BINARY_DIR        \"${SAPI_GFLAGS_BINARY_DIR}\"
  CONFIGURE_COMMAND \"\"
  BUILD_COMMAND     \"\"
  INSTALL_COMMAND   \"\"
  TEST_COMMAND      \"\"
)
")
 execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                 RESULT_VARIABLE error
                 WORKING_DIRECTORY "${SAPI_GFLAGS_POPULATE_DIR}")
 if(error)
   message(FATAL_ERROR "CMake step for ${PROJECT_NAME} failed: ${error}")
 endif()
 execute_process(COMMAND ${CMAKE_COMMAND} --build .
                 RESULT_VARIABLE error
                 WORKING_DIRECTORY "${SAPI_GFLAGS_POPULATE_DIR}")
 if(error)
   message(FATAL_ERROR "Build step for ${PROJECT_NAME} failed: ${error}")
 endif()
endif()

if(SAPI_GFLAGS_PROVIDER STREQUAL "package")
  find_package(gflags REQUIRED CONFIG)
else()
  set(GFLAGS_IS_SUBPROJECT TRUE)
  set(GFLAGS_BUILD_SHARED_LIBS ${SAPI_ENABLE_SHARED_LIBS})
  set(GFLAGS_INSTALL_SHARED_LIBS ${SAPI_ENABLE_SHARED_LIBS})
  set(GFLAGS_INSTALL_HEADERS OFF) # TODO: Temporary off
  set(GFLAGS_BUILD_TESTING FALSE)

  if(SAPI_GFLAGS_PROVIDER STREQUAL "fetch")
    FetchContent_MakeAvailable(gflags)
  elseif(SAPI_GFLAGS_PROVIDER STREQUAL "superbuild")
    add_subdirectory("${SAPI_GFLAGS_SOURCE_DIR}"
                     "${SAPI_GFLAGS_BINARY_DIR}" EXCLUDE_FROM_ALL)
  endif()
endif()

sapi_check_target(gflags)
