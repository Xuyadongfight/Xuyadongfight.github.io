## 总览
**图示**
![IMAGE](resources/B4DD5AB9C89C3CB51CF01DB71D1DECC3.jpg =684x681)
**一个实际的Mach-O文件**
![IMAGE](resources/32E644F13C778C051565670BA0170B4E.jpg =900x428)
可以看到一个Mach-O文件主要分为以下3大部分:
## Header（Macho-O头部）
```
struct mach_header_64 {
	uint32_t	magic;		/* mach magic number identifier */
	cpu_type_t	cputype;	/* cpu specifier */
	cpu_subtype_t	cpusubtype;	/* machine specifier */
	uint32_t	filetype;	/* type of file */
	uint32_t	ncmds;		/* number of load commands */
	uint32_t	sizeofcmds;	/* the size of all the load commands */
	uint32_t	flags;		/* flags */
	uint32_t	reserved;	/* reserved */
};
```
* magic一个整数，包含标识此文件为64位Mach-O文件的值。如果文件用于与运行编译器的计算机具有相同字节数的CPU上，则使用常量MH_MAGIC_64。当目标计算机的字节排序方案与主机CPU相反时，可以使用常量MH_CIGAM_64
* cputype 一个整数，指示您打算在其上使用文件的体系结构。
* cpusubtype一个整数，指定CPU的确切型号。
* filetype指示文件用途和对齐方法的整数。常用的几种有效值包括以下:
1. **MH_OBJECT**文件类型是用于中间对象文件的格式。它是一种非常紧凑的格式，将所有部分包含在一个段中。编译器和汇编器通常为每个源代码文件创建一个MH_OBJECT文件。按照约定，这种格式的文件扩展名是.o。
2. **MH_EXECUTE**文件类型是标准可执行程序使用的格式。
3. **MH_BUNDLE**文件类型是运行时加载的代码通常使用的类型(通常称为包或插件)。按照约定，这种格式的文件扩展名为.bundle。
4. **MH_DYLIB**文件类型用于动态共享库。它包含一些额外的表来支持多个模块。按照惯例，这种格式的文件扩展名是.dylib，但框架的主要共享库通常没有文件扩展名。
5. **MH_PRELOAD**文件类型是一种可执行格式，用于OS X内核不加载的特殊用途程序，例如刻录到可编程ROM芯片中的程序。不要将此文件类型与MH_PREBOUND标志混淆，MH_PREBOUND标志是静态链接器在头结构中设置的标志，用于标记预绑定图像。
6. **MH_CORE**文件类型用于存储核心文件，这些文件通常是在程序崩溃时创建的。核心文件存储进程崩溃时的整个地址空间。您可以稍后在核心文件上运行gdb，以找出崩溃发生的原因。
7. **MH_DYLINKER**文件类型是动态链接器共享库的类型。这是dyld文件的类型。
8. **MH_DSYM**文件类型指定为相应二进制文件存储符号信息的文件。
* ncmds表示头结构后面的加载命令数量的整数。
* sizeofcmds一个整数，表示在头结构后面的load命令所占用的字节数。
* flags一种整数，包含一组位标志，指示Mach-O文件格式某些可选特性的状态。
* reserved保留字段以备将来使用。

## Loca commands（加载命令）
load命令结构直接位于目标文件的头之后，它们指定了文件的逻辑结构和文件在虚拟内存中的布局。每个load命令都以指定命令类型和命令数据大小的字段开始。
### load_command
所有加载命令的通用字段
```
struct load_command {
   uint32_t cmd;
   uint32_t cmdsize;
};
```
#### cmd
表示加载命令类型的整数。包含以下:
![IMAGE](resources/095EB09ADC5DBBB47C529D0BEDC62FCC.jpg =899x1590)
#### cmdsize
以字节为单位指定加载命令数据结构的总大小的整数。每个加载命令结构都包含一组不同的数据，这取决于加载命令类型，因此每个数据可能有不同的大小。在32位架构中，大小必须始终是4的倍数;在64位体系结构中，大小必须始终是8的倍数。如果load命令数据没有平均除以4或8(取决于目标体系结构是32位还是64位)，则在末尾添加包含0的字节，直到它平均除以8为止。

### uuid_command
指定映像或其对应的dSYM文件的128位通用唯一标识符(UUID)。
```
struct uuid_command {
   uint32_t cmd;
   uint32_t cmdsize;
   uint8_t uuid[16];
};
```
#### cmd
此结构设置为LC_UUID。
#### cmdsize
设置为sizeof(uuid_command)。
#### uuid
128位的唯一标识符。

