import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF4CAF50),
      elevation: 8,
      child: const Icon(
        Icons.mic,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}