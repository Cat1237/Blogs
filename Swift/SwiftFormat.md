# `swift-format`
`swift-format`与`clang-format`功能类似，但是是基于[`SwiftSyntax`](./SwiftSyntax.md)，对`Swift`代码进格式化，同时可以`lint` `Swift`代码是否存在违规的工具。

`swift-format`在进行`lint`或格式化`Swift`代码文件，会在当前目录查找名称为`.swift-format`的`json`文件。如果找到，加载格式化配置。如果未找到，则在父目录中查找，依此类推。

## `.swift-format`文件
实例文件：
```json
{
    "version": 1,
    "lineLength": 100,
    "indentation": {
        "spaces": 2
    },
    "maximumBlankLines": 1,
    "respectsExistingLineBreaks": true,
    "lineBreakBeforeControlFlowKeywords": true,
    "lineBreakBeforeEachArgument": true
}
```

`.swift-format`有以下配置选项：
* `version`：`_(number)_`。配置文件的版本。当前是1
* `lineLength`：`_(number)_`。行的最大允许长度，以字符为单位，例如：
    ```swift
    func foo() {
      let a = b as Int
      a = b as Int
      let reallyLongVariableName = x as ReallyLongTypeName
      reallyLongVariableName = x as ReallyLongTypeName
    }
    ```
    
    在设置`lineLength`为`40`时，代码会被格式化为：
    ```swift
    func foo() {
      let a = b as Int
      a = b as Int
      let reallyLongVariableName =
        x as ReallyLongTypeName
      reallyLongVariableName =
        x as ReallyLongTypeName
    }
    ```

* `indentation`：`_(object)_`。缩进一级时应添加的空格的种类和数量。**此属性可以配置如下`key`**：
    * `spaces`：` _(number)_`。一级缩进是给定的空格数
    * `tabs`： `_(number)_`。一级缩进是给定的制表符数

*   `tabWidth`：`_(number)_`。一个制表符的空格数
*   `maximumBlankLines`：`_(number)_`。文件中允许出现的最大连续空白行数
*   `respectsExistingLineBreaks`：`_(boolean)_`。遵守当前代码的换行方式。设置为`false`，则将代码换行交给工具自行判断，可能会删除或新增换行。例如：
    ```swift
    a = b + c
      + d
      + e + f + g
      + h + i
    ```
    设置`linelength`为`6`，`respectsExistingLineBreaks`为`true`，代码将会被格式化为：
    ```swift
    a =
      b + c
      + d
      + e + f
      + g
      + h + i
      
    ```
    设置`linelength`为`19`，`respectsExistingLineBreaks`为`false`，代码将会被格式化为：
    ```swift
    a =
      b + c + d + e + f + g
      + h + i
      
    ```
*   `lineBreakBeforeControlFlowKeywords`：`_(boolean)_`。确定右大括号后的控制流关键字的换行行为，例如`else`、`catch`。如果为`true`，将在关键字之前添加一个换行符，强制它进入自己的行。如果为`false`（默认值），则关键字将放置在右大括号之后（由空格分隔）。例如：
    ```Swift
    if var1 < var2 {
      let a = 23
    } else if d < e {
      var b = 123
    } else {
      var c = 456
    }
    ```
    设置`lineBreakBeforeControlFlowKeywords`为`true`，代码将会被格式化为：
    ```swift
    if var1 < var2 {
      let a = 23
    }
    else if d < e {
      var b = 123
    }
    else {
      var c = 456
    }
    ```
*   `lineBreakBeforeEachArgument`：`_(boolean)_`。在多行情况下，确定参数的换行行为。如果为`true`，将在每个参数之前添加一个换行符，进行垂直排列。如果为`false`（默认值），参数将首先水平布局，仅当超过行长时才会触发换行符，例如：
    ```swift
    @available(iOS 9.0, *)
    func f() {}
    @available(*,unavailable, renamed:"MyRenamedProtocol")
    func f() {}
    ```
    在设置`linelength`为`26`，`lineBreakBeforeEachArgument`为`true`，将会格式化为：
    ```swift
    @available(iOS 9.0, *)
    func f() {}
    @available(
      *,
      unavailable,
      renamed: "MyRenamedProtocol"
    )
    func f() {}
    ```
