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

  MyExpansionTile _expansionTile(BuildContext context, BiblionMetadata meta){
    MyExpansionTile tile = PlatformProvider.of(context).platform == TargetPlatform.iOS ? _iosExpansionTile(context, meta) : _androidExpansionTile(context, meta);
    return tile;
  }

  MyExpansionTile _androidExpansionTile(BuildContext context, BiblionMetadata meta){
    return MyExpansionTile(
      title: Text(meta.shortname, style: TextStyle(color: Colors.black),),
      leading: Checkbox(
          value: meta.active,
          onChanged: (bool newValue) => this._onChanged(newValue, meta),
      ),
      children: <Widget>[
        _displayMeta(context, meta)
      ],
    );
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
                  _constructDownloadWarning(meta)
                      .then((value) => showPlatformDialog(
                            context: context,
                            builder: (_) => value,
                          ))
                },
                cupertinoFilled: (__, _) => CupertinoFilledButtonData(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<PlatformAlertDialog> _constructDownloadWarning(
      BiblionMetadata meta) async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    String title;
    Widget content;
    List<Widget> actions;
    bool checked = false;
    if (connectivityResult == ConnectivityResult.wifi) {
      title = 'Download ${meta.shortname}';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
              'The file you are about to download is very large (${meta.size}). Would you still like to download it?'),
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
      actions = <Widget>[
        PlatformDialogAction(
          child: PlatformText('Cancel'),
          material: (__, _) => MaterialDialogActionData(textColor: Colors.red),
          cupertino: (__, _) =>
              CupertinoDialogActionData(isDefaultAction: true),
          onPressed: () => Navigator.pop(context),
        ),
        PlatformDialogAction(
          child: PlatformText('Download'),
          onPressed: () => Navigator.pop(context),
        ),
      ];
    }

    return PlatformAlertDialog(
      title: Text(title),
      content: StatefulBuilder(
        builder: (context, setState) {
          return content;
        },
      ),
      actions: actions,
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