

import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:palette_generator/palette_generator.dart';

Future<Color> getColors(ImageProvider imageProvider) async {
  PaletteGenerator paletteGenerator;
  paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
  Color dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
  if (dominantColor.computeLuminance() > 0.6) {
    Color contrastColor =
        paletteGenerator.darkMutedColor?.color ?? Colors.black;
    if (dominantColor == contrastColor) {
      contrastColor = paletteGenerator.lightMutedColor?.color ?? Colors.white;
    }
    if (contrastColor.computeLuminance() < 0.6) {
      dominantColor = contrastColor;
    }
  }
  GetIt.I<MyTheme>().playGradientColor = dominantColor;
  return dominantColor;
}
