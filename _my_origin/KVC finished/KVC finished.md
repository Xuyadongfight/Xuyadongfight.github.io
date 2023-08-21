## 键值编码
键值编码是由NSKeyValueCoding非正式协议启用的一种机制，对象采用该协议来提供对其属性的间接访问。当对象符合键值编码时，可以通过简洁、统一的消息传递接口通过字符串参数对其属性进行寻址。这种间接访问机制补充了实例变量及其相关访问方法提供的直接访问。
通常使用访问器方法来访问对象的属性。get访问器(或getter)返回属性的值。set访问器(或setter)用于设置属性的值。在Objective-C中，你也可以直接访问属性的底层实例变量。以上述任何一种方式访问对象属性都很简单，但需要调用特定于属性的方法或变量名。随着属性列表的增长或变化，访问这些属性的代码也必须增长或变化。相反，符合键值编码的对象提供了一个简单的消息传递接口，该接口在其所有属性上保持一致。
键值编码是许多其他Cocoa技术的基础概念，例如键值观察、Cocoa绑定、Core Data 和applescript能力。在某些情况下，键值编码还可以帮助简化代码。
使用符合键值编码的对象
对象在直接或间接继承NSObject时，通常采用键值编码。NSObject既采用NSKeyValueCoding协议，又为基本方法提供默认实现。这样的对象通过紧凑的消息传递接口使其他对象能够执行以下操作:
 
## 访问对象属性
对象通常在其接口声明中指定属性，这些属性属于以下几个类别之一:
* **属性**这些是简单的值，如标量、字符串或布尔值。值对象如NSNumber和其他不可变类型如NSColor也被认为是属性。
* **一对一关系**这些都是具有自己属性的可变对象。对象的属性可以在对象本身不改变的情况下改变。例如，一个银行帐户对象可能有一个owner属性，该属性是Person对象的一个实例，Person对象本身有一个address属性。业主地址可以变更，但不改变银行账户中持有的业主资料。银行账户的所有者没有改变。只有他们的地址改变。
* **一对多关系**这些是集合对象。你通常使用NSArray或NSSet的实例来保存这样的集合，尽管也可以使用自定义的集合类。

![IMAGE](resources/F5FDC220A52247D94B92354A87281374.jpg =696x218)
为了保持封装，对象通常为其接口上的属性提供访问器方法。对象的作者可以显式地编写这些方法，也可以依赖编译器自动地合成它们。无论哪种方式，使用这些访问器之一的代码的作者必须在编译代码之前将属性名称写入代码中。访问器方法的名称成为使用它的代码的静态部分。例如，给定清单2-1中声明的银行帐户对象，编译器将合成一个setter，你可以为myAccount实例调用该setter:
`[myAccount setCurrentBalance: @ (100.0)];`
这是直接的，但缺乏灵活性。另一方面，符合键值编码的对象提供了一种更通用的机制，可以使用字符串标识符访问对象的属性。

### 用键和键路径识别对象的属性
键是标识特定属性的字符串。通常，按照约定，表示属性的键是在代码中出现的属性本身的名称。键必须使用ASCII编码，不能包含空格，并且通常以小写字母开头(尽管也有例外，例如在许多类中发现的URL属性)。
可以通过键设置值。
`[myAccount setValue:@(100.0) forKey:@"currentBalance"];`
实际上，你可以使用不同的键参数使用相同的方法来设置myAccount对象的所有属性。由于参数是字符串类型，因此它可以在运行时操作的变量。
键路径是由点分隔的键组成的字符串，用于指定要遍历的对象属性序列。序列中第一个键的属性相对于接收者，每个后续键都相对于前一个属性的值进行评估。键路径对于使用单个方法调用深入遍历对象层次结构非常有用。
例如，应用于银行账户实例的键路径owner.address.street指的是存储在银行账户拥有者的地址中的街道字符串的值，假设Person和Address类也与键值编码兼容。
 
### 使用键和键路径获取属性值。
当对象遵循NSKeyValueCoding协议时，它是键值编码兼容的。从NSObject继承的对象，该对象提供了协议基本方法的默认实现，会自动采用此协议并具有某些默认行为。这样的对象至少实现了以下基本基于键的getter：

