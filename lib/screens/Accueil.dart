import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'main.dart';
import './../size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import './../db_utils/database_helper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sqflite/sqflite.dart';

import 'Help.dart';
import 'Settings.dart';

///TODO :
///Faire la recherche dans la BDD pour tester si la fonction marche
///A RECHECK du coup parce que ça fonctionne pas ;)
///
///Check pour utiliser avec écran éteint.
///Le Streambuilder s'éxécute toujours plusieurs fois,
///Il donne parfois des paramètres random au T2S, mais
///Avant de parler il récupère les bons, le programme est donc fonctionnel
///Mais peut encore etre amélioré !
///
/// Page d'Accueil de l'application
/// Il faudra empecher le retour sur la page d'accueil quand on se déconnecte du Nordic.

enum TtsState { playing, stopped, paused, continued }

class Accueil extends StatefulWidget {
  double volume ;
  double pitch;
  double rate;
  String language;

  BluetoothDevice device;
  final BluetoothCharacteristic characteristic;
  final List<BluetoothService> services;


  Accueil({this.volume, this.pitch, this.rate, this.language, this.device, this.characteristic, this.services});
//On met des "named arguments" ici pour pouvoir les utiliser dans l'ordre qu'on veut


  @override
  _Accueil_State createState() {
    return _Accueil_State(this.volume, this.pitch, this.rate, this.language, this.device,this.characteristic, this.services);
  }
}

class _Accueil_State extends State<Accueil> {

  //Déclaration des variables
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  List<BluetoothService> services;

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume;
  double pitch ;
  double rate ;
  String mystate;

  int _buildWidget = 0;
  bool _isnotifset = false;


  String _val;

  DatabaseHelper databaseHelper = DatabaseHelper();

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();



  //Constructeur & getters

  _Accueil_State(this.volume , this.pitch, this.rate, this.language, this.device,this.characteristic,this.services);



  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  get isPaused => ttsState == TtsState.paused;

  get isContinued => ttsState == TtsState.continued;




  @override
  initState() {
    super.initState();
    _get_shared();


    initTts();
    print("value volume init : $volume , $rate, $pitch");
  }






