# `USR`
`USR`的全称为`Unified Symbol Resolution`是一个字符串，用于标识程序中的特定实体（函数、类、变量等）。

在代码中使用一个变量或者函数，视为对其定义的引用（`reference`）。使用的名称，称之为`spelling`。

在识别符号时，不能仅通过拼写，而是要根据上下文环境，消除在不同范围内使用相同拼写的歧义。

这个时候就需要`USR`，作为符号的唯一标识符。同时可以确定多个编译单元`Translation Unit`相互引用关系。

例如：
```swift
class Foo {
    func barbar() {}
}
```
`Foo`中的`barbar()`的`USR`为`s:3foo3FooC6barbaryyF`。

## 参考
* [Cross-referencing in the AST](https://clang.llvm.org/doxygen/group__CINDEX__CURSOR__XREF.html#ga51679cb755bbd94cc5e9476c685f2df3)
* [SwiftShield](https://github.com/rockbruno/swiftshield)