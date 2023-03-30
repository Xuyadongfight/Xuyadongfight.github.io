## 调度源
无论何时与底层系统交互，都必须准备好该任务将占用大量时间。向下调用内核或其他系统层涉及上下文的更改，与在您自己的进程中发生的调用相比，这种更改的代价相当大。因此，许多系统库提供异步接口，以允许您的代码向系统提交请求，并在处理该请求时继续执行其他工作。Grand Central Dispatch基于这种通用行为，允许您提交请求，并使用块和调度队列将结果报告给程序。

## 关于调度源
调度源是一种基本数据类型，用于协调特定低级系统事件的处理。Grand Central Dispatch支持以下类型的调度源:

* 计时器调度源生成周期性通知。
* 信号分派源在UNIX信号到达时通知您。
* 描述符源会通知你各种基于文件和套接字的操作，例如:
当数据可供读取时
当有可能写入数据时
当删除、移动或重命名文件系统中的文件时
当文件元信息发生变化时
* 流程调度源通知您与流程相关的事件，例如:
当进程退出时
当进程发出fork或exec类型的调用时
当信号传递给进程时
* Mach端口调度源通知您与Mach相关的事件。
* 自定义分派源是您自己定义和触发的源。

调度源替换通常用于处理系统相关事件的异步回调函数。在配置调度源时，您可以指定要监视的事件以及用于处理这些事件的调度队列和代码。可以使用块对象或函数指定代码。当感兴趣的事件到达时，调度源将您的块或函数提交到指定的调度队列执行。

与手动提交到队列的任务不同，分派源为应用程序提供连续的事件源。分派源一直附加到它的分派队列，直到显式地取消它。在附加时，只要发生相应的事件，它就将其关联的任务代码提交给分派队列。有些事件(如计时器事件)定期发生，但大多数事件仅在特定条件出现时零星发生。出于这个原因，分派源保留其关联的分派队列，以防止在事件可能仍然挂起时过早释放分派队列。

为了防止事件积压在调度队列中，调度源实现了事件合并方案。如果新事件在前一个事件的事件处理程序被退出队列并执行之前到达，分派源将合并来自新事件数据的数据和来自旧事件的数据。根据事件的类型，合并可以替换旧事件或更新它所包含的信息。例如，基于信号的分派源只提供关于最近的信号的信息，但也报告自上次调用事件处理程序以来总共传递了多少个信号。
 
## 创建调度源
创建分派源涉及创建事件源和分派源本身。事件的源是处理事件所需的任何本地数据结构。例如，对于基于描述符的调度源，您需要打开描述符，而对于基于进程的源，您需要获取目标程序的进程ID。有了事件源之后，就可以创建相应的调度源，如下所示:

1. 使用dispatch_source_create函数创建调度源。
2. 配置调度源:
  * 将事件处理程序分配给分派源;请参见编写和安装事件处理程序。
  * 对于计时器源，使用dispatch_source_set_timer函数设置计时器信息;请参见创建定时器。
3. 可选地将取消处理程序分配给调度源;请参阅安装取消处理程序。
4. 调用dispatch_resume函数开始处理事件;请参见暂停和恢复调度源。

因为调度源在使用之前需要进行一些额外的配置，dispatch_source_create函数返回处于挂起状态的调度源。在挂起时，分派源接收事件但不处理它们。这使您有时间安装事件处理程序并执行处理实际事件所需的任何额外配置。

下面几节向您展示如何配置调度源的各个方面。有关如何配置特定类型的调度源的详细示例，请参见调度源示例。有关用于创建和配置调度源的函数的其他信息，请参阅中央调度(GCD)参考。
 
### 编写和安装事件处理程序
要处理调度源生成的事件，必须定义一个事件处理程序来处理这些事件。事件处理程序是使用dispatch_source_set_event_handler或dispatch_source_set_event_handler_f函数安装在调度源上的函数或块对象。当事件到达时，调度源将事件处理程序提交到指定的调度队列进行处理。

