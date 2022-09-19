cmake_minimum_required(VERSION 3.0.0)
project(Clang-Tidy)

SET(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    "${CMAKE_CURRENT_SOURCE_DIR}/../cmake"
    )
INCLUDE(Clang-Tidy)

IF (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    SET(CMAKE_SHARED_LINKER_FLAGS "-undefined dynamic_lookup")
ENDIF()

add_subdirectory(custom)
set(ALL_CLANG_TIDY_CHECKS
 clangTidyCustomModule
)
add_subdirectory(tool)




