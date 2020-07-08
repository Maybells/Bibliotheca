import 'package:bibliotheca/metadata.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BibliaWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BibliaWidgetState();
}

class _BibliaWidgetState extends State<BibliaWidget> with SingleTickerProviderStateMixin{
  List<BiblionMetadata> _metadata;
  String active;
  Map<String, MyExpansionTile> tiles;

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
    tiles[meta.id] = tile;
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
                    child: _allToggle ? Text('All Off') : Text('All On'),
                    onPressed: () => {
                      setState(() => {
                        _allToggle = !_allToggle,
                        _metadata.forEach((meta) {meta.active = _allToggle;})
                      })
                    },
                    materialFlat: (__, _) => MaterialFlatButtonData(
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
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
                child: Text('Download (${meta.size})'),
                onPressed: () => {
                  _constructDownloadWarning(meta)
                      .then((value) => showPlatformDialog(
                            context: context,
                            builder: (_) => value,
                          ))
                },
                material: (__, _) => MaterialRaisedButtonData(
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
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

class MyExpansionTile extends StatefulWidget{

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final List<Widget> children;
  final bool titleChevron;
  final ValueChanged<bool> onExpansionChanged;
  MyExpansionTile({this.leading, this.title, this.trailing, this.children, this.titleChevron = false, this.onExpansionChanged})
      : assert(title != null),
        assert(children != null);

  @override
  State<StatefulWidget> createState() {
    return _MyExpansionTileState();
  }

}

class _MyExpansionTileState extends State<MyExpansionTile> with SingleTickerProviderStateMixin{
  bool _isExpanded = false;

  AnimationController _controller;
  Animation<double> _heightFactor;
  Animation<Color> _borderColor;

  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);

  ColorTween _borderColorTween = ColorTween();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _borderColor = _controller.drive(_borderColorTween.chain(_easeOutTween));

    _isExpanded = PageStorage.of(context)?.readState(context) as bool ?? false;
    if(_isExpanded){
      _controller.value = 1.0;
    }
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies(){
    final ThemeData theme = Theme.of(context);
    _borderColorTween.end = theme.dividerColor;
    _borderColorTween.begin = Colors.transparent;
    super.didChangeDependencies();
  }

  Widget _chevron(){
    Animation<double> iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5).chain(_easeInTween));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: RotationTransition(
        turns: iconTurns,
        child: const Icon(Icons.expand_more, color: Colors.black,),
      ),
    );
  }

  collapse(){
    if(_isExpanded){
      _handleTap();
    }
  }

  _handleTap(){
    setState(() {
      _isExpanded = !_isExpanded;
      if(_isExpanded){
        _controller.forward();
      }else{
        _controller.reverse().then((value) => setState((){}));
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    if(widget.onExpansionChanged != null){
      widget.onExpansionChanged(_isExpanded);
    }
  }

  Widget _buildChildren(BuildContext context, Widget child) {
    final Color borderSideColor = _borderColor.value ?? Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderSideColor),
          bottom: BorderSide(color: borderSideColor),
        )
      ),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: widget.leading,
            title: widget.titleChevron ?
            Row(
              children: <Widget>[
                widget.title,
                _chevron()
              ],
            )
            : widget.title,
            trailing: widget.trailing ?? _chevron(),
            onTap: _handleTap,
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    final bool shouldRemoveChildren = closed;
    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
        ),
      ),
    );
    
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}