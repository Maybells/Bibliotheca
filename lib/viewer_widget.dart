import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'pickers.dart';
import 'biblia_widget.dart';
import 'files.dart';
import 'metadata.dart';

class ViewerWidget extends StatefulWidget {
  String _biblionID = 'MiddleLiddell';

  @override
  _ViewerWidgetState createState() => _ViewerWidgetState();
}

//Taken from https://www.burkharts.net/apps/blog/over-the-rainbow-colour-filters/
const Map<String, List<double>> predefinedFilters = {
  'Identity': [
    //R  G   B    A  Const
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ],
  'Inverse': [
    //R  G   B    A  Const
    -0.8, 0, 0, 0, 204, //
    0, -0.8, 0, 0, 204, //
    0, 0, -0.8, 0, 204, //
    0, 0, 0, 1, 0, //
  ],
};

class _ViewerWidgetState extends State<ViewerWidget> {
  int _pages = 1;
  bool _searching = false;
  PageController _controller;
  TextEditingController _textController;
  Biblion _biblion;
  String _biblionLang;
  String _directory;

  @override
  initState() {
    super.initState();

    _initializeDirectory();
    _listenEachBook();

    _textController = new TextEditingController();
    _biblion = null;

    final persist = GetStorage();

    String current = readValue('current_book');
    current == null ? _loadBiblion(widget._biblionID) : _loadBiblion(current);
  }

  _initializeDirectory() async {
    _directory = (await getApplicationDocumentsDirectory()).path;
  }

