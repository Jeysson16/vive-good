import 'package:flutter/material.dart';

class ResponsiveDimensions {
  static double getCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 12.0; // Pantallas muy pequeñas
    } else if (screenWidth < 600) {
      return 16.0; // Pantallas móviles normales
    } else if (screenWidth < 900) {
      return 20.0; // Tablets pequeñas
    } else {
      return 24.0; // Tablets grandes y desktop
    }
  }

  static double getCardMinHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360 || screenHeight < 600) {
      return 60.0; // Pantallas muy pequeñas
    } else if (screenWidth < 600) {
      return 70.0; // Pantallas móviles normales
    } else if (screenWidth < 900) {
      return 80.0; // Tablets pequeñas
    } else {
      return 90.0; // Tablets grandes y desktop
    }
  }

  static double getIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 20.0;
    } else if (screenWidth < 600) {
      return 24.0;
    } else if (screenWidth < 900) {
      return 28.0;
    } else {
      return 32.0;
    }
  }

  static double getIconContainerSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 40.0;
    } else if (screenWidth < 600) {
      return 48.0;
    } else if (screenWidth < 900) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  static double getHorizontalSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 8.0;
    } else if (screenWidth < 600) {
      return 8.0; // Reducido para compactar grilla en móviles
    } else if (screenWidth < 900) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  static double getVerticalSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 4.0;
    } else if (screenWidth < 600) {
      return 4.0; // Reducido para compactar separación vertical en móviles
    } else if (screenWidth < 900) {
      return 8.0;
    } else {
      return 10.0;
    }
  }

  static double getFontSize(BuildContext context, {required String type}) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (type) {
      case 'title':
        if (screenWidth < 360) return 14.0;
        if (screenWidth < 600) return 16.0;
        if (screenWidth < 900) return 18.0;
        return 20.0;

      case 'subtitle':
        if (screenWidth < 360) return 12.0;
        if (screenWidth < 600) return 14.0;
        if (screenWidth < 900) return 15.0;
        return 16.0;

      case 'caption':
        if (screenWidth < 360) return 10.0;
        if (screenWidth < 600) return 12.0;
        if (screenWidth < 900) return 13.0;
        return 14.0;

      default:
        return 14.0;
    }
  }

  static EdgeInsets getCardMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return const EdgeInsets.only(bottom: 8);
    } else if (screenWidth < 600) {
      return const EdgeInsets.only(bottom: 12);
    } else {
      return const EdgeInsets.only(bottom: 16);
    }
  }

  static double getBorderRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 8.0;
    } else if (screenWidth < 600) {
      return 12.0;
    } else {
      return 16.0;
    }
  }
}
