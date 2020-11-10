# License information...
# ...

#[=======================================================================[.rst:
CreateTarget
------------------

Description.

.. command:: create_*

  .. code-block:: cmake

    create_executable(<target>
					 [LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
					 [CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
					 [QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...])

	create_library(<target>
				  [LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
				  [CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
				  [QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...])

	create_header_only_library(<target>
					          [LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
							  [CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
							  [QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...])

	create_test(<target>
			   [LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
			   [CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
			   [QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
			   [INTEGRATION_LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
			   [INTEGRATION_CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
			   [INTEGRATION_QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]))

  The LOCAL, CONAN, and QT keywords can be used to specify the type of the dependency list to follow.

More description...

.. note::
  Notes...
#]=======================================================================]

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/private/FindSources.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/private/AddTargetDependencies.cmake)

cmake_minimum_required(VERSION 3.12)

#]=======================================================================]

function(_set_install_directories target)
	install(TARGETS ${target}
		CONFIGURATIONS Debug
		ARCHIVE DESTINATION ${DEBUG_INSTALL_DIR}
		LIBRARY DESTINATION ${DEBUG_INSTALL_DIR}
		RUNTIME DESTINATION ${DEBUG_INSTALL_DIR})
	install(TARGETS ${target}
		CONFIGURATIONS Release
		ARCHIVE DESTINATION ${RELEASE_INSTALL_DIR}
		LIBRARY DESTINATION ${RELEASE_INSTALL_DIR}
		RUNTIME DESTINATION ${RELEASE_INSTALL_DIR})
endfunction(_set_install_directories)

#]=======================================================================]

function(_configure_target target source_directory)
	set(multiValueArgs LOCAL CONAN QT)
	cmake_parse_arguments("_configure_target" "" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED _configure_target_UNPARSED_ARGUMENTS)
		message(WARNING "  -> _configure_target received unexpected argument(s) '${_configure_target_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	find_source_files(${source_directory} sources private_headers public_headers qt_resource_files)
	if(DEFINED qt_resource_files)
		# Qt Quick Compiler is required for AOT compilation (avoiding JIT compilation with Q_INIT_RESOURCE(libraryname) in the dependent code)
		message(VERBOSE " => Adding Qt resouce files: ${qt_resource_files}")
		find_package(Qt5QuickCompiler REQUIRED)
		qtquick_compiler_add_resources(compiled_qt_resource_files ${qt_resource_files})
	endif()

	# TODO PUYA: Does this duplicate resources in library and the consumer of the library?
	target_sources(${target}
		PRIVATE ${sources} ${private_headers} ${compiled_qt_resource_files}
		PUBLIC ${public_headers} ${qt_resource_files}) # headers added for IDE
	target_include_directories(${target} PRIVATE ${source_directory}/src PUBLIC ${source_directory}/include)

	add_target_dependencies(${target}
		LOCAL "${_configure_target_LOCAL}"
		CONAN "${_configure_target_CONAN}"
		QT "${_configure_target_QT}")

	_set_install_directories(${target})
endfunction(_configure_target)

#]=======================================================================]

function(create_executable target)
	set(multiValueArgs LOCAL CONAN QT)
	cmake_parse_arguments("create_executable" "" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED create_executable_UNPARSED_ARGUMENTS)
		message(WARNING "  -> create_executable received unexpected argument(s) '${create_executable_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	add_executable(${target})
	_configure_target(${target} ${CMAKE_CURRENT_SOURCE_DIR}
		LOCAL "${create_executable_LOCAL}"
		CONAN "${create_executable_CONAN}"
		QT "${create_executable_QT}")
endfunction(create_executable)

#]=======================================================================]

function(create_library target)
	set(multiValueArgs LOCAL CONAN QT)
	cmake_parse_arguments("create_library" "" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED create_library_UNPARSED_ARGUMENTS)
		message(WARNING "  -> create_library received unexpected argument(s) '${create_library_UNPARSED_ARGUMENTS}' for ${target}")
	endif()
	
	add_library(${target})
	_configure_target(${target} ${CMAKE_CURRENT_SOURCE_DIR}
		LOCAL "${create_library_LOCAL}"
		CONAN "${create_library_CONAN}"
		QT "${create_library_QT}")
endfunction(create_library)

#]=======================================================================]

function(create_header_only_library target)
	set(multiValueArgs LOCAL CONAN QT)
	cmake_parse_arguments("create_header_only_library" "" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED create_library_UNPARSED_ARGUMENTS)
		message(WARNING "  -> create_header_only_library received unexpected argument(s) '${create_header_only_library_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	find_source_files(${CMAKE_CURRENT_SOURCE_DIR} _ _ public_headers _)

	add_library(${target} INTERFACE)
	target_sources(${target} INTERFACE ${public_headers}) # headers added for IDE
	target_include_directories(${target} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)

	add_target_dependencies(${target}
		LOCAL "${create_header_only_library_LOCAL}"
		CONAN "${create_header_only_library_CONAN}"
		QT "${create_header_only_library_QT}")
endfunction(create_header_only_library)

#]=======================================================================]

function(create_test target)
	set(options ADD_INTEGRATION_TESTS)
	set(multiValueArgs LOCAL CONAN QT INTEGRATION_LOCAL INTEGRATION_CONAN INTEGRATION_QT)
	cmake_parse_arguments("create_test" "${options}" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED create_test_UNPARSED_ARGUMENTS)
		message(WARNING "  -> create_test received unexpected argument(s) '${create_test_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	string(CONCAT test_target "test-" ${target})

	# Create main unit test file from template
	configure_file(
		${CMAKE_SOURCE_DIR}/templates/unit-test-template.in
		${CMAKE_CURRENT_SOURCE_DIR}/tests/src/${test_target}.cpp)

	add_executable(${test_target})
	_configure_target(${test_target} ${CMAKE_CURRENT_SOURCE_DIR}/tests
		LOCAL ${create_test_LOCAL} PRIVATE ${target}
		CONAN ${create_test_CONAN} PRIVATE glog gtest)

	# We also test private code
	target_include_directories(${test_target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

	# Enable/Disable integration tests that might require additional dependencies
	if(${ENABLE_INTEGRATION_TESTS} AND ${create_test_ADD_INTEGRATION_TESTS})
		# Add integration tests' dependencies
		add_target_dependencies(${test_target}
			LOCAL "${create_test_INTEGRATION_LOCAL}"
			CONAN "${create_test_INTEGRATION_CONAN}"
			QT "${create_test_INTEGRATION_QT}")
		target_compile_definitions(${test_target} PRIVATE ENABLE_INTEGRATION_TESTS)
		message(STATUS " => Integration tests are enabled for ${target}")
	endif()
endfunction(create_test)
