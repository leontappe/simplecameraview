import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsTile({
    super.key,
    required this.title,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      color: Colors.blueGrey.shade800,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4.0,
            left: 8.0,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 26.0,
            left: 8.0,
            right: 8.0,
            bottom: 8.0,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: children),
          )
        ],
      ),
    );
  }
}

class SettingsTitle extends StatelessWidget {
  final String title;

  const SettingsTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
