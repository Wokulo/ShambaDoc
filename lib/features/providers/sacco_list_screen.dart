import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/sacco_service.dart';

class SaccoListScreen extends StatefulWidget {
  const SaccoListScreen({super.key});
  @override
  State<SaccoListScreen> createState() => _SaccoListScreenState();
}

class _SaccoListScreenState extends State<SaccoListScreen> {
  List<dynamic> _saccos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaccos();
  }

  Future<void> _loadSaccos() async {
    setState(() => _loading = true);
    final saccos = await SaccoService.listSaccos();
    if (mounted) {
      setState(() {
        _saccos = saccos;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SACCOs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _saccos.isEmpty
              ? const Center(child: Text('No SACCOs found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _saccos.length,
                  itemBuilder: (context, index) {
                    final sacco = _saccos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.info.withOpacity(0.1),
                          child: Icon(Icons.account_balance_rounded, color: AppColors.info),
                        ),
                        title: Text(sacco.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${sacco.county} • ${sacco.phone ?? ''}'),
                        trailing: sacco.verificationStatus == 'verified'
                            ? Icon(Icons.verified_rounded, color: AppColors.success, size: 20)
                            : null,
                        onTap: () => Navigator.pushNamed(context, '/saccos/${sacco.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
