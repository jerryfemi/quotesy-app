import 'package:flutter/material.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050505),
      body: Center(
        child: Text(
          'The Vault',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 28,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}
