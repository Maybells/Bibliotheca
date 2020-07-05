import 'package:bibliotheca/biblia_widget.dart';
import 'package:bibliotheca/placeholder_widget.dart';
import 'package:bibliotheca/viewer_widget.dart';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Bibliotheca'),
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
    PlaceholderWidget(Colors.blue),
    BibliaWidget(),
    PlaceholderWidget(Colors.amber),
  ];

  @override
  initState() {
    super.initState();
  }

  _clickTab(int index){
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: _clickTab,
        items: [
          BottomNavigationBarItem(
            title: const Text('Viewer'),
            icon: const Icon(Icons.pageview)
          ),
          BottomNavigationBarItem(
              title: const Text('Books'),
              icon: const Icon(Icons.library_books)
          ),
          BottomNavigationBarItem(
              title: const Text('Settings'),
              icon: const Icon(Icons.settings)
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: _children,
      )
    );
  }
}