事件处理程序的主体负责处理任何到达的事件。如果您的事件处理程序已经排队，等待在新事件到达时处理事件，则分派源将合并这两个事件。事件处理程序通常只看到最近事件的信息，但根据分派源的类型，它也可能能够获得关于发生和合并的其他事件的信息。如果一个或多个新事件在事件处理程序开始执行之后到达，分派源将保留这些事件，直到当前事件处理程序完成执行。此时，它将事件处理程序与新事件一起再次提交到队列。

基于函数的事件处理程序接受一个包含分派源对象的上下文指针，并且不返回任何值。基于块的事件处理程序不接受参数，也没有返回值。
 ```
 // Block-based event handler
void (^dispatch_block_t)(void)
 
// Function-based event handler
void (*dispatch_function_t)(void *)
 ```

在事件处理程序内部，您可以从分派源本身获得关于给定事件的信息。尽管基于函数的事件处理程序将一个指向分派源的指针作为参数传递，但基于块的事件处理程序本身必须捕获该指针。您可以通过引用包含分派源的变量来为您的块执行此操作。例如，下面的代码片段捕获源变量，该变量在块的作用域之外声明。
 ```
 dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                 myDescriptor, 0, myQueue);
dispatch_source_set_event_handler(source, ^{
   // Get some data from the source variable, which is captured
   // from the parent context.
   size_t estimated = dispatch_source_get_data(source);
 
   // Continue reading the descriptor...
});
dispatch_resume(source);
 ```
在块中捕获变量通常是为了获得更大的灵活性和动态性。当然，在默认情况下，捕获的变量在块中是只读的。尽管blocks特性提供了在特定情况下修改捕获变量的支持，但您不应该尝试在与调度源关联的事件处理程序中这样做。分派源总是异步执行其事件处理程序，因此您捕获的任何变量的定义范围可能在事件处理程序执行时消失。有关如何在块中捕获和使用变量的更多信息，请参阅块编程主题。

表4-1列出了可以从事件处理程序代码中调用以获取事件信息的函数。
 ![IMAGE](resources/A19CD37FC19B2DD92CD9ABF7BB236AE0.jpg =1179x550)
 
### 安装取消处理程序
取消处理程序用于在调度源被释放之前对其进行清理。对于大多数类型的调度源，取消处理程序是可选的，只有当您有一些绑定到调度源的自定义行为也需要更新时才需要取消处理程序。然而，对于使用描述符或Mach端口的调度源，您必须提供一个取消处理程序来关闭描述符或释放Mach端口。如果不这样做，可能会导致代码中出现细微的错误，因为这些结构被您的代码或系统的其他部分无意地重用了。

您可以在任何时候安装取消处理程序，但通常在创建分派源时才会这样做。您可以使用dispatch_source_set_cancel_handler或dispatch_source_set_cancel_handler_f函数安装取消处理程序，这取决于您想在实现中使用块对象还是函数。下面的示例展示了一个简单的取消处理程序，它关闭为调度源打开的描述符。fd变量是一个包含描述符的捕获变量。
 ```
 dispatch_source_set_cancel_handler(mySource, ^{
   close(fd); // Close a file descriptor opened earlier.
});
 ```
 
### 更改目标队列
尽管您在创建调度源时指定了要在其上运行事件和取消处理程序的队列，但您可以在任何时候使用dispatch_set_target_queue函数更改该队列。您可以这样做来更改处理调度源事件的优先级。

更改调度源的队列是一个异步操作，并且调度源会尽最大努力尽可能快地进行更改。如果事件处理程序已经排队等待处理，则在前一个队列上执行。但是，在您进行更改前后到达的其他事件可以在任何队列上处理。
 
### 将自定义数据与调度源关联
与Grand Central Dispatch中的许多其他数据类型一样，可以使用dispatch_set_context函数将自定义数据与调度源关联起来。您可以使用上下文指针存储事件处理程序处理事件所需的任何数据。如果您确实在上下文指针中存储了任何自定义数据，那么还应该安装一个取消处理程序(如安装取消处理程序中所述)，以便在不再需要调度源时释放该数据。

