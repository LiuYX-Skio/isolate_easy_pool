import 'dart:async';
import 'dart:isolate';

import 'package:isolate_easy_pool/isolate_easy_pool.dart';

import 'isolate_message.dart';

class IsolateTask {

  void sendTask(Future Function() task, IsolateMessage isolate,
      void Function(dynamic) callback) {
    final port = ReceivePort();
    isolate.receivePort = port;
    // 向Isolate发送任务
    isolate.sendPort.send(<dynamic>[task, port.sendPort]);
    isolate.msgBackPort = port;
    // 监听任务完成的通知
    port.listen((message) {
      callback(message);
    });
  }

  /// 创建Isolate
  Future<IsolateMessage> spawnIsolate() async {
    final receivePort = ReceivePort();
    Isolate isolate = await Isolate.spawn(_worker, receivePort.sendPort);
    // 获取工作线程的 SendPort
    final sendPort = await receivePort.first;
    return IsolateMessage(
        sendPort: sendPort, receivePort: receivePort, isolate: isolate);
  }

  /// 创建工作线程 (Isolate)
  Future<void> _worker(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    //isolate循环接收消息
    await for (var message in receivePort) {
      if (message == null) {
        break;
      }
      final task = message[0] as Future Function();
      final replyPort = message[1] as SendPort;
      // 执行任务
      final result = await task();
      //完成后回调给当前调用isloate
      replyPort.send(result);
      if (result is String && result == IsolatePool.ISOLATE_DISPOSE) {
        break;
      }
    }
    receivePort.close();
  }

}
