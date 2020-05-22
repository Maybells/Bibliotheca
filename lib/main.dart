import 'files.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/services.dart' show rootBundle;

const String kTestString = 'Test of firebase storage';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  int pages = 910;
  bool _searching = false;
  String _currentBiblion;

  /*void _downloadFile() async{
    final StorageReference ref = FirebaseStorage.instance.ref().child('Firebase Test.txt');
    final String url = await ref.getDownloadURL();
    final http.Response downloadData = await http.get(url);
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/Firebase Test.txt');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    await tempFile.create();
    assert(await tempFile.readAsString() == "");
    final StorageFileDownloadTask task = ref.writeToFile(tempFile);
    final int byteCount = (await task.future).totalByteCount;
    final String tempFileContents = await tempFile.readAsString();
    assert(tempFileContents == kTestString);
    assert(byteCount == kTestString.length);

    final String fileContents = downloadData.body;
    setState(() {
      _downloaded = fileContents;
    });
  }*/

  PageController controller;
  TextEditingController textController;
  Biblion _biblion;

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
    _loadBiblion("Meletontas");
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  void _loadBiblion(String name) async {
    _currentBiblion = name;
//    FileLoader loader = new FileLoader();
//    String contents = await loader.readFile(name);
//    String contents = await rootBundle.loadString('assets/$name.json');
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

  void _searchFor(String input) async {
    _gotoPage(await _biblion.search(input));
    setState(() {
      _searching = false;
    });
  }

  void _searchEntered(String search) async {
    if (_biblion != null) {
      _searchFor(search);
    }
    textController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
//          IconButton(
//            icon: const Icon(Icons.list),
//            tooltip: 'Choose Book',
//            onPressed: (){
//              showDialog(
//                context: context,
//                barrierDismissible: true,
//                builder: (BuildContext context){
//                  return AlertDialog(
//                    title: Text('Choose Book'),
//                    content: SingleChildScrollView(
//                      child: ,
//                    ),
//                  );
//                }
//              );
//            },
//          ),
        ],
      ),
      body: Column(
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
                    onPressed: () => showBookPicker(context),
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

  changeBook(String to){
    setState(() {
      _currentBiblion = to;
      _loadBiblion(to);
    });
  }

  showBookPicker(BuildContext context){
    Widget optionOne = SimpleDialogOption(
      child: const Text('Liddell-Scott'),
      onPressed: () {
        print('Liddell-Scott');
        changeBook('Liddell-Scott');
        Navigator.of(context).pop();
      },
    );
    Widget optionTwo = SimpleDialogOption(
      child: const Text('Meletontas'),
      onPressed: () {
        print('Meletontas');
        changeBook('Meletontas');
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
}