如果使用块实现事件处理程序，还可以捕获局部变量并在基于块的代码中使用它们。尽管这可能会减少在分派源的上下文指针中存储数据的需求，但您应该始终审慎地使用此特性。因为分派源在应用程序中可能是长期存在的，所以在捕获包含指针的变量时应该非常小心。如果指针所指向的数据在任何时候都可能被释放，您应该复制数据或保留数据以防止这种情况发生。在这两种情况下，您都需要提供一个取消处理程序，以便稍后发布数据。
 
### 调度源内存管理
与其他分派对象一样，分派源是引用计数的数据类型。调度源的初始引用计数为1，可以使用dispatch_retain和dispatch_release函数保留和释放。当队列的引用计数为零时，系统自动释放调度源数据结构。

由于它们的使用方式不同，调度源的所有权可以在内部管理，也可以在调度源本身的外部管理。对于外部所有权，另一个对象或代码段获得调度源的所有权，并在不再需要它时负责释放它。对于内部所有权，调度源拥有自己，并负责在适当的时间释放自己。尽管外部所有权非常常见，但在希望创建自治调度源并让它管理代码的某些行为而无需任何进一步交互的情况下，也可以使用内部所有权。例如，如果调度源被设计为响应单个全局事件，则可以让它处理该事件，然后立即退出。
 
## 调度源举例
下面几节向您展示如何创建和配置一些更常用的调度源。有关配置特定类型的调度源的更多信息，请参阅Grand Central dispatch (GCD)参考。

### 创建定时器
计时器分派源以定期的、基于时间的间隔生成事件。您可以使用计时器来启动需要定期执行的特定任务。例如，游戏和其他图形密集型应用程序可能使用计时器来启动屏幕或动画更新。您还可以设置一个计时器，并使用产生的事件来检查频繁更新的服务器上的新信息。

所有计时器分派源都是间隔计时器——也就是说，一旦创建，它们将按照您指定的间隔交付常规事件。在创建计时器分派源时，必须指定的值之一是一个让系统了解计时器事件所需精度的余地值。Leeway值使系统在如何管理电源和唤醒核心方面具有一定的灵活性。例如，系统可能会使用浮动值来提前或延迟火灾时间，并将其与其他系统事件更好地对齐。因此，您应该尽可能为自己的计时器指定一个浮动值。
 
注意:即使您指定了一个0的浮动值，也不要期望计时器在您所要求的纳秒内触发。该系统尽最大努力满足您的需求，但不能保证准确的发射时间。
 
当计算机进入睡眠状态时，所有计时器分派源都被挂起。当计算机被唤醒时，那些计时器分派源也会被自动唤醒。根据计时器的配置，这种性质的暂停可能会影响下一次触发计时器的时间。如果使用dispatch_time函数或DISPATCH_TIME_NOW常量设置计时器调度源，则计时器调度源将使用默认的系统时钟来确定何时触发。但是，当计算机处于睡眠状态时，默认时钟不会前进。相反，当您使用dispatch_walltime函数设置计时器调度源时，计时器调度源将跟踪其触发时间到挂钟时间。后一种选项通常适用于触发间隔相对较大的计时器，因为它可以防止事件时间之间有太多的漂移。

清单4-1显示了一个timer的例子，它每30秒触发一次，并且有一个1秒的空闲值。因为计时器间隔比较大，所以调度源是使用dispatch_walltime函数创建的。计时器的第一次触发立即发生，后续事件每30秒到达一次。MyPeriodicTask和MyStoreTimer符号表示自定义函数，您可以编写这些函数来实现计时器行为，并将计时器存储在应用程序数据结构中的某个位置。
 
```
dispatch_source_t CreateDispatchTimer(uint64_t interval,
              uint64_t leeway,
              dispatch_queue_t queue,
              dispatch_block_t block)
{
   dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
   if (timer)
   {
      dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
      dispatch_source_set_event_handler(timer, block);
      dispatch_resume(timer);
   }
   return timer;
}
 
void MyCreateTimer()
{
   dispatch_source_t aTimer = CreateDispatchTimer(30ull * NSEC_PER_SEC,
                               1ull * NSEC_PER_SEC,
                               dispatch_get_main_queue(),
                               ^{ MyPeriodicTask(); });
 
   // Store it somewhere for later use.
    if (aTimer)
    {
        MyStoreTimer(aTimer);
    }
}

```
尽管创建计时器分派源是接收基于时间的事件的主要方式，但也有其他可用的选项。如果希望在指定的时间间隔后执行一次块，可以使用dispatch_after或dispatch_after_f函数。这个函数的行为很像dispatch_async函数，除了它允许您指定将块提交到队列的时间值。时间值可以根据需要指定为相对时间值或绝对时间值。
 