### segment_command
指定组成一个段的32位Mach-O文件中的字节范围。这些字节由加载器映射到程序的地址空间。在/usr/include/mach-o/loader.h中声明参见segment_command_64。
```
struct segment_command {
   uint32_t cmd;
   uint32_t cmdsize;
   char segname[16];
   uint32_t vmaddr;
   uint32_t vmsize;
   uint32_t fileoff;
   uint32_t filesize;
   vm_prot_t maxprot;
   vm_prot_t initprot;
   uint32_t nsects;
   uint32_t flags;
};
```
#### cmd
所有加载命令结构都通用。对于这个结构，设置为LC_SEGMENT。
#### cmdsize
所有加载命令结构都通用。对于这个结构，将这个字段设置为sizeof(segment_command)加上后面所有section数据结构的大小(sizeof(segment_command + (sizeof(section) * segment->nsect)))。
#### segname
一个C字符串，指定段的名称。此字段的值可以是任何ASCII字符序列，尽管Apple定义的段名称以两个下划线开头，由大写字母组成(如__TEXT和__DATA)。这个字段的长度固定为16字节。
#### vmaddr
此段的起始虚拟内存地址。
#### vmsize
反映该段占用虚拟内存的字节数。另请参阅下面对filesize的描述。
#### fileoff
表示该文件中要映射到vmaddr的数据的偏移量。
#### filesize
反映该段在磁盘上占用的字节数。对于运行时比构建时需要更多内存的段，vmsize可以大于filesize。例如，由链接器为MH_EXECUTABLE文件生成的__PAGEZERO段的vmsize为0x1000，但文件大小为0。因为__pagezero不包含任何数据，所以在运行时之前它不需要占用任何空间。同样，静态链接器经常在__DATA段的末尾分配未初始化的数据;在本例中，vmsize大于文件大小。加载器保证这种类型的任何内存都是用零初始化的。
#### maxport
指定此段允许的最大虚拟内存保护。
#### initprot
指定此段的初始虚拟内存保护。
#### nsects
指示此load命令后的节数据结构的数量。
#### flags
定义一组影响此段加载的标志:
SG_HIGHVM此段的文件内容用于虚拟内存空间的高部分;低的部分是零填充(对于核心文件中的堆栈)。
SG_NORELOC这个段中没有任何被重新定位的东西，也没有任何被重新定位到它的东西。可以安全地更换，无需重新定位。

