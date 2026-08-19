import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/agrovet_service.dart';

class AgrovetListScreen extends StatefulWidget {
  const AgrovetListScreen({super.key});
  @override
  State<AgrovetListScreen> createState() => _AgrovetListScreenState();
}

class _AgrovetListScreenState extends State<AgrovetListScreen> {
  List<dynamic> _agrovets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgrovets();
  }

  Future<void> _loadAgrovets() async {
    setState(() => _loading = true);
    final agrovets = await AgrovetService.listAgrovets();
    if (mounted) {
      setState(() {
        _agrovets = agrovets;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agrovets')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _agrovets.isEmpty
              ? const Center(child: Text('No agrovets found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _agrovets.length,
                  itemBuilder: (context, index) {
                    final agrovet = _agrovets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.warning.withOpacity(0.1),
                          child: Icon(Icons.store_rounded, color: AppColors.warning),
                        ),
                        title: Text(agrovet.businessName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${agrovet.county} • ${agrovet.phone ?? ''}'),
                        trailing: agrovet.verificationStatus == 'verified'
                            ? Icon(Icons.verified_rounded, color: AppColors.success, size: 20)
                            : null,
                        onTap: () => Navigator.pushNamed(context, '/agrovets/${agrovet.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
