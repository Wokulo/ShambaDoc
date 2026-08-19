import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/models/farmer_models.dart';
import 'package:shambadoc/services/api/farmer_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});
  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  FarmerProfile? _profile;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _countyController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;
  String _selectedCounty = 'Kiambu';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _countyController = TextEditingController();
    _phoneController = TextEditingController();
    _experienceController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countyController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await FarmerService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
        if (profile != null) {
          _nameController.text = profile.fullName;
          _countyController.text = profile.county;
          _phoneController.text = profile.phoneNumber ?? '';
          _experienceController.text = profile.farmingExperienceYears?.toString() ?? '';
          _selectedCounty = profile.county;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = await FarmerService.upsertProfile(
      fullName: _nameController.text.trim(),
      county: _selectedCounty,
      subCounty: _countyController.text.trim().isEmpty ? null : _countyController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      farmingExperienceYears: int.tryParse(_experienceController.text.trim()),
    );
    if (mounted) {
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded, size: 60, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCounty,
                      decoration: const InputDecoration(
                        labelText: 'County',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Kiambu', child: Text('Kiambu')),
                        DropdownMenuItem(value: 'Nakuru', child: Text('Nakuru')),
                        DropdownMenuItem(value: 'Kisumu', child: Text('Kisumu')),
                        DropdownMenuItem(value: 'Nairobi', child: Text('Nairobi')),
                        DropdownMenuItem(value: 'Mombasa', child: Text('Mombasa')),
                        DropdownMenuItem(value: 'Eldoret', child: Text('Eldoret')),
                      ],
                      onChanged: (v) => setState(() => _selectedCounty = v ?? _selectedCounty),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countyController,
                      decoration: const InputDecoration(
                        labelText: 'Sub-County (optional)',
                        prefixIcon: Icon(Icons.place_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Farming Experience (years)',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
