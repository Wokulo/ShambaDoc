import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await StorageService().getScanHistory();
    setState(() { _history = data; _isLoading = false; });
  }

  Future<void> _deleteScan(String id) async {
    await StorageService().deleteScan(id);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length,
                  itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No scans yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Your crop diagnoses will appear here', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ScanResult scan) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isHealthy = scan.disease.name.toLowerCase().contains('healthy');

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteScan(scan.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isHealthy ? Colors.green.shade100 : Colors.orange.shade100,
            child: Icon(isHealthy ? Icons.check : Icons.warning_amber,
              color: isHealthy ? Colors.green : Colors.orange),
          ),
          title: Text(scan.disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${scan.disease.cropType} - ${(scan.disease.confidence * 100).toStringAsFixed(1)}% confidence'),
              Text(dateFormat.format(scan.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (scan.farmNote != null) Text('Note: ${scan.farmNote}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }
}
