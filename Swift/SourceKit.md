- [`SourceKit`](#sourcekit)
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
  - [参考](#参考)

# `SourceKit`
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

## 参考
* [Cross-referencing in the AST](https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__XREF.html#ga51679cb755bbd94cc5e9476c685f2df3)
* [SwiftShield](https://github.com/rockbruno/swiftshield)

