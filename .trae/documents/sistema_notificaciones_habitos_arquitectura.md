# Sistema de Notificaciones de Hábitos Diarios - Arquitectura Técnica

## 1. Architecture design

```mermaid
graph TD
    A[User Interface] --> B[Notification BLoC]
    B --> C[Notification Use Cases]
    C --> D[Notification Repository]
    D --> E[Local Notification Service]
    D --> F[Notification Local Repository]
    E --> G[Flutter Local Notifications]
    F --> H[Hive Database]
    
    C --> I[Habit Repository]
    I --> J[Habit Local Repository]
    J --> H
    
    D --> K[Sync Service]
    K --> L[Connectivity Service]
    
    subgraph "Presentation Layer"
        A
        B
    end
    
    subgraph "Domain Layer"
        C
    end
    
    subgraph "Data Layer"
        D
        E
        F
        I
        J
        K
    end
    
    subgraph "External Services"
        G
        H
        L
    end
```

## 2. Technology Description

- Frontend: Flutter con arquitectura BLoC para gestión de estado
- Notificaciones Locales: flutter_local_notifications@17.0.0
- Base de Datos Local: Hive (ya implementado)
- Programación de Tareas: timezone@0.9.0 para manejo de zonas horarias
- Arquitectura: Clean Architecture con patrón Repository

## 3. Route definitions

| Route | Purpose |
|-------|---------|
| /notifications/settings | Configuración general de notificaciones y permisos |
| /habits/:id/notifications | Configuración específica de notificaciones para un hábito |
| /notifications/schedule | Vista de horarios programados y gestión de recordatorios |
| /notifications/history | Historial de notificaciones enviadas y estadísticas |

## 4. API definitions

### 4.1 Core API

**Casos de Uso de Notificaciones**

```typescript
// Programar notificación de hábito
ScheduleHabitNotificationUseCase
```

Request:
| Param Name | Param Type | isRequired | Description |
|------------|------------|------------|-------------|
| userHabitId | String | true | ID del hábito del usuario |
| scheduledTime | DateTime | true | Hora programada para la notificación |
| message | String | false | Mensaje personalizado (opcional) |

Response:
| Param Name | Param Type | Description |
|------------|------------|-------------|
| notificationId | String | ID único de la notificación programada |
| success | boolean | Estado de la operación |

```typescript
// Cancelar notificación de hábito
CancelHabitNotificationUseCase
```

Request:
| Param Name | Param Type | isRequired | Description |
|------------|------------|------------|-------------|
| notificationId | String | true | ID de la notificación a cancelar |

Response:
| Param Name | Param Type | Description |
|------------|------------|-------------|
| success | boolean | Estado de la operación |

```typescript
// Obtener notificaciones pendientes
GetPendingNotificationsUseCase
```

Response:
| Param Name | Param Type | Description |
|------------|------------|-------------|
| notifications | List<HabitNotification> | Lista de notificaciones programadas |

```typescript
// Configurar recordatorio con snooze
SnoozeNotificationUseCase
```

Request:
| Param Name | Param Type | isRequired | Description |
|------------|------------|------------|-------------|
| notificationId | String | true | ID de la notificación |
| snoozeMinutes | int | true | Minutos para posponer (5, 15, 30, 60) |

## 5. Server architecture diagram

```mermaid
graph TD
    A[Notification Controller] --> B[Notification Service Layer]
    B --> C[Habit Service Layer]
    B --> D[Local Storage Repository]
    C --> E[Habit Repository]
    D --> F[Notification Local Repository]
    E --> G[Habit Local Repository]
    F --> H[(Hive - Notifications)]
    G --> I[(Hive - Habits)]
    
    B --> J[Platform Services]
    J --> K[Flutter Local Notifications]
    J --> L[Android Notification Manager]
    J --> M[iOS User Notifications]
    
    subgraph "Service Layer"
        B
        C
    end
    
    subgraph "Repository Layer"
        D
        E
        F
        G
    end
    
    subgraph "Storage Layer"
        H
        I
    end
    
    subgraph "Platform Layer"
        K
        L
        M
    end
```

## 6. Data model

### 6.1 Data model definition

