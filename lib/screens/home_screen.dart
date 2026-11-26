import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'import_screen.dart';
import 'structure_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _storage = StorageService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _storage.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [ImportScreen(), StructureScreen()],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Container(
            height: 62,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(children: [
              _nav(0, Icons.cloud_download_rounded, 'Import'),
              _nav(1, Icons.account_tree_rounded, 'Structure'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final sel = _index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? AppTheme.primary : AppTheme.textMuted, size: 22),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                color: sel ? AppTheme.primary : AppTheme.textMuted,
                fontWeight: FontWeight.w700, fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
