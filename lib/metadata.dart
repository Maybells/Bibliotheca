import 'dart:convert';

import 'files.dart';

class _MetadataLoader {
  static Map<String, BiblionMetadata> _data = {};

  static Future<Map<String, BiblionMetadata>> get() async {
    if (_data == null || _data.isEmpty) {
      String json = await _loadData();
      Map<String, dynamic> metadata = jsonDecode(json);
      for(String id in metadata.keys){
        _data[id] = new BiblionMetadata(id, metadata[id]);
      }
    }
    return _data;
  }

  static Future<String> _loadData() async {
    String input = await FileLoader.loadJSON("Metadata");
    return input;
  }
}

class Metadata {
  static Future<Map<String, String>> getTitles() async {
    Map<String, BiblionMetadata> data = await _MetadataLoader.get();
    Map<String, String> out = {};
    for (String id in data.keys) {
      if(data[id].active)
        out[data[id].shortname] = id;
    }
    return out;
  }

  static Future<List<BiblionMetadata>> getAll() async {
    Map data = await _MetadataLoader.get();
    return List.from(data.values);
  }
}

class BiblionMetadata {
  String id;
  String name;
  String shortname;
  String author;
  String type;
  int pages;
  String size;
  String _inLang;
  String _outLang;
  bool active;
  int abbr;
  bool hidden;

  dynamic _data;

  BiblionMetadata(this.id, dynamic data) {
    this._data = data;
    name = _read("name");
    shortname = data.containsKey("shortname") ? _read("shortname") : _read("name");
    author = _read("author");
    type = _read("type");
    pages = int.parse(_read("pages")??0);
    abbr = int.parse(_read("abbr")??0);
    size = _read("size");
    _inLang = _read("inLang");
    _outLang = _read("outLang");
    hidden = _read('hidden') == 'true' ? true : false;
    active = hidden ? false : readValue('${id}_active') == null ? true : readValue('${id}_active');
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
