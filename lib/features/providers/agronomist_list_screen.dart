import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/agronomist_service.dart';

class AgronomistListScreen extends StatefulWidget {
  const AgronomistListScreen({super.key});
  @override
  State<AgronomistListScreen> createState() => _AgronomistListScreenState();
}

class _AgronomistListScreenState extends State<AgronomistListScreen> {
  List<dynamic> _agronomists = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String? _selectedCounty;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAgronomists();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAgronomists() async {
    setState(() => _loading = true);
    final agronomists = await AgronomistService.listAgronomists(county: _selectedCounty);
    if (mounted) {
      setState(() {
        _agronomists = agronomists;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verified Agronomists')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or specialization...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                        _searchController.clear();
                        _loadAgronomists();
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                  if (v.isEmpty) _loadAgronomists();
                });
              },
              onSubmitted: (v) => _loadAgronomists(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _agronomists.isEmpty
                    ? const Center(child: Text('No agronomists found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _agronomists.length,
                        itemBuilder: (context, index) {
                          final ag = _agronomists[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Icon(Icons.person_rounded, color: AppColors.primary),
                              ),
                              title: Text(ag.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${ag.professionalTitle ?? ''} • ${ag.county}'),
                              trailing: ag.verificationStatus == 'verified'
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                          const SizedBox(width: 4),
                                          Text('Verified', style: TextStyle(fontSize: 11, color: AppColors.success)),
                                        ],
                                      ),
                                    )
                                  : null,
                              onTap: () => Navigator.pushNamed(context, '/agronomists/${ag.id}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
