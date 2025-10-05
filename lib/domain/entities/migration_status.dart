/// Entidad que representa el estado de las migraciones de base de datos
class MigrationStatus {
  final bool conversationsTableExists;
  final bool symptomsKnowledgeTableExists;
  final bool eatingHabitsTableExists;
  final bool healthyHabitsTableExists;
  final bool techAcceptanceTableExists;
  final Map<String, int> tableColumnCounts;
  final List<String> missingTables;
  final List<String> missingColumns;
  final bool allMigrationsApplied;

  const MigrationStatus({
    required this.conversationsTableExists,
    required this.symptomsKnowledgeTableExists,
    required this.eatingHabitsTableExists,
    required this.healthyHabitsTableExists,
    required this.techAcceptanceTableExists,
    required this.tableColumnCounts,
    required this.missingTables,
    required this.missingColumns,
    required this.allMigrationsApplied,
  });

  /// Crea un estado de migración exitoso
  factory MigrationStatus.success() {
    return const MigrationStatus(
      conversationsTableExists: true,
      symptomsKnowledgeTableExists: true,
      eatingHabitsTableExists: true,
      healthyHabitsTableExists: true,
      techAcceptanceTableExists: true,
      tableColumnCounts: {},
      missingTables: [],
      missingColumns: [],
      allMigrationsApplied: true,
    );
  }

  /// Crea un estado de migración fallido
  factory MigrationStatus.failed({
    required List<String> missingTables,
    required List<String> missingColumns,
  }) {
    return MigrationStatus(
      conversationsTableExists: false,
      symptomsKnowledgeTableExists: false,
      eatingHabitsTableExists: false,
      healthyHabitsTableExists: false,
      techAcceptanceTableExists: false,
      tableColumnCounts: const {},
      missingTables: missingTables,
      missingColumns: missingColumns,
      allMigrationsApplied: false,
    );
  }

  @override
  String toString() {
    return 'MigrationStatus(allMigrationsApplied: $allMigrationsApplied, '
           'missingTables: $missingTables, missingColumns: $missingColumns)';
  }
}

/// Entidad que representa información de una columna de tabla
class TableColumn {
  final String columnName;
  final String dataType;
  final bool isNullable;

  const TableColumn({
    required this.columnName,
    required this.dataType,
    required this.isNullable,
  });

  factory TableColumn.fromMap(Map<String, dynamic> map) {
    return TableColumn(
      columnName: map['column_name'] as String,
      dataType: map['data_type'] as String,
      isNullable: map['is_nullable'] == 'YES',
    );
  }

  @override
  String toString() {
    return 'TableColumn(columnName: $columnName, dataType: $dataType, isNullable: $isNullable)';
  }
}