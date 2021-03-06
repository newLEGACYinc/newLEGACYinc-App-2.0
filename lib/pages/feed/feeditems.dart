import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nlapp/flavor.dart';

class FeedItems extends StatefulWidget {
  final List<String> items = [
    'Twitch',
    'YouTube',
    'Twitter',
    'Instagram',
    'TikTok',
    'Discord'
  ];
  final Map<String, String> itemImage = {
    'Twitch': 'assets/images/twitch.png',
    'YouTube': 'assets/images/youtube.png',
    'Twitter': 'assets/images/twitter.png',
    'Instagram': 'assets/images/instagram.png',
    'TikTok': 'assets/images/tiktok.png',
    'Discord': 'assets/images/discord.png',
  };
  final Map<String, String> itemText = {
    'Twitch': 'Offline',
    'YouTube': 'Latest Video',
    'Twitter': 'Follow us and get the latest updates',
    'Instagram': 'Check out our photos',
    'TikTok': 'Watch some of our clips',
    'Discord': 'Join the community'
  };
  final Map<String, String> itemURL = {
    'Twitch': 'https://www.twitch.tv/newlegacyinc',
    'YouTube': 'https://www.youtube.com/newlegacyinc',
    'Twitter': 'https://www.twitter.com/newlegacyinc',
    'Instagram': 'https://www.instagram.com/newlegacygram',
    'TikTok': 'https://www.tiktok.com/@newlegacyinc',
    'Discord': 'https://www.discord.gg/newlegacyinc',
  };

  final data = GetStorage();

  @override
  _FeedItems createState() {
    data.writeIfNull('itemText', itemText);
    data.writeIfNull('itemURL', itemURL);
    return _FeedItems();
  }
}

class _FeedItems extends State<FeedItems> with WidgetsBindingObserver {
  FirebaseMessaging messaging;
  String notificationText;

  Future<String> fetchData() async {
    final flavor = await _getFlavorSettings();
    var response = await http.get(Uri.parse(flavor.apiBaseUrl));
    if (response.statusCode == 201) {
      if (mounted) {
        this.setState(() {
          widget.itemText['Twitch'] =
              jsonDecode(response.body)['stream_status'];
          widget.itemURL['YouTube'] = 'https:///www.youtube.com/watch?v=' +
              jsonDecode(response.body)['video_id'];
          widget.itemText['YouTube'] = jsonDecode(response.body)['video_title'];
          widget.data.write('itemText', widget.itemText);
          widget.data.write('itemURL', widget.itemURL);
        });
      }
      return 'Data loaded';
    } else {
      return 'Data not loaded';
    }
  }

  Future<FlavorSettings> _getFlavorSettings() async {
    String flavor =
        await const MethodChannel('flavor').invokeMethod<String>('getFlavor');

    if (flavor == 'dev') {
      return FlavorSettings.dev();
    } else if (flavor == 'prod') {
      return FlavorSettings.prod();
    } else {
      throw Exception("Unknown flavor: $flavor");
    }
  }

  @override
  void initState() {
    fetchData();
    WidgetsBinding.instance.addObserver(this);
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
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Ink(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[Color(0xFF061539), Color(0xFF4F628E)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: InkWell(
                    child: Container(
                        constraints: BoxConstraints(
                            minHeight: 80, minWidth: double.infinity),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 12, right: 12),
                              child: Image.asset(
                                widget.itemImage[widget.items[index]]
                                    .toString(),
                                width: 42,
                                height: 42,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: '${widget.items[index]}\n',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: widget.data
                                                .read('itemText')[
                                                    widget.items[index]]
                                                .toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )),
                    onTap: () async {
                      if (await canLaunch(widget.data
                          .read('itemURL')[widget.items[index]]
                          .toString()))
                        await launch(widget.data
                            .read('itemURL')[widget.items[index]]
                            .toString());
                      else
                        throw "Could not launch ${widget.data.read('itemURL')[widget.items[index]].toString()}";
                    },
                  )));
        },
        itemCount: widget.items.length,
      ),
      onRefresh: fetchData,
    );
  }
}
