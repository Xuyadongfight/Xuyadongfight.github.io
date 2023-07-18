---
layout: post
title: Objective-C基础系列-2
subtitle: Objective-C基础系列-2
categories: iOS
tags: [iOS,Objective-C]
---
## 使用协议
Objective-C允许你定义协议，它声明了在特定情况下预期使用的方法。协议定义消息传递的约定。

### 定义协议
```
@protocol ProtocolTest
@property(nonatomic,copy)NSString* name;
+(void)testTwo;

-(void)testOne;
-(void)testTwice:(NSString *)para;

@optional
-(void)testOptional;

@end
```
协议可以包括实例方法和类方法以及属性的声明。也可以通过`@optional`来声明一个可选的方法。
声明一个遵循协议的属性
```
@property(nonatomic,weak)id<ProtocolTest> delegate;
```
### 协议继承
就像Objective-C类可以继承超类，你也可以指定一个协议遵循另一个协议。
```
@protocol MyProtocol <NSObject>

@end
```
像上面的MyProtocol协议继承自NSObject协议。

### 类遵守协议
```
@interface MyClass : NSObject <MyProtocol>

@end
```
像是上面表示类MyClass遵守MyProtocol协议。这表示类MyClass提供协议MyProtocol中所有非可选类型的方法的实现。
如果需要遵守多个协议可以在尖括号中添加其它的协议
```
@interface MyClass : NSObject <MyProtocol, AnotherProtocol, YetAnotherProtocol>

@end
```

### 协议的使用是匿名的
你只知道这个实例遵守了某个协议，而不知道这个实例具体是什么类型。只是知道这个实例对象可以调用协议中声明的方法。对于协议中声明的可选类型的方法。在使用之前需要检查对象是否实现了这个可选方法。
```
    if ([self.delegate respondsToSelector:@selector(testOptional)]){
        [self.delegate testOptional];
    }
```
**注意：
`respondsToSelector`方法是在协议NSObject中声明的，要想使用这个方法，你自己定义的协议需要继承NSObject协议。**

## 使用Block
Block是添加到C、Objective-C和c++中的语言级特性，它允许你创建不同的代码段，这些代码段可以像传递值一样传递给方法或函数。block是Objective-C对象，这意味着它们可以被添加到集合中，比如NSArray或NSDictionary。它们还具有从封闭范围捕获值的能力，使它们类似于其他编程语言中的闭包或lambdas。

### Block 语法
```
    ^{
         NSLog(@"This is a block");
    }
```
与函数和方法定义一样，大括号表示块的开始和结束。在这个例子中，块不返回任何值，也不接受任何参数。
就像你可以使用函数指针来引用C函数一样，你可以声明一个变量来跟踪一个块，像这样:
```
void (^simpleBlock)(void);
```
如果你不习惯处理C函数指针，那么语法可能看起来有点不寻常。这个例子声明了一个名为simpleBlock的变量来引用一个不接受参数也不返回值的Block，这意味着该变量可以被赋值为上面所示的块字面量，就像这样:
```
  simpleBlock = ^{
        NSLog(@"This is a block");
    };
```
这就像任何其他变量赋值一样，因此语句必须以结束大括号后的分号结束。你也可以把变量声明和赋值结合起来:
```
  void (^simpleBlock)(void) = ^{
        NSLog(@"This is a block");
    };
```
一旦你声明并赋值了一个块变量，你就可以用它来调用这个块:
```
simpleBlock();
```
**注意：
如果你视图调用一个未赋值的Block变量，应用程序会崩溃。**

### Block能接受参数和返回值
就像方法和函数一样，块也可以接受参数和返回值。例如，考虑一个变量引用一个块，该块返回两个值相乘的结果:
```
double (^multiplyTwoValues)(double, double) =
                              ^(double firstValue, double secondValue) {
                                  return firstValue * secondValue;
                              };
 
    double result = multiplyTwoValues(2,4);
 
    NSLog(@"The result is %f", result);

```

