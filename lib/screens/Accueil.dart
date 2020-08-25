import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'main.dart';
import './../size_config.dart';
import 'package:flutter/material.dart';
import 'dart:async' show Future;
import './../db_utils/database_helper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Help.dart';
import 'Settings.dart';

///TODO :

///Check pour utiliser avec écran éteint.
///
///Récupération de la BDD via internet puis accéder en local.
///
///Utiliser l'extension pour parler en background.
///
///Le Streambuilder s'éxécute toujours plusieurs fois,
///Il donne parfois des paramètres random au T2S, mais
///Avant de parler il récupère les bons, le programme est donc fonctionnel
///Mais peut encore etre amélioré !
///
///
///
/// Pour le texte, il faudra faire une changement de couleur avec le pourcentage de batterie.
///On pourra peut etre utiliser Fractionnaly sized box.
///Faire parler au démarrage avec le pourcentage de batterie envoyé

enum TtsState { playing, stopped, paused, continued } //Pour le T2Speech

class Accueil extends StatefulWidget {
  final double volume;
  final double pitch;
  final double rate;
  final String language;

  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;
  final List<BluetoothService> services;

  Accueil(
      {this.volume,
      this.pitch,
      this.rate,
      this.language,
      this.device,
      this.characteristic,
      this.services});
//On met des "named arguments" ici pour pouvoir les utiliser dans l'ordre qu'on veut

  @override
  _Accueil_State createState() {
    return _Accueil_State(this.volume, this.pitch, this.rate, this.language,
        this.device, this.characteristic, this.services);
  }
}

class _Accueil_State extends State<Accueil> {
  //Déclaration des variables
  BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  final mylistener = ValueNotifier(0);

  List<BluetoothService> services;

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume;
  double pitch;
  double rate;
  String mystate;

  bool _isnotifset = false;
  String _productname = "";
  String _newcode = "";

  String _val;

  DatabaseHelper databaseHelper = DatabaseHelper();

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //Constructeur & getters

  _Accueil_State(this.volume, this.pitch, this.rate, this.language, this.device,
      this.characteristic, this.services);

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  get isPaused => ttsState == TtsState.paused;

  get isContinued => ttsState == TtsState.continued;

  @override
  initState() {
    super.initState();

    _get_shared();
    mylistener.addListener(changesOnName); //Permet d'écouter les changements & faire recherche dans BDD
    initTts();
    print("value volume init : $volume , $rate, $pitch");
  }

  //Permet de récupérer la liste des langages disponibles
  initTts() {
    flutterTts = FlutterTts();
    _getLanguages();
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  //Récupération des shared preferences
  //Pourra peut etre s'optimiser et garder uniquement la fonction ici car on le fait aussi dans les "Settings"
  //C'est peut etre pas utile.
  Future<Null> _get_shared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final key4 = 'volume';
    final key5 = 'pitch';
    final key6 = 'rate';
    final key7 = 'language';

    final value4 = prefs.getDouble(key4) ?? 0.5;
    final value5 = prefs.getDouble(key5) ?? 1;
    final value6 = prefs.getDouble(key6) ?? 0.5;
    final value7 = prefs.getString(key7) ?? 'fr-FR';

    setState(() {
      volume = value4;
      pitch = value5;
      rate = value6;
      language = value7;
    });
    print(
        "We got from shared : vol : $volume, , rate : $rate , pitch : $pitch");
  }

  //Recherche occurence dans BDD
  changesOnName() async {
    if (_newcode != null) {
      await _searchproduct(_newcode);
    } else {
      _productname = null;
    }

    //Permet d'afficher une snackbar lorsqu'on touche un produit.
    //Le widget binding permet de construire la snackbar quand les
    //Widgets sont build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_productname != null) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
              backgroundColor: Colors.blueGrey,
              duration: Duration(seconds: 5),
              content: Center(
                child: Text("Nom produit : $_productname"),
              )),
        );
        _onChange(_productname);
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          backgroundColor: Colors.blueGrey
          ,
          duration: Duration(seconds: 5),
          content: Center(
            child: Text("produit non trouvé !"),
          ),
        ));
        _onChange("Produit non trouvé !");
      }
      setState(() {});
    });
  }

  //Permet d'utiliser les hauts parleurs du smartphone
  //Appelé par la fonction _onChange.
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


  //Fonction a apeller pour utiliser Text_To_Speech

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
    _speak();
  }

  ///Bluetooth :

  Future _searchproduct(String code) async {
    _productname = await databaseHelper.getOneAliment(code);
    print("We set the name to the product : $_productname");
  }




