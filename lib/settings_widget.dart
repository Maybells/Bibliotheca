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
          title: 'Searches saved',
          subtitle: '10',
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
  }

  bool _searchEmpty;
  _historyChanged(dynamic history){
    setState(() {
      _searchEmpty = false;
    });
  }
}
