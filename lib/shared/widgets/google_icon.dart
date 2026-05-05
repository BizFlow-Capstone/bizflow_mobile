import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return FaIcon(
      FontAwesomeIcons.google,
      size: size,
      color: const Color(0xFF4285F4), // Google Blue
    );
  }
}