*   `lineBreakBeforeEachGenericRequirement`：`_(boolean)_`。指明修饰符/限定符（`Requirement`）的排列方式。如果为`true`，将在每个`Requirement`之前添加一个换行符，强制垂直布局。如果为`false`（默认值），则要求将首先水平布局，仅当超过行长时才会触发换行符，例如：
    ```swift
    class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
      let A: Int
      let B: Double
    }
    ```
    设置`linelength`为`54`，`lineBreakBeforeEachGenericRequirement`为`true`：
    ```swift
    class MyClass<S, T>
    where S: Collection, T: ReallyLongClassName {
      let A: Int
      let B: Double
    }
    ```
*   `prioritizeKeepingFunctionOutputTogether`：`_(boolean)_`。指明是否应设置，函数的声明与（右）括号一起。如果为`false`（默认），则函数不优先与右括号一起，当超过行长时，会在先触发换行，缩进声明。如果为`true`，则在函数的达到最大长度时，将在函数的参数中进一步触发换行符，例如：
    ```swift
    func name<R>(_ x: Int) throws -> R
    
    func name<R>(_ x: Int) throws -> R {
      statement
      statement
    }
    ```
    设置`linelength`为`23`，`prioritizeKeepingFunctionOutputTogether`为`true`：
    ```swift
    func name<R>(
      _ x: Int
    ) throws -> R
    
    func name<R>(
      _ x: Int
    ) throws -> R {
      statement
      statement
    }
    
    ```

*   `indentConditionalCompilationBlocks` _(boolean)_：确定`#if`块是否缩进。如果此设置是`false`，`#if`，`#elseif`和`#else`不缩进。默认为`true`，例如：
    ```swift
    #if someCondition
      let a = 123
      let b = "abc"
    #endif
    ```
    设置`linelength`为`39`，`indentConditionalCompilationBlocks`为`false`时：
    ```swift
    #if someCondition
    let a = 123
    let b = "abc"
    #endif
    
    ```
*  `lineBreakAroundMultilineExpressionChainComponents`：`_(boolean)_`。通过点语法进行链式调用时是否换行。当为`true`时，将在`.`之前强制换行。例如：
    ```swift
    let result = [1, 2, 3, 4, 5].filter { $0 % 2 == 0 }.map { $0 * $0 }
    ```
    设置`linelength`为`14`，`lineBreakAroundMultilineExpressionChainComponents`为`true`时：
    ```swift
    let result = [
      1, 2, 3, 4, 5,
    ]
    .filter {
      $0 % 2 == 0
    }
    .map { $0 * $0 } 
    ```
    
