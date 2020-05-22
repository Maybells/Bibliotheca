import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'files.dart';

class ViewerWidget extends StatefulWidget{
  @override
  _MyViewerWidgetState createState() => _MyViewerWidgetState();
}

class _MyViewerWidgetState extends State<ViewerWidget>{
  int pages = 910;
  bool _searching = false;
  List<String> searches;
  PageController controller;
  TextEditingController textController;
  Biblion _biblion;
  String _currentBiblion;

  @override
  initState() {
    super.initState();
    controller = new PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1,
    );
    textController = new TextEditingController();
    _biblion = null;
    searches = new List();
    _loadBiblion("Meletontas");
  }

  @override
  dispose() {
    controller.dispose();
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
                      controller: textController,
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
    _currentBiblion = name;
    String contents = await DefaultAssetBundle.of(context)
        .loadString('lib/assets/$name.json');
    setState(() {
      _biblion = new Biblion(contents);
    });
  }

  String _getImageUrl(int page) {
    page++;
    String url = _biblion.getUrl(page);
    return url;
  }

  void _gotoPage(int page) {
    page--;
    if (page < 0) page = 0;
    if (page >= pages) page = pages - 1;
    print("Going to " + page.toString());
    controller.jumpToPage(page);
  }

  void _searchFor(String input, bool saveSearch) async {
    if(saveSearch) {
      searches.insert(0, input);
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
    textController.clear();
  }

  _changeBook(String to){
    setState(() {
      _currentBiblion = to;
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
            maxScale: PhotoViewComputedScale.contained * 2.0,
            minScale: PhotoViewComputedScale.contained * 1.0,
          );
        },
        itemCount: pages,
        loadingChild: Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: new BoxDecoration(color: Colors.white),
        pageController: controller,
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  _showBookPicker(BuildContext context){
    Widget optionOne = SimpleDialogOption(
      child: const Text('Liddell-Scott'),
      onPressed: () {
        _changeBook('Liddell-Scott');
        Navigator.of(context).pop();
      },
    );
    Widget optionTwo = SimpleDialogOption(
      child: const Text('Meletontas'),
      onPressed: () {
        _changeBook('Meletontas');
        Navigator.of(context).pop();
      },
    );

    SimpleDialog dialog = SimpleDialog(
      title: const Text('Choose a book'),
      children: <Widget>[
        optionOne,
        optionTwo,
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

  _showSearchHistory(BuildContext context) {
    if (searches.isNotEmpty) {
      SimpleDialog dialog = SimpleDialog(
        title: const Text('Search History'),
        children: <Widget>[
          Container(
            height: min(searches.length * 50.0, 300),
            width: 300.0,
            child: ListView.builder(
                itemCount: searches.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    child: SimpleDialogOption(
                      child: Text(searches.elementAt(index)),
                      onPressed: () {
                        _searchFor(searches.elementAt(index), false);
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