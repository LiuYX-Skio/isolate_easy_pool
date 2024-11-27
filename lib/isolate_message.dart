import 'dart:isolate';

class IsolateMessage {
  SendPort sendPort;
  ReceivePort? receivePort; //用于接收创建子isolate返回sendPort的receivePort
  ReceivePort? msgBackPort; //将消息回传给isolate创建者（如当前在dart主isolate创建的子isolate，当前返回的是dart主isolate）
  Isolate isolate;
  bool? isDestroy;

  IsolateMessage(
      {required this.sendPort,
      required this.receivePort,
      required this.isolate});
}
