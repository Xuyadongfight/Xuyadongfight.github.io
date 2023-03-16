# KVC
kvc全称key-value coding 键值编码
常用用法
![IMAGE](resources/4595F05EF41AE72FFA7DE843D50970CE.jpg =519x98)

设值原理
1.先调用三种setter方法，顺序为set<Key>:  _set<Key>  setIs<Key>
2.如果三个方法不存在，则查找accessInstanceVariablesDirectly方法。如果返回YES则查找实例变量进行赋值 顺序为_<key>  _is<Key> <key> is<Key> 如果找到任意一个则直接赋值。
3.如果方法和实例变量都没有找到，则执行默认的setValue:forUndefinedKey:方法，默认抛出NSUndefinedKeyException异常

取值原理
1.查找getter方法，按照get<Key> <key> is<Key>  _<key>的方法顺序查找。
2.如果以上的方法没找到，则调用accessInstanceVariablesDirectly确定是否允许访问成员变量，依次访问_<key>  _is<key>  <key> is<Key>的实例变量。
3.如果上面的方法都没有找到，则调用valueForUndefinedKey:方法抛出NSUndefinedKeyException类型的异常。
如果取到了值，是对象则直接返回，如果是NSNumber支持的类型，则转为NSNumber对象返回，如果是NSNumber不支持的类型则转为NSValue对象返回。

kvc使用场景
1,动态设置和取值 比如一些json解析库就是使用kvc来设置对应的属性。setValuesForKeysWithDictionary:
2,通过KVC访问和修改私有变量。对于一些类的私有属性，可以访问和修改私有属性。比如有些系统控件的属性苹果没有提供访问的API，这时就可以通过kvc来访问和修改。
3,在对容器类使用KVC时，valueForKey:将会被传递给容器中的每一个对象，而不是对容器本身进行操作，结果会被添加到返回的容器中，这样可以很方便的操作集合来返回另一个集合。

# KVO
kvo 全称 key-value observing 键值观察
作用：可以将指定对象的属性的更改通知给观察者对象。
使用注意：注册和移除需要成对出现。不观察之后需要移除观察者。
常见不移除观察者导致的崩溃。

kvo实现的原理 通过动态创建一个被观察对象的子类，然后将当前被观察类的isa指向新的类。并且重写了被观察属性的set方法。