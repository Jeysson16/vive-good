import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfileImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen desde la galería o cámara
  Future<XFile?> selectImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  /// Sube una imagen de perfil a Supabase Storage
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Leer los bytes del archivo
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Generar nombre único para el archivo
      final String fileExtension = path.extension(imageFile.name).toLowerCase();
      final String fileName = '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Subir archivo a Supabase Storage
      final String uploadPath = await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final String publicUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Actualiza la imagen de perfil del usuario en la base de datos
  Future<bool> updateUserProfileImage(String imageUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('profiles')
          .update({'profile_image_url': imageUrl})
          .eq('id', user.id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Elimina una imagen de perfil anterior
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final Uri uri = Uri.parse(imageUrl);
      final String fileName = uri.pathSegments.last;
      
      await _supabase.storage
          .from('profile-images')
          .remove([fileName]);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Proceso completo: seleccionar, subir y actualizar imagen de perfil
  Future<String?> changeProfileImage({ImageSource source = ImageSource.gallery}) async {
    try {
      // Seleccionar imagen
      final XFile? selectedImage = await selectImage(source: source);
      if (selectedImage == null) {
        return null;
      }

      // Subir imagen
      final String? imageUrl = await uploadProfileImage(selectedImage);
      if (imageUrl == null) {
        throw Exception('Error al subir la imagen');
      }

      // Actualizar perfil del usuario
      final bool success = await updateUserProfileImage(imageUrl);
      if (!success) {
        throw Exception('Error al actualizar el perfil del usuario');
      }

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la URL de la imagen de perfil actual del usuario
  Future<String?> getCurrentProfileImageUrl() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('profiles')
          .select('profile_image_url')
          .eq('id', user.id)
          .single();

      return response['profile_image_url'] as String?;
    } catch (e) {
      return null;
    }
  }
}