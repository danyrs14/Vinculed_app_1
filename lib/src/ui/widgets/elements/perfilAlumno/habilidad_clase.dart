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
        idAlumno: _asIntNullable(j['id_alumno']),
        idHabilidad: _asInt(j['id_habilidad']),
        idExperiencia: _asIntNullable(j['id_experiencia']),
        idCertificado: _asIntNullable(j['id_certificado']),
        categoria: (j['categoria'] ?? '') as String,
        tipo: (j['tipo'] ?? '') as String,
        habilidad: (j['habilidad'] ?? '') as String,
      );
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
int? _asIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}