### Block可以从封闭作用域捕获值
除了包含可执行代码外，块还具有从其封闭范围捕获状态的能力。例如，如果你在一个方法中声明一个块字面量，就有可能捕获该方法范围内可访问的任何值，如下所示:
```
- (void)testMethod {
    int anInteger = 42;
 
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
    };
 
    testBlock();
}
```
在上面的例子中，anInteger是在块外部声明的，但是在定义块时捕获该值。除非你另有指定，否则只捕获值。这意味着，如果你在定义块和调用块之间改变变量的外部值，就像这样:
```
    int anInteger = 42;
 
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
    };
 
    anInteger = 84;
 
    testBlock();
```
Block捕获的值不受影响。这意味着输出仍然显示:
`Integer is: 42`
这也意味着块不能改变原始变量的值，甚至不能改变捕获的值(它作为const变量被捕获)。
 
### 使用__block变量共享存储
如果你需要能够从块中更改捕获的变量的值，你可以在原始变量声明上使用__block存储类型修饰符。这意味着该变量位于原始变量的词法作用域和该作用域中声明的任何块之间共享的存储中。
作为一个例子，你可以像这样重写前面的例子:
```
   __block int anInteger = 42;
 
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
    };
 
    anInteger = 84;
 
    testBlock();
```
因为anInteger被声明为__block变量，所以它的存储空间与block声明共享。这意味着日志输出现在显示:
`Integer is: 84`
这也意味着块可以修改原始值，如下所示:
```
    __block int anInteger = 42;
 
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
        anInteger = 100;
    };
 
    testBlock();
    NSLog(@"Value of original variable is now: %i", anInteger);
```
现在输出为：
```
Integer is: 42
Value of original variable is now: 100

```

### 可以将Block作为参数传递给方法或者函数
前面的每个示例都在定义块之后立即调用它。实际上，将块传递给其他地方调用的函数或方法是很常见的。例如，你可以使用Grand Central Dispatch在后台调用一个块，或者定义一个块来表示要重复调用的任务，例如在枚举集合时。
块也用于回调，定义任务完成时要执行的代码。例如，你的应用程序可能需要通过创建执行复杂任务的对象来响应用户操作，例如从web服务请求信息。由于任务可能需要很长时间，因此应该在任务发生时显示某种进度指示器，然后在任务完成后隐藏该指示器。
```
- (IBAction)fetchRemoteInformation:(id)sender {
    [self showProgressIndicator];
 
    XYZWebTask *task = ...
 
    [task beginTaskWithCallbackBlock:^{
        [self hideProgressIndicator];
    }];
}
```
这个例子调用一个方法来显示进度指示器，然后创建任务并告诉它开始。回调块指定任务完成后执行的代码;在这种情况下，它只是调用一个方法来隐藏进度指示器。注意，这个回调块捕获self，以便在调用时能够调用hideProgressIndicator方法。捕获self时要小心，这很重要，因为很容易创建一个强引用循环，正如后面在捕获self时避免强引用循环所描述的那样。
在代码可读性方面，该块可以很容易地在一个地方看到任务完成之前和之后会发生什么，从而避免了通过委托方法来跟踪将要发生什么。

### 块应该始终是方法的最后一个参数
最好的做法是在一个方法中只使用一个块参数。如果方法还需要其他非块参数，则块应该放在最后:
```
- (void)beginTaskWithName:(NSString *)name completion:(void(^)(void))callback;
```
这使得方法调用在内联指定块时更容易阅读，如下所示:
```
 [self beginTaskWithName:@"MyTask" completion:^{
        NSLog(@"The task is complete");
    }];

```
### 使用类型定义来简化块语法
如果需要用相同的签名定义多个块，则可能需要为该签名定义自己的类型。
例如，你可以为一个简单的块定义一个没有参数或返回值的类型，如下所示:
`typedef void (^XYZSimpleBlock)(void);`
然后你可以在方法参数或创建块变量时使用你的自定义类型:
```
XYZSimpleBlock anotherBlock = ^{
        ...
    };
```
### 对象使用属性来跟踪块
定义跟踪块的属性的语法类似于块变量:
```
@interface XYZObject : NSObject
@property (copy) void (^blockProperty)(void);
@end
```
**注意：
应该指定copy作为属性特征，因为需要复制块以跟踪其在原始作用域之外捕获的状态。在使用自动引用计数时，你不需要担心这个问题，因为它会自动发生，但是最好的做法是让property属性显示结果行为。**

