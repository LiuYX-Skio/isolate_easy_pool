# IsolateEasyPool

&ensp;&ensp;Dart is a single threaded language that supports asynchronous programming, but
if time-consuming operations are executed in the main thread, it will inevitably
affect system performance. Dart's main thread is suitable for handling shorter
asynchronous tasks, while for long-running tasks, executing directly in the main
thread may lead to blocking and performance bottlenecks. However, Dart itself also
supports multi-threaded programming, and Isolation, as a thread like concept,
provides the ability for multitasking parallelism. However, its use is relatively
complex, and the process of creating and destroying Isolation is cumbersome, which
may burden performance.<br/>
&ensp;&ensp;To address this issue, this plugin encapsulates an efficient thread pool based on
Isolate, which includes configurable core thread counts and task waiting queues.
After entering the pool, tasks will first attempt to retrieve and execute from
idle threads. If all core threads are busy, new tasks will be added to the waiting
queue. This design effectively reduces the performance overhead caused by frequent
creation and destruction of isolates, ensuring the efficiency and responsiveness
of the system. The use of plugins is very simple, and after integration, only a
few simple configuration steps are needed to quickly achieve task parallel processing.

## Usage
Update your pubspec.yaml file and add IsolatePool dependency
```
dependencies:
  isolate_easy_pool: ^0.0.8

```
Initialize SDK, it is recommended to initialize it at the earliest possible time
```
  IsolatePool.getInstance().init();
```
By calling the runTask method in ThreadPool, asynchronous tasks can be executed
with just one line of code
```
  void startExecuteIsolatePoolTask(int i) async {
    // 运行一个简单的异步任务
    String data = await IsolatePool.getInstance().runTask(() async {
      //子线程任务
      await Future.delayed(const Duration(seconds: 10)); // 模拟异步任务
      //将信息返回给主线程
      return "Task completed!";
    });
    //dart主线程
    print("received====The $i task has been completed=${Isolate.current.debugName}");
  }
```
Call this method to destroy when confirming that thread pool is no longer needed
```
IsolatePool.getInstance().dispose();
```
