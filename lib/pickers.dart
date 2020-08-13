import 'package:Bibliotheca/files.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'biblia_widget.dart';
import 'metadata.dart';

androidPicker(
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
  switch (entries.length) {
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
    selectedItem: initialItem == null || initialIndex < 0
        ? null
        : entries.keys.toList().elementAt(initialIndex),
    onChanged: (value) => {current = entries[value]},
    onConfirmed: () => {
      if (current != null) {onPressed(current)}
    },
  );
}

iosPicker(
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0, color: CupertinoColors.activeBlue),
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
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? CupertinoColors.white
                : CupertinoColors.black,
//              color: CupertinoDynamicColor.withBrightness(color: Colors.white, darkColor: Colors.black),
            height: 200.0,
            child: picker,
          ));
}

showBookPicker(BuildContext context,
    {Function(String) onPressed, String initialItem}) {
  Metadata.getAll().then((List<BiblionMetadata> all) {
    all.sort((a, b) => a.shortname.compareTo(b.shortname));
    Map<String, String> books = {};
    int active = 0;
    for (BiblionMetadata biblion in all) {
      if (biblion.active) {
        active++;
        books[biblion.shortname] = biblion.id;
      }
    }

    if (active > 1) {
      PlatformProvider.of(context).platform == TargetPlatform.iOS
          ? iosPicker(
              context: context,
              entriesMap: books,
              initialItem: initialItem,
              onPressed: onPressed) //_bookPickerIOS(context, books)
          : androidPicker(
              context: context,
              title: 'Choose a Book',
              entriesMap: books,
              initialItem: initialItem,
              onPressed: onPressed);
    } else {
      noBooksWarning(context);
    }
  });
}

showPresetPicker(BuildContext context,
    {Function(String) onPressed, String initialItem}) {
  //Map presets = loadPresets();
  List<dynamic> presets = readValue('presets_list') ?? [];
  List<String> list = [];
  for (dynamic value in presets) {
    list.add(value.toString());
  }

  PlatformProvider.of(context).platform == TargetPlatform.iOS
      ? iosPicker(
          context: context,
          entriesList: list,
          initialItem: initialItem,
          onPressed: onPressed) //_bookPickerIOS(context, books)
      : androidPicker(
          context: context,
          title: 'Choose a Preset',
          initialItem: initialItem,
          entriesList: list,
          onPressed: onPressed);
}

showStringPicker(BuildContext context,
    {String title,
    List<String> list,
    String initialItem,
    Function(String) onPressed}) {
  PlatformProvider.of(context).platform == TargetPlatform.iOS
      ? iosPicker(
          context: context,
          entriesList: list,
          initialItem: initialItem,
          onPressed: onPressed,
        )
      : androidPicker(
          context: context,
          entriesList: list,
          initialItem: initialItem,
          title: title,
          onPressed: onPressed,
        );
}