### 在捕获self时避免强引用循环
如果需要在块中捕获self，例如在定义回调块时，那么考虑内存管理含义是很重要的。
block维护对任何捕获对象的强引用，包括self，这意味着很容易以强引用循环结束，例如，一个对象维护捕获self的block的copy属性:
```
@interface XYZBlockKeeper : NSObject
@property (copy) void (^block)(void);
@end
```
```
@implementation XYZBlockKeeper
- (void)configureBlock {
    self.block = ^{
        [self doSomething];    // capturing a strong reference to self
                               // creates a strong reference cycle
    };
}
...
@end
```
对于这样一个简单的示例，编译器会警告你，但是一个更复杂的示例可能涉及对象之间的多个强引用来创建循环，从而使其更难以诊断。
为了避免这个问题，最好的做法是捕获对self的弱引用，如下所示:
```
- (void)configureBlock {
    XYZBlockKeeper * __weak weakSelf = self;
    self.block = ^{
        [weakSelf doSomething];   // capture the weak reference
                                  // to avoid the reference cycle
    }
}
```
通过捕获指向self的弱指针，块将不会保持与XYZBlockKeeper对象的强关系。如果该对象在调用块之前被释放，则weakSelf指针将被简单地设置为nil。
 
## 处理错误
几乎每个应用都会遇到错误。其中一些错误将超出你的控制范围，例如磁盘空间耗尽或失去网络连接。其中一些错误是可以恢复的，比如无效的用户输入。而且，虽然所有开发人员都力求完美，但偶尔也会出现程序员错误。
如果你来自其他平台和语言，那么你可能习惯于处理大多数错误处理的异常。当你用Objective-C编写代码时，异常仅用于程序员错误，如越界数组访问或无效的方法参数。这些都是你应该在发布应用前的测试过程中发现并修复的问题。
所有其他错误都由NSError类的实例表示。

### 对大多数错误使用NSError
错误是任何应用生命周期中不可避免的一部分。例如，如果你需要从远程web服务请求数据，可能会出现各种潜在问题，包括:
没有网络连接
远程web服务可能无法访问
远程web服务可能无法提供您请求的信息
你收到的数据可能与你所期望的不匹配
遗憾的是，我们不可能为每一个可能的问题都制定应急计划和解决方案。相反，你必须为错误做好计划，并知道如何处理它们，以提供最佳的用户体验。
 
### 一些委托方法会提醒你错误
如果你正在实现一个委托对象，以便与执行特定任务的框架类一起使用，例如从远程web服务下载信息，通常会发现你需要实现至少一个与错误相关的方法。例如，NSURLConnectionDelegate协议包含一个connection:didFailWithError:方法:
```
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
```
如果发生错误，将调用这个委托方法为你提供一个NSError对象来描述问题。
NSError对象包含数字错误代码、域和描述，以及打包在用户信息字典中的其他相关信息。
。

### 异常用于程序员错误
Objective-C支持异常的方式与其他编程语言大致相同，语法与Java或c++相似。和NSError一样，Cocoa和Cocoa Touch中的异常是对象，由NSException类的实例表示
如果需要编写可能导致抛出异常的代码，可以将该代码包含在try-catch块中:
```
 @try {
        // do something that might throw an exception
    }
    @catch (NSException *exception) {
        // deal with the exception
    }
    @finally {
        // optional block of clean-up code
        // executed whether or not an exception occurred
    }
```
如果@try块内的代码抛出异常，它将被@catch块捕获，以便你可以处理它。例如，如果你正在使用使用异常进行错误处理的低级c++库，你可能会捕获其异常并生成合适的NSError对象以显示给用户。
如果抛出异常而未捕获异常，则默认的未捕获异常处理程序将一条消息记录到控制台并终止应用程序。
你不应该使用try-catch块来代替Objective-C方法的标准编程检查。例如，在NSArray的情况下，在尝试访问给定索引的对象之前，你应该始终检查数组的计数以确定项的数量。如果你发出越界请求，objectAtIndex:方法会抛出一个异常，这样你就可以在开发周期的早期发现代码中的错误——你应该避免在交付给用户的应用程序中抛出异常。
 
## 参考
1. https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html#//apple_ref/doc/uid/TP40011210-CH6-SW1
2. https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Blocks/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40007502
