import 'dart:convert';

import 'files.dart';

class _MetadataLoader {
  static Map<String, dynamic> _data = {};

  static Future<Map<String, dynamic>> get() async {
    if (_data == null || _data.isEmpty) {
      await _loadData();
    }
    return _data;
  }

  static _loadData() async {
    String input = await FileLoader.loadJSON("Metadata");
    print(input);
    _data = jsonDecode(input);
  }
}

class Metadata {
  Future<Map<String, String>> getTitles() async {
    Map<String, dynamic> data = await _MetadataLoader.get();
    Map<String, String> out = {};
    for (String id in data.keys) {
      out[_getName(data[id])] = id;
    }
    return out;
  }

  static String _getName(Map<String, dynamic> dict) {
    if (dict.containsKey("shortname")) {
      return dict["shortname"];
    } else {
      return dict["name"];
    }
  }
}

class BiblionMetadata {
  String name;
  String shortname;
  String author;
  String type;
  String pages;
  String size;
  String _inLang;
  String _outLang;

  Map<String, String> _data;

  BiblionMetadata(Map<String, String> data) {
    this._data = data;
    name = _read("name");
    shortname = data.containsKey("shortname") ? _read("shortname") : _read("name");
    author = _read("author");
    type = _read("type");
    pages = _read("pages");
    size = _read("size");
    _inLang = _read("inLang");
    _outLang = _read("outLang");
  }

  String _read(String key){
    if(_data.containsKey(key)){
      return _data[key];
    }
    return "n/a";
  }

  String get inLang{
    return _formatLang(_inLang);
  }

  String get outLang{
    return _formatLang(_outLang);
  }

  String _formatLang(String lang){
    switch(lang){
      case "Ancient Greek":
        return "Greek (Ancient)";
      case "Katharevousa":
        return "Greek (Katharevousa)";
      case "Modern Greek":
        return "Greek (Modern)";
      default:
        return lang;
    }
  }
}
