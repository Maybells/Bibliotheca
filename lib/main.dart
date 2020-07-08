import 'package:bibliotheca/biblia_widget.dart';
import 'package:bibliotheca/placeholder_widget.dart';
import 'package:bibliotheca/viewer_widget.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

final materialThemeData = ThemeData(
  // ???
  primarySwatch: Colors.blue,
  // Main area background color
  scaffoldBackgroundColor: Colors.white,
  // Switch color (and presumably other things too)
  accentColor: Colors.blue,
  // AppBar background color
  appBarTheme: AppBarTheme(color: Colors.blue),
  // BottomBar selected color
  primaryColor: Colors.blue,
  // ???
  secondaryHeaderColor: Colors.blue.shade300,
  // BottomBar background color
  canvasColor: Colors.white,
  // Should not be visible
  backgroundColor: Colors.red,
);
final cupertinoThemeData = CupertinoThemeData(
    primaryColor: Colors.blue,
    barBackgroundColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
);
Image logo = Image.asset(
  'lib/assets/images/BibliothecaLogo.png',
  fit: BoxFit.contain,
  height: 24.0,
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
      initialPlatform: TargetPlatform.iOS,
      builder: (context) => PlatformApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        material: (context, target) =>
            MaterialAppData(theme: materialThemeData),
        cupertino: (context, target) =>
            CupertinoAppData(theme: cupertinoThemeData),
        home: MyHomePage(title: 'Bibliotheca'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentTab = 0;
  final List<Widget> _children = [
//    ViewerWidget(),
    PlaceholderWidget(Colors.purple),
    BibliaWidget(),
    PlaceholderWidget(Colors.amber),
  ];

  @override
  initState() {
    super.initState();
  }

  _clickTab(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    precacheImage(logo.image, context);
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        child: PlatformScaffold(
            appBar: _appBar(context),
            bottomNavBar: PlatformNavBar(
              currentIndex: _currentTab,
              itemChanged: _clickTab,
              items: [
                BottomNavigationBarItem(
                    title: const Text('Viewer'), icon: const Icon(Icons.pageview)),
                BottomNavigationBarItem(
                    title: const Text('Books'),
                    icon: const Icon(Icons.library_books)),
                BottomNavigationBarItem(
                    title: const Text('Settings'),
                    icon: const Icon(Icons.settings)),
              ],
            ),
            body: IndexedStack(
              index: _currentTab,
              children: _children,
            )),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return PlatformAppBar(
        cupertino: (_, __) => CupertinoNavigationBarData(
              backgroundColor: Colors.blue,
            ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _changePlatform(context),
                child: logo,
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20.0, color: Colors.white),
            ),
          ],
        ));
  }

  _changePlatform(BuildContext context){
    PlatformProviderState provider = PlatformProvider.of(context);
    if(provider.platform == TargetPlatform.iOS){
      provider.changeToMaterialPlatform();
    }else{
      provider.changeToCupertinoPlatform();
    }
  }
}
