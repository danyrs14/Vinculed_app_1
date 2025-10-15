import 'package:flutter/material.dart';
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/menu.dart';
import 'package:vinculed_app_1/src/ui/pages/reclutador/perfil_visible.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:vinculed_app_1/src/ui/widgets/textos/textos.dart';

class VacanteDetallePage extends StatelessWidget {
  const VacanteDetallePage({
    super.key,
    this.titulo = 'Becario de QA',
    this.salario = '\$7500 Mensuales',
    this.empresa = 'BBVA Mexico',
    this.direccion =
    'Av. Miguel Othón de Mendizábal Ote. 343-Locales 2-5,\nIndustrial Vallejo, Gustavo A. Madero, 07700 Ciudad de\nMéxico, CDMX',
    this.requisitosEscolares = const ['Universitarios sin Titulo'],
    this.requisitosEspecificos = const ['Informatica, Ing Sistemas, o Afin'],
    this.descripcion =
    'El puesto de Becario de TI está dirigido a estudiantes que desean adquirir experiencia práctica en el área de Tecnologías de la Información dentro de una empresa de tecnología o en el departamento de TI de una organización. El becario trabajará bajo la supervisión de profesionales experimentados en el campo, participando en proyectos tecnológicos y colaborando en tareas de soporte y mantenimiento de sistemas, redes, y aplicaciones de la empresa.',
    this.postulados = const [
      _MiniCandidato(
        nombre: 'Fernando Torres Juarez',
        fotoUrl:
        'https://images.unsplash.com/photo-1573497161161-c3e73707e25c?q=80&w=1200&auto=format&fit=crop',
      ),
      _MiniCandidato(
        nombre: 'Edgar Gomez Martinez',
        fotoUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=1328&auto=format&fit=crop',
      ),
    ],
    this.cumplenPerfil = const [
      _MiniCandidato(
        nombre: 'Fernando Torres Juarez',
        fotoUrl:
        'https://images.unsplash.com/photo-1573497161161-c3e73707e25c?q=80&w=1200&auto=format&fit=crop',
      ),
    ],
    this.onEditar,
    this.onAccionSecundaria,
    this.onCerrarVacante,
  });

  final String titulo;
  final String salario;
  final String empresa;
  final String direccion;
  final List<String> requisitosEscolares;
  final List<String> requisitosEspecificos;
  final String descripcion;
  final List<_MiniCandidato> postulados;
  final List<_MiniCandidato> cumplenPerfil;

  /// Callbacks opcionales (para conectar con tu lógica)
  final VoidCallback? onEditar;
  final VoidCallback? onAccionSecundaria; // por si quieres compartir/duplicar
  final VoidCallback? onCerrarVacante;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: theme.background(),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.background(),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.black87,
            // El icono de back SÍ regresa a la pantalla anterior
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MenuPageRec()),
            ),
          ),
          title: Texto(text: titulo, fontSize: 20, fontWeight: FontWeight.w700),
          actions: [
            IconButton(
              onPressed: onEditar ??
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Editar vacante')),
                    );
                  },
              icon: const Icon(Icons.edit_rounded, color: Colors.black87),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onAccionSecundaria ??
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eliminar')),
                    );
                  },
              icon: const Icon(Icons.delete, color: Colors.black87),
              tooltip: 'Eliminar',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado (salario, empresa, dirección)
                Center(
                  child: Column(
                    children: [
                      Texto(
                        text: salario,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Texto(
                        text: empresa,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        direccion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 24),

                // Requisitos
                const _SeccionTitulo('Requisitos:'),
                const SizedBox(height: 6),
                _TextoCuerpoList(lines: requisitosEscolares),
                const SizedBox(height: 6),
                _TextoCuerpoList(lines: requisitosEspecificos),

                const SizedBox(height: 6),
                const Divider(height: 28),

                // Descripción
                const _SeccionTitulo('Descripcion:'),
                const SizedBox(height: 6),
                _TextoCuerpo(text: descripcion),

                const SizedBox(height: 12),
                const Divider(height: 28),

                // Postulados
                Center(
                  child:
                  const Texto(text: 'Postulados', fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _FilaCandidatos(items: postulados),

                const SizedBox(height: 12),
                const Divider(height: 28),

                // Cumplen el perfil
                Center(
                  child: const Texto(
                    text: 'Cumple el Perfil',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _FilaCandidatos(items: cumplenPerfil),

                const SizedBox(height: 22),

                // Botón Cerrar Vacante
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 48,
                    child: SimpleButton(
                      title: 'Cerrar Vacante',
                      onTap: onCerrarVacante ??
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Vacante cerrada'),
                                backgroundColor: theme.primario(),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Widgets auxiliares (locales a esta pantalla) ----------

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
        ],
        Texto(text: text, fontSize: 13, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _TextoCuerpo extends StatelessWidget {
  const _TextoCuerpo({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 13.2, height: 1.35),
    );
  }
}

class _TextoCuerpoList extends StatelessWidget {
  const _TextoCuerpoList({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            e,
            style: const TextStyle(fontSize: 13.2, height: 1.25),
          ),
        ),
      )
          .toList(),
    );
  }
}

class _MiniCandidato {
  final String nombre;
  final String fotoUrl;
  const _MiniCandidato({required this.nombre, required this.fotoUrl});
}

class _FilaCandidatos extends StatelessWidget {
  const _FilaCandidatos({required this.items});
  final List<_MiniCandidato> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 18,
      runSpacing: 18,
      children: items
          .map(
            (c) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // ⬇️ Al seleccionar un postulado, mostramos la pantalla anterior
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilPostuladoPage(
                  nombre: c.nombre,
                  // El resto usa valores por defecto de la pantalla
                ),
              ),
            );
          },
          child: SizedBox(
            width: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.network(
                    c.fotoUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
