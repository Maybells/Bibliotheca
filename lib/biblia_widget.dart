import 'dart:io';

import 'package:bibliotheca/metadata.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BibliaWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BibliaWidgetState();
}

class _BibliaWidgetState extends State<BibliaWidget> {
  List<BiblionMetadata> _metadata;

  @override
  Widget build(BuildContext context) {
    if (_metadata != null) {
      return ListView(
        children: <Widget>[
          for (BiblionMetadata meta in _metadata)
            ExpansionTile(
              key: Key(meta.id),
              title: Text(meta.shortname),
              leading: Switch.adaptive(
                  value: meta.active,
                  onChanged: (bool newValue) {
                    setState(() {
                      meta.active = newValue;
                    });
                  }),
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: _displayMeta(meta),
                )
              ],
            )
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

  Widget _displayMeta(BiblionMetadata meta) {
    return Padding(
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
        ],
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
