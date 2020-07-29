import 'main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import './../size_config.dart';
import 'package:flutter_blue/flutter_blue.dart';



///PAge d'aide
///
class Help extends StatefulWidget {
  Help({this.services, Key key, this.title}) : super(key: key);
  List<BluetoothService> services;
  final String title;

  @override
  _Help_State createState() => _Help_State(this.services);
}

class _Help_State extends State<Help>{
  List<BluetoothService> services;
  _Help_State(this.services);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title : Text(
          widget.title,
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
                   "Vous sentirez une vibration lorsque l'appairage est effectué",
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