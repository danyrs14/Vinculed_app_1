import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/pages/login.dart';
import 'package:vinculed_app_1/src/ui/pages/modulo_candidato/registrar_alumno.dart';

class LectorQRPage extends StatefulWidget {
  const LectorQRPage({Key? key}) : super(key: key);

  @override
  State<LectorQRPage> createState() => _LectorQRPageState();
}

class _LectorQRPageState extends State<LectorQRPage> {
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _mostrarScanner = false;
  final String baseUrl = "http://10.0.2.2:3000/api/verificarqr";

  Future<void> _procesarCodigo(String codigo) async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),)),
    );
    try {
      //Hacer la petición al servidor
      final Uri url = Uri.parse("$baseUrl?url=$codigo");
      final response = await http.get(url);
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String nombre = data['nombre'] ?? 'Usuario'; 
        //redirigir al formulario
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegisterStudentPage(nombre: nombre)));
      } else if (response.statusCode == 400) {
        _mostrarMensaje(
          "Lo sentimos. Solo se pueden registrar alumnos de la ESCOM.",
          redirigirLogin: true,
        );
      } else if (response.statusCode == 500) {
        _mostrarMensaje(
          "Hubo un error al escanear el código QR. Por favor, inténtelo más tarde.",
          redirigirLogin: false,
        );
      } else {
        _mostrarMensaje(
          "Se produjo un error inesperado. Por favor, inténtelo más tarde.",
          redirigirLogin: true,
        );
      }
    } catch (e) {
      _mostrarMensaje(
        "Error de conexión con el servidor. Por favor, inténtelo más tarde.",
        redirigirLogin: false,
      );
      print("Error al procesar el código QR: $e");
      setState(() {
        _mostrarScanner = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje, {bool redirigirLogin = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
    if (redirigirLogin) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    }
  }

  void _onDetect(BarcodeCapture captura) {
    final List<Barcode> codigos = captura.barcodes;
    if (codigos.isNotEmpty) {
      final codigo = codigos.first.rawValue ?? 'Código no válido';
      print('Código detectado: $codigo');
      if (codigo.isNotEmpty) {
        _procesarCodigo(codigo);
      } else {
        _mostrarMensaje("Lo sentimos. El código escaneado no es válido.");
      }
    } else {
      _mostrarMensaje("No se detectó ningún código QR.");
    }
  }

  Future<void> _escanearDesdeImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    final result = await _controller.analyzeImage(imagen.path);
    if (result != null  && result.barcodes.isNotEmpty) {
      final codigo = result.barcodes.first.rawValue ?? 'Código no válido';
      print('Código detectado desde imagen: $codigo');
      if (codigo.isNotEmpty) {
        _procesarCodigo(codigo);
      } else {
        _mostrarMensaje("Lo sentimos. El código escaneado no es válido.");
      }
    } else {
      _mostrarMensaje("No se detectó ningún código QR en la imagen.");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text('Lector de código QR', 
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        
      ),
      body: _mostrarScanner
          ? MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Por favor, escanea el código QR que se encuentra detrás de tu credencial institucional. Puedes hacerlo desde una imagen o usando la cámara de tu dispositivo.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SimpleButton(
                    title: 'Escanear con cámara',
                    icon: Icons.camera_alt,
                    onTap: () {
                      setState(() {
                        _mostrarScanner = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SimpleButton(
                    title: 'Escanear desde galería',
                    icon: Icons.image,
                    onTap: _escanearDesdeImagen,
                  ),
                ],
              ),
            ),
    );
  }
}
