import 'dart:io';

import 'package:Bibliotheca/help_widget.dart';
import 'package:Bibliotheca/metadata.dart';
import 'package:Bibliotheca/pickers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
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

  Widget _item(
      {Widget title, Widget subtitle, Function onTap, bool enabled = true}) {
    return platformListTile(
      context,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      enabled: enabled,
    );
  }

  Widget _switchItem(
      {Widget title, bool initialValue, Function(bool) onToggle}) {
    bool val = initialValue;

    return platformListTile(context,
        title: title,
        trailing: Switch.adaptive(
          value: val,
          onChanged: (value) {
            setState(() {
              val = value;
              onToggle(val);
            });
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _title('Viewer'),
//            _switchItem(
//              title: platformText(context, 'Search bar on top'),
//              initialValue: readValue('search_on_top') ?? true,
//              onToggle: (value) {
//                setState(() {
//                  persistValue('search_on_top', value);
//                });
//              },
//            ),
            _item(
                title: platformText(context, 'Search history'),
                subtitle: readValue('history_limit') == 0
                    ? platformText(context, 'Don\'t save history')
                    : platformText(
                        context, 'Last ${readValue('history_limit')} searches'),
                onTap: () {
                  showStringPicker(
                    context,
                    initialItem: readValue('history_limit').toString(),
                    list: [for (int i = 0; i <= 6; i++) (i * 5).toString()],
                    title: 'Search History',
                    onPressed: (value) {
                      int val = int.parse(value);
                      if (val == 0) {
                        persistValue('history', null);
                        _searchEmpty = true;
                      } else {
                        Map<String, dynamic> history = readValue('history');
                        for (String id in history.keys) {
                          while (history[id].length > val) {
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
                }),
            _item(
              title: platformText(context, 'Clear search history'),
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
              title: platformText(context, 'Download over mobile connection'),
              initialValue: readValue('mobile_download') ?? false,
              onToggle: (value) {
                setState(() {
                  persistValue('mobile_download', value);
                });
              },
            ),
            _item(
                title: platformText(context, 'Presets'),
                onTap: () => Navigator.push(
                    context,
                    platformPageRoute(
                      context: context,
                      iosTitle: 'Presets',
                      builder: (context) => PresetsWidget(),
                    ))),
            _item(
              title: platformText(context, 'Unlock extras'),
              onTap: () => _unlockBook(context),
            ),
            _title('Miscellaneous'),
            _item(
                title: platformText(context, 'Help'),
                onTap: () => Navigator.push(
                    context,
                    platformPageRoute(
                        context: context, builder: (context) => HelpWidget()))),
            _item(
                title: platformText(context, 'Contact us'),
                onTap: () =>
                    launch('mailto:bibliotheca@bibliothecauraniae.com')),
            _item(
                title: platformText(context, 'About us'),
                onTap: () => Navigator.push(
                    context,
                    platformPageRoute(
                        context: context,
                        builder: (context) => TextFileWidget(
                              title: 'About Us',
                              filename: 'about_me',
                            )
                    )
                )
            ),
            _item(
                title: platformText(context, 'Support the creator'),
                onTap: () => launch('https://www.patreon.com/uraniae')),
            //_item(title: platformText(context, 'About the app')),
          ],
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

  _historyChanged(dynamic history) {
    setState(() {
      _searchEmpty = false;
    });
  }

  _unlock(BuildContext context, String password) async {
    List<BiblionMetadata> metadata = await Metadata.getAll();

    for (BiblionMetadata meta in metadata) {
      if (meta.password == password.toUpperCase()) {
        persistValue('${meta.id}_unlocked', true);
        String directory = (await getApplicationDocumentsDirectory()).path;
        File unlocked = File('$directory/${meta.id}_unlocked.txt');
        await unlocked.create();

        showPlatformDialog(
            context: context,
            builder: (_) => PlatformAlertDialog(
                  title: platformText(context, 'Book Unlocked'),
                  content: platformText(
                      context, '${meta.shortname} is now unlocked'),
                  actions: <Widget>[
                    PlatformDialogAction(
                      child: Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ));
        return;
      }
    }
    showPlatformDialog(
        context: context,
        builder: (_) => PlatformAlertDialog(
              title: Text('Invalid Code'),
              content:
                  Text('The code you entered was incorrect. Please try again'),
              actions: <Widget>[
                PlatformDialogAction(
                  child: Text('OK'),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ));
  }

  TextEditingController textController;

  _unlockBook(BuildContext context) {
    textController = TextEditingController();
    bool filled = false;
    showPlatformDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => PlatformAlertDialog(
                title: Text('Unlock Extras'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            style: PlatformProvider.of(context).platform ==
                                    TargetPlatform.iOS
                                ? CupertinoTheme.of(context).textTheme.textStyle
                                : Theme.of(context).textTheme.bodyText2,
                            text:
                                'Extra books can be unlocked using codes from our '),
                        TextSpan(
                            text: 'Patreon page',
                            style: TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch('https://www.patreon.com/uraniae');
                              }),
                        TextSpan(
                            style: PlatformProvider.of(context).platform ==
                                TargetPlatform.iOS
                                ? CupertinoTheme.of(context).textTheme.textStyle
                                : Theme.of(context).textTheme.bodyText2,
                            text:
                            '.'),
                      ]),
                    ),
                    PlatformTextField(
                      controller: textController,
                      onChanged: (value) {
                        setState(() {
                          textController.value = textController.value.copyWith(
                            text: textController.text.toUpperCase(),
                          );
                          filled = value.length > 0;
                        });
                      },
                    )
                  ],
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                    child: PlatformText('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  PlatformDialogAction(
                    child: PlatformText('Unlock'),
                    onPressed: filled
                        ? () {
                            _unlock(context, textController.text);
                            textController.clear();
                          }
                        : null,
                  ),
                ],
              )),
    );
  }
}

Widget platformText(BuildContext context, String text) {
  if (PlatformProvider.of(context).platform == TargetPlatform.iOS) {
    return Text(
      text,
      style: CupertinoTheme.of(context).textTheme.textStyle,
    );
  } else {
    return Text(text);
  }
}

Widget platformListTile(BuildContext context,
    {Widget leading,
    Widget title,
    Widget subtitle,
    Widget trailing,
    Function onTap,
    bool enabled = true,
    Key key}) {
  if (PlatformProvider.of(context).platform == TargetPlatform.iOS) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        key: key,
        onTap: onTap,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        enabled: enabled,
      ),
    );
  } else {
    return ListTile(
      key: key,
      onTap: onTap,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      enabled: enabled,
    );
  }
}

