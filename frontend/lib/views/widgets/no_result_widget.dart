import 'package:flutter/material.dart';

class NoResultWidget extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String? message;

  const NoResultWidget({
    required this.iconData,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 50, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          if (message != null) ...[
            SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}
