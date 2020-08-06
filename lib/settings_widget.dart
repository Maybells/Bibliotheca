import 'package:bibliotheca/pickers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'files.dart';

class SettingsWidget extends StatefulWidget {
  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  Widget _title(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(
            color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _item({String title, String subtitle, Function onTap, bool enabled = true}) {
    if (PlatformProvider.of(context).platform == TargetPlatform.iOS) {
      return Material(
        child: ListTile(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onTap: onTap,
          enabled: enabled,
        ),
      );
    } else {
      return ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        onTap: onTap,
        enabled: enabled,
      );
    }
  }

  Widget _switchItem(
      {String title, bool initialValue, Function(bool) onToggle}) {
    bool val = initialValue;
    return SwitchListTile.adaptive(
      title: Text(title),
        value: val,
        onChanged: (value) {
          setState(() {
            val = value;
            onToggle(val);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Viewer'),
        _item(
          title: 'Search bar position',
          subtitle: 'Top',
        ),
        _item(
          title: 'Search history',
          subtitle: readValue('history_limit') == 0 ? 'Don\'t save history' : 'Last ${readValue('history_limit')} searches',
          onTap: (){
            androidPicker(
              context: context,
              initialItem: readValue('history_limit').toString(),
              entriesList: [for(int i = 0; i <= 6; i++) (i*5).toString()],
              title: 'Search History',
              onPressed: (value){
                int val = int.parse(value);
                if(val == 0){
                  persistValue('history', null);
                  _searchEmpty = true;
                }else{
                  Map<String, dynamic> history = readValue('history');
                  for(String id in history.keys){
                    while(history[id].length > val){
                      history[id].removeLast();
                    }
                  }
                  persistValue('history', history);
                }
                setState(() {
                  persistValue('history_limit', val);
                });
              },
            );
          }
        ),
        _item(
          title: 'Clear search history',
          enabled: !_searchEmpty,
          onTap: () {
            persistValue('history', null);
            setState(() {
              _searchEmpty = true;
            });
          },
        ),
        _title('Book Manager'),
        _switchItem(
          title: 'Download over mobile connection',
          initialValue: false,
          onToggle: (value) {
            setState(() {
              persistValue('mobile_download', value);
            });
          },
        ),
        _item(
          title: 'Presets',
        ),
        _item(
          title: 'Patreon extras',
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    listenValue('history_changed', _historyChanged);

    _searchEmpty = false;

    if (readValue('history_limit') == null) {
      persistValue('history_limit', 10);
    }
  }

  bool _searchEmpty;
  _historyChanged(dynamic history){
    setState(() {
      _searchEmpty = false;
    });
  }
}
