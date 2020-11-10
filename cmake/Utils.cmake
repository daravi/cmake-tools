# License information...
# ...

#[=======================================================================[.rst:
Utils
------------------

Description.

.. command::

  .. code-block:: cmake

    ...

More description...

.. note::
  Notes...
#]=======================================================================]

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/CreateTarget.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Generators.cmake)

cmake_minimum_required(VERSION 3.12)

#]=======================================================================]

# Options
option(ENABLE_INTEGRATION_TESTS "Enables the integration tests for all targets that use it. (might require additional dependencies)" OFF)

#]=======================================================================]

# TODO PUYA: improve these, specially for default case of Debug and Release

macro(set_compiler_flags)
	set(CMAKE_CXX_STANDARD 17)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)
	# set(CMAKE_CXX_FLAGS_DEBUG "-fsanitize=address -g3") # AddressSanitizer
	# set(CMAKE_CXX_FLAGS_DEBUG "-g -O0") # valgrind
	# set(CMAKE_CXX_FLAGS_DEBUG "-g3 --coverage") # Enable coverage (for gcov)
endmacro()

#]=======================================================================]

macro(set_clang_compiler_flags)
	set_compiler_flags()
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -stdlib=libc++ -fdiagnostics-color=always")
	# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++ -static -fuse-ld=lld")
	# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -stdlib=libc++") # Enable warnings
endmacro()

#]=======================================================================]
