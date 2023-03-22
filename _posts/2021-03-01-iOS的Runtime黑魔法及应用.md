---
layout: post
title: Runtime
subtitle: Runtime及应用
categories: iOS
tags: [Runtime]
---
## Runtime方法的前缀

* objc_
* class_
* object_
* property_
* ivar_
* method_
* sel_
* imp_
* protocol_

## 1.根据字符串获取类，方法，协议。

![IMAGE](/assets/images/resources/EF46A5803405F42163EE32F785F74EB8.jpg)

### 应用

CTMediator模块化解耦
通过字符串获取类及方法来达到跨模块调用解耦对应类的引用。

## 2.获取类的信息。比如：属性,成员变量，方法，协议。

通过class_copypropertylist,class_copyIvarList等一系列的方法。

### 应用

json解析 MJExtension
通过动态获取类的属性，来实现将json数据动态赋值给对象。

## 3.通过分类来给已有类添加关联对象。形式上看起来像是添加了成员变量

objc_setAssociatedObject ,objc_getAssociatedObject

### 应用
需要给已有的类关联对象的时候

## 4.替换方法实现

class_replaceMethod;method_exchangeImplementations,method_setImplementation替换方法实现。

### 应用

常用的替换系统方法实现的地方。比如检测视图控制器的内存泄漏
通过替换视图控制器的viewDidDisAppear方法，来进行自己的操作。
将调用viewDidDisAppear方法的控制器认为其应该要马上被销毁的对象。持有其弱引用进行延时调用，如果延时调用失败说明其正常被释放。反之则说明该对象还存在，弱应用并没有被置为nil。则说明其发生了内存泄漏。

## 5.修改实例的isa指向

object_setClass

### 应用
基于替换当前类的isa实现热重载

## 6.动态创建类

objc_allocateClassPair,objc_registerClassPair

### 应用
kvo的实现；

## 后面会出一些runtime相关的应用实现
