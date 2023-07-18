## 定义类
### 类是对象的模板
类描述任何特定类型的对象所共有的属性和行为。即同一个类的不同实例拥有相同的属性和行为。

### 基础语法
定义类的接口及属性
```
@interface Person : NSObject
 
@property (readwrite)NSString *firstName;
@property (readonly)NSString *lastName;
@property NSString *fullName;

@end
```
以上放在.h文件中对外暴露与外界进行交互。`@property`控制对象值的访问。括号中的是`@property`的特征。可以有多个特征用逗号分隔。这里分别使用了`readwrite`和`readonly`表示了属性的访问特征。表示可读写和只读。默认是`readwrite`。

方法声明指示对象可以接收的消息。同样在`@interface`中声明
```
@interface Person : NSObject
 
@property (readwrite)NSString *firstName;
@property (readonly)NSString *lastName;
@property NSString *fullName;

- (void)sayHello;

@end
```

使用`@implementation`来实现类的接口，并放在.m文件中。
```
#import "Person.h"
@implementation Person

- (void)sayHello{
    NSLog(@"Hello!");
}

@end
```

**注意：
根类提供基本功能，就像所有生物体都有一些基本的“生命”特征一样，Objective-C中的所有对象都有一些共同的功能。当Objective-C对象需要与另一个类的实例一起工作时，期望另一个类提供某些基本特征和行为。出于这个原因，Objective-C定义了一个根类，绝大多数其他类都是从它继承的，叫做NSObject。当一个对象遇到另一个对象时，它期望能够至少使用NSObject类描述定义的基本行为进行交互**。

## 使用对象
```
    Person *personOne = [[Person alloc] init];
    NSString *firstName = personOne.firstName;
    personOne.firstName = @"new name";
    [personOne sayHello];
```

## 封装数据
数据的封装主要分为封装属性和封装方法。

### 封装属性
使用`@property`在接口中封装属性，使用生成的访问器方法获取和设置属性。
```
    NSString *firstName = personOne.firstName;//访问属性
    personOne.firstName = @"new name";//设置属性
```
默认情况下，这些访问器方法是由编译器自动合成的，因此除了在类接口中使用`@property`声明属性外，不需要做任何事情。
像对于属性`firstName`，编译器就默认生成了getter和setter方法。
```
    [personOne firstName];
    [personOne setFirstName:@""];
```
点语法其实就是调用了生成的访问器方法。
大多数属性是由实例变量支持的。默认情况下，readwrite属性将由实例变量支持，该实例变量将再次由编译器自动合成。
实例变量是一种存在并在对象的生命周期内保持其值的变量。用于实例变量的内存是在对象第一次创建时分配的(通过alloc)，并在对象被释放时释放。
除非另行指定，否则合成的实例变量具有与属性相同的名称，但带有下划线前缀。例如，对于名为firstName的属性，合成的实例变量将被称为_firstName。
当然你也可以告诉编译器生成你指定的访问器方法和实例变量名。比如:
```
@interface Person : NSObject

@property (readwrite)NSString *firstName;
@property (readonly)NSString *lastName;

@property (getter=myFullName,setter=mySetFullName:)NSString *fullName;

- (void)sayHello;

@end
```
在`@implementation`修改自动生成的成员变量名
```
#import "Person.h"

@implementation Person
@synthesize fullName = my_fullName;
- (void)sayHello{
    NSLog(@"Hello!");
}
@end
```
### 属性的特征
#### 控制访问的特征
`readonly`和`readwrite`控制属性是只读还是可读可写的。当使用`readonly`时，就只会生成属性的getter访问器方法。默认是`readwrite`

#### 原子性的特征
`atomic`和`nonatomic`原子性和非原子性。原子性表示属性的getter和setter能够保证从不同线程调用是一致的。是线程安全的。而`nonatomic`则不保证。由于这个原因，访问非原子属性比访问原子属性要快。默认是`atomic`

**注意：
属性原子性并不等同于对象的线程安全性。考虑一个XYZPerson对象，其中一个人的名字和姓氏都是使用来自一个线程的原子访问器更改的。如果另一个线程同时访问这两个名称，原子getter方法将返回完整的字符串(不会崩溃)，但不能保证这些值是相对于彼此的正确名称。如果在更改之前访问了第一个名称，但在更改之后访问了最后一个名称，那么最终会得到不一致的、不匹配的一对名称。**

#### 管理所有权的特征（ARC下对象类型默认是strong）
**`strong`和`retain`**
`strong`和`retain`修饰属性没有区别，都是对属性的强引用。只不过ARC时代用的是`strong`，MRC时代用的是`retain`

**`weak`和`unsafe_unretained`**
`weak`弱引用修饰那些不需要强引用的对象。又因为属于弱引用，所以使用的时候可能引用的对象已经释放掉了。`weak`会自动将其置为nil。
而对于一些类不支持弱引用的使用`unsafe_unretained`。不安全引用类似于弱引用，因为它不会使其相关对象保持活动状态，但如果目标对象被释放，它不会被设置为nil。这意味着你将留下一个悬空指针，指向现在被释放的对象最初占用的内存，因此有了术语“不安全”。向悬空指针发送消息将导致崩溃。

