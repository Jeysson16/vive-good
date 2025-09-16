import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_advice_model.dart';
import '../../core/error/exceptions.dart';

abstract class AIAdviceRemoteDataSource {
  Future<List<AIAdviceModel>> getAdviceForUser(String userId);
  Future<List<AIAdviceModel>> getAdviceForHabit(
    String userId,
    String habitName,
  );
  Future<AIAdviceModel> saveAdvice(AIAdviceModel advice);
  Future<AIAdviceModel> updateAdvice(AIAdviceModel advice);
  Future<void> deleteAdvice(String adviceId);
  Future<void> markAdviceAsApplied(String adviceId);
  Future<void> toggleAdviceFavorite(String adviceId, bool isFavorite);
}

class AIAdviceRemoteDataSourceImpl implements AIAdviceRemoteDataSource {
  final SupabaseClient supabaseClient;

  AIAdviceRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<AIAdviceModel>> getAdviceForUser(String userId) async {
    try {
      final response = await supabaseClient
          .from('ai_advice')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AIAdviceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener consejos del usuario: $e');
    }
  }

  @override
  Future<List<AIAdviceModel>> getAdviceForHabit(
    String userId,
    String habitName,
  ) async {
    try {
      final response = await supabaseClient
          .from('ai_advice')
          .select()
          .eq('user_id', userId)
          .eq('habit_name', habitName)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AIAdviceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error al obtener consejos del hábito: $e');
    }
  }

  @override
  Future<AIAdviceModel> saveAdvice(AIAdviceModel advice) async {
    try {
      final data = advice.toJson();
      // Remover el ID para que Supabase genere uno nuevo
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await supabaseClient
          .from('ai_advice')
          .insert(data)
          .select()
          .single();

      return AIAdviceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Error al guardar consejo: $e');
    }
  }

  @override
  Future<AIAdviceModel> updateAdvice(AIAdviceModel advice) async {
    try {
      final data = advice.toJson();
      // Remover campos que no se deben actualizar
      data.remove('id');
      data.remove('user_id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await supabaseClient
          .from('ai_advice')
          .update(data)
          .eq('id', advice.id)
          .select()
          .single();

      return AIAdviceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Error al actualizar consejo: $e');
    }
  }

  @override
  Future<void> deleteAdvice(String adviceId) async {
    try {
      await supabaseClient.from('ai_advice').delete().eq('id', adviceId);
    } catch (e) {
      throw ServerException('Error al eliminar consejo: $e');
    }
  }

  @override
  Future<void> markAdviceAsApplied(String adviceId) async {
    try {
      await supabaseClient
          .from('ai_advice')
          .update({'is_applied': true})
          .eq('id', adviceId);
    } catch (e) {
      throw ServerException('Error al marcar consejo como aplicado: $e');
    }
  }

  @override
  Future<void> toggleAdviceFavorite(String adviceId, bool isFavorite) async {
    try {
      await supabaseClient
          .from('ai_advice')
          .update({'is_favorite': isFavorite})
          .eq('id', adviceId);
    } catch (e) {
      throw ServerException('Error al cambiar estado de favorito: $e');
    }
  }
}
