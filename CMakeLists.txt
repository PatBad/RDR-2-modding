cmake_minimum_required(VERSION 3.21)
project(RDR2Mods LANGUAGES CXX)

if(NOT MSVC OR NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "Build with 64-bit MSVC (Visual Studio 2022 or later): run scripts/build.ps1.")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Static runtime: the .asi files don't depend on a Visual C++ Redistributable being installed.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# --- Script Hook RDR2 SDK -------------------------------------------------------------------
set(SHRDR2_LIB "${CMAKE_SOURCE_DIR}/sdk/lib/ScriptHookRDR2.lib" CACHE FILEPATH
    "Path to ScriptHookRDR2.lib from the Script Hook RDR2 SDK")
if(NOT EXISTS "${SHRDR2_LIB}")
    message(FATAL_ERROR
        "ScriptHookRDR2.lib not found at ${SHRDR2_LIB}\n"
        "Download the Script Hook RDR2 SDK from http://www.dev-c.com/rdr2/scripthookrdr2/ and "
        "extract it into the sdk/ folder so that sdk/lib/ScriptHookRDR2.lib exists.")
endif()
add_library(ScriptHookRDR2 INTERFACE)
target_link_libraries(ScriptHookRDR2 INTERFACE "${SHRDR2_LIB}")

# --- Shared code (natives, logging, settings, input, on-screen text) ------------------------
add_library(rdr2shared STATIC
    shared/src/config.cpp
    shared/src/input.cpp
    shared/src/log.cpp
    shared/src/ui.cpp
)
target_include_directories(rdr2shared PUBLIC shared/include)
target_compile_definitions(rdr2shared PUBLIC WIN32_LEAN_AND_MEAN NOMINMAX)
target_compile_options(rdr2shared PUBLIC /W4 /permissive- /utf-8 /MP /bigobj)
target_link_libraries(rdr2shared PUBLIC ScriptHookRDR2)

# --- Mods: every folder in mods/ becomes <FolderName>.asi -----------------------------------
set(MOD_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/$<CONFIG>")

file(GLOB mod_dirs LIST_DIRECTORIES true "${CMAKE_SOURCE_DIR}/mods/*")
foreach(mod_dir IN LISTS mod_dirs)
    if(NOT IS_DIRECTORY "${mod_dir}")
        continue()
    endif()
    get_filename_component(mod_name "${mod_dir}" NAME)
    file(GLOB_RECURSE mod_sources CONFIGURE_DEPENDS "${mod_dir}/*.cpp" "${mod_dir}/*.h")
    if(NOT mod_sources)
        continue()
    endif()

    add_library(${mod_name} SHARED ${mod_sources})
    target_link_libraries(${mod_name} PRIVATE rdr2shared)
    set_target_properties(${mod_name} PROPERTIES
        SUFFIX ".asi"
        RUNTIME_OUTPUT_DIRECTORY "${MOD_OUTPUT_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${MOD_OUTPUT_DIR}"
    )
    if(EXISTS "${mod_dir}/${mod_name}.ini")
        add_custom_command(TARGET ${mod_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${mod_dir}/${mod_name}.ini" "$<TARGET_FILE_DIR:${mod_name}>/${mod_name}.ini")
    endif()
    message(STATUS "Mod: ${mod_name}")
endforeach()
