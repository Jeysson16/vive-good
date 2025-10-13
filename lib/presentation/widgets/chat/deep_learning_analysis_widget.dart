import 'package:flutter/material.dart';

/// Widget para mostrar el análisis de Deep Learning
class DeepLearningAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const DeepLearningAnalysisWidget({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis.isEmpty) return const SizedBox.shrink();

    // Extraer datos del análisis de manera más robusta
    final riskAssessment = analysis['risk_assessment'] as Map<String, dynamic>?;
    final suggestedActions = analysis['suggested_actions'] as List?;
    final confidenceScore = analysis['confidence_score'] ?? analysis['confidence'];
    final respuestaModelo = analysis['respuesta_modelo'] as String?;

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 56, right: 48),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              const Text(
                '🤖',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis Inteligente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Respuesta del modelo si está disponible
          if (respuestaModelo != null && respuestaModelo.isNotEmpty) ...[
            _buildModelResponse(respuestaModelo),
            const SizedBox(height: 12),
          ],
          
          // Nivel de riesgo desde risk_assessment
          if (riskAssessment != null && riskAssessment['level'] != null) ...[
            _buildRiskLevel(riskAssessment['level']),
            const SizedBox(height: 8),
          ],
          
          // Confianza
          if (confidenceScore != null) ...[
            _buildConfidence(confidenceScore),
            const SizedBox(height: 8),
          ],
          
          // Factores de riesgo
          if (riskAssessment != null && riskAssessment['factors'] != null) ...[
            _buildRiskFactors(riskAssessment['factors']),
            const SizedBox(height: 8),
          ],
          
          // Recomendaciones desde suggested_actions o recommendations
          if (suggestedActions != null && suggestedActions.isNotEmpty) ...[
            _buildRecommendations(suggestedActions),
          ] else if (riskAssessment != null && riskAssessment['recommendations'] != null) ...[
            _buildRecommendations(riskAssessment['recommendations']),
          ],
        ],
      ),
    );
  }

  Widget _buildModelResponse(String response) {
    // Limpiar la respuesta del modelo de datos técnicos
    String cleanResponse = response;
    
    // Si la respuesta contiene solo el texto del modelo, extraerlo
    if (response.contains('Riesgo bajo de gastritis') || 
        response.contains('Riesgo medio de gastritis') || 
        response.contains('Riesgo alto de gastritis')) {
      cleanResponse = response;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        cleanResponse,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF333333),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRiskFactors(dynamic factors) {
    List<String> factorList = [];
    if (factors is List) {
      factorList = factors.cast<String>();
    }
    
    if (factorList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Factores identificados:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...factorList.map((factor) => Padding(
          padding: const EdgeInsets.only(left: 24, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              Expanded(
                child: Text(
                  factor,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRiskLevel(dynamic riskLevel) {
    String level = riskLevel.toString();
    Color color;
    String emoji;
    
    switch (level.toLowerCase()) {
      case 'low':
        color = Colors.green;
        emoji = '🟢';
        level = 'Bajo';
        break;
      case 'medium':
        color = Colors.orange;
        emoji = '🟡';
        level = 'Medio';
        break;
      case 'high':
        color = Colors.red;
        emoji = '🔴';
        level = 'Alto';
        break;
      case 'critical':
        color = Colors.red.shade800;
        emoji = '🚨';
        level = 'Crítico';
        break;
      default:
        color = Colors.grey;
        emoji = '⚪';
        level = 'No determinado';
    }

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          'Nivel de riesgo: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          level,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidence(dynamic confidence) {
    double conf = 0.0;
    if (confidence is num) {
      conf = confidence.toDouble();
    }
    
    return Row(
      children: [
        const Icon(
          Icons.analytics,
          size: 16,
          color: Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Text(
          'Confianza: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${(conf * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(dynamic recommendations) {
    List<String> recs = [];
    if (recommendations is List) {
      recs = recommendations.cast<String>();
    }
    
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.lightbulb,
              size: 16,
              color: Color(0xFF666666),
            ),
            SizedBox(width: 8),
            Text(
              'Recomendaciones:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...recs.map((rec) => Padding(
          padding: const EdgeInsets.only(left: 24, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              Expanded(
                child: Text(
                  rec,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}