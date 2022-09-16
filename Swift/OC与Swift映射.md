# `APINotes`

我们在使用一些头文件的时候，可能会对头文件中的一些`API`添加一些专属的描述信息。此时，会导致头文件看上去非常的混乱。或许你的头文件来修改起来很多，很复杂。这个时候，应该怎么办？

提供一个`<name>.apinotes`的`YAML`格式的文件，放在头文件所在的目录中。同时向`Clang`传递`-fapi-notes-modules`参数，那么编译器在编译时，会自动去解析该文件对指定`API`的描述信息。

```yaml
# APINotes包含一个YAML字典
# 最上层的Name，代表framework的module的名称
Name: SomeKit
# Classes, Protocols, Tags, Typedefs, Globals, Enumerators, Functions
# YAML数组。当前头文件的API信息描述
# Tags对应structs，enums，unions
# Enumerators对应enum cases
# Classes和Protocols下的每个条目都可以包含Methods和Properties数组
Classes:
  # YAML字典。此条目描述Class A
  - Name: A
    # 该类在Swift中的桥接名称，空字符串表示没有桥接
    SwiftBridge: 'Swift.A'
    # YAML数组。此条目描述Class A指定的methods
    Methods:
    # YAML字典。描述的selector
      - Selector: "transform:integer:"
        # selector类型：Instance 或者 Class
        MethodKind:      Instance
        # 宏NS_SWIFT_NAME。重新命名该OC方法在Swift中的名称
        SwiftName: "transform(_:integer:)"
        # YAML数组。提示是否为可选类型
        # ``Nonnull`` or ``N`` (等于``_Nonnull``)
        # ``Optional`` or ``O`` (等于``_Nullable``)
        # ``Unspecified`` or ``U`` (等于``_Null_unspecified``)
        # ``Scalar`` or ``S`` (deprecated)
        Nullability:      [ N, S ]
        # 提示返回值是否为可选类型。同上
        # 暂时有bug。建议使用ResultType
        NullabilityOfRet: N
      - Selector: "implicitGetOnlyInstance"
        MethodKind:      Instance
        # 等同于宏NS_SWIFT_UNAVAILABLE。声明此方法，不能在Swift使用
        Availability:    nonswift
        # 提示信息
        AvailabilityMsg: "getter gone"
        # 等同于宏NS_REFINED_FOR_SWIFT。
        # 由 Swift 导入此方法时，会在此方法前加入双下划线__
        # 类似Swift私有方法，便于在Swift中再进行扩展
        SwiftPrivate: true
      - Selector: "implicitGetOnlyClass"
        MethodKind:      Class
        Availability:    none
        AvailabilityMsg: "getter gone"
    Properties:
      # 描述的属性名称
      - Name: intValue
        # 属性的类别：Instance 或者 Class
        PropertyKind:    Instance
        Availability: none
        # 如果为真，该属性将在Swift中作为存储属性，而不是作为计算属性
        SwiftImportAsAccessors: false
        AvailabilityMsg: "wouldn't work anyway"
      - Name: MKErrorCode
        # NSError Code枚举
        NSErrorDomain: MKErrorDomain
      - Name: AVMediaType
        # NS_STRING_ENUM & NS_EXTENSIBLE_STRING_ENUM。是否可扩展
        # 三个选项：struct（可扩展）、enum、none
        SwiftWrapper: none
    　- Name: GKPhotoSize
        # NS_ENUM & NS_OPTIONS
        # "NSEnum" / "CFEnum"
        # "NSClosedEnum" / "CFClosedEnum"
        # "NSOptions" / "CFOptions"
        # "none"
        EnumKind: none
  - Name: C
    Methods:
      - Selector: "initWithA:"
        MethodKind: Instance
        # 相当于宏NS_DESIGNATED_INITIALIZER，标记该方法必须在init方法中实现
        DesignatedInit: true
  - Name: OverriddenTypes
    Methods:
      - Selector: "methodToMangle:second:"
        MethodKind: Instance
        # 返回值类型，以及Nullability
        ResultType: 'NSArray * _Nonnull'
        Parameters:
          - Position: 0
            # 参数类型
            Type: 'SOMEKIT_DOUBLE *'
          - Position: 1
            Type: 'float *'
    Properties:
      - Name: intPropertyToMangle
        PropertyKind: Instance
        Type: 'double *'
Functions:
  - Name: global_int_fun
    ResultType: 'char *'
    Parameters:
      - Position: 0
        Type: 'double *'
      - Position: 1
        Type: 'void (^)()'
        # 相当于宏NS_NOESCAPE
        NoEscape: true
Globals:
  - Name: global_int_ptr
    Type: 'double (*)(int, void (^)())'
# 当前API对于Swift兼容描述
SwiftVersions:
  # 支持的最高版本
  - Version: 5.0
    # 同上
    Classes:
      - Name: A
        Methods:
          - Selector: "transform:integer:"
            MethodKind:      Instance
            NullabilityOfRet: O
            Nullability:      [ O, S ]
        Properties:
          - Name: explicitNonnullInstance
            PropertyKind:    Instance
            Nullability:     O
          - Name: explicitNullableInstance
            PropertyKind:    Instance
            Nullability:     N
```

