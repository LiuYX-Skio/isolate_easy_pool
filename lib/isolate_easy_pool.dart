import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:isolate_easy_pool/isolate_task.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate_queue.dart';

class IsolatePool {
  int _coreThreadSum = 4;
  final List<SendPort> _sendCorePorts = [];
  final Queue<IsolateQueue> _waitQueue = Queue<IsolateQueue>(); // 等待任务队列
  final IsolateTask iTask = IsolateTask();
  final lock = Lock();
  static const String TAG = "ThreadPool";
  bool isInit = false;

  IsolatePool._();

  static IsolatePool? _instance;

  static IsolatePool getInstance() {
    _instance ??= IsolatePool._();
    return _instance!;
  }

  Future<void> init([int coreThreadSum = 4]) async {
    // 启动线程池中的工作线程
    _coreThreadSum = coreThreadSum;
    _sendCorePorts.clear();
    for (int i = 0; i < _coreThreadSum; i++) {
      final sendPort = await iTask.spawnIsolate();
      _sendCorePorts.add(sendPort);
    }
    isInit = true;
  }

  /// 销毁线程池
  Future<void> dispose() async {
    // 停止所有的线程
    for (var sendPort in _sendCorePorts) {
      sendPort.send(null); // 向工作线程发送一个结束信号
    }
    _sendCorePorts.clear();
  }

  /// 寻找空闲线程执行任务，没有空闲线程将任务放入等待队列
  Future<T> runTask<T>(Future<T> Function() task) async {
    if (!isInit) {
      await init();
    }
    // 获取空闲线程的 SendPort
    if (_sendCorePorts.isNotEmpty) {
      printf("run tasking");
      // 创建任务完成的 Completer
      final completer = Completer<T>();
      return _runTask(task, completer);
    } else {
      //当前不存在空闲线程，加入等待队列
      final completer = Completer<T>();
      _waitQueue.addLast(IsolateQueue(func: task, completer: completer));
      printf("join wait queue,wait queue count ${_waitQueue.length}");
      return completer.future;
    }
  }

  void printf(String msg) {
    if (kDebugMode) {
      print("$TAG $msg");
    }
  }

  /// 空闲线程执行任务
  Future<T> _runTask<T>(
      Future<T> Function() task, Completer<T> completer) async {
    // 获取空闲线程的 SendPort
    final sendPort = _sendCorePorts.isNotEmpty
        ? _sendCorePorts.removeAt(0)
        : await iTask.spawnIsolate();
    iTask.sendTask(task, sendPort, (message) {
      completer.complete(message);
      _sendCorePorts.add(sendPort); // 任务完成后，释放SendPort给线程池
      _checkExecuteNextTask();
    });
    return completer.future;
  }

  /// 检查队列并执行下一个任务
  _checkExecuteNextTask() async {
    //该函数存在并发情况，加锁进行同步，防止任务执行异常
    await lock.synchronized(() async {
      printf(
          "check execute next task,isoloate free count ${_sendCorePorts.length}");
      if (_waitQueue.isNotEmpty && _sendCorePorts.isNotEmpty) {
        final nextTask = _waitQueue.removeFirst(); // 取出下一个任务
        if (_waitQueue.isNotEmpty) {
          _checkExecuteNextTask();
        }
        final task = nextTask.func; // 获取任务
        final completer = nextTask.completer;
        printf(
            "execute wait queue,isoloate free count ${_sendCorePorts.length},wait queue count ${_waitQueue.length}");
        _runTask(task, completer);
      }
    });
  }
}
