import SwiftSyntax
import SwiftSyntaxParser
import SwiftSyntaxBuilder

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

// 创建一个无用字符，放在->的最左边
let leadingTrivia = Trivia.garbageText("␣")
// 创建ArrowExpr和`async`关键字
let builder = ArrowExpr(asyncKeyword: "async")
let arrowExpr = builder.createArrowExpr()
// 生成Syntax
let a_syntax = arrowExpr.buildSyntax(format: Format(), leadingTrivia: leadingTrivia)
var text = ""
a_syntax.write(to: &text)
print("\(text)")

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
print("\(syntax)")


let source = "struct A { func f() {} }"
let tree = try! SyntaxParser.parse(source: source)
print("\(tree.firstToken!)")
print("\(tree.firstToken!.nextToken!)")
