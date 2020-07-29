import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import './aliment.dart';



//Création des différentes fonctions utiles à la BDD


class DatabaseHelper{
  static DatabaseHelper _databaseHelper; //Initialisé une seule fois quand on lance l'appli jusqu'a ce qu'on la ferme
//C'est ce qu'on appelle un singleton.

  static Database _database; //Singleton db aussi

  ///On déclare tous les objets maintenant
  ///

  String alimentTable = 'alimentTable';
  String myindex="my_index";
  String colName = 'name';
  String colCode = 'code';


  DatabaseHelper._createInstance();

  ///Partie création de la DB !
  factory DatabaseHelper(){
    //Factory permet de retourner des valeurs en utilisant un constructeur

    if(_databaseHelper == null){ //On ne le crée qu'une fois, d'ou singleton
      _databaseHelper = DatabaseHelper._createInstance();
    }

  return _databaseHelper;
  }

  Future<Database> get database async{
    if(_database == null){
      _database = await initializeDatabase();
    }
    return _database;
  }

 Future<Database> initializeDatabase() async { //On initialise maintenant
    //On récupère la db
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path+'aliments.db';

    //Maintenant qu'on à défini un chemin pour la db, on la crée

    var alimentDatabase = await openDatabase(path, version : 1, onCreate: _createDb);
    return alimentDatabase;
  }

  void _createDb(Database db, int newVersion) async { // On crée la db ici
    await db.execute('CREATE TABLE $alimentTable($colName TEXT NOT NULL,'
        '$colCode TEXT NOT NULL) ');
    await db.execute('CREATE UNIQUE INDEX $myindex ON $alimentTable($colCode)');
  }

  ///FIN création db
///
/// CRUD Opération :
/// Fetch :

Future<List<Map<String, dynamic>>> getAlimMapList() async{
    Database db = await this.database;
    var result = await db.rawQuery('SELECT * FROM $alimentTable order by $colName ASC');
    return result;
    //Result est un future de list of map car DB de différents styles (d'ou dynamic)
  //On le convertira en liste d'aliments plus tard, pour l'instant on a une liste de Map du coup.
}


Future <int> insertAliment(Aliment aliment) async{
    Database db = await this.database;
    var result = await db.insert(alimentTable, aliment.toMap()); //Bien convertir en objet MAP
  //sinon tu pourras pas l'insérer !
  return result;
}

Future<int> updateAliment(Aliment aliment) async{
    var db = await this.database;
    var result = await db.update(alimentTable, aliment.toMap(), where: '$colName = ?', whereArgs: [aliment.name]);
    return result;
}

Future<int> deleteAliment(String name) async {
    var db = await this.database;
    int result = await db.rawDelete('DELETE FROM $alimentTable WHERE $colName = ?', ['$name']);
    return result;
}

Future<int> deleteAll() async {
    var db = await this.database;
    int result = await db.rawDelete('DELETE FROM $alimentTable');
    return result;
}

//Fonction pour récupérer un aliment lors de la recherche future.
  Future<List<Map<String, dynamic>>> getOneAliment(String barcode) async {

    var db=await this.database;
    var prod_name = await db.rawQuery('SELECT $colName FROM $alimentTable WHERE $colCode =$barcode ');
    return prod_name;
  }


//Récupère nombre d'éléments

Future<int> getCount() async {
    var db = await this.database;
    List<Map<String, dynamic>> number = await db.rawQuery('SELECT COUNT (*) from $alimentTable');
    int result = Sqflite.firstIntValue(number);
    return result;
}

//Avec getalimentmaplist, on récupère une liste de Map, pas une liste d'Aliments !
  //On crée donc cette fonction pour récupérer cette liste de map et convertir en liste d'aliments.
Future<List<Aliment>> getAlimentList() async{
    var alimentMapList = await getAlimMapList(); //On récupère la liste de map
    int count = alimentMapList.length;
    //print("l'aliment maplist : $alimentMapList");
    List<Aliment> alimentList = List<Aliment>(); //Empty list of note

    for(int i=0;i< count; i++){
      alimentList.add(Aliment.fromMapObject(alimentMapList[i]));
    }
  return alimentList;
}

}