* **valueForKey:** - 返回由键参数命名的属性的值。如果根据访问器搜索模式中描述的规则无法找到由键命名的属性，则对象会发送一个valueForUndefinedKey:消息。valueForUndefinedKey:的默认实现会引发NSUndefinedKeyException，但子类可以覆盖此行为并以更优雅的方式处理这种情况。

* **valueForKeyPath:** - 返回相对于接收者指定的键路径的值。对于特定键的任何对象，在键路径序列中的任何对象都不遵循键值编码 - 即，对于默认实现的valueForKey:无法找到访问器方法 - 对象会收到valueForUndefinedKey:消息。

* **dictionaryWithValuesForKeys:** - 返回相对于接收者的一组键的值。该方法对数组中的每个键调用valueForKey:。返回的NSDictionary包含数组中所有键的值。
 
当你使用键路径访问属性时，如果键路径中的除最后一个键以外的任何键都是一对多关系（即，它引用了一个集合），则返回的值是一个包含所有右侧一对多键值的集合。例如，请求键路径transactions.payee的值将返回一个包含所有交易的所有付款人对象的数组。这也可以适用于键路径中的多个数组。键路径accounts.transactions.payee将返回一个包含所有账户中所有交易的所有付款人对象的数组。

### 使用键设置属性值。
与getters一样，遵循NSKeyValueCoding协议的对象还提供一组具有基于NSObject中的NSKeyValueCoding协议的实现的默认行为的通用setter。

* **setValue:forKey:** - 将接收消息的对象中指定键的值设置为给定值。setValue:forKey:的默认实现会自动解包表示标量和结构的NSNumber和NSValue对象，并将它们分配给属性。有关包装和解包语义的详细信息，请参阅“表示非对象值”。
如果指定的键对应于接收setter调用的对象没有的属性，则对象会发送一个setValue:forUndefinedKey:消息。setValue:forUndefinedKey:的默认实现会引发NSUndefinedKeyException。但是，子类可以覆盖此方法以以自定义方式处理请求。

* **setValue:forKeyPath:** - 在接收者指定的键路径处设置给定值。键路径序列中的任何对象都不会为特定键进行键值编码，都会收到setValue:forUndefinedKey:消息。

* **setValuesForKeysWithDictionary:** - 使用指定字典中的值设置接收者的属性，使用字典键标识属性。默认实现对每个键值对调用setValue:forKey:，根据需要将NSNull对象替换为nil。


在默认实现中，当你尝试将非对象属性设置为nil值时，遵循键值编码的对象会发送自己一个setNilValueForKey:消息。setNilValueForKey:的默认实现会引发NSInvalidArgumentException，但对象可以覆盖此行为，以插入默认值或标记值，如“处理非对象值”中所述。

### 使用键简化对象访问
要了解基于键的getter和setter如何简化代码，请考虑以下示例。在macOS中，NSTableView和NSOutlineView对象将每个列的标识符字符串与它们关联起来。如果支持表格的模型对象不符合键值编码要求，则表格的数据源方法必须逐个检查每个列标识符，以找到正确的属性返回，如清单2-2所示。此外，将来，如果您向模型添加另一个属性（在这种情况下是Person对象），您还必须重新访问数据源方法，添加另一个条件来测试新属性并返回相关值。
![IMAGE](resources/27C74694B1C8D43DC75BBF564FA90CB4.jpg =726x421)

另一方面，清单2-3显示了利用键值编码兼容的Person对象的相同数据源方法的更紧凑的实现。仅使用valueForKey: getter，数据源方法使用列标识符作为键返回适当的值。除了更短之外，它还更加通用，因为它在以后添加新列时仍然可以保持不变，只要列标识符始终与模型对象的属性名称匹配即可。
![IMAGE](resources/2A347E9E6126F8DE25417ECBCA83ED0F.jpg =714x176)

