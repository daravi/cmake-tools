# License information...
# ...

#[=======================================================================[.rst:
Generators
------------------

Description.

.. command:: generate_*

  .. code-block:: cmake

	generate_qrc(<root> <outfile> [GENERATOR <generator_path>])
	>> The GENERATOR is the python script to generate the qrc file (default is <CORELIBS>/scripts/generate_qrc.py).
	
	generate_custom(<outfile> <generator> [INFILES <file1> <file2> ...] [INDIRS <dir1> <dir2> ...] [<arg1> <arg2> ...])
	>> Remaining arguments are passed to the python generator script

More description...

.. note::
  Notes...
#]=======================================================================]

include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.12)

#]=======================================================================]
# TODO PUYA: Throw WARNING when helper functions (starting with _) are not called from the same file
function(_modified_timestamp last_modified files)
	set(result 0)
	foreach(file ${files})
		file(TIMESTAMP ${file} file_last_update %s)
		if(file_last_update GREATER result)
			set(result ${file_last_update})
		endif()
	endforeach()

	set(${last_modified} ${result} PARENT_SCOPE)
endfunction(_modified_timestamp)

#]=======================================================================]

function(_directory_files_changed changed directories)
	set(result FALSE)
	foreach(directory ${directories})
		file(GLOB_RECURSE all_files_in_directory CONFIGURE_DEPENDS ${directory}/*)

		string(SHA256 directory_hash ${directory})
		set(cached_file_list_variable_name ${directory_hash}_FILE_LIST)
		if(NOT ("$CACHE{${cached_file_list_variable_name}}" STREQUAL all_files_in_directory))
			# directory's recursive file list has changed (files added or removed)
			set(${cached_file_list_variable_name} ${all_files_in_directory} CACHE INTERNAL "")
			set(result TRUE)
			break()
		endif()
	endforeach()

	set(${changed} ${result} PARENT_SCOPE)
endfunction(_directory_files_changed)

#]=======================================================================]

function(_list_subdirs result current_dir)
	file(GLOB children RELATIVE ${current_dir} "${current_dir}/*")
	set(subdirs)
	foreach(child ${children})
		if(IS_DIRECTORY "${current_dir}/${child}")
			list(APPEND subdirs ${child})
		endif()
	endforeach()
	set(${result} ${subdirs} PARENT_SCOPE)
endfunction(_list_subdirs)

#]=======================================================================]

function(_generate_file outfile generation_command)
	set(multiValueArgs ARGS INDIRS INFILES)
	cmake_parse_arguments("_generate_file" "FORCE" "" "${multiValueArgs}" ${ARGN})
	if(DEFINED generate_file_UNPARSED_ARGUMENTS)
		message(WARNING "  -> _generate_file received unexpected argument(s) '${generate_file_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	_modified_timestamp(last_modified "${_generate_file_INFILES}")
	_directory_files_changed(indirs_changed "${_generate_file_INDIRS}")

	string(SHA256 filename_hash ${outfile})
	set(cache_variable_name ${filename_hash}_LAST_MODIFIED)

	if(NOT ${_generate_file_FORCE})
		if(("$CACHE{${cache_variable_name}}" STREQUAL last_modified) AND (NOT ${indirs_changed}) AND (EXISTS ${outfile}))
			message(VERBOSE " => Nothing to do. Already up-to-date! (remove generated file(s) or CMakeCache.txt to force re-generation)")
			return()
		endif()
	endif()

	message(STATUS "Generating ${outfile}")

	EXECUTE_PROCESS(COMMAND ${generation_command} ${_generate_file_ARGS})

	if(DEFINED last_modified)
		set(${cache_variable_name} ${last_modified} CACHE INTERNAL "Timestamp for last update of inputs for generating ${outfile}")
	else()
		unset(${cache_variable_name} CACHE)
	endif()
endfunction(_generate_file)

#]=======================================================================]

function(generate_qrc root outfile)
	cmake_parse_arguments("generate_qrc" "" "GENERATOR" "" ${ARGN})
	if(DEFINED generate_qrc_UNPARSED_ARGUMENTS)
		message(WARNING "  -> generate_qrc received unexpected argument(s) '${generate_qrc_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	set(generator "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/private/generators/generate_qrc.py")
	if(DEFINED generate_qrc_GENERATOR)
		set(generator ${generate_qrc_GENERATOR})
	endif()

	_generate_file(${outfile} python
		ARGS ${generator} ${root} -o ${outfile}
		INDIRS ${root}
		INFILES ${generator})
endfunction(generate_qrc)

#]=======================================================================]

function(generate_custom outfile generator)
	# TODO PUYA: Use a python template engine to avoid code duplication in the generators
	set(multiValueArgs INFILES INDIRS)
	cmake_parse_arguments("generate_custom" "" "" "${multiValueArgs}" ${ARGN})

	_generate_file(${outfile} python
		ARGS
			${generator}
			--output_file ${outfile}
			--input_files ${generate_custom_INFILES}
			--input_directories ${generate_custom_INDIRS}
			${generate_custom_UNPARSED_ARGUMENTS}
		INDIRS ${generate_custom_INDIRS}
		INFILES ${generate_custom_INFILES} ${generator})
endfunction(generate_custom)

#]=======================================================================]

function(generate_proto protofile outdir)
	cmake_parse_arguments("generate_proto" "PUBLIC" "PROTOC" "PROTO_PATHS" ${ARGN})
	if(DEFINED generate_proto_UNPARSED_ARGUMENTS)
		message(WARNING "  -> generate_proto received unexpected argument(s) '${generate_proto_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	set(protoc_exe "protoc")
	if (WIN32)
		set(protoc_exe "protoc.exe")
	endif()

	set(protoc "")
	if(DEFINED generate_proto_PROTOC)
		set(protoc ${generate_proto_PROTOC})
	elseif(EXISTS ${CONAN_BIN_DIRS_PROTOBUF}/${protoc_exe})
		set(protoc ${CONAN_BIN_DIRS_PROTOBUF}/${protoc_exe})
	else()
		message(FATAL_ERROR " => No protobuf compiler was provided (have you added protobuf to Conan requirements?)")
	endif()

	get_filename_component(file_directory ${protofile} DIRECTORY)
	get_filename_component(file_stem ${protofile} NAME_WLE)

	get_filename_component(protofile_directory ${protofile} DIRECTORY)

	set(proto_path_args "")
	if(DEFINED generate_proto_PROTO_PATHS)
		foreach(proto_path ${generate_proto_PROTO_PATHS})
			list(APPEND proto_path_args "--proto_path=${proto_path}")
		endforeach()
	else()
		set(proto_path_args "--proto_path=${protofile_directory}")
	endif()

	file(MAKE_DIRECTORY ${outdir})

	# TODO PUYA: Properly fix this:
	set(outfile_directory ${outdir})
	if(DEFINED proto_root)
		string(REPLACE ${proto_root} ${outdir} outfile_directory ${protofile_directory})
	endif()
	
	set(cc_path "${outfile_directory}/${file_stem}.pb.cc")
	set(default_h_path "${outfile_directory}/${file_stem}.pb.h")

	set(final_h_path "${default_h_path}")
	if(${generate_proto_PUBLIC})
		string(REPLACE "src" "include" public_header_dir ${outfile_directory})
		file(MAKE_DIRECTORY ${public_header_dir})
		string(REPLACE "src" "include" final_h_path ${default_h_path})
	endif()

	# TODO PUYA: Change _generate_file to _generate and add optional argument "tracked files"
	set(force_option "")
	if(NOT EXISTS ${cc_path} OR NOT EXISTS ${final_h_path})
		set(force_option FORCE)
	endif()

	_generate_file(${cc_path} ${protoc}
		ARGS
			${proto_path_args}
			--cpp_out=${outdir}
			${protofile}
		INFILES ${protofile} ${protoc}
		${force_option})

	# ---------------------------------------------
	# Move header to public headers directory if PUBLIC option is set:
	if(default_h_path STREQUAL final_h_path)
		return()
	endif()
	

	set(move_command "mv")
	if (WIN32)
		set(move_command "move")
	endif()

	_generate_file(${final_h_path} ${move_command}
		ARGS
			${default_h_path}
			${final_h_path}
		INFILES ${protofile} ${protoc}
		${force_option})
endfunction(generate_proto)

#]=======================================================================]

function(generate_protos proto_root outdir)
	cmake_parse_arguments("generate_protos" "PUBLIC" "PROTOC" "PROTO_PATHS" ${ARGN})
	if(DEFINED generate_protos_UNPARSED_ARGUMENTS)
		message(WARNING "  -> generate_protos received unexpected argument(s) '${generate_protos_UNPARSED_ARGUMENTS}' for ${target}")
	endif()

	set(protoc_exe "protoc")
	if (WIN32)
		set(protoc_exe "protoc.exe")
	endif()

	set(protoc "")
	if(DEFINED generate_protos_PROTOC)
		set(protoc ${generate_protos_PROTOC})
	elseif(EXISTS ${CONAN_BIN_DIRS_PROTOBUF}/${protoc_exe})
		set(protoc ${CONAN_BIN_DIRS_PROTOBUF}/${protoc_exe})
	else()
		message(FATAL_ERROR " => No protobuf compiler was provided (have you added protobuf to Conan requirements?)")
	endif()

	set(public_option "")
	if(${generate_protos_PUBLIC})
		set(public_option PUBLIC)
	endif()

	file(GLOB_RECURSE protofiles ${proto_root} "${proto_root}/*.proto")
	foreach(protofile ${protofiles})
		generate_proto(${protofile} ${outdir}
			${public_option}
			PROTOC ${protoc}
			PROTO_PATHS ${proto_root} ${generate_protos_PROTO_PATHS})
	endforeach()
endfunction(generate_protos)
