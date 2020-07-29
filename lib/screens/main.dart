import 'package:flutter/material.dart';
import 'Accueil.dart';
import 'Help.dart';
import 'package:flutter/rendering.dart';
import './../size_config.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../ble_utils/building_ble_services.dart';

///Page de démarrage

void main() {
  //debugPaintSizeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demonstrateur Astek',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state); //Page quand le bluetooth est désactivé
          }),
    );
  }
}

//Page quand le bluetooth est activé

class FindDevicesScreen extends StatefulWidget {
  FindDevicesScreen({Key key}) : super(key:key);

  @override
  FindDevicesScreenState createState() {
    return FindDevicesScreenState();
  }
}


class FindDevicesScreenState extends State<FindDevicesScreen>{

  FindDevicesScreenState();
  BluetoothCharacteristic characteristic;

  List<BluetoothService> _services;


  @override
  void initState(){
    bool isHere = false;
    ScanResult r;
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 2));
    /*var subscription = FlutterBlue.instance.scanResults.listen((results) {
      for(r in results){
        if(r.device.name ==('Nordic_UART')){
          isHere=true;

        }
      }
      if(isHere == true){
        /// r.device.connect(); Pas fou parce qu'il essaie de se connecer à tous
        ///Les devices dispos !
        print("Connected to nordic from init");
      }
    });*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conect to Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                    title: Text((() { // A placer quand la liste est crée apparemment, parce que ça s'éxécute quand je cliques sur Nordic.

                      ///Le fait de mettre un navigator empeche de revenir sur la page
                      ///de connexion, ça sera peut etre intérréssant !
                      return d.name;
                    } ())),


                    subtitle: Text(d.id.toString()),
                    trailing: StreamBuilder<BluetoothDeviceState>(
                      stream: d.state,
                      initialData: BluetoothDeviceState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.data ==
                            BluetoothDeviceState.connected) {
                          return RaisedButton(
                            child: Text('DISCONNECT'),
                            onPressed: () {
                              d.disconnect();
                              FlutterBlue.instance.startScan(timeout: Duration(seconds: 2));
                            },

                          );
                        }


                        return Text(snapshot.data.toString());
                      },
                    ),
                  ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                      result: r,
                      onTap: () async {
                        await r.device.connect(autoConnect: true);
                        _services = await r.device.discoverServices();

                        Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {


                          return Accueil(device : r.device, characteristic: characteristic,services: _services,);

                      }));

  }
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}







class BluetoothOffScreen extends StatefulWidget {
  final BluetoothState state;
  const BluetoothOffScreen(this.state, {Key key}) : super(key: key);


  @override
  BluetoothOffScreenState createState(){
    return BluetoothOffScreenState(this.state);
  }

}

class BluetoothOffScreenState extends State<BluetoothOffScreen>{

  final BluetoothState state;

  BluetoothOffScreenState(this.state);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

///Deprecated

///Redirection vers la page d'appairage automatique





  //Cette fonction permet d'afficher une SnackBar, elle peut etre utile dans une future version
  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }



