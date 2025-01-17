import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_storage/get_storage.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;
import 'package:http/http.dart' as http;

import 'metadata.dart';

enum Language { English, Latin, Greek }

String getLangString(Language lang) {
  return lang.toString().split('.').last;
}

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return int.tryParse(s) != null;
}

persistValue(String key, dynamic value){
  final persist = GetStorage();
  persist.write(key, value);
}

dynamic readValue(String key){
  final persist = GetStorage();
  return persist.read(key);
}

listen(Function onChanged){
  final persist = GetStorage();
  persist.listen(onChanged);
}
listenValue(String key, Function(dynamic) onChanged){
  final persist = GetStorage();
  persist.listenKey(key, (value) => onChanged(value));
}

String get currentPreset{
  return readValue('current_preset');
}

class Biblion {
  String name;
  String id;
  Language inLang;
  Language inType;
  Map pages;
  bool vu;
  bool ji;
  int abbr;

  Biblion(String id, String input) {
    this.id = id;
    pages = new Map();
    pages = jsonDecode(input);
    _loadMetadata();
  }

  void _loadMetadata() {
    String intype = pages["metadata"]["inLang"];
    switch (intype) {
      case "English":
        inLang = Language.English;
        inType = Language.Latin;
        break;
      case "Latin":
        inLang = Language.Latin;
        inType = Language.Latin;
        break;
      default:
        inLang = Language.Greek;
        inType = Language.Greek;
        break;
    }

    vu = pages['metadata']['vu'] == 'true';
    ji = pages['metadata']['ji'] == 'true';
    abbr = int.parse(pages['metadata']['abbr']);
  }

  int numPages() {
    return pages["pages"].length;
  }

  String _getPage(int page) {
    return pages["pages"][page.toString()];
  }

  bool _hasOverride(String input) {
    return pages["overrides"].containsKey(input);
  }

  String _getOverride(String input) {
    return pages["overrides"][input];
  }

  bool _isCommand(String input) {
    return input.startsWith('/');
  }

  int _doCommand(String input) {
    String command = input.substring(1);
    if (command == 'r' || command == 'rand' || command == 'random') {
      return Random.secure().nextInt(numPages()) + 1 + abbr;
    } else if (command == 'last' || command == 'l') {
      return numPages() + abbr + 1;
    } else if (command == 'first' || command == 'f') {
      return abbr + 2;
    } else if (command == 'abbr') {
      if(abbr > 0){
        return 2;
      }else{
        return 1;
      }
    } else if (command == 'title' || command == 't') {
      return 1;
    } else if(command == 'extras' || command == 'e'){
      return -1;
    } else if (isNumeric(command)) {
      return int.parse(command) + abbr + 1;
    } else {
      return 1;
    }
  }

  static String toGreek(String input) {
    input = input.toLowerCase();
    String output = "";
    for (int i = 0; i < input.length; i++) {
      switch (input[i]) {
        case 'a':
          output = output + "α";
          break;
        case 'b':
          output = output + "β";
          break;
        case 'g':
          output = output + "γ";
          break;
        case 'd':
          output = output + "δ";
          break;
        case 'e':
          output = output + "ε";
          break;
        case 'z':
          output = output + "ζ";
          break;
        case 'h':
          output = output + "η";
          break;
        case 'q':
          output = output + "θ";
          break;
        case 'i':
          output = output + "ι";
          break;
        case 'k':
          output = output + "κ";
          break;
        case 'l':
          output = output + "λ";
          break;
        case 'm':
          output = output + "μ";
          break;
        case 'n':
          output = output + "ν";
          break;
        case 'c':
          output = output + "ξ";
          break;
        case 'o':
          output = output + "ο";
          break;
        case 'p':
          output = output + "π";
          break;
        case 'r':
          output = output + "ρ";
          break;
        case 's':
        case 'σ':
        case 'ς':
          if(i > 0 && i == input.length-1){
            output = output + "ς";
          }else{
            output = output + "σ";
          }
          break;
        case 't':
          output = output + "τ";
          break;
        case 'u':
          output = output + "υ";
          break;
        case 'f':
          output = output + "φ";
          break;
        case 'x':
          output = output + "χ";
          break;
        case 'y':
          output = output + "ψ";
          break;
        case 'w':
          output = output + "ω";
          break;
        default:
          output += input[i];
          break;
      }
    }
    return output;
  }

