import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bluetooth_identifiers/bluetooth_identifiers.dart';
import 'package:teacher_bluetooth/ulits.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    final UUIDAllocation? uuidServiceId = BluetoothIdentifiers.uuidServiceIdentifiers[64753];

    print(uuidServiceId ?? '');
  }

  StreamSubscription? scanSubscription;
  BehaviorSubject<Map<String, ScanResult>> listOfDevice = BehaviorSubject.seeded({});

  Future<void> startScan() async {

    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.bluetoothConnect.request();
    // On iOS, a "This app would like to use Bluetooth" system dialogue appears on first call to any FlutterBluePlus method.
    // TODO(JohnyTwoJacket): проверить
    await FlutterBluePlus.turnOn();



    final devices = await FlutterBluePlus.systemDevices;
    print(devices);

    scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          print('${r.advertisementData.serviceUuids}: "${r.device.advName}" found!');

          final map = listOfDevice.value;
          map.putIfAbsent(
            r.device.remoteId.str,
            () => r,
          );
          listOfDevice.value = map;
        }
      },
      onError: (e) => print(e),
    );
    FlutterBluePlus.startScan(
      timeout: const Duration(minutes: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: () {
              startScan();
            },
            child: const Text("Start scan"),
          ),
          StreamBuilder(
            stream: listOfDevice,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return Container();
              }
              final listOfDevice = data.values.toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final device = listOfDevice[index].device;
                  return ListTile(
                    title: Text(device.platformName),
                    subtitle: Text( device.remoteId.str ),
                  );
                },
                itemCount: listOfDevice.length,
              );
            },
          ),
        ],
      ),
    );
  }
}
