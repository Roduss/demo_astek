Les 8 fichiers codes doivent �tre organis�s de cette fa�on : 
	size_config dans le dossier lib
	aliment et database_helper dans un dossier "db_utils"
	building_ble_services dans un dossier "ble_utils"
	le reste dans un dossier "screens"

Voir le dossier github si besoin : https://github.com/Roduss/demo_astek


La base de donn�es est accessible au format csv au lien suivant : https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv

Pour acc�der � la base de donn�es sous d'autres format, voir ce lien : https://fr.openfoodfacts.org/data


Version flutter : v1.17.2

Version lbrairies : (voir pubspec.yaml)

  auto_size_text: ^2.1.0
  intl: ^0.16.1
  shared_preferences: ^0.5.7+3
  sqflite: ^1.3.0+2
  csv: ^4.0.3
  characters : ^1.0.0
  flutter_tts: ^1.2.6
  flutter_blue: ^0.7.2
  path_provider: ^1.6.10
  intl: ^0.16.1


Voici leur utilit� :
	-main : Page de d�marrage, appairage r�cepteur & page pour activer Bluetooth
	-Accueil : Page d'accueil, avec possibilit� d'acc�der � l'aide, les param�tres et la batterie, le T2Speech ne fonctionne que sur cette
page pour le moment
	-Help : Page d'aide avec texte pour "tutos"
	-Settings : Page pour param�trer langue, voix, MAJ auto & acc�der � database_list
	- database_list : Permet d'afficher et modifier le contenu de la BDD
	-aliment : Permet de cr�er une classe de type Aliment
	-database_helper : Permet d'effectuer les op�ration CRUD sur la BDD
	-size_config: Permet de redimensionner rapidemment des Widget
	- building_ble_services : Permet de donner un bel aspect graphique � la liste 
des appareils Bluetooth a proximit� de la page main.

Faire compiler le programme : 
flutter pub get (ou r�cup�rer les d�pendences en se placant sur le fichier pubspec
Changer le fichier build.gradle dans android/app/ : 
	minSdkVersion X ==> minSdkVersion 21
(X num�ro version par d�faut)