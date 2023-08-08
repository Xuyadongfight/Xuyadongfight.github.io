---
layout: post
title: Objective-C基础进阶系列-3
subtitle: 方法缓存
categories: iOS
tags: [iOS,cache_t]
---
## 从`cache_t`聊聊方法调用的优化

## 方法的结构
方法的结构包含什么，方法其实从定义就知道。
```
- (void)test:(id)param1{
    NSLog(@"test");
}
```
包含方法名，返回值及参数，方法体。三部分内容。

### 方法名SEL
通过`@selector`就可以直接获取方法名。类型是SEL。
```
SEL my_sel);
```
通过将方法改下为c++可以发现就是调用了`sel_registerName`方法
![IMAGE](/assets/images/resources/A248C1169B38BE88EAA38766CAFB2E11.jpg)
![IMAGE](/assets/images/resources/B5C97BA526A5BC89016E84B1557D87B3.jpg)
如果之前使用字符串注册过选择器则直接返回，否则创建新的选择器返回。

查看源码发现SEL是一个objc_selector结构体类型的指针。但是我们又找不到这个结构体的实现。
![IMAGE](/assets/images/resources/A0FE7B4F3B4EA15EFDD20C135A12E23D.jpg)
实际上它只是为了隐藏选择器实现的细节。本质上就是个C字符串。通过定义objc_selector和C字符串区分开来。通过下面两个方法就能看出来
![IMAGE](/assets/images/resources/090DE88F56981EA4D7D688104F2A1A52.jpg)
返回选择器的名称直接类型转化为了`char *`。

### 方法体入口地址IMP
方法名只是一个用来寻找方法地址的符号，真正使用方法需要找到方法的地址。
![IMAGE](/assets/images/resources/25A103588193173333B7FDD697AFAC79.jpg)
可以看到IMP就是一个简单的方法指针，这个方法的返回值为id类型，参数是变长参数，第一个参数为id,第二个参数为SEL,后面是变长参数。

### 方法返回值及参数类型编码@encode
使用`@encode`对类型进行编码
```
- (void)test:(id)param1{
    const char* retChar);
    const char* selectorChar);
    const char* paramChar);
    printf("%s %s %s",retChar,selectorChar,paramChar); //v : @
}
```
更多类型编码参考https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100

### 方法的定义`Method`
![IMAGE](/assets/images/resources/17FCBFDD298E07AED39661B130251DF2.jpg)
发现方法`Method`是一个指向结构体`method_t`的指针。
![IMAGE](/assets/images/resources/35D162A90A24B18A352C6D9C27AB4DB4.jpg)
可以看到方法的定义其实就是上面提到的方法名name，方法返回值及类型编码types，方法体地址imp。
![IMAGE](/assets/images/resources/30B05D77FB96A3270CEF0F9483985DE8.jpg)
从它的初始化及几个方法中就可以看出，它实际上就是方法返回值及参数类型编码的一个对象表示。

### 扩展针对方法封装的一些面向对象的类
#### 方法签名NSMethodSignature
它是记录方法的返回值和参数的类型信息的一个对象。
![IMAGE](/assets/images/resources/80B928B06C133BEAC31D8F45B40DC103.jpg)
**1. 顺序问题？**
我们知道按照方法的定义`- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event`的编码应该是返回值类型void编码为`v`,方法名SEL编码为`:`,第一个参数和第二个参数都是id类型编码为`@`。那么加起来的编码应该是`v:@@`。但为什么最后获取到的编码为`v@:@@`(先忽略数字)。这是因为在OC中的方法调用实际上大部分都被转为了`objc_msgSend`调用。而它的固定参数第一个为调用方法的对象，第二个参数为方法名。即
```
void
objc_msgSend(void /* id self, SEL op, ... */ )
```
所以这里`touchesBegan`的方法编码为返回值`v`,第一个参数为对象本身`@`，第二个参数为方法名SEL`:`然后就是剩余的参数touches对象为`@`和event对象为`@`。即`v@:@@`。

**2. 类型后面的数字字符意思？**
![IMAGE](/assets/images/resources/3B12F3A45727E613D7B00CE5F2A0BDAE.jpg)
可以看到通过`method_getTypeEncoding`方法获取的方法类型编码，每个字符后面都跟着数字字符。通过runtime源码发现方法`encoding_getSizeOfArguments`。后面的数字字符表示的是参数所占栈空间的大小。显然从方法名可以看出来，返回值后面的数字字符表示所有参数所占栈空间的内存大小。

