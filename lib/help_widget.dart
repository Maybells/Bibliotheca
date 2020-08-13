import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class HelpWidget extends StatelessWidget {
  static const List<String> items = [
    'How to Use App',
    'Report an Issue',
    'Search Commands',
    'Grammatical Terms in Greek',
    'What is Katharevousa?',
    'How to Read Katharevousa',
  ];

  static const List<String> files = [
    'tutorial',
    '',
    'search_commands',
    'greek_terms',
    'katharevousa_history',
    'katharevousa_tutorial',
  ];

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: CupertinoDynamicColor.withBrightness(
              color: Theme.of(context).primaryColor,
              darkColor: Color(0xF01D1D1D)),
          transitionBetweenRoutes: false,
          title: Text(
            'Help',
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
        material: (_, __) => MaterialAppBarData(
          title: Text('Help'),
        ),
      ),
      body: ListView.separated(
          itemBuilder: (context, index) => Material(
              color: Colors.transparent,
              child: ListTile(
                title: Text(items.elementAt(index)),
                onTap: () {
                  if (index == 1) {
                    launch('mailto:bibliotheca@bibliothecauraniae.com');
                  } else {
                    Navigator.push(
                        context,
                        platformPageRoute(
                            context: context,
                            builder: (context) => TextFileWidget(
                                  title: items.elementAt(index),
                                  filename: files.elementAt(index),
                                )));
                  }
                },
              )),
          separatorBuilder: (context, index) => Divider(),
          itemCount: items.length),
    );
  }
}

class TextFileWidget extends StatelessWidget {
  final String title;
  final String filename;

  TextFileWidget({this.title, this.filename});

  Future<String> loadAsset(BuildContext context, String name) async {
    return await DefaultAssetBundle.of(context).loadString('lib/assets/help/$name.txt');
  }

  MarkdownBody _parseText(String text){
    return MarkdownBody(
      data: text,
      onTapLink: (link) => launch(link),
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 22.0),
        listBullet: TextStyle(fontSize: 24.0),
        blockSpacing: 20.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: CupertinoDynamicColor.withBrightness(
              color: Theme.of(context).primaryColor,
              darkColor: Color(0xF01D1D1D)),
          transitionBetweenRoutes: false,
          title: Text(
            title,
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
        material: (_, __) => MaterialAppBarData(
          title: Text(title),
        ),
      ),
      body: FutureBuilder(
        future: loadAsset(context, filename),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _parseText(snapshot.data), //Text(snapshot.data, style: TextStyle(fontSize: 20.0),),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
