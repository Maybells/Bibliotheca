import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

  @override
  initState() {
    super.initState();
    controller = new PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1,
    );
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  String _intToDigits(int num, int digits){
    String out = num.toString();
    while(out.length < digits){
      out = "0" + out;
    }
    return out;
  }

  String _getImageUrl(int page) {
    page++;
    String filename = _intToDigits(page, 3);
    String url = 'https://firebasestorage.googleapis.com/v0/b/bibliotheca-cd54e.appspot.com/o/Liddell-Scott%2F'+filename+'.png?alt=media';
    return url;
  }

  void _gotoPage(int page){
    page--;
    if(page < 0) page = 0;
    if(page >= pages) page = pages-1;
    print("Going to "+page.toString());
    controller.jumpToPage(page);
  }

  void _searchEntered(String search){
    final numericCommand = RegExp(r'^/[0-9]+$', unicode: true);
    if(numericCommand.hasMatch(search)){
      search = RegExp(r'[0-9]+').stringMatch(search);
      _gotoPage(int.parse(search));
    }
  }

  Widget _pageviewer(){
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: AdvancedNetworkImage(
              _getImageUrl(index),
              useDiskCache: true,
              cacheRule: CacheRule(maxAge: const Duration(days: 7)),
              timeoutDuration: Duration(minutes: 1)
          ),
          initialScale: 0.0,
          maxScale: PhotoViewComputedScale.contained * 2.0,
          minScale: PhotoViewComputedScale.contained * 1.0,
        );
      },
      itemCount: pages,
      loadingChild: Center(
        child: CircularProgressIndicator(),),
      backgroundDecoration: new BoxDecoration(color: Colors.white),
      pageController: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            maxLines: 1,
            onSubmitted: (text) {
              print(text);
              _searchEntered(text);
            },
            keyboardType: TextInputType.text,
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
}
/*
Expanded(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: _pageviewer(),
                ),
              )

 */