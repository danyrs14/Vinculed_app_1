import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/text_inputs/text_input.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class Postulaciones extends StatefulWidget {
  @override
  _PostulacionesState createState() => _PostulacionesState();
}

class _PostulacionesState extends State<Postulaciones> {
  // Controladores de los campos de texto
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController atnController = TextEditingController();

  // Variable para guardar la fecha seleccionada
  DateTime? selectedDate;

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return Scaffold(
      backgroundColor: theme.background(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la página
                Texto(
                  text: 'Postulaciones',
                  fontSize: 24,
                ),
            
              ],
            ),
          ),
        ),
      ),
    );
  }
}