## 访问集合属性
键值编码兼容的对象以相同的方式暴露他们的多对多属性。您可以使用valueForKey:和setValue:forKey:（或其键路径等效项）获取或设置集合对象，就像您使用任何其他对象一样。但是，当您想要操作这些集合的内容时，通常最高效的方法是使用协议定义的可变代理方法。
协议为集合对象访问定义了三种不同的代理方法，每种方法都有一个键和一个键路径变体：

* mutableArrayValueForKey:和mutableArrayValueForKeyPath:这些返回一个像NSMutableArray对象一样行为的代理对象。

* mutableSetValueForKey:和mutableSetValueForKeyPath:这些返回一个像NSMutableSet对象一样行为的代理对象。

* mutableOrderedSetValueForKey:和mutableOrderedSetValueForKeyPath:这些返回一个像NSMutableOrderedSet对象一样行为的代理对象。

当你操作代理对象时，向其中添加对象、从中删除对象或替换对象，协议的默认实现会相应地修改底层属性。这比使用valueForKey:获取非可变集合对象、使用更改后的内容创建修改后的集合对象并将其存储回具有setValue:forKey:消息的对象更高效。在许多情况下，它与直接使用可变属性相比也更高效。这些方法提供了额外的优势，即维护集合对象中对象的键值观察兼容性。

## 使用集合运算符
当您向键值编码兼容的对象发送valueForKeyPath:消息时，可以在键路径中嵌入集合运算符。集合运算符是一小串以@符号开头的关键字之一，指定获取器在返回之前应该如何以某种方式操作数据。NSObject提供的valueForKeyPath:的默认实现提供了这种行为。
当键路径包含集合运算符时，运算符之前的任何部分，称为左键路径，表示相对于消息接收者要操作的集合。如果您直接将消息发送到集合对象（如NSArray实例），则可以省略左键路径。
运算符之后的键路径部分，称为右键路径，指定运算符应在集合中操作的属性。除@count之外的所有集合运算符都要求右键路径。图4-1说明了运算符键路径格式。
![IMAGE](resources/FDEE2ABE92FDDC267C20949150AC43A8.jpg =671x115)

集合运算符表现出三种基本的行为：
* **聚合运算符**以一种某种方式合并集合中的对象，并返回一个通常与右键路径中命名的属性的数据类型匹配的单个对象。@count运算符是一个例外，它不需要右键路径，并且总是返回一个NSNumber实例。

* **数组运算符**返回一个包含命名集合中某些对象的NSArray实例。

* **嵌套运算符**对包含其他集合的集合进行操作，并根据运算符返回一个NSArray或NSSet实例，以某种方式组合嵌套集合中的对象。

定义一个类
```
@interface Transaction : NSObject
 
@property (nonatomic) NSString* payee;   // To whom
@property (nonatomic) NSNumber* amount;  // How much
@property (nonatomic) NSDate* date;      // When
 
@end

self.transactions = @[[Transaction new],[Transaction new],[Transaction new]];
```
### 聚合运算符
聚合运算符（Aggregation Operators）用于处理数组或属性集合，生成一个反映集合某个方面的单个值。

#### @avg
当你指定@avg运算符时，valueForKeyPath:会读取由右键路径指定的集合中每个元素的属性，将其转换为双精度浮点数（将nil值替换为0），并计算这些值的算术平均值。然后，它返回存储在NSNumber实例中的结果。
```
NSNumber *transactionAverage = [self.transactions valueForKeyPath:@"@avg.amount"];
```
#### @count
当您指定@count运算符时，valueForKeyPath:会返回NSNumber实例中集合中对象的数量。如果存在正确的键路径，则会被忽略。
```
NSNumber *numberOfTransactions = [self.transactions valueForKeyPath:@"@count"];
```

