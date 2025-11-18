import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vinculed_app_1/src/core/providers/user_provider.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/habilidades_multi_dropdown.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/perfilAlumno/habilidad_clase.dart';

class HabilidadesTipoSection extends StatelessWidget {
  const HabilidadesTipoSection({
    super.key,
    required this.title,
    required this.tipoDisplay,
    required this.items,
    required this.idAlumno,
    required this.emptyText,
    required this.onUpdated,
  });
  final String title;
  final String tipoDisplay; // 'Técnicas' | 'Blandas' | 'Idiomas'
  final List<HabilidadItem> items;
  final int idAlumno;
  final String emptyText;
  final VoidCallback onUpdated;

  Future<void> _openEditDialog(BuildContext context) async {
    final provider = context.read<UserDataProvider>();
    final initialIds = items.map((e) => e.idHabilidad).toList();
    List<int>? chosenIds; // actualizado vía onChanged

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? fieldError; // estado local del error visual
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return AlertDialog(
              title: Text('Editar $title'),
              content: SizedBox(
                width: 520,
                child: HabilidadesMultiDropdown(
                  label: 'Selecciona $title',
                  hintText: '',
                  initialSelectedIds: initialIds,
                  allowedTipo: tipoDisplay,
                  errorText: fieldError,
                  onChanged: (opts) {
                    chosenIds = opts.map((o) => o.id).toList();
                    if ((chosenIds?.isNotEmpty ?? false) && fieldError != null) {
                      setStateDialog(() => fieldError = null);
                    }
                  },
                ),
              ),
              actions: (() {
                final isMobile = MediaQuery.of(ctx2).size.width < 700;
                final buttons = <Widget>[
                  SimpleButton(
                    title: 'Cancelar',
                    icon: Icons.close_outlined,
                    backgroundColor: Colors.blueGrey,
                    textColor: Colors.white,
                    onTap: () => Navigator.pop(ctx2),
                  ),
                  SimpleButton(
                    title: 'Guardar',
                    icon: Icons.save_outlined,
                    onTap: () async {
                      final idsToSend = (chosenIds ?? initialIds);
                      if (idsToSend.isEmpty) {
                        setStateDialog(() => fieldError = 'Selecciona al menos una habilidad del tipo $tipoDisplay');
                        return;
                      }
                      final payload = idsToSend.map((idHab) => {
                        'id_alumno': idAlumno,
                        'id_habilidad': idHab,
                        'tipo': tipoDisplay,
                      }).toList();
                      try {
                        final headers = await provider.getAuthHeaders();
                        final res = await http.put(
                          Uri.parse('https://oda-talent-back-81413836179.us-central1.run.app/api/alumnos/perfil/actualizar_habilidades'),
                          headers: headers,
                          body: jsonEncode(payload),
                        );
                        if (res.statusCode >= 200 && res.statusCode < 300) {
                          if (ctx2.mounted) Navigator.pop(ctx2);
                          onUpdated();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Habilidades actualizadas')),
                            );
                          }
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error ${res.statusCode} al actualizar')), 
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Excepción: $e')),
                          );
                        }
                      }
                    },
                  ),
                ];
                if (isMobile) {
                  return [
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: buttons,
                      ),
                    ),
                  ];
                }
                return buttons;
              })(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = items.map((e) => e.habilidad).toList();
    if (texts.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emptyText, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
            onPressed: () => _openEditDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 190,
          child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...texts.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(e),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Editar lista',
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
          onPressed: () => _openEditDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
