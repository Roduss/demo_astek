import './Accueil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import './../size_config.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './database_list.dart';

import 'package:csv/csv.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import './../db_utils/database_helper.dart';
import './../db_utils/aliment.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_blue/flutter_blue.dart';


///Page de paramètres

//Définition des états pour le Text-To-Speech, voir la page de l'extension pour plus d'infos
enum TtsState { playing, stopped, paused, continued }


class Settings extends StatefulWidget {
  final double volume ;
  final double pitch ;
  final double rate ;
  final String language;
  final List<BluetoothService> services;
  final BluetoothDevice device;
  Settings({this.volume, this.pitch, this.rate, this.language,Key key, this.title, this.services, this.device}) : super(key: key);

  final String title;

  @override
  _Settings_State createState() {
    return _Settings_State(this.volume, this.pitch, this.rate, this.language, this.services, this.device);
  }
}

class _Settings_State extends State<Settings>{

  //Déclaration des variables
  BluetoothDevice device;
  final _updatekey = GlobalKey<FormState>();
  var _currentItemSelected = 'Français';
  var _voices = ['Jeanne', 'Robert'];
  var _currentVoiceSelected = 'Jeanne';
  bool my_assets = false;

  List<BluetoothService> services;

  var now;
  var time;
  var time_for_diff;
  var formatedTime;
  String timeString;
  var nb_days='12'; //Délai de MAJ AUTO initial

  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  //===Partie DB====//
  DatabaseHelper databaseHelper = DatabaseHelper();
  int count = 0;
  List<Aliment> foodList;
  Aliment aliment;

  List<List<dynamic>> data = [];

  //====Partie TextToSpeech=====

  FlutterTts flutterTts;
  double volume;
  double pitch;
  double rate;
  String language;
  dynamic languages;
  int nb_insert=0;

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  _Settings_State(this.volume, this.pitch, this.rate, this.language, this.services, this.device);

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  get isPaused => ttsState == TtsState.paused;

  get isContinued => ttsState == TtsState.continued;

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (dynamic type in languages) {
      items.add(
          DropdownMenuItem(value:
          type as String,
              child:
              Text(type as String,
                  style: TextStyle(
                    fontSize: 40,)
              )));
    }
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
      _save_to_shared('language', language);
    });
  }

//Récupère le language sélectionné
  //Le langage au démarrage est initialisé sur Français avec les sharedpreferences.
  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  initTts() {
    flutterTts = FlutterTts();
    _getLanguages();

  }
 //Permet d'utiliser les hauts parleurs pour le Text-To-Speech
 //Utiliser la fonction Onchange pour envoyer une string particulière.
  Future _speak() async {
    print("Val volume : $volume, rate : $rate pitch : $pitch");
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        var result = await flutterTts.speak(_newVoiceText);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  //Fonction a utiliser pour parler
  //Elle récupère en argument ce que l'on veut entendre
  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
    _speak();
  }


 //Charge le fichier csv en mémoire
  loadAsset() async { //Chargement fichier CSV
    final myData = await rootBundle.loadString("assets/My_csv_test.csv");
    List<List<dynamic>> csvTable = CsvToListConverter().convert(myData);

    data = csvTable;
    my_assets = true;
    print("Assets loaded!");
  }

  //Conversion du contenu du CSV en une liste d'aliments
  //Nous utilisons ici différents filtres afin de ne pas surcharger la BDD avec des aliments qui ne seront pas utilisés 
  //Par ex : Les aliments de Grande Bretagne ou des States
  ///Cependant, nous pourrons ajouter une option ou télécharger les différents codes barres en fonction du pays dans lequel 
  ///nous nous trouvons.
  Future<List<Aliment>> convertListToAlim() async {
    int datacount = data.length;
    List<Aliment> newfoodList = List<Aliment>();

    for (int i = 1; i < datacount; i++) {
      ///Le fichier csv a été modifié avec python en utilisant Pandas, le code devrait être disponible sur Sharepoint
      ///Il n'est pas optmisé et nécéssite un post traitement sur Excel malheureusement
      ///(Pandas ajoute une colonne de nombre qu'il auto-incrémente lorsqu'il fait son traitement ...)
      if(data[i][1] is String && data[i][1] != "" && data[i][2].contains("France")){
        aliment = Aliment(data[i][0].toString(), data[i][1]);
        newfoodList.add(aliment);
      }
      else{
        print("Error, name not String, null or not French");
      }

    }

    return newfoodList;
  }


