import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.headline,
    required this.studentInfo,
    required this.skills,
    this.onTap,
  });

  final String imageAsset;
  final String name;
  final String headline;
  final String studentInfo;
  final String skills;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen superior
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nombre
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),

        // Headline (puesto)
        Text(headline, style: const TextStyle(color: Colors.black87)),
        const SizedBox(height: 10),

        // Detalles
        _detailRow('Estudiante:', studentInfo),
        const SizedBox(height: 6),
        _detailRow('Habilidades:', skills),
      ],
    );

    final card = Container(
      decoration: BoxDecoration(
        color: theme.background(),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: content,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