### 从描述符读取数据
要从文件或套接字读取数据，必须打开文件或套接字并创建DISPATCH_SOURCE_TYPE_READ类型的调度源。您指定的事件处理程序应该能够读取和处理文件描述符的内容。对于文件，这相当于读取文件数据(或该数据的子集)并为应用程序创建适当的数据结构。对于网络套接字，这涉及到处理新接收到的网络数据。

无论何时读取数据，都应该将描述符配置为使用非阻塞操作。虽然可以使用dispatch_source_get_data函数来查看有多少数据可以读取，但该函数返回的数字可能在调用时间和实际读取数据时间之间发生变化。如果底层文件被截断或发生网络错误，则从阻塞当前线程的描述符读取可能会使事件处理程序在执行过程中暂停，并阻止调度队列调度其他任务。对于串行队列，这可能会导致队列死锁，甚至对于并发队列，这也会减少可以启动的新任务的数量。

清单4-2显示了配置调度源从文件读取数据的示例。在本例中，事件处理程序将指定文件的全部内容读入缓冲区，并调用自定义函数(您将在自己的代码中定义该函数)来处理数据。(一旦读取操作完成，此函数的调用者将使用返回的调度源取消它。)为了确保调度队列在没有数据读取时不会发生不必要的阻塞，本示例使用fcntl函数配置文件描述符以执行非阻塞操作。安装在调度源上的取消处理程序确保在读取数据后关闭文件描述符。
 ```
 dispatch_source_t ProcessContentsOfFile(const char* filename)
{
   // Prepare the file for reading.
   int fd = open(filename, O_RDONLY);
   if (fd == -1)
      return NULL;
   fcntl(fd, F_SETFL, O_NONBLOCK);  // Avoid blocking the read operation
 
   dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_source_t readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                   fd, 0, queue);
   if (!readSource)
   {
      close(fd);
      return NULL;
   }
 
   // Install the event handler
   dispatch_source_set_event_handler(readSource, ^{
      size_t estimated = dispatch_source_get_data(readSource) + 1;
      // Read the data into a text buffer.
      char* buffer = (char*)malloc(estimated);
      if (buffer)
      {
         ssize_t actual = read(fd, buffer, (estimated));
         Boolean done = MyProcessFileData(buffer, actual);  // Process the data.
 
         // Release the buffer when done.
         free(buffer);
 
         // If there is no more data, cancel the source.
         if (done)
            dispatch_source_cancel(readSource);
      }
    });
 
   // Install the cancellation handler
   dispatch_source_set_cancel_handler(readSource, ^{close(fd);});
 
   // Start reading the file.
   dispatch_resume(readSource);
   return readSource;
}
 ```
在前面的示例中，自定义MyProcessFileData函数确定何时已经读取了足够多的文件数据，并且可以取消调度源。默认情况下，配置为从描述符读取的调度源在仍有数据要读取时重复调度其事件处理程序。如果套接字连接关闭或到达文件末尾，调度源将自动停止调度事件处理程序。如果您知道您不需要调度源，您可以直接自己取消它。
 
### 将数据写入描述符
将数据写入文件或套接字的过程与读取数据的过程非常相似。在为写操作配置描述符之后，您可以创建DISPATCH_SOURCE_TYPE_WRITE类型的调度源。一旦创建了分派源，系统就会调用事件处理程序，让它有机会开始向文件或套接字写入数据。写完数据后，使用dispatch_source_cancel函数取消调度源。

无论何时写入数据，都应该将文件描述符配置为使用非阻塞操作。虽然可以使用dispatch_source_get_data函数来查看有多少空间可用来写入，但该函数返回的值仅为建议值，并且在调用和实际写入数据之间可能会发生变化。如果发生错误，将数据写入阻塞文件描述符可能会使事件处理程序在执行过程中暂停，并阻止调度队列调度其他任务。对于串行队列，这可能会导致队列死锁，甚至对于并发队列，这也会减少可以启动的新任务的数量。