  static String toEnglish(String input) {
    input = input.toLowerCase();
    if (input.length != input.replaceAll(r'^[a-zA-Zα-ωΑ-Ω]', "").length) {
      input = unorm.nfd(input);
    }
    String output = "";
    for (int i = 0; i < input.length; i++) {
      switch (input[i]) {
        case 'α':
          output = output + "a";
          break;
        case 'β':
          output = output + "b";
          break;
        case 'γ':
          output = output + "g";
          break;
        case 'δ':
          output = output + "d";
          break;
        case 'ε':
          output = output + "e";
          break;
        case 'ζ':
          output = output + "z";
          break;
        case 'η':
          output = output + "h";
          break;
        case 'θ':
          output = output + "q";
          break;
        case 'ι':
          output = output + "i";
          break;
        case 'κ':
          output = output + "k";
          break;
        case 'λ':
          output = output + "l";
          break;
        case 'μ':
          output = output + "m";
          break;
        case 'ν':
          output = output + "n";
          break;
        case 'ξ':
          output = output + "c";
          break;
        case 'ο':
          output = output + "o";
          break;
        case 'π':
          output = output + "p";
          break;
        case 'ρ':
          output = output + "r";
          break;
        case 'σ':
          output = output + "s";
          break;
        case 'ς':
          output = output + "s";
          break;
        case 'τ':
          output = output + "t";
          break;
        case 'υ':
          output = output + "u";
          break;
        case 'φ':
          output = output + "f";
          break;
        case 'χ':
          output = output + "x";
          break;
        case 'ψ':
          output = output + "y";
          break;
        case 'ω':
          output = output + "w";
          break;
        default:
          output += input[i];
          break;
      }
    }
    return output;
  }

  String _convertString(String input) {
    input = input.toLowerCase();
    input = input.replaceAll(r"[\p{InCombiningDiacriticalMarks}]", "");
    switch (inType) {
      case Language.English:
        input = toEnglish(input);
        break;
      case Language.Greek:
        input = toGreek(input);
        break;
      default:
        break;
    }

    if (vu) {
      input = input.replaceAll('v', 'u');
    }
    if (ji) {
      input = input.replaceAll('j', 'i');
    }

    return input;
  }

  _dictionarySearch(String input, [int lower = 1, int upper = -1]) {
    if (upper == -1) {
      upper = numPages();
    }
    if (lower >= upper) {
      return lower + 1;
    }

    int mid = (upper + lower) ~/ 2;
    String current = _getPage(mid);
    if (mid == lower) {
      if(input.compareTo(current) <= 0){
        return mid;
      }else{
        return mid + 1;
      }
    }
    if (input.compareTo(current) < 0) {
      return _dictionarySearch(input, lower, mid);
    } else if (input.compareTo(current) > 0) {
      return _dictionarySearch(input, mid, upper);
    } else {
      return mid;
    }
  }

  int _earliestPage(int page){
    String content = _getPage(page);
    if(page == 1 || content != _getPage(page-1)){
      return page;
    }else{
      return _earliestPage(page-1);
    }
  }

  Future<int> search(String input) async {
    if (_hasOverride(input)) {
      return search(_getOverride(input));
    } else if (_isCommand(input)) {
      return _doCommand(input);
    } else {
      input = _convertString(input);
      return _earliestPage(_dictionarySearch(input)) + abbr + 1;
    }
  }

  int initialPage() {
    return abbr+2;
  }

  String getUrl(int page) {
    return 'http://assets.bibliothecauraniae.com/${getFile(page)}?i=1';
  }

  String getFile(int page){
    if (page == 0) {
      // The title page
      return '$id/title.png';
    } else if (page <= abbr) {
      // Pages containing the abbreviations used in the book
      return '$id/abbr_$page.png';
    } else {
      // All other pages
      page = page - abbr;
      String filename = intToDigits(page, numPages());
      return '$id/$filename.png';
    }
  }
}

class FileLoader {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  static Future<File> _localFile(String name) async {
    final path = await _localPath;
    return File('$path/$name.json');
  }

  static Future<String> readFile(String name) async {
    try {
      final file = await _localFile(name);

      // Read the file
      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      print(e);
      return null;
    }
  }

  static Future<File> writeFile(String string) async {
    final file = await _localFile(string);

    // Write the file
    return file.writeAsString(string);
  }

  static Future<String> loadJSON(String name) async {
    return await rootBundle.loadString('lib/assets/$name.json');
  }
}

Future<File> saveImage(String directory, String name, String url)async{
  http.Client client = new http.Client();
  var req = await client.get(Uri.parse(url));
  var bytes = req.bodyBytes;
  File file = File(
    '$directory/$name'
  );
  //file.createSync();
  await file.writeAsBytes(bytes);
  return file;
}

String intToDigits(int num, int max) {
  int digits = max.toString().length;
  String out = num.toString();
  while (out.length < digits) {
    out = "0" + out;
  }
  return out;
}