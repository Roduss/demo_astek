import 'package:flutter/material.dart';

//Déclaration de la classe Aliment

class Aliment {

  String _name;
  String _code;


  Aliment(this._code, this._name); //Constructeur 1

  String get name => _name;

  String get code => _code;




  set name(String newName) {
    ///On pourra ajouter des conditions sur le nom ou sur d'autres variables des Aliments
    if (newName.length <= 255 && newName.length >0) {
      this._name = newName;
    }
  }

  set price(String newCode) {
    this._code = newCode;
  }

  ///Conversion des aliments en Map

  Map<String, dynamic> toMap() {
    ///Dynamic veut dire qu'on peut mettre différents types d'objets.
    var map = Map<String, dynamic>();

    map['name'] = _name;
    map['code'] = _code;
    return map;
  }

  ///Extraire les Aliments d'une Map.

  Aliment.fromMapObject(Map<String, dynamic> map) {

    this._name = map['name'];
    this._code = map['code'];
  }
}
