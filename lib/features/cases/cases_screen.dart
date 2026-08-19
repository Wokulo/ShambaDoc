import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/case_service.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  List<dynamic> _cases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _loading = true);
    final cases = await CaseService.listCases(myCases: true);
    if (mounted) {
      setState(() {
        _cases = cases;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in_review':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? const Center(child: Text('No cases yet. Create one from a diagnosis.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) {
                    final c = _cases[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Case #${c.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(c.farmerNote ?? 'No notes'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(c.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.status.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: _statusColor(c.status), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
