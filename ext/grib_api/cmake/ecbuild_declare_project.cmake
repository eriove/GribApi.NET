# (C) Copyright 1996-2014 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

# macro to initialize a project

macro( ecbuild_declare_project )

	string( TOUPPER ${PROJECT_NAME} PNAME )

	# reset the lists of targets (executables, libs, tests & resources)

	set( ${PROJECT_NAME}_ALL_EXES "" CACHE INTERNAL "" )
	set( ${PROJECT_NAME}_ALL_LIBS "" CACHE INTERNAL "" )

	# if git project get its HEAD SHA1
	# leave it here so we may use ${PNAME}_GIT_SHA1 on the version file

	if( EXISTS ${PROJECT_SOURCE_DIR}/.git )
		get_git_head_revision( GIT_REFSPEC ${PNAME}_GIT_SHA1 )
		if( ${PNAME}_GIT_SHA1 )
		  string( SUBSTRING "${${PNAME}_GIT_SHA1}" 0 7 ${PNAME}_GIT_SHA1_SHORT )
#		  debug_var( ${PNAME}_GIT_SHA1 )
#		  debug_var( ${PNAME}_GIT_SHA1_SHORT )
        else()
          message( STATUS "Could not get git-sha1 for project ${PNAME}")
        endif()
	endif()

	# read and parse project version file
	if( EXISTS ${PROJECT_SOURCE_DIR}/VERSION.cmake )
		include( ${PROJECT_SOURCE_DIR}/VERSION.cmake )
	else()
		set( ${PROJECT_NAME}_VERSION_STR "0.0.0" )
	endif()

	string( REPLACE "." " " _version_list ${${PROJECT_NAME}_VERSION_STR} ) # dots to spaces

	separate_arguments( _version_list )

	list( GET _version_list 0 ${PNAME}_MAJOR_VERSION )
	list( GET _version_list 1 ${PNAME}_MINOR_VERSION )
	list( GET _version_list 2 ${PNAME}_PATCH_VERSION )

	# cleanup patch version of any extra qualifiers ( -dev -rc1 ... )

	string( REGEX REPLACE "^([0-9]+).*" "\\1" ${PNAME}_PATCH_VERSION "${${PNAME}_PATCH_VERSION}" )

	set( ${PNAME}_VERSION "${${PNAME}_MAJOR_VERSION}.${${PNAME}_MINOR_VERSION}.${${PNAME}_PATCH_VERSION}" CACHE INTERNAL "package ${PNAME} version" )

	set( ${PNAME}_VERSION_STR "${${PROJECT_NAME}_VERSION_STR}" CACHE INTERNAL "package ${PNAME} version string" ) # ignore caps

#    debug_var( ${PNAME}_VERSION )
#    debug_var( ${PNAME}_VERSION_STR )
#    debug_var( ${PNAME}_MAJOR_VERSION )
#    debug_var( ${PNAME}_MINOR_VERSION )
#    debug_var( ${PNAME}_PATCH_VERSION )

	# install dirs for this project

	set( INSTALL_BIN_DIR bin )
	set( INSTALL_LIB_DIR lib )
    set( INSTALL_INCLUDE_DIR include )
	set( INSTALL_DATA_DIR share/${PROJECT_NAME} )
	set( INSTALL_CMAKE_DIR share/${PROJECT_NAME}/cmake )

	mark_as_advanced( INSTALL_BIN_DIR )
	mark_as_advanced( INSTALL_LIB_DIR )
	mark_as_advanced( INSTALL_INCLUDE_DIR )
	mark_as_advanced( INSTALL_DATA_DIR )
	mark_as_advanced( INSTALL_CMAKE_DIR )

	# overrides of install dirs

	foreach( p LIB BIN INCLUDE DATA CMAKE )
		if( ${PNAME}_INSTALL_${p}_DIR )
			set( INSTALL_${p}_DIR ${${PNAME}_INSTALL_${p}_DIR} )
		endif()
	endforeach()

	# warnings for non-relocatable projects

	foreach( p LIB BIN INCLUDE DATA CMAKE )
		if( IS_ABSOLUTE ${INSTALL_${p}_DIR} )
			message( WARNING "Defining INSTALL_${p}_DIR as absolute path '${INSTALL_${p}_DIR}' makes this build non-relocatable, possibly breaking the installation of RPMS and DEB packages" )
		endif()
	endforeach()

	# make relative paths absolute ( needed later on ) and cache them ...
	foreach( p LIB BIN INCLUDE DATA CMAKE )

		set( var INSTALL_${p}_DIR )

		if( NOT IS_ABSOLUTE "${${var}}" )
			set( ${PNAME}_FULL_INSTALL_${p}_DIR "${CMAKE_INSTALL_PREFIX}/${${var}}" CACHE INTERNAL "${PNAME} ${p} full install path" )
		else()
			message( WARNING "Setting an absolute path for ${VAR} in project ${PNAME}, breakes generation of relocatable binary packages (rpm,deb,...)" )
			set( ${PNAME}_FULL_INSTALL_${p}_DIR "${${var}}" CACHE INTERNAL "${PNAME} ${p} full install path" )
		endif()

#        debug_var( ${PNAME}_FULL_INSTALL_${p}_DIR )

	endforeach()

	# correctly set CMAKE_INSTALL_RPATH

	if( ENABLE_RPATHS )

		if( ENABLE_RELATIVE_RPATHS )

			file( RELATIVE_PATH relative_rpath ${${PNAME}_FULL_INSTALL_BIN_DIR} ${${PNAME}_FULL_INSTALL_LIB_DIR} )
			# debug_var( relative_rpath )

			ecbuild_append_to_rpath( ${relative_rpath} )

		else() # make rpaths absolute

		    if( IS_ABSOLUTE ${INSTALL_LIB_DIR} )
		        ecbuild_append_to_rpath( "${INSTALL_LIB_DIR}" )
		    else()
		        ecbuild_append_to_rpath( "${CMAKE_INSTALL_PREFIX}/${INSTALL_LIB_DIR}" ) 
		    endif()

		endif()
    
	endif()

	# debug_var( CMAKE_INSTALL_RPATH )

	# print project header

	message( STATUS "---------------------------------------------------------" )

	if( ${PNAME}_GIT_SHA1_SHORT )
		message( STATUS "[${PROJECT_NAME}] (${${PNAME}_VERSION_STR}) [${${PNAME}_GIT_SHA1_SHORT}]" )
	else()
		message( STATUS "[${PROJECT_NAME}] (${${PNAME}_VERSION_STR})" )
	endif()

endmacro( ecbuild_declare_project )
