import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../models/code_file.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _storage = StorageService();

  Future<void> _pickAndImport() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.any);
      if (r == null || r.files.single.path == null) return;
      final path = r.files.single.path!;

      // کپی مسیر در کلیپ‌بورد
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📋 Path copied to clipboard'),
        duration: Duration(seconds: 2),
      ));

      if (!mounted) return;
      await _showImportSheet(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ $e')));
    }
  }

  Future<void> _showImportSheet(String srcPath) async {
    final descCtrl = TextEditingController();
    String? category;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text('Import File', style: Theme.of(ctx).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(p.basename(srcPath), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                TextField(
                  controller: descCtrl,
                  minLines: 2, maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this file about?',
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _chip('None', category == null, () => setSt(() => category = null)),
                    ..._storage.categories.map((c) => _chip(c, category == c, () => setSt(() => category = c))),
                    _chip('+ New', false, () async {
                      final name = await _promptNewCategory(ctx);
                      if (name != null && name.isNotEmpty) {
                        setSt(() => category = name);
                      }
                    }, accent: true),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _storage.importFile(srcPath,
                          category: category,
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save to Vault', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && mounted) setState(() {});
  }

  Future<String?> _promptNewCategory(BuildContext ctx) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (c2) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        title: const Text('New Category'),
        content: TextField(controller: c, autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Hacking, Defense, HTML…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c2, c.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap, {bool accent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppTheme.primary : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
          color: sel ? AppTheme.primary : (accent ? AppTheme.secondary : AppTheme.textSecondary),
          fontWeight: FontWeight.w700, fontSize: 12,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = _storage.files;
    return Scaffold(
      appBar: AppBar(title: const Text('CodeVault')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _hero(),
          const SizedBox(height: 26),
          if (files.isEmpty) _empty() else ...[
            Row(children: [
              const Text('Recent Imports', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const Spacer(),
              Text('${files.length} file${files.length == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...files.take(8).map(_fileTile),
          ],
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B7CFF), Color(0xFF00E0B8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 38),
          const SizedBox(height: 16),
          const Text('Import a File', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
          const SizedBox(height: 6),
          Text('Pick any file — path is copied automatically.',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickAndImport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Choose File', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.6)),
        const SizedBox(height: 16),
        const Text('No files yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _fileTile(CodeFile f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        _icon(f.extension),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
          if (f.category != null && f.category!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(f.category!, style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700))),
          if (f.description != null && f.description!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(f.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        ])),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textMuted),
          onPressed: () async {
            final pth = await _storage.absolutePath(f);
            await Clipboard.setData(ClipboardData(text: pth));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Path copied')));
          },
        ),
      ]),
    );
  }

  Widget _icon(String ext) {
    IconData icon = Icons.insert_drive_file_rounded;
    Color c = AppTheme.textMuted;
    switch (ext) {
      case 'py': icon = Icons.code_rounded; c = const Color(0xFF3D7EAA); break;
      case 'js': case 'ts': case 'jsx': case 'tsx': icon = Icons.javascript_rounded; c = const Color(0xFFF7DF1E); break;
      case 'html': case 'htm': icon = Icons.html_rounded; c = const Color(0xFFE34F26); break;
      case 'css': icon = Icons.css_rounded; c = const Color(0xFF1572B6); break;
      case 'zip': icon = Icons.folder_zip_rounded; c = AppTheme.warn; break;
      case 'json': icon = Icons.data_object_rounded; c = AppTheme.secondary; break;
      case 'md': icon = Icons.article_rounded; c = AppTheme.textPrimary; break;
      case 'pdf': icon = Icons.picture_as_pdf_rounded; c = AppTheme.accent; break;
      case 'sh': icon = Icons.terminal_rounded; c = AppTheme.secondary; break;
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: c, size: 22),
    );
  }
}
