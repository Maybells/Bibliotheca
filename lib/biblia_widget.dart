import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'file:///C:/AndroidStudio/Bibliotheca/bibliotheca/lib/pickers.dart';
import 'package:bibliotheca/metadata.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:get_storage/get_storage.dart';

import 'files.dart';
import 'myexpansiontile_widget.dart';

class BibliaWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BibliaWidgetState();
}

class DownloadProgress {
  bool inProgress;
  bool downloaded;
  bool paused;
  int last;
  bool pausing;
  bool deleting;

  DownloadProgress(
      {this.inProgress = false,
      this.downloaded = false,
      this.last,
      this.paused = false,
      this.pausing = false,
      this.deleting = false});

  String button(BiblionMetadata meta) {
    if (downloaded) {
      return 'Uninstall (${meta.size})';
    } else if (deleting) {
      return 'Uninstalling...';
    } else if (pausing) {
      return 'Pausing...';
    } else if (paused) {
      return 'Paused ($last/${meta.pages})';
    } else if (inProgress) {
      if (last != null) {
        return 'Loading... ($last/${meta.pages})';
      } else {
        return 'Loading...';
      }
    } else {
      return 'Download (${meta.size})';
    }
  }
}

class _BibliaWidgetState extends State<BibliaWidget>
    with SingleTickerProviderStateMixin {
  List<BiblionMetadata> _metadata;
  bool _allToggle = true;
  Map<String, DownloadProgress> _downloadButtons;

  @override
  initState() {
    super.initState();

    _downloadButtons = Map();
    _getDownloadsStatus();

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

  MyExpansionTile _expansionTile(BuildContext context, BiblionMetadata meta) {
    return MyExpansionTile(
      key: PageStorageKey(meta.id),
      title: Text(
        meta.shortname,
        style: (PlatformProvider.of(context).platform == TargetPlatform.iOS
                ? CupertinoTheme.of(context).textTheme.textStyle
                : Theme.of(context).textTheme.subtitle1)
            .copyWith(fontFeatures: [FontFeature.enable('smcp')]),
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
      List<Widget> widgets = [

      ];
      for (BiblionMetadata meta in _metadata)
        if(!meta.hidden || readValue('${meta.id}_unlocked') == 'true')
          widgets.add(_expansionTile(context, meta));
        else
          listenValue('${meta.id}_unlocked', (value){
            setState(() {
              meta.hidden = false;
            });
          });

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
                onPressed: () {
                  loadPresets() == null
                      ? noPresetsWarning(context)
                      : _showPresetPicker();
                },
              )
            ],
          ),
          ...widgets,
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
                    : Theme.of(context).textTheme.subtitle1)
                .copyWith(fontSize: 16.0),
            children: <TextSpan>[
              TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: variable),
            ]),
      ),
    );
  }

  Widget _downloadButton(BuildContext context, BiblionMetadata meta) {
    Function pressed = () => {_downloadPressed(context, meta)};
    DownloadProgress progress = _downloadButtons[meta.id] ?? DownloadProgress();

    return PlatformButton(
      child: PlatformProvider.of(context).platform == TargetPlatform.android
          ? Text(progress.button(meta))
          : Text(
              progress.button(meta),
              style: TextStyle(
                color: progress.downloaded || progress.deleting
                    ? CupertinoColors.destructiveRed
                    : CupertinoColors.activeBlue,
              ),
            ),
      onPressed: pressed,
      cupertino: (__, _) => CupertinoButtonData(),
      material: (context, _) => MaterialRaisedButtonData(
        textColor: Theme.of(context).accentTextTheme.headline6.color,
        color: progress.downloaded || progress.deleting
            ? Colors.red
            : Theme.of(context).accentColor,
      ),
    );
  }

  _downloadPressed(BuildContext context, BiblionMetadata meta) {
    DownloadProgress progress = _downloadButtons[meta.id] ?? DownloadProgress();
    if (progress.paused) {
      // Resume download
      _downloadWarning(context, meta, false);
    } else if (progress.downloaded) {
      // Uninstall (with warning)
      _uninstallWarning(context, meta);
    } else if (progress.inProgress) {
      // Pause download
      setState(() {
        _downloadButtons[meta.id].pausing = true;
      });
    } else {
      // Download (with warning if mobile)
      _downloadWarning(context, meta, true);
    }
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
            _displayVariable('Pages', '${meta.pages}'),
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

  _uninstallWarning(BuildContext context, BiblionMetadata meta) {
    showPlatformDialog(
        context: context,
        builder: (context) => PlatformAlertDialog(
              title: Text('Uninstall Book?'),
              content: Text(
                  'Are you sure you want to remove ${meta.shortname} from your phone?'),
              actions: <Widget>[
                PlatformDialogAction(
                  child: PlatformText('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                PlatformDialogAction(
                  child: PlatformText('Uninstall'),
                  cupertino: (__, _) => CupertinoDialogActionData(
                    isDestructiveAction: true,
                  ),
                  material: (__, _) => MaterialDialogActionData(
                    textColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    _uninstall(meta);
                    Navigator.pop(context);
                  },
                ),
              ],
            ));
  }

  _uninstall(BiblionMetadata meta) async {
    setState(() {
      _downloadButtons[meta.id] = DownloadProgress(deleting: true);
    });

    Directory directory = await createDirectory(meta.id);
    directory.delete(recursive: true).then((value) {
      setState(() {
        _downloadButtons[meta.id] = DownloadProgress();
      });
    });
  }

  _downloadPages(BiblionMetadata meta, int from) async {
    const int grouping = 21;

    setState(() {
      _downloadButtons[meta.id] = DownloadProgress(inProgress: true);
    });

    int currentPage = from - 1;
    int loadedPage = from - 1;
    Timer timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (currentPage < loadedPage) {
        if (loadedPage - currentPage > grouping) {
          currentPage += 4;
        } else {
          currentPage++;
        }

        setState(() {
          _downloadButtons[meta.id].last = currentPage;
        });
      }
    });

    String directory = (await createDirectory(meta.id)).path;

    File finished = File('$directory/finished.png}');

    // Download the rest of the book 21 pages at a time (one-by-one took ~17 minutes for a 900 page book, 4-by-4 took ~4.5, 11-by-11 ~1.5, 21-by-21 ~50 secs)
    for (int i = from; i <= meta.pages; i += grouping) {
      await Future.wait([
        for (int j = 0; j < grouping && i + j <= meta.pages; j++)
          saveImage(directory, '${intToDigits(i + j, meta.pages)}.png',
              'http://assets.bibliothecauraniae.com/${meta.id}/${intToDigits(i + j, meta.pages)}.png?i=1')
      ]);
      if (_downloadButtons[meta.id].pausing) {
        timer.cancel();
        setState(() {
          _downloadButtons[meta.id]
            ..pausing = false
            ..paused = true
            ..last = min(i + grouping, meta.pages)
            ..inProgress = false;
        });
        return;
      } else {
        loadedPage = i + grouping;
        if (loadedPage > meta.pages) {
          loadedPage = meta.pages;
        }
      }
    }
    timer.cancel();
    finished.createSync();
    setState(() {
      _downloadButtons[meta.id]
        ..inProgress = false
        ..downloaded = true;
    });
  }

  _download(BiblionMetadata meta) async {
    setState(() {
      _downloadButtons[meta.id] = DownloadProgress(inProgress: true);
    });

    String directory = (await createDirectory(meta.id)).path;

    // Download the title and abbreviations
    await Future.wait([
      saveImage(directory, 'title.png',
          'http://assets.bibliothecauraniae.com/${meta.id}/title.png?i=1'),
      for (int i = 1; i <= meta.abbr; i++)
        saveImage(directory, 'abbr_$i.png',
            'http://assets.bibliothecauraniae.com/${meta.id}/abbr_$i.png?i=1'),
    ]);

    // Download the pages
    _downloadPages(meta, 1);
  }

  void _downloadWarning(
      BuildContext context, BiblionMetadata meta, bool initial) async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    String title;
    Widget content;
    List<Widget> actions;
    if (connectivityResult == ConnectivityResult.wifi ||
        (connectivityResult == ConnectivityResult.mobile &&
            (readValue('mobile_download')??false))) {
      initial
          ? _download(meta)
          : _downloadPages(meta, _downloadButtons[meta.id].last);
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
                  'You are about to download a large file over a cellular connection. Are you sure you want to do this?'),
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
            if (checked) persistValue('mobile_download', true);
            initial
                ? _download(meta)
                : _downloadPages(meta, _downloadButtons[meta.id].last);
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
    showPresetPicker(context,
        initialItem: readValue('current_preset'), onPressed: _loadPreset);
  }

  _savePresetPopup(BuildContext context) {
    bool hasActive = false;
    List<String> preset = [];
    for (BiblionMetadata biblion in _metadata) {
      if (biblion.active) {
        hasActive = true;
        preset.add(biblion.id);
      }
    }
    if (hasActive) {
      TextEditingController controller = TextEditingController();
      showPlatformDialog(
          context: context,
          builder: (_) => PlatformAlertDialog(
                title: Text('Save As'),
                content: PlatformTextField(
                  controller: controller,
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                    child: PlatformText('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  PlatformDialogAction(
                    child: Text('OK'),
                    onPressed: () {
                      Map<String, dynamic> save = readValue('presets');
                      List<dynamic> presetsList = readValue('presets_list');

                      if (save == null || presetsList == null) {
                        save = Map();
                        presetsList = [];
                      }

                      save[controller.text] = preset;
                      presetsList.add(controller.text);
                      persistValue('presets', save);
                      persistValue('presets_list', presetsList);
                      persistValue('current_preset', controller.text);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
    } else {
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
              ));
    }
  }

  _getDownloadsStatus() async {
    Directory directory = await getApplicationDocumentsDirectory();

    directory.list(recursive: false).listen((FileSystemEntity event) {
      if (event is Directory) {
        String folder = event.path.split('/').last;
        File finished = File('${event.path}/finished.png}');
        finished.exists().then((value) {
          if (value) {
            setState(() {
              _downloadButtons[folder] = DownloadProgress(downloaded: true);
            });
          } else {
            var files = <FileSystemEntity>[];
            event.list().listen((event) {
              files.add(event);
            }, onDone: () {
              if(files != null){
                files.sort((a, b) => a.path.compareTo(b.path));
                File first = files.firstWhere((element) => element.path
                    .split('/')
                    .last
                    .contains(RegExp(r'^0+1.png')));

                if(first != null){
                  int digits = first.path.split('/').last.split('.').first.length;
                  int last = 1;
                  for(int i = 1; i < pow(10, digits)-1; i++){
                    String num = i.toString();
                    while(num.length < digits){
                      num = '0$num';
                    }
                    File current = File('${event.path}/$num.png');
                    if(current.existsSync()){
                      last = i;
                    }else{
                      break;
                    }
                  }

                  setState(() {
                    _downloadButtons[folder] =
                        DownloadProgress(paused: true, last: last);
                  });
                }
              }
            });
          }
        });
      }else if(event is File){
        if(event.path.split('.').last == 'png'){
          event.delete();
        }
      }
    });
  }
}

Map<String, dynamic> loadPresets() {
//    _presets = Map();
//    _presets['Greek'] = ['English-Greek', 'LSK', 'Meletontas', 'MiddleLiddell'];
//    _presets['Latin'] = ['CopCrit', 'Gradus'];
//    _presets['Mix'] = ['Gradus', 'LSK'];
  return readValue('presets');
}

noPresetsWarning(BuildContext context) {
  showPlatformDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
            title: Text('No Presets Saved'),
            content: Text(
                'You must save a group of books as a preset before you can load them here'),
            actions: <Widget>[
              PlatformDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ));
}

noBooksWarning(BuildContext context) {
  showPlatformDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
            title: Text('No Active Books'),
            content: Text(
                'You must have at least two active books to switch between them'),
            actions: <Widget>[
              PlatformDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ));
}

Future<Directory> createDirectory(String folder) async {
  Directory directory = await getApplicationDocumentsDirectory();

  Directory above = Directory('${directory.path}/$folder');
  return above.create();
}
