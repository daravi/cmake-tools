# License information...
# ...

#[=======================================================================[.rst:
AddTargetDependencies
------------------

Description.

.. command:: add_target_dependencies

  .. code-block:: cmake

	add_target_dependencies(<target>
	                [LOCAL [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
					[CONAN [<PRIVATE|PUBLIC|INTERFACE> <item>...]...]
					[QT [<PRIVATE|PUBLIC|INTERFACE> <item>...]...])

  The LOCAL, CONAN, and QT keywords can be used to specify the type of the dependency list to follow.

More description...

.. note::
  Notes...
#]=======================================================================]

include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.12)

#]=======================================================================]

function(_add_qt5_dependencies target modules)
	set(possibleLinkScopes PUBLIC PRIVATE INTERFACE)	
	set(scope PUBLIC)
	foreach(item ${modules})
		if(${item} IN_LIST possibleLinkScopes)
			set(scope ${item})
			continue()
		else()
			find_package(Qt5 COMPONENTS ${item} REQUIRED)
			target_link_libraries(${target} ${scope} Qt5::${item})
		endif()
	endforeach()

	set_target_properties(${target}
		PROPERTIES 
			AUTOMOC ON
			AUTOUIC ON
			AUTORCC ON)

	target_compile_definitions(${target} PUBLIC $<$<CONFIG:Debug>:QT_QML_DEBUG>)
endfunction(_add_qt5_dependencies)

#]=======================================================================]

function(_add_conan_dependencies target dependencies)
	set(possibleLinkScopes PUBLIC PRIVATE INTERFACE)
	set(scope PRIVATE)
	foreach(item ${dependencies})
		if(${item} IN_LIST possibleLinkScopes)
			set(scope ${item})
			continue()
		else()
			target_link_libraries(${target} ${scope} CONAN_PKG::${item})
		endif()
	endforeach()
endfunction(_add_conan_dependencies)

#]=======================================================================]

function(add_target_dependencies target)
	set(multiValueArgs LOCAL CONAN QT)
	cmake_parse_arguments("add_target_dependencies" "" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED add_target_dependencies_UNPARSED_ARGUMENTS)
		message(WARNING "  -> add_target_dependencies received unexpected argument(s) '${add_target_dependencies_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	message(VERBOSE " -- Adding intra-project dependencies for ${target}: ${add_target_dependencies_LOCAL}")
	if(DEFINED add_target_dependencies_LOCAL)
		target_link_libraries(${target} PRIVATE ${add_target_dependencies_LOCAL})
	endif()

	message(VERBOSE " -- Adding Conan dependencies for ${target}: ${add_target_dependencies_CONAN}")
	if(DEFINED add_target_dependencies_CONAN)
		_add_conan_dependencies(${target} "${add_target_dependencies_CONAN}")
	endif()

	message(VERBOSE " -- Adding Qt dependencies for ${target}: ${add_target_dependencies_QT}")
	if(DEFINED add_target_dependencies_QT)
		_add_qt5_dependencies(${target} "${add_target_dependencies_QT}")
	endif()
endfunction(add_target_dependencies)
