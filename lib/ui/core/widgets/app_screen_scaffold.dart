import 'package:flutter/material.dart';

class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    required this.title,
    required this.body,
    super.key,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