///Cette fonction active les notifications pour les services concernés
///De base, il y a 3 services avec la carte nRF, un seul permet de recevoir les
///notifications, c'est celui auquel on souscrit ici.
///La fonction ne retourne plus de boutons, car nous voulons que tout s'effectue en background
///Elle est appelée dans la fonction _buildConnectDeviceView
  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();
    if (_isnotifset == false) {
      ///Permet d'activer les notifications automatiques une seule fois pour éviter les erreurs
      ///Transfert de données automatiques entre émetteur/receveur
      if (characteristic.properties.notify) {
        characteristic.setNotifyValue(true);
        print("notification listening");
        _isnotifset = true;
      }
    }

    return buttons;
  }

  ///Cette fonction écoute le service auquel nous avons souscrit auparavant 
  ///dans _buildReadWriteNotifyButton et traite les données.
  ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in services) {
      List<Widget> characteristicsWidget = new List<Widget>();

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          characteristicsWidget.add(
            Center(
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: StreamBuilder<List<int>>(
                      stream: characteristic.value,
                      initialData: characteristic.lastValue,
                      builder: (c, snapshot) {
                        final value = snapshot.data;
                        if (snapshot.hasData &&
                            value.toString().length > 2 &&
                            value.toString() != _val)
                        {
                          ///Permet de n'avoir l'affichage code-barre qu'une fois
                          ///Car le streambuilder recevait les données plusieurs fois d'affilées - donc affichage de plusieurs snackbars
                          ///Le problème de cette condition est que l'on ne peut toucher 2 fois d'affilée le même produit.
                          ///La dernière condition sera peut être à modifier

                          Text((() {
                            _val = value.toString();
                            var _mytab = List(14); //De 0 a 14
                            ///La Taille de mytab peut etre à modifier (mini : 13 car 13 chiffres + retour à la ligne );

                            String res = "";

                            int i = 0;
                            print("Val de la longueur de val: ${_val.length}");
                            print(value.toString());
                            if (_val.length > 2) {
                              while (value[i] != 10 && i < 14) { //Condition sur la taille des code-barre
                                _mytab[i] = value[i] - 48; //Conversion ASCII Décimale (chiffres uniquement)

                                _newcode = _newcode + _mytab[i].toString();
                                i++;
                              }
                              mylistener.notifyListeners();
                              //Permet de chercher les occurences dans la BDD quand le code barre est reçu,
                              // puis de parler.
                            }

                            res = "code barre : " + _newcode;
                            _newcode = "";

                            _mytab = [0];
                            print(res);
                            return res;
                          })());
                        }

                        return Container();
                      },
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic), //Ne retourne rien car s'effectue en background.
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
          //Ajoute un container vide qui sera situé en bas de l'écran, comme invisible pour l'utilisateur
        )),
      );
    }
    // }

    return ListView( //Affiche le container (vide) correspondant au service auquel nous avons souscrit précédemment.
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
          "Bienvenue !",
        ),
        actions: <Widget>[
          RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: BorderSide(color: Colors.black)),
            color: Colors.amber[800],
            child: Text('DECONNECTER'),
            onPressed: () async {
              await device.disconnect();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => FindDevicesScreen()));
            },
          ),
          // Image.asset('images/logo_astek.png'),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.help),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Help(
                        services: services,
                        device: device,
                        title: "Page d'aide")));
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView( ///Construction de l'interface graphique
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
                  "Ex : 50%", ///TODO : Il faudra surement créer un Streambuilder pour écouter périodiquement la batterie
                  ///Restante.
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
                          builder: (BuildContext context) => Settings(
                                title: "Paramètres",
                                volume: volume,
                                pitch: pitch,
                                rate: rate,
                                services: services,
                                device: device,
                              )));
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
                    if (BluetoothDeviceState.disconnected == true) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              FindDevicesScreen()));
                    } else {
                      _showSnackBar(context,
                          "Vous etes déja connecté, veuillez vous déconnecter d'abord"); ///Sinon, nous pourrons cacher le bouton
                          ///Ou le griser.
                    }
                  },
                  child: Text(
                    "Apparairage récepteur",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  color: Colors.grey,
                ),
              ),
              _buildConnectDeviceView(), ///Streambuilder qui traite les données reçues du Bluetooth
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }
}
