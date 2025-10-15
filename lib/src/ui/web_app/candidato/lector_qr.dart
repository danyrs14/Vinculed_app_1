import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image/image.dart' as img; // Importa con un alias para evitar conflictos
import 'package:zxing2/qrcode.dart';

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

class LectorQRPageWeb extends StatefulWidget {
  const LectorQRPageWeb({Key? key}) : super(key: key);

  @override
  State<LectorQRPageWeb> createState() => _LectorQRPageWebState();
}

class _LectorQRPageWebState extends State<LectorQRPageWeb> {
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController _controller = MobileScannerController();

  // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
  final String baseUrl = "http://localhost:3000/api/verificarqr";
  bool _isLoading = false;

  // Lógica de Footer
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFooter = false;
  static const double _footerReservedSpace = EscomFooter.height;
  static const double _extraBottomPadding = 24.0;
  static const double _atEndThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }
  
  // --- Lógica de Procesamiento de QR ---

  Future<void> _procesarCodigo(String codigo) async {
    setState(() => _isLoading = true);
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),)),
    );
    try {
      final Uri url = Uri.parse("$baseUrl?url=$codigo");
      final response = await http.get(url);
      Navigator.pop(context);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 304) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String nombre = data['nombre'] ?? 'Usuario';
        // Redirigir al formulario de registro pasando el nombre
        context.go('/signin', extra: nombre);
      } else if (response.statusCode == 400) {
        _mostrarMensaje(
          "Lo sentimos. Solo se pueden registrar alumnos de la ESCOM.",
          redirigirLogin: true,
        );
      } else {
        _mostrarMensaje(
          "Hubo un error al verificar el código QR. Por favor, inténtelo más tarde.",
          redirigirLogin: false,
        );
      }
    } catch (e) {
      _mostrarMensaje(
        "Error de conexión con el servidor. Por favor, inténtelo más tarde.",
        redirigirLogin: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool redirigirLogin = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
    if (redirigirLogin) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/login');
      });
    }
  }

  Future<void> _escanearDesdeImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await imagen.readAsBytes();
      // Decodificar la imagen usando el paquete 'image'
      final img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {

        LuminanceSource source = RGBLuminanceSource(
          decodedImage.width,
          decodedImage.height,
          decodedImage
              .convert(numChannels: 4)
              .getBytes(order: img.ChannelOrder.abgr)
              .buffer
              .asInt32List());
        var bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));

        final reader = QRCodeReader();
        final result = reader.decode(bitmap);
        print(result.text);

        _procesarCodigo(result.text);

      } else {
        throw Exception("No se pudo decodificar la imagen.");
      }
    } on NotFoundException catch (e) {
      // Este error es común si no se encuentra un QR en la imagen
      print("Error de zxing: ${e.toString()}");
      _mostrarMensaje("No se detectó ningún código QR en la imagen.");
    } catch (e) {
      print("Error inesperado: $e");
      _mostrarMensaje("Ocurrió un error al procesar la imagen.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Lógica del Footer y Dispose ---

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;
    if (pos.maxScrollExtent <= 0) {
      if (_showFooter) setState(() => _showFooter = false);
      return;
    }
    final atBottom = pos.pixels >= (pos.maxScrollExtent - _atEndThreshold);
    if (atBottom != _showFooter) {
      setState(() => _showFooter = atBottom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      appBar: EscomHeader(
        onLoginTap: () => context.go('/login'),
        onRegisterTap: () => context.go('/lector_qr'),
        onNotifTap: () {},
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minBodyHeight =
                    constraints.maxHeight - _footerReservedSpace - _extraBottomPadding;

                return SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.only(
                    bottom: _footerReservedSpace + _extraBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minBodyHeight > 0 ? minBodyHeight : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                child: Lottie.asset(
                                  'assets/images/logen.json', // Tu animación
                                  height: 180,
                                  width: 280,
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'Verifica tu credencial de estudiante',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Para continuar con tu registro, por favor sube una fotografía o captura de pantalla del código QR que se encuentra al reverso de tu credencial institucional.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 32),
                              LargeButton(
                                title: 'Subir Imagen de QR',
                                onTap: _isLoading ? null : _escanearDesdeImagen,
                                icon: Icons.upload_file_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              offset: _showFooter ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showFooter ? 1 : 0,
                child: EscomFooter(isMobile: isMobile),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}