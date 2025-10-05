import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Servicio para aplicar migraciones de base de datos desde la aplicación
class DatabaseMigrationService {
  static final _supabase = Supabase.instance.client;

  /// Aplica la migración para crear tablas de métricas (tabla conversations eliminada)
  static Future<void> applyMetricsMigration() async {
    try {
      developer.log('Iniciando migración de métricas...');

      // Crear tablas de métricas
      await _createMetricsTables();

      developer.log('Migración de métricas completada exitosamente');
    } catch (e) {
      developer.log('Error en migración: $e');
      throw Exception('Error al aplicar migración: $e');
    }
  }



  /// Crea las tablas para métricas de salud
  static Future<void> _createMetricsTables() async {
    final tables = [
      _getUserSymptomsKnowledgeTableSQL(),
      _getUserEatingHabitsTableSQL(),
      _getUserHealthyHabitsTableSQL(),
      _getUserTechAcceptanceTableSQL(),
    ];

    for (final tableSQL in tables) {
      try {
        await _supabase.rpc('execute_sql', params: {'sql': tableSQL});
      } catch (e) {
        developer.log('Error creando tabla: $e');
        // Continuar con las demás tablas
      }
    }

    // Crear políticas RLS
    await _createRLSPolicies();
  }

  /// SQL para crear tabla de conocimiento de síntomas
  static String _getUserSymptomsKnowledgeTableSQL() {
    return '''
      CREATE TABLE IF NOT EXISTS user_symptoms_knowledge (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
        symptom_type VARCHAR(100) NOT NULL,
        knowledge_level VARCHAR(50) NOT NULL,
        risk_factors_identified TEXT[],
        symptoms_mentioned TEXT[],
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        metadata JSONB DEFAULT '{}'
      );
    ''';
  }

  /// SQL para crear tabla de hábitos alimenticios
  static String _getUserEatingHabitsTableSQL() {
    return '''
      CREATE TABLE IF NOT EXISTS user_eating_habits (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
        habit_type VARCHAR(100) NOT NULL,
        risk_level VARCHAR(50) NOT NULL,
        frequency VARCHAR(50),
        habits_identified TEXT[],
        recommendations_given TEXT[],
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        metadata JSONB DEFAULT '{}'
      );
    ''';
  }

  /// SQL para crear tabla de hábitos saludables
  static String _getUserHealthyHabitsTableSQL() {
    return '''
      CREATE TABLE IF NOT EXISTS user_healthy_habits (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
        habit_category VARCHAR(100) NOT NULL,
        current_level VARCHAR(50) NOT NULL,
        target_level VARCHAR(50),
        habits_tracked TEXT[],
        progress_indicators JSONB DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        metadata JSONB DEFAULT '{}'
      );
    ''';
  }

  /// SQL para crear tabla de aceptación tecnológica
  static String _getUserTechAcceptanceTableSQL() {
    return '''
      CREATE TABLE IF NOT EXISTS user_tech_acceptance (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
        tech_category VARCHAR(100) NOT NULL,
        acceptance_level VARCHAR(50) NOT NULL,
        usage_frequency VARCHAR(50),
        features_used TEXT[],
        barriers_identified TEXT[],
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        metadata JSONB DEFAULT '{}'
      );
    ''';
  }

  /// Crea las políticas RLS para las tablas de métricas
  static Future<void> _createRLSPolicies() async {
    final policies = [
      // Habilitar RLS
      'ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY;',
      'ALTER TABLE user_eating_habits ENABLE ROW LEVEL SECURITY;',
      'ALTER TABLE user_healthy_habits ENABLE ROW LEVEL SECURITY;',
      'ALTER TABLE user_tech_acceptance ENABLE ROW LEVEL SECURITY;',
      
      // Políticas para user_symptoms_knowledge
      '''CREATE POLICY IF NOT EXISTS "Users can view their own symptoms knowledge" ON user_symptoms_knowledge
         FOR SELECT USING (auth.uid() = user_id);''',
      '''CREATE POLICY IF NOT EXISTS "Users can insert their own symptoms knowledge" ON user_symptoms_knowledge
         FOR INSERT WITH CHECK (auth.uid() = user_id);''',
      
      // Políticas para user_eating_habits
      '''CREATE POLICY IF NOT EXISTS "Users can view their own eating habits" ON user_eating_habits
         FOR SELECT USING (auth.uid() = user_id);''',
      '''CREATE POLICY IF NOT EXISTS "Users can insert their own eating habits" ON user_eating_habits
         FOR INSERT WITH CHECK (auth.uid() = user_id);''',
      
      // Políticas para user_healthy_habits
      '''CREATE POLICY IF NOT EXISTS "Users can view their own healthy habits" ON user_healthy_habits
         FOR SELECT USING (auth.uid() = user_id);''',
      '''CREATE POLICY IF NOT EXISTS "Users can insert their own healthy habits" ON user_healthy_habits
         FOR INSERT WITH CHECK (auth.uid() = user_id);''',
      '''CREATE POLICY IF NOT EXISTS "Users can update their own healthy habits" ON user_healthy_habits
         FOR UPDATE USING (auth.uid() = user_id);''',
      
      // Políticas para user_tech_acceptance
      '''CREATE POLICY IF NOT EXISTS "Users can view their own tech acceptance" ON user_tech_acceptance
         FOR SELECT USING (auth.uid() = user_id);''',
      '''CREATE POLICY IF NOT EXISTS "Users can insert their own tech acceptance" ON user_tech_acceptance
         FOR INSERT WITH CHECK (auth.uid() = user_id);''',
    ];

    for (final policy in policies) {
      try {
        await _supabase.rpc('execute_sql', params: {'sql': policy});
      } catch (e) {
        developer.log('Error creando política: $e');
        // Continuar con las demás políticas
      }
    }
  }

