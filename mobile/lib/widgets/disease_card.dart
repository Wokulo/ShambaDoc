import 'package:flutter/material.dart';
import 'package:shambadoc/ai/disease_model.dart';

class DiseaseCard extends StatelessWidget {
  final DiseaseModel disease;

  const DiseaseCard({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (disease.confidence * 100).toStringAsFixed(1);
    final isHighConfidence = disease.confidence >= 0.85;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHighConfidence ? Icons.verified : Icons.help_outline,
                  color: isHighConfidence ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disease.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (disease.scientificName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                disease.scientificName,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: disease.confidence,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                isHighConfidence ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text('AI Confidence: $confidencePercent%'),
            const SizedBox(height: 12),
            Text(
              disease.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(disease.cropType),
              backgroundColor: Colors.green.shade50,
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }
}