**`copy`**
`copy`用在当你希望保留为其属性设置的任何对象的自己的副本的时候。当然其本身也有是强引用。

**`assign`**
`assign`用于基本类型，比如int,float等。

#### 扩展
**1. 关于`copy`和`mutableCopy`方法**
```
    NSString *str = @"test";
    NSString *strCopy = [str copy];
    NSMutableString *strMut = [str mutableCopy];
```
copy方法返回一个原对象的不可变的复制对象，而mutableCopy方法返回一个原对象的可变的复制对象。

**对于原对象是不可变的对象**
调用copy方法会返回对象本身。因为既然不可变，那么多个不可变的对象其实都是一样的，直接使用内存中的同一份即可。而调用mutableCopy方法则会返回一份复制原对象的可变的对象，显然跟原对象不是同一个对象。

**对于原对象是可变的对象**
调用copy方法返回的一个新的不可变对象，显然跟原对象不是同一个对象，因为一个是可变的，一个是不可变的。调用mutableCopy方法则会返回一个新的不可变对象。因为原对象和新对象都可能有不同的改变，所以必须是两个不同的对象。当然有的语言也可能存在写时优化，就是当你真正去改变新对象的时候在创建一个不同的对象。不改变的时候还是原来的对象。

**2. 声明属性时@property中的特征关键字copy**
```
@property(copy)NSString *name;
```
实际上这个copy就是在给属性赋值时候，调用了原对象的copy方法。那么显然不管原对象是不可变还是可变类型。当赋值给copy关键字的属性时候就会变为不可变对象。思考一下当使用以下声明时会有什么问题:
```
@property(copy)NSMutableString *mName;
```
显然，哪怕当你创建一个可变对象赋值给mName属性时候，由于copy关键字的存在，其实际上已经通过调用copy方法变为了一个不可变对象。但由于你的声明是可变的对象，当你使用可变对象的方法时候，就会造成崩溃。所以对于可变对象属性的声明是一定不要使用copy关键字的。那么为什么不可变对象的属性声明要加上copy关键字。因为当你将一个可变对象赋值给不可变属性时候，会调用copy方法将产生一个新的不可变的对象赋值给它。当你改变原来的对象的时候，这个属性不会因为原来对象的改变而改变。

```
    NSMutableString;
    NSMutableArray;
    NSMutableDictionary;
    NSMutableSet;
    NSMutableData;
    NSMutableIndexSet;
    NSMutableOrderedSet;
    NSMutableURLRequest;
    NSMutableCharacterSet;
    NSMutableParagraphStyle;
    NSMutableAttributedString;
```
**注意：
对于自定义的对象如果需要使用copy或者mutableCopy功能，则需要实现对应的NSObject中声明的两个方法**
```
- (id)copy;
- (id)mutableCopy;
```

**3. 浅拷贝和深拷贝**
浅拷贝和深拷贝很好理解，当我们拷贝对象的时候，如果对象属性中还包含了其它的对象，要不要对包含的对象进行拷贝。不对属性对象进行拷贝就是浅拷贝，而对属性中的对象也进行拷贝就是深拷贝。

## 自定义现有的类
### 分类或类别（以下统称类别）
能向现有类添加方法，并且不需要原类的源码。
在.h文件中声明新的类方法
```
#import "Person.h"
@interface Person (category1)

-(void)newCategoryFunc;

@end
```
在.m中实现方法
```
#import "Person+category1.h"

@implementation Person (category1)

- (void)newCategoryFunc{
    NSLog(@"newCategoryFunc");
}
@end
```
### 类别的特点
1. 类别只能给类添加方法，不能添加含有成员变量的属性。
2. 可以通过runtime方法`objc_getAssociatedObject`和`objc_setAssociatedObject`模拟给类添加属性，但和声明的属性有明显的区别。声明的属性背后都是有成员变量支持的且存放在类结构中。而通过runtime模拟的属性是存放在全局的hash表中的。
3. 类别中如果定义了和元类中的同名方法，则表现出来是类别的方法会覆盖原类的方法。其实本质不是覆盖而是类别的方法添加在原类方法列表的前面，方法调用的时候先找到的是类别的方法。多个类别中的同名方法调用则是和类别文件的编译顺序有关，后编译的类别中的方法在前，同理调用方法时候会调用后编译的类别中的方法。

### 类扩展
类扩展扩展内部实现，需要类源码。因为类扩展声明的方法是在原始类的@implementation块中实现的。
在原类的.m文件中添加
```
@interface Person ()
@property (copy,nonatomic)NSString *extensionName;
-(void)extensionFunc;
@end
```
### 类扩展的特点
1. 类扩展既可以添加属性也可以添加方法，但是需要有原类的源码。
2. 类扩展常用来隐藏属性或者方法。
3. 类扩展虽然也被称作为匿名分类，但这仅仅只是因为它们的写法差不多。实际上类扩展和类别有本质的区别。类扩展是在编译时就将属性和方法放进原类中。而类别则是在运行时将方法插入进原类的数据中。


参考
1. https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/DefiningClasses/DefiningClasses.html#//apple_ref/doc/uid/TP40011210-CH3-SW1
2. https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011226-CH1-SW11