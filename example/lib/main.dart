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


  @override
  void initState() {
    super.initState();
    initSDK();
  }

  void initSDK(){
    IsolatePool.getInstance().init();
  }

  void startExecuteIsolatePoolTask() async {
    // 运行一个简单的异步任务
    for(int i = 0; i<10; i++){
      IsolatePool.getInstance().runTask(() async {
        await Future.delayed(const Duration(seconds: 10)); // 模拟异步任务
        print("test = runTask==== ${i}");
        // return "Task completed!";
      });
    }
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
