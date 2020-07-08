import 'package:bibliotheca/metadata.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'myexpansiontile_widget.dart';

class BibliaWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BibliaWidgetState();
}

class _BibliaWidgetState extends State<BibliaWidget> with SingleTickerProviderStateMixin{
  List<BiblionMetadata> _metadata;
  bool _downloadOverMobile = false;

  void _onChanged(bool newValue, BiblionMetadata meta){
    setState(() {
      meta.active = newValue;
    });
  }

  MyExpansionTile _iosExpansionTile(BuildContext context, BiblionMetadata meta){
    return MyExpansionTile(
      title: Text(meta.shortname, style: TextStyle(color: Colors.black),),
      trailing: CupertinoSwitch(
          value: meta.active,
          onChanged: (bool newValue) => this._onChanged(newValue, meta)
      ),
      children: <Widget>[
        _displayMeta(context, meta)
      ],
      titleChevron: true,
    );
  }

  MyExpansionTile _androidExpansionTile(BuildContext context, BiblionMetadata meta){
    return MyExpansionTile(
      title: Text(meta.shortname, style: TextStyle(color: Colors.black),),
//      leading: Checkbox(
//        value: meta.active,
//        onChanged: (bool newValue) => this._onChanged(newValue, meta),
//      ),
      children: <Widget>[
        _displayMeta(context, meta)
      ],
      titleChevron: true,
      trailing: Switch(
        value: meta.active,
        onChanged: (bool newValue) => this._onChanged(newValue, meta),
      ),
    );
  }

  MyExpansionTile _expansionTile(BuildContext context, BiblionMetadata meta){
    MyExpansionTile tile = PlatformProvider.of(context).platform == TargetPlatform.iOS ? _iosExpansionTile(context, meta) : _androidExpansionTile(context, meta);
    return tile;
  }

  bool _allToggle = true;

  @override
  Widget build(BuildContext context) {
    if (_metadata != null) {
      return Material(
        child: ListView(
          children: <Widget>[
            ButtonBar(
              children: <Widget>[
                  PlatformButton(
                    child: Text('Save to Preset'),
                    onPressed: () {

                    },
                  ),
                  PlatformButton(
                    child: _allToggle ? Text('All Off') : Text('All On'),
                    onPressed: () => {
                      setState(() => {
                        _allToggle = !_allToggle,
                        _metadata.forEach((meta) {meta.active = _allToggle;})
                      })
                    },
                  ),
                  PlatformButton(
                    child: Text('Presets'),
                  )
              ],
            ),
            for (BiblionMetadata meta in _metadata)
              _expansionTile(context, meta)
          ],
        ),
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
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: variable),
            ]),
      ),
    );
  }

  Widget _displayMeta(BuildContext context, BiblionMetadata meta) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding:
            const EdgeInsets.only(top: 6.0, bottom: 8.0, left: 16.0, right: 16.0),
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
            Center(
              child: PlatformButton(
                child: Text('Download (${meta.size})', style: const TextStyle(color: Colors.white),),
                onPressed: () => {
                  _constructDownloadWarning(context, meta)
                },
                cupertinoFilled: (__, _) => CupertinoFilledButtonData(),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _constructDownloadWarning(
      BuildContext context,
      BiblionMetadata meta) async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    String title;
    Widget content;
    List<Widget> actions;
    if(connectivityResult == ConnectivityResult.wifi || (connectivityResult == ConnectivityResult.mobile && _downloadOverMobile)){
      return;
    }else if (connectivityResult == ConnectivityResult.mobile) {
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
            if(checked)
              _downloadOverMobile = true;
            Navigator.pop(context);
          },
        ),
      ];
    }else if(connectivityResult == ConnectivityResult.none){
      title = 'Device Offline';
      content = Text('You must be connected to the internet to download books.');
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
}