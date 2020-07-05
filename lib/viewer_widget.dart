import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'files.dart';
import 'metadata.dart';

class ViewerWidget extends StatefulWidget {
  final Map<Language, List<String>> _history = _initializeHistory();
  String _biblionID = 'MiddleLiddell';

  @override
  _ViewerWidgetState createState() => _ViewerWidgetState();

  static Map<Language, List<String>> _initializeHistory(){
    Map<Language, List<String>> history = {};
    history[Language.English] = [];
    history[Language.Latin] = [];
    history[Language.Greek] = [];
    return history;
  }
}

class _ViewerWidgetState extends State<ViewerWidget> {
  int _pages = 1;
  bool _searching = false;
  PageController _controller;
  TextEditingController _textController;
  Biblion _biblion;
  Language _biblionLang;

  @override
  initState() {
    super.initState();
    _controller = new PageController(
      initialPage: 0,
      keepPage: true,
      viewportFraction: 1,
    );
    _textController = new TextEditingController();
    _biblion = null;
    _loadBiblion(widget._biblionID);
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(bottom: 5.0),
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          child: Center(
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.library_books),
                  tooltip: 'Switch books',
                  iconSize: 28.0,
                  color: Colors.grey,
                  onPressed: () => _showBookPicker(context),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.bottom,
                      maxLines: 1,
                      minLines: 1,
                      style: TextStyle(fontSize: 18.0),
                      controller: _textController,
                      onSubmitted: (text) {
                        setState(() {
                          _searching = true;
                        });
                        _searchEntered(text);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search...',
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  iconSize: 28.0,
                  tooltip: 'Search history',
                  color: Colors.grey,
                  onPressed: () => _showSearchHistory(context),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: _pageviewer(),
          ),
        ),
      ],
    );
  }

  void _loadBiblion(String name) async {
    String contents = await FileLoader.loadJSON(name);
    setState(() {
      widget._biblionID = name;
      _biblion = new Biblion(name, contents);
      _pages = _biblion.numPages();
      _biblionLang = _biblion.inLang;
      if(_getHistory().isNotEmpty){
        _searchFor(_getHistory().first, false);
      }else if(_controller.hasClients) {
        _gotoPage(1);
      }
    });
  }

  void _addSearchToHistory(String search){
    widget._history[_biblionLang].insert(0, search);
  }
  List<String> _getHistory(){
    return widget._history[_biblionLang];
  }

  String _getImageUrl(int page) {
    page++;
    String url = _biblion.getUrl(page);
    return url;
  }

  void _gotoPage(int page) {
    page--;
    if (page < 0) page = 0;
    if (page >= _pages) page = _pages - 1;
    print("Going to " + page.toString());
    _controller.jumpToPage(page);
  }

  void _searchFor(String input, bool saveSearch) async {
    if (saveSearch) {
      _addSearchToHistory(input);
    }
    _gotoPage(await _biblion.search(input));
    setState(() {
      _searching = false;
    });
  }

  void _searchEntered(String search) async {
    if (_biblion != null) {
      _searchFor(search, true);
    }
    _textController.clear();
  }

  _changeBook(String to) {
    setState(() {
      _loadBiblion(to);
    });
  }

  Widget _pageviewer() {
    if (_biblion != null && !_searching) {
      return PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: AdvancedNetworkImage(_getImageUrl(index),
                useDiskCache: true,
                cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                timeoutDuration: Duration(minutes: 1)),
            initialScale: 0.0,
            maxScale: PhotoViewComputedScale.contained * 4.0,
            minScale: PhotoViewComputedScale.contained * 1.0,
          );
        },
        itemCount: _pages,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: new BoxDecoration(color: Colors.white),
        pageController: _controller,
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  _showBookPicker(BuildContext context) {
    Metadata.getTitles().then((Map<String, String> books) {
      SimpleDialog dialog = SimpleDialog(
        title: const Text('Choose a book'),
        children: [
          for (String book in books.keys)
            SimpleDialogOption(
                child: Text(
                  book,
                  style: new TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                onPressed: () {
                  _changeBook(books[book]);
                  Navigator.of(context).pop();
                })
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    });
  }

  _showSearchHistory(BuildContext context) {
    if (_getHistory().isNotEmpty) {
      String lang = _biblionLang.getString();
      SimpleDialog dialog = SimpleDialog(
        title: Text('Search History ($lang)'),
        children: <Widget>[
          Container(
            height: min(_getHistory().length * 32.0, 300),
            width: 300.0,
            child: ListView.builder(
                itemCount: _getHistory().length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    child: SimpleDialogOption(
                      child: Text(_getHistory().elementAt(index)),
                      onPressed: () {
                        _searchFor(_getHistory().elementAt(index), false);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }),
          ),
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    }
  }
}
