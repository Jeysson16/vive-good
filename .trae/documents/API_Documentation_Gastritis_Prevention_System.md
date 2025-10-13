# API Documentation - Sistema de Prevención de Gastritis

## Información General

**Título:** Sistema Gastritis CRISP-DL con Predicción de Hábitos  
**Versión:** 2.0.0  
**Base URL:** `https://api.jeysson.cloud`  
**Documentación Swagger:** `https://api.jeysson.cloud/docs`  

### Descripción
Sistema avanzado de prevención de gastritis con capacidades de:
- Chat interactivo con IA
- Análisis de secuencias de síntomas  
- Predicción de evolución de hábitos usando Deep Learning
- Autenticación y gestión de usuarios

**Nuevo:** Modelo LSTM + Attention para predicción de evolución de hábitos optimizado para Raspberry Pi con tiempo de respuesta <500ms.

---

## Autenticación

La API utiliza autenticación JWT (JSON Web Tokens). Para acceder a endpoints protegidos, incluye el token en el header:

```
Authorization: Bearer <your_jwt_token>
```

---

## Endpoints

### 1. Health Check

#### GET `/health`
**Descripción:** Verifica el estado general del sistema y todos sus componentes.

**Parámetros:** Ninguno

**Respuesta exitosa (200):**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15 10:30:00",
  "version": "2.0.0",
  "model_loaded": true,
  "uptime_seconds": 3600.5
}
```

**Códigos de respuesta:**
- `200`: Sistema funcionando correctamente
- `500`: Error interno del servidor

---

### 2. Autenticación

#### POST `/api/v1/auth/login`
**Descripción:** Autentica un usuario y devuelve un token JWT.

**Parámetros del cuerpo:**
```json
{
  "codigo_usuario": "string (1-50 caracteres)",
  "password": "string (6-100 caracteres)"
}
```

**Respuesta exitosa (200):**
```json
{
  "user": {
    "codigo_usuario": "user123",
    "email": "user@example.com",
    "nombre": "Usuario Ejemplo"
  },
  "token": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "refresh_token_here"
  },
  "message": "Login exitoso"
}
```

**Códigos de respuesta:**
- `200`: Login exitoso
- `401`: Credenciales inválidas
- `422`: Error de validación

#### POST `/api/v1/auth/register`
**Descripción:** Registra un nuevo usuario en el sistema.

**Parámetros del cuerpo:**
```json
{
  "codigo_usuario": "string (1-50 caracteres, alfanumérico con _ y -)",
  "email": "string (formato email válido)",
  "password": "string (mín. 6 caracteres, debe contener letra y número)",
  "nombre": "string (opcional, máx. 100 caracteres)"
}
```

**Respuesta exitosa (201):**
```json
{
  "user": {
    "codigo_usuario": "newuser123",
    "email": "newuser@example.com",
    "nombre": "Nuevo Usuario"
  },
  "token": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "expires_in": 3600
  },
  "message": "Usuario registrado exitosamente"
}
```

**Códigos de respuesta:**
- `201`: Usuario creado exitosamente
- `400`: Usuario ya existe
- `422`: Error de validación

#### GET `/api/v1/auth/me`
**Descripción:** Obtiene información del usuario autenticado.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Respuesta exitosa (200):**
```json
{
  "codigo_usuario": "user123",
  "email": "user@example.com",
  "nombre": "Usuario Ejemplo",
  "fecha_registro": "2024-01-01T00:00:00Z",
  "ultimo_acceso": "2024-01-15T10:30:00Z",
  "activo": true
}
```

#### POST `/api/v1/auth/refresh`
**Descripción:** Renueva el token de acceso usando el refresh token.

**Parámetros del cuerpo:**
```json
{
  "refresh_token": "string"
}
```

**Respuesta exitosa (200):**
```json
{
  "access_token": "new_jwt_token_here",
  "token_type": "bearer",
  "expires_in": 3600
}
```

---

### 3. Chat Interactivo

#### POST `/api/v1/chat/send`
**Descripción:** Envía un mensaje al sistema de chat y recibe una respuesta del bot.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros del cuerpo:**
```json
{
  "mensaje": "¿Qué alimentos debo evitar para prevenir la gastritis?",
  "codigo_sesion": "sess_abc123def456 (opcional)",
  "contexto": {
    "ubicacion": "casa",
    "hora_comida": "desayuno"
  },
  "intent": "consulta_alimentacion (opcional)",
  "entidades": {
    "alimentos": ["café", "picante"],
    "sintomas": ["dolor"]
  }
}
```

**Respuesta exitosa (200):**
```json
{
  "mensaje_id": "msg_abc123def456",
  "respuesta_bot": "Para prevenir la gastritis, te recomiendo evitar alimentos picantes, café y alcohol. Incluye más verduras y frutas en tu dieta.",
  "codigo_sesion": "sess_abc123def456",
  "timestamp": "2024-01-15T10:30:00Z",
  "intent_detectado": "consulta_alimentacion",
  "confianza": 0.95,
  "entidades": {
    "alimentos": ["café", "picante"],
    "sintomas": ["dolor"]
  }
}
```

#### POST `/api/v1/chat/session`
**Descripción:** Crea una nueva sesión de chat.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros del cuerpo:**
```json
{
  "codigo_usuario": "user123",
  "tipo_sesion": "general (opcional)",
  "configuracion": {
    "idioma": "es",
    "modo": "preventivo"
  }
}
```

**Respuesta exitosa (201):**
```json
{
  "sesion_id": "sess_abc123def456",
  "codigo_usuario": "user123",
  "estado": "activa",
  "fecha_inicio": "2024-01-15T10:30:00Z",
  "fecha_fin": null,
  "total_mensajes": 0,
  "configuracion": {
    "idioma": "es",
    "modo": "preventivo"
  }
}
```

#### GET `/api/v1/chat/history/{codigo_usuario}`
**Descripción:** Obtiene el historial de chat de un usuario.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `codigo_usuario`: Código del usuario

**Parámetros de consulta:**
- `limite`: Número máximo de mensajes (opcional, default: 50)
- `offset`: Número de mensajes a omitir (opcional, default: 0)

**Respuesta exitosa (200):**
```json
{
  "codigo_usuario": "user123",
  "mensajes": [
    {
      "id": "msg_123",
      "codigo_usuario": "user123",
      "sesion_id": "sess_456",
      "mensaje_usuario": "¿Cómo prevenir gastritis?",
      "respuesta_sistema": "Para prevenir gastritis...",
      "timestamp": "2024-01-15T10:30:00Z",
      "metadatos": {}
    }
  ],
  "total_mensajes": 1,
  "sesiones_activas": 1,
  "ultima_actividad": "2024-01-15T10:30:00Z"
}
```

#### PUT `/api/v1/chat/session/{codigo_sesion}/close`
**Descripción:** Cierra una sesión de chat activa.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `codigo_sesion`: Código de la sesión a cerrar

**Respuesta exitosa (200):**
```json
{
  "mensaje": "Sesión cerrada exitosamente",
  "sesion_id": "sess_abc123def456",
  "fecha_cierre": "2024-01-15T10:30:00Z"
}
```

#### GET `/api/v1/chat/sessions/{codigo_usuario}`
**Descripción:** Obtiene todas las sesiones de chat de un usuario.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `codigo_usuario`: Código del usuario

**Respuesta exitosa (200):**
```json
[
  {
    "sesion_id": "sess_abc123def456",
    "codigo_usuario": "user123",
    "estado": "activa",
    "fecha_inicio": "2024-01-15T10:30:00Z",
    "fecha_fin": null,
    "total_mensajes": 5,
    "configuracion": {}
  }
]
```

---

### 4. Análisis de Secuencias

#### POST `/api/v1/sequences/register`
**Descripción:** Registra una nueva secuencia numérica para análisis.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros del cuerpo:**
```json
{
  "codigo_usuario": "user123",
  "secuencia": [0.2, 0.5, 0.3, 0.8, 0.6],
  "tipo_secuencia": "habitos",
  "metadata": {
    "periodo": "semanal",
    "unidad": "porciones",
    "categoria": "verduras"
  }
}
```

**Validaciones:**
- `secuencia`: Valores entre 0.0 y 1.0, máximo 100 elementos
- `tipo_secuencia`: Debe ser uno de: "habitos", "horarios", "estres", "sintomas"

**Respuesta exitosa (201):**
```json
{
  "secuencia_id": "seq_abc123def456",
  "codigo_usuario": "user123",
  "tipo_secuencia": "habitos",
  "fecha_registro": "2024-01-15T10:30:00Z",
  "procesada": true,
  "mensaje": "Secuencia de hábitos registrada exitosamente"
}
```

#### POST `/api/v1/sequences/analyze`
**Descripción:** Analiza una secuencia registrada usando el modelo de deep learning.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros del cuerpo:**
```json
{
  "secuencia_id": "seq_abc123def456",
  "forzar_reanalisis": false,
  "contexto_usuario": {
    "edad": 30,
    "nivel_actividad": "medio"
  }
}
```

**Respuesta exitosa (200):**
```json
{
  "secuencia_id": "seq_abc123def456",
  "resultado": {
    "patron_detectado": "tendencia_positiva",
    "puntuacion_riesgo": 0.3,
    "prediccion_proximos_dias": [0.7, 0.8, 0.6]
  },
  "confianza": 0.85,
  "recomendaciones": [
    "Mantener la tendencia positiva",
    "Incrementar actividad los fines de semana"
  ],
  "timestamp_analisis": "2024-01-15T10:30:00Z",
  "estado": "completado"
}
```

#### GET `/api/v1/sequences/history/{codigo_usuario}`
**Descripción:** Obtiene el historial de secuencias de un usuario.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `codigo_usuario`: Código del usuario

**Parámetros de consulta:**
- `pagina`: Número de página (opcional, default: 1)
- `limite`: Elementos por página (opcional, default: 20)
- `tipo`: Filtrar por tipo de secuencia (opcional)

**Respuesta exitosa (200):**
```json
{
  "secuencias": [
    {
      "secuencia_id": "seq_123",
      "tipo_secuencia": "habitos",
      "fecha_registro": "2024-01-15T10:30:00Z",
      "procesada": true,
      "resultado_analisis": {}
    }
  ],
  "total": 1,
  "pagina": 1,
  "limite": 20,
  "tiene_mas": false
}
```

#### GET `/api/v1/sequences/stats/{codigo_usuario}`
**Descripción:** Obtiene estadísticas de secuencias de un usuario.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Respuesta exitosa (200):**
```json
{
  "total_secuencias": 10,
  "secuencias_por_tipo": {
    "habitos": 4,
    "sintomas": 3,
    "estres": 2,
    "horarios": 1
  },
  "promedio_puntuacion_riesgo": 0.4,
  "tendencia_general": "mejorando"
}
```

#### DELETE `/api/v1/sequences/sequence/{secuencia_id}`
**Descripción:** Elimina una secuencia específica.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `secuencia_id`: ID de la secuencia a eliminar

**Respuesta exitosa (200):**
```json
{
  "mensaje": "Secuencia eliminada exitosamente",
  "secuencia_id": "seq_abc123def456"
}
```

#### GET `/api/v1/sequences/sequence/{secuencia_id}`
**Descripción:** Obtiene detalles de una secuencia específica.

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros de ruta:**
- `secuencia_id`: ID de la secuencia

**Respuesta exitosa (200):**
```json
{
  "secuencia_id": "seq_abc123def456",
  "codigo_usuario": "user123",
  "secuencia": [0.2, 0.5, 0.3, 0.8, 0.6],
  "tipo_secuencia": "habitos",
  "metadata": {},
  "fecha_registro": "2024-01-15T10:30:00Z",
  "resultado_analisis": {},
  "estado": "procesada"
}
```

---

### 5. Predicción de Evolución de Hábitos

#### POST `/api/v1/predict/habit-evolution`
**Descripción:** Predice la evolución futura de un hábito usando un modelo de deep learning LSTM + Attention.

**Características del modelo:**
- Arquitectura: Embedding → LSTM(128) → Attention → Dense(64) → Multiple Outputs
- Optimizado para Raspberry Pi con quantización y caching
- Tiempo de respuesta objetivo: <500ms
- Métricas: MAPE <15% (7 días), Accuracy >80% tendencias

**Headers requeridos:**
```
Authorization: Bearer <jwt_token>
```

**Parámetros del cuerpo:**
```json
{
  "user_id": "user_12345",
  "habit_id": "habit_exercise_001",
  "habit_name": "Ejercicio matutino",
  "habit_type": "exercise",
  "history": [
    {
      "date": "2024-01-01",
      "completed": true,
      "consistency_score": 85.0,
      "duration_minutes": 30,
      "intensity": 7,
      "mood_before": 6,
      "mood_after": 8,
      "energy_level": 7,
      "sleep_hours": 7.5,
      "stress_level": 4,
      "motivation": 8,
      "social_support": 6,
      "environmental_factors": 7,
      "time_of_day": 14,
      "weather_score": 8,
      "habit_streak": 5,
      "completion_rate": 0.85,
      "habit_type_id": 3,
      "weather_id": 2
    }
  ],
  "user_profile": {
    "age": 28,
    "activity_level": "high",
    "timezone": "America/Mexico_City",
    "goals": ["perder_peso", "mejorar_salud"]
  },
  "contextual_factors": {
    "season": "winter",
    "work_schedule": "flexible",
    "life_events": ["mudanza", "nuevo_trabajo"],
    "support_system": "high"
  },
  "prediction_horizon_days": 30,
  "include_recommendations": true,
  "include_insights": true
}
```

**Validaciones:**
- `history`: Mínimo 7 días de datos (recomendado: 30+ días)
- `prediction_horizon_days`: Entre 7 y 90 días
- Fechas del historial deben estar en orden cronológico
- Valores numéricos deben estar en rangos válidos

**Respuesta exitosa (200):**
```json
{
  "user_id": "user_12345",
  "habit_id": "habit_exercise_001",
  "habit_name": "Ejercicio matutino",
  "prediction_horizon_days": 30,
  "predictions": [
    {
      "date": "2024-02-15",
      "completion_probability": 0.85,
      "confidence_interval_lower": 0.75,
      "confidence_interval_upper": 0.95,
      "predicted_consistency_score": 82.5,
      "risk_factors": ["alto_estres"],
      "protective_factors": ["alta_motivacion", "apoyo_social"]
    }
  ],
  "trend_analysis": {
    "trend_direction": "improving",
    "trend_strength": 0.7,
    "trend_confidence": 0.85,
    "seasonal_patterns": ["mejor_mananas", "dificil_fines_semana"],
    "critical_periods": ["dias_14-21", "inicio_mes"]
  },
  "insights": {
    "completion_rate_current": 0.75,
    "completion_rate_predicted": 0.82,
    "streak_current": 5,
    "streak_predicted_max": 12,
    "best_performance_days": ["monday", "tuesday", "wednesday"],
    "challenging_days": ["friday", "saturday"],
    "key_success_factors": ["sueno_adecuado", "baja_estres", "alta_motivacion"],
    "improvement_areas": ["consistencia_fines_semana", "manejo_estres"]
  },
  "recommendations": [
    {
      "type": "timing",
      "title": "Optimiza tu horario de ejercicio",
      "description": "Basado en tu historial, tienes mayor éxito ejercitándote entre las 7-9 AM",
      "priority": "high",
      "confidence": 0.9,
      "actionable_steps": [
        "Configura alarma para 6:45 AM",
        "Prepara ropa la noche anterior"
      ]
    }
  ],
  "model_metrics": {
    "model_version": "v1.2.3",
    "prediction_accuracy": 0.87,
    "mape_7_days": 12.5,
    "confidence_calibration": 0.92,
    "processing_time_ms": 245.7,
    "data_quality_score": 0.95
  },
  "generated_at": "2024-01-15T10:30:00Z",
  "expires_at": "2024-01-16T10:30:00Z"
}
```

**Códigos de respuesta:**
- `200`: Predicción exitosa
- `400`: Datos de entrada inválidos (ej: historial insuficiente)
- `422`: Error de validación de esquema
- `500`: Error interno del servidor

#### GET `/api/v1/predict/habit-evolution/health`
**Descripción:** Health check específico para el servicio de predicción de hábitos.

**Respuesta exitosa (200):**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_optimized": true,
  "cache_size": 150,
  "performance_status": "optimal",
  "validation_time_ms": 45.2,
  "system_metrics": {
    "memory_usage_mb": 512.3,
    "cpu_usage_percent": 15.2
  },
  "performance_metrics": {
    "avg_prediction_time_ms": 234.5,
    "cache_hit_rate": 0.85
  },
  "edge_optimization": {
    "quantization_enabled": true,
    "model_size_mb": 12.5
  },
  "raspberry_pi_config": {
    "optimized_for_pi": true,
    "memory_limit_mb": 1024
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## Códigos de Estado HTTP

### Códigos de Éxito
- `200 OK`: Solicitud exitosa
- `201 Created`: Recurso creado exitosamente

### Códigos de Error del Cliente
- `400 Bad Request`: Solicitud malformada o datos inválidos
- `401 Unauthorized`: Token de autenticación requerido o inválido
- `403 Forbidden`: Acceso denegado
- `404 Not Found`: Recurso no encontrado
- `422 Unprocessable Entity`: Error de validación de datos

### Códigos de Error del Servidor
- `500 Internal Server Error`: Error interno del servidor
- `503 Service Unavailable`: Servicio temporalmente no disponible

---

## Límites y Restricciones

### Límites de Rate Limiting
- **Requests por minuto:** 100 por usuario autenticado
- **Requests por hora:** 1000 por usuario autenticado

### Límites de Datos
- **Tamaño máximo del cuerpo:** 10MB
- **Secuencias:** Máximo 100 elementos por secuencia
- **Historial de hábitos:** Máximo 365 días
- **Horizonte de predicción:** Máximo 90 días

### Timeouts
- **Timeout de conexión:** 30 segundos
- **Timeout de respuesta:** 60 segundos
- **Predicción de hábitos:** Objetivo <500ms

---

## Ejemplos de Uso

### Flujo Completo: Registro, Chat y Predicción

```bash
# 1. Registrar usuario
curl -X POST "https://api.jeysson.cloud/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_usuario": "usuario_ejemplo",
    "email": "usuario@ejemplo.com",
    "password": "password123",
    "nombre": "Usuario Ejemplo"
  }'

