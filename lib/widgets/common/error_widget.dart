import 'package:flutter/material.dart';

/// Widget de error personalizado reutilizable
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? color;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de error
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFFF44336)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 40,
                color: color ?? const Color(0xFFF44336),
              ),
            ),

            const SizedBox(height: 24),

            // Título del error
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null) const SizedBox(height: 12),

            // Mensaje de error
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Botón de reintentar
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget de error compacto para usar en espacios reducidos
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Color? color;

  const CompactErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFFF44336)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? const Color(0xFFF44336)).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: color ?? const Color(0xFFF44336),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: color ?? const Color(0xFFF44336),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: color ?? const Color(0xFFF44336),
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de error para conexión de red
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'Sin conexión',
      message: 'Verifica tu conexión a internet e intenta nuevamente.',
      icon: Icons.wifi_off,
      color: const Color(0xFF666666),
      onRetry: onRetry,
    );
  }
}

/// Widget de error para datos no encontrados
class NotFoundErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const NotFoundErrorWidget({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'No encontrado',
      message: message ?? 'Los datos solicitados no se encontraron.',
      icon: Icons.search_off,
      color: const Color(0xFF666666),
      onRetry: onRetry,
    );
  }
}
