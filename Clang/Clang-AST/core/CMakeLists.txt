cmake_minimum_required(VERSION 3.0.0)
project(Clang-AST)

SET(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    "${CMAKE_CURRENT_SOURCE_DIR}/../cmake"
    )
INCLUDE(Clang-AST)

IF (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    SET(CMAKE_SHARED_LINKER_FLAGS "-undefined dynamic_lookup")
ENDIF()

macro(build_example name)
    ADD_EXECUTABLE(${name} ${name}.cpp)
    TARGET_LINK_LIBRARIES(${name} ${CLANG_LIBRARIES} ${CMAKE_DL_LIBS} ${REQ_LLVM_LIBRARIES})
endmacro(build_example)

build_example(clang_ast_match)
build_example(clang_ast_re)




