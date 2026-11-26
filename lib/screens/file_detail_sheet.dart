import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';
import '../services/structure_generator.dart';
import '../theme/app_theme.dart';

class FileDetailSheet extends StatefulWidget {
  final CodeFile file;
  final StorageService storage;
  const FileDetailSheet({super.key, required this.file, required this.storage});
  @override
  State<FileDetailSheet> createState() => _FileDetailSheetState();
}

class _FileDetailSheetState extends State<FileDetailSheet> {
  late TextEditingController _desc;
  String? _category;
  String? _structure;
  bool _gen = false;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.file.description ?? '');
    _category = widget.file.category;
    _structure = widget.file.structure;
  }

  Future<void> _save() async {
    final updated = CodeFile(
      id: widget.file.id,
      name: widget.file.name,
      storedName: widget.file.storedName,
      category: (_category?.isEmpty ?? true) ? null : _category,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      structure: _structure,
      addedAt: widget.file.addedAt,
    );
    await widget.storage.updateFile(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Saved')));
      Navigator.pop(context);
    }
  }

  Future<void> _generate() async {
    setState(() => _gen = true);
    try {
      final content = await widget.storage.readContent(widget.file);
      final path = await widget.storage.absolutePath(widget.file);
      final result = await StructureGenerator.generate(widget.file, content, absolutePath: path);

      // ذخیره خودکار
      final updated = CodeFile(
        id: widget.file.id,
        name: widget.file.name,
        storedName: widget.file.storedName,
        category: widget.file.category,
        description: widget.file.description,
        structure: result,
        addedAt: widget.file.addedAt,
      );
      await widget.storage.updateFile(updated);

      setState(() {
        _structure = result;
        _gen = false;
      });
    } catch (e) {
      setState(() { _structure = '⚠️ $e'; _gen = false; });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        title: const Text('Delete file?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: AppTheme.accent))),
        ],
      ),
    );
    if (ok == true) {
      await widget.storage.deleteFile(widget.file);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.storage.categories;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text(widget.file.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Row(children: [
              Text(widget.file.extension.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Text(widget.file.addedAt.toIso8601String().substring(0, 10),
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]),
            const SizedBox(height: 22),

            const _Label('DESCRIPTION'),
            const SizedBox(height: 8),
            TextField(
              controller: _desc, minLines: 3, maxLines: 6,
              decoration: const InputDecoration(hintText: 'Write what this file is about…'),
            ),
            const SizedBox(height: 18),

            const _Label('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('None', _category == null || _category!.isEmpty, () => setState(() => _category = null)),
              ...cats.map((c) => _chip(c, _category == c, () => setState(() => _category = c))),
            ]),
            const SizedBox(height: 22),

            Row(children: [
              const _Label('FILE STRUCTURE'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _gen ? null : _generate,
                icon: _gen
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary))
                  : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(_gen ? 'Analyzing…' : 'Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary.withOpacity(0.15),
                  foregroundColor: AppTheme.secondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: _structure == null
                ? const Text('Tap "Generate" to auto-analyze this file.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textMuted, fontSize: 12))
                : SelectableText(_structure!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.55, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  final p = await widget.storage.absolutePath(widget.file);
                  await Clipboard.setData(ClipboardData(text: p));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Path copied')));
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Path'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accent, size: 16),
                label: const Text('Delete File', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? AppTheme.primary : Colors.transparent),
      ),
      child: Text(label, style: TextStyle(
        color: sel ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: FontWeight.w700, fontSize: 12,
      )),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppTheme.textMuted));
}
