import 'package:flutter/material.dart';

class LogWidget extends StatelessWidget {
  final String text;
  const LogWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.47,
        width: double.infinity,
        color: Colors.teal.shade200,
        padding: const EdgeInsets.only(
          left: 15,
          right: 5,
          top: 10,
          bottom: 20,
        ),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 3, 12, 22),
              fontSize: 13,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
