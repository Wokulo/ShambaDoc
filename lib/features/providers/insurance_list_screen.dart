import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/insurance_service.dart';

class InsuranceListScreen extends StatefulWidget {
  const InsuranceListScreen({super.key});
  @override
  State<InsuranceListScreen> createState() => _InsuranceListScreenState();
}

class _InsuranceListScreenState extends State<InsuranceListScreen> {
  List<dynamic> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    final providers = await InsuranceService.listProviders();
    if (mounted) {
      setState(() {
        _providers = providers;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Providers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? const Center(child: Text('No insurance providers found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.error.withOpacity(0.1),
                          child: Icon(Icons.shield_rounded, color: AppColors.error),
                        ),
                        title: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${provider.county} • ${provider.phone ?? ''}'),
                        trailing: provider.verificationStatus == 'verified'
                            ? Icon(Icons.verified_rounded, color: AppColors.success, size: 20)
                            : null,
                        onTap: () => Navigator.pushNamed(context, '/insurance/${provider.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