//Insertion d'un i-eme aliment dans la BDD
  Future<int> insertOneToDb(int i, List<Aliment> myList) async {
    int result = await databaseHelper
        .insertAliment(myList[i]); //On doit avoir des types aliments donc
    if (result != 0) {

      nb_insert++; //Peut permettre de savoir combien d'aliments on été insérés dans la BDD
      ///Le problème est qu'il s'incrémente meme quand l'aliment est déja présent dans la BDD à cause de l'INDEX UNIQUE
      ///sur le code barre.
    } else {
      print("Failure to save bdd");
    }
    return result;
  }


//Comparaison de la liste avec la BDD avant insertions
  //Nous voulions récupérer le nombre d'éléments ajoutés mais nous rencontrons encore des problèmes avec async await
  //insertOnetoDb ne se termine jamais s'il est mis en "await", or nous avons besoin de le mettre en await pour compter le nombre d'éléments ajoutés

  Future compareLists() async {


    List<Aliment> csvFoodList = await convertListToAlim(); //Liste d'aliments csv.

    //Les contraintes "UNIQUE" permettent de ne pas insérer de doublons
    //l'INDEX permet d'accélérer la recherche de doublons
    //Voir database_helper pour plus de détails
    for (int i = 0; i< csvFoodList.length; i++) {
      //print("on insère : ${csvFoodList[i].name} avec ce code : ${csvFoodList[i].code}");

      insertOneToDb(i, csvFoodList);
      ///Finalement, la comparaison se fait directement avec l'index que nous avons ajouté
      ///Lors de la création de la BDD
    }

    //print("We added $nb_insert elements to BDD");
    ///On voulait ajouter nb_insert dans la snackbar pour avoir une indication sur le nombre d'éléments ajoutés
    ///Si on remet cette snackbar, il faudra enlever celle qui est dans check auto_update (pour la condition true, pas pour l'autre !)
    //_showSnackBar(context, "La BDD a été éditée, cliquez ici pour la voir");
    nb_insert=0;
    csvFoodList.clear();


  }

