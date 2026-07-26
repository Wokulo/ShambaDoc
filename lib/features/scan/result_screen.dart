import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shambadoc/ai/disease_model.dart';
import 'package:shambadoc/app/routes.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api_service.dart';
import 'package:shambadoc/widgets/disease_card.dart';
import 'package:shambadoc/widgets/treatment_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final ScanResult? scan = args?['scan'];
    final File? image = args?['image'];

    if (scan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result data available.')),
      );
    }

    final disease = scan.disease;
    final isHealthy = disease.name.toLowerCase().contains('healthy');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        // Hero image app bar
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (_) => false),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share',
              onPressed: () => _share(scan, image),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Diagnosis Result',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            background: image != null
                ? Stack(fit: StackFit.expand, children: [
                    Image.file(image, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ])
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        size: 80, color: Colors.white24),
                  ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status banner
              _StatusBanner(isHealthy: isHealthy, disease: disease),
              const SizedBox(height: 16),

              // Confidence & severity chips
              _ConfidenceCard(disease: disease),
              const SizedBox(height: 16),

              // Disease details
              DiseaseCard(disease: disease),
              const SizedBox(height: 16),

              // Treatment (only if diseased)
              if (!isHealthy) ...[
                TreatmentCard(disease: disease),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.map),
                    icon: const Icon(Icons.store_rounded, size: 18),
                    label: const Text('Find Dealer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.scan),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Scan Again'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Feedback
              Center(
                child: TextButton.icon(
                  onPressed: () => _showFeedback(context, scan),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Was this diagnosis correct?'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  void _share(ScanResult scan, File? image) {
    final text = '''
ShambaDoc Diagnosis Report
Disease: ${scan.disease.name}
Crop: ${scan.disease.cropType}
Confidence: ${(scan.disease.confidence * 100).toStringAsFixed(1)}%
Treatment: ${scan.disease.treatment}
Scanned: ${scan.timestamp.toLocal()}
''';
    if (image != null) {
      Share.shareXFiles([XFile(image.path)], text: text);
    } else {
      Share.share(text);
    }
  }

  void _showFeedback(BuildContext context, ScanResult scan) {
    String? correction;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Was this diagnosis correct?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your feedback helps improve ShambaDoc for all farmers.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Correct disease name (optional)',
              hintText: 'e.g. Late Blight',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            onChanged: (v) => correction = v,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.submitFeedback(
                      scanId: scan.id, wasCorrect: false,
                      correctDisease: correction);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Thanks for your feedback!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Incorrect'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.submitFeedback(
                      scanId: scan.id, wasCorrect: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Thanks for your feedback!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Correct'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isHealthy;
  final DiseaseModel disease;
  const _StatusBanner({required this.isHealthy, required this.disease});

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.healthy : AppColors.diseased;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(
            isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHealthy ? 'Crop Appears Healthy' : 'Disease Detected',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(
              isHealthy
                  ? 'Continue standard agronomic practices.'
                  : disease.name,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

// ── Confidence Card ───────────────────────────────────────────────────────────

class _ConfidenceCard extends StatelessWidget {
  final DiseaseModel disease;
  const _ConfidenceCard({required this.disease});

  @override
  Widget build(BuildContext context) {
    final tier = disease.confidenceTier;
    final severity = disease.severity;

    final tierColor = switch (tier) {
      'high'      => AppColors.success,
      'uncertain' => AppColors.warning,
      _           => AppColors.error,
    };
    final sevColor = switch (severity) {
      'early'    => AppColors.success,
      'moderate' => AppColors.warning,
      _          => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress bar
        Row(children: [
          const Text('AI Confidence',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Text('${(disease.confidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: tierColor, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: disease.confidence,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(tierColor),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(
            icon: Icons.psychology_rounded,
            label: '${tier[0].toUpperCase()}${tier.substring(1)} confidence',
            color: tierColor,
          ),
          _Chip(
            icon: Icons.priority_high_rounded,
            label: '${severity[0].toUpperCase()}${severity.substring(1)} severity',
            color: sevColor,
          ),
        ]),
        const SizedBox(height: 12),
        Text(disease.confidenceGuidance,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.45)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
