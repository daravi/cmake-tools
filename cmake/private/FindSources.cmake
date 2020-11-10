# License information...
# ...

#[=======================================================================[.rst:
AddDependencies
------------------

Description.

.. command:: find_*

  .. code-block:: cmake

	find_source_files(root SOURCES PUBLIC_HEADERS PRIVATE_HEADERS QT_RESOURCE_FILES)

  Given root, finds the result and stores them in the following variables

More description...

.. note::
  Function assumes a separate include/src pitchfork project structure:
  https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs#src.header-placement.separate
#]=======================================================================]

include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.12)

#]=======================================================================]

function(find_source_files root sources public_headers private_headers qt_resource_files)
	file(GLOB_RECURSE source_list CONFIGURE_DEPENDS ${root}/src/*.C ${root}/src/*.cc ${root}/src/*.cpp ${root}/src/*.CPP ${root}/src/*.c++ ${root}/src/*.cp ${root}/src/*.cxx)
	set(${sources} ${source_list} PARENT_SCOPE)
	
	file(GLOB_RECURSE public_header_list ${root}/include/*.h ${root}/include/*.hh ${root}/include/*.H ${root}/include/*.hp ${root}/include/*.hxx ${root}/include/*.hpp ${root}/include/*.HPP ${root}/include/*.h++)
	set(${public_headers} ${public_header_list} PARENT_SCOPE)
	
	file(GLOB_RECURSE private_header_list ${root}/src/*.h ${root}/src/*.hh ${root}/src/*.H ${root}/src/*.hp ${root}/src/*.hxx ${root}/src/*.hpp ${root}/src/*.HPP ${root}/src/*.h++)
	set(${private_headers} ${private_header_list} PARENT_SCOPE)

	file(GLOB_RECURSE qt_resource_list CONFIGURE_DEPENDS ${root}/src/*.qrc)
	set(${qt_resource_files} ${qt_resource_list} PARENT_SCOPE)
endfunction(find_source_files)