清单4-3显示了使用调度源将数据写入文件的基本方法。在创建新文件之后，该函数将结果文件描述符传递给它的事件处理程序。放入文件中的数据是由MyGetData函数提供的，您可以用生成文件数据所需的任何代码替换该函数。将数据写入文件后，事件处理程序将取消分派源，以防止再次调用它。然后，调度源的所有者将负责释放它。
 ```
 dispatch_source_t WriteDataToFile(const char* filename)
{
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC,
                      (S_IRUSR | S_IWUSR | S_ISUID | S_ISGID));
    if (fd == -1)
        return NULL;
    fcntl(fd, F_SETFL); // Block during the write.
 
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE,
                            fd, 0, queue);
    if (!writeSource)
    {
        close(fd);
        return NULL;
    }
 
    dispatch_source_set_event_handler(writeSource, ^{
        size_t bufferSize = MyGetDataSize();
        void* buffer = malloc(bufferSize);
 
        size_t actual = MyGetData(buffer, bufferSize);
        write(fd, buffer, actual);
 
        free(buffer);
 
        // Cancel and release the dispatch source when done.
        dispatch_source_cancel(writeSource);
    });
 
    dispatch_source_set_cancel_handler(writeSource, ^{close(fd);});
    dispatch_resume(writeSource);
    return (writeSource);
}

 ```
 
### 监视文件系统对象
如果希望监视文件系统对象的更改，可以设置DISPATCH_SOURCE_TYPE_VNODE类型的调度源。当文件被删除、写入或重命名时，可以使用这种类型的分派源来接收通知。您还可以使用它来在文件的特定类型的元信息(如大小和链接计数)发生变化时发出警报。

注意:在分派源本身处理事件时，为分派源指定的文件描述符必须保持打开状态。

清单4-4显示了一个监视文件名称更改的示例，并在更改时执行一些自定义行为。(您将提供实际的行为来代替示例中调用的MyUpdateFileName函数。)因为一个描述符是专门为调度源打开的，所以调度源包括一个关闭描述符的取消处理程序。由于该示例创建的文件描述符与底层文件系统对象相关联，因此可以使用相同的调度源检测任意数量的文件名更改。
 ```
 dispatch_source_t MonitorNameChangesToFile(const char* filename)
{
   int fd = open(filename, O_EVTONLY);
   if (fd == -1)
      return NULL;
 
   dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                fd, DISPATCH_VNODE_RENAME, queue);
   if (source)
   {
      // Copy the filename for later use.
      int length = strlen(filename);
      char* newString = (char*)malloc(length + 1);
      newString = strcpy(newString, filename);
      dispatch_set_context(source, newString);
 
      // Install the event handler to process the name change
      dispatch_source_set_event_handler(source, ^{
            const char*  oldFilename = (char*)dispatch_get_context(source);
            MyUpdateFileName(oldFilename, fd);
      });
 
      // Install a cancellation handler to free the descriptor
      // and the stored string.
      dispatch_source_set_cancel_handler(source, ^{
          char* fileStr = (char*)dispatch_get_context(source);
          free(fileStr);
          close(fd);
      });
 
      // Start processing events.
      dispatch_resume(source);
   }
   else
      close(fd);
 
   return source;
}

 ```
 
### 监控信号
UNIX信号允许从应用程序的域之外操作应用程序。应用程序可以接收许多不同类型的信号，从不可恢复的错误(例如非法指令)到关于重要信息的通知(例如当子进程退出时)。传统上，应用程序使用sigaction函数来安装信号处理程序函数，该函数在信号到达后立即对其进行同步处理。如果您只是希望收到信号到达的通知，而不是实际处理该信号，则可以使用信号调度源来异步处理信号。

信号分派源不能替代使用sigaction函数安装的同步信号处理程序。同步信号处理程序实际上可以捕获信号并防止它终止应用程序。信号调度源允许您仅监视信号的到达。此外，您不能使用信号分派源来检索所有类型的信号。具体来说，不能使用它们监视SIGILL、SIGBUS和SIGSEGV信号。

