
add_clang_library(clangTidyMain
  ClangTidyMain.cpp

  LINK_LIBS
  clangTidy
  ${ALL_CLANG_TIDY_CHECKS}

  DEPENDS
  omp_gen
  )


clang_target_link_libraries(clangTidyMain
  PRIVATE
  ${CLANG_LIBRARIES}
  )

add_clang_tool(clang-tidy
  ClangTidyToolMain.cpp
)

target_link_libraries(clang-tidy
  PRIVATE
  clangTidy
  clangTidyMain
  ${llvm_libs}
  ${ALL_CLANG_TIDY_CHECKS}
  )
