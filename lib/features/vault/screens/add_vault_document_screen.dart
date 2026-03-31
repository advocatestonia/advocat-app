import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class AddVaultDocumentScreen extends StatelessWidget {
  const AddVaultDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Document')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Choose how to add your document',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xl),
              _OptionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Scan Document',
                subtitle: 'Take a photo of your document',
                color: AppColors.accent,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _OptionCard(
                icon: Icons.upload_file_outlined,
                title: 'Upload File',
                subtitle: 'Choose a PDF or image from your device',
                color: AppColors.info,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _OptionCard(
                icon: Icons.edit_document,
                title: 'Create Note',
                subtitle: 'Write a note or record important details',
                color: AppColors.warning,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
