import 'package:flutter/material.dart';

import 'package:esptouch/esptouch.dart';
import 'package:connectivity/connectivity.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP-Touch Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with EsptouchMixin {
  /// May be entered from TextField
  String wifiPasswrod = 'Secret Password';

  List _results = [];

  void tryConnectEsp() async {
    /// Identify whether Esptouch is already executing
    if (esptouchExecuting) return;

    /// Create and fill [WifiInfo]
    /// For example with [Connectivity] package
    WifiInfo wifiInfo = WifiInfo(
      ip: await Connectivity().getWifiIP(),
      ssid: await Connectivity().getWifiName(),
      bssid: await Connectivity().getWifiBSSID(),
      password: wifiPasswrod,
    );

    print(wifiInfo);

    startEsptouch(wifiInfo);

    setState(() {});
  }

  @override
  void onEsptouchError(dynamic error) {
    if (mounted) setState(() => _results.add(error));
  }

  @override
  void onEsptouchResult(EsptouchResult result) {
    if (mounted) setState(() => _results.add(result));
  }

  @override
  void onEsptouchFinished(List<EsptouchResult> result) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildControlButton(),
            RaisedButton(
              child: Text('Clear'),
              onPressed: () => setState(_results.clear),
            ),
            _buildProgressIndicator(),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton() {
    if (esptouchExecuting) {
      return RaisedButton(
        child: Text('Stop'),
        onPressed: stopEsptouch,
      );
    } else {
      return RaisedButton(
        child: Text('Connect'),
        onPressed: tryConnectEsp,
      );
    }
  }

  Widget _buildResults() => Column(children: _results.map<Widget>(_buildResult).toList());

  Widget _buildResult(result) => Text('${result.runtimeType} $result');

  Widget _buildProgressIndicator() {
    if (esptouchExecuting) {
      return CircularProgressIndicator();
    }

    return Container();
  }
}
