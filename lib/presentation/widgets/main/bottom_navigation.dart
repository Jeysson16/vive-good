import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';

class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 97, // Altura total del taskbar según Figma
      child: Stack(
        children: [
          // Bottom bar principal
          Positioned(
            top: 33, // Posición desde arriba según Figma
            left: 0,
            right: 0,
            child: Container(
              height: 64, // Altura del bottom bar según Figma
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: BottomBarPainter(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 37, // Padding izquierdo según Figma
                    right: 27, // Padding derecho según Figma
                    top: 13, // Padding superior según Figma
                    bottom: 5, // Padding inferior según Figma
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(
                        context: context,
                        icon: Icons.home_outlined,
                        label: 'Inicio',
                        index: 0,
                        isSelected: currentIndex == 0,
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.grid_view_outlined,
                        label: 'Hábitos',
                        index: 1,
                        isSelected: currentIndex == 1,
                      ),
                      const SizedBox(width: 56), // Espacio para el botón flotante
                      _buildNavItem(
                        context: context,
                        icon: Icons.trending_up_outlined,
                        label: 'Progreso',
                        index: 2,
                        isSelected: currentIndex == 2,
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.person_outline,
                        label: 'Perfil',
                        index: 3,
                        isSelected: currentIndex == 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Botón flotante del micrófono
          Positioned(
            top: 1, // Posición desde arriba según Figma
            left: MediaQuery.of(context).size.width / 2 - 28, // Centrado horizontalmente
            child: GestureDetector(
              onTap: () {
                // Navegar directamente al asistente usando GoRouter
                context.go(AppRoutes.assistant);
              },
              child: Container(
                width: 56, // Ancho según Figma
                height: 56, // Alto según Figma
                decoration: BoxDecoration(
                  color: const Color(0xFF219540), // Color verde según Figma
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3AAEF8).withOpacity(0.3), // Sombra según Figma
                      blurRadius: 21,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.only(
                    left: 12, // Padding según Figma
                    right: 11,
                    top: 12,
                    bottom: 10,
                  ),
                  child: Icon(
                    Icons.keyboard_voice,
                    color: Colors.white,
                    size: 34, // Tamaño del ícono según Figma
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        // Usar el sistema de índices normal para todos los botones
        onTap(index);
      },
      child: SizedBox(
        width: 60, // Ancho fijo para cada item
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF219540) : const Color(0xFFACADB9),
              size: 22, // Reducido ligeramente para dar más espacio
            ),
            const SizedBox(height: 2), // Reducido el espaciado
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF219540) : const Color(0xFFACADB9),
                  fontSize: 12, // Reducido para evitar overflow
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter para crear el efecto de hueco en el centro del bottom bar
class BottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Comenzar desde la esquina superior izquierda con borde redondeado
    path.moveTo(20.0, 0); // Empezar después del radio
    
    // Línea hasta antes del hueco (centrado)
    final centerX = size.width / 2;
    final notchWidth = 80.0; // Ancho del hueco
    final notchHeight = 20.0; // Profundidad del hueco
    
    path.lineTo(centerX - notchWidth / 2, 0);
    
    // Crear el hueco para el botón flotante (efecto de recorte)
    path.quadraticBezierTo(
      centerX - notchWidth / 2 + 10.0, 0,
      centerX - notchWidth / 2 + 15.0, notchHeight,
    );
    
    path.quadraticBezierTo(
      centerX - 15.0, notchHeight + 5.0,
      centerX, notchHeight + 5.0,
    );
    
    path.quadraticBezierTo(
      centerX + 15.0, notchHeight + 5.0,
      centerX + notchWidth / 2 - 15.0, notchHeight,
    );
    
    path.quadraticBezierTo(
      centerX + notchWidth / 2 - 10.0, 0,
      centerX + notchWidth / 2, 0,
    );
    
    // Continuar hasta la esquina superior derecha
    path.lineTo(size.width - 20.0, 0);
    
    // Esquina redondeada superior derecha
    path.quadraticBezierTo(size.width, 0, size.width, 20.0);
    
    // Líneas hacia abajo y esquinas inferiores
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 20.0);
    
    // Esquina redondeada superior izquierda
    path.quadraticBezierTo(0, 0, 20.0, 0);
    
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}