import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';

import 'files.dart';
import 'metadata.dart';

class ViewerWidget extends StatefulWidget {
  final Map<Language, List<String>> _history = _initializeHistory();
  String _biblionID = 'MiddleLiddell';

  @override
  _ViewerWidgetState createState() => _ViewerWidgetState();

  static Map<Language, List<String>> _initializeHistory() {
    Map<Language, List<String>> history = {};
    history[Language.English] = [];
    history[Language.Latin] = [];
    history[Language.Greek] = [];
    return history;
  }
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
  Language _biblionLang;
  String _preset;

  @override
  initState() {
    super.initState();
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
    return SafeArea(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 5.0),
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
                    onPressed: () => _showPresetPicker(context),
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
                    onPressed: () => _showBookPicker(context),
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
      ),
    );
  }

  void _search(String string) {
    setState(() {
      _searching = true;
    });
    _searchEntered(string);
  }

  Widget _searchBar(BuildContext context) {
    bool hasHistory = _getHistory() != null && _getHistory().isNotEmpty;
    
    Widget history = !hasHistory
        ? Container(
            width: 0.0,
            height: 0.0,
          )
        : Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: PlatformIconButton(
              iosIcon: Icon(CupertinoIcons.time, color: Colors.grey),
              materialIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.history, size: 24.0,),
                onSelected: (String value) {
                  _search(value);
                },
                itemBuilder: (BuildContext context) {
                  return _getHistory()
                      .map<PopupMenuItem<String>>((String value) {
                    return new PopupMenuItem(
                        child: new Text(value), value: value);
                  }).toList();
                },
              ),
              cupertino: (context, _) => CupertinoIconButtonData(
                onPressed: () {
                  _iosPicker(
                    context: context,
                    entriesList: _getHistory(),
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
          onChanged: (text) {
            if (!text.startsWith('/')) {
              String out = _biblionLang == Language.Greek
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
              suffixIcon: hasHistory ? Padding(padding: const EdgeInsets.only(right: 46.0),) : null,
            ),
          ),
          cupertino: (__, _) => CupertinoTextFieldData(
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: const Icon(Icons.search, color: Colors.grey),
              ),
              padding: hasHistory ? const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0, right: 46.0) : const EdgeInsets.all(8.0),
              //clearButtonMode: OverlayVisibilityMode.editing,
              placeholder: 'Search...'),
          keyboardType: TextInputType.text,
        ),
        history,
      ],
    );
  }

  void _loadBiblion(String name) async {
    _textController.clear();
    String contents = await FileLoader.loadJSON(name);
    setState(() {
      widget._biblionID = name;
      _biblion = new Biblion(name, contents);
      _pages = _biblion.numPages() + _biblion.abbr + 1;
      _biblionLang = _biblion.inLang;
      if(_controller == null) {
        _controller = new PageController(
          initialPage: _biblion.initialPage()-1,
          keepPage: true,
          viewportFraction: 1,
        );
      }
      if (_getHistory().isNotEmpty) {
        _searchFor(_getHistory().first, false);
      } else if (_controller.hasClients) {
        _gotoPage(_biblion.initialPage());
      }
    });
  }

  void _addSearchToHistory(String search) {
    int index = widget._history[_biblionLang].indexOf(search);
    if (index >= 0) {
      widget._history[_biblionLang].removeAt(index);
    }
    widget._history[_biblionLang].insert(0, search);
  }

  List<String> _getHistory() {
    return widget._history[_biblionLang];
  }

  String _getImageUrl(int page) {
    String url = _biblion.getUrl(page);
    return url;
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

  Widget _pageviewer() {
    List<double> filter =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? predefinedFilters['Identity'].toList()
            : predefinedFilters['Inverse'];

    if (_biblion != null && !_searching) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(filter),
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: AdvancedNetworkImage(_getImageUrl(index),
                  useDiskCache: true,
                  cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                  timeoutDuration: Duration(minutes: 1)),
              initialScale: 0.0,
              basePosition: MediaQuery.of(context).orientation == Orientation.portrait ? Alignment.center : Alignment.topCenter,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              minScale: MediaQuery.of(context).orientation == Orientation.portrait ? PhotoViewComputedScale.contained * 1.0 : PhotoViewComputedScale.covered * 0.75,
            );
          },
          itemCount: _pages,
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(),
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

  _androidPicker(
      {BuildContext context,
      List<String> entriesList,
      Map<String, String> entriesMap,
      String initialItem,
      Function(String) onPressed,
      String title}) {
    assert(context != null);
    assert(entriesList != null || entriesMap != null);
    assert(onPressed != null);
    assert(title != null);

    Map<String, String> entries;
    String current;
    int initialIndex;
    if (entriesMap != null) {
      entries = entriesMap;
    } else {
      entries = {};
      for (String entry in entriesList) entries[entry] = entry;
    }
    current = initialItem;
    initialIndex = entries.values.toList().indexOf(initialItem);

    int maxSide;
    switch(entries.length){
      case 1:
      case 2:
        maxSide = 280;
        break;
      case 3:
        maxSide = 300;
        break;
      default:
        maxSide = 400;
        break;
    }

    showMaterialRadioPicker(
      context: context,
      title: title,
      items: entries.keys.toList(),
      maxLongSide: maxSide * 1.0,
      selectedItem: initialItem == null
          ? null
          : entries.keys.toList().elementAt(initialIndex),
      onChanged: (value) => {current = entries[value]},
      onConfirmed: () => {
        if (current != null) {onPressed(current)}
      },
    );
  }

  _iosPicker(
      {BuildContext context,
      List<String> entriesList,
      Map<String, String> entriesMap,
      String initialItem,
      Function(String) onPressed}) {
    assert(context != null);
    assert(entriesList != null || entriesMap != null);
    assert(onPressed != null);

    Map<String, String> entries;
    String current;
    int initialIndex;
    if (entriesMap != null) {
      entries = entriesMap;
    } else {
      entries = {};
      for (String entry in entriesList) entries[entry] = entry;
    }
    if (initialItem == null) {
      initialItem = entries.values.toList().first;
      initialIndex = 0;
    } else {
      initialIndex = entries.values.toList().indexOf(initialItem);
    }
    current = initialItem;

    Widget picker = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          CupertinoButton(
            child: Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            onPressed: () {
              onPressed(current);
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController:
                  FixedExtentScrollController(initialItem: initialIndex),
              itemExtent: 46.0,
              children: <Widget>[
                for (String entry in entries.keys)
                  Text(
                    entry,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 36.0),
                  )
              ],
              onSelectedItemChanged: (item) {
                current = entries.values.elementAt(item);
              },
            ),
          ),
        ]);

    showCupertinoModalPopup(
        context: context,
        useRootNavigator: true,
        semanticsDismissible: true,
        builder: (_) => Container(
              color:
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? CupertinoColors.white
                      : CupertinoColors.black,
//              color: CupertinoDynamicColor.withBrightness(color: Colors.white, darkColor: Colors.black),
              height: 200.0,
              child: picker,
            ));
  }

  _showBookPicker(BuildContext context) {
    Metadata.getAll().then((List<BiblionMetadata> all) {
      all.sort((a, b) => a.shortname.compareTo(b.shortname));
      Map<String, String> books = {};
      for (BiblionMetadata biblion in all) {
        if (biblion.active) books[biblion.shortname] = biblion.id;
      }

      PlatformProvider.of(context).platform == TargetPlatform.iOS
          ? _iosPicker(
              context: context,
              entriesMap: books,
              initialItem: widget._biblionID,
              onPressed: _changeBook) //_bookPickerIOS(context, books)
          : _androidPicker(
              context: context,
              title: 'Choose a Book',
              entriesMap: books,
              initialItem: widget._biblionID,
              onPressed: _changeBook);
    });
  }

  Map<String, List<String>> _loadPresets() {
    Map<String, List<String>> presets = Map();
    presets['Greek'] = ['English-Greek', 'Gaza', 'MiddleLiddell'];
    //presets['Latin'] = ['CopCrit', 'Gradus'];
    //presets['Mix'] = ['Gaza', 'Gradus'];
    return presets;
  }

  _loadPreset(String preset) {
    _preset = preset;
    List<String> list = _loadPresets()[preset];

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

  _showPresetPicker(BuildContext context) {
    Map presets = _loadPresets();

    PlatformProvider.of(context).platform == TargetPlatform.iOS
        ? _iosPicker(
            context: context,
            entriesList: presets.keys.toList(),
            initialItem: _preset,
            onPressed: _loadPreset) //_bookPickerIOS(context, books)
        : _androidPicker(
            context: context,
            title: 'Choose a Preset',
            initialItem: _preset,
            entriesList: presets.keys.toList(),
            onPressed: _loadPreset);
  }
}
