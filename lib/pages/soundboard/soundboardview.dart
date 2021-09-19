import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nlapp/drawer.dart';
import 'dart:convert';

class SoundboardView extends StatefulWidget {
  static const String routeName = '/soundboard';
  final Multimap<String, String> soundList = new Multimap<String, String>();

  @override
  _SoundboardView createState() {
    return _SoundboardView();
  }
}

class _SoundboardView extends State<SoundboardView> {
  static AudioPlayer audioPlayer = AudioPlayer(playerId: 'soundboard');
  AudioCache audioCache = AudioCache(fixedPlayer: audioPlayer);

  Future _listAssets(BuildContext context) async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    List<String> listMp3 =
        manifestMap.keys.where((String key) => key.contains('.mp3')).toList();
    listMp3.forEach((mp3) {
      var file =
          mp3.split('assets/sounds/')[1].replaceAll('%20', ' ').split('-');
      this.setState(() {
        widget.soundList.add(file[0].trim(), file[1].trim());
      });
    });
    widget.soundList.forEach((key, value) {
      print('[$key->$value]');
    });
  }

  @override
  void initState() {
    _listAssets(context);

    if (kIsWeb) {
      // Calls to Platform.isIOS fails on web
      return;
    }
    if (Platform.isIOS) {
      audioCache.fixedPlayer.notificationService.startHeadlessService();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: DefaultTabController(
      length: widget.soundList.length,
      child: Scaffold(
        drawer: createDrawer(context),
        appBar: AppBar(
          title: const Text('Soundboard'),
          bottom: new TabBar(
            isScrollable: true,
            tabs: List<Widget>.generate(widget.soundList.length, (int index) {
              return new Tab(text: widget.soundList.keys.elementAt(index));
            }),
          ),
        ),
        body: TabBarView(
          children: List<Widget>.generate(widget.soundList.length, (int index) {
            var name = widget.soundList.keys.elementAt(index);
            var list = widget.soundList[name].toList();
            return new Container(
                width: 50,
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: GestureDetector(
                          child: Container(
                              constraints: BoxConstraints(minHeight: 80),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      Color(0xFF061539),
                                      Color(0xFF4F628E)
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(list[index].split('.mp3')[0],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ))
                                ],
                              )),
                          onTap: () {
                            audioCache.play('sounds/$name - ${list[index]}');
                          },
                        ));
                  },
                  itemCount: list.length,
                ));
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            audioPlayer.stop();
          },
          child: Text(
            "Stop",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Color(0xFF061539),
        ),
      ),
    ));
  }
}