## `YAML`快速入门
让我们来看一个简单的`JSON`文件。

```json
{
  "macOS": "maOS Big Sur",
  "Swift": 5,
  "Air-pods": false,
  "iOS": {
    "version": 14.7
  },
  "Devices": [
    "iPhone",
    "iPad"
  ]
}
```
再来看它的`YAML`版本：

```yaml
--- 
macOS: "maOS Big Sur"
Swift: 5
Air-pods: False
iOS:
  version: 14.7
Devices:
  - iPhone
  - iPad
...
```
`YAML`文件以`---`开头，表示新`YAML`文档的开始。以`...`表示文档结束。意味着，在同一个`YAML`文件里，可以定义多个`YAML`文档。

接下来，就是构成`YAML`文件中最基础的数据类型`map`，也就是`JSON`中的`hash`，也叫`dictionary`。文件以一个`map`开始，包含五个键值对，分别存储五种不同的数据类型：
* `macOS`，指向字符串`maOS Big Sur`。字符串可以用单引号或双引号，或者根本不引号表示；
* `Swift`，指向整数`5`，`YAML`将未引号的数字识别为整数或浮点数；
* `Air-pods`，代表了布尔值`false`；
* `iOS`，指向字典类型，并在里面使用了浮点数；
* 最后一个`Devices`表示的数据类型以`-`开头，表示数组中的每一项数据。

接下来，我们具体看一下`YAML`中的数据类型。

### `YAML`中的数据类型

#### 标量（scalars）类型
除了上面我们提到的整数类型、浮点数类型、字符串、布尔值。`YMAL`还支持以下标量类型：

##### 布尔类型
```yaml
---
# True, On and Yes for true
foo: True
light: On
cat: Yes
bar: False
TV: Off
dog: No
```
##### `null`

```yaml
---
foo: ~
bar: null
```

##### 数字类型

```yaml
---
foo: 12345
bar: 0x12d4
plop: 023332
ep:  12.3015e+05
na: .NAN
```
##### 字符串类型
`YAML`字符串，在大多数情况下不需要使用引号：

```yaml
---
paragraph: records separated by commas
   good choice for data transport
```
如果想使用转义字符，请使用双引号：

```yaml
---
Superscript two: "\u00B2"
# YAML不会转义带有单引号的字符串
Superscript two s: '\u00B2'
Superscript two str: \u00B2
```
`JSON`版本：

```
{
  "Superscript two": "²",
  "Superscript two s": "\\u00B2",
  "Superscript two str": "\\u00B2"
}
```
如果想使用多行字符串，有几种方式。区别是，如何对待行尾的空格\换行符。

多行字符串，`>`折叠换行，也就是每一行行尾的空格不会转换成换行，空白行才视为换行：
```yaml
---
paragraph: >
    records separated by commas
    good choice for data transport
    
```
多行字符串，`-`保留换行，每行开头的缩进（以首行为基准）会被去除，而与首行不同的缩进会保留，行尾的自动添加换行符：
```yaml
---
paragraph: |
    records separated by commas
    good choice for data transport
line: line
```

