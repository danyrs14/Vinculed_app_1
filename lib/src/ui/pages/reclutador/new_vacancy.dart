import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class CrearVacantePage extends StatefulWidget {
  const CrearVacantePage({super.key});

  @override
  State<CrearVacantePage> createState() => _CrearVacantePageState();
}

class _CrearVacantePageState extends State<CrearVacantePage> {
  final theme = ThemeController.instance;

  // Controllers
  final _nombreCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Datos base (puedes cargarlos de Firestore si lo deseas)
  static const List<String> _requisitosEscolaresOpc = [
    'Licenciado',
    'Título',
    'Grado',
    'Tesis',
    'Prepa',
    '2 Año',
    '1. Se',
    'Experto',
    'Grado',
    '3 Año',
    '1 Año',
    'Tecnico',
    'trunco',
    'Ultimo S.',
    'licenciatura',
    'Universitario sin titulo',
  ];

  static const List<String> _requisitosEspecificosOpc = [
    'Sistemas',
    'Informatica',
    'QA',
    'Electronica',
    'Administración',
    'Redes',
    'Ventas',
  ];

  // Selecciones
  final List<String> _selEscolares = ['Universitario sin titulo'];
  final List<String> _selEspecificos = ['Ingeniero en Sistemas'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _salarioCtrl.dispose();
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: theme.primario(), width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.primario().withOpacity(0.45)),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: theme.primario(), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: false,
    );
  }

  void _toggle(List<String> target, String item) {
    setState(() {
      if (target.contains(item)) {
        target.remove(item);
      } else {
        target.add(item);
      }
    });
  }

  void _publicar() {
    final payload = {
      'nombre': _nombreCtrl.text.trim(),
      'salario': _salarioCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'requisitosEscolares': _selEscolares,
      'requisitosEspecificos': _selEspecificos,
      'descripcion': _descripcionCtrl.text.trim(),
      'creadoEn': DateTime.now().toIso8601String(),
    };

    // TODO: Reemplaza este print por tu lógica (Firestore/API).
    // ignore: avoid_print
    print(payload);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vacante lista para publicar.'),
        backgroundColor: theme.primario(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.background(),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Texto(
          text: 'Crear Vacante',
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inputs principales
              TextField(controller: _nombreCtrl, decoration: _input('Nombre de la Vacante')),
              const SizedBox(height: 14),
              TextField(
                controller: _salarioCtrl,
                keyboardType: TextInputType.number,
                decoration: _input('Salario'),
              ),
              const SizedBox(height: 14),
              TextField(controller: _direccionCtrl, decoration: _input('Direccion donde se laborara')),
              const SizedBox(height: 18),

              // Requisitos escolares
              const Texto(
                text: 'REQUISITOS ESCOLARES:',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              SelectedBox(items: _selEscolares),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _requisitosEscolaresOpc.map((e) {
                  final selected = _selEscolares.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: selected,
                    onSelected: (_) => _toggle(_selEscolares, e),
                    side: const BorderSide(color: Colors.black54, width: 1),
                    selectedColor: theme.primario().withOpacity(.1),
                    showCheckmark: false,
                    labelStyle: const TextStyle(fontSize: 13),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // Requisitos específicos
              const Texto(
                text: 'REQUISITOS ESPECIFICOS:',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              SelectedBox(items: _selEspecificos),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _requisitosEspecificosOpc.map((e) {
                  final selected = _selEspecificos.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: selected,
                    onSelected: (_) => _toggle(_selEspecificos, e),
                    side: const BorderSide(color: Colors.black54, width: 1),
                    selectedColor: theme.primario().withOpacity(.1),
                    showCheckmark: false,
                    labelStyle: const TextStyle(fontSize: 13),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Descripción
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140),
                child: TextField(
                  controller: _descripcionCtrl,
                  maxLines: 8,
                  decoration: _input('Añade una Descripcion'),
                ),
              ),

              const SizedBox(height: 22),

              // Botón Publicar
              Center(
                child: SizedBox(
                  width: 220,
                  height: 48,
                  child: SimpleButton(
                    onTap: _publicar,
                    title: 'Publicar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenedor azul-gris para mostrar los seleccionados (como en la imagen).
class SelectedBox extends StatelessWidget {
  const SelectedBox({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFAEC1CB), // azul grisáceo similar al mock
        borderRadius: BorderRadius.circular(8),
      ),
      child: items.isEmpty
          ? const SizedBox(height: 30)
          : Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                border: Border.all(color: Colors.black87, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Texto(
                text: '${i + 1}. ${items[i]}',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
