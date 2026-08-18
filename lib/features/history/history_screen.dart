import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/app/routes.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _all = [];
  List<ScanResult> _filtered = [];
  bool _loading = true;
  String _filter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  static const _filters = ['All', 'Diseased', 'Healthy'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await StorageService().getScanHistory();
    setState(() {
      _all = data;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((s) {
        final matchFilter = _filter == 'All' ||
            (_filter == 'Healthy' &&
                s.disease.name.toLowerCase().contains('healthy')) ||
            (_filter == 'Diseased' &&
                !s.disease.name.toLowerCase().contains('healthy'));
        final matchQuery = _query.isEmpty ||
            s.disease.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.disease.cropType.toLowerCase().contains(_query.toLowerCase());
        return matchFilter && matchQuery;
      }).toList();
    });
  }

  Future<void> _delete(String id) async {
    await StorageService().deleteScan(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Scan History')),
      body: Column(children: [
        if (widget.embedded)
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16, bottom: 12,
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Scan History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _query = v;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: 'Search disease or crop…',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        _query = '';
                        _applyFilter();
                      })
                  : null,
            ),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: _filters.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) {
                  _filter = f;
                  _applyFilter();
                },
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider),
              ),
            );
          }).toList()),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? _EmptyState(hasScans: _all.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _HistoryCard(
                              scan: _filtered[i],
                              onDelete: () => _delete(_filtered[i].id),
                              onTap: () => Navigator.pushNamed(
                                context, AppRoutes.result,
                                arguments: {
                                  'scan': _filtered[i],
                                  'image': File(_filtered[i].imagePath),
                                },
                              ),
                            ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasScans;
  const _EmptyState({required this.hasScans});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(hasScans ? Icons.search_off_rounded : Icons.folder_open_rounded,
          size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(
        hasScans ? 'No results match your filter' : 'No scans yet',
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text(
        hasScans
            ? 'Try a different filter or search term.'
            : 'Your crop diagnoses will appear here.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      if (!hasScans) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
          label: const Text('Scan a Crop'),
        ),
      ],
    ]),
  );
}

class _HistoryCard extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _HistoryCard(
      {required this.scan, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHealthy = scan.disease.name.toLowerCase().contains('healthy');
    final color = isHealthy ? AppColors.healthy : AppColors.diseased;
    final fmt = DateFormat('dd MMM yyyy • HH:mm');

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Scan'),
            content: const Text('Remove this scan from history?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border.fromBorderSide(
                BorderSide(color: AppColors.divider)),
          ),
          child: Row(children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 80, height: 80,
                child: File(scan.imagePath).existsSync()
                    ? Image.file(File(scan.imagePath), fit: BoxFit.cover)
                    : Container(
                        color: color.withOpacity(0.1),
                        child: Icon(
                          isHealthy
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color: color, size: 32),
                      ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan.disease.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(scan.disease.cropType,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _Badge(
                        label:
                            '${(scan.disease.confidence * 100).toStringAsFixed(0)}%',
                        color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(fmt.format(scan.timestamp),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
      style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}
