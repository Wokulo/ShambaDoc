import 'package:flutter/material.dart';
import 'package:shambadoc/ai/disease_model.dart';

class TreatmentCard extends StatelessWidget {
  final DiseaseModel disease;

  const TreatmentCard({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Recommended Treatment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              disease.treatment,
              style: const TextStyle(height: 1.6, fontSize: 15),
            ),
            if (disease.dosage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dosage / Application',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(disease.dosage),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (disease.isOrganic)
              Chip(
                avatar: const Icon(Icons.eco, size: 18, color: Colors.green),
                label: const Text('Organic / Biological'),
                backgroundColor: Colors.green.shade100,
              )
            else
              Chip(
                avatar: const Icon(Icons.warning, size: 18, color: Colors.orange),
                label: const Text('Chemical Treatment - Follow PPE'),
                backgroundColor: Colors.orange.shade100,
              ),
          ],
        ),
      ),
    );
  }
}
