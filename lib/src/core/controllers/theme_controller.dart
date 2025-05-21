import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/ui/widgets/configure.dart';

class ThemeController {
  ThemeController._(); //privado

  static final instance = ThemeController._();

  ValueNotifier<bool> brightness = ValueNotifier<bool>(true);
  bool get brightnessValue => brightness.value;

  Color primario() =>
      brightnessValue ? Configure.PRIMARIO : Configure.PRIMARIO_DARK;

  Color secundario() =>
      brightnessValue ? Configure.SECUNDARIO : Configure.SECUNDARIO_DARK;

  Color background() =>
      brightnessValue ? Configure.BACKGROUND_LIGHT : Configure.BACKGROUND_DARK;

  Color fuente() =>
      brightnessValue ? Configure.FUENTE : Configure.FUENTE_DARK;

/*String encabezado() => brightnessValue
      ? Configure.ENCABEZADO_LIGHT
      : Configure.ENCABEZADO_DARK;

  // Métodos para cambiar a tema claro y oscuro
  void setLightTheme() async {
    brightness.value = true; // Activa el tema claro
    await PreferencesService.instance.setBool("tema", brightness.value);
  }

  void setDarkTheme() async {
    brightness.value = false; // Activa el tema oscuro
    await PreferencesService.instance.setBool("tema", brightness.value);
  }

  Future<void> initTheme() async {
    brightness.value = await PreferencesService.instance.getBool("Tema");
  }*/
}
