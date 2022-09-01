#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/Attr.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/ADT/FunctionExtras.h"
#include "llvm/ADT/STLExtras.h"
#include <cassert>

using namespace clang;

namespace
{
  class ProcessASTAction : public clang::ASTFrontendAction
  {
  public:
    ProcessASTAction(llvm::unique_function<void(clang::ASTContext &)> Process)
        : Process(std::move(Process))
    {
      assert(this->Process);
    }

    std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                   StringRef InFile)
    {
      class Consumer : public ASTConsumer
      {
      public:
        Consumer(llvm::function_ref<void(ASTContext &CTx)> Process)
            : Process(Process) {}

        void HandleTranslationUnit(ASTContext &Ctx) override { 
          Process(Ctx); 
        }
        bool HandleTopLevelDecl(DeclGroupRef DG) override {
          for (DeclGroupRef::iterator I = DG.begin(), E = DG.end(); I != E; ++I) {
            (*I)->print(llvm::errs());
            llvm::errs() << (*I)->getDeclKindName() << "\n";
             if (const NamedDecl *ND = dyn_cast<NamedDecl>(*I)) {
              llvm::errs() << ND->getNameAsString() << "\n";
             }
            
          }
          return true;
        }

      private:
        llvm::function_ref<void(ASTContext &CTx)> Process;
      };

      return std::make_unique<Consumer>(Process);
    }

  private:
    llvm::unique_function<void(clang::ASTContext &)> Process;
  };

  enum class VisitEvent
  {
    StartTraverseFunction,
    EndTraverseFunction,
    StartTraverseAttr,
    EndTraverseAttr
  };

  class CollectInterestingEvents
      : public RecursiveASTVisitor<CollectInterestingEvents>
  {
  public:
    bool TraverseFunctionDecl(FunctionDecl *D)
    {
      Events.push_back(VisitEvent::StartTraverseFunction);
      bool Ret = RecursiveASTVisitor::TraverseFunctionDecl(D);
      Events.push_back(VisitEvent::EndTraverseFunction);

      return Ret;
    }

    bool TraverseAttr(Attr *A)
    {
      Events.push_back(VisitEvent::StartTraverseAttr);
      bool Ret = RecursiveASTVisitor::TraverseAttr(A);
      Events.push_back(VisitEvent::EndTraverseAttr);

      return Ret;
    }

    std::vector<VisitEvent> takeEvents() && { return std::move(Events); }

  private:
    std::vector<VisitEvent> Events;
  };

  std::vector<VisitEvent> collectEvents(llvm::StringRef Code)
  {
    CollectInterestingEvents Visitor;
    clang::tooling::runToolOnCode(
        std::make_unique<ProcessASTAction>(
            [&](clang::ASTContext &Ctx)
            { Visitor.TraverseAST(Ctx); }),
        Code);
    return std::move(Visitor).takeEvents();
  }
} // namespace

int main(int argc, const char **argv)
{
  llvm::StringRef Code = R"cpp(
__attribute__((annotate("something"))) int foo() { return 10; }
  )cpp";
  std::vector<VisitEvent> event = collectEvents(Code);
}