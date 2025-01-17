import 'dart:ui';

import 'package:Bibliotheca/biblia_widget.dart';
import 'package:Bibliotheca/help_widget.dart';
import 'package:Bibliotheca/settings_widget.dart';
import 'package:Bibliotheca/viewer_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'dart:io' show Platform;

final materialThemeData = ThemeData(
  // ???
  primarySwatch: Colors.blue,
  // Main area background color
  scaffoldBackgroundColor: Colors.white,
  // Switch color (and presumably other things too)
  accentColor: Colors.blue,
  // AppBar background color
  appBarTheme: AppBarTheme(color: Colors.blue),
  //Color(0xff3F51B5)),
  // BottomBar selected color
  primaryColor: Colors.blue,
  // ???
  secondaryHeaderColor: Colors.blue.shade300,
  // BottomBar background color
  canvasColor: Colors.white,
  // Should not be visible
  backgroundColor: Colors.red,
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
  ),
  brightness: Brightness.light,
);

final materialDarkThemeData = ThemeData(
  brightness: Brightness.dark,
  accentColor: Colors.deepPurpleAccent[100],
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFFB388FF),
    textTheme: ButtonTextTheme.accent,
  ),
  toggleableActiveColor: Colors.deepPurpleAccent[100],
  dividerColor: Colors.white38,
  scaffoldBackgroundColor: Colors.black38,
  appBarTheme: AppBarTheme(color: Colors.black12),
  canvasColor: Colors.black54,
);

final cupertinoThemeData = CupertinoThemeData(
    primaryColor: CupertinoDynamicColor.withBrightness(
        color: CupertinoColors.black, darkColor: CupertinoColors.white),
    textTheme: const CupertinoTextThemeData(
        navActionTextStyle: const TextStyle(
          color: CupertinoColors.white,
        ),
//        navTitleTextStyle: const TextStyle(
//          color: CupertinoColors.white,
//          fontSize: 24.0,
//        ),
        textStyle: const TextStyle(
          color: CupertinoDynamicColor.withBrightness(
              color: CupertinoColors.black, darkColor: CupertinoColors.white),
        )));

Image logo = Image.asset(
  'lib/assets/images/BibliothecaLogo.png',
  fit: BoxFit.contain,
  height: 24.0,
);

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    return PlatformProvider(
      initialPlatform:
          Platform.isIOS ? TargetPlatform.iOS : TargetPlatform.android,
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            currentFocus.focusedChild.unfocus();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: PlatformApp(
          debugShowCheckedModeBanner: false,
          material: (context, target) => MaterialAppData(
              theme: materialThemeData, darkTheme: materialDarkThemeData),
          cupertino: (context, target) =>
              CupertinoAppData(theme: cupertinoThemeData),
          home: MyHomePage(title: 'Bibliotheca'),
        ),
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
    ViewerWidget(),
    BibliaWidget(),
    SettingsWidget(),
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
            cupertino: (__, _) => CupertinoTabBarData(
              activeColor: CupertinoColors.activeBlue,
            ),
            items: [
              BottomNavigationBarItem(
                  title: const Text('Viewer'),
                  icon: Icon(isMaterial(context)
                      ? Icons.find_in_page
                      : CupertinoIcons.bookmark_solid)),
              BottomNavigationBarItem(
                  title: const Text('Book Manager'),
                  icon: Icon(isMaterial(context)
                      ? Icons.library_books
                      : CupertinoIcons.collections_solid)),
              BottomNavigationBarItem(
                  title: const Text('Settings'),
                  icon: Icon(PlatformIcons(context).gearSolid)),
            ],
          ),
          body: IndexedStack(
            index: _currentTab,
            children: _children,
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return PlatformAppBar(
        cupertino: (_, __) => CupertinoNavigationBarData(
              backgroundColor: CupertinoDynamicColor.withBrightness(
                  color: Theme.of(context).primaryColor,
                  darkColor: Color(0xF01D1D1D)),
              transitionBetweenRoutes: false,
            ),
        trailingActions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 16.0),
//            child: PlatformIconButton(
//              icon: Icon(Icons.help_outline),
//              onPressed: () => Navigator.push(context, platformPageRoute(context: context, builder: (context) => HelpWidget())),
//            ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    platformPageRoute(
                        context: context, builder: (context) => HelpWidget())),
                child: Icon(
                  Icons.help_outline,
                  color: Colors.white,
                ),
              )),
        ],
        leading: Icon(
          Icons.help_outline,
          color: Colors.transparent,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Foundation.kDebugMode
                  ? GestureDetector(
                      onTap: () => _changePlatform(context),
                      child: logo,
                    )
                  : logo,
            ),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20.0, color: Colors.white),
            ),
          ],
        ));
  }

  _changePlatform(BuildContext context) {
    PlatformProviderState provider = PlatformProvider.of(context);
    if (provider.platform == TargetPlatform.iOS) {
      provider.changeToMaterialPlatform();
    } else {
      provider.changeToCupertinoPlatform();
    }
  }
}
