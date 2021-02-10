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

set(SAPI_ABSL_GIT_REPOSITORY https://github.com/abseil/abseil-cpp.git
                             CACHE STRING "")
set(SAPI_ABSL_GIT_TAG b315753c0b8b4aa4e3e1479375eddb518393bab6
                      CACHE STRING "") # 2020-11-19

if(SAPI_ABSL_PROVIDER STREQUAL "fetch")
  FetchContent_Declare(absl
    GIT_REPOSITORY "${SAPI_ABSL_GIT_REPOSITORY}"
    GIT_TAG        "${SAPI_ABSL_GIT_TAG}"
  )
else()
  set(SAPI_ABSL_POPULATE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/absl-populate" CACHE STRING "")
  set(SAPI_ABSL_SOURCE_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/absl-src" CACHE STRING "")
  set(SAPI_ABSL_BINARY_DIR
    "${SAPI_SUPERBUILD_BASE_DIR}/absl-build" CACHE STRING "")
  file(WRITE "${SAPI_ABSL_POPULATE_DIR}/CMakeLists.txt" "\
cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(absl-populate NONE)
include(ExternalProject)
ExternalProject_Add(absl
  GIT_REPOSITORY    \"${SAPI_ABSL_GIT_REPOSITORY}\"
  GIT_TAG           \"${SAPI_ABSL_GIT_TAG}\"
  SOURCE_DIR        \"${SAPI_ABSL_SOURCE_DIR}\"
  BINARY_DIR        \"${SAPI_ABSL_BINARY_DIR}\"
  CONFIGURE_COMMAND \"\"
  BUILD_COMMAND     \"\"
  INSTALL_COMMAND   \"\"
  TEST_COMMAND      \"\"
)
")
  execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_ABSL_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "CMake step for ${PROJECT_NAME} failed: ${error}")
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} --build .
                  RESULT_VARIABLE error
                  WORKING_DIRECTORY "${SAPI_ABSL_POPULATE_DIR}")
  if(error)
    message(FATAL_ERROR "Build step for ${PROJECT_NAME} failed: ${error}")
  endif()
endif()

if(SAPI_ABSL_PROVIDER STREQUAL "package")
  find_package(absl REQUIRED CONFIG)
else()
  set(_sapi_saved_CMAKE_CXX_STANDARD ${CMAKE_CXX_STANDARD})
  set(_sapi_saved_BUILD_TESTING ${BUILD_TESTING})

  set(CMAKE_CXX_STANDARD ${SAPI_CXX_STANDARD})
  set(ABSL_USE_GOOGLETEST_HEAD OFF CACHE BOOL "" FORCE)
  set(ABSL_RUN_TESTS OFF CACHE BOOL "" FORCE)
  set(BUILD_TESTING OFF)  # Avoid errors when re-configuring SAPI
  set(ABSL_CXX_STANDARD ${SAPI_CXX_STANDARD} CACHE STRING "" FORCE)
  set(ABSL_ENABLE_INSTALL ON CACHE BOOL "" FORCE)

  if(SAPI_ABSL_PROVIDER STREQUAL "fetch")
    FetchContent_MakeAvailable(absl)
  elseif(SAPI_ABSL_PROVIDER STREQUAL "superbuild")
    add_subdirectory("${SAPI_ABSL_SOURCE_DIR}"
                     "${SAPI_ABSL_BINARY_DIR}" EXCLUDE_FROM_ALL)
  endif()

  if(_sapi_saved_BUILD_TESTING)
    set(BUILD_TESTING "${_sapi_saved_BUILD_TESTING}")
  endif()
  if(_sapi_saved_CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD "${_sapi_saved_CMAKE_CXX_STANDARD}")
  endif()
endif()

sapi_check_target(absl::core_headers)