  /// Verifica si las migraciones se aplicaron correctamente
  static Future<bool> verifyMigrations() async {
    try {
      // Verificar que la tabla chat_sessions exista y tenga las columnas necesarias
      final chatSessionsResult = await _supabase
          .from('chat_sessions')
          .select('id, title, status')
          .limit(1)
          .maybeSingle();

      // Verificar que las tablas de métricas existan
      final symptomsResult = await _supabase
          .from('user_symptoms_knowledge')
          .select('id')
          .limit(1)
          .maybeSingle();

      developer.log('Verificación de migraciones exitosa');
      return true;
    } catch (e) {
      developer.log('Error en verificación de migraciones: $e');
      return false;
    }
  }

  /// Registra datos de conversación en las tablas de métricas
  static Future<void> recordConversationMetrics({
    required String userId,
    required String sessionId,
    required String messageContent,
    required Map<String, dynamic> analysisResult,
  }) async {
    try {
      // Analizar el contenido del mensaje para extraer métricas
      final metrics = _analyzeMessageForMetrics(messageContent, analysisResult);

      // Registrar conocimiento de síntomas
      if (metrics['symptoms'] != null) {
        await _recordSymptomsKnowledge(userId, sessionId, metrics['symptoms']);
      }

      // Registrar hábitos alimenticios
      if (metrics['eating_habits'] != null) {
        await _recordEatingHabits(userId, sessionId, metrics['eating_habits']);
      }

      // Registrar hábitos saludables
      if (metrics['healthy_habits'] != null) {
        await _recordHealthyHabits(userId, sessionId, metrics['healthy_habits']);
      }

      // Registrar aceptación tecnológica
      if (metrics['tech_acceptance'] != null) {
        await _recordTechAcceptance(userId, sessionId, metrics['tech_acceptance']);
      }

    } catch (e) {
      developer.log('Error registrando métricas de conversación: $e');
    }
  }

  /// Analiza el contenido del mensaje para extraer métricas
  static Map<String, dynamic> _analyzeMessageForMetrics(
    String messageContent, 
    Map<String, dynamic> analysisResult
  ) {
    final metrics = <String, dynamic>{};
    final content = messageContent.toLowerCase();

    // Detectar conocimiento de síntomas
    if (content.contains('dolor') || content.contains('ardor') || 
        content.contains('náusea') || content.contains('gastritis')) {
      metrics['symptoms'] = {
        'symptom_type': 'gastritis_symptoms',
        'knowledge_level': _determineKnowledgeLevel(content),
        'symptoms_mentioned': _extractSymptoms(content),
        'risk_factors_identified': _extractRiskFactors(content),
      };
    }

    // Detectar hábitos alimenticios
    if (content.contains('comida') || content.contains('comer') || 
        content.contains('dieta') || content.contains('alimento')) {
      metrics['eating_habits'] = {
        'habit_type': 'dietary_habits',
        'risk_level': _determineRiskLevel(content),
        'habits_identified': _extractEatingHabits(content),
      };
    }

    // Detectar adopción de hábitos saludables
    if (content.contains('ejercicio') || content.contains('agua') || 
        content.contains('dormir') || content.contains('relajar')) {
      metrics['healthy_habits'] = {
        'habit_category': _determineHabitCategory(content),
        'adoption_status': 'en_proceso',
        'habits_adopted': _extractHealthyHabits(content),
      };
    }

    // Detectar aceptación tecnológica (basado en interacción con el bot)
    metrics['tech_acceptance'] = {
      'tool_type': 'chat_bot',
      'acceptance_level': 'alta', // Si está usando el bot, la aceptación es alta
      'usage_frequency': 'activo',
      'feedback_sentiment': _determineSentiment(content),
    };

    return metrics;
  }

