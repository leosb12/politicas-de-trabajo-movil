import 'package:flutter/material.dart';

enum TramiteFilter { todos, gratis, paga }

class TramitesSearchBar extends StatefulWidget {
  const TramitesSearchBar({
    super.key,
    required this.onQueryChanged,
    this.onFilterChanged,
    this.showFilters = true,
  });

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TramiteFilter>? onFilterChanged;
  final bool showFilters;

  @override
  State<TramitesSearchBar> createState() => _TramitesSearchBarState();
}

class _TramitesSearchBarState extends State<TramitesSearchBar> {
  TramiteFilter _currentFilter = TramiteFilter.todos;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar trámite...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          ),
          onChanged: widget.onQueryChanged,
        ),
        if (widget.showFilters) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', TramiteFilter.todos),
                const SizedBox(width: 8),
                _buildFilterChip('Gratis', TramiteFilter.gratis),
                const SizedBox(width: 8),
                _buildFilterChip('De paga', TramiteFilter.paga),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, TramiteFilter filter) {
    final bool isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
          widget.onFilterChanged?.call(filter);
        }
      },
    );
  }
}
