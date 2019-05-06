import 'package:flutter/material.dart';

import 'example.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP-Touch Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExamplePage(),
    );
  }
}
