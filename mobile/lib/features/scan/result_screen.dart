import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/widgets/disease_card.dart';
import 'package:shambadoc/widgets/treatment_card.dart';
import 'package:shambadoc/app/routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final ScanResult? scan = args?['scan'];
    final File? image = args?['image'];

    if (scan == null) {
      return const Scaffold(body: Center(child: Text('No result data')));
    }

    final disease = scan.disease;
    final isHealthy = disease.name.toLowerCase().contains('healthy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHealthy ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle : Icons.warning,
                    color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHealthy ? 'Crop appears healthy' : 'Disease detected: ${disease.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _ConfidenceGuidanceCard(disease: disease),
            const SizedBox(height: 16),

            DiseaseCard(disease: disease),
            const SizedBox(height: 16),

            if (!isHealthy) TreatmentCard(disease: disease),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.map),
                    icon: const Icon(Icons.map),
                    label: const Text('Find Agro-Dealer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _showFeedbackDialog(context, scan),
                child: const Text('Was this diagnosis correct?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, ScanResult scan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Feedback'),
        content: const Text('Help us improve ShambaDoc. Was this diagnosis accurate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceGuidanceCard extends StatelessWidget {
  final DiseaseModel disease;

  const _ConfidenceGuidanceCard({required this.disease});

  @override
  Widget build(BuildContext context) {
    final tier = disease.confidenceTier;
    final severity = disease.severity;
    final tierColor = switch (tier) {
      'high' => Colors.green,
      'uncertain' => Colors.orange,
      _ => Colors.red,
    };
    final severityColor = switch (severity) {
      'early' => Colors.green,
      'moderate' => Colors.orange,
      _ => Colors.red,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.psychology, size: 18, color: tierColor),
                  label: Text('${tier[0].toUpperCase()}${tier.substring(1)} confidence'),
                  backgroundColor: tierColor.shade50,
                  side: BorderSide(color: tierColor.shade200),
                ),
                Chip(
                  avatar: Icon(Icons.priority_high, size: 18, color: severityColor),
                  label: Text('${severity[0].toUpperCase()}${severity.substring(1)} severity'),
                  backgroundColor: severityColor.shade50,
                  side: BorderSide(color: severityColor.shade200),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(disease.confidenceGuidance, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
