import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image/image.dart' as img; // Importa con un alias para evitar conflictos
import 'package:zxing2/qrcode.dart';
//import 'package:zxing2/zxing2.dart';
import 'dart:js_interop' as js;

import 'package:vinculed_app_1/src/ui/widgets/elements/header.dart';
import 'package:vinculed_app_1/src/ui/widgets/elements/footer.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/large_buttons.dart';

// Bridge to JS helper defined in web/index.html
@js.JS('decodeQrFromBytes')
external js.JSPromise<js.JSString?> _decodeQrFromBytes(js.JSUint8Array bytes);



class LectorQRPageWeb extends StatefulWidget {
  const LectorQRPageWeb({Key? key}) : super(key: key);

  @override
  State<LectorQRPageWeb> createState() => _LectorQRPageWebState();
}

class _LectorQRPageWebState extends State<LectorQRPageWeb> {
  final ImagePicker _picker = ImagePicker();

  // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
  final String baseUrl = "http://localhost:3000/api/verificarqr";
  //final String baseUrl = "https://oda-talent-back-81413836179.us-central1.run.app/api/verificarqr";
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
      print(e.toString());
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

  Future<void> _escanearDesdeImagenWebJS() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    setState(() => _isLoading = true);
    try {
      final Uint8List bytes = await imagen.readAsBytes();
      
      // Intento 1: Usar jsQR vía JavaScript (muy robusto para fotos del mundo real)
      String? decoded = await _intentarDecodificarConJS(bytes);
      
      // Intento 2: Si jsQR falla, intentar con zxing2 Dart como respaldo
      if (decoded == null || decoded.isEmpty) {
        decoded = await _intentarDecodificarConZxing(bytes);
      }
      
      if (decoded != null && decoded.isNotEmpty) {
        await _procesarCodigo(decoded);
      } else {
        _mostrarMensaje('No se pudo detectar el código QR en la imagen. Intenta con otra foto más clara.');
      }
    } catch (e) {
      print('Error al escanear imagen: $e');
      _mostrarMensaje('Error al procesar la imagen.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Intenta decodificar usando jsQR vía JavaScript (index.html helper)
  Future<String?> _intentarDecodificarConJS(Uint8List bytes) async {
    try {
      final js.JSString? jsResult = await _decodeQrFromBytes(bytes.toJS).toDart;
      return jsResult?.toDart;
    } catch (e) {
      print('Error con jsQR: $e');
      return null;
    }
  }

  /// Respaldo: intenta decodificar usando zxing2 (Dart puro) con preprocesamiento
  Future<String?> _intentarDecodificarConZxing(Uint8List bytes) async {
    try {
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // Preparar variantes de la imagen
      final List<img.Image> candidatos = _prepararCandidatos(decodedImage);
      
      for (final img.Image cand in candidatos) {
        final String? resultado = _decodificarConZxing(cand);
        if (resultado != null) return resultado;
      }
      return null;
    } catch (e) {
      print('Error con zxing2: $e');
      return null;
    }
  }

  /// Prepara múltiples versiones de la imagen para mejorar la detección
  /// Incluye operaciones morfológicas para QRs de baja calidad
  List<img.Image> _prepararCandidatos(img.Image original) {
    final List<img.Image> candidatos = [];
    
    // Normalizar tamaño - escalar para tener mejor resolución
    img.Image trabajo = original;
    final int maxLado = trabajo.width > trabajo.height ? trabajo.width : trabajo.height;
    if (maxLado > 1500) {
      final double escala = 1500 / maxLado;
      trabajo = img.copyResize(
        trabajo,
        width: (trabajo.width * escala).round(),
        height: (trabajo.height * escala).round(),
        interpolation: img.Interpolation.cubic,
      );
    } else if (maxLado < 800) {
      // Escalar hacia arriba si la imagen es muy pequeña
      final double escala = 800 / maxLado;
      trabajo = img.copyResize( //1200
        trabajo,
        width: (trabajo.width * escala).round(),
        height: (trabajo.height * escala).round(),
        interpolation: img.Interpolation.cubic,
      );
    }
    
    // 1. Imagen original en escala de grises
    final img.Image gris = img.grayscale(trabajo);
    candidatos.add(gris);
    
    // 2. Con contraste aumentado
    final img.Image contrasteAlto = img.adjustColor(img.grayscale(trabajo), contrast: 1.3);
    candidatos.add(contrasteAlto);
    
    // 3. Imagen binarizada con dilatación morfológica (para QRs de baja calidad)
    // Esto rellena los "huecos" blancos dentro de los módulos negros
    candidatos.add(_binarizarConDilatacion(trabajo, umbral: 128, iteraciones: 1));
    candidatos.add(_binarizarConDilatacion(trabajo, umbral: 100, iteraciones: 1));
    candidatos.add(_binarizarConDilatacion(trabajo, umbral: 128, iteraciones: 2));
    
    // 4. Versión escalada con morfología
    final img.Image escalada = img.copyResize(
      trabajo,
      width: (trabajo.width * 1.5).round(),
      height: (trabajo.height * 1.5).round(),
      interpolation: img.Interpolation.cubic,
    );
    candidatos.add(_binarizarConDilatacion(escalada, umbral: 128, iteraciones: 1));
    
    // 5. Recorte central (60% del centro)
    final int anchoRecorte = (trabajo.width * 0.6).round();
    final int altoRecorte = (trabajo.height * 0.6).round();
    final int offsetX = ((trabajo.width - anchoRecorte) / 2).round();
    final int offsetY = ((trabajo.height - altoRecorte) / 2).round();
    final img.Image centro = img.copyCrop(
      trabajo, 
      x: offsetX, 
      y: offsetY, 
      width: anchoRecorte, 
      height: altoRecorte,
    );
    candidatos.add(img.grayscale(centro));
    
    // 6. Recorte central con morfología
    candidatos.add(_binarizarConDilatacion(centro, umbral: 128, iteraciones: 1));
    
    // 7. Recorte central escalado
    final img.Image centroEscalado = img.copyResize(
      centro,
      width: (centro.width * 1.5).round(),
      height: (centro.height * 1.5).round(),
      interpolation: img.Interpolation.cubic,
    );
    candidatos.add(img.grayscale(centroEscalado));
    candidatos.add(_binarizarConDilatacion(centroEscalado, umbral: 128, iteraciones: 1));
    
    return candidatos;
  }

  /// Binariza la imagen y aplica dilatación morfológica para rellenar huecos
  /// en los módulos negros del QR (útil para credenciales de baja calidad)
  img.Image _binarizarConDilatacion(img.Image src, {int umbral = 128, int iteraciones = 1}) {
    final int width = src.width;
    final int height = src.height;
    
    // Convertir a escala de grises y binarizar
    final img.Image gris = img.grayscale(src);
    final Uint8List pixels = gris.getBytes(order: img.ChannelOrder.rgb);
    
    // Crear matriz binaria (0 = negro, 255 = blanco)
    final Uint8List binario = Uint8List(width * height);
    for (int i = 0; i < binario.length; i++) {
      final int lum = pixels[i * 3]; // Canal R (igual a G y B en escala de grises)
      binario[i] = lum < umbral ? 0 : 255;
    }
    
    // Aplicar dilatación de píxeles negros (rellena huecos blancos)
    Uint8List actual = binario;
    for (int d = 0; d < iteraciones; d++) {
      final Uint8List siguiente = Uint8List.fromList(actual);
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final int idx = y * width + x;
          // Si algún vecino (8-conectividad) es negro, este píxel se vuelve negro
          if (actual[idx - 1] == 0 || actual[idx + 1] == 0 ||
              actual[idx - width] == 0 || actual[idx + width] == 0 ||
              actual[idx - width - 1] == 0 || actual[idx - width + 1] == 0 ||
              actual[idx + width - 1] == 0 || actual[idx + width + 1] == 0) {
            siguiente[idx] = 0;
          }
        }
      }
      actual = siguiente;
    }
    
    // Reconstruir imagen
    final Uint8List outData = Uint8List(width * height * 3);
    for (int i = 0; i < actual.length; i++) {
      final int val = actual[i];
      outData[i * 3] = val;
      outData[i * 3 + 1] = val;
      outData[i * 3 + 2] = val;
    }
    
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: outData.buffer,
      order: img.ChannelOrder.rgb,
    );
  }

  /// Intenta decodificar una imagen con zxing2
  String? _decodificarConZxing(img.Image imagen) {
    try {
      final img.Image rgba = imagen.convert(numChannels: 4);
      final Uint8List bytesRgba = rgba.getBytes(order: img.ChannelOrder.rgba);
      final int pixelCount = rgba.width * rgba.height;
      final Int32List argb = Int32List(pixelCount);
      
      for (int i = 0, p = 0; i < bytesRgba.length; i += 4, p++) {
        final int r = bytesRgba[i];
        final int g = bytesRgba[i + 1];
        final int b = bytesRgba[i + 2];
        final int a = bytesRgba[i + 3];
        argb[p] = (a << 24) | (r << 16) | (g << 8) | b;
      }

      final LuminanceSource source = RGBLuminanceSource(rgba.width, rgba.height, argb);
      final DecodeHints hints = DecodeHints()
        ..put(DecodeHintType.tryHarder, true)
        ..put(DecodeHintType.possibleFormats, [BarcodeFormat.qrCode]);

      // Intentar con HybridBinarizer
      try {
        final bitmap = BinaryBitmap(HybridBinarizer(source));
        final result = QRCodeReader().decode(bitmap, hints: hints);
        return result.text;
      } catch (_) {}

      // Intentar con GlobalHistogramBinarizer
      try {
        final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
        final result = QRCodeReader().decode(bitmap, hints: hints);
        return result.text;
      } catch (_) {}

      // Intentar invertido
      try {
        final invertedSource = InvertedLuminanceSource(source);
        final bitmap = BinaryBitmap(HybridBinarizer(invertedSource));
        final result = QRCodeReader().decode(bitmap, hints: hints);
        return result.text;
      } catch (_) {}

      return null;
    } catch (e) {
      return null;
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
                                onTap: _isLoading ? null : () => _escanearDesdeImagenWebJS(),
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