### segment_command_64
指定64位Mach-O文件中组成段的字节范围。这些字节由加载器映射到程序的地址空间。如果64位段有分段，则由section_64结构体定义。在/usr/include/mach-o/loader.h中声明
```
struct segment_command_64 {
   uint32_t cmd;
   uint32_t cmdsize;
   char segname[16];
   uint64_t vmaddr;
   uint64_t vmsize;
   uint64_t fileoff;
   uint64_t filesize;
   vm_prot_t maxprot;
   vm_prot_t initprot;
   uint32_t nsects;
   uint32_t flags;
};
```
#### cmd
参见segment_command中的描述。为此结构设置为LC_SEGMENT_64。
#### cmdsize
所有加载命令结构都通用。对于这个结构，将这个字段设置为sizeof(segment_command_64)加上后面所有的section数据结构的大小(sizeof(segment_command_64 + (sizeof(section_64) * segment->nsect))。
#### segname
一个C字符串，指定段的名称。此字段的值可以是任何ASCII字符序列，尽管Apple定义的段名称以两个下划线开头，由大写字母组成(如__TEXT和__DATA)。这个字段的长度固定为16字节。
#### vmaddr
此段的起始虚拟内存地址。
#### vmsize
反映该段占用虚拟内存的字节数。另请参阅下面对filesize的描述。
#### fileoff
表示该文件中要映射到vmaddr的数据的偏移量。
#### filesize
反映该段在磁盘上占用的字节数。对于运行时比构建时需要更多内存的段，vmsize可以大于filesize。例如，由链接器为MH_EXECUTABLE文件生成的__PAGEZERO段的vmsize为0x1000，但文件大小为0。因为__pagezero不包含任何数据，所以在运行时之前它不需要占用任何空间。同样，静态链接器经常在__DATA段的末尾分配未初始化的数据;在本例中，vmsize大于文件大小。加载器保证这种类型的任何内存都是用零初始化的。
#### maxprot
指定此段允许的最大虚拟内存保护。
#### initprot
指定此段的初始虚拟内存保护。
#### nsects
指示此load命令后的节数据结构的数量。
#### flags
定义一组影响此段加载的标志:
SG_HIGHVM此段的文件内容用于虚拟内存空间的高部分;低的部分是零填充(对于核心文件中的堆栈)。
SG_NORELOC这个段中没有任何被重新定位的东西，也没有任何被重新定位到它的东西。可以安全地更换，无需重新定位。

### section 
定义32位节使用的元素。直接跟在segment_command数据结构后面的是一个section数据结构数组，确切的计数由segment_command结构的nsects字段决定。在/usr/include/mach-o/loader.h中声明参见section_64。
```
struct section {
   char sectname[16];
   char segname[16];
   uint32_t addr;
   uint32_t size;
   uint32_t offset;
   uint32_t align;
   uint32_t reloff;
   uint32_t nreloc;
   uint32_t flags;
   uint32_t reserved1;
   uint32_t reserved2;
};
```
#### sectname
指定此节名称的字符串。该字段的值可以是任意ASCII字符序列，尽管Apple定义的section名称以两个下划线开头，由小写字母组成(如__text和__data)。这个字段的长度固定为16字节。
#### segname
一个字符串，指定最终应包含此节的段的名称。为了紧凑起见，中间对象文件(mh_object类型的文件)只包含一个段，所有部分都放在这个段中。在构建最终产品(非MH_OBJECT类型的任何文件)时，静态链接器将每个节放在命名段中。
 
#### addr
指定此节的虚拟内存地址的整数。
#### size
一个整数，以字节为单位指定此节占用的虚拟内存的大小。
#### offset
指定文件中此部分偏移量的整数。
#### align
指定节的字节对齐方式的整数。将其指定为2的幂;例如，一个8字节对齐的section的对齐值为3(2的3次方等于8)。
#### reloff
指定此节的第一个重定位表项的文件偏移量的整数。
#### nreloc
一个整数，指定位于此节的重定位表项的数目。
#### flags
分成两部分的整数。最不重要的8位包含节类型，而最重要的24位包含一组指定节的其他属性的标志。这些类型和标志主要由静态链接器和文件分析工具(如otool)使用，以确定如何修改或显示节。这些是可能的类型:
![IMAGE](resources/1C31B570D6759C4A696EF7024C2D758E.jpg =924x1363)

#### reserved1
保留用于某些节类型的整数。对于引用间接符号表项的符号指针节和符号存根节，这是该节的表项在间接表中的索引。条目的数量是基于节的大小除以符号指针或存根的大小。否则，该字段设置为0。
#### reserved2
对于S_SYMBOL_STUBS类型的节，指定节中包含的符号存根条目大小的整数(以字节为单位)。否则，该字段将保留以供将来使用，并应设置为0。
#### 讨论
Mach-O文件中的每个部分都有一个类型和一组属性标志。在中间对象文件中，类型和属性决定静态链接器如何将节复制到最终产品中。对象文件分析工具(如otool)使用类型和属性来确定如何读取和显示节。动态链接器使用一些节类型和属性。
这些是符号类型和属性的重要静态链接变量:

**常规的section**。在一个常规的section中，在中间的object文件中只能存在一个外部符号的定义。如果静态链接器发现任何重复的外部符号定义，则返回一个错误。
**合并的section**。在最终的产品中，静态链接器只保留在合并部分中定义的每个符号的一个实例。为了支持复杂的语言特性(如c++虚表和RTTI)，编译器可以在每个中间对象文件中创建一个特定符号的定义。然后静态链接器和动态链接器将重复的定义减少为程序使用的单个定义。
**弱符号定义只能出现在合并的section中**。当静态链接器发现一个符号的重复定义时，它会丢弃任何具有弱定义属性集(参见nlist)的合并符号定义。如果没有非弱定义，则使用第一个弱定义。该特性旨在支持c++模板;它允许显式模板实例化覆盖隐式模板实例化。c++编译器将显式定义放在常规节中，将隐式定义放在合并节中，标记为弱定义。使用弱定义构建的中间对象文件(以及静态归档库)只能与OS X v10.2及更高版本中的静态链接器一起使用。如果最终产品(应用程序和共享库)预计将在OS X的早期版本上使用，则不应包含弱定义。

### section_64
定义64位节使用的元素。直接跟在segment_command_64数据结构后面的是一个section_64数据结构数组，确切的计数由segment_command_64结构的nsects字段决定。在/usr/include/mach-o/loader.h中声明
```
struct section_64 {
   char sectname[16];
   char segname[16];
   uint64_t addr;
   uint64_t size;
   uint32_t offset;
   uint32_t align;
   uint32_t reloff;
   uint32_t nreloc;
   uint32_t flags;
   uint32_t reserved1;
   uint32_t reserved2;
   uint32_t reserved3;
};
```
#### sectname
指定此节名称的字符串。该字段的值可以是任意ASCII字符序列，尽管Apple定义的section名称以两个下划线开头，由小写字母组成(如__text和__data)。这个字段的长度固定为16字节。
#### segname
一个字符串，指定最终应包含此节的段的名称。为了紧凑起见，中间对象文件(mh_object类型的文件)只包含一个段，所有部分都放在这个段中。在构建最终产品(非MH_OBJECT类型的任何文件)时，静态链接器将每个节放在命名段中。
#### addr
指定此节的虚拟内存地址的整数。
#### size
一个整数，以字节为单位指定此节占用的虚拟内存的大小。
#### offset
指定文件中此部分偏移量的整数。
#### align
指定节的字节对齐方式的整数。将其指定为2的幂;例如，一个8字节对齐的section的对齐值为3(2的3次方等于8)。
#### reloff
指定此节的第一个重定位表项的文件偏移量的整数。
#### nreloc
一个整数，指定位于此节的重定位表项的数目。
#### flags
分成两部分的整数。最不重要的8位包含节类型，而最重要的24位包含一组指定节的其他属性的标志。这些类型和标志主要由静态链接器和文件分析工具(如otool)使用，以确定如何修改或显示节。这些是可能的类型:
![IMAGE](resources/B8A7D0CEF001CFEE91DFF14EADF42D7B.jpg =896x1290)

#### reserved1
保留用于某些节类型的整数。对于引用间接符号表项的符号指针节和符号存根节，这是该节的表项在间接表中的索引。条目的数量是基于节的大小除以符号指针或存根的大小。否则，该字段设置为0。
#### reserved2
对于S_SYMBOL_STUBS类型的节，指定节中包含的符号存根条目大小的整数(以字节为单位)。否则，该字段将保留以供将来使用，并应设置为0。
#### reserved3
保留以备将来使用。苹果官方文档中没有。
#### 讨论
Mach-O文件中的每个部分都有一个类型和一组属性标志。在中间对象文件中，类型和属性决定静态链接器如何将节复制到最终产品中。对象文件分析工具(如otool)使用类型和属性来确定如何读取和显示节。动态链接器使用一些节类型和属性。
这些是符号类型和属性的重要静态链接变量:
**常规部分**。在一个常规的section中，在中间的object文件中只能存在一个外部符号的定义。如果静态链接器发现任何重复的外部符号定义，则返回一个错误。
**结合部分**。在最终的产品中，静态链接器只保留在合并部分中定义的每个符号的一个实例。为了支持复杂的语言特性(如c++虚表和RTTI)，编译器可以在每个中间对象文件中创建一个特定符号的定义。然后静态链接器和动态链接器将重复的定义减少为程序使用的单个定义。
**弱符号定义只能出现在合并的节**中。当静态链接器发现一个符号的重复定义时，它会丢弃任何具有弱定义属性集(参见nlist)的合并符号定义。如果没有非弱定义，则使用第一个弱定义。该特性旨在支持c++模板;它允许显式模板实例化覆盖隐式模板实例化。c++编译器将显式定义放在常规节中，将隐式定义放在合并节中，标记为弱定义。使用弱定义构建的中间对象文件(以及静态归档库)只能与OS X v10.2及更高版本中的静态链接器一起使用。如果最终产品(应用程序和共享库)预计将在OS X的早期版本上使用，则不应包含弱定义。

### lc_str
定义一个变长字符串。在/usr/include/mach-o/loader.h中声明
```
union lc_str {
   uint32_t offset;
#ifndef __LP64__
   char* ptr;
#endif
};
```
#### offset
一个长整数。从包含此字符串的load命令开始到字符串数据开始的字节偏移量。
#### ptr
指向字节数组的指针。在运行时，该指针包含字符串数据的虚拟内存地址。在Mach-O文件中不使用ptr字段。
#### 讨论
Load命令使用lc_str数据结构存储变长数据，例如库名。除非另有说明，否则数据由C字符串组成。
所指向的数据被存储在load命令之后，大小被添加到load命令的大小中。字符串应该以空结尾;用于四舍五入大小的任何额外字节都应该为空。还可以通过从load命令数据结构的cmdsize字段中减去load命令数据结构的大小来确定字符串的大小。
 
### dylib
定义动态链接器用于将共享库与已链接到该库的文件匹配的数据。专用于dylib_command数据结构。在/usr/include/mach-o/loader.h中声明
```
struct dylib {
   union lc_str name;
   uint32_t timestamp;
   uint32_t current_version;
   uint32_t compatibility_version;
};
```
#### name
lc_str类型的数据结构。指定共享库的名称。
#### timestamp
构建共享库的日期和时间。
#### current_version
共享库的当前版本。
#### compatibility_version
共享库的兼容性版本。

### dylib_command
定义LC_LOAD_DYLIB和LC_ID_DYLIB加载命令的属性。在/usr/include/mach-o/loader.h中声明
```
 struct dylib_command {
   uint32_t cmd;
   uint32_t cmdsize;
   struct dylib dylib;
};
 ```
#### cmd
所有加载命令结构都通用。对于这个结构，设置为LC_LOAD_DYLIB、LC_LOAD_WEAK_DYLIB或LC_ID_DYLIB。
#### cmdsize
所有加载命令结构都通用。对于这个结构，设置为sizeof(dylib_command)加上dylib字段的name字段所指向的数据的大小。
#### dylib
dylib类型的数据结构。指定共享库的属性。
#### 讨论
对于文件链接到的每个共享库，静态链接器创建一个LC_LOAD_DYLIB命令，并将其dylib字段设置为目标库LC_ID_DYLD加载命令的dylib字段的值。所有LC_LOAD_DYLIB命令一起组成一个列表，该列表根据文件中的位置排序，最早的LC_LOAD_DYLIB命令排在第一位。对于两级命名空间文件，符号表中的未定义符号项通过索引引用它们的父共享库。索引称为库序号，它存储在nlist数据结构的n_desc字段中。
在运行时，动态连接器使用LC_LOAD_DYLIB命令的dyld字段中的名称来定位共享库。如果找到库，动态连接器将LC_LOAD_DYLIB加载命令的版本信息与库的版本进行比较。要使动态链接器成功链接共享库，共享库的兼容性版本必须小于或等于LC_LOAD_DYLIB命令中的兼容性版本。
动态连接器使用时间戳来确定是否可以使用预绑定信息。当前版本由NSVersionOfRunTimeLibrary函数返回，以允许您确定程序正在使用的库的版本。
 
### dylinker_command
定义LC_LOAD_DYLINKER和LC_ID_DYLINKER加载命令的属性。在/usr/include/mach-o/loader.h中声明
```
struct dylinker_command {
   uint32_t cmd;
   uint32_t cmdsize;
   union lc_str name;
};
```
#### cmd
所有加载命令结构都通用。对于这个结构，设置为LC_ID_DYLINKER或LC_LOAD_DYLINKER。
#### cmdsize
所有加载命令结构都通用。对于这个结构，设置为sizeof(dylinker_command)，加上name字段所指向的数据的大小。
#### name
lc_str类型的数据结构。指定动态链接器的名称。
#### 讨论
每个被动态链接的可执行文件都包含LC_LOAD_DYLINKER命令，该命令指定内核为了执行该文件必须加载的动态链接器的名称。动态连接器本身使用LC_ID_DYLINKER加载命令指定其名称。

### Symbol Table和Related Data Structures(符号表和相关数据结构)
两个加载命令LC_SYMTAB和LC_DYSYMTAB描述符号表的大小和位置，以及其他元数据。本节中列出的其他数据结构表示符号表本身。

### symtab_command
定义LC_SYMTAB加载命令的属性。描述符号表数据结构的大小和位置。在/usr/include/mach-o/loader.h中声明
```
struct symtab_command {
   uint32_t cmd;
   uint32_t cmdsize;
   uint32_t symoff;
   uint32_t nsyms;
   uint32_t stroff;
   uint32_t strsize;
};
```
#### cmd
所有加载命令结构都通用。对于这个结构，设置为LC_SYMTAB。
#### cmdsize
所有加载命令结构都通用。对于这个结构，设置为sizeof(symtab_command)。
#### symoff
一个整数，包含从文件开始到符号表项位置的字节偏移量。符号表是一个nlist数据结构的数组。
#### nsyms
表示符号表中条目数的整数。
#### stroff
一个整数，包含从图像开始到字符串表位置的字节偏移量。
#### strsize
表示字符串表大小(以字节为单位)的整数。
#### 讨论
LC_SYMTAB应该同时存在于静态链接和动态链接的文件类型中。

### nlist
描述用于32位体系结构的符号表中的项。在/usr/include/mach-o/nlist.h中声明参见nlist_64。
```
struct nlist {
   union {
     #ifndef __LP64__
        char * n_name;
     #endif
     int32_t n_strx;
   } n_un;
   uint8_t n_type;
   uint8_t n_sect;
   int16_t n_desc;
  uint32_t n_value;
};
```
#### n_un
一个保存字符串表n_strx索引的联合。若要指定空字符串("")，请将此值设置为0。在Mach-O文件中不使用n_name字段。
#### n_type
由四个位掩码访问的数据组成的字节值:
![IMAGE](resources/1AF2AFE8658133D14CCC989C8D1249D4.jpg =871x590)
#### n_sect
一个整数，指定该符号可以在该图像的任何部分中找到，或者NO_SECT(如果该符号没有在此图像的任何部分中找到)。根据区段在LC_SEGMENT加载命令中出现的顺序，区段从1开始连续编号。
#### n_desc
一个16位的值，为非插入符号提供关于此符号性质的附加信息。引用标志可以使用REFERENCE_TYPEmask (0xF)访问，定义如下:
 ![IMAGE](resources/611DB50316A6B14C10D47A1CAD012834.jpg =906x975)
如果这个文件是一个两级命名空间映像(也就是说，如果设置了mach_header结构的MH_TWOLEVEL标志)，n_desc的高8位指定定义这个未定义符号的库的编号。使用宏GET_LIBRARY_ORDINAL来获取这个值，使用宏SET_LIBRARY_ORDINAL来设置它。0指定当前图像。1到253根据文件中LC_LOAD_DYLIB命令的顺序指定库号。值254用于动态查找未定义的符号(仅在OS X v10.3及更高版本中支持)。对于从链接它们的可执行程序加载符号的插件，255指定可执行映像。对于平面名称空间映像，高8位必须为0。
#### n_value
包含符号值的整数。这个值的格式对于每种类型的符号表项是不同的(由n_type字段指定)。对于N_SECT符号类型，n_value是该符号的地址。有关其他可能值的信息，请参阅n_type字段的描述。
#### 讨论
通用符号必须为N_UNDF类型，并且必须设置n_next位。普通符号的n_value是该符号数据的大小(以字节为单位)。在C语言中，公共符号是在此文件中声明但未初始化的变量。普通符号只能出现在MH_OBJECT Mach-O文件中。

### nlist_64
描述用于64位体系结构的符号表中的项。在/usr/include/mach-o/nlist.h中声明
```
struct nlist_64 {
   union {
     uint32_t n_strx; 
   } n_un;
   uint8_t n_type;
   uint8_t n_sect;
   uint16_t n_desc;
   uint64_t n_value;
};
```
#### n_un
一个保存字符串表n_strx索引的联合。若要指定空字符串("")，请将此值设置为0。
#### n_type
由四个位掩码访问的数据组成的字节值:
 ![IMAGE](resources/2CFB388BE05C6E2F9141EE1A09F4DB1C.jpg =846x584)
#### n_sect
一个整数，指定该符号可以在该图像的任何部分中找到，或者NO_SECT(如果该符号没有在此图像的任何部分中找到)。根据区段在LC_SEGMENT加载命令中出现的顺序，区段从1开始连续编号。
#### n_desc
一个16位的值，提供关于此符号性质的附加信息。引用标志可以使用REFERENCE_TYPE掩码(0xF)访问，定义如下:
![IMAGE](resources/D99663DC036EFD8F7A4F2C9D45826397.jpg =888x904)
如果这个文件是一个两级命名空间映像(也就是说，如果设置了mach_header结构的MH_TWOLEVEL标志)，n_desc的高8位指定了定义该符号的库的编号。使用宏GET_LIBRARY_ORDINAL来获取这个值，使用宏SET_LIBRARY_ORDINAL来设置它。0指定当前图像。1到254根据文件中LC_LOAD_DYLIB命令的顺序指定库号。对于从链接它们的可执行程序加载符号的插件，255指定可执行映像。对于平面名称空间映像，高8位必须为0。
#### n_value
包含符号值的整数。这个值的格式对于每种类型的符号表项是不同的(由n_type字段指定)。对于N_SECT符号类型，n_value是该符号的地址。有关其他可能值的信息，请参阅n_type字段的描述。
#### 讨论
同nlist

### dysymtab_command
LC_DYSYMTAB加载命令的数据结构。它描述了用于动态链接的符号表各部分的大小和位置。在/usr/include/mach-o/loader.h中声明
```
struct dysymtab_command {
   uint32_t cmd;
   uint32_t cmdsize;
   uint32_t ilocalsym;
   uint32_t nlocalsym;
   uint32_t iextdefsym;
   uint32_t nextdefsym;
   uint32_t iundefsym;
   uint32_t nundefsym;
   uint32_t tocoff;
   uint32_t ntoc;
   uint32_t modtaboff;
   uint32_t nmodtab;
   uint32_t extrefsymoff;
   uint32_t nextrefsyms;
   uint32_t indirectsymoff;
   uint32_t nindirectsyms;
   uint32_t extreloff;
   uint32_t nextrel;
   uint32_t locreloff;
   uint32_t nlocrel;
};
```
#### cmd
所有加载命令结构都通用。对于这个结构，设置为LC_DYSYMTAB。
#### cmdsize
所有加载命令结构都通用。对于这个结构，设置为sizeof(dysymtab_command)。
#### ilocalsym
一个整数，表示局部符号组中第一个符号的索引。
#### nlocalsym
表示局部符号组中符号总数的整数。
#### iextdefsym
一个整数，表示所定义的外部符号组中第一个符号的索引。
#### nextdefsym
一个整数，表示所定义的外部符号组中的符号总数。
#### iundefsym
一个整数，表示未定义的外部符号组中第一个符号的索引。
#### nundefsym
一个整数，表示未定义的外部符号组中的符号总数。
#### tocoff
一个整数，表示从文件开始到目录数据的字节偏移量。
#### ntoc
表示目录中条目数量的整数。
#### modtaboff
一个整数，指示从文件开始到模块表数据的字节偏移量。
#### nmodtab
指示模块表中条目数量的整数。
#### extrefsymoff
一个整数，指示从文件开始到外部引用表数据的字节偏移量。
#### nextrefsyms
表示外部引用表中条目数的整数。
#### indirectsymoff
一个整数，指示从文件开始到间接符号表数据的字节偏移量。
#### nindirectsyms
表示间接符号表中条目数的整数。
#### extreloff
一个整数，指示从文件开始到外部重定位表数据的字节偏移量。
#### nextrel
一个整数，表示外部重定位表中的表项数。
#### locreloff
一个整数，指示从文件开始到本地重定位表数据的字节偏移量。
#### nlocrel
一个整数，表示本地重定位表中的表项数。
#### 讨论
LC_DYSYMTAB load命令包含符号表的一组索引和一组文件偏移量，这些文件偏移量定义了其他几个表的位置。文件中未使用的表的字段应设置为0。这些表在Mach-O编程主题中的“位置无关代码”中有描述。

### Relocation Data Structures（重定位数据结构）
重定位是将符号移动到不同地址的过程。当静态链接器将符号(函数或数据项)移动到不同的地址时，它需要更改对该符号的所有引用以使用新地址。Mach-O文件中的重定位表项包含文件中到文件内容重定位时需要重定位的地址的偏移量。存储在CPU指令中的地址可以是绝对地址也可以是相对地址。每个重定位表项都指定地址的确切格式。在创建中间对象文件时，编译器为每条包含地址的指令生成一个或多个重定位项。因为在运行时不会重定位到固定地址的符号，也不会重定位到与位置无关的引用的相对地址，所以静态连接器在构建最终产品时通常会删除部分或全部重定位表项。
注意:在OS X x86-64环境中不使用分散重定位。编译器生成的代码主要使用外部重定位，其中r_extern位被设置为1,r_symbolnum字段包含目标标签的符号表索引。

### relocation_info
描述文件中使用当地址更改时需要更新的地址的项。在/usr/include/mach-o/reloc.h中声明
 ```
 struct relocation_info {
   int32_t r_address;
   uint32_t r_symbolnum : 24, r_pcrel : 1, r_length : 2, r_extern : 1, r_type : 4;
};
 
 ```
#### r_address
在MH_OBJECT文件中，这是从section开始到包含需要重定位地址的项的偏移量。如果设置了这个字段的高位(可以使用R_SCATTERED位掩码检查)，relocation_info结构实际上是一个scattered_relocation_info结构。

在动态连接器使用的映像中，这是文件中出现的第一个segment_command数据的虚拟内存地址的偏移量(不一定是具有最低地址的那个)。对于设置了MH_SPLIT_SEGS标志的图像，这是与第一个读/写segment_命令的数据的虚拟内存地址的偏移量。

#### r_symbolnum
表示符号表的索引(当r_extern字段设置为1时)或节号(当r_extern字段设置为0时)。正如前面提到的，节按照它们在LC_SEGMENT加载命令中出现的顺序从1到255排序。绝对符号的重定位表项设置为R_ABS，绝对符号不需要重定位。

#### r_pcrel
指示包含要重新定位的地址的项是否是使用pc相对寻址的CPU指令的一部分。
对于pc相关指令中包含的地址，CPU将指令的地址添加到指令中包含的地址。
 
#### r_length
指示包含要重新定位的地址的项的长度。下表列出了r_length值和对应的地址长度。
 ![IMAGE](resources/BABFCA475B69E126E923CAC83CF16C4E.jpg =810x212)
 
#### r_extern
指示r_symbolnum字段是符号表(1)的索引还是节号(0)。

#### r_type
![IMAGE](resources/94C1C1C7A1727A4E8DE37F4F5453C88E.jpg =876x1691)

### Universal Binaries and 32-bit/64-bit PowerPC Binaries(通用二进制文件和32 /64位PowerPC二进制文件)
标准开发工具接受两种二进制文件作为参数:
**针对一个体系结构的目标文件**。这些库包括Mach-O文件、静态库和动态库。
**针对多个体系结构的二进制文件**。这些二进制文件包含以下系统类型之一的编译代码和数据:
基于powerpc(32位和64位)的Macintosh计算机。包含32位和64位基于powerpc的Macintosh计算机代码的二进制文件称为PPC/PPC64二进制文件。
基于intel和powerpc(32位、64位或两者都有)的Macintosh计算机。包含基于intel和基于powerpc的Macintosh计算机代码的二进制文件称为通用二进制文件。
每个对象文件存储为一个连续的字节集，从二进制文件的开头偏移。它们使用一种简单的归档格式来存储两个目标文件，在文件的开头有一个特殊的头，以允许各种运行时工具快速找到适合当前体系结构的代码。
包含多个体系结构代码的二进制文件总是以fat_header数据结构开始，然后是两个fat_arch数据结构和文件中包含的体系结构的实际数据。这些数据结构中的所有数据都以大端字节顺序存储。
 
### fat_header
定义包含用于多个体系结构的代码的二进制文件的布局。在头文件/usr/include/mach-o/fat.h中声明
 ```
 struct fat_header {
  uint32_t magic;
  uint32_t nfat_arch;
};
 
 ```
#### magic
以大端字节序格式包含值0xCAFEBABE的整数。在大端主机CPU上，可以使用常量FAT_MAGIC来验证这一点;在小端序的主机CPU上，可以使用常量FAT_CIGAM进行验证。

#### nfat_arch
体系结构的数量
#### 讨论
fat_header数据结构被放置在包含多个体系结构代码的二进制文件的开头。直接跟在fat_header数据结构后面的是一组fat_arch数据结构，每个结构对应二进制文件中包含的每个体系结构。不管这个数据结构描述什么内容，它的所有字段都以大端字节顺序存储。
 
### fat_arch
描述针对单个体系结构的目标文件在二进制文件中的位置。在/usr/include/mach-o/fat.h中声明
```
struct fat_arch
{
   cpu_type_t cputype;
   cpu_subtype_t cpusubtype;
   uint32_t offset;
   uint32_t size;
   uint32_t align;
};
```
#### cputype
cpu_type_t类型的枚举值。CPU族。
#### cpusubtype
cpu_subtype_t类型的枚举值。指定可以在其上使用此条目的CPU族的特定成员或指定所有成员的常量。
#### offset
此CPU数据开始的偏移量。
#### size
此CPU的数据大小。
#### align
对于在二进制文件中cputype中指定的体系结构的目标文件的偏移量，2的幂对齐。这是必需的，以确保在更改此二进制文件时，它保留的内容为虚拟内存分页和其他用途正确对齐。
#### 讨论
一个fat_arch数据结构数组直接出现在包含多个体系结构的目标文件的二进制文件的fat_header数据结构之后。不管这个数据结构描述什么内容，它的所有字段都以大端字节顺序存储。

## Data数据
数据部分其实就是前面的加载命令所要加载的内容。

### 引用
https://github.com/aidansteele/osx-abi-macho-file-format-reference