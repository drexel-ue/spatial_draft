import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_painter.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_registry.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Modal dialog and bottom drawer to browse, search, and select procedural forms.
class FormLibrarySheet extends StatefulWidget {
  const FormLibrarySheet({
    super.key,
    required this.theme,
    required this.onSelectForm,
    this.initialSelectedId,
  });

  final AppThemeTokens theme;
  final ValueChanged<ProceduralFormId> onSelectForm;
  final ProceduralFormId? initialSelectedId;

  /// Convenience launcher for the form library dialog.
  static Future<void> show({
    required BuildContext context,
    required AppThemeTokens theme,
    required ValueChanged<ProceduralFormId> onSelectForm,
    ProceduralFormId? initialSelectedId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormLibrarySheet(
        theme: theme,
        onSelectForm: onSelectForm,
        initialSelectedId: initialSelectedId,
      ),
    );
  }

  @override
  State<FormLibrarySheet> createState() => _FormLibrarySheetState();
}

class _FormLibrarySheetState extends State<FormLibrarySheet> {
  final TextEditingController _searchController = TextEditingController();
  FormCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProceduralFormDefinition> _getFilteredForms() {
    var list = _searchQuery.isEmpty
        ? ProceduralFormRegistry.getAllDefinitions()
        : ProceduralFormRegistry.search(_searchQuery);

    if (_selectedCategory != null) {
      list = list.where((d) => d.category == _selectedCategory).toList();
    }
    return list;
  }

  int _countForCategory(FormCategory? category) {
    if (category == null) {
      return ProceduralFormRegistry.getAllDefinitions().length;
    }
    return ProceduralFormRegistry.getDefinitionsByCategory(category).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final filtered = _getFilteredForms();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.canvasBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.secondaryInk.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.borderHighlight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: theme.borderHighlight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROCEDURAL FORM & ANATOMY LIBRARY',
                        style: theme.headingStyle.copyWith(
                          fontSize: 16,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '23 Constructive Primitives, 3D Solids & Anatomical Masses',
                        style: theme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: theme.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.secondaryInk,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search Toolbar & Category Filter Rail
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.surfaceGlass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.bodyStyle.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search shapes (eye, hand, arm, cylinder)...',
                        hintStyle: theme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: theme.secondaryInk.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: theme.secondaryInk,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildCategoryChip(
                  label: 'All (${_countForCategory(null)})',
                  category: null,
                  theme: theme,
                ),
                ...FormCategory.values.map(
                  (cat) => _buildCategoryChip(
                    label: '${cat.label} (${_countForCategory(cat)})',
                    category: cat,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Forms Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 44,
                          color: theme.secondaryInk.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Procedural Forms Found',
                          style: theme.headingStyle.copyWith(
                            fontSize: 15,
                            color: theme.secondaryInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching for "eye", "arm", "cube", or "cylinder"',
                          style: theme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: theme.secondaryInk.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 270,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final def = filtered[index];
                      final isSelected =
                          widget.initialSelectedId == def.id;

                      return _FormCard(
                        definition: def,
                        theme: theme,
                        isSelected: isSelected,
                        onSelect: () {
                          widget.onSelectForm(def.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required FormCategory? category,
    required AppThemeTokens theme,
  }) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 11,
            color: isSelected ? Colors.white : theme.secondaryInk,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        backgroundColor: theme.surfaceGlass,
        selectedColor: theme.borderHighlight,
        showCheckmark: false,
        side: BorderSide(
          color: isSelected ? theme.borderHighlight : theme.borderSubtle,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.definition,
    required this.theme,
    required this.isSelected,
    required this.onSelect,
  });

  final ProceduralFormDefinition definition;
  final AppThemeTokens theme;
  final bool isSelected;
  final VoidCallback onSelect;

  Color _getDifficultyColor(String diff) {
    switch (diff) {
      case 'Foundational':
        return theme.accentCyan;
      case 'Intermediate':
        return theme.accentAmber;
      default:
        return const Color(0xFFA855F7); // Purple for Advanced
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _getDifficultyColor(definition.difficulty);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceGlass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.borderHighlight : theme.borderSubtle,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top badges (Category & Difficulty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.borderHighlight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        definition.category.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.monoStyle.copyWith(
                          fontSize: 8,
                          letterSpacing: 0.6,
                          color: theme.borderHighlight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      definition.difficulty.toUpperCase(),
                      style: theme.monoStyle.copyWith(
                        fontSize: 8,
                        letterSpacing: 0.6,
                        color: diffColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Vector Form Preview Canvas
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.canvasBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderSubtle.withOpacity(0.5),
                    ),
                  ),
                  child: CustomPaint(
                    painter: ProceduralFormPainter(
                      theme: theme,
                      formId: definition.id,
                      config: const ProceduralFormConfig(scale: 0.52),
                    ),
                  ),
                ),
              ),
            ),

            // Card Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.headingStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    definition.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyStyle.copyWith(
                      fontSize: 10,
                      color: theme.secondaryInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
