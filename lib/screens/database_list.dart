import 'package:demo_astek/screens/Settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async' show Future;

import './../db_utils/database_helper.dart';
import './../db_utils/aliment.dart';


import 'package:flutter_blue/flutter_blue.dart';

///Permet d'afficher la liste des aliments dans la BDD
///Accessible uniquement lorsqu'on arrive sur la page de settings via une snackbar.

class DBList extends StatefulWidget {
  DBList({Key key, this.title, this.services, this.device}) : super(key: key);
  final List<BluetoothService> services;
  final String title;
  final BluetoothDevice device;

  @override
  _DBList_State createState() => _DBList_State(this.title,this.services, this.device);
}


class _DBList_State extends State<DBList> {
  List<BluetoothService> services;
  BluetoothDevice device;
  DatabaseHelper databaseHelper = DatabaseHelper();
  int count = 0;
  List<Aliment> foodList;
  Aliment aliment;
  String title;
  _DBList_State(this.title, this.services, this.device);

  var _scaffoldKey = new GlobalKey<ScaffoldState>();


  @override
  void initState(){
    super.initState();
    updateListView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(title,),
        leading: Builder(
          builder: (BuildContext context){
            return IconButton(
              icon : const Icon(Icons.subdirectory_arrow_left),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder:(context)=> Settings(services: services, device: device, title: "Paramètres"
                  ,)));
              },
            );
          },
        ),
      ),
      body: getListView(),
        floatingActionButton: FloatingActionButton(

          onPressed: () {
            _showDialog(0, "Supression de tous les aliments ?", 0);
          },
          child: Icon(Icons.delete_forever),
          backgroundColor: Colors.red,
        ),
    );
  }

  ListView getListView(){
    return ListView.builder(
        itemCount:
        count, //Il prendra la longueur de la liste ds la fonction updatelistview
        itemBuilder: (BuildContext context, int position) {
          return Card(
            color: Colors.white,
            elevation: 2.0,
            child: ListTile(
              leading: Icon(Icons.fastfood),
              trailing: GestureDetector(
                child: Icon(Icons.delete),
                onTap: (){
                  _showDialog(position,"Supression de cet aliment : ${foodList[position].name} ?",1);
                },
              ),
              title: Text(this.foodList[position].name),
              subtitle: Text(
                  'code-barre : ${this.foodList[position].code}'),
            ),
          );
        });

  }

  void _delete_all_db() async {
    int result = await databaseHelper.deleteAll();
    if (result !=0 ){
      _showSnackBar(context, "Supprimé !");
      updateListView();
    }
    else{
      _showSnackBar(context, "Erreur suppression");
    }
  }

  void _showSnackBar(BuildContext context, String message) {

    final snackBar = SnackBar(content: Text(message)     );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<void> _showDialog(int position, String message, int choix) {
  
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Attention"),
            content: new Text(message),
            actions: <Widget>[
              FlatButton(
                child: Text("Oui"),
                onPressed: () {
                  if(choix == 1){
                    _delete(foodList[position]);
                  }
                  if (choix ==0){
                    _delete_all_db();
                  }

                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text("Non"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void _delete(Aliment aliment) async {
    int result = await databaseHelper.deleteAliment(aliment.name);

    if (result != 0) {

      _showSnackBar(context, "Supprimé");
      updateListView();

    } else {

      _showSnackBar(context, "Problème de suppression");
    }
  }

  updateListView() async {
    await databaseHelper.initializeDatabase();
    List<Aliment> foodListFuture = await databaseHelper.getAlimentList();
    this.foodList = foodListFuture;
    this.count = foodListFuture.length;

    setState(() {

    });

  }
}