class PresetsWidget extends StatefulWidget {
  @override
  _PresetsWidgetState createState() => _PresetsWidgetState();
}

class _PresetsWidgetState extends State<PresetsWidget> {
  List<Widget> _generateChildren(List<dynamic> presets) {
    return [
      for (String name in presets)
        platformListTile(context,
            key: ValueKey(name),
            leading: PlatformProvider.of(context).platform == TargetPlatform.iOS
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PlatformIconButton(
                        icon: Icon(CupertinoIcons.up_arrow),
                        onPressed: presets.indexOf(name) == 0
                            ? null
                            : () {
                                int index = presets.indexOf(name);
                                if (index > 0) {
                                  _onReorder(index, index - 1,
                                      presets: presets);
                                }
                              },
                      ),
                      PlatformIconButton(
                        icon: Icon(
                          CupertinoIcons.down_arrow,
                        ),
                        onPressed: presets.indexOf(name) == presets.length - 1
                            ? null
                            : () {
                                int index = presets.indexOf(name);
                                if (index > -1 && index < presets.length - 1) {
                                  _onReorder(index, index + 2,
                                      presets: presets);
                                }
                              },
                      ),
                    ],
                  )
                : Icon(Icons.reorder),
            title: Row(
              children: <Widget>[
                platformText(
                  context,
                  name,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: PlatformIconButton(
                    iosIcon: Icon(CupertinoIcons.pencil),
                    androidIcon: Icon(Icons.edit),
                    onPressed: () {
                      TextEditingController controller =
                          TextEditingController(text: name);
                      showPlatformDialog(
                          context: context,
                          builder: (_) => PlatformAlertDialog(
                                title: Text('Rename to'),
                                content: PlatformTextField(
                                  controller: controller,
                                ),
                                actions: <Widget>[
                                  PlatformDialogAction(
                                    child: PlatformText('Cancel'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  PlatformDialogAction(
                                    child: PlatformText('OK'),
                                    onPressed: () {
                                      setState(() {
                                        if (controller.text != '') {
                                          // Copy map[name] to map[newname]
                                          Map<String, dynamic> sets =
                                              readValue('presets');
                                          sets[controller.text] = sets[name];
                                          persistValue('presets', sets);

                                          // Delete index of name and add newname there
                                          int index = presets.indexOf(name);
                                          presets.removeAt(index);
                                          presets.insert(
                                              index, controller.text);
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                  )
                                ],
                              ));
                    },
                  ),
                ),
              ],
            ),
            trailing: PlatformIconButton(
              iosIcon: Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.destructiveRed,
              ),
              androidIcon: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  presets.removeWhere((element) => element == name);
                  persistValue('presets_list', presets);
                });
              },
            ))
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> presets = readValue('presets_list');
    Widget widget;
    if (presets == null || presets.isEmpty) {
      widget = Center(
        child: platformText(
            context, 'Reorder, rename, and delete your presets here.'),
      );
    } else if (PlatformProvider.of(context).platform == TargetPlatform.iOS) {
      widget = ListView(
        children: _generateChildren(presets),
      );
    } else {
      widget = ReorderableListView(
        children: _generateChildren(presets),
        onReorder: (oldIndex, newIndex) =>
            _onReorder(oldIndex, newIndex, presets: presets),
      );
    }
    return PlatformScaffold(
      appBar: PlatformAppBar(
//          leading: PlatformIconButton(
//            androidIcon: Icon(Icons.arrow_back),
//            iosIcon: Icon(CupertinoIcons.back, color: CupertinoColors.white),
//            cupertino: (context, _) => CupertinoIconButtonData(
//              padding: const EdgeInsets.only(bottom: 4.0),
//            ),
//            onPressed: () => Navigator.pop(context),
//          ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: CupertinoDynamicColor.withBrightness(
              color: Theme.of(context).primaryColor,
              darkColor: Color(0xF01D1D1D)),
          transitionBetweenRoutes: false,
          title: Text(
            'Presets',
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
        material: (_, __) => MaterialAppBarData(
          title: Text('Presets'),
        ),
      ),
      body: widget,
    );
  }

  _onReorder(int oldIndex, int newIndex, {List<dynamic> presets}) {
    setState(
      () {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final String item = presets.removeAt(oldIndex);
        presets.insert(newIndex, item);
        persistValue('presets_list', presets);
      },
    );
  }
}
