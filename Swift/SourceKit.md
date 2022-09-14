- [一、`SourceKit`](#一、sourcekit)
  - [`SourceKitten`](#sourcekitten)
    - [`SourceKitObject`](#sourcekitobject)
    - [`UID`](#uid)
    - [`ByteRange`](#byterange)
    - [`Module`](#module)
    - [`StringView`](#stringview)
    - [`ClangTranslationUnit`](#clangtranslationunit)
    - [`CodeCompletionItem`](#codecompletionitem)
    - [`SwiftDocs`](#swiftdocs)
    - [`Structure`](#structure)
    - [`SyntaxMap -> SwiftlintSyntaxMap`](#syntaxmap-swiftlintsyntaxmap)
      - [`SyntaxToken -> SwiftLintSyntaxToken`](#syntaxtoken-swiftlintsyntaxtoken)
  - [二、使用`SourceKit`对`Swift`代码做混淆](#二、使用sourcekit对-swift代码做混淆)
    - [1. 通过`SourceKit`使用`indexing`](#1通过-sourcekit使用-indexing)
    - [2. 混淆](#2混淆)
  - [三、`USR`](#三、usr)
  - [四、参考](#四、参考)


# 一、`SourceKit`
`SourceKit framework`是用来支持`IDE`在处理`Swift`语言的处理，例如`Xcode`支持的`Swift`代码格式化、代码提示`code-completion`、`indexing`、跳转到特定符号，语法高亮`syntax-coloring`等等操作。

实际上在`Xcode`内部集成了`SourceKit`，也就是`sourcekitd.framework`。也可以使用`sourcekitdInProc`，在其他平台，例如`Linux`等。

通过开启`SourceKit`日志输出，可以查看`Xcode`使用`SourceKit`的流程：
```sh
export SOURCEKIT_LOGGING=3 && /Applications/Xcode.app/Contents/MacOS/Xcode > log.txt
```

`SourceKit`通过`XPC`方式（基于`mach port`的跨进程通讯方式）接受请求`request`，返回处理结果`response`：

| Request Name | Request Key |
| -------------:|:------------|
| 代码补全[`Code Completion`] | source.request.codecomplete 
| 选中位置提示[`Cursor Info`] | source.request.cursorinfo |
| 复原`Swift`符号信息[`Demangling`] | source.request.demangle |
| 将正常符号转成`Swift`符号[`Mangling`] | source.request.mangle_simple_class |
| 文档[`Documentation`] | source.request.docinfo |
| 模块接口生成[`Module interface generation`]| source.request.editor.open.interface |
| 获取所有`sur
`表达式[`Expression Type`]| source.request.expression.type |
| 获取所有变量[`Variable Type`]| source.request.variable.type |
| 诊断[`Diagnostics`]| source.diagnostic.severity.note/warning/error |
| 索引[`Indexing`] | source.request.indexsource  |
| [`Protocol Version`] | source.request.protocol_version |
| [`Compiler Version`] | source.request.compiler_version |

整个通讯协议使用如下格式：
```json
{
    <KEY>: (type) // comments
}
```
这种格式并不能直接生成，而是需要使用`sourcekitd_uid_t`作为`key`，`sourcekitd_object_t`作为`value`，初始化`SKDDictionary`。
例如，如果想要发送该请求
```json
{
    "key.request": "source.request.editor.open",
    "key.name": "Cat1237",
    "key.sourcefile": "cat.swift"
}
```
1. 需要先将`key.request`和`key.name`、`key.sourcefile`三个`key`通过`sourcekitd_uid_get_from_cstr`生成`sourcekitd_uid_t`。

2. 再将`value`通过`sourcekitd_request_*_create`生成`sourcekitd_object_t`对象。

3. 然后通过`sourcekitd_request_dictionary_create`创建`SKDDictionary`。

> i. `sourcekitd_uid_t`是整个通讯过程等**唯一标识符**。一个`sourcekitd_uid_t`与一个字符串关联，并且在当前进程的生命周期内是唯一的，同时可以保证标识符可以无穷多。同时，即便整个通讯过程出现问题，`sourcekitd_uid_t`仍然有效。
> ii. `sourcekitd_object_t`实际上是`SKDObject`类型。当遇到`value`是`String`或者`Array`、`sourcekitd_uid_t`类型时，会包装成`SKD*`开头等内部类。

如果想要在`Swift`中使用`SourceKit`的功能，有两个选择：
* `SourceKitten`：由`JP Simard`编写，桥接了大部分功能。也是`SwiftLint`内部使用的
* `SourceKit-LSP`：由`Swift`官方编写，基于语言服务器协议`LSP`协议实现，专为`IDE`编写`Swift`打造

## `SourceKitten`

### `SourceKitObject`
表示`sourcekitd_object_t`。
### `UID`
表示`sourcekitd_uid_t`。

### `ByteRange`
用来表示编码后的字符位置（`Range`）
```swift
let string = "👨‍👩‍👧‍👧123"
print("\(string.stringView().substringWithByteRange(ByteRange(location: 0, length: 25))!)")
```
输出：
```text
👨‍👩‍👧‍👧
```

### `Module`
表示`source.request.cursorinfo`。

### `StringView`
用于`ByteRange`和`NSRange`相互转换。

### `ClangTranslationUnit`
使用`libClang`处理`OC`头文件和编译参数，获取`头文件`内部等`Swift`相关声明：
1. 使用`source.request.editor.open.interface.header`生成`Swift interface`
2. 通过`Cursor`获取[usr](#usr)声明位置。同时，在上一步骤打开`module interface`后，发送`source.request.editor.find_usr`，获取`offset`
3. 通过获取的`usr offset`发送`source.request.cursorinfo`，获取该位置的`Swift`代码信息

> `libClang`用于将源代码解析为抽象语法树 (`AST`)、加载已解析的`AST`、遍历`AST`、将源码位置与`AST`关联等等

### `CodeCompletionItem`
表示`source.request.codecomplete`。

### `SwiftDocs`
表示`source.request.cursorinfo`。

### `Structure`
表示`Swift`代码文件。

### `SyntaxMap -> SwiftlintSyntaxMap`
用来表示`Swift`文件中的语法信息。
#### `SyntaxToken -> SwiftLintSyntaxToken`
用来表示`Swift`文件中的`token`信息。
```swift
let file = File(contents: "import Foundation // Hello World!")
let syntaxMap = try! SyntaxMap(file: file)
let syntaxJSONData = syntaxMap.description.data(using: .utf8)!
print(syntaxMap.tokens)
```
将会输出：
```text
[{
  "length" : 6,
  "offset" : 0,
  "type" : "source.lang.swift.syntaxtype.keyword"
}, {
  "length" : 10,
  "offset" : 7,
  "type" : "source.lang.swift.syntaxtype.identifier"
}, {
  "length" : 15,
  "offset" : 18,
  "type" : "source.lang.swift.syntaxtype.comment"
}]
```

## 二、使用`SourceKit`对`Swift`代码做混淆
[完整代码参考`SwiftObfuscateSample`](./SwiftObfuscateSample)
`SourceKit`可以对代码进行`indexing`操作，可以获取到第几行第几列代码结构的引用`reference`。

* `Request`
    * `key.request`：`(UID) <source.request.indexsource>`
    * `key.sourcetext`：`[opt] (string)`代码文本
    * `key.sourcefile`：`[opt] (string)`代码文件路径
    * `<key.compilerargs>`：`[opt] [string*]`编译参数，例如其他文件的`interface`位置
    * `key.hash`：`[opt]`文件的`hash`，用于判断文件是否修改过
* `Response`：
    *  `<key.dependencies>`： `(array) [dependency*]`当前文件依赖的其他模块信息
        *  `<key.kind>`：`(UID)``<source.lang.swift.import.module.swift>`当前依赖的类型
        *  `<key.name>`：`(string)`当前依赖`dependency`名称
        *  `<key.filepath>`：`(string)`文件路径
        *  `<key.hash>`：`[opt]`当前依赖`dependency`的`hash`
    *  `<key.hash>`：`(string)`文件的`hash`。如果`Request`没有设置该参数，`Response`不会返回该参数
    *  `<key.entities>`：`[opt] (array) [entity*]` 当前文件经过`indexing`后最外层的结构
        *  `<key.kind>`：`(UID)`当前结构的类型（`enum`、`function`、`enumelement`）等等
        *  `<key.usr>`：`(string)`当前结构的`USR`标识
        *  `<key.line>`：`(int64)`所在行
        *  `<key.column>`：`(int64)`所在列
        *  `<key.is_test_candidate>`：测试相关
        *  `<key.entities>`：`[opt] (array) [entity+]`当前结构包含的子结构
        *  `<key.related>`：`[opt] (array) [entity+]`当前结构相关的结构，继承的协议，类等等

### 1. 通过`SourceKit`使用`indexing`
需要经过`indexing`处理的文件内容如下：
```swift
class Foo {
    func barbar() {}
}
```
通过`SourceKit`发送`Request`：
```swift
// 加载`sourcekitd.framework`或者`sourcekitdInProc.framework`
// `Linux`加载`libsourcekitdInProc.so`
// 创建`SourceKitDImpl`
let sourceKit = try load()
// 获取`sourcekitd_keys`，用来设置`Request`具体内容
let keys = sourceKit.keys
// 创建`SKDRequestDictionary`，可以参考上部分`SKDDictionary`是如何创建的
let request = SKDRequestDictionary(sourcekitd: sourceKit)
// 文件完整路径
let file = "foo.swift"
// 当前`Request`的类型，`source.request.indexsource`
request[keys.request] = sourceKit.requests.index_source
// 代码路径
request[keys.sourcefile] = file
// 编译参数
request[keys.compilerargs] = ["-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk", file]
// 发送`Request`
let response = try sourceKit.sendSync(request)
```
打印`request`输出：
```json
{
  key.request: source.request.indexsource,
  key.compilerargs: [
    "-sdk",
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk",
    "foo.swift"
  ],
  key.sourcefile: "foo.swift"
}
```
打印`response`输出：
```json
{
  key.dependencies: [
    {
      key.kind: source.lang.swift.import.module.swift,
      key.name: "Swift",
      key.filepath: "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.swiftinterface",
      key.is_system: 1
    },
    {
      key.kind: source.lang.swift.import.module.swift,
      key.name: "_Concurrency",
      key.filepath: "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift/_Concurrency.swiftmodule/x86_64-apple-macos.swiftinterface",
      key.is_system: 1,
      key.dependencies: [
        {
          key.kind: source.lang.swift.import.module.swift,
          key.name: "Swift",
          key.filepath: "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.swiftinterface",
          key.is_system: 1
        }
      ]
    }
  ],
  key.entities: [
    {
      key.kind: source.lang.swift.decl.class,
      key.name: "Foo",
      key.usr: "s:3foo3FooC",
      key.line: 8,
      key.column: 7,
      key.entities: [
        {
          key.kind: source.lang.swift.decl.function.method.instance,
          key.name: "barbar()",
          key.usr: "s:3foo3FooC6barbaryyF",
          key.line: 9,
          key.column: 10,
          key.is_dynamic: 1,
          key.effective_access: source.decl.effective_access.internal
        },
        {
          key.kind: source.lang.swift.decl.function.constructor,
          key.usr: "s:3foo3FooCACycfc",
          key.line: 8,
          key.column: 7,
          key.is_implicit: 1,
          key.effective_access: source.decl.effective_access.internal
        }
      ],
      key.effective_access: source.decl.effective_access.internal
    }
  ]
}
```
可以看到整个代码的结构，包括位置信息以及`USR`全部被解析出来。
### 2. 混淆
尝试对当前`Foo`和`barbar`的名称进行混淆。
`entry`的类型一般有两种：
* `source.lang.swift.re.*`：表示引用的方法，类，结构体等等
* `source.lang.swift.decl.*`：表示声明的方法，类等等
首先遍历整个`entities`，拿到`Foo`和`barbar`的结构信息：
```swift
let kindId: SourceKitdUID  = dict[sourceKit.keys.kind]!
guard kindId.referenceType() != nil || kindId.declarationType() != nil,
      let rawName: String = dict[sourceKit.keys.name],
      let usr: String = dict[sourceKit.keys.usr],
      let line: Int = dict[sourceKit.keys.line],
      let column: Int = dict[sourceKit.keys.column] else {
    return
}
```

对获取的`name`进行混淆。
最后根据获取到的位置信息，进行代码替换。
最后混淆的结果：
```swift
class XD6YdizIccTi2FEHDhx4Y2BQwUUP0zRE {
    func Xwath8AAgA5p2c7YKvz5wO0f5BjVJB1M() {}
}
```

## 三、`USR`
`USR`的全称为`Unified Symbol Resolution`是一个字符串，用于标识程序中的特定实体（函数、类、变量等）。
在代码中使用一个变量或者函数，视为对其定义的引用（`reference`）。使用的名称，称之为`spelling`。
在识别符号时，不能仅通过拼写，而是要根据上下文环境，消除在不同范围内使用相同拼写的歧义。
这个时候就需要`USR`，作为符号的唯一标识符。同时可以确定多个编译单元`Translation Unit`相互引用关系
例如，`Foo`中的`barbar()`的`USR`为`s:3foo3FooC6barbaryyF`。

## 四、参考
* [Cross-referencing in the AST](https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__XREF.html#ga51679cb755bbd94cc5e9476c685f2df3)
* [SwiftShield](https://github.com/rockbruno/swiftshield)

