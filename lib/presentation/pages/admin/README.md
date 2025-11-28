# Módulo de Administración - Vive Good App

## Descripción
El módulo de administración proporciona una interfaz completa para gestionar usuarios, roles, categorías, hábitos y generar reportes analíticos de la aplicación Vive Good.

## Estructura del Módulo

### Páginas Principales
- **AdminMainPage**: Página principal que incluye middleware de verificación de permisos
- **AdminDashboardPage**: Panel principal con navegación y estadísticas generales
- **AdminMantenedoresPage**: CRUD para usuarios, roles, categorías y hábitos
- **AdminIndicadoresPage**: KPIs y gráficos analíticos
- **AdminEvaluacionesPage**: Listado y gestión de evaluaciones de usuarios
- **AdminExportPage**: Exportación de datos a Excel

### Widgets Reutilizables
- **AdminNavigationRail**: Navegación lateral del módulo
- **KpiCard**: Tarjetas para mostrar indicadores clave
- **AdminDataTable**: Tabla de datos con paginación y filtros

### Arquitectura Clean
El módulo sigue los principios de Clean Architecture:

#### Domain Layer
- **Entidades**: AdminDashboardStats, UserEvaluation, TechAcceptanceIndicators, etc.
- **Repositorios**: AdminRepository (interfaz)
- **Casos de Uso**: GetAdminDashboardStatsUseCase, GetUserEvaluationsUseCase, etc.

#### Data Layer
- **Datasources**: AdminRemoteDataSource (integración con Supabase)
- **Repositorios**: AdminRepositoryImpl
- **Modelos**: AdminDashboardStatsModel, UserEvaluationModel

#### Presentation Layer
- **Providers**: AdminProvider (manejo de estado)
- **Páginas**: Todas las páginas del módulo
- **Widgets**: Componentes reutilizables
- **Middleware**: AdminMiddleware (verificación de permisos)

## Funcionalidades

### Dashboard
- Estadísticas generales de usuarios
- KPIs de engagement y actividad
- Resumen de evaluaciones y hábitos

### Mantenedores
- Gestión de usuarios y roles
- CRUD de categorías de hábitos
- Administración de hábitos disponibles

### Indicadores
- Gráficos de aceptación tecnológica
- Métricas de conocimiento de síntomas
- Indicadores de hábitos de riesgo
- Análisis de completitud de hábitos

### Evaluaciones
- Listado de evaluaciones de usuarios
- Filtros por rol y fechas
- Detalles de cada evaluación

### Exportación
- Reportes consolidados en Excel
- Exportación de datos de usuarios
- Reportes de aceptación tecnológica
- Datos de conocimiento de síntomas

## Stored Procedures Utilizados

El módulo se integra con los siguientes stored procedures de Supabase:

- `get_admin_dashboard_stats()`: Estadísticas del dashboard
- `get_admin_user_evaluations()`: Evaluaciones de usuarios
- `get_admin_tech_acceptance_indicators()`: Indicadores de aceptación tecnológica
- `get_admin_knowledge_symptoms_indicators()`: Conocimiento de síntomas
- `get_admin_risk_habits_indicators()`: Hábitos de riesgo
- `get_admin_users()`: Lista de usuarios
- `get_admin_categories()`: Categorías de hábitos
- `get_admin_habits()`: Hábitos disponibles
- `get_admin_consolidated_report()`: Reporte consolidado
- `check_admin_permissions()`: Verificación de permisos

## Seguridad

### Verificación de Permisos
- **AdminMiddleware**: Verifica permisos antes de acceder al módulo
- **Integración con AuthBloc**: Usa el sistema de autenticación existente
- **Verificación en Supabase**: Valida permisos de administrador en la base de datos

### Acceso Controlado
- Solo usuarios con rol de administrador pueden acceder
- Redirección automática si no se tienen permisos
- Manejo de errores de autenticación

## Navegación

### Rutas
- `/admin`: Ruta principal del módulo de administración

### Integración con App Router
El módulo se integra con el sistema de rutas existente usando GoRouter.

## Dependencias

### Nuevas Dependencias Agregadas
- `fl_chart`: Para gráficos y visualizaciones
- `excel`: Para exportación de datos
- `path_provider`: Para manejo de archivos
- `open_filex`: Para abrir archivos exportados

### Dependencias Existentes Utilizadas
- `provider`: Para manejo de estado
- `flutter_bloc`: Para autenticación
- `supabase_flutter`: Para integración con backend
- `go_router`: Para navegación

## Uso

### Acceso al Módulo
1. El usuario debe estar autenticado
2. Debe tener permisos de administrador
3. Navegar a `/admin` o usar el enlace correspondiente

### Navegación Interna
- Usar el AdminNavigationRail para cambiar entre secciones
- Cada sección tiene su propia funcionalidad específica

### Exportación de Datos
1. Ir a la sección "Exportar"
2. Seleccionar tipo de reporte
3. Configurar filtros (fechas, roles, etc.)
4. Hacer clic en "Exportar"
5. El archivo se guarda en la carpeta de Descargas

## Personalización

### Tema Visual
- Usa los colores del tema existente (azul #2196F3, naranja #FF9800)
- Mantiene consistencia con el diseño de la aplicación
- Responsive design para diferentes tamaños de pantalla

### Extensibilidad
- Fácil agregar nuevos tipos de reportes
- Estructura modular para nuevas funcionalidades
- Separación clara de responsabilidades

## Consideraciones Técnicas

### Performance
- Paginación en tablas de datos
- Carga lazy de datos pesados
- Cache de estadísticas frecuentes

### Manejo de Errores
- Validación de permisos
- Manejo de errores de red
- Feedback visual al usuario

### Mantenibilidad
- Código bien documentado
- Separación de responsabilidades
- Patrones de diseño consistentes