```mermaid
erDiagram
    HABIT_NOTIFICATION ||--|| USER_HABIT : belongs_to
    HABIT_NOTIFICATION ||--o{ NOTIFICATION_SCHEDULE : has_many
    USER_HABIT ||--|| HABIT : references
    NOTIFICATION_SCHEDULE ||--o{ NOTIFICATION_LOG : generates
    
    HABIT_NOTIFICATION {
        string id PK
        string user_habit_id FK
        string title
        string message
        boolean is_enabled
        string notification_sound
        datetime created_at
        datetime updated_at
    }
    
    NOTIFICATION_SCHEDULE {
        string id PK
        string habit_notification_id FK
        string day_of_week
        time scheduled_time
        boolean is_active
        int snooze_count
        datetime last_triggered
    }
    
    NOTIFICATION_LOG {
        string id PK
        string notification_schedule_id FK
        datetime scheduled_for
        datetime sent_at
        string status
        string action_taken
        datetime created_at
    }
    
    USER_HABIT {
        string id PK
        string user_id
        string habit_id FK
        string frequency
        time scheduled_time
        boolean notifications_enabled
        datetime start_date
        datetime end_date
    }
    
    HABIT {
        string id PK
        string name
        string description
        string category_id
        string icon_name
        string icon_color
    }
```

### 6.2 Data Definition Language

**Tabla de Notificaciones de Hábitos (habit_notifications)**
```dart
// Hive TypeAdapter para HabitNotification
@HiveType(typeId: 10)
class HabitNotificationLocalModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userHabitId;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  String? message;
  
  @HiveField(4)
  bool isEnabled;
  
  @HiveField(5)
  String? notificationSound;
  
  @HiveField(6)
  List<NotificationScheduleLocalModel> schedules;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime updatedAt;
  
  @HiveField(9)
  bool isSynced;
}
```

**Tabla de Horarios de Notificación (notification_schedules)**
```dart
// Hive TypeAdapter para NotificationSchedule
@HiveType(typeId: 11)
class NotificationScheduleLocalModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String habitNotificationId;
  
  @HiveField(2)
  String dayOfWeek; // 'monday', 'tuesday', etc. o 'daily'
  
  @HiveField(3)
  String scheduledTime; // HH:mm format
  
  @HiveField(4)
  bool isActive;
  
  @HiveField(5)
  int snoozeCount;
  
  @HiveField(6)
  DateTime? lastTriggered;
  
  @HiveField(7)
  int platformNotificationId; // ID usado por flutter_local_notifications
}
```

**Tabla de Log de Notificaciones (notification_logs)**
```dart
// Hive TypeAdapter para NotificationLog
@HiveType(typeId: 12)
class NotificationLogLocalModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String notificationScheduleId;
  
  @HiveField(2)
  DateTime scheduledFor;
  
  @HiveField(3)
  DateTime? sentAt;
  
  @HiveField(4)
  String status; // 'scheduled', 'sent', 'failed', 'cancelled'
  
  @HiveField(5)
  String? actionTaken; // 'completed', 'snoozed', 'dismissed', 'ignored'
  
  @HiveField(6)
  DateTime createdAt;
}
```

**Configuración de Permisos y Preferencias**
```dart
// Configuración global de notificaciones
@HiveType(typeId: 13)
class NotificationSettingsLocalModel extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  bool globalNotificationsEnabled;
  
  @HiveField(2)
  bool permissionsGranted;
  
  @HiveField(3)
  String? quietHoursStart; // HH:mm
  
  @HiveField(4)
  String? quietHoursEnd; // HH:mm
  
  @HiveField(5)
  int defaultSnoozeMinutes;
  
  @HiveField(6)
  int maxSnoozeCount;
  
  @HiveField(7)
  String defaultNotificationSound;
  
  @HiveField(8)
  DateTime updatedAt;
}
```

**Inicialización de Datos**
```dart
// Configuración por defecto para nuevos usuarios
final defaultSettings = NotificationSettingsLocalModel(
  userId: currentUserId,
  globalNotificationsEnabled: true,
  permissionsGranted: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  defaultSnoozeMinutes: 15,
  maxSnoozeCount: 3,
  defaultNotificationSound: 'default',
  updatedAt: DateTime.now(),
);

// Programación automática para hábitos existentes
for (final userHabit in existingHabits) {
  if (userHabit.notificationsEnabled && userHabit.scheduledTime != null) {
    await createDefaultNotificationSchedule(userHabit);
  }
}
```