  // Métodos auxiliares para análisis de contenido
  static String _determineKnowledgeLevel(String content) {
    if (content.contains('no sé') || content.contains('no entiendo')) return 'bajo';
    if (content.contains('creo que') || content.contains('tal vez')) return 'medio';
    return 'alto';
  }

  static String _determineRiskLevel(String content) {
    if (content.contains('picante') || content.contains('grasa') || 
        content.contains('alcohol') || content.contains('café')) return 'alto';
    if (content.contains('a veces') || content.contains('poco')) return 'medio';
    return 'bajo';
  }

  static String _determineHabitCategory(String content) {
    if (content.contains('ejercicio') || content.contains('caminar')) return 'ejercicio';
    if (content.contains('agua') || content.contains('beber')) return 'alimentacion';
    if (content.contains('dormir') || content.contains('descansar')) return 'sueno';
    if (content.contains('estrés') || content.contains('relajar')) return 'estres';
    return 'general';
  }

  static String _determineSentiment(String content) {
    if (content.contains('bien') || content.contains('bueno') || 
        content.contains('gracias') || content.contains('útil')) return 'positivo';
    if (content.contains('mal') || content.contains('problema') || 
        content.contains('difícil')) return 'negativo';
    return 'neutral';
  }

  static List<String> _extractSymptoms(String content) {
    final symptoms = <String>[];
    if (content.contains('dolor')) symptoms.add('dolor_estomacal');
    if (content.contains('ardor')) symptoms.add('ardor_estomacal');
    if (content.contains('náusea')) symptoms.add('nauseas');
    if (content.contains('hinchazón')) symptoms.add('hinchazon');
    return symptoms;
  }

  static List<String> _extractRiskFactors(String content) {
    final factors = <String>[];
    if (content.contains('estrés')) factors.add('estres');
    if (content.contains('picante')) factors.add('comida_picante');
    if (content.contains('alcohol')) factors.add('alcohol');
    if (content.contains('café')) factors.add('cafeina');
    return factors;
  }

  static List<String> _extractEatingHabits(String content) {
    final habits = <String>[];
    if (content.contains('rápido')) habits.add('comer_rapido');
    if (content.contains('tarde')) habits.add('comer_tarde');
    if (content.contains('picante')) habits.add('comida_picante');
    if (content.contains('grasa')) habits.add('comida_grasa');
    return habits;
  }

  static List<String> _extractHealthyHabits(String content) {
    final habits = <String>[];
    if (content.contains('agua')) habits.add('beber_agua');
    if (content.contains('ejercicio')) habits.add('hacer_ejercicio');
    if (content.contains('dormir')) habits.add('dormir_bien');
    if (content.contains('relajar')) habits.add('manejar_estres');
    return habits;
  }

  // Métodos para registrar en las tablas específicas
  static Future<void> _recordSymptomsKnowledge(
    String userId, 
    String sessionId, 
    Map<String, dynamic> data
  ) async {
    await _supabase.from('user_symptoms_knowledge').insert({
      'user_id': userId,
      'session_id': sessionId,
      'symptom_type': data['symptom_type'],
      'knowledge_level': data['knowledge_level'],
      'symptoms_mentioned': data['symptoms_mentioned'],
      'risk_factors_identified': data['risk_factors_identified'],
    });
  }

  static Future<void> _recordEatingHabits(
    String userId, 
    String sessionId, 
    Map<String, dynamic> data
  ) async {
    await _supabase.from('user_eating_habits').insert({
      'user_id': userId,
      'session_id': sessionId,
      'habit_type': data['habit_type'],
      'risk_level': data['risk_level'],
      'habits_identified': data['habits_identified'],
    });
  }

  static Future<void> _recordHealthyHabits(
    String userId, 
    String sessionId, 
    Map<String, dynamic> data
  ) async {
    await _supabase.from('user_healthy_habits').insert({
      'user_id': userId,
      'session_id': sessionId,
      'habit_category': data['habit_category'],
      'adoption_status': data['adoption_status'],
      'habits_adopted': data['habits_adopted'],
    });
  }

  static Future<void> _recordTechAcceptance(
    String userId, 
    String sessionId, 
    Map<String, dynamic> data
  ) async {
    await _supabase.from('user_tech_acceptance').insert({
      'user_id': userId,
      'session_id': sessionId,
      'tool_type': data['tool_type'],
      'acceptance_level': data['acceptance_level'],
      'usage_frequency': data['usage_frequency'],
      'feedback_sentiment': data['feedback_sentiment'],
    });
  }
}