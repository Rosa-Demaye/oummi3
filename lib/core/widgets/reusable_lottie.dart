import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ReusableLottie extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final bool repeat;

  const ReusableLottie({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      repeat: repeat,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.error_outline,
          color: Colors.red,
          size: width ?? 50,
        );
      },
    );
  }
}
