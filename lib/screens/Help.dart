import 'package:demo_astek/screens/Accueil.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './Accueil.dart';

import './../size_config.dart';
import 'package:flutter_blue/flutter_blue.dart';



///Page d'aide a aggrémenter si besoin
///
class Help extends StatefulWidget {
  BluetoothDevice device;
  Help({this.services, this.device, Key key, this.title}) : super(key: key);
  List<BluetoothService> services;
  final String title;

  @override
  _Help_State createState() => _Help_State(this.services, this.device);
}

class _Help_State extends State<Help>{
  List<BluetoothService> services;
  BluetoothDevice device;
  _Help_State(this.services, this.device);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
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

                  Navigator.push(context, MaterialPageRoute(builder:(context)=> Accueil(services: services,device : device)));
                },
              );
            },
          ),

      ),
      body: ListView(

          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20, bottom: 30,right: 10,left: 10),

              child: Text(
                "Bienvenue sur la page d'aide du démonstrateur Cap-Label ! ",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 35,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child:

              Text(
                "Comment appairer le récepteur avec l'application ?",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,


                ),

              ),
            ),
            Container(

              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
               "Allez sur la page 'Appairage', puis approchez simplement le récepteur du smartphone."
                   "Vous sentirez une vibration lorsque l'appairage est effectué"
                   "Assurez vous d'avoir le Bluetooth ET le GPS activé"
                   "Sinon le Scan ne fonctionnera pas !",
               textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Comment fonctionne la mise à jour automatique ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.wavy,


                ),

              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                "Il vous suffit de vous rendre dans l'onglet 'paramètres', puis de renseigner la fréquence "
                    "des mises à jour automatiques. Par exemple, si vous voulez effectuer une mise à jour toutes les semaines, il "
                    "vous suffit de rentrer '7', puis d'appuyer sur le bouton 'envoyer'. \n "
                    "Par défaut, la mise à jour automatique s'effectue tous les 15 jours.",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),

          ],

      ),
    );
  }
}