import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:isolate_pool/isolate_pool.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final isolatePool = ThreadPool.getInstance();

  @override
  void initState() {
    super.initState();
    initSDK();
  }

  void initSDK(){
    ThreadPool.getInstance().init();
  }

  void startExecuteIsolatePoolTask() async {
    await isolatePool.init();
    // 运行一个简单的异步任务
    for(int i = 0;i<10;i++){
      isolatePool.runTask(() async {
        await Future.delayed(const Duration(seconds: 10)); // 模拟异步任务
        print("test = runTask==== ${i}");
        // return "Task completed!";
      });
    }
  }

  void destroyIsolatePool() async {
    isolatePool.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(children: [
          ElevatedButton(
            child: Text('start isolate pool'),
            onPressed: () {
              startExecuteIsolatePoolTask();
            },
          ),
          ElevatedButton(
            child: Text('destroy isolate pool'),
            onPressed: () {
              destroyIsolatePool();
            },
          ),
        ],),
      ),
    );
  }
}
