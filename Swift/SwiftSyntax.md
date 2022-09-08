# `swift-syntax`
`swift-syntax`实际上提供了一组`Swift API`来使用`libSyntax`表示`Swift`语法。
* 语法`（syntax）`
    * 可以使用的关键字、语法糖等等
    * 在编译时确定编写代码是否满足语法要求
    * 上下文无关
* 语义`（semantics）`
    * 代码具体含义
    * 运行时确定，上下文关联

传统的`AST`结构可以并没有很清晰的对`syntax`和`semantics`做明确的区分。例如`Swift`中的`libAST`。

`libSyntax`实际上想要通过将`syntax`和`semantics`分离。实现更好的稳定性以及适用性。对`Syntax node`有如下类型：
* Expression
    * NilLiteralExpr
    * IntegerLiteralExpr
    * FloatLiteralExpr
    * BooleanLiteralExpr
    * StringLiteralExpr
    * DiscardAssignmentExpr
    * DeclRefExpr
    * IfExpr
    * AssignExpr
    * TypeExpr
    * UnresolvedMemberExpr
    * SequenceExpr
    * TupleElementExpr
    * TupleExpr
    * ArrayExpr
    * DictionaryExpr
    * PrefixUnaryExpr
    * TryExpr
    * ForceTryExpr
    * OptionalTryExpr
    * ClosureExpr
    * FunctionCallExpr
    * SubscriptExpr
    * DotSelfExpr
    * PostfixUnaryExpr
    * ForcedValueExpr
    * SuperRefExpr
    * ImplicitMemberExpr
    * KeyPathExpr
    * KeyPathDotExpr
    * InOutExpr
    * EditorPlaceholderExpr
    * ObjectLiteralExpr
    * MagicIdentifierLiteralExpr
    * SpecializeExpr
    * UnresolvedPatternExpr
    * IsExpr
    * AsExpr
    * ArrowExpr
    * ObjCSelectorExpr
* Declaration
    * TopLevelCodeDecl
    * ClassDecl
    * StructDecl
    * FuncDecl
    * ProtocolDecl
    * ImportDecl
    * AssociatedTypeDecl
    * TypeAliasDecl
    * IfConfigDecl
    * PatternBindingDecl
    * VarDecl
    * ExtensionDecl
    * SubscriptDecl
    * ConstructorDecl
    * DestructorDecl
    * EnumDecl
    * EnumCaseDecl
    * OperatorDecl
    * PrecedenceGroupDecl
* Statement
    * BraceStmt
    * ReturnStmt
    * DeferStmt
    * DoStmt
    * RepeatWhileStmt
    * BreakStmt
    * ContinueStmt
    * FallthroughStmt
    * ThrowStmt
    * IfStmt
    * GuardStmt
    * WhileStmt
    * ForInStmt
    * SwitchStmt
    * YieldStmt
* Pattern
    * IdentifierPattern
    * WildcardPattern
    * TuplePattern
    * ExpressionPattern
    * ValueBindingPattern
    * IsTypePattern
    * AsTypePattern
    * OptionalPattern
    * EnumCasePattern
* TypeRepr
    * SimpleTypeIdentifier
    * MemberTypeIdentifier
    * ArrayType
    * DictionaryType
    * MetatypeType
    * OptionalType
    * ImplicitlyUnwrappedOptionalType
    * CompositionType
    * TupleType
    * FunctionType
    * AttributedType

