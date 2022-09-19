//===--- MiscTidyModule.cpp - clang-tidy ----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "../../clang-tidy/ClangTidy.h"
#include "../../clang-tidy/ClangTidyModule.h"
#include "../../clang-tidy/ClangTidyModuleRegistry.h"
#include "CatCheckCheck.h"


namespace clang {
namespace tidy {
namespace custom {

class CustomModule : public ClangTidyModule {
public:
  void addCheckFactories(ClangTidyCheckFactories &CheckFactories) override {
    CheckFactories.registerCheck<CatCheckCheck>(
        "custom-cat-check");
  }
};

} // namespace custom

// Register the CustomModule using this statically initialized variable.
static ClangTidyModuleRegistry::Add<custom::CustomModule>
    X("custom-module", "Adds CustomModule lint checks.");

// This anchor is used to force the linker to link in the generated object file
// and thus register the CustomModule.
volatile int CustomModuleAnchorSource = 0;

} // namespace tidy
} // namespace clang
