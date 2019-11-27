import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:preferences/preferences.dart';

const host="http://192.168.1.55/musica";
var ms ;
var todo;
AudioPlayer audioPlayer = null;

double duracion = 10;
double current = 0;


//-------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioPlayer = AudioPlayer();

  await PrefService.init(prefix: 'pref_');
  runApp(Ppal());
}



// RECUPERA EL JSON DEL SERVIDOR -----------------------------------------------

Future<List<dynamic>> makeGet(url) async {

  print("lanzar la consuta");
  // make GET request
  url = url+'/MUSICA.JSON';

  print(url);

  http.Response response = await http.get(url);
  // sample info available in response
  int statusCode = response.statusCode;
  Map<String, String> headers = response.headers;
  String contentType = headers['content-type'];
  String js = response.body;
  print(js);
  // TODO convert json to object...
  var caca = json.decode(js);
  print(caca['hijos']);
  ms = caca['hijos'];

  todo = ms;
  //runApp(MyApp() );

  return ms;

}

class Ppal extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mi Música",
      home: Setup(),
    );
  }
}

class Setup extends StatelessWidget{
  var _c;
  var _u;

  void empezar() {
    print("empezar");
    makeGet(_u).then((_) {
      print("REady !!!");
      Navigator.push(
        _c,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup'),
      ),
      body: Container(
        padding: EdgeInsets.all(50),
        child: Column(
          children: <Widget>[
            new FlatButton(
              onPressed: () =>_u = "http://192.168.1.55/musica",
              child: new Text("Raspi")
              ),

            new FlatButton(
                onPressed: () =>_u = "http://puturrudefua.es/musica",
                child: new Text("Puturrudefua.es")
            ),



          ],
        )
        /*
        PreferencePage([
          PreferenceTitle('Servidor'),

          RadioPreference(
            'Raspi',
            'http://192.168.1.55/musica',
            'servidor',
            isDefault: true,
          ),
          RadioPreference(
            'Remoto',
            'http://puturrudefua.es/musica',
            'servidor',
          ),
        ]),*/
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
            empezar();
            _c = context;
          },
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }

}
//---------------------------------------------------------------

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() {
    print("Create state !!");
    return new MyAppState();
  }
}

class MyAppState extends State<MyApp>{

  var hoja = null ;
  String img="";
  String _path = "/";
  String _name = "";
  var seleccionado;
  List _temas = [];


  void _goBack(){

    setState( (){

      print("home");
      img = "";
      ms = todo;
      _temas= [];

    });
  }

  void _click(){

    setState(() {

      ms = seleccionado;
      print("Click en carpeta: ");
      _path = hoja['path'];

      //print(seleccionado);
      if(hoja['fotos'].length > 0) {
        img = host + hoja['path'] + "/" + hoja['fotos'][0];
        print(img);
      }else img="http://puturrudefua.es/musica/casetes.jpg";

      List temasSonando = [];
      for (var t in hoja['temas']){
        temasSonando.add({'tema':t, "sonando": false});
      }
      print(_temas);
      _temas = temasSonando;
    });
  }

  void _play( var u ) async {


    Future<bool> playSong(u) async {

      audioPlayer.stop();

      print(  " >>>>> "+ u.toString());
      var urls = host+ _path +"/"+u['tema'];
      print(urls);
      audioPlayer.play(urls, stayAwake: true);

      audioPlayer.onDurationChanged.listen((Duration d) {
        duracion = d.inSeconds.toDouble();
      });

      audioPlayer.onAudioPositionChanged.listen((p){
        setState(() {
          current = p.inSeconds.toDouble();
        });
      });

      //escuchar cuando termine
      audioPlayer.onPlayerStateChanged.listen((e){

        //print(e.toString());

        // siguiente
        if(e.toString()=="AudioPlayerState.COMPLETED"){
          setState(() {
            u['sonando'] = false;
            current = 0.0;
          });
          print("\n\nTERMINADo "+ u['tema']);
          List l = hoja['temas'];
          var x = l.indexOf(u['tema']);
          print(" Posicion "+ x.toString() );

          print("\n\nsiguiente"+_temas[x+1].toString());
          audioPlayer.stop();
          _play(_temas[x+1]);
        }

      });

    }

    // obtener la posicion de la cancio
    print( "Tocar  "+u.toString());


    setState(() {
      u['sonando'] = true;
    });

    // Al ataquerl!!!
    playSong(u);

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musicola!',
      home: Scaffold(

          body: Column(

            children: [

              if(img!="") FittedBox(
                child: Image.network(img, scale:.1),
              ),


              if (img=="") FittedBox(
                  fit:BoxFit.fill,
                  child: FadeInImage.assetNetwork(
                    placeholder: 'images/disco.png',
                    image:img,
                  )
              ),

              Slider(
                activeColor: Colors.black26,
                min: 0.0,
                max: duracion,
                onChanged: (newPos) {
                  setState((){
                    current = newPos;
                    audioPlayer.seek(Duration(seconds: current.toInt()));
                  });
                },
                value: current,
              ),


              Expanded(
                //padding: EdgeInsets.all(0),
                  child: ListView(
                    children: <Widget>[
                      for(var m in ms) Container(

                          padding: EdgeInsets.only(left:  10, right: 10),
                          margin: EdgeInsets.all(0),
                          alignment: Alignment.topLeft,
                          child:
                          FlatButton(
                              onPressed: (){
                                hoja = m;
                                _name = m['name'];
                                _path = m['path'];
                                _temas = m['temas'];
                                seleccionado = m['hijos'];
                                _click();
                              },
                              child: Carpeta(m['name'])
                          )

                      ),

                      // CANCIONES *********
                      for(var t in _temas) Container(
                        child: FlatButton(
                            onPressed: ()=> _play(t),
                            child: Song(t)
                        ),
                      ),
                    ],

                  )
              ),
              Container(
                  padding: EdgeInsets.all(11),

                  child: FlatButton(
                      onPressed: (){
                        _goBack();
                      },
                      child: Text(_path))
              )
            ],
          )
      ),
    );
  }

}


class Song extends StatefulWidget {

  var song;
  Song(this.song);


  @override
  State<Song> createState() {
    print("Create song state -> "+ song.toString());
    return new SongState(song);
  }
}

class SongState extends State<Song>{

  var song;
  SongState(this.song); //constructor
  double _sliderValue = current;

  @override
  Widget build(BuildContext context) {
    return
      Column(
          children:[

            //-----------------------------------------------
            Container(
              padding: EdgeInsets.only(left:20),
              child: Row(
                  children:[
                    if(song['sonando']) Icon( Icons.play_arrow),
                    Flexible(
                      child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(song['tema'],
                            style: TextStyle(fontSize: 16, fontFamily: "Roboto"),
                          ),
                        ],
                      ),
                    ),
                  ]
              ),
            ),
            //--------------------------------------------------

          ]
      );
  }

}
//-------------------------------------------------------------------
class Carpeta extends StatelessWidget{

  final carpeta;
  Carpeta(this.carpeta); //constructor

  @override
  Widget build(BuildContext context) {

    return Container(
        padding: EdgeInsets.only(left:40),
        child: Row(
            children:[

              Container(
                padding: EdgeInsets.only(right:8),
                child:  Icon( Icons.folder),
              ),
              Flexible(
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[

                    Text(carpeta,
                      style: TextStyle(fontSize: 16, fontFamily: "Roboto"),
                    )
                  ],
                ),
              ),

            ]
        )

    );


  }

}