# 2. Iniciar sesión de chat
curl -X POST "https://api.jeysson.cloud/api/v1/chat/session" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_usuario": "usuario_ejemplo",
    "tipo_sesion": "general"
  }'

# 3. Enviar mensaje
curl -X POST "https://api.jeysson.cloud/api/v1/chat/send" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "mensaje": "¿Cómo puedo mejorar mis hábitos alimentarios?",
    "codigo_sesion": "sess_abc123"
  }'

# 4. Registrar secuencia de hábitos
curl -X POST "https://api.jeysson.cloud/api/v1/sequences/register" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_usuario": "usuario_ejemplo",
    "secuencia": [0.8, 0.7, 0.9, 0.6, 0.8, 0.9, 0.7],
    "tipo_secuencia": "habitos",
    "metadata": {
      "categoria": "alimentacion",
      "periodo": "semanal"
    }
  }'

# 5. Predecir evolución de hábito
curl -X POST "https://api.jeysson.cloud/api/v1/predict/habit-evolution" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "usuario_ejemplo",
    "habit_id": "habito_alimentacion_001",
    "habit_name": "Alimentación saludable",
    "habit_type": "nutrition",
    "history": [
      {
        "date": "2024-01-01",
        "completed": true,
        "consistency_score": 80.0,
        "duration_minutes": 60,
        "intensity": 6
      }
    ],
    "prediction_horizon_days": 14
  }'
```

---

## Soporte y Contacto

Para soporte técnico o preguntas sobre la API:

- **Documentación interactiva:** `https://api.jeysson.cloud/docs`
- **Health check:** `https://api.jeysson.cloud/health`
- **Versión actual:** 2.0.0

---

## Changelog

### v2.0.0 (Actual)
- ✅ Nuevo endpoint de predicción de evolución de hábitos
- ✅ Modelo LSTM + Attention optimizado para Raspberry Pi
- ✅ Mejoras en el sistema de chat interactivo
- ✅ Análisis avanzado de secuencias

### v1.0.0
- ✅ Sistema básico de chat
- ✅ Autenticación JWT
- ✅ Análisis de secuencias básico