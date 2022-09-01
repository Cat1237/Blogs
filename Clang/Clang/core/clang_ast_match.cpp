#include <string>
#include <unistd.h>
#include <clang/Driver/Compilation.h>
#include <clang/Driver/Driver.h>
#include <clang/Driver/Job.h>
#include <clang/Driver/Tool.h>
#include "clang/AST/AST.h"
#include <clang/Basic/TargetInfo.h>
#include "clang/AST/ASTConsumer.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include "clang/ASTMatchers/ASTMatchers.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/CompilationDatabase.h"
#include "clang/Tooling/Tooling.h"
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Host.h>
#include <llvm/Support/raw_ostream.h>
#include <clang/AST/RecursiveASTVisitor.h>

using namespace llvm;
using namespace clang;
using namespace clang::ast_matchers;
using namespace clang::driver;
using namespace clang::tooling;

class IfStmtHandler : public MatchFinder::MatchCallback, protected clang::RecursiveASTVisitor<IfStmtHandler>
{
    friend class clang::RecursiveASTVisitor<IfStmtHandler>;

public:
    IfStmtHandler(Rewriter &Rewrite) : Rewrite(Rewrite) {}
    void setUpMatcher()
    {
        _finder = new clang::ast_matchers::MatchFinder();
        _finder->addMatcher(ifStmt().bind("ifStmt"), this);
    }
    void traverse(clang::ASTContext *c, clang::Decl *decl)
    {
        _astContext = c;
        (void)/* explicitly ignore the return of this function */
            clang::RecursiveASTVisitor<IfStmtHandler>::TraverseDecl(decl);
    }
    bool VisitDecl(Decl *decl)
    {
        _finder->match(*decl, *_astContext);
        return true;
    }

    bool VisitStmt(Stmt *stmt)
    {
        _finder->match(*stmt, *_astContext);
        return true;
    }
    virtual void run(const MatchFinder::MatchResult &Result)
    {
        if (const IfStmt *IfS = Result.Nodes.getNodeAs<clang::IfStmt>("ifStmt"))
        {
            const Stmt *Then = IfS->getThen();
            Rewrite.InsertText(IfS->getIfLoc(), "// the 'if' part\n", true, true);

            if (const Stmt *Else = IfS->getElse())
            {
                Rewrite.InsertText(IfS->getElseLoc(), "// the 'else' part\n", true, true);
            }
        }
    }

private:
    Rewriter &Rewrite;
    clang::ast_matchers::MatchFinder *_finder;
    clang::ASTContext *_astContext;
};

static std::vector<std::string> adjustArguments(std::vector<std::string> &unadjustedCmdLine,
                                                const std::string &filename)
{
    clang::tooling::ArgumentsAdjuster argAdjuster =
        clang::tooling::combineAdjusters(
            clang::tooling::getClangStripOutputAdjuster(),
            clang::tooling::getClangSyntaxOnlyAdjuster());
    return argAdjuster(unadjustedCmdLine, filename);
}
std::string stringReplace(std::string orig, std::string oldStr, std::string newStr)
{
    std::string::size_type pos(orig.find(oldStr));

    while (pos != std::string::npos)
    {
        orig.replace(pos, oldStr.length(), newStr);
        pos = orig.find(oldStr, pos + newStr.length());
    }

    return orig;
}
static const llvm::opt::ArgStringList *getCC1Arguments(clang::driver::Compilation *compilation)
{
    /**
     * 在只有源文件作为输入的 `Compilation` 中检索 `-cc1` 作业的标志。
     * 如果没有此类(job)或多个(jobs)，则返回 nullptr。请注意，offload 将被忽略。
     * 命令(Command) - 要执行的可执行路径/名称和参数向量。
     *  来源(Action Source) - 导致创建此作业的操作。
     *  工具(Tool Creator) - 导致创建此作业的工具。
     */
    const clang::driver::JobList &jobList = compilation->getJobs();
    for (const driver::Command &Job : jobList)
    {
        llvm::outs() << Job.getExecutable();
    }

    auto jobSize = jobList.size();

    if (jobSize == 0)
    {
        llvm::errs() << "compilation contains no job";
    }

    bool offloadCompilation = false;
    if (jobSize > 1)
    {
        auto actions = compilation->getActions();
        for (auto action : actions)
        {
            if (llvm::isa<clang::driver::OffloadAction>(action))
            {
                assert(actions.size() > 1);
                offloadCompilation = true;
                break;
            }
        }
    }
    if (jobSize > 1 && !offloadCompilation)
    {
        llvm::errs() << "compilation contains multiple jobs";
    }

    if (!clang::isa<clang::driver::Command>(*jobList.begin()))
    {
        llvm::errs() << "compilation job does not contain correct command";
    }

    const clang::driver::Command &cmd = clang::cast<clang::driver::Command>(*jobList.begin());
    if (llvm::StringRef(cmd.getCreator().getName()) != "clang")
    {
        llvm::errs() << "expected a command for clang compiler";
    }
    return &cmd.getArguments();
}
static cl::OptionCategory CatToolCategory("Cat tool options", "Cat tool description");
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);
static cl::extrahelp MoreHelp("\nMore help text...\n");
static llvm::cl::opt<bool> args("cat",
                                llvm::cl::desc("该参数的描述信息"),
                                llvm::cl::init(false),
                                llvm::cl::cat(CatToolCategory));
