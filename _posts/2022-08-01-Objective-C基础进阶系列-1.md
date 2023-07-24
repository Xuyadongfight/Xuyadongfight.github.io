---
layout: post
title: Objective-C基础进阶系列-1
subtitle: Objective-C基础进阶系列-1
categories: iOS
tags: [iOS,Objective-C]
---
## 从面向对象的三个特征来看Objective-C


### 封装
通过创建类来封装具有相同属性和方法的对象，类是对象的模板。再通过对象中的isa来关联类来共享属性和方法。

**id和Class类型**

---

![IMAGE](/assets/images/resources/97E661696E0820219AD025AE76BB2B1E.jpg)

---


**objc_object结构**

---

![IMAGE](/assets/images/resources/8E7011F7B502AAA79C7D5FAABF7D3807.jpg)

---


**objc_class结构**

---

![IMAGE](/assets/images/resources/F2E310068662D03B22A2E083E0CED463.jpg)

---

### 扩展
**1. 为什么id和Class能接受所有对象和类？**
```
+ (void)start{
    id tempObj;
    NSObject *obj = [[NSObject alloc] init];
    NSString *str = @"test";
    NSNumber *number = @123;
    tempObj = obj;
    tempObj = str;
    tempObj = number;
    
    Class tempClass;
    tempClass = [NSObject class];
    tempClass = [NSString class];
    tempClass = [NSNumber class];
}
```
思考一下如果定义以下两个结构体：
```
typedef struct{
    int a;
}structA;

typedef struct{
    int a;
    double b;
}structB;
```
怎么使用一个通用的类型表示。
计算机领域有句名言：计算机科学领域的任何问题都可以通过增加一个间接的中间层来解决。虽然structA和structB所占内存大小不同，但是如果添加一个指针中间层，不管是什么类型，在64位机器下它的指针大小一定是8个字节大小。我们可以定义一个新的结构
```
typedef struct{
    int a;
}structGeneral;
```
表示structA和structB类型的时候都用structGeneral的指针来表示
```
{
    structA a = {10};
    structB b = {10,1000};
    
    structGeneral *pa = &a;
    structGeneral *pb = &b;
}
```
我们使用一个通用类型来表示了structA和structB。但是还是有不好的地方。对于structB，当我们将其转化为structGeneral时，它的成员变量b的信息被我们丢失了。既然我们可以通过指针将两个不同的结构体大小转为同样的指针大小，那么我们能不能将成员变量的信息也转为指针描述，这样它们所占内存大小就一样了。
```
typedef struct{
    void *my_ivars;//指针指向描述structA的成员变量信息的地址 int a
}structA;

typedef struct{
    void *my_ivars;//指针指向描述structB的成员变量信息的地址 int a;double b;
}structB;
```
再回头看看objc_class结构中的bits。虽然看起来它好像不是一个指针。但接着往下看它的data方法，返回了一个class_rw_t类型的指针。你会发现它只是用了一个小小的障眼法而已。如果看老版本的源码你会发现，它甚至没有使用障眼法。
![IMAGE](/assets/images/resources/2A1290F4DBCD5F50723529DBCEA1A857.jpg)
总的来说，id和Class能接受所有对象和类的根本原因是：1.通过指针这个中间层抹平不同类型之间的内存大小区别 2.将相同的部分提取出来作为通用的表示。

### 继承
类之间的继承通过类结构中的superclass来实现。
**isa及superclass指向**

---

![IMAGE](/assets/images/resources/2AC20B7CD03D8C3855A6BC083C5DF8CA.jpg)

---

封装形成类，通过类模板创建相应的实例。而实例和类之间的关系通过isa相关联，即实例的isa指向的是类。然后又通过类的superclass形成继承的关系。

### 扩展
**1. meta class是什么？为什么有它？**
meta class我们称之为元类。我们都知道类是实例的模板。没错正如你所想的那样元类是类的模板。
元类怎么来的，这就要从第一个面向对象的编程语言Smalltalk说起。在Smalltalk中，一切都是对象。此外，Smalltalk是一个基于类的系统，这意味着每个对象都有一个类，这个类定义了该对象的结构(即对象拥有的实例变量)和对象理解的消息。总之，这意味着Smalltalk中的类是一个对象，因此类需要是一个类的实例(称为元类)。早期所有类的元类是同一个，也就意味着是没有类实例变量和类方法的。到了后期不同的类拥有不同的类方法，于是每个类都有一个单独的元类。

**2. 为什么所有类的isa最终指向meta Root class?**
因为所有的元类的行为是一样的，你不能为元类添加类方法，所有它们都是同一个类的实例，根元类的实例。即所有元类的isa都是指向根元类。

**3. 为什么所有类的meta Root class 的superclass最终指向 Root class，而不是像Root class 一样指向nil?**
根类中定义了一系列的实例方法。当根元类的superclass指向根类之后，就可以保证所有类对象最终都是根类的实例，这样就可以在类对象本身上使用根类的实例方法。

### 多态
同一个父类的不同子类的实例对象，调用同一个方法，产生不同的行为就是多态。这个的实现是通过Objective-c特有的消息机制实现的。
OC中的消息发送都被转为`objc_msgSend`和`objc_msgSendSuper`。以`objc_msgSend`举例。它的第一个参数为发送消息的对象本身。通过对象本身的isa找到对应的类。然后在不同的类中查找要调用的方法。因为不同的子类中的方法重写了父类的同名方法。即根据相同的方法名找到的方法实现是不同的。最终产生的效果就是调用同一个方法，产生不同的行为。

## 参考
1. https://en.wikipedia.org/wiki/Metaclass
