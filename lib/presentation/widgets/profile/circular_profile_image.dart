import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/profile_image_service.dart';

/// Widget que muestra la foto de perfil circular
/// Conectada a Supabase Storage con dimensiones exactas del Figma (153x153px)
class CircularProfileImage extends StatelessWidget {
  final String? profileImageUrl;
  final String userId;
  final String? firstName;
  final String? lastName;
  final VoidCallback? onTap;

  const CircularProfileImage({
    super.key,
    this.profileImageUrl,
    required this.userId,
    this.firstName,
    this.lastName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center( // ✅ CENTRAR LA IMAGEN
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 153,
          height: 153,
          // ❌ REMOVIDO: margin: const EdgeInsets.only(left: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildProfileImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profileImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildAvatarWithInitials(),
        errorWidget: (context, url, error) => _buildAvatarWithInitials(),
      );
    } else {
      return _buildAvatarWithInitials();
    }
  }

  Widget _buildAvatarWithInitials() {
    // Obtener las iniciales del usuario
    String initials = _getInitials();
    
    return Container(
      color: const Color(0xFF219540), // Color verde del tema
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    String initials = '';
    
    if (firstName != null && firstName!.isNotEmpty) {
      initials += firstName![0].toUpperCase();
    }
    
    if (lastName != null && lastName!.isNotEmpty) {
      initials += lastName![0].toUpperCase();
    }
    
    // Si no hay nombre, usar 'U' de Usuario
    if (initials.isEmpty) {
      initials = 'U';
    }
    
    return initials;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}

/// Widget que incluye funcionalidad de selección de imagen
class EditableCircularProfileImage extends StatefulWidget {
  final String? profileImageUrl;
  final String userId;
  final String? firstName;
  final String? lastName;
  final Function(String?)? onImageChanged;

  const EditableCircularProfileImage({
    super.key,
    this.profileImageUrl,
    required this.userId,
    this.firstName,
    this.lastName,
    this.onImageChanged,
  });

  @override
  State<EditableCircularProfileImage> createState() => _EditableCircularProfileImageState();
}

class _EditableCircularProfileImageState extends State<EditableCircularProfileImage> {
  final ProfileImageService _profileImageService = ProfileImageService();
  bool _isUploading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.profileImageUrl;
  }

  Future<void> _selectAndUploadImage() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final newImageUrl = await _profileImageService.changeProfileImage();

      if (newImageUrl != null) {
        setState(() {
          _currentImageUrl = newImageUrl;
        });
        
        widget.onImageChanged?.call(newImageUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen de perfil actualizada correctamente'),
              backgroundColor: Color(0xFF219540),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center( // ✅ CENTRAR TAMBIÉN EL EDITABLE
      child: Stack(
        children: [
          CircularProfileImage(
            profileImageUrl: _currentImageUrl,
            userId: widget.userId,
            firstName: widget.firstName,
            lastName: widget.lastName,
            onTap: _selectAndUploadImage,
          ),
          
          // Indicador de carga
          if (_isUploading)
            Positioned.fill(
              child: Container(
                // ❌ REMOVIDO: margin: const EdgeInsets.only(left: 120),
                width: 153,
                height: 153,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          
          // Icono de editar
          if (!_isUploading)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                // ❌ REMOVIDO: margin: const EdgeInsets.only(left: 120),
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF219540),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}