import 'package:flutter/material.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'file_detail_sheet.dart';

class StructureScreen extends StatefulWidget {
  const StructureScreen({super.key});
  @override
  State<StructureScreen> createState() => _StructureScreenState();
}

class _StructureScreenState extends State<StructureScreen> {
  final _storage = StorageService();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final files = _storage.files.where((f) {
      if (_q.isEmpty) return true;
      final s = _q.toLowerCase();
      return f.name.toLowerCase().contains(s) ||
             (f.description?.toLowerCase().contains(s) ?? false) ||
             (f.category?.toLowerCase().contains(s) ?? false);
    }).toList();

    final grouped = <String, List<CodeFile>>{};
    for (final f in files) {
      final k = (f.category == null || f.category!.isEmpty) ? 'Uncategorized' : f.category!;
      grouped.putIfAbsent(k, () => []).add(f);
    }
    final keys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Structure')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Search files, categories…',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
            ),
          ),
        ),
        Expanded(
          child: files.isEmpty
            ? _empty()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: keys.map((k) => _section(k, grouped[k]!)).toList(),
              ),
        ),
      ]),
    );
  }

  Widget _section(String cat, List<CodeFile> files) {
    final isUncat = cat == 'Uncategorized';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          iconColor: AppTheme.primary,
          collapsedIconColor: AppTheme.textMuted,
          title: Row(children: [
            Icon(Icons.folder_rounded, color: isUncat ? AppTheme.textMuted : AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.surfaceHigh, borderRadius: BorderRadius.circular(8)),
              child: Text('${files.length}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          children: files.map(_fileRow).toList(),
        ),
      ),
    );
  }

  Widget _fileRow(CodeFile f) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(f),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.insert_drive_file_rounded, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                if (f.description != null && f.description!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2),
                    child: Text(f.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primary),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _open(CodeFile f) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FileDetailSheet(file: f, storage: _storage),
    );
    setState(() {});
  }

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.account_tree_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.6)),
    const SizedBox(height: 16),
    const Text('No files to display', style: TextStyle(color: AppTheme.textSecondary)),
  ]));
}
