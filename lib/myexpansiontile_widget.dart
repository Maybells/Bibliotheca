import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MyExpansionTile extends StatefulWidget{

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final List<Widget> children;
  final bool titleChevron;
  final ValueChanged<bool> onExpansionChanged;
  final Key key;
  MyExpansionTile({this.leading, this.title, this.trailing, this.children, this.titleChevron = false, this.onExpansionChanged, this.key})
      : assert(title != null),
        assert(children != null);

  @override
  State<StatefulWidget> createState() {
    return _MyExpansionTileState();
  }

}

class _MyExpansionTileState extends State<MyExpansionTile> with SingleTickerProviderStateMixin{
  bool _isExpanded = false;

  Tween<double> _halfTween = Tween(begin: 0.0, end: 0.5);
  Tween<double> _partialTween = Tween(begin: 0.6, end: 1.0);

  AnimationController _controller;
  Animation<double> _heightFactor;
  Animation<Color> _borderColor;
  Animation<Color> _borderBottomColor;

  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);

  ColorTween _borderColorTween = ColorTween();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _borderColor = _controller.drive(_borderColorTween.chain(_partialTween.chain(_easeOutTween)));
    _borderBottomColor = _controller.drive(_borderColorTween.chain(_easeOutTween));

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
    _borderColorTween
      ..begin = Colors.transparent
      ..end = theme.dividerColor;
    super.didChangeDependencies();
  }

  Widget _chevron(){
    Animation<double> iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: RotationTransition(
        turns: iconTurns,
        child: Icon(
          Icons.expand_more,
          color: PlatformProvider.of(context).platform == TargetPlatform.iOS
              ? CupertinoTheme.of(context).textTheme.textStyle.color
              : Theme.of(context).textTheme.subtitle1.color,
        ),
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
    final Color borderBottomColor = _borderBottomColor.value ?? Colors.transparent;

    return Container(
      decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderSideColor),
            bottom: BorderSide(color: borderBottomColor),
          )
      ),
      child: Column(
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: ListTile(
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
      key: widget.key,
      animation: _controller.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}