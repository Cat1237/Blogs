- [`swift-syntax`](#swift-syntax)
  - [`Trivia`](#trivia)
  - [`SyntaxFactory`](#syntaxfactory)
  - [`SwiftSyntaxBuilder`](#swiftsyntaxbuilder)
  - [`SwiftSyntaxParser`](#swiftsyntaxparser)
  - [`SyntaxVisitor`](#syntaxvisitor)
    - [`SyntaxAnyVisitor`](#syntaxanyvisitor)
  - [`SyntaxRewriter`](#syntaxrewriter)

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
```swift
public enum SyntaxKind {
  case token
  case unknown
  case unknownDecl
  case unknownExpr
  case unknownStmt
  case unknownType
  case unknownPattern
  case missing
  case missingDecl
  case missingExpr
  case missingStmt
  case missingType
  case missingPattern
  case codeBlockItem
  case codeBlockItemList
  case codeBlock
  case unexpectedNodes
  case inOutExpr
  case poundColumnExpr
  case tupleExprElementList
  case arrayElementList
  case dictionaryElementList
  case stringLiteralSegments
  case tryExpr
  case awaitExpr
  case moveExpr
  case declNameArgument
  case declNameArgumentList
  case declNameArguments
  case identifierExpr
  case superRefExpr
  case nilLiteralExpr
  case discardAssignmentExpr
  case assignmentExpr
  case sequenceExpr
  case exprList
  case poundLineExpr
  case poundFileExpr
  case poundFileIDExpr
  case poundFilePathExpr
  case poundFunctionExpr
  case poundDsohandleExpr
  case symbolicReferenceExpr
  case prefixOperatorExpr
  case binaryOperatorExpr
  case arrowExpr
  case infixOperatorExpr
  case floatLiteralExpr
  case tupleExpr
  case arrayExpr
  case dictionaryExpr
  case tupleExprElement
  case arrayElement
  case dictionaryElement
  case integerLiteralExpr
  case booleanLiteralExpr
  case unresolvedTernaryExpr
  case ternaryExpr
  case memberAccessExpr
  case unresolvedIsExpr
  case isExpr
  case unresolvedAsExpr
  case asExpr
  case typeExpr
  case closureCaptureItem
  case closureCaptureItemList
  case closureCaptureSignature
  case closureParam
  case closureParamList
  case closureSignature
  case closureExpr
  case unresolvedPatternExpr
  case multipleTrailingClosureElement
  case multipleTrailingClosureElementList
  case functionCallExpr
  case subscriptExpr
  case optionalChainingExpr
  case forcedValueExpr
  case postfixUnaryExpr
  case specializeExpr
  case stringSegment
  case expressionSegment
  case stringLiteralExpr
  case regexLiteralExpr
  case keyPathExpr
  case keyPathBaseExpr
  case objcNamePiece
  case objcName
  case objcKeyPathExpr
  case objcSelectorExpr
  case postfixIfConfigExpr
  case editorPlaceholderExpr
  case objectLiteralExpr
  case typeInitializerClause
  case typealiasDecl
  case associatedtypeDecl
  case functionParameterList
  case parameterClause
  case returnClause
  case functionSignature
  case ifConfigClause
  case ifConfigClauseList
  case ifConfigDecl
  case poundErrorDecl
  case poundWarningDecl
  case poundSourceLocation
  case poundSourceLocationArgs
  case declModifierDetail
  case declModifier
  case inheritedType
  case inheritedTypeList
  case typeInheritanceClause
  case classDecl
  case actorDecl
  case structDecl
  case protocolDecl
  case extensionDecl
  case memberDeclBlock
  case memberDeclList
  case memberDeclListItem
  case sourceFile
  case initializerClause
  case functionParameter
  case modifierList
  case functionDecl
  case initializerDecl
  case deinitializerDecl
  case subscriptDecl
  case accessLevelModifier
  case accessPathComponent
  case accessPath
  case importDecl
  case accessorParameter
  case accessorDecl
  case accessorList
  case accessorBlock
  case patternBinding
  case patternBindingList
  case variableDecl
  case enumCaseElement
  case enumCaseElementList
  case enumCaseDecl
  case enumDecl
  case operatorDecl
  case identifierList
  case operatorPrecedenceAndTypes
  case precedenceGroupDecl
  case precedenceGroupAttributeList
  case precedenceGroupRelation
  case precedenceGroupNameList
  case precedenceGroupNameElement
  case precedenceGroupAssignment
  case precedenceGroupAssociativity
  case tokenList
  case nonEmptyTokenList
  case customAttribute
  case attribute
  case attributeList
  case specializeAttributeSpecList
  case availabilityEntry
  case labeledSpecializeEntry
  case targetFunctionEntry
  case namedAttributeStringArgument
  case declName
  case implementsAttributeArguments
  case objCSelectorPiece
  case objCSelector
  case differentiableAttributeArguments
  case differentiabilityParamsClause
  case differentiabilityParams
  case differentiabilityParamList
  case differentiabilityParam
  case derivativeRegistrationAttributeArguments
  case qualifiedDeclName
  case functionDeclName
  case backDeployAttributeSpecList
  case backDeployVersionList
  case backDeployVersionArgument
  case opaqueReturnTypeOfAttributeArguments
  case labeledStmt
  case continueStmt
  case whileStmt
  case deferStmt
  case expressionStmt
  case switchCaseList
  case repeatWhileStmt
  case guardStmt
  case whereClause
  case forInStmt
  case switchStmt
  case catchClauseList
  case doStmt
  case returnStmt
  case yieldStmt
  case yieldList
  case fallthroughStmt
  case breakStmt
  case caseItemList
  case catchItemList
  case conditionElement
  case availabilityCondition
  case matchingPatternCondition
  case optionalBindingCondition
  case unavailabilityCondition
  case hasSymbolCondition
  case conditionElementList
  case declarationStmt
  case throwStmt
  case ifStmt
  case elseIfContinuation
  case elseBlock
  case switchCase
  case switchDefaultLabel
  case caseItem
  case catchItem
  case switchCaseLabel
  case catchClause
  case poundAssertStmt
  case genericWhereClause
  case genericRequirementList
  case genericRequirement
  case sameTypeRequirement
  case layoutRequirement
  case genericParameterList
  case genericParameter
  case primaryAssociatedTypeList
  case primaryAssociatedType
  case genericParameterClause
  case conformanceRequirement
  case primaryAssociatedTypeClause
  case simpleTypeIdentifier
  case memberTypeIdentifier
  case classRestrictionType
  case arrayType
  case dictionaryType
  case metatypeType
  case optionalType
  case constrainedSugarType
  case implicitlyUnwrappedOptionalType
  case compositionTypeElement
  case compositionTypeElementList
  case compositionType
  case packExpansionType
  case tupleTypeElement
  case tupleTypeElementList
  case tupleType
  case functionType
  case attributedType
  case genericArgumentList
  case genericArgument
  case genericArgumentClause
  case typeAnnotation
  case enumCasePattern
  case isTypePattern
  case optionalPattern
  case identifierPattern
  case asTypePattern
  case tuplePattern
  case wildcardPattern
  case tuplePatternElement
  case expressionPattern
  case tuplePatternElementList
  case valueBindingPattern
  case availabilitySpecList
  case availabilityArgument
  case availabilityLabeledArgument
  case availabilityVersionRestriction
  case versionTuple
}
```

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
专门用来构造`SwiftSyntax`。
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

## `SyntaxVisitor`
调用`visit*`开头的函数，专门用来遍历`Syntax node`。可以指定类型。
### `SyntaxAnyVisitor`
对`visitAny(_)`重新处理，提升速度。

## `SyntaxRewriter`
`SyntaxRewriter`同样调用`visit*`开头的函数，用来遍历`Syntax node`。区别于`SyntaxVisitor`，函数可以返回一个`rewritten node`，用于表示重新处理的`syntax`。

* 将代码`n`修改为`Cat`：
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