import 'package:featurehub_client_api/api.dart';
import 'package:featurehub_client_sdk/featurehub.dart';
import 'package:featurehub_client_sdk/featurehub_get.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

ClientFeatureRepository featurehub;
FeatureHubSimpleApi featurehubApi;

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.object != null) {
      // ignore: avoid_print
      print('exception:${record.object}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('stackTrace:${record.stackTrace}');
    }
  });

  featurehub = ClientFeatureRepository();
  // this next step can be delayed based on environment loading, etc
  featurehubApi = FeatureHubSimpleApi(
      'http://127.0.0.1:8553',
      [
        'default/ec6a720b-71ac-4cc1-8da1-b5e396fa00ca/Kps0MAqsGt5QhgmwMEoRougAflM2b8Q9e1EFeBPHtuIF0azpcCXeeOw1DabFojYdXXr26fyycqjBt3pa'
      ],
      featurehub);
  featurehub.clientContext
      .userKey('susanna')
      .device(StrategyAttributeDeviceName.desktop)
      .platform(StrategyAttributePlatformName.macos)
      .attr('sausage', 'cumberlands')
      .build();
  featurehubApi.request();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<FeatureStateHolder>(
          stream: featurehub.feature('FLUTTER_COLOUR').featureUpdateStream,
          builder: (context, snapshot) {
            return RefreshIndicator(
              onRefresh: () => featurehubApi.request(),
              child: ListView(
                children: [
                  Container(
                    color: determineColour(snapshot.data),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'You have pushed the button this many times:',
                          ),
                          Text(
                            '$_counter',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  Color determineColour(FeatureStateHolder data) {
    // ignore: avoid_print
    print('colour changed? $data');
    if (data == null || !data.exists) {
      return Colors.white;
    }
    // ignore: avoid_print
    print('colour is ${data.stringValue}');
    switch (data.stringValue) {
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }
}