因为信号调度源是在调度队列上异步执行的，所以它们不会受到同步信号处理程序的某些限制。例如，对于可以从信号分派源的事件处理程序调用的函数没有限制。这种增加的灵活性的代价是，在信号到达和调用调度源的事件处理程序之间可能会有一些增加的延迟。

清单4-5显示了如何配置信号调度源来处理SIGHUP信号。分派源的事件处理程序调用MyProcessSIGHUP函数，您可以在应用程序中用处理信号的代码替换该函数。
 ```
 void InstallSignalHandler()
{
   // Make sure the signal does not terminate the application.
   signal(SIGHUP, SIG_IGN);
 
   dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGHUP, 0, queue);
 
   if (source)
   {
      dispatch_source_set_event_handler(source, ^{
         MyProcessSIGHUP();
      });
 
      // Start processing signals
      dispatch_resume(source);
   }
}
 ```
如果您正在为自定义框架开发代码，那么使用信号分派源的一个优点是，您的代码可以独立于链接到它的任何应用程序来监视信号。信号分派源不会干扰其他分派源或应用程序可能已安装的任何同步信号处理程序。

有关实现同步信号处理程序的更多信息以及信号名称列表，请参见信号手册页。
 
### 监控进程
流程调度源允许您监视特定流程的行为并做出适当的响应。父进程可以使用这种类型的分派源来监视它所创建的任何子进程。例如，父进程可以使用它来监视子进程的死亡。类似地，子进程可以使用它监视父进程并在父进程退出时退出。

清单4-6显示了安装分派源以监视父进程的终止的步骤。当父进程死亡时，分派源设置一些内部状态信息，让子进程知道它应该退出。(您自己的应用程序将需要实现MySetAppExitFlag函数来为终止设置适当的标志。)因为调度源是自主运行的，因此它拥有自己，所以它也会在程序关闭之前取消和释放自己。
 ```
 void MonitorParentProcess()
{
   pid_t parentPID = getppid();
 
   dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC,
                                                      parentPID, DISPATCH_PROC_EXIT, queue);
   if (source)
   {
      dispatch_source_set_event_handler(source, ^{
         MySetAppExitFlag();
         dispatch_source_cancel(source);
         dispatch_release(source);
      });
      dispatch_resume(source);
   }
}

 ```
 
## 取消调度源
调度源将保持活动状态，直到使用dispatch_source_cancel函数显式地取消它们。取消调度源将停止新事件的交付，且无法撤消。因此，您通常取消调度源，然后立即释放它，如下所示:
 ```
 void RemoveDispatchSource(dispatch_source_t mySource)
{
   dispatch_source_cancel(mySource);
   dispatch_release(mySource);
}
 ```
 取消调度源是一种异步操作。尽管在调用dispatch_source_cancel函数之后没有处理新的事件，但是已经由调度源处理的事件将继续被处理。在完成任何最终事件的处理后，如果存在取消处理程序，分派源将执行它的取消处理程序。

取消处理程序是您释放内存或清理代表分派源获取的任何资源的机会。如果调度源使用描述符或mach端口，则必须提供一个取消处理程序，以便在发生取消时关闭描述符或销毁端口。其他类型的调度源不需要取消处理程序，不过如果您将任何内存或数据与调度源关联，则仍然应该提供一个取消处理程序。例如，如果在调度源的上下文指针中存储数据，则应该提供一个。有关取消处理程序的详细信息，请参见安装取消处理程序。
 
## 暂停和恢复调度源
可以使用dispatch_suspend和dispatch_resume方法暂时暂停和恢复调度源事件的传递。这些方法增加和减少调度对象的挂起计数。因此，在事件传递恢复之前，必须平衡对dispatch_suspend的每个调用和对dispatch_resume的匹配调用。

挂起调度源时，在挂起调度源期间发生的任何事件都会累积，直到队列恢复为止。当队列恢复时，不是交付所有事件，而是在交付之前将事件合并为单个事件。例如，如果您正在监视一个文件的名称更改，则传递的事件将只包括姓氏更改。以这种方式合并事件可以防止它们在队列中堆积，并在工作恢复时使应用程序不堪重负。
 