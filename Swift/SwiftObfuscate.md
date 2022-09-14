# 使用`SourceKit`对`Swift`代码做混淆

> [完整代码参考`SwiftObfuscateSample`](./SwiftObfuscateSample)

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

## 通过`SourceKit`使用`indexing`
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
可以看到整个代码的结构，包括位置信息以及[USR](./USR.md)全部被解析出来。
## 混淆
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
