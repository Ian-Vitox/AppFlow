import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .18),
    child: Image.asset(
      'assets/images/estuda_mais_logo.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo Estuda+',
    ),
  );
}
