import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:toit_api/generated/toit/api/pubsub/publish.pbgrpc.dart'
    show PublishClient, PublishRequest;
import 'package:toit_api/generated/toit/api/device.pbgrpc.dart';
import 'package:toit_api/generated/toit/model/device.pb.dart';

Future<void> main() async {
  runApp(MyApp());
}

class ToitServer {
  static ClientChannel _channel = ClientChannel("api.toit.io");
  static String _authorizationToken =
      "30fb04d06dc4c97c9efb3c10704b16b5b816673acfdaec51336d4904c8186419";
  static CallOptions _options =
      CallOptions(metadata: {'Authorization': 'Bearer ${_authorizationToken}'});

  static Future<DeviceStatus> getConnectedStatus() async {
    var deviceStub = DeviceServiceClient(_channel, options: _options);
    /*
    var deviceList = (await deviceStub.listDevices(ListDevicesRequest())).devices;
    for (var device in deviceList) {
      print(device);
    }
    */
    var lookupResponse = await deviceStub.lookupDevices(
        LookupDevicesRequest(deviceName: "airwick-spray"));
    var deviceIds = lookupResponse.deviceIds;
    if (deviceIds.length != 1) {
      throw "expected only one match";
    }

    var device = (await deviceStub
            .getDevice(GetDeviceRequest(deviceId: deviceIds.first)))
        .device;
    return device.status;
  }

  static Future<void> spray() async {
    var publishStub = PublishClient(_channel, options: _options);
    await publishStub.publish(PublishRequest(
        topic: "cloud:airwick",
        publisherName: "from flutter",
        data: [utf8.encode("trigger")]));
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Let it Spray',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Spray Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = "Title"}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<DeviceStatus> _connectedFuture;
  bool sprayed = false;

  @override
  void initState() {
    super.initState();
    _connectedFuture = ToitServer.getConnectedStatus();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<DeviceStatus>(
                future: _connectedFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var status = snapshot.data!;
                    var isAlive =
                        !status.health.connectivity.checkins.last.hasMissed();
                    if (!isAlive) return Text("Dead");
                    var lastCheckin = status.health.connectivity.lastSeen;
                    return Text(
                        "Alive: ${DateTime.fromMillisecondsSinceEpoch(lastCheckin.seconds.toInt() * 1000)}");
                  } else if (snapshot.hasError) {
                    return Text("$snapshot.error}");
                  }
                  return CircularProgressIndicator();
                }),
            OutlinedButton(
              child: Text("Spray"),
              onPressed: sprayed
                  ? null
                  : () {
                      ToitServer.spray();
                      setState(() {
                        sprayed = true;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}
