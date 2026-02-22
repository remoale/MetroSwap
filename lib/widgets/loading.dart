import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final String text;

  const Loading({super.key, this.text = "Cargando..."});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(text),
        ],
      ),
    );
  }
}
