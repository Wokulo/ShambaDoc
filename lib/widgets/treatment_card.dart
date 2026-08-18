import 'package:flutter/material.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/app/theme.dart';

class TreatmentCard extends StatelessWidget {
  final DiseaseModel disease;
  const TreatmentCard({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.healing_rounded,
                  color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Recommended Treatment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Treatment text
            Text(disease.treatment,
              style: const TextStyle(
                  fontSize: 14, height: 1.6, color: AppColors.textPrimary)),

            // Dosage box
            if (disease.dosage.isNotEmpty && disease.dosage != 'N/A') ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.science_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dosage / Application',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 13, color: AppColors.accent)),
                      const SizedBox(height: 4),
                      Text(disease.dosage,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary,
                            height: 1.45)),
                    ],
                  )),
                ]),
              ),
            ],

            const SizedBox(height: 14),

            // Organic / Chemical badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: disease.isOrganic
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: disease.isOrganic
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  disease.isOrganic ? Icons.eco_rounded : Icons.warning_rounded,
                  size: 16,
                  color: disease.isOrganic ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  disease.isOrganic
                      ? 'Organic / Biological Treatment'
                      : 'Chemical Treatment — Wear PPE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: disease.isOrganic ? AppColors.success : AppColors.warning,
                  ),
                ),
              ]),
            ),

            // PPE reminder for chemical
            if (!disease.isOrganic) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Always read the label. Use gloves, mask and protective clothing.',
                      style: TextStyle(fontSize: 12,
                          color: AppColors.info, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
