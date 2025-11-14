class HabilidadItem {
  final int? idAlumno; // presente en algunos contextos
  final int idHabilidad;
  final int? idExperiencia;
  final int? idCertificado;
  final String categoria;
  final String tipo;
  final String habilidad;
  HabilidadItem({
    required this.idAlumno,
    required this.idHabilidad,
    required this.idExperiencia,
    required this.idCertificado,
    required this.categoria,
    required this.tipo,
    required this.habilidad,
  });
  factory HabilidadItem.fromJson(Map<String, dynamic> j) => HabilidadItem(
        idAlumno: j['id_alumno'],
        idHabilidad: j['id_habilidad'] ?? 0,
        idExperiencia: j['id_experiencia'],
        idCertificado: j['id_certificado'],
        categoria: j['categoria'],
        tipo: j['tipo'],
        habilidad: (j['habilidad'] ?? '') as String,
      );
}