import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:isolate_easy_pool/isolate_easy_pool.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String message = "start isolate pool";

  @override
  void initState() {
    super.initState();
    initSDK();
  }

  void initSDK() {
    //第一个参数是线程池线程数,建议根据实际情况选择合适的Isolate数量（如CPU核心数，异步类型（CPU密集型、IO））等，默认4个Isolate
    //第二个参数是否开启debug日志，默认不开启，建议debug模式开始，release模式关闭
    IsolatePool.getInstance().init(4, true);
  }

  void startExecuteIsolatePoolTask(int i) async {
    // 运行一个简单的异步任务
    String data = await IsolatePool.getInstance().runTask(() async {
      //子线程任务
      await Future.delayed(const Duration(seconds: 10)); // 模拟异步任务
      //将信息返回给主线程
      return "Task completed!";
    });
    //dart主线程
    print(
        "received====The $i task has been completed=${Isolate.current.debugName}=data=$data");
    setState(() {
      message = data;
    });
  }

  void destroyIsolatePool() async {
    IsolatePool.getInstance().dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              child: Text(message),
              onPressed: () {
                print("开始同时执行10个任务,${DateTime.now()}");
                for (int i = 0; i < 10; i++) {
                  startExecuteIsolatePoolTask(i);
                }
              },
            ),
            ElevatedButton(
              child: Text('destroy isolate pool'),
              onPressed: () {
                print("destroy isolate pool");
                destroyIsolatePool();
              },
            ),
          ],
        ),
      ),
    );
  }
}