多行字符串，`|-`作用与`-`相同，但是不保留最后一行的换行符：
```yaml
---
paragraph: |-
   Or we
   can auto
   convert line breaks
   to save space
line: line
```
多行字符串，`>+`作用与`>`相同，保留最后一行的换行符：
```yaml
---
# `>`折叠换行，每一行行尾的空格不会转换成换行，空白行才视为换行
paragraph: >
    records separated by commas
    good choice for data transport
# `-`保留换行，每行开头的缩进（以首行为基准）会被去除，而与首行不同的缩进会保留，行尾空格转换成换行符
paragraph1: |
    records separated by commas
    good choice for data transport
# `|-`作用与`-`相同，但是不保留最后一行的换行符
paragraph2: |-
   Or we
   can auto
   convert line breaks
   to save space
# `>+`作用与`>`相同，保留最后一行的换行符   
paragraph3: >+
 records separated by commas
   good choice for data transport
line: I am line.
```

`JSON`版本：

```json
{
  "paragraph": "records separated by commas good choice for data transport\n",
  "paragraph1": "records separated by commas\ngood choice for data transport\n",
  "paragraph2": "Or we\ncan auto\nconvert line breaks\nto save space",
  "paragraph3": "records separated by commas\n  good choice for data transport\n",
  "line": "I am line."
}
```

#### 数组
上述讲到的在`YAML`文件中声明数组的方式，需要特殊字符`-`和缩进配合。如果不希望使用缩进，也可以将数组的元素声明在一行，使用`JSON`的方式。同时，数组中的值不必是相同类型：

```yaml
---
items: [ 1, 2, 3, 4, 5 ]
names: [ "one", "two", 1, 5 ]
```

#### 字典
字典中的`key`可以用下划线、破折号或空格分隔。
和数组一样，`YAML`中的字典，如果不喜欢使用缩进，也可以使用`JSON`的定义方式：

```yaml
---
foo: { thing1: huey, thing2: louie, thing3: dewey }
```
如果一个`key`很复杂，比如多行字符串，使用`?`后面跟着一个空格，表示复杂`key`：

```yaml
---
? |
  This is a key
  that has multiple lines
: and this is its value
```
`JSON`版本：

```json
{
  "This is a key\nthat has multiple lines\n": "and this is its value"
}
```

#### 引用与合并
锚点符号`&`声明一个数据的别名。引用符号`*`，可以用来引用一个锚点数据：

```yaml
---
array:
  - null_value:
  - boolean: true
  - integer: 1
  - alias: &example aliases are like variables
  - alias_1: *example
```
当前`array`的最后一个数据`alias_1`，直接使用倒数第二个`alias`的数据，`JSON`版本：

```json
{
  "array": [
    {
      "null_value": null
    },
    {
      "boolean": true
    },
    {
      "integer": 1
    },
    {
      "alias": "aliases are like variables"
    },
    {
      "alias_1": "aliases are like variables"
    }
  ]
}
```
可以看到，`alias_1`和`alias`保存的是相同的`value`。

`<<`用来合并其他锚点字典到当前的字典中：

```yaml
---
base : &base
  name: Everyone has same name 
  
alias: &example aliases are like 

array: &array
	- *base
  
foo:
  <<: *base
  base: *array
```
`JSON`版本：

```json
{
  "base": {
    "name": "Everyone has same name"
  },
  "alias": "aliases are like",
  "array": [
    {
      "name": "Everyone has same name"
    }
  ],
  "foo": {
    "name": "Everyone has same name",
    "base": [
      {
        "name": "Everyone has same name"
      }
    ]
  }
}
```

#### `set`

```yaml
---
set:
  ? item1
  ? item2
  ? item3
or: {item1, item2, item3}
```
`JSON`版本：

```json
{
  "set": {
    "item1": null,
    "item2": null,
    "item3": null
  },
  "or": {
    "item1": null,
    "item2": null,
    "item3": null
  }
}
```

#### 类型转换
`YAML`允许使用`!!`，显式声明数据类型：

```yaml
---
explicit_string: !!str 0.5

explicit_int: !!int '0.4'
```
`JSON`版本：

```json
{
  "explicit_string": "0.5",
  "explicit_int": 0.4
}
```