  //Permet de récupérer la liste des langages disponibles
  initTts() {
    flutterTts = FlutterTts();

    _getLanguages();
  }
  Future<String> _getdeviceState() async{
    String _state = await device.state.toString();
    return _state;
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);

  }


  Future <Null> _get_shared() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final key4 = 'volume';
    final key5 = 'pitch';
    final key6 =  'rate';
    final key7 = 'language';


    final value4 = prefs.getDouble(key4) ?? 0.5;
    final value5 = prefs.getDouble(key5) ?? 1;
    final value6 = prefs.getDouble(key6) ?? 0.5;
    final value7 = prefs.getString(key7) ??'fr-FR';


    setState(() {
      volume = value4;
      pitch = value5;
      rate = value6;
      language = value7;

    });
    print("We got from shared : vol : $volume, , rate : $rate , pitch : $pitch");
  }

  _save_bool_to_shared(String key, var to_save ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, to_save);

    print("We saved : $to_save");
  }


  //Permet d'utiliser les hauts parleurs du smartphone
  Future _speak() async {

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    print("Val volume : $volume, rate : $rate pitch : $pitch");
    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        var result = await flutterTts.speak(_newVoiceText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  //Stop l'élocution

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  //Met en pause l'élocution

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }
  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();

  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (dynamic type in languages) {
      items.add(
          DropdownMenuItem(value: type as String, child: Text(type as String)));
    }
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  //Fonction a appeler pour le Text_To_Speech
  //Elle prend en argument ce que l'on veut entendre
  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
    _speak();
  }

  ///Bluetooth part
  ///

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();
  if(_isnotifset == false){
    if (characteristic.properties.notify) {
      characteristic.setNotifyValue(true);
      print("notification listening");
      _isnotifset = true;
    }

  }


    return buttons;
  }


  ListView _buildConnectDeviceView()  {
    List<Container> containers = new List<Container>();


  //if(_buildWidget == 1){
   // print("We are BUILDING SERVICES");
    for (BluetoothService service in services) {
      List<Widget> characteristicsWidget = new List<Widget>();

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if(characteristic.properties.notify){
          characteristicsWidget.add(

            Center(

              child: Column(
                children: <Widget>[
                  Align(alignment: Alignment.center,
                  child: StreamBuilder<List<int>>(
                    stream: characteristic.value,
                    initialData: characteristic.lastValue,
                    builder: (c, snapshot){

                      final value = snapshot.data;
                      if(snapshot.hasData && value.toString().length >2 && value.toString()!=_val){ //Permet de n'avoir l'affichage code-barre qu'une fois
                        ///Car le streambuilder recevait les données plusieurs fois d'affilées - donc affihage de plusieurs snackbars
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scaffoldKey.currentState.showSnackBar(
                            SnackBar(
                              duration: Duration(seconds: 15),
                                content:
                            Center(

                                child: Text(((){
                                  String _newcode = "";
                                  String _productname = "";
                                  _val = value.toString();

                                  String res = "";
                                  int _code = 0;
                                  print("Val de la longueur de val: ${_val.length}");
                                  if (_val.length > 2) {
                                    for (int i = 0; i < _val.length / 4-1; i++) {
                                      //print("Val $i : ${value[i]}");
                                      _code = value[i] - 48;

                                      _newcode = _newcode + _code.toString();
                                    }

                                  }
                                  //_productname = await databaseHelper.getOneAliment(_newcode);
                                  //Regarder pour print un contenu dynamique peut etre ? Ou caster la fonction dans
                                  //Le database helper pour qu'elle renvoie un string.
                                  res = "Code barre reçu : " + _newcode;
                                  _onChange(res);

                                  return res;

                                })())

                                  ,


                            )
                        ),
                          );
                       });
                      }
                      return Container();



                    },
                  ),
                    ),


                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),

                    ],
                  ),

                  Divider(),
                ],
              ),
            ),
          );
        }

      }
      containers.add(
        Container(
            child: Column(
              children: characteristicsWidget,
            ) ),

      );
    }
 // }



    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Bonjour",
        ),
        actions: <Widget>[
          Image.asset('images/logo_astek.png'),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.help),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) =>
                        Help(title: "Page d'aide")));
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              Container(
                height: SizeConfig.blockSizeVertical * 10,
                width: SizeConfig.blockSizeHorizontal * 90,
                margin: EdgeInsets.only(bottom: 50),
                child: AutoSizeText(
                  "Bonjour ! Touchez un produit svp",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical * 10,
                width: SizeConfig.blockSizeHorizontal * 90,
                child: AutoSizeText(
                  "Autonomie récepteur:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                ///TODO : Pour le texte, il faudra faire une changement de couleur avec le pourcentage de batterie.
                ///On pourra peut etre utiliser Fractionnaly sized box.
                ///Faire parler au démarrage avec le pourcentage de batterie envoyé
                //color: Colors.green,
                height: SizeConfig.blockSizeVertical * 10,
                width: SizeConfig.blockSizeHorizontal * 90,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.red, Colors.green],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0, 0.3]

                        /// Ici on aura du rouge jusqu'a 30% de la barre.
                        )),
                child: AutoSizeText(
                  "Ex : 50%",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 90,
                  ),
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical * 8,
                width: SizeConfig.blockSizeHorizontal * 90,
                margin: EdgeInsets.only(top: 15),
                child: AutoSizeText(
                  "Paramètres :",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical * 30,
                width: SizeConfig.blockSizeHorizontal * 90,
                //margin: EdgeInsets.symmetric(vertical: 10),
                child: Transform.scale(
                  scale: 9,
                  child: IconButton(
                    icon: Icon(
                      Icons.settings,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              Settings(title: "Paramètres", volume: volume, pitch: pitch, rate: rate, services: services,)));
                    },
                  ),
                ),
              ),
              ButtonTheme(
                height: SizeConfig.blockSizeVertical * 10,
                minWidth: SizeConfig.blockSizeHorizontal * 90,
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => FindDevicesScreen(

                            )));
                  },
                  child: Text(
                    "Apparairage récepteur",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  color: Colors.grey,
                ),
              ),
              _buildConnectDeviceView(),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message),
    action: SnackBarAction(
      label: "Connecté à ${device.name}",
      onPressed: null,
    ),);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }
}
