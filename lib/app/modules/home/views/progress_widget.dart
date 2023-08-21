import 'package:flutter/material.dart';

class ProgressWidget extends StatelessWidget {
  final double downloadProgress;
  const ProgressWidget({super.key, required this.downloadProgress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 20,
              value: downloadProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.teal.shade200,
              ),
            ),
          ),
        ),
        Align(
          child: Padding(
            padding: const EdgeInsets.only(top: 35.0),
            child: Text(
              '${downloadProgress.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