typedef std::vector<std::pair<std::string, clang::tooling::CompileCommand>> CompileCommandPairs;
int main(int argc, const char **argv)
{
    auto op = CommonOptionsParser::create(argc, argv, CatToolCategory);
    if (!op)
    {
        llvm::errs() << op.takeError();
        return -1;
    }
    clang::tooling::CompilationDatabase &compilationDatabase = op->getCompilations();
    llvm::ArrayRef<std::string> sourcePaths = op->getSourcePathList();
    CompileCommandPairs compileCommands;
    for (const auto &sourcePath : sourcePaths)
    {
        std::string filePath(clang::tooling::getAbsolutePath(sourcePath));
        // FixedCompilationDatabase
        // frame variable -d run-target compilationDatabase
        std::vector<clang::tooling::CompileCommand> compileCmdsForFile =
            compilationDatabase.getCompileCommands(filePath);
        if (compileCmdsForFile.empty())
        {
            llvm::errs() << "Skipping " << filePath << ". Compile command not found.\n";
            continue;
        }
        for (auto &compileCommand : compileCmdsForFile)
        {
            compileCommands.push_back(std::make_pair(filePath, compileCommand));
        }
    }
    for (auto &compileCommand : compileCommands)
    {
        /**
         * 一个命令行调整器的原型。
         * 命令行参数调整器负责在参数用于运行前端操作之前修改命令行参数。
         * 获取一个参数调整器，它删除与输出相关的命令行参数。
         * 获取将输入命令行参数转换为“仅语法检查”变体的参数调整器。
         *
         */
        std::vector<std::string> adjustedCmdLine =
            adjustArguments(compileCommand.second.CommandLine, compileCommand.first);

        std::string targetDir = stringReplace(compileCommand.second.Directory, "\\ ", " ");

        if (chdir(targetDir.c_str()))
        {
            llvm::errs() << "Cannot change dictionary into";
        }
        std::vector<std::string> commandLine = adjustedCmdLine;
        assert(!commandLine.empty() && "Command line must not be empty!");
        // commandLine[0] = mainExecutable;

        std::vector<const char *> argv;
        int start = 0, end = commandLine.size();
        for (int cmdIndex = start; cmdIndex != end; cmdIndex++)
        {
            if (commandLine[cmdIndex] != "-gmodules")
            {
                argv.push_back(commandLine[cmdIndex].c_str());
            }
        }

        // 用于控制编译器诊断引擎的选项。
        llvm::IntrusiveRefCntPtr<clang::DiagnosticOptions> diagOpts =
            new clang::DiagnosticOptions();
        // 前端用来报告问题和问题的具体类。
        // 例如，处理“将警告作为错误报告”之类的事情，并将它们传递给 DiagnosticConsumer 以向用户报告。DiagnosticsEngine 与一个翻译单元和一个 SourceManager 相关联。
        clang::DiagnosticsEngine diagnosticsEngine(
            llvm::IntrusiveRefCntPtr<clang::DiagnosticIDs>(new clang::DiagnosticIDs()),
            &*diagOpts,
            new clang::DiagnosticConsumer());

        // 构建一个为运行 clang 工具而初始化的 clang 驱动程序。
        const char *const mainBinaryPath = argv[0];
        clang::driver::Driver *driver =
            new clang::driver::Driver(mainBinaryPath, llvm::sys::getDefaultTargetTriple(), diagnosticsEngine);
        driver->setTitle("Cat");
        // 构建编译作业时是否检查输入文件是否存在。
        driver->setCheckInputsExist(false);

        // 为单个驱动程序调用执行的一组任务。
        // BuildCompilation: 通过编译参数构建Compilation
        const std::unique_ptr<clang::driver::Compilation> compilation(
            driver->BuildCompilation(llvm::makeArrayRef(argv)));
        auto cc1Args = getCC1Arguments(compilation.get());
        // 返回从 CC1 标志初始化的 clang 构建调用。
        CompilerInvocation *compilerInvocation = new clang::CompilerInvocation;
        clang::CompilerInvocation::CreateFromArgs(*compilerInvocation, *cc1Args, diagnosticsEngine);

        // 退出时禁用内存释放
        compilerInvocation->getFrontendOpts().DisableFree = false;
        // Create the compiler instance to use for building the AST.
        std::unique_ptr<CompilerInstance> compilerInstance(new clang::CompilerInstance());
        // 用于保存调用编译器所需数据的帮助类。此类旨在表示编译器的抽象“调用”，包括诸如包含路径、代码生成选项、警告标志等数据。
        auto invocation = std::unique_ptr<clang::CompilerInvocation>(compilerInvocation);
        compilerInstance->setInvocation(std::move(invocation));
        compilerInstance->createDiagnostics(new clang::DiagnosticConsumer());
        if (!compilerInstance->hasDiagnostics())
        {
            llvm::errs() << "cannot create compiler diagnostics";
        }
        compilerInstance->setTarget(clang::TargetInfo::CreateTargetInfo(compilerInstance->getDiagnostics(), compilerInstance->getInvocation().TargetOpts));
        if (!compilerInstance->hasTarget())
        {
            return -1;
        }
        compilerInstance->getTarget().adjust(compilerInstance->getDiagnostics(), compilerInstance->getLangOpts());
        if (auto *auxTarget = compilerInstance->getAuxTarget())
        {
            compilerInstance->getTarget().setAuxTarget(auxTarget);
        }
        // The input files and their types
        for (const auto &input : compilerInstance->getFrontendOpts().Inputs)
        {
            if (compilerInstance->hasSourceManager())
            {
                compilerInstance->getSourceManager().clearIDTables();
            }

            std::unique_ptr<SyntaxOnlyAction> Act;
            Act.reset(new SyntaxOnlyAction);
            if (Act->BeginSourceFile(*compilerInstance.get(), input))
            {
                if (llvm::Error Err = Act->Execute())
                {
                    llvm::errs() << Err;
                }
            }
        }
        std::vector<clang::CompilerInstance *> compilers;
        // Act->EndSourceFile();
        // Notify the diagnostic client that all files were processed.
        // compilerInstance->getDiagnostics().getClient()->finish();
        if (!compilerInstance->getDiagnostics().hasErrorOccurred() && compilerInstance->hasASTContext())
        {
            compilers.push_back(compilerInstance.get());
        }
        std::vector<clang::ASTContext *> localContexts;
        Rewriter TheRewriter;
        TheRewriter.setSourceMgr(compilerInstance->getSourceManager(), compilerInstance->getLangOpts());
        IfStmtHandler Visitor = IfStmtHandler(TheRewriter);
        Visitor.setUpMatcher();
        for (auto compiler : compilers)
        {
            clang::ASTContext *context = &compiler->getASTContext();
            clang::DeclContext *tu = context->getTranslationUnitDecl();
            for (clang::DeclContext::decl_iterator it = tu->decls_begin(), declEnd = tu->decls_end(); it != declEnd; ++it)
            {
                clang::Decl *decl = *it;
                clang::SourceManager *sourceManager = &context->getSourceManager();
                clang::SourceLocation startLocation = decl->getBeginLoc();
                bool isValidDecl = startLocation.isValid() && sourceManager->isInMainFile(startLocation);
                Visitor.traverse(context, decl);
            }
        }
        const RewriteBuffer *RewriteBuf =
            TheRewriter.getRewriteBufferFor(compilerInstance->getSourceManager().getMainFileID());
        llvm::outs() << std::string(RewriteBuf->begin(), RewriteBuf->end());
    }
    return 0;
}
