import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:isolate_easy_pool/isolate_task.dart';
import 'package:synchronized/synchronized.dart';

import 'isolate_message.dart';
import 'isolate_queue.dart';

class IsolatePool {
  int _coreThreadSum = 4;
  final List<IsolateMessage> _isolates = [];
  final Queue<IsolateQueue> _waitQueue = Queue<IsolateQueue>(); // 等待任务队列
  final IsolateTask _iTask = IsolateTask();
  final _lock = Lock();
  static const String TAG = "IsolatePool";
  static const String ISOLATE_DISPOSE = "isolate_dispose";
  bool _isInit = false;
  bool _isOpenLog = false;
  bool _isDestroy = false;

  IsolatePool._();

  static IsolatePool? _instance;

  static IsolatePool getInstance() {
    _instance ??= IsolatePool._();
    return _instance!;
  }

  ///isolate pool初始化,coreThreadSum 运行isolate数量,isOpenLog 是否打开日志
  Future<void> init([int coreThreadSum = 4, bool isOpenLog = false]) async {
    // 启动线程池中的工作线程
    if (!_isInit) {
      _isOpenLog = isOpenLog;
      _coreThreadSum = coreThreadSum;
      _isolates.clear();
      for (int i = 0; i < _coreThreadSum; i++) {
        final sendPort = await _iTask.spawnIsolate();
        _isolates.add(sendPort);
      }
      _isInit = true;
    }
  }

  /// 寻找空闲线程执行任务，没有空闲线程将任务放入等待队列
  Future<T> runTask<T>(Future<T> Function() task) async {
    if (!_isInit) {
      await init();
    }
    if (_isDestroy) {
      _printf("The current isolate pool has been destroyed");
      final completer = Completer<T>();
      return completer.future;
    } else {
      // 获取空闲线程的 SendPort
      if (_isolates.isNotEmpty) {
        _printf("run tasking");
        // 创建任务完成的 Completer
        final completer = Completer<T>();
        return _runTask(task, completer);
      } else {
        //当前不存在空闲线程，加入等待队列
        final completer = Completer<T>();
        _waitQueue.addLast(IsolateQueue(func: task, completer: completer));
        _printf("join wait queue,wait queue count ${_waitQueue.length}");
        return completer.future;
      }
    }
  }

  ///日志打印
  void _printf(String msg) {
    if (_isOpenLog) {
      print("$TAG $msg");
    }
  }

  /// 空闲线程执行任务
  Future<T> _runTask<T>(
      Future<T> Function() task, Completer<T> completer) async {
    // 获取空闲线程的 SendPort
    final isolate = _isolates.isNotEmpty
        ? _isolates.removeAt(0)
        : await _iTask.spawnIsolate();
    _iTask.sendTask(task, isolate, (message) {
      completer.complete(message);
      _isolates.add(isolate); // 任务完成后，释放SendPort给线程池
      _checkExecuteNextTask();
    });
    return completer.future;
  }

  /// 检查队列并执行下一个任务
  _checkExecuteNextTask() async {
    //该函数存在并发情况，加锁进行同步，防止任务执行异常
    await _lock.synchronized(() async {
      _printf("check execute next task");
      if (_waitQueue.isNotEmpty && _isolates.isNotEmpty) {
        final nextTask = _waitQueue.removeFirst(); // 取出下一个任务
        if (_waitQueue.isNotEmpty) {
          _checkExecuteNextTask();
        }
        final task = nextTask.func; // 获取任务
        final completer = nextTask.completer;
        _printf(
            "execute wait queue,isoloate free count ${_isolates.length},wait queue count ${_waitQueue.length}");
        _runTask(task, completer);
      }
    });
  }

  /// 销毁线程池，正在执行的任务不一定会立即被销毁，当前任务执行完成后才会被销毁
  Future<void> dispose() async {
    // 停止所有的线程
    _printf("dispose all isolate");
    for (var isolate in _isolates) {
      final completer = Completer<String?>();
      _iTask.sendTask(
          () async {
            return ISOLATE_DISPOSE;
          },
          isolate,
          (message) {
            completer.complete(message);
            _destroy();
          });
    }
  }

  ///销毁isolate pool
  void _destroy() {
    if (!_isDestroy) {
      print("destroy=${_isolates.length}");
      _isDestroy = true;
      Future.delayed(Duration(seconds: 2), () {
        for (var isolate in _isolates) {
          isolate.receivePort?.close();
          isolate.msgBackPort?.close();
          isolate.isolate.kill(priority: Isolate.immediate);
        }
        _isolates.clear();
      });
    }
  }
}
