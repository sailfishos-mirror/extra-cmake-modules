cmake_minimum_required(VERSION 3.16)

project(new_explicit_header_abspath VERSION 1.5.6.7)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../modules)
include(ECMSetupVersion)

ecm_setup_version(2.3.4
    VARIABLE_PREFIX Foo
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/../ecm_new_explicit_header_abspath_version.h"
)

include(../version_helpers.cmake)
project_version_var_checks(1.5.6.7)
version_var_checks(Foo 2.3.4)
assert_var_num_value(Foo_SOVERSION 2)

add_executable(check_header main.c)
target_include_directories(check_header PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/..")
