import 'package:flutter/material.dart';
import 'package:nlapp/pages/feed/feed_page.dart';
import 'package:nlapp/pages/settings/setting_page.dart';
import 'package:nlapp/pages/soundboard/sound_page.dart';
import 'package:nlapp/pages/videos/video_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nlapp/firebase.dart';
import 'package:nlapp/provider_data_class.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  await GetStorage.init();
  GetStorage().writeIfNull('announcementSwitch', false);
  GetStorage().writeIfNull('twitchSwitch', true);
  GetStorage().writeIfNull('youtubeSwitch', true);
  WidgetsFlutterBinding.ensureInitialized();

  await firebaseInitialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ProviderData(),
          ),
        ],
        child: MaterialApp(
          title: 'newLEGACYinc',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: HomeScreen(),
        ));
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int page = 0;
  List<Color> _iconColor = [
    Colors.blue,
    Colors.white,
    Colors.white,
    Colors.white
  ];
  Future<List> _fetchVideos;
  Future<List> _fetchData;

  @override
  void initState() {
    _fetchVideos = fetchVideos();
    _fetchData = fetchData();
    listAssets();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchVideos = fetchVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).orientation == Orientation.landscape
          ? null
          : AppBar(
              elevation: 1,
              backgroundColor: Colors.grey[900],
              title: Container(
                height: 50,
                margin: const EdgeInsets.all(5.0),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/images/newlegacyinc_logo.png"),
                      fit: BoxFit.contain),
                ),
              ),
              centerTitle: true,
            ),
      body: listOfItems(),
      bottomNavigationBar: MediaQuery.of(context).orientation ==
              Orientation.landscape
          ? null
          : BottomAppBar(
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildBottomIconButton(Icons.home, _iconColor[0], 0, 'Feed'),
                  buildBottomIconButton(
                      Icons.personal_video, _iconColor[1], 1, 'Videos'),
                  buildBottomIconButton(
                      Icons.volume_up, _iconColor[2], 2, 'Soundboard'),
                  buildBottomIconButton(
                      Icons.settings, _iconColor[3], 3, 'Settings'),
                ],
              ),
            ),
    );
  }

  Widget buildBottomIconButton(
      IconData icon, Color color, int pageNo, String name) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Icon(
          icon,
          color: color,
        ),
        onPressed: () {
          if (Provider.of<ProviderData>(context, listen: false).page != pageNo)
            Provider.of<ProviderData>(context, listen: false)
                .changeVisbility(false);
          results = videos;
          setState(() {
            Provider.of<ProviderData>(context, listen: false)
                .changePage(pageNo);
          });
        },
      ),
      Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ))
    ]);
  }

  Widget listOfItems() {
    setState(() {
      for (var i = 0; i < _iconColor.length; i++) {
        if (i == Provider.of<ProviderData>(context).page) {
          _iconColor[i] = Colors.blue;
        } else {
          _iconColor[i] = Colors.white;
        }
      }
    });
    switch (Provider.of<ProviderData>(context).page) {
      case 0:
        return Container(
            color: Colors.grey[700],
            child: RefreshIndicator(
              child: FutureBuilder(
                  future: _fetchData,
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        return ListView.separated(
                          itemBuilder: (BuildContext context, int index) {
                            return feeds[index];
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(
                            height: 0,
                          ),
                          itemCount: feeds.length,
                        );
                      }
                    }
                    return Center(child: CircularProgressIndicator());
                  }),
              onRefresh: () async {
                setState(() {
                  _fetchData = fetchData();
                });
              },
            ));

        break;
      case 1:
        return Stack(children: [
          Visibility(
            child: Scaffold(
                appBar: AppBar(
                  titleSpacing: 0,
                  toolbarHeight: 50.0,
                  backgroundColor: Colors.grey[800],
                  leading: IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.filter,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return FilterDialog();
                          });
                    },
                  ),
                  title: TextField(
                    textInputAction: TextInputAction.search,
                    onChanged: (term) {
                      setState(() {
                        results = videos
                            .where((element) => element.title
                                .toLowerCase()
                                .contains(term.toLowerCase()))
                            .toList();
                        onTimeSelected(
                            Provider.of<ProviderData>(context, listen: false)
                                .selectedSort);
                      });
                    },
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        hintText: 'Search'),
                  ),
                ),
                body: RefreshIndicator(
                  child: videoList(_fetchVideos, results),
                  onRefresh: () async {
                    setState(() {
                      _fetchVideos = fetchVideos();
                    });
                  },
                )),
            visible: !Provider.of<ProviderData>(context).isVisible,
          ),
          Visibility(
            child: videoPlayer(context),
            visible: Provider.of<ProviderData>(context).isVisible,
          )
        ]);
        break;
      case 2:
        return Container(
          child: DefaultTabController(
            length: sounds.length,
            child: Scaffold(
                appBar: AppBar(
                  elevation: 1,
                  backgroundColor: Colors.grey[800],
                  title: new TabBar(
                      isScrollable: true,
                      tabs: List.generate(sounds.length, (int index) {
                        return new Tab(text: sounds.keys.elementAt(index));
                      })),
                ),
                body: TabBarView(
                    children: List.generate(sounds.length, (int index) {
                  var name = sounds.keys.elementAt(index);
                  var list = sounds[name].toList();
                  return new Container(
                      color: Colors.grey[700],
                      child: ListView.separated(
                        itemBuilder: (BuildContext context, int index) {
                          return list[index];
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            Divider(
                          height: 0,
                        ),
                        itemCount: list.length,
                      ));
                })),
                floatingActionButton: FloatingActionButton(
                    child: Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors.grey[800],
                    onPressed: () {
                      setState(() {
                        audioStop();
                      });
                    })),
          ),
        );
        break;
      case 3:
        return Container(
          color: Colors.grey[700],
          child: ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              return settings[index];
            },
            separatorBuilder: (BuildContext context, int index) => Divider(
              height: 0,
            ),
            itemCount: settings.length,
          ),
        );
        break;
      default:
        Provider.of<ProviderData>(context).changeVisbility(false);
        return Container(
          color: Colors.white,
          child: Text('Loading...'),
        );
        break;
    }
  }
}
