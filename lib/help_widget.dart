
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class HelpWidget extends StatelessWidget {
  static const List<String> items = ['How to Use App', 'Downloading Books', 'What is Katharevousa?', 'How to Read Katharevousa', 'Grammatical Terms in Greek'];

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: CupertinoDynamicColor.withBrightness(
              color: Theme.of(context).primaryColor,
              darkColor: Color(0xF01D1D1D)),
          transitionBetweenRoutes: false,
          title: Text(
            'Help',
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
        material: (_, __) => MaterialAppBarData(
          title: Text('Help'),
        ),
      ),
      body: ListView.separated(itemBuilder: (context, index) => Text(items.elementAt(index)), separatorBuilder: (context, index) => Divider(), itemCount: items.length),
    );
  }
}
