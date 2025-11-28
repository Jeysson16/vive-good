import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static const String _profilePicturesBucket = 'profile-pictures';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sube una imagen de perfil a Supabase Storage
  Future<String?> uploadProfilePicture({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Leer los bytes del archivo
      final bytes = await imageFile.readAsBytes();
      
      // Generar nombre único para el archivo
      final fileExtension = path.extension(imageFile.name).toLowerCase();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      // Subir archivo a Supabase Storage
      final response = await _supabase.storage
          .from(_profilePicturesBucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Obtener URL pública del archivo
      final publicUrl = _supabase.storage
          .from(_profilePicturesBucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Elimina una imagen de perfil anterior
  Future<bool> deleteProfilePicture(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final fileName = path.basename(uri.path);
      
      await _supabase.storage
          .from(_profilePicturesBucket)
          .remove([fileName]);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la URL pública de una imagen de perfil
  String? getProfilePictureUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    
    try {
      return _supabase.storage
          .from(_profilePicturesBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si el bucket de profile-pictures existe, si no lo crea
  Future<bool> ensureProfilePicturesBucketExists() async {
    try {
      // Intentar listar archivos del bucket
      await _supabase.storage.from(_profilePicturesBucket).list();
      return true;
    } catch (e) {
      try {
        // Si el bucket no existe, crearlo
        await _supabase.storage.createBucket(
          _profilePicturesBucket,
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB'
          ),
        );
        return true;
      } catch (createError) {
        return false;
      }
    }
  }
}