import 'package:flutter/material.dart';

class AdminDataTable<T> extends StatelessWidget {
  final List<T> data;
  final List<AdminDataColumn<T>> columns;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final Widget? emptyWidget;
  final bool showCheckboxColumn;
  final List<T>? selectedItems;
  final ValueChanged<List<T>>? onSelectionChanged;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int>? onSort;

  const AdminDataTable({
    super.key,
    required this.data,
    required this.columns,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.emptyWidget,
    this.showCheckboxColumn = false,
    this.selectedItems,
    this.onSelectionChanged,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          showCheckboxColumn: showCheckboxColumn,
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: columns.map((column) {
            return DataColumn(
              label: Text(
                column.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: column.sortable && onSort != null
                  ? (columnIndex, ascending) => onSort!(columnIndex)
                  : null,
            );
          }).toList(),
          rows: data.map((item) {
            final isSelected = selectedItems?.contains(item) ?? false;
            return DataRow(
              selected: isSelected,
              onSelectChanged: showCheckboxColumn && onSelectionChanged != null
                  ? (selected) {
                      final newSelection = List<T>.from(selectedItems ?? []);
                      if (selected == true) {
                        newSelection.add(item);
                      } else {
                        newSelection.remove(item);
                      }
                      onSelectionChanged!(newSelection);
                    }
                  : null,
              cells: columns.map((column) {
                return DataCell(
                  column.cellBuilder(item),
                  onTap: column.onTap != null ? () => column.onTap!(item) : null,
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class AdminDataColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final bool sortable;
  final void Function(T item)? onTap;

  const AdminDataColumn({
    required this.label,
    required this.cellBuilder,
    this.sortable = false,
    this.onTap,
  });
}

class AdminTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final void Function(int?)? onItemsPerPageChanged;
  final List<int> availableItemsPerPage;

  const AdminTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.availableItemsPerPage = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          if (onItemsPerPageChanged != null) ...[
            Text(
              'Elementos por página:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: itemsPerPage,
              onChanged: onItemsPerPageChanged,
              items: availableItemsPerPage.map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            'Mostrando ${(currentPage * itemsPerPage) + 1}-${((currentPage + 1) * itemsPerPage).clamp(0, totalItems)} de $totalItems',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          IconButton(
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Página anterior',
          ),
          Text(
            '${currentPage + 1} de $totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Página siguiente',
          ),
        ],
      ),
    );
  }
}