//Récupération shared_preferences
  Future <Null> _get_shared() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final key = 'time_last_Update';
    final key1 = 'language';
    final key2 = 'voice';
    final key3 = 'nb_days_auto_maj';
    final key4 = 'volume';
    final key5 = 'pitch';
    final key6 =  'rate';
    final key7 = 'language';


    final value = prefs.getString(key) ?? 'Never';
    final value1 = prefs.getString(key1) ?? 'Français';
    final value2 = prefs.getString(key2) ?? 'Jeanne';
    final value3 = prefs.getString(key3) ?? '15';
    final value4 = prefs.getDouble(key4) ?? 0.5;
    final value5 = prefs.getDouble(key5) ?? 1;
    final value6 = prefs.getDouble(key6) ?? 0.5;
    final value7 = prefs.getString(key7) ??'fr-FR';


    setState(() {
      timeString = value;
      _currentItemSelected = value1;
      _currentVoiceSelected = value2;
      nb_days = value3;
      volume = value4;
      pitch = value5;
      rate = value6;
      language = value7;

    });

    if(timeString != 'Never'){
      time_for_diff = DateFormat("yyyy-MM-dd hh:mm").parse((timeString));
    }
    else{
      time_for_diff= DateFormat("yyyy-MM-dd hh:mm").parse("2020-07-01 12:30");
      ///Lorsque la MAJ n'a jamais été effectuée, nous disons que la dernière mise à jour date de cette date la.
    }

    ///Debug only
    print("valeur de langue $_currentItemSelected et de voix : $_currentVoiceSelected");
   print("Valeur de timestring : $timeString");
   print("Valeur de timefordiff : $time_for_diff");
   print("Valeur de nb days : $nb_days");
   print("Valeur volume : $volume, pitch : $pitch, rate : $rate");
  }

  //Lorsque nous arrivons sur la page, nous vérifions s'il y a un besoin de mise à jour
  @override
  void initState() {
    super.initState();
    initTts();
    _check_auto_update();

    //En vérifiant l'update on récupére les shared_preferences
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }


  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title : Text(
          widget.title,
        ),
        leading: Builder(
          builder: (BuildContext context){
            return IconButton(
              icon : const Icon(Icons.subdirectory_arrow_left),
              onPressed: (){
                print("On envoie : volume : $volume, pitch : $pitch");
                Navigator.push(context, MaterialPageRoute(builder:(context)=> Accueil(volume : volume,pitch : pitch,rate : rate,language : language, services: services,device: device,)));
              },
            );
          },
        ),

      ),

      body: Builder(
        builder : (BuildContext context){
          return SingleChildScrollView(
            child:  Center(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 30,bottom: 10),

                    width: SizeConfig.blockSizeHorizontal * 90,
                    child: AutoSizeText(
                      "Changer de langue :",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,

                    ),

                  ),

                  Container(
                    width: SizeConfig.blockSizeHorizontal * 90,
                    child:  languages != null ? _languageDropDownSection() : Text(""),
                  ),


                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 10),

                    width: SizeConfig.blockSizeHorizontal * 90,
                    child: AutoSizeText(
                      "Choix de la voix :",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,

                    ),

                  ),


                  Container(
                    width: SizeConfig.blockSizeHorizontal * 90,
                    margin: EdgeInsets.only(bottom: 30),
                    child:  DropdownButton<String>(

                      items: _voices.map((String dropDownStringItem) {
                        return DropdownMenuItem<String>(
                          value: dropDownStringItem,

                          child: AutoSizeText(dropDownStringItem,
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.black,
                            ),),
                        );
                      }).toList(),
                      //Les items sont sous forme de liste, on prend un tableau de String qu'on converti en liste.
                      ///Pour l'instant, le choix de voix n'est pas possible avec l'extension T2Speech.
                      ///Pourra être implémentée plus tard.

                      onChanged: (String newVoiceSelected) {
                        _onDropDownItemSelected(newVoiceSelected,1);
                      },

                      value: _currentVoiceSelected,
                      isExpanded: true,
                      iconSize: 70,
                    ),
                  ),

                  Container(
                    width: SizeConfig.blockSizeHorizontal * 90,
                    margin: EdgeInsets.only(bottom: 30),
                    child: AutoSizeText(
                      "Paramétrer voix :",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                  ),),
                  Container(
                    width: SizeConfig.blockSizeHorizontal * 90,
                    margin: EdgeInsets.only(bottom: 30),
                    child: _buildSliders(), ///Sliders pour les paramètres du T2Speech.
                  ),

                  Row(

                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(left : 15, right :15),
                        width: SizeConfig.blockSizeHorizontal * 50,
                        child: Form(
                          key: _updatekey,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nb jours MAJ auto : $nb_days',

                            ),
                            validator: (value){
                              ///Nous obligeons à avoir au moins 1 MAJ de la BDD par an, la condition peut être modifié ! 
                              if(value.isEmpty || int.tryParse(value) == null|| int.tryParse(value)<1 || int.tryParse(value)>365){
                                print("Here is value $value");
                                return 'Entrez un nombre entre 1 et 365';
                              }
                              else {

                                if(int.tryParse(value) != null)
                                {
                                  nb_days=value;
                                }
                                else{
                                  print("Error parsing nbdays");
                                }
                                print("nb days : $nb_days");
                              }

                              return null;
                            },
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ButtonTheme(

                          height: SizeConfig.blockSizeVertical * 10,
                          minWidth: SizeConfig.blockSizeHorizontal * 40,
                          child: RaisedButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side : BorderSide(color: Colors.red)
                            ),
                            onPressed: () async {
                              FocusScope.of(context).unfocus(); //Baisse le clavier numérique

                              if(_updatekey.currentState.validate()){
                                _save_to_shared('nb_days_auto_maj', nb_days);
                                print("We saved nb days ! $nb_days");

                                await _check_auto_update();

                              }
                            },
                            color: Colors.green,
                            child: Text('Envoyer'),
                          ),
                        ),
                      )

                    ],
                  ),


                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child:
                    ButtonTheme(

                      height: SizeConfig.blockSizeVertical * 10,
                      minWidth: SizeConfig.blockSizeHorizontal * 90,
                      child: RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.black)),
                        onPressed: () {
                          _update_database();


                        },
                        child: Text(
                          "Mise à jour Base de Données",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(top: 30, bottom: 20),

                    width: SizeConfig.blockSizeHorizontal * 90,
                    child: AutoSizeText(
                      "Heure dernière mise à jour : $timeString",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,

                    ),

                  ),

                ],
              ),
            ),
          );

        }
      )

    );
  }

  //Menu déroulant du langage
  Widget _languageDropDownSection() => Container(

      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(),
          onChanged: changedLanguageDropDownItem,

        )
      ]));

  //Permet d'afficher les sliders pour configurer le text-to-speech
  Widget _buildSliders() {
    return Column(
      children: [
        AutoSizeText("Volume : "),
        _volume(),
        AutoSizeText("Tonalité :"),
        _pitch(),
        AutoSizeText("Vitesse d'élocution"),
        _rate()],
    );
  }
  Widget _volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) {
          setState(() {
            volume = newVolume;
            _save_double_to_shared('volume', volume);
          }
          );
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $volume");
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() => pitch = newPitch);
        _save_double_to_shared('pitch', pitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $pitch",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() => rate = newRate);
        _save_double_to_shared('rate', rate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $rate",
      activeColor: Colors.green,
    );
  }

  //Permet de changer la personne qui parle
  //Nous avons ajouté une variable "choice" au cas ou nous ajouterions d'autres menus déroulants dans le futur
  void _onDropDownItemSelected(String newValueSelected,int choice) {
    //Cette fonction actualise l'écran en fonction du choix des menus.

    if (choice ==1){
      print("We changed voice");
      setState(() {

        this._currentVoiceSelected = newValueSelected;
        _onChange(_currentVoiceSelected);
        _save_to_shared('voice', _currentVoiceSelected);
      });
    }
  }

  //Sauvegarde des strings dans les sharedpreferences
  _save_to_shared(String key, var to_save ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, to_save);

    print("We saved : $to_save");
  }
