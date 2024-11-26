import 'dart:async';

class IsolateQueue{
  Future Function() func;
  Completer completer;
  IsolateQueue({required this.func, required this.completer});
}
