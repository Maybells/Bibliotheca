import 'dart:ui';

import 'package:bibliotheca/assets/pickers.dart';
import 'package:bibliotheca/metadata.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'files.dart';
import 'myexpansiontile_widget.dart';

class BibliaWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BibliaWidgetState();
}

class _BibliaWidgetState extends State<BibliaWidget>
    with SingleTickerProviderStateMixin {
  List<BiblionMetadata> _metadata;
  bool _allToggle = true;
  bool _downloadOverMobile = false;

  @override
  initState() {
    super.initState();

    if (_metadata == null) {
      Metadata.getAll().then((List<BiblionMetadata> data) {
        data.sort((a, b) => a.shortname.compareTo(b.shortname));
        setState(() {
          _metadata = data;
        });
      });
    }
  }

  void _onChanged(bool newValue, BiblionMetadata meta) {
    setState(() {
      meta.active = newValue;
      persistValue('${meta.id}_active', newValue);
    });
  }

  MyExpansionTile _expansionTile(
      BuildContext context, BiblionMetadata meta) {
    return MyExpansionTile(
      title: Text(
        meta.shortname,
        style: (PlatformProvider.of(context).platform == TargetPlatform.iOS
            ? CupertinoTheme.of(context).textTheme.textStyle
            : Theme.of(context).textTheme.subtitle1).copyWith(fontFeatures: [FontFeature.enable('smcp')]),
      ),
      children: <Widget>[_displayMeta(context, meta)],
      titleChevron: true,
      trailing: Switch.adaptive(
        value: meta.active,
        onChanged: (bool newValue) {
          persistValue('current_preset', null);
          this._onChanged(newValue, meta);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_metadata != null) {
      return ListView(
        children: <Widget>[
          ButtonBar(
            children: <Widget>[
              PlatformButton(
                child: Text('Save to Preset'),
                onPressed: () {
                  _savePresetPopup(context);
                },
              ),
              PlatformButton(
                child: _allToggle ? Text('All Off') : Text('All On'),
                onPressed: () => {
                  setState(() => {
                        _allToggle = !_allToggle,
                        _metadata.forEach((meta) {
                          meta.active = _allToggle;
                          persistValue('${meta.id}_active', _allToggle);
                        })
                      })
                },
              ),
              PlatformButton(
                child: Text('Presets'),
                onPressed: (){
                  loadPresets() == null ? noPresetsWarning(context) : _showPresetPicker();
                },
              )
            ],
          ),
          for (BiblionMetadata meta in _metadata)
            _expansionTile(context, meta)
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _displayVariable(String title, String variable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
            style: (PlatformProvider.of(context).platform == TargetPlatform.iOS
                ? CupertinoTheme.of(context).textTheme.textStyle
                : Theme.of(context).textTheme.subtitle1).copyWith(fontSize: 16.0),
            children: <TextSpan>[
              TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: variable),
            ]),
      ),
    );
  }

  Widget _downloadButton(BuildContext context, BiblionMetadata meta){
    String text = 'Download (${meta.size})';
    Function pressed = () => {_constructDownloadWarning(context, meta)};

    return PlatformButton(
      child: Text(text),
      onPressed: pressed,
      cupertino: (__, _) => CupertinoButtonData(),
      material: (context, _) => MaterialRaisedButtonData(textColor: Theme.of(context).accentTextTheme.headline6.color),
    );
  }

  Widget _displayMeta(BuildContext context, BiblionMetadata meta) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(
            top: 6.0, bottom: 8.0, left: 16.0, right: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _displayVariable('Full Name', meta.name),
            _displayVariable('Author', meta.author),
            _displayVariable('Type', meta.type),
            _displayVariable('Pages', meta.pages),
            _displayVariable('Headword Language', meta.inLang),
            _displayVariable('Definition Language', meta.outLang),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
              child: Center(
                child: _downloadButton(context, meta),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _constructDownloadWarning(
      BuildContext context, BiblionMetadata meta) async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    String title;
    Widget content;
    List<Widget> actions;
    if (connectivityResult == ConnectivityResult.wifi ||
        (connectivityResult == ConnectivityResult.mobile &&
            _downloadOverMobile)) {
      return;
    } else if (connectivityResult == ConnectivityResult.mobile) {
      bool checked = false;
      title = 'Download over Cellular?';
      content = StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  'You are about to download a ${meta.size} file over a cellular connection.'),
              Row(
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: Checkbox(
                      value: checked,
                      onChanged: (value) {
                        setState(() {
                          checked = value;
                        });
                      },
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        print(checked);
                        setState(() {
                          checked = !checked;
                        });
                      },
                      child: Text(
                        'Don\'t ask again',
                      ))
                ],
              )
            ],
          );
        },
      );
      actions = <Widget>[
        PlatformDialogAction(
          child: PlatformText('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        PlatformDialogAction(
          child: PlatformText('Download'),
          onPressed: () {
            if (checked) _downloadOverMobile = true;
            Navigator.pop(context);
          },
        ),
      ];
    } else if (connectivityResult == ConnectivityResult.none) {
      title = 'Device Offline';
      content =
          Text('You must be connected to the internet to download books.');
      actions = <Widget>[
        PlatformDialogAction(
          child: PlatformText('Ok'),
          onPressed: () => Navigator.pop(context),
        ),
      ];
    }

    showPlatformDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) {
            return content;
          },
        ),
        actions: actions,
      ),
    );
  }

  void _loadPreset(String preset) {
    persistValue('current_preset', preset);
    List<dynamic> toLoad = loadPresets()[preset];
    setState(() {
      for (BiblionMetadata meta in _metadata) {
        meta.active = toLoad.contains(meta.id);
      }
    });
  }

  _showPresetPicker() {
    showPresetPicker(context, initialItem: readValue('current_preset'), onPressed: _loadPreset);
  }

  _savePresetPopup(BuildContext context){
    bool hasActive = false;
    List<String> preset = [];
    for(BiblionMetadata biblion in _metadata){
      if(biblion.active){
        hasActive = true;
        preset.add(biblion.id);
      }
    }
    if(hasActive){
      TextEditingController controller = TextEditingController();
      showPlatformDialog(context: context,
          builder: (_) => PlatformAlertDialog(
            title: Text('Save As'),
            content: PlatformTextField(
              controller: controller,
            ),
            actions: <Widget>[
              PlatformDialogAction(
                child: PlatformText('Cancel'),
                onPressed: (){
                  Navigator.of(context).pop();
                },
              ),
              PlatformDialogAction(
                child: Text('OK'),
                onPressed: (){
                  Map<String, dynamic> save = readValue('presets');

                  if(save == null){save = Map();}

                  save[controller.text] = preset;
                  persistValue('presets', save);
                  persistValue('current_preset', controller.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
    }else{
      showPlatformDialog(
          context: context,
          builder: (_) => PlatformAlertDialog(
            title: Text('Preset is Empty'),
            content: Text('You cannot have a preset with no books'),
            actions: <Widget>[
              PlatformDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          )
      );
    }
  }
}

Map<String, dynamic> loadPresets() {
//    _presets = Map();
//    _presets['Greek'] = ['English-Greek', 'LSK', 'Meletontas', 'MiddleLiddell'];
//    _presets['Latin'] = ['CopCrit', 'Gradus'];
//    _presets['Mix'] = ['Gradus', 'LSK'];
  return readValue('presets');
}

noPresetsWarning(BuildContext context){
  showPlatformDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text('No Presets Saved'),
        content: Text('You must save a group of books as a preset before you can load them here'),
        actions: <Widget>[
          PlatformDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      )
  );
}