//Sauvegarde des doubles dans les sharedpreferences
  _save_double_to_shared(String key, var to_save) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble(key, to_save);

    print("We saved : $to_save");
  }




  Future<DateTime> _update_database() async{
    print("We run update");
    time = DateTime.now();
    time_for_diff=DateTime.now();
    formatedTime = DateFormat('yyyy-MM-dd kk:mm').format(time);
    if(my_assets == false){
      await loadAsset(); // Permet de ne pas charger en mémoire la liste csv à chaque fois
    }

    compareLists(); ///Permet d'ajouter les éléments manquants à la BDD en partant du fichier CSV.

    setState(() {

      timeString = formatedTime.toString();
      print("valeur timestring : $timeString");
      print("valeur time $time");

    });
    _save_to_shared('time_last_Update', timeString);

    return time;
  }


  //Cette fonction se lance lorsque nous arrivons sur la page de paramètres ou
  //Lorsque nous définissons un intervalle de MAJ auto
  Future<int> _check_auto_update() async{
    now = DateTime.now(); ///Récupère l'heure actuelle
    await _get_shared(); ///Récupère la date de la dernière MAJ.

    var difference = now.difference(time_for_diff);
    print("Here is the diff : ${difference.inDays}");
    int diff_day = difference.inDays;


    if(diff_day>=int.parse(nb_days)){
      await _update_database();
      ///Si on remet la snackbar avec le nombre d'éléments, on devra commenter celle ci !
      _showSnackBar(context, "On a fait une MAJ auto !");
      return 0;

    }
    else{
      print("No need for updates !");
      _showSnackBar(context," pas d'auto-update aujourd'hui !");
      return 1;
    }
  }

  updateListView() async { //Update la vue de l'interface
    await databaseHelper.initializeDatabase();
    List<Aliment> foodListFuture = await databaseHelper.getAlimentList();
    this.foodList = foodListFuture;
    this.count = foodListFuture.length;
  print("longueur foodlist dans l'update:  ${foodListFuture.length}");
    setState(() {

    });

  }

  void _showSnackBar(BuildContext context, String message) {
      //La snackbar permet un accès au contenu de la BDD
    final snackBar = SnackBar(content: Text(message),
    action: SnackBarAction(
        label : "voir BDD",
      onPressed: (){
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => DBList(title : "Contenu BDD", services: services, device : device)));
      },
    ),);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

}