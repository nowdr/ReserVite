import 'package:flutter/material.dart';

class DataErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  DataErrorWidget({required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Erreur: $error\n\nStackTrace : $stackTrace'));
  }
}
