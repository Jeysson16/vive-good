import 'package:flutter/material.dart';

class ResponsiveDimensions {
  // Breakpoints para diferentes tamaños de pantalla
  static const double _smallScreenWidth = 360;
  static const double _mediumScreenWidth = 768;
  static const double _largeScreenWidth = 1024;

  // Obtener el factor de escala basado en el ancho de pantalla
  static double _getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= _smallScreenWidth) {
      return 0.85;
    } else if (screenWidth <= _mediumScreenWidth) {
      return 1.0;
    } else if (screenWidth <= _largeScreenWidth) {
      return 1.15;
    } else {
      return 1.3;
    }
  }

  // Padding responsive para cards
  static EdgeInsets getCardPadding(BuildContext context) {
    final scaleFactor = _getScaleFactor(context);
    final basePadding = 16.0;
    final responsivePadding = basePadding * scaleFactor;

    return EdgeInsets.all(responsivePadding.clamp(12.0, 24.0));
  }

  // Margen responsive para cards
  static EdgeInsets getCardMargin(BuildContext context) {
    final scaleFactor = _getScaleFactor(context);
    final baseHorizontal = 8.0;
    final baseVertical = 4.0;

    return EdgeInsets.symmetric(
      horizontal: (baseHorizontal * scaleFactor).clamp(6.0, 12.0),
      vertical: (baseVertical * scaleFactor).clamp(3.0, 6.0),
    );
  }

  // Altura mínima responsive para cards
  static double getCardMinHeight(BuildContext context) {
    final scaleFactor = _getScaleFactor(context);
    final baseHeight =
        140.0; // Aumentado de 120 a 140 para evitar overflow definitivamente

    return (baseHeight * scaleFactor).clamp(120.0, 170.0);
  }

  // Espaciado responsive
  static double getSpacing(BuildContext context, double baseSpacing) {
    final scaleFactor = _getScaleFactor(context);

    return (baseSpacing * scaleFactor).clamp(
      baseSpacing * 0.75,
      baseSpacing * 1.5,
    );
  }

  // Tamaño de fuente responsive
  static double getFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = _getScaleFactor(context);

    return (baseFontSize * scaleFactor).clamp(
      baseFontSize * 0.85,
      baseFontSize * 1.3,
    );
  }

  // Tamaño de icono responsive
  static double getIconSize(BuildContext context, double baseIconSize) {
    final scaleFactor = _getScaleFactor(context);

    return (baseIconSize * scaleFactor).clamp(
      baseIconSize * 0.8,
      baseIconSize * 1.4,
    );
  }

  // Radio de borde responsive
  static double getBorderRadius(BuildContext context, double baseBorderRadius) {
    final scaleFactor = _getScaleFactor(context);

    return (baseBorderRadius * scaleFactor).clamp(
      baseBorderRadius * 0.8,
      baseBorderRadius * 1.2,
    );
  }
}
