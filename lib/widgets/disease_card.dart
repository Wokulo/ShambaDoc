import 'package:flutter/material.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/app/theme.dart';

class DiseaseCard extends StatelessWidget {
  final DiseaseModel disease;
  const DiseaseCard({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    final isHealthy = disease.name.toLowerCase().contains('healthy');
    final pct = (disease.confidence * 100).toStringAsFixed(1);
    final tierColor = switch (disease.confidenceTier) {
      'high'      => AppColors.success,
      'uncertain' => AppColors.warning,
      _           => AppColors.error,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: (isHealthy ? AppColors.healthy : AppColors.diseased)
                .withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.bug_report_rounded,
              color: isHealthy ? AppColors.healthy : AppColors.diseased,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(disease.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scientific name
              if (disease.scientificName.isNotEmpty) ...[
                Text(disease.scientificName,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  )),
                const SizedBox(height: 12),
              ],

              // Confidence bar
              Row(children: [
                const Text('Confidence',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
                const Spacer(),
                Text('$pct%',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: tierColor)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: disease.confidence,
                  minHeight: 7,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(tierColor),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              Text(disease.description,
                style: const TextStyle(
                    fontSize: 14, height: 1.55,
                    color: AppColors.textPrimary)),
              const SizedBox(height: 14),

              // Chips row
              Wrap(spacing: 8, runSpacing: 8, children: [
                _InfoChip(
                  icon: Icons.grass_rounded,
                  label: disease.cropType,
                  color: AppColors.primary,
                ),
                _InfoChip(
                  icon: Icons.priority_high_rounded,
                  label: '${disease.severity[0].toUpperCase()}'
                      '${disease.severity.substring(1)} severity',
                  color: switch (disease.severity) {
                    'early'    => AppColors.success,
                    'moderate' => AppColors.warning,
                    _          => AppColors.error,
                  },
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label,
        style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