#### @max
当您指定@max运算符时，valueForKeyPath:会在由正确的键路径命名的集合条目中进行搜索，并返回最大的一个。搜索使用compare:方法进行比较，这是由许多Foundation类定义的，例如NSNumber类。因此，由正确的键路径指示的属性必须持有一个对此消息有意义响应的对象。搜索忽略nil值的集合条目。
```
NSDate *latestDate = [self.transactions valueForKeyPath:@"@max.date"];
```
#### @min
当您指定@min运算符时，valueForKeyPath:会在由正确的键路径命名的集合条目中进行搜索，并返回最小的一个。搜索使用compare:方法进行比较，这是由许多Foundation类定义的，例如NSNumber类。因此，由正确的键路径指示的属性必须持有一个对此消息有意义响应的对象。搜索忽略nil值的集合条目。
```
NSDate *earliestDate = [self.transactions valueForKeyPath:@"@min.date"];
```

#### @sum
当您指定@sum运算符时，valueForKeyPath:会读取由正确的键路径指定的集合中每个元素的property，将其转换为double（将nil值替换为0），并计算这些值的总和。然后，它会返回存储在NSNumber实例中的结果。
```
NSNumber *amountSum = [self.transactions valueForKeyPath:@"@sum.amount"];
```

### 数组运算符
数组运算符使valueForKeyPath:返回由正确的键路径指示的一组对象对应的对象数组。

#### @distinctUnionOfObjects
当您指定@distinctUnionOfObjects运算符时，valueForKeyPath:会创建一个包含与由正确的键路径指定的属性对应的集合中不同对象的数组并返回。
```
NSArray *distinctPayees = [self.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
```

#### @unionOfObjects
当您指定@unionOfObjects运算符时，valueForKeyPath:会创建一个包含与由正确的键路径指定的属性对应的集合中所有对象的数组并返回。与@distinctUnionOfObjects不同，重复的对象不会被删除。
```
NSArray *payees = [self.transactions valueForKeyPath:@"@unionOfObjects.payee"];

```

### 嵌套运算符
嵌套运算符在嵌套集合上操作，其中集合本身的每个条目都包含一个集合。
**重要提示：当使用嵌套运算符时，如果任何叶对象为nil，valueForKeyPath:方法会引发异常。**
再定义一个新的数组
```
NSArray* moreTransactions = @[[Transaction new],[Transaction new],[Transaction new]];
NSArray* arrayOfArrays = @[self.transactions, moreTransactions];

```
#### @distinctUnionOfArrays
当您指定@distinctUnionOfArrays运算符时，valueForKeyPath:会创建一个包含由正确的键路径指定的属性对应的所有集合的组合的不同对象的数组并返回。
```
NSArray *collectedDistinctPayees = [arrayOfArrays valueForKeyPath:@"@distinctUnionOfArrays.payee"];
```

#### @unionOfArrays
当您指定@unionOfArrays运算符时，valueForKeyPath:会创建一个包含由正确的键路径指定的属性对应的所有集合的组合的所有对象的数组并返回，不会删除重复项。
```
NSArray *collectedPayees = [arrayOfArrays valueForKeyPath:@"@unionOfArrays.payee"];
```
#### @distinctUnionOfSets
当您指定@distinctUnionOfSets运算符时，valueForKeyPath:会创建一个包含由正确的键路径指定的属性对应的所有集合的组合的不同对象的NSSet并返回。
该运算符的行为类似于@distinctUnionOfArrays，除了它期望一个包含NSSet实例的NSSet实例而不是一个包含NSArray实例的NSArray实例。此外，它返回一个NSSet实例。假设示例数据已存储在集合中而不是数组中，则示例调用和结果与@distinctUnionOfArrays中显示的相同。

## 表示非对象值
NSObject提供的键值编码协议方法的默认实现可以处理对象和非对象属性。默认实现会自动在对象参数或返回值和非对象属性之间进行转换。这使得基于键的getter和setter的签名即使在存储的属性是标量或结构时也能保持一致。
当您调用协议的getter之一，例如valueForKey:时，默认实现根据Accessor Search Patterns中描述的规则确定为指定键提供值的特定访问器方法或实例变量。如果返回值不是对象，则getter使用此值初始化NSNumber对象（对于标量）或NSValue对象（对于结构体），并返回该值。
类似地，默认情况下，像setValue:forKey:这样的setter确定属性的访问器或实例变量所需的数据类型，给定特定的键。如果数据类型不是对象，则setter首先向传入的值对象发送适当的Value消息以提取底层数据，并将该值存储起来。
**注意：
当您为非对象属性调用键值编码协议的setter之一时，setter没有明显的通用操作步骤。因此，它向接收setter调用的对象发送setNilValueForKey:消息。此方法的默认实现会引发NSInvalidArgumentException异常，但子类可以重写此行为，例如在处理非对象值中描述的那样，以设置标记值或提供有意义的默认值。**

