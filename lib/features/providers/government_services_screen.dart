import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/government_service.dart';

class GovernmentServicesScreen extends StatefulWidget {
  const GovernmentServicesScreen({super.key});
  @override
  State<GovernmentServicesScreen> createState() => _GovernmentServicesScreenState();
}

class _GovernmentServicesScreenState extends State<GovernmentServicesScreen> {
  List<dynamic> _officers = [];
  List<dynamic> _programs = [];
  List<dynamic> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final officers = await GovernmentService.listOfficers();
    final programs = await GovernmentService.getPrograms();
    final events = await GovernmentService.getEvents();
    if (mounted) {
      setState(() {
        _officers = officers;
        _programs = programs;
        _events = events;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Agriculture')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3 + _officers.length + _programs.length + _events.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _Section(title: 'Agricultural Officers', children: _officers.map((o) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.info.withOpacity(0.1),
                        child: Icon(Icons.badge_rounded, color: AppColors.info),
                      ),
                      title: Text(o.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${o.designation} • ${o.county}'),
                      trailing: o.verificationStatus == 'verified'
                          ? Icon(Icons.verified_rounded, color: AppColors.success, size: 20)
                          : null,
                    );
                  }).toList());
                }
                if (index == 1 + _officers.length) {
                  return _Section(title: 'Programs', children: _programs.map((p) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(p.description),
                      ),
                    );
                  }).toList());
                }
                if (index == 2 + _officers.length + _programs.length) {
                  return _Section(title: 'Upcoming Events', children: _events.map((e) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${e.eventType} • ${e.county}'),
                        trailing: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList());
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
