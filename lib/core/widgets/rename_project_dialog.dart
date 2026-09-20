import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Modal dialog for naming or renaming a spatial drafting project.
class RenameProjectDialog extends StatefulWidget {
  /// Creates a [RenameProjectDialog].
  const RenameProjectDialog({
    super.key,
    required this.currentTitle,
    required this.theme,
    this.dialogTitle = 'Rename Project',
  });

  /// The existing project title to edit.
  final String currentTitle;

  /// Active theme tokens.
  final AppThemeTokens theme;

  /// Header title for the dialog.
  final String dialogTitle;

  /// Convenience show method returning the new title or null if cancelled.
  static Future<String?> show({
    required BuildContext context,
    required String currentTitle,
    required AppThemeTokens theme,
    String dialogTitle = 'Rename Project',
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => RenameProjectDialog(
        currentTitle: currentTitle,
        theme: theme,
        dialogTitle: dialogTitle,
      ),
    );
  }

  @override
  State<RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<RenameProjectDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      Navigator.of(context).pop(trimmed);
    }
  }

  void _appendTag(String tag) {
    final current = _controller.text.trim();
    final newText = current.isEmpty ? tag : '$current - $tag';
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newText.length);
    setState(() {});
  }

  String _getTodayTag() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AlertDialog(
      backgroundColor: theme.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.borderSubtle, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.borderHighlight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: theme.borderHighlight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.dialogTitle,
            style: theme.headingStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give this draft a clear, memorable engineering or study name.',
              style: theme.bodyStyle.copyWith(
                fontSize: 13,
                color: theme.secondaryInk,
              ),
            ),
            const SizedBox(height: 16),

            // Text Input
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: theme.bodyStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.defaultInk,
              ),
              cursorColor: theme.borderHighlight,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.canvasBackground,
                hintText: 'Enter project title...',
                hintStyle: TextStyle(
                  color: theme.secondaryInk.withOpacity(0.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (ctx, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    );
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.borderHighlight,
                    width: 1.8,
                  ),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Quick Tag Suggestions
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTagChip(
                  '+ ${_getTodayTag()}',
                  () => _appendTag(_getTodayTag()),
                ),
                _buildTagChip('+ Study', () => _appendTag('Study')),
                _buildTagChip('+ Assembly', () => _appendTag('Assembly')),
                _buildTagChip('+ Voxel', () => _appendTag('Voxel')),
                _buildTagChip('+ Rev A', () => _appendTag('Rev A')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (ctx, value, _) {
            final isValid = value.text.trim().isNotEmpty;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.borderHighlight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: isValid ? _submit : null,
              child: Text(
                'Save Name',
                style: theme.headingStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagChip(String label, VoidCallback onTap) {
    final theme = widget.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.borderSubtle.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderSubtle),
        ),
        child: Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 11,
            color: theme.secondaryInk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
