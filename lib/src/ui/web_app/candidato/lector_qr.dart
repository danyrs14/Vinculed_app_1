import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:zxing2/qrcode.dart' as zxing;
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
  final theme = ThemeController.instance;
  final ImagePicker _picker = ImagePicker();

  // NOTA: Para web, usa 'localhost' en lugar de '10.0.2.2'
  //final String baseUrl = "http://localhost:3000/api/verificarqr";
  final String baseUrl = "https://oda-talent-back-81413836179.us-central1.run.app/api/verificarqr";
  bool _isLoading = false;
  
  // Controlador del escáner de cámara
  MobileScannerController? _scannerController;
  bool _hasScanned = false; // Evita múltiples escaneos

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
    final theme = ThemeController.instance;
    setState(() => _isLoading = true);
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.primario()),)),
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
        Navigator.pop(context);
      }
    }
  }

  /// Procesa el código QR sin mostrar indicador de carga (usado cuando ya hay uno visible)
  Future<void> _procesarCodigoSinIndicador(String codigo) async {
    try {
      final Uri url = Uri.parse("$baseUrl?url=$codigo");
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 304) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String nombre = data['nombre'] ?? 'Usuario';
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
    final theme = ThemeController.instance;
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    // Mostrar indicador de carga azul
    setState(() => _isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primario()),
        ),
      ),
    );

    try {
      final Uint8List bytes = await imagen.readAsBytes();
      
      // Intento 1: Usar jsQR vía JavaScript (muy robusto para fotos del mundo real)
      String? decoded = await _intentarDecodificarConJS(bytes);
      
      // Intento 2: Si jsQR falla, intentar con zxing2 Dart como respaldo
      if (decoded == null || decoded.isEmpty) {
        decoded = await _intentarDecodificarConZxing(bytes);
      }
      
      if (decoded != null && decoded.isNotEmpty) {
        // Cerrar el diálogo de carga antes de procesar
        if (mounted) Navigator.pop(context);
        await _procesarCodigoSinIndicador(decoded);
      } else {
        if (mounted) Navigator.pop(context);
        _mostrarMensaje('No se pudo detectar el código QR en la imagen. Intenta con otra foto más clara.');
      }
    } catch (e) {
      print('Error al escanear imagen: $e');
      if (mounted) Navigator.pop(context);
      _mostrarMensaje('Error al procesar la imagen.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Abre el escáner de cámara en un diálogo modal
  void _abrirEscanerCamara() {
    _hasScanned = false;
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode],
    );
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: theme.background(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primario(),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: theme.background()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Escanear código QR',
                          style: TextStyle(
                            color: theme.background(),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.background()),
                        onPressed: () {
                          _cerrarEscaner();
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                ),
                // Vista de la cámara
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (BarcodeCapture capture) {
                            if (_hasScanned) return; // Evitar múltiples detecciones
                            
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                                _hasScanned = true;
                                final String codigo = barcode.rawValue!;
                                
                                // Cerrar el diálogo y procesar
                                Navigator.of(dialogContext).pop();
                                _cerrarEscaner();
                                _procesarCodigo(codigo);
                                return;
                              }
                            }
                          },
                        ),
                        // Overlay con marco de escaneo
                        Center(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.background(),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        // Instrucciones
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.fuente(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Enfoca el código QR de tu credencial',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.background(),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Asegurar limpieza cuando se cierra el diálogo
      _cerrarEscaner();
    });
  }

  /// Cierra el escáner y libera recursos
  void _cerrarEscaner() {
    _scannerController?.dispose();
    _scannerController = null;
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

      final zxing.LuminanceSource source = zxing.RGBLuminanceSource(rgba.width, rgba.height, argb);
      final zxing.DecodeHints hints = zxing.DecodeHints()
        ..put(zxing.DecodeHintType.tryHarder, true)
        ..put(zxing.DecodeHintType.possibleFormats, [zxing.BarcodeFormat.qrCode]);

      // Intentar con HybridBinarizer
      try {
        final bitmap = zxing.BinaryBitmap(zxing.HybridBinarizer(source));
        final result = zxing.QRCodeReader().decode(bitmap, hints: hints);
        return result.text;
      } catch (_) {}

      // Intentar con GlobalHistogramBinarizer
      try {
        final bitmap = zxing.BinaryBitmap(zxing.GlobalHistogramBinarizer(source));
        final result = zxing.QRCodeReader().decode(bitmap, hints: hints);
        return result.text;
      } catch (_) {}

      // Intentar invertido
      try {
        final invertedSource = zxing.InvertedLuminanceSource(source);
        final bitmap = zxing.BinaryBitmap(zxing.HybridBinarizer(invertedSource));
        final result = zxing.QRCodeReader().decode(bitmap, hints: hints);
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
    _cerrarEscaner();
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
                              Text(
                                'Para continuar con tu registro, escanea el código QR de tu credencial institucional usando la cámara, o sube una fotografía del mismo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.fuente(),
                                ),
                              ),
                              const SizedBox(height: 32),
                              LargeButton(
                                title: 'Escanear con Cámara',
                                onTap: _isLoading ? null : () => _abrirEscanerCamara(),
                                icon: Icons.camera_alt_rounded,
                              ),
                              const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}