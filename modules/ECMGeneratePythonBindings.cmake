# SPDX-FileCopyrightText: 2023 The Qt Company Ltd.
# SPDX-FileCopyrightText: 2024 Manuel Alcaraz Zambrano <manuelalcarazzam@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause

# Based on https://code.qt.io/cgit/pyside/pyside-setup.git/tree/examples/widgetbinding/CMakeLists.txt

# TODO: there are some hardcoded paths

#[=======================================================================[.rst:
ECMGeneratePythonBindings
-------------------------

Generate Python bindings using Shiboken.

::

  ecm_generate_python_bindings(PACKAGE_NAME <pythonlibrary>
                               WRAPPED_HEADER <filename>
                               TYPESYSTEM <filename>
                               GENERATED_SOURCES <filename> [<filename> [...]]
                               DEPENDENCIES <target> [<target> [...]]
                               PYPROJECT <filename> )

``<pythonlibrary>`` is the name of the Python library that will be created.

``WRAPPED_HEADER`` is a C++ header that contains all the required includes
for the library.

``TYPESYSTEM`` is the XML file where the bindings are defined.

``GENERATED_SOURCES`` is the list of generated C++ source files by Shiboken
that will be used to build the shared library.

``DEPENDENCIES`` is a list of dependencies that the library uses. They will
be linked to the shared library.

``PYPROJECT`` is the pyproject.toml file that will be used to build the
Python wheel (the file format used to distribute Python packages).

#]=======================================================================]

function(ecm_generate_python_bindings)
    set(options )
    set(oneValueArgs PACKAGE_NAME WRAPPED_HEADER TYPESYSTEM PYPROJECT)
    set(multiValueArgs GENERATED_SOURCES DEPENDENCIES)

    cmake_parse_arguments(PB "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})

    if(NOT ${PROJECT_NAME}_PYTHON_BINDINGS_INSTALL_PREFIX)
        set(${PROJECT_NAME}_PYTHON_BINDINGS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
    endif()
    set(Python3_VERSION_MAJORMINOR "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}")
    set(BINDINGS_DIR "${INSTALL_LIBRARY_DIR}/python${Python3_VERSION_MAJORMINOR}/site-packages/${PYTHON_BINDING_NAMESPACE}")
    set(${PB_PROJECT_NAME}_PYTHON_BINDINGS_INSTALL_PREFIX "${${PB_PROJECT_NAME}_PYTHON_BINDINGS_INSTALL_PREFIX}/${BINDINGS_DIR}")

    list(APPEND PB_DEPENDENCIES PySide6::pyside6)
    list(APPEND PB_DEPENDENCIES Shiboken6::libshiboken)

    # Enable rpaths so that the built shared libraries find their dependencies.
    set(CMAKE_SKIP_BUILD_RPATH FALSE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH ${SHIBOKEN_PYTHON_MODULE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    # Get the relevant Qt include dirs, to pass them on to shiboken.
    set(INCLUDES "")
    list(APPEND INCLUDES "-I/usr/include/KF6/")

    foreach(DEPENDENCY ${PB_DEPENDENCIES})
        get_property(DEPENDENCY_INCLUDE_DIRS TARGET "${DEPENDENCY}" PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

        foreach(INCLUDE_DIR ${DEPENDENCY_INCLUDE_DIRS})
            if (NOT ("${INCLUDE_DIR}" MATCHES "INSTALL_INTERFACE"))
                list(APPEND INCLUDES "-I${INCLUDE_DIR}")
            endif()
        endforeach()
    endforeach()

    list(APPEND INCLUDES "-I${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_INCLUDEDIR}/KF6/${PB_PACKAGE_NAME}")

    # Set up the options to pass to shiboken.
    set(shiboken_options --enable-pyside-extensions
        ${INCLUDES}
        -I${CMAKE_SOURCE_DIR}
        -T${CMAKE_SOURCE_DIR}
        -T${PYSIDE_TYPESYSTEMS}
        --output-directory=${CMAKE_CURRENT_BINARY_DIR})

    set(generated_sources_dependencies ${PB_WRAPPED_HEADER} ${PB_TYPESYSTEM})

    # Add custom target to run shiboken to generate the binding cpp files.
    add_custom_command(
        OUTPUT ${PB_GENERATED_SOURCES}
        COMMAND shiboken6 ${shiboken_options} ${PB_WRAPPED_HEADER} ${PB_TYPESYSTEM}
        DEPENDS ${generated_sources_dependencies}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Running generator for ${PB_TYPESYSTEM}"
    )

    # Set the cpp files which will be used for the bindings library.
    set(${PB_PACKAGE_NAME}_sources ${PB_GENERATED_SOURCES})

    # TODO:
    remove_definitions("-DQT_DEPRECATED_WARNINGS_SINCE")
    remove_definitions("-DQT_DISABLE_DEPRECATED_BEFORE")

    # Define and build the bindings library.
    add_library(${PB_PACKAGE_NAME} SHARED ${${PB_PACKAGE_NAME}_sources})

    target_link_libraries(${PB_PACKAGE_NAME} PRIVATE
        PySide6::pyside6
        Shiboken6::libshiboken
        ${Python3_LIBRARIES}
    )

    # Apply relevant include and link flags.
    target_include_directories(${PB_PACKAGE_NAME} PRIVATE ${PYSIDE_PYTHONPATH}/include ${SHIBOKEN_PYTHON_INCLUDE_DIRS})
    # TODO:
    target_include_directories(${PB_PACKAGE_NAME} PRIVATE "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_INCLUDEDIR}/KF6/${PB_PACKAGE_NAME}"
                                                          "/usr/include/PySide6/"
                                                          "/usr/include/PySide6/QtWidgets/"
                                                          "/usr/include/PySide6/QtGui/"
                                                          "/usr/include/PySide6/QtCore/" )

    foreach(DEPENDENCY ${PB_DEPENDENCIES})
        target_link_libraries(${PB_PACKAGE_NAME} PRIVATE "${DEPENDENCY}")
    endforeach()

    # Adjust the name of generated module.
    set_property(TARGET ${PB_PACKAGE_NAME} PROPERTY PREFIX "")
    set_property(TARGET ${PB_PACKAGE_NAME} PROPERTY OUTPUT_NAME "${PB_PACKAGE_NAME}${PYTHON_CONFIG_SUFFIX}${PYTHON_EXTENSION_SUFFIX}")
    set_property(TARGET ${PB_PACKAGE_NAME} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${PB_PACKAGE_NAME}/build/lib)

    install(
        TARGETS ${PB_PACKAGE_NAME}
        LIBRARY DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}
        RUNTIME DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}
    )

    # Build Python Wheel
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${PB_PACKAGE_NAME}/${PB_PACKAGE_NAME}")
    configure_file(${PB_PYPROJECT} "${CMAKE_CURRENT_BINARY_DIR}/${PB_PACKAGE_NAME}/pyproject.toml" COPYONLY)

    add_custom_command(
        TARGET ${PB_PACKAGE_NAME}
        POST_BUILD
        COMMAND python -m build --wheel
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${PB_PACKAGE_NAME}"
        COMMENT "Building Python Wheel"
    )

endfunction(PythonBindings)