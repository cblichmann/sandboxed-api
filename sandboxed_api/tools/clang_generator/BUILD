# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@com_google_sandboxed_api//sandboxed_api/bazel:build_defs.bzl", "sapi_platform_copts")

licenses(["notice"])

cc_library(
    name = "generator",
    srcs = [
        "diagnostics.cc",
        "emitter.cc",
        "emitter_base.cc",
        "generator.cc",
        "types.cc",
    ],
    hdrs = [
        "diagnostics.h",
        "emitter.h",
        "emitter_base.h",
        "generator.h",
        "types.h",
    ],
    copts = sapi_platform_copts(),
    deps = [
        "@com_google_absl//absl/container:flat_hash_set",
        "@com_google_absl//absl/container:node_hash_set",
        "@com_google_absl//absl/log",
        "@com_google_absl//absl/random",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/status:statusor",
        "@com_google_absl//absl/strings",
        "@com_google_absl//absl/strings:cord",
        "@com_google_absl//absl/strings:str_format",
        "@com_google_absl//absl/types:optional",
        "@com_google_sandboxed_api//sandboxed_api/util:file_base",
        "@com_google_sandboxed_api//sandboxed_api/util:status",
        "@llvm-project//clang:ast",
        "@llvm-project//clang:basic",
        "@llvm-project//clang:format",
        "@llvm-project//clang:frontend",
        "@llvm-project//clang:lex",
        "@llvm-project//clang:serialization",
        "@llvm-project//clang:tooling",
        "@llvm-project//clang:tooling_core",
        "@llvm-project//llvm:Support",
        "@llvm-project//llvm:config",
    ],
)

cc_test(
    name = "generator_test",
    srcs = [
        "emitter_test.cc",
        "frontend_action_test_util.cc",
        "frontend_action_test_util.h",
    ],
    copts = sapi_platform_copts(),
    deps = [
        ":generator",
        "@com_google_absl//absl/container:flat_hash_map",
        "@com_google_absl//absl/memory",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/status:statusor",
        "@com_google_absl//absl/strings",
        "@com_google_googletest//:gtest_main",
        "@com_google_sandboxed_api//sandboxed_api/util:status_matchers",
        "@llvm-project//clang:basic",
        "@llvm-project//clang:frontend",
        "@llvm-project//clang:tooling",
        "@llvm-project//llvm:Support",
        "@llvm-project//llvm:config",
    ],
)

# Clang tool that generates Sandboxed API headers
cc_binary(
    name = "generator_tool",
    srcs = [
        "compilation_database.cc",
        "compilation_database.h",
        "generator_tool.cc",
    ],
    copts = sapi_platform_copts(),
    visibility = ["//visibility:public"],
    deps = [
        ":generator",
        "@com_google_absl//absl/base:core_headers",
        "@com_google_absl//absl/base:no_destructor",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/strings",
        "@com_google_absl//absl/strings:str_format",
        "@com_google_sandboxed_api//sandboxed_api/util:file_base",
        "@com_google_sandboxed_api//sandboxed_api/util:file_helpers",
        "@com_google_sandboxed_api//sandboxed_api/util:fileops",
        "@com_google_sandboxed_api//sandboxed_api/util:status",
        "@llvm-project//clang:driver",
        "@llvm-project//clang:tooling",
        "@llvm-project//llvm:Support",
        "@llvm-project//llvm:config",
    ],
)
