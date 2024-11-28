import 'dart:async';

///任务队列封装类
class IsolateQueue {
  Future Function() func;
  Completer completer;

  IsolateQueue({required this.func, required this.completer});
}
