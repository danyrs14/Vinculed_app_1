import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';

class RequisitosColumn extends StatelessWidget {
  const RequisitosColumn({
    super.key,
    required this.titulo,
    required this.seleccionados,
    required this.options,
    required this.onAdd,
    required this.onRemove,
  });

  final String titulo;
  final List<String> seleccionados;
  final List<String> options;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 6),

        // Bandeja gris (seleccionados)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFB7C6CF), // gris azulado como en la imagen
            borderRadius: BorderRadius.circular(6),
          ),
          child: seleccionados.isEmpty
              ? const Text(
            'Sin requisitos agregados',
            style: TextStyle(color: Colors.black54),
          )
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seleccionados
                .map(
                  (e) => _chipFilled(
                label: e,
                onDelete: () => onRemove(e),
              ),
            )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Opciones en chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (o) => InputChip(
              label: Text(o),
              onPressed: () => onAdd(o),
              side: const BorderSide(color: Colors.black38),
              selectedColor: theme.background(),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget _chipFilled({required String label, required VoidCallback onDelete}) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFF97AAB6),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