## `swift-format rule`
在`swift-format`有两种类型的`rule`：
* `SyntaxFormatRule`，继承自`SwiftSyntax`中的[`SyntaxRewriter`](./SwiftSyntax.md/#syntaxrewriter)类和`Rule`根协议。用于`format`和`lint`
* `SyntaxLintRule`，继承自`SwiftSyntax`中的[`SyntaxVisitor`](./SwiftSyntax.md/#syntaxvisitor)类和`Rule`根协议。仅用于`lint`

接下来，来看一下，`swift-format`是如何定义`rule`的。
### [`DoNotUseSemicolons`](https://github.com/apple/swift-format/blob/main/Sources/SwiftFormatRules/DoNotUseSemicolons.swift)
在`Swift`中，不应该出现`;`(`semicolon`)。这个内置的`rule`的作用是将所有分号替换换行符。
首先来看`Rule`根协议：
```swift
public protocol Rule {
  /// 当前`rule`执行的上下文环境（配置信息）
  var context: Context { get }

  /// `rule`的显示名称
  static var ruleName: String { get }

  /// 默认是否使用
  static var isOptIn: Bool { get }

  init(context: Context)
}
```
然后来看`SyntaxFormatRule`类：
```swift
open class SyntaxFormatRule: SyntaxRewriter, Rule {
  /// 所有继承`SyntaxFormatRule`的都不是默认开启的
  open class var isOptIn: Bool {
    return false
  }
  
  public let context: Context

  public required init(context: Context) {
    self.context = context
  }
 /// 实现`SyntaxRewriter`的`visitAny`函数，用于遍历和修改`syntax node`
  open override func visitAny(_ node: Syntax) -> Syntax? {
    // 没有启用该`rule`，对当前`node`不做处理
    context.isRuleEnabled(type(of: self), node: node) else { return node }
    return nil
  }
}
```
接下来，来看[`DoNotUseSemicolons`](https://github.com/apple/swift-format/blob/main/Sources/SwiftFormatRules/DoNotUseSemicolons.swift)类。
首先要清楚一点，在编写`Swift`代码时，什么情况下，会添加分号？
* `MemberDecl`：声明变量，可以添加分号
* `CodeBlock`：在代码块中编写的每一行代码

那就意味着，需要使用[`SyntaxRewriter`](./SwiftSyntax.md/#syntaxrewriter)遍历和修改着两种类型的`Syntax`。所以，`DoNotUseSemicolons`实际上重新了[`SyntaxRewriter`](./SwiftSyntax.md/#syntaxrewriter)两个函数：
* `func visit(_ node: CodeBlockItemListSyntax) -> Syntax`
* `func visit(_ node: MemberDeclListSyntax) -> Syntax`

用来获取同时修改这两种情况下的`Syntax`。

接下来来看核心代码`nodeByRemovingSemicolons`：
```swift
var newItems = Array(node)

// 因为换行符属于新行上的 _first_ 标记，如果要删除分号，就需要跟踪下一条语句是否需要换行var previousHadSemicolon = false
for (idx, item) in node.enumerated() {

  // 存储前一个语句的分号
  defer { previousHadSemicolon = item.semicolon != nil }

  // 判断当前item内的代码是否存在分号，会递归调用`nodeByRemovingSemicolons`
  guard let visitedItem = visit(Syntax(item)).as(ItemType.self) else {
    return node
  }

  // 判断是否需要进行修改（删除分号/添加换行符）
  guard visitedItem != item || item.semicolon != nil || previousHadSemicolon else {
    continue
  }

  var newItem = visitedItem
  defer { newItems[idx] = newItem }

  // 判断语句`leading`的`trivia`是否能添加换行符
  if previousHadSemicolon, let firstToken = newItem.firstToken,
    !firstToken.leadingTrivia.containsNewlines
  {
    let leadingTrivia = .newlines(1) + firstToken.leadingTrivia
    newItem = replaceTrivia(
      on: newItem,
      token: firstToken,
      leadingTrivia: leadingTrivia
    )
  }

  // 删除分号
  if let semicolon = item.semicolon {

    // 如果分号将“do”语句与“while”语句分开，不进行删除
    if Syntax(item).as(CodeBlockItemSyntax.self)?
      .children(viewMode: .sourceAccurate).first?.is(DoStmtSyntax.self) == true,
      idx < node.count - 1
    {
      let children = node.children(viewMode: .sourceAccurate)
      let nextItem = children[children.index(after: item.index)]
      if Syntax(nextItem).as(CodeBlockItemSyntax.self)?
        .children(viewMode: .sourceAccurate).first?.is(WhileStmtSyntax.self) == true
      {
        continue
      }
    }

    newItem = newItem.withSemicolon(nil)

  }
}
// 返回新创建的`CodeBlockItemListSyntax`或者`MemberDeclListSyntax`
return nodeCreator(newItems)
```
当如下代码执行该`rule`时：
```swift             
print("hello"); print("goodbye");
print("3")
```
将会被修改为：
```swift
print("hello")
print("goodbye")
print("3")
```

## 参考
* [swift-format](https://github.com/apple/swift-format)