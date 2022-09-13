# `SwiftLint`
- [`SwiftLint`](#swiftlint)
  - [一、`LintOrAnalyze`](#一、lintoranalyze)
  - [二、在`SwiftLint`中，如何实现一个`Rule`？](#二、在swiftlint中，如何实现一个-rule？)
      - [1. `ConfigurationProviderRule`](#1-configurationproviderrule)
      - [2. `Rule`](#2-rule)
      - [3. `CorrectableRule`](#3-correctablerule)
    - [三、`UntypedErrorInCatchRule`](#三、untypederrorincatchrule)
  - [四、正则表达式补充](#四、正则表达式补充)

`SwiftLint`绝大多数功能是基于`SourceKitten`通过`SourceKit`实现的。还有一部分功能是基于`SwiftSyntax`。
* [`SourceKitten`详细介绍](SourceKit.md)
* [`SwiftSyntax`详细介绍](SwiftSyntax.md)

`SwiftLint`支持五种类型的`rule`：
* `lint`：`Swift`语法规则验证；
* `idiomatic`：`Swift`社区达成一致的语法规则验证；
* `style`：编码风格的验证；
* `metrics`：对代码长度及复杂程度规则的验证；
* `performance`：代码性能的验证。

## 一、`LintOrAnalyze`
`SwiftLint`有两个基本操作：`analyze`和`lint`：
* `lint`：直接进行规则验证。将需要验证的文件，及相关配置包装成`Linter`，进行`rule`验证；
* `analyze`：会在确定代码正确的前提下，通过分析`xcode`编译日志获取编译参数再去执行`Linter`。速度比直接`lint`慢，但更精确。

## 二、在`SwiftLint`中，如何实现一个`Rule`？
#### 1. `ConfigurationProviderRule`
定义的`rule`要根据具体的配置，作出相应的调整。配置的传递者就是`ConfigurationProviderRule`，它遵守了所有`rule`的根协议`Rule`。内部拥有一个`configuration`的`RuleConfiguration`属性。通过设置这个`configuration`，可以让当前的`rule`支持自定义配置或者内置的配置，例如在`UntypedErrorInCatchRule`中：
```swift
public var configuration = SeverityConfiguration(.warning)
```
表明对违反该`rule`的严重性声明，当前是`warning`。
#### 2. `Rule`
每一个`Rule`都遵守了`Rule`。在`Rule`协议中，除了`init`函数外，还有几个要求必须实现的方法和属性：
* `description`：`RuleDescription`类型，可以在终端显示该`description`。保存了对该`rule`的详细描述，例如：
    * 该`rule`类型（`kind`）
    * 那些写法（`nonTriggeringExamples`）能通过该`rule`
    * 那些不能通过（`triggeringExamples`）
    * 以及能进行那些自动更正（`corrections`）。
* `validate*`函数：对`Swift`代码执行`rule`并返回任何违反该`rule`的详细信息`StyleViolation`。例如，违反规则的代码位置在哪？理由是什么？等等。该函数有三种类型，区别在于是否要预先设定收集文件的部分信息，是否使用编译参数，三个函数由上到下依次调用：
    * `func validate(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation]`
    * `func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation]`
    * `func validate(file: SwiftLintFile) -> [StyleViolation]`
* `collectInfo`：用于提供要对指定的源码文件收集的信息，由`RuleStorage`存储，由`CollectedLinter`进行处理

#### 3. `CorrectableRule`
`CorrectableRule`协议用于纠正`SwiftLint`能够修复的违反规则的部分。同时对`Rule`协议扩展了三个函数，区别在于是否要预先设定收集文件的部分信息，是否使用编译参数，三个函数由上到下依次调用：
* `func correct(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [Correction]`
* `func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction]`
* `func correct(file: SwiftLintFile) -> [Correction]`

我们可以参考`UntypedErrorInCatchRule`的实现，该`rule`属于`style rule`。

### 三、`UntypedErrorInCatchRule`
该规则用来表示`Catch`语句不应该在没有类型转换的情况下声明错误变量，同时可以进行简单修正。

例如：
```swift
do {
  try foo()
} catch let error {}
```
将会被修正为：
```swift
do {
  try foo()
} catch {}
```
完整代码：
```Swift
import SourceKittenFramework
// OptInRule：该`rule`默认不启用，需手动启用
public struct UntypedErrorInCatchRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}
    // 进行代码匹配的正则表达式
    private static let regularExpression =
        "catch" + // The catch keyword
        "(?:"   + // Start of the first non-capturing group
        "\\s*"  + // Zero or multiple whitespace character
        "\\("   + // The `(` character
        "?"     + // Zero or one occurrence of the previous character
        "\\s*"  + // Zero or multiple whitespace character
        "(?:"   + // Start of the alternative non-capturing group
        "let"   + // `let` keyword
        "|"     + // OR
        "var"   + // `var` keyword
        ")"     + // End of the alternative non-capturing group
        "\\s+"  + // At least one any type of whitespace character
        "\\w+"  + // At least one any type of word character
        "\\s*"  + // Zero or multiple whitespace character
        "\\)"   + // The `)` character
        "?"     + // Zero or one occurrence of the previous character
        ")"     + // End of the first non-capturing group
        "(?:"   + // Start of the second non-capturing group
        "\\s*"  + // Zero or unlimited any whitespace character
        ")"     + // End of the second non-capturing group
        "\\{"     // Start scope character

    public static let description = RuleDescription(
        // `rule`唯一标识，用于在配置文件和命令行中使用
        identifier: "untyped_error_in_catch",
        name: "Untyped Error in Catch",
        description: "Catch statements should not declare error variables without type casting.",
        // 编码风格
        kind: .idiomatic,
        // 符合该`rule`
        nonTriggeringExamples: [
            Example("""
            do {
              try foo()
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch Error.invalidOperation {
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch let error as MyError {
            } catch {}
            """),
            Example("""
            do {
              try foo()
            } catch var error as MyError {
            } catch {}
            """)
        ],
        // 不符合该`rule`
        triggeringExamples: [
            Example("""
            do {
              try foo()
            } ↓catch var error {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let error {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let someError {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch var someError {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch let e {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch(let error) {}
            """),
            Example("""
            do {
              try foo()
            } ↓catch (let error) {}
            """)
        ],
        // 该`rule`能进行的修正
        corrections: [
            Example("do {\n    try foo() \n} ↓catch let error {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch(let error) {}"): Example("do {\n    try foo() \n} catch {}"),
            Example("do {\n    try foo() \n} ↓catch (let error) {}"): Example("do {\n    try foo() \n} catch {}")
        ])
    // 编写规则，表明哪些代码位置不满足该`rule`
    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.location))
        }
    }

    fileprivate func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        // 通过正则匹配文件内容，同时指明`syntax kind`
        // 同时进行`syntax`验证
        return file.match(pattern: Self.regularExpression,
                          with: [.keyword, .keyword, .identifier])
    }
}
// 修正处理
extension UntypedErrorInCatchRule: CorrectableRule {
    public func correct(file: SwiftLintFile) -> [Correction] {
        let violations = violationRanges(in: file)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var contents = file.contents.bridge()
        let description = Self.description
        var corrections = [Correction]()

        for range in matches.reversed() where contents.substring(with: range).contains("let error") {
            contents = contents.replacingCharacters(in: range, with: "catch {").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents.bridge())
        return corrections
    }
}
```


## 四、正则表达式补充

* `?`：匹配前面一个表达式 0 次或者 1 次。等价于 `{0,1}`。例如，`/e?le?/` 匹配 `angel`中的`el`、`angle`中的 `le`以及 `oslo`中的 `l`；
* `(?:pattern)`：`(?:)`表示非捕获分组，和捕获分组区别在于，非捕获分组不记住匹配项；
* `x(?=pattern)`：匹配`x`仅当`x`后面跟着`pattern`。这种叫做先行断言。例如，`/Jack(?=Sprat)/`会匹配到`Jack`仅当它后面跟着`Sprat`。`/Jack(?=Sprat|Frost)/`匹配`Jack`仅当它后面跟着`Sprat`或者是`Frost`。但是`Sprat`和`Frost`都不是匹配结果的一部分；
* `(?<=pattern)x`：匹配`x`仅当`x`前面是`pattern`。这种叫做后行断言。例如，`/(?<=Jack)Sprat/`会匹配到`Sprat`仅当它前面跟着`Jack`。`/(?<=Jack|Tom)`匹配`Sprat`仅当它前面跟着`Jack`或者是`Tom`。但是`Jack`和`Tom`都不是匹配结果的一部分；
* `x(?!pattern)`：匹配`x`仅当`x`后面不是`pattern`。这种叫做正向否定查找。例如，仅仅当这个数字后面没有跟小数点的时候，`/\d+(?!\.)/`匹配一个数字。正则表达式`/\d+(?!\.)/`匹配`3.141`匹配`141`而不是`3.141`；
* `(?<!pattern)x`：仅当`x`前面不是`y`时匹配`x`，这被称为反向否定查找。例如，仅仅当这个数字前面没有负号的时候，`/(?<!-)\d+/`匹配一个数字。对于`3`，`/(?<!-)\d+/`匹配到`3`。对于`-3`，`/(?<!-)\d+/`匹配不到；
