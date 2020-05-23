import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

enum Language{
  English,
  Latin,
  AncientGreek,
  Katharevousa
}

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return int.tryParse(s) != null;
}

class Biblion{
  String name;
  String id;
  Language inLang;
  Language outLang;
  Language inType;
  Map pages;

  Biblion(String input){
    pages = new Map();
    pages = jsonDecode(input);
    _loadMetadata();
  }

  void _loadMetadata(){
    id = pages["metadata"]["id"];
    String intype = pages["metadata"]["inType"];
    switch(intype){
      case "English":
        inType = Language.English;
        break;
      case "Greek":
        inType = Language.AncientGreek;
        break;
      default:
        inType = Language.English;
        break;
    }
  }

  String _intToDigits(int num){
    int digits = numPages().toString().length;
    String out = num.toString();
    while(out.length < digits){
      out = "0" + out;
    }
    return out;
  }

  int numPages(){
    return pages["pages"].length;
  }

  String _getPage(int page){
    return pages["pages"][page.toString()];
  }

  bool _hasOverride(String input){
    return pages["overrides"].containsKey(input);
  }

  String _getOverride(String input){
    return pages["overrides"][input];
  }

  bool _isCommand(String input){
    return input.startsWith('/');
  }

  int _doCommand(String input){
    String command = input.substring(1);
    if(command == 'r' || command == 'rand' || command == 'random'){
      return Random.secure().nextInt(numPages())+1;
    }else if(command == 'last' || command == 'l'){
      return numPages();
    }else if(command == 'first' || command == 'f'){
      return 1;
    } else if(isNumeric(command)){
      return int.parse(command);
    }else{
      return 1;
    }
  }

  String _toGreek(String input) {
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
          output = output + "σ";
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

  String _toEnglish(String input) {
    if(input.length != input.replaceAll(r'^[a-zA-Zα-ωΑ-Ω]', "").length) {
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

  String _convertString(String input){
    input = input.toLowerCase();
    input = input.replaceAll(r"[\p{InCombiningDiacriticalMarks}]", "");
    switch(inType){
      case Language.English:
        return _toEnglish(input);
        break;
      case Language.AncientGreek:
        return _toGreek(input);
        break;
      default:
        return input;
        break;
    }
  }

  _dictionarySearch(String input, [int lower = 1, int upper = -1]){
    if(upper == -1){
      upper = numPages();
    }
    if(lower >= upper){
      return lower + 1;
    }

    int mid = (upper + lower) ~/ 2;
    if(mid == lower){
      return mid + 1;
    }
    String current = _getPage(mid);
    if(input.compareTo(current) < 0){
      return _dictionarySearch(input, lower, mid);
    }else if(input.compareTo(current) > 0){
      return _dictionarySearch(input, mid, upper);
    }else{
      return mid;
    }
  }



  Future<int> search(String input) async{
    if(_hasOverride(input)){
      return search(_getOverride(input));
    }else if(_isCommand(input)){
      return _doCommand(input);
    }else{
      input = _convertString(input);
      return _dictionarySearch(input);
    }
  }

  String getUrl(int page){
    String filename =_intToDigits(page);
    return 'https://firebasestorage.googleapis.com/v0/b/bibliotheca-cd54e.appspot.com/o/$id%2F$filename.png?alt=media';
  }
}

class FileLoader {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _localFile(String name) async {
    final path = await _localPath;
    return File('$path/$name.json');
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

  Future<File> writeFile(String string) async {
    final file = await _localFile(string);

    // Write the file
    return file.writeAsString(string);
  }
}