SET(CMAKE_DISABLE_SOURCE_CHANGES ON)
SET(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
SET(CMAKE_MACOSX_RPATH ON)
SET(CMAKE_BUILD_TYPE None)

IF(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    SET(CMAKE_CXX_FLAGS "-fcolor-diagnostics")
ENDIF()
SET(CMAKE_CXX_FLAGS "-std=c++14 ${CMAKE_CXX_LINKER_FLAGS} -fno-rtti -fPIC ${CMAKE_CXX_FLAGS}")
SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -fno-rtti")

IF(APPLE)
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden -mmacosx-version-min=12.0")
    SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -mmacosx-version-min=12.0")
ENDIF()

IF(CLANG_AST_BUILD_TYPE STREQUAL "Release")
    SET(CMAKE_CXX_FLAGS "-O3 -DNDEBUG ${CMAKE_CXX_FLAGS}")
    SET(CMAKE_SHARED_LINKER_FLAGS "-s ${CMAKE_SHARED_LINKER_FLAGS}")
ELSE()
    SET(CMAKE_CXX_FLAGS "-O0 -g ${CMAKE_CXX_FLAGS}")
    SET(CMAKE_SHARED_LINKER_FLAGS "-g ${CMAKE_SHARED_LINKER_FLAGS}")
ENDIF()

SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

SET(CLANG_AST_VERSION "0.1")

IF(LLVM_ROOT)
    IF(NOT EXISTS ${LLVM_ROOT}/include/llvm)
        MESSAGE(FATAL_ERROR "LLVM_ROOT (${LLVM_ROOT}) is not a valid LLVM install. Could not find ${LLVM_ROOT}/include/llvm")
    ENDIF()
    MESSAGE("LLVM_ROOT: ${LLVM_ROOT}")
    IF(EXISTS ${LLVM_ROOT}/lib/cmake/llvm)
        SET(LLVM_DIR ${LLVM_ROOT}/lib/cmake/llvm)
    ELSE()
        SET(LLVM_DIR ${LLVM_ROOT}/share/llvm/cmake)
    ENDIF()
    SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${LLVM_DIR}")
    INCLUDE(LLVMConfig)
ELSE()
    FIND_PACKAGE(LLVM REQUIRED CONFIG)
ENDIF()

INCLUDE_DIRECTORIES( ${LLVM_INCLUDE_DIRS} )
LINK_DIRECTORIES( ${LLVM_LIBRARY_DIRS} )
ADD_DEFINITIONS( ${LLVM_DEFINITIONS} )

STRING(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+)?" LLVM_VERSION_RELEASE ${LLVM_PACKAGE_VERSION})

MESSAGE(STATUS "Found LLVM LLVM_PACKAGE_VERSION: ${LLVM_PACKAGE_VERSION} - LLVM_VERSION_RELEASE: ${LLVM_VERSION_RELEASE}")
MESSAGE(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
LLVM_MAP_COMPONENTS_TO_LIBNAMES(llvm_libs core AllTargetsDescs AllTargetsInfos AllTargetsAsmParsers support frontendopenmp option)

SET(CLANG_LIBRARIES
    clangAnalysis
    clangAST
    clangASTMatchers
    clangBasic
    clangCrossTU
    clangDriver
    clangEdit
    clangFormat
    clangFrontend
    clangIndex
    clangParse
    clangRewrite
    clangSerialization
    clangSema
    clangStaticAnalyzerCore
    clangStaticAnalyzerCheckers
    clangStaticAnalyzerFrontend
    clangTooling
    clangToolingCore
    clangToolingInclusions
    clangLex
)

# Contains wrappers for functions/macros used in original clang-tidy CMake files

macro(add_clang_library name)
    cmake_parse_arguments(ARG
        ""
        ""
        "DEPENDS;LINK_LIBS"
        ${ARGN}
        )
    
    add_library(${name} ${ARG_UNPARSED_ARGUMENTS})

endmacro()

function(clang_target_link_libraries target type)
    target_link_libraries(${target} ${type} ${ARGN})
endfunction()

macro(add_clang_tool name)
    add_executable(${name} ${ARGN})
endmacro()