### 包装和解包标量(数值)类型
表5-1列出了默认键值编码实现使用NSNumber实例包装的标量类型。对于每种数据类型，表显示了用于从底层属性值初始化NSNumber以提供getter返回值的创建方法。然后它显示了在set操作期间从setter输入参数中提取值的访问器方法。
![IMAGE](resources/1F20E0FA3A2B91CC19AB4A27D5F6871A.jpg =711x516)
**注意在macOS中，出于历史原因，BOOL类型定义为有符号char，并且KVC不区分这些类型。因此，当键为BOOL时，不应将字符串值（如@“true”或@“YES”）传递给setValue:forKey:。KVC将尝试调用charValue（因为BOOL本质上是char），但NSString没有实现此方法，导致运行时错误。相反，仅将NSNumber对象（如@(1)或@(YES)）作为值参数传递给setValue:forKey:，当键为BOOL时。此限制不适用于iOS，在iOS中，BOOL类型定义为本机Boolean类型bool，并且KVC调用boolValue，这对于NSNumber对象或正确格式化的NSString对象都有效。**

### 包装和解包结构体
![IMAGE](resources/6B8DF1A54A8D17953D032C481C86EE84.jpg =710x209)
自动包装和解包不仅限于NSPoint、NSRange、NSRect和NSSize。结构类型（即Objective-C类型编码字符串以{开头的类型）可以被包装在NSValue对象中。例如，考虑在清单5-1中声明的结构体和类接口。
![IMAGE](resources/05595569B374CD62BBB37EBAAAB34412.jpg =727x573)

## 验证属性
键值编码协议定义了一些方法来支持属性验证。正如您可以使用基于键的访问器读取和写入符合键值编码的对象的属性一样，您也可以通过键（或键路径）验证属性。当您调用validateValue:forKey:error:（或validateValue:forKeyPath:error:）方法时，协议的默认实现会在接收验证消息的对象（或键路径末尾的对象）中搜索名称与pattern validate:error:匹配的方法。如果对象没有这样的方法，则默认情况下验证成功，并且默认实现返回YES。当存在特定于属性的验证方法时，默认实现返回调用该方法的结果。
由于属性特定的验证方法通过引用接收值和错误参数，因此验证有三种可能的结果：
1. 验证方法认为值对象有效，并在不更改值或错误的情况下返回YES。
2. 验证方法认为值对象无效，但选择不进行更改。在这种情况下，该方法返回NO并将错误引用（如果由调用者提供）设置为指示失败原因的NSError对象。
3. 验证方法认为值对象无效，但创建一个新的有效值作为替换。在这种情况下，该方法在不更改错误对象的情况下返回YES。在返回之前，该方法修改值引用以指向新的值对象。当进行修改时，该方法始终创建新对象，而不是修改旧对象，即使值对象是可变的。

![IMAGE](resources/7E400F206138D1DF61FC7EA74218070A.jpg =608x228)
通常情况下，键值编码协议及其默认实现没有定义任何自动执行验证的机制。相反，您在应用程序中适当时使用验证方法。
某些其他Cocoa技术在某些情况下会自动执行验证。例如，当托管对象上下文保存时，Core Data会自动执行验证。

## 访问器搜索模式
NSKeyValueCoding协议的默认实现由NSObject提供，它将基于键的访问器调用映射到对象的基础属性，使用一组明确定义的规则。这些协议方法使用键参数在其自己的对象实例中搜索访问器、实例变量和遵循某些命名约定的相关方法。尽管您很少修改此默认搜索，但了解其工作原理对于跟踪键值编码对象的行为以及使您自己的对象符合规范都是有帮助的。

### 基础Getter的搜索模式
valueForKey:的默认实现，给定一个键参数作为输入，执行以下过程，从接收valueForKey:调用的类实例中操作。
1. 在实例中搜索名称为get<Key>，<key>，is<Key>，or_<key>，按这个顺序，如果找到了调用并带着结果跳到第5步，否则继续执行下一步。
2. 如果没有找到简单访问器方法，则在实例中搜索名称匹配countOf<Key>和objectIn<Key>AtIndex:(对应于NSArray类定义的基本方法)和<key>AtIndex:(对应NSArray方法objectsAtIndexes:)。如果这些中的第一个和其他两个中的至少一个被找到，创建一个响应所有NSArray方法的集合代理对象并返回它。否则，继续执行步骤3。代理对象随后将它接收到的任何NSArray消息转换为countOf<Key>，objectIn<Key>AtIndex:，和<key>AtIndexes:消息发送给创建它的键值编码兼容对象。如果原始对象还实现了一个名为get<Key>:range:的可选方法，代理对象也会在适当的时候使用它。实际上，代理对象与键值编码兼容对象一起工作，允许底层属性表现得好像它是一个NSArray，即使它不是。
3. 如果没有找到简单的访问方法或数组访问方法组，则查找名为countOf<Key>，enumeratorOf<Key>，和memberOf<Key>:(对应于NSSet类定义的原语方法)的方法的三元组。如果所有三个方法都找到了，创建一个响应所有NSSet方法的集合代理对象并返回它。否则，继续执行步骤4。这个代理对象随后将它接收到的任何NSSet消息转换成countOf<Key>，enumeratorOf<Key>和memberOf<Key>:消息的某种组合，传递给创建它的对象。实际上，与键值编码兼容对象一起工作的代理对象允许底层属性表现得好像它是NSSet一样，即使它不是。
4. 如果没有找到简单的访问方法或集合访问方法组，并且如果接收方的类方法accessinstancevariablesdirect返回YES，则按此顺序搜索名为_<key>，_is<Key>，<key>，或者is<Key>的实例变量。如果找到，直接获取实例变量的值，然后继续步骤5。否则，继续执行步骤6。
5. 如果检索到的属性值是一个对象指针，只需返回结果。如果该值是NSNumber支持的数值类型，则将其存储在NSNumber实例中并返回。如果结果是NSNumber不支持的数值类型，则转换为NSValue对象并返回它。
6. 如果以上方法都失败，调用valueForUndefinedKey:。这在默认情况下会引发一个异常，但NSObject的子类可能会提供特定于键的行为。

### 基础Setter的搜索模式
setValue:forKey:的默认实现，给定key和value参数作为输入，尝试在接收调用的对象内部设置一个名为key的属性为value(或者，对于非对象属性，为value的未包装版本，如表示非对象值所述)，使用以下过程:
1. 按照这个顺序查找第一个名为set<Key>:或_set<Key>:的访问器。如果找到，使用输入值(或根据需要打开包装的值)调用它，然后完成。
2. 如果没有找到简单的访问器，并且类方法accessInstanceVariablesDirectly返回YES，则按照顺序查找名称为_<key>, _is<Key>, <key>, or is<Key>,的实例变量。如果找到，直接用输入值(或未包装的值)设置变量，然后完成。
3. 如果找不到访问器或实例变量，调用setValue:forUndefinedKey:。这在默认情况下会引发一个异常，但NSObject的子类可能会提供特定于键的行为。


### 可变数组的搜索模式
mutableArrayValueForKey:的默认实现，给定一个key参数作为输入，使用以下过程返回一个可变代理数组，用于接收访问器调用的对象中名为key的属性:
1. 寻找一对名称类似的方法insertObject:in<Key>AtIndex:和removeObjectFrom<Key>AtIndex:（对应于NSMutableArray原语方法insertObject:atIndex:和removeObjectAtIndex:）或者名称类似insert<Key>:atIndexes: 和remove<Key>AtIndexes:（对应NSMutableArrayinsertObjects:atIndexes:和removeObjectsAtIndexes:方法）。如果对象至少有一个插入方法和一个移除方法，返回一个代理对象，它通过发送insertObject:in<Key>AtIndex:, removeObjectFrom<Key>AtIndex:, insert<Key>:atIndexes:,和remove<Key>AtIndexes:消息的组合来响应NSMutableArray消息给mutableArrayValueForKey:的原始接收者。当接收到mutableArrayValueForKey:消息的对象还实现了一个可选的替换对象方法，其名称类似于replaceObjectIn<Key>AtIndex:withObject: 或replace<Key>AtIndexes:with<Key>:，代理对象也会在适当的时候利用这些方法来获得最佳性能。
2. 如果对象没有可变数组方法，则查找名称与模式set<Key>:匹配的访问器方法。在这种情况下，返回一个代理对象，通过向mutableArrayValueForKey:的原始接收者发出set<Key>:消息来响应NSMutableArray消息。**注意本步骤中描述的机制比上一步的效率要低得多，因为它可能需要反复创建新的集合对象，而不是修改现有的一个。因此，在设计自己的键值编码兼容对象时，应尽量避免使用它。**
3. 如果既没有找到可变数组方法，也没有找到访问器，并且如果接收方的类对accessInstanceVariablesDirectly响应YES，则搜索名称为_<key>或者<key>按这个顺序。如果找到这样一个实例变量，返回一个代理对象，它将接收到的每个NSMutableArray消息转发给实例变量的值，该值通常是NSMutableArray的一个实例或它的一个子类。
4. 如果所有这些都失败了，返回一个可变集合代理对象，当它接收到一个NSMutableArray消息时，它会向mutableArrayValueForKey:消息的原始接收者发出setValue:forUndefinedKey:消息。setValue:forUndefinedKey:的默认实现会引发一个NSUndefinedKeyException，但是子类可能会覆盖这个行为。

### 可变有序集的搜索模式
mutableOrderedSetValueForKey的默认实现:识别与valueForKey相同的简单访问方法和有序设置访问方法(参见基本Getter的默认搜索模式)，并遵循相同的直接实例变量访问策略，但总是返回一个可变集合代理对象，而不是valueForKey:返回的不可变集合。此外，它还做了以下工作:
1. 查找名称类似insertObject:in<Key>AtIndex:和removeObjectFrom<Key>AtIndex:(对应于NSMutableOrderedSet类定义的两个最基本的方法)，以及insert<Key>:atIndexes: 和remove<Key>AtIndexes: (对应于insertObjects:atIndexes:和removeObjectsAtIndexes:)的方法。如果找到至少一个插入方法和至少一个移除方法，则返回的代理对象在接收到NSMutableOrderedSet消息时，将insertObject:in<Key>AtIndex:，removeObjectFrom<Key>AtIndex:， insert<Key>:atIndexes:和remove<Key>AtIndexes:的组合发送给mutableOrderedSetValueForKey:消息的原始接收方。代理对象还使用名称为replaceObjectIn<Key>AtIndex:withObject:或replace<Key>AtIndexes:with<Key>:的方法，当它们存在于原始对象中时。
2. 如果没有找到可变集合方法，则搜索名称为set<Key>:的访问器方法。在这种情况下，返回的代理对象每次接收到NSMutableOrderedSet消息时，都会向mutableOrderedSetValueForKey:的原始接收方发送set<Key>:消息。**请注意此步骤中描述的机制比前一步的效率低得多，因为它可能涉及重复创建新的集合对象，而不是修改现有的集合对象。因此，在设计自己的键值编码兼容对象时，通常应该避免使用它**。
3. 如果既没有找到可变集合消息，也没有找到访问器，并且如果接收方的accessInstanceVariablesDirectly类方法返回YES，则搜索名称为_<key>或者<key>按这个顺序。如果找到这样的实例变量，返回的代理对象将接收到的任何NSMutableOrderedSet消息转发给实例变量的值，该值通常是NSMutableOrderedSet的实例或其子类之一。
4. 如果所有这些都失败，返回的代理对象将发送一个setValue:forUndefinedKey:消息给mutableOrderedSetValueForKey:的原始接收者。setValue:forUndefinedKey:的默认实现会引发一个NSUndefinedKeyException异常，但是对象可以覆盖这个行为。

### 可变集的搜索模式
mutableSetValueForKey:的默认实现，给定一个key参数作为输入，使用以下过程返回一个可变代理集，用于接收访问器调用的对象中名为key的数组属性:
1. 查找名称类似于add<Key>Object:和remove<Key>Object:(分别对应于NSMutableSet原语方法addObject:和removeObject:)以及add<Key>:和remove<Key>:(对应于NSMutableSet方法unionSet:和minusSet:)的方法。如果找到至少一个添加方法和至少一个删除方法，则返回一个代理对象，该对象将add<Key>Object:，remove<Key>Object:，add<Key>:和remove<Key>:消息的组合发送给mutableSetValueForKey:的原始接收者，对于它接收到的每个NSMutableSet消息。代理对象还使用名称为intersect<Key>:或set<Key>:的方法来获得最佳性能，如果它们可用的话。
2. 如果mutableSetValueForKey:调用的接收方是一个托管对象，则搜索模式不会像查找非托管对象那样继续进行。有关更多信息，请参阅核心数据编程指南中的托管对象访问器方法。
3. 如果没有找到可变集方法，并且对象不是托管对象，则搜索名称为set<Key>:的访问器方法。如果找到了这样的方法，返回的代理对象接收到的每一个NSMutableSet消息都会发送一个set<Key>:消息给mutableSetValueForKey:的原始接收者。**请注意此步骤中描述的机制比第一步的效率低得多，因为它可能涉及重复创建新的集合对象，而不是修改现有的集合对象。因此，在设计自己的键值编码兼容对象时，通常应该避免使用它。**
4. 如果没有找到可变集方法和访问器方法，并且如果accessInstanceVariablesDirectly类方法返回YES，则搜索名称为 _<key>或者 <key>按这个顺序。如果找到了这样的实例变量，代理对象将接收到的每个NSMutableSet消息转发给实例变量的值，该值通常是NSMutableSet的一个实例或它的一个子类。
5. 如果所有这些都失败，返回的代理对象通过发送setValue:forUndefinedKey:消息给mutableSetValueForKey:的原始接收者来响应它接收到的任何NSMutableSet消息。

 
## 总结what,how,why
### 是什么
KVC是由NSKeyValueCoding非正式协议启用的一种机制，对象采用该协议来提供对其属性的间接访问。当对象符合键值编码时，可以通过简洁、统一的消息传递接口通过字符串参数对其属性进行寻址。这种间接访问机制补充了实例变量及其相关访问方法提供的直接访问。

### 怎么用
1. 访问对象属性
2. 操作集合属性
3. 调用集合操作符
4. 访问非对象属性
5. 使用关键路径访问属性

### 为什么
NSObject提供的NSKeyValueCoding协议的默认实现使用一组明确定义的规则将基于键的访问器调用映射到对象的底层属性。这些协议方法使用一个关键参数来搜索它们自己的对象实例，以查找访问器、实例变量和遵循某些命名约定的相关方法。即先找方法，再匹配变量名，最后抛出异常。
1. 其实KVC就是默认实现了一组明确定义的规则将基于键即key的调用转为访问器的调用，比如`valueForKey`,则会被转为查找`get<Key>`,`key`,`isKey`方法。
2. 如果方法没有找到则看类方法的`accessInstanceVariablesDirectly`是否允许直接访问实例变量。如果允许则查找类变量中名称匹配`_<key>`,`_is<Key>`,`<key>`,`is<Key>`。如果找到就返回。
3. 否则则调用`valueForUndefinedKey`，而这个方法的默认实现会抛出一个NSUndefinedKeyException异常。

## 参考
1. https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html#//apple_ref/doc/uid/10000107-SW1
2. https://honkersk.gitbooks.io/key-value-coding-programming-guide/content/chapter1.html