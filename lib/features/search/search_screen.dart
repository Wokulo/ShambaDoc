import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Services')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search agronomists, agrovets, diseases...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
                            _controller.clear();
                            setState(() => _results = []);
                          })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() {}),
                  onSubmitted: (v) => _performSearch(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', selected: _selectedType == null, onTap: () {
                        setState(() => _selectedType = null);
                        if (_controller.text.isNotEmpty) _performSearch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Agronomist', selected: _selectedType == 'agronomist', onTap: () {
                        setState(() => _selectedType = 'agronomist');
                        if (_controller.text.isNotEmpty) _performSearch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Agrovet', selected: _selectedType == 'agrovet', onTap: () {
                        setState(() => _selectedType = 'agrovet');
                        if (_controller.text.isNotEmpty) _performSearch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'SACCO', selected: _selectedType == 'sacco', onTap: () {
                        setState(() => _selectedType = 'sacco');
                        if (_controller.text.isNotEmpty) _performSearch();
                      }),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Insurance', selected: _selectedType == 'insurance', onTap: () {
                        setState(() => _selectedType = 'insurance');
                        if (_controller.text.isNotEmpty) _performSearch();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(child: Text(_controller.text.isEmpty ? 'Enter a search query' : 'No results found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Icon(Icons.search_rounded, color: AppColors.primary),
                              ),
                              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${r.type.toUpperCase()} • ${r.county ?? ''}'),
                              trailing: r.verificationStatus == 'verified'
                                  ? Icon(Icons.verified_rounded, color: AppColors.success, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final results = await SearchService.searchServices(
      query: _controller.text.trim(),
      type: _selectedType,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.12),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
    );
  }
}