  _listenEachBook() async {
    List<BiblionMetadata> metadata = await Metadata.getAll();
    for(BiblionMetadata meta in metadata){
      listenValue('${meta.id}_active', (value) => _handleActiveChanged(meta.id, value));
    }
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          readValue('search_on_top')??true ? _topBar(context, true) : Container(),

          _viewer(context),

          readValue('search_on_top')??true ? Container() : _topBar(context, false),
        ],
      ),
    );
  }

  Widget _viewer(BuildContext context){
    return Expanded(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: _pageViewer(),
      ),
    );
  }

  Widget _topBar(BuildContext context, bool top){
    return Container(
      margin: top ? EdgeInsets.only(bottom: 5.0, top: 5.0) : EdgeInsets.only(bottom: 20.0, top: 5.0),
      padding: EdgeInsets.symmetric(horizontal: 5.0),
      child: Center(
        child: Row(
          children: <Widget>[
            PlatformIconButton(
              materialIcon: Icon(Icons.collections_bookmark),
              material: (__, _) => MaterialIconButtonData(
                tooltip: 'Switch presets',
                iconSize: 28.0,
                color: Colors.grey,
                enableFeedback: false,
              ),
              iosIcon: Icon(
                MediaQuery.of(context).platformBrightness ==
                    Brightness.light
                    ? CupertinoIcons.folder
                    : CupertinoIcons.folder_solid,
                size: 28.0,
                color: Colors.grey,
              ),
              cupertino: (__, _) => CupertinoIconButtonData(),
              onPressed: () => (readValue('presets_list')??[]).isEmpty
                  ? noPresetsWarning(context)
                  : showPresetPicker(context,
                  initialItem: currentPreset, onPressed: _loadPreset),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: _searchBar(context),
              ),
            ),
            PlatformIconButton(
              materialIcon: Icon(Icons.import_contacts),
              material: (__, _) => MaterialIconButtonData(
                tooltip: 'Switch books',
                iconSize: 28.0,
                color: Colors.grey,
              ),
              iosIcon: Icon(
                MediaQuery.of(context).platformBrightness ==
                    Brightness.light
                    ? CupertinoIcons.book
                    : CupertinoIcons.book_solid,
                size: 28.0,
                color: Colors.grey,
              ),
              cupertino: (__, _) => CupertinoIconButtonData(),
              onPressed: () => showBookPicker(context,
                  initialItem: widget._biblionID, onPressed: _changeBook),
            ),
          ],
        ),
      ),
    );
  }

  void _search(String string) {
    _lastSeen = _biblion.id;
    setState(() {
      _searching = true;
    });
    _searchEntered(string);
  }

  Widget _searchBar(BuildContext context) {
    bool hasHistory = _getHistory() != null && _getHistory().isNotEmpty;

    Widget history = !hasHistory || !_hasActive
        ? Container(
            width: 0.0,
            height: 0.0,
          )
        : Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: PlatformIconButton(
              iosIcon: Icon(CupertinoIcons.time, color: Colors.grey),
              materialIcon: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.history,
                  size: 24.0,
                ),
                onSelected: (String value) {
                  _search(value);
                },
                itemBuilder: (BuildContext context) {
                  return _getHistory()
                      .map<PopupMenuItem<String>>((dynamic value) {
                    return new PopupMenuItem(
                        child: new Text(value), value: value);
                  }).toList();
                },
              ),
              cupertino: (context, _) => CupertinoIconButtonData(
                onPressed: () {
                  iosPicker(
                    context: context,
                    entriesList: _getHistory().map((e) => e as String).toList(),
                    onPressed: _search,
                  );
                },
              ),
            ),
          );

    return Stack(
      alignment: Alignment.centerRight,
      children: <Widget>[
        PlatformTextField(
          textAlignVertical: TextAlignVertical.bottom,
          maxLines: 1,
          minLines: 1,
          style: TextStyle(fontSize: 18.0),
          controller: _textController,
          enabled: _hasActive,
          onChanged: (text) {
            if (!text.startsWith('/')) {
              String out = _biblionLang == Language.Greek.toString()
                  ? Biblion.toGreek(text)
                  : Biblion.toEnglish(text);

              _textController.value = _textController.value.copyWith(
                text: out,
              );
            }
          },
          textInputAction: TextInputAction.search,
          onSubmitted: (text) {
            _search(text);
          },
          material: (__, _) => MaterialTextFieldData(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search...',
              suffixIcon: hasHistory
                  ? Padding(
                      padding: const EdgeInsets.only(right: 46.0),
                    )
                  : null,
            ),
          ),
          cupertino: (__, _) => CupertinoTextFieldData(
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: const Icon(Icons.search, color: Colors.grey),
              ),
              padding: hasHistory
                  ? const EdgeInsets.only(
                      left: 8.0, top: 8.0, bottom: 8.0, right: 46.0)
                  : const EdgeInsets.all(8.0),
              //clearButtonMode: OverlayVisibilityMode.editing,
              placeholder: 'Search...'),
          keyboardType: TextInputType.text,
        ),
        history,
      ],
    );
  }

  _handleActiveChanged(String id, dynamic value) {
//    if (_biblion == null || !mounted) {
//      return;
//    }
    if (readValue('${_lastSeen}_active') ?? true) {
      // If lastSeen is active but not visible, load it
      setState(() {
        _hasActive = true;
        if (_lastSeen != _biblion?.id) {
          _load(_lastSeen);
        }
      });
    } else if (!(readValue('${_biblion.id}_active') ?? true)) {
      // If lastSeen is not active and current is not active, load the earliest active
      Metadata.getAll().then((List<BiblionMetadata> all) {
        all.sort((a, b) => a.shortname.compareTo(b.shortname));
        for (BiblionMetadata biblion in all) {
          if (biblion.active) {
            setState(() {
              _hasActive = true;
              _load(biblion.id);
            });
            return;
          }
        }
        // If none are active, show a 'none active' page
        setState(() {
          _hasActive = false;
        });
      });
    } else {
      // Do nothing
      setState(() {
        _hasActive = true;
      });
    }
  }

  bool _hasActive = true;

  String _lastSeen;

  void _loadBiblion(String name) {
    _lastSeen = name;
    _load(name);
  }

  void _load(String name) async {
    _textController.clear();
    String contents = await FileLoader.loadJSON(name);

    setState(() {
      widget._biblionID = name;
      _biblion = new Biblion(name, contents);
      _pages = _biblion.numPages() + _biblion.abbr + 1;
      _biblionLang = _biblion.inLang.toString();

      persistValue('current_book', name);
//      if(name != _currentBiblion) {
//        stopListen(_currentBiblionActive);
//      }

      if (_controller == null) {
        _controller = new PageController(
          initialPage: readValue('current_page') == null
              ? _biblion.initialPage() - 1
              : readValue('current_page'),
          keepPage: true,
          viewportFraction: 1,
        );
      }
      if (_controller.hasClients) {
        if (_getHistory() != null && _getHistory().isNotEmpty) {
          _searchFor(_getHistory().first, false);
        } else {
          _gotoPage(_biblion.initialPage());
        }
      }
    });
  }

  Map<String, dynamic> get _history {
    Map<String, dynamic> history = readValue('history');
    if (history == null) {
      history = {};
      history[Language.English.toString()] = [];
      history[Language.Latin.toString()] = [];
      history[Language.Greek.toString()] = [];
    }
    persistValue('history', history);
    return history;
  }

  int get _historyLimit {
    int limit = readValue('history_limit');
    if (limit == null) {
      limit = 10;
      persistValue('history_limit', limit);
    }
    return limit;
  }

  void _addSearchToHistory(String search) {
    Map<String, dynamic> history = _history;
    int index = history[_biblionLang].indexOf(search);
    if (index >= 0) {
      history[_biblionLang].removeAt(index);
    }
    history[_biblionLang].insert(0, search);
    while (history[_biblionLang].length > _historyLimit) {
      history[_biblionLang].removeLast();
    }
    persistValue('history', history);
    persistValue('history_changed', true);
  }

  List<dynamic> _getHistory() {
    return _history[_biblionLang];
  }

  String _getImageUrl(int page) {
    String url = _biblion.getUrl(page);
    return url;
  }
  
  String _getImageFile(int page){
    return _biblion.getFile(page);
  }

  void _gotoPage(int page) {
    page--;
    if (page < 0) page = 0;
    if (page >= _pages) page = _pages - 1;
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

  _onPageChanged(int page) {
    persistValue('current_page', page);
  }

  ImageProvider _pageSource(int index){
    File page = File('$_directory/${_getImageFile(index)}');
    if(page.existsSync()){
      return FileImage(page);
    }else{
//      return AdvancedNetworkImage(_getImageUrl(index),
//          useDiskCache: true,
//          cacheRule: CacheRule(maxAge: const Duration(days: 7)),
//          timeoutDuration: Duration(minutes: 1));
      return CachedNetworkImageProvider(
          _getImageUrl(index),
      );
    }
  }

  Widget _pageViewer() {
    List<double> filter =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? predefinedFilters['Identity'].toList()
            : predefinedFilters['Inverse'];

    if (!_hasActive) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'No books are currently selected. You can turn them on the in the Book Manager tab',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20.0),
        ),
      ));
    }
    if (_biblion != null && !_searching) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(filter),
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: _pageSource(index),
              //FileImage(File('$_directory/title.png')),
              initialScale: 0.0,
              basePosition:
                  MediaQuery.of(context).orientation == Orientation.portrait
                      ? Alignment.center
                      : Alignment.topCenter,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              minScale:
                  MediaQuery.of(context).orientation == Orientation.portrait
                      ? PhotoViewComputedScale.contained * 1.0
                      : PhotoViewComputedScale.covered * 0.75,
            );
          },
          itemCount: _pages,
          onPageChanged: _onPageChanged,
          loadingBuilder: (context, event) => Center(
            //TODO: Fix iOS progress not showing in dark mode
            child: PlatformCircularProgressIndicator(
              cupertino: (__, _) => CupertinoProgressIndicatorData(
                radius: 24.0,
              ),
            ),
          ),
          backgroundDecoration: new BoxDecoration(color: Colors.white),
          pageController: _controller,
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  _loadPreset(String preset) {
    persistValue('current_preset', preset);
    List<dynamic> list = loadPresets()[preset];

    Metadata.getAll().then((List<BiblionMetadata> all) {
      bool reload = false;
      for (BiblionMetadata biblion in all) {
        biblion.active = list.contains(biblion.id);
        if (biblion.id == widget._biblionID && !biblion.active) {
          reload = true;
        }
      }
      if (reload) {
        _loadBiblion(list.first);
      }
    });
  }
}
