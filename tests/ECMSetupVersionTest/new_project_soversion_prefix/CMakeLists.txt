cmake_minimum_required(VERSION 3.16)

project(new_project_soversion_prefix VERSION 2.3.4)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../modules)
include(ECMSetupVersion)

ecm_setup_version(PROJECT
    VARIABLE_PREFIX Foo
    SOVERSION 1
)

include(../version_helpers.cmake)
standard_version_var_checks(Foo 2.3.4 1)

add_executable(dummy main.c)
