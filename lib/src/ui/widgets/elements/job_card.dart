import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';

class JobItem {
  final String title;
  final String location;
  final String company;

  const JobItem({
    required this.title,
    required this.location,
    required this.company,
  });
}

class JobCard extends StatefulWidget {
  const JobCard({
    super.key,
    required this.item,
    this.onApply,
    this.onSave,
    this.onHide,
  });

  final JobItem item;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final VoidCallback? onHide;

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      decoration: BoxDecoration(
        color: theme.background(),
        border: Border.all(color: theme.secundario(), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            widget.item.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.item.location,
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            widget.item.company,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Acciones
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => isSaved = !isSaved);
                  if (widget.onSave != null) widget.onSave!();
                },
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? theme.secundario() : Colors.black54,
                ),
                tooltip: 'Guardar',
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: SimpleButton(
                  onTap: widget.onApply,
                  title: 'Postularme',
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onHide,
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: 'Ocultar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JobsGrid extends StatelessWidget {
  const JobsGrid({super.key, required this.items, this.onApply, this.onSave, this.onHide});

  final List<JobItem> items;
  final void Function(JobItem item)? onApply;
  final void Function(JobItem item)? onSave;
  final void Function(JobItem item)? onHide;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double cardWidth = w < 420 ? w - 48 : 340.0;

    return Wrap(
      spacing: 28,
      runSpacing: 28,
      alignment: WrapAlignment.spaceBetween,
      children: [
        for (final e in items)
          ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: cardWidth),
            child: JobCard(
              item: e,
              onApply: onApply == null ? null : () => onApply!(e),
              onSave: onSave == null ? null : () => onSave!(e),
              onHide: onHide == null ? null : () => onHide!(e),
            ),
          ),
      ],
    );
  }
}