#### 方法调用NSInvocation
NSInvocation是作为对象呈现的Objective-C消息。
![IMAGE](/assets/images/resources/E68F4FC041EB9A9A4024D45BEB0332C7.jpg)
可以发现它是通过方法签名`NSMethodSignature`进行初始化，并通过`invoke`方法调用。自己创建一个消息对象，并进行调用。
![IMAGE](/assets/images/resources/9D4162C7B53A11D52549F4585BFE8CAF.jpg)

## 方法调用的过程
方法的调用会被转为`objc_msgSend`和`objc_msgSendSuper`的调用。我们用`objc_msgSend`来分析。当一个对象调用实例方法时候。编译器会将其转为`objc_msgSend`方法。这个方法的固定参数为：第一个参数要调用方法的对象，第二个参数为方法名SEL。剩下的参数则是OC方法定义的参数。`objc_msgSend`的调用过程为：
1. 判断第一个参数对象是否为空，为空则直接返回。（这也是为什么空对象调用方法不会崩溃的原因）
2. 通过对象的isa查找到类，查找类方法的缓存。找到则直接调用方法。
3. 缓存中没找到则查找类中的方法列表，并且沿着继承链产找方法。
4. 还是没找到进入动态方法决议阶段`resolveInstanceMethod`自己能否解决
5. 不能解决就进入快速消息转发，即`forwardingTargetForSelector`看是不是转发给其它对象处理
6. 接着进入慢速消息转发，即通过`methodSignatureForSelector`及`forwardInvocation`根据方法名创建方法签名及消息的封装对象。
7. 如果没有返回方法签名或者没有实现`forwardInvocation`方法则会抛出未识别到的方法错误

### 方法调用优化缓存
通过上面方法调用的过程可以发现，如果去掉缓存这一步，会发现哪怕是连续调用相同的方法，每次都需要进入类中的方法列表中查找，显然很影响方法的执行效率。于是又了缓存，将最近调用的方法放入缓存中，下次调用时直接去缓存中查找，提高方法调用的效率。

## 方法缓存是怎么做的
### 方法缓存的结构cache_t
![IMAGE](/assets/images/resources/922BD21DC1AAAB6B22410867BE5843C0.jpg)
superclass是为了实现继承功能指向父类的一个指针。我们主要看看`cache_t`做了什么。
![IMAGE](/assets/images/resources/176C10DD413B4A92AB20B578FD81A55E.jpg)
`cache_t`中主要是一个`bucket_t *`类型指针
![IMAGE](/assets/images/resources/D0B17E37CB43D097F06474655AD10CE2.jpg)
而结构体`bucket_t`就比较简单了，就是一个key值一个方法地址。

通过`cache_fill_nolock`来看方法缓存的初始化大小，查找方式和扩容
![IMAGE](/assets/images/resources/9D8DD113A58AF5E3013B6B4126AB5CC7.jpg)

### 初始化
![IMAGE](/assets/images/resources/C388A73A1B1611C420F0ED186F44F476.jpg)
![IMAGE](/assets/images/resources/D764D4E00CC5A147A947A6F9F10A6216.jpg)
![IMAGE](/assets/images/resources/E2B30E2C7EF64D2912779886894B00EC.jpg)
可以看到初始化时，cache的容量为1左移两位为4。

### 查找方式
![IMAGE](/assets/images/resources/B39A12D5BD113459ACE5F311F3B5634F.jpg)
![IMAGE](/assets/images/resources/4305E6CD8D4FCD7A96016AB24CD68D8A.jpg)
通过将key值和mask做位与运算进行哈希来获取下标取值。

### 扩容
![IMAGE](/assets/images/resources/DB72E19E6260FEF08D95F22264E30222.jpg)
![IMAGE](/assets/images/resources/C961E38688744CD8341811A16BC65AF9.jpg)
![IMAGE](/assets/images/resources/D66D6C80B20D28805E86BBF004283152.jpg)
当当前容量大于总容量的四分之三时进行扩容，并且新容量为原来总容量的两倍。并且原来的缓存不会被保留。

## 参考
1. https://zhuanlan.zhihu.com/p/142819413
2. https://tech.meituan.com/2015/08/12/deep-understanding-object-c-of-method-caching.html
