import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum Language{
  English,
  Latin,
  AncientGreek,
  Katharevousa
}

class Biblion{
  String name;
  Language inLang;
  Language outLang;
  var pages;

  Biblion(String input){
    pages = new Map();
    print(input);
  }
}

class FileLoader{
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _localFile(String name) async {
    final path = await _localPath;
    return File('$path/$name.txt');
  }

  Future<String> readFile(String name) async {
    try {
      final file = await _localFile(name);

      // Read the file
      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return null;
    }
  }
}