## `Trivia`
并不影响语义的语法，例如：
* Spaces
* Tabs
* Newlines
* Single-line developer (//) comments
* Block developer (/* ... */) comments
* Single-line documentation (///) comments
* Block documentation (/** ... */) comments
* Backticks

## `SyntaxFactory`
用来构造新的`SwiftSyntax`和`Token`的工厂方法。每个`SwiftSyntax`节点都有两个主要的`make`开发头的`API`。例如`makeStructDecl`和`makeBlankStructDecl`都返回`StructDeclSyntax`。
使用工厂方法修改`let`变成`var`：
```swift
// 创建表达式
let identifierPattern = SyntaxFactory.makeIdentifierPattern(
    identifier: SyntaxFactory.makeIdentifier("a")
        .withLeadingTrivia(.spaces(1))
)
// 创建表达式类型
let Pattern = SyntaxFactory.makePatternBinding(
    pattern: PatternSyntax(identifierPattern),
    typeAnnotation: SyntaxFactory.makeTypeAnnotation(
        colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
        type: SyntaxFactory.makeTypeIdentifier("Int")),
    initializer: nil, accessor: nil, trailingComma: nil)
// 使用let关键字声明变量
var variableDeclSyntax = VariableDeclSyntax {
    $0.useLetOrVarKeyword(SyntaxFactory.makeLetKeyword())
    $0.addBinding(Pattern)
}
print("\(variableDeclSyntax)")
// 将let改为var
variableDeclSyntax.letOrVarKeyword = SyntaxFactory.makeVarKeyword().withTrailingTrivia(.spaces(0))
print("\(variableDeclSyntax)")
```
输出：
```swift
let a: Int
var a: Int
```

## `SwiftSyntaxBuilder`
专门用来构造`SwiftSyntax`
使用`ArrowExpr`：
```swift
// 创建一个无用字符，放在->的最左边
let leadingTrivia = Trivia.garbageText("␣")
// 创建ArrowExpr和`async`关键字
let builder = ArrowExpr(asyncKeyword: "async")
let arrowExpr = builder.createArrowExpr()
// 生成Syntax
let syntax = arrowExpr.buildSyntax(format: Format(), leadingTrivia: leadingTrivia)
var text = ""
syntax.write(to: &text)
```
这将会输出：
```txt
␣async-> 
```
生成`fibonacci`函数：
```swift
// 参数语句
let input = ParameterClause(parameterListBuilder: {
  FunctionParameter(firstName: .wildcard, secondName: .identifier("n"), colon: .colon, type: "Int", attributesBuilder: {})
})
// 函数体，if语句函数体
let ifCodeBlock = ReturnStmt(expression: IntegerLiteralExpr(digits: "n"))
// 函数签名
let signature = FunctionSignature(input: input, output: "Int")
// 函数体    
let codeBlock = CodeBlock(statementsBuilder: {
  // 函数体，if语句
  IfStmt(conditions: ExprList([
    IntegerLiteralExpr(digits: "n"),

    BinaryOperatorExpr("<="),

    IntegerLiteralExpr(1)
  ]), body: ifCodeBlock)
  // 函数体，返回语句
  ReturnStmt(expression: SequenceExpr(elementsBuilder: {
    // fibonacci(n - 1)
    FunctionCallExpr(calledExpression: IdentifierExpr("fibonacci"), leftParen: .leftParen, rightParen: .rightParen, argumentListBuilder: {
      TupleExprElement(expression: SequenceExpr(elementsBuilder: {
        IntegerLiteralExpr(digits: "n")

        BinaryOperatorExpr("-")

        IntegerLiteralExpr(1)
      }))
    })

    BinaryOperatorExpr("+")
    // fibonacci(n - 2)
    FunctionCallExpr("fibonacci", leftParen: .leftParen, rightParen: .rightParen, argumentListBuilder: {
      TupleExprElement(expression: SequenceExpr(elementsBuilder: {
        IntegerLiteralExpr(digits: "n")

        BinaryOperatorExpr("-")

        IntegerLiteralExpr(2)
      }))
    })
  }))
})
// 函数声明
let buildable = FunctionDecl(identifier: .identifier("fibonacci"), signature: signature, body: codeBlock, attributesBuilder: {})
// 生成语句
let syntax = buildable.buildSyntax(format: Format())
```
将会生成：
```swift
func fibonacci(_ n: Int)-> Int{
    if n <= 1{
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}
```

## `SwiftSyntaxParser`
用来解析和遍历`Swift`代码，生成语法树。
```swift
let source = "struct A { func f() {} }"
let tree = try! SyntaxParser.parse(source: source)
print("\(tree.firstToken!)")
print("\(tree.firstToken!.nextToken!)")
```
输出：
```text
struct 
A 
```
`SyntaxRewriter`调用`visit*`开头的函数，专门用来遍历`Syntax node`。可以指定类型。
遍历并修改代码：
```swift
class VisitAnyRewriter: SyntaxRewriter {
  let transform: (TokenSyntax) -> TokenSyntax
  init(transform: @escaping (TokenSyntax) -> TokenSyntax) {
    self.transform = transform
  }
  override func visitAny(_ node: Syntax) -> Syntax? {
    if let tok = node.as(TokenSyntax.self), tok.tokenKind != .eof  {
         return Syntax(transform(tok))
    }
    return nil
  }
}
let parsed = try! SyntaxParser.parse(source: "n")
let rewriter = VisitAnyRewriter(transform: { _ in
 return SyntaxFactory.makeIdentifier("Cat")
})
let rewritten = rewriter.visit(parsed)
```
将会输出：
```swift
Cat
```