import 'dart:async';
import 'dart:isolate';

class IsolateTask {
  void sendTask(Future Function() task, SendPort sendPort,
      void Function(dynamic) callback) {
    final port = ReceivePort();
    // 向Isolate发送任务
    sendPort.send(<dynamic>[task, port.sendPort]);
    // 监听任务完成的通知
    port.listen((message) {
      callback(message);
    });
  }

  /// 创建Isolate
  Future<SendPort> spawnIsolate() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_worker, receivePort.sendPort);
    // 获取工作线程的 SendPort
    final sendPort = await receivePort.first;
    return sendPort;
  }

  /// 创建工作线程 (Isolate)
  static Future<void> _worker(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    await for (var message in receivePort) {
      if (message == null) {
        // 如果接收到 null，表示结束工作线程
        break;
      }
      final task = message[0] as Future Function();
      final replyPort = message[1] as SendPort;
      // 执行任务
      final result = await task();
      //完成后回调给当前调用isloate
      replyPort.send(result);
    }
    receivePort.close();
  }
}
