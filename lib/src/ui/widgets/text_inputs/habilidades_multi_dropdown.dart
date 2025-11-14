import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class HabilidadOption {
  final int id;
  final String habilidad;
  final String categoria;
  final String tipo;

  const HabilidadOption({
    required this.id,
    required this.habilidad,
    required this.categoria,
    required this.tipo,
  });

  factory HabilidadOption.fromJson(Map<String, dynamic> j) => HabilidadOption(
        id: j['id_habilidad'] as int,
        habilidad: (j['habilidad'] ?? '').toString(),
        categoria: (j['categoria'] ?? '').toString(),
        tipo: (j['tipo'] ?? '').toString(),
      );
}

class HabilidadesMultiDropdown extends StatefulWidget {
  final List<int> initialSelectedIds;
  final ValueChanged<List<HabilidadOption>> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;
  final String? authToken;
  final String? allowedTipo; // restrict selectable tipo
  final String? errorText; // show error and red border

  const HabilidadesMultiDropdown({
    super.key,
    this.initialSelectedIds = const [],
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    this.authToken,
    this.allowedTipo, // new param
    this.errorText,
  });

  @override
  State<HabilidadesMultiDropdown> createState() => _HabilidadesMultiDropdownState();
}

class _HabilidadesMultiDropdownState extends State<HabilidadesMultiDropdown> {
  static const _endpoint = 'https://oda-talent-back-81413836179.us-central1.run.app/api/habilidades/disponibles';

  final Set<int> _selectedIds = {};
  List<HabilidadOption> _options = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
  }

  Future<void> _ensureLoaded() async {
    if (_options.isNotEmpty || _loading) return;
    setState(() { _loading = true; _error = ''; });
    try {
      // Intentar cargar desde el cache del UserDataProvider
      final userProv = Provider.of<UserDataProvider>(context, listen: false);
      if (!userProv.habilidadesCargadas) {
        // Pre-cargar una sola vez (usa idToken internamente)
        await userProv.preloadHabilidades();
      }
      final cached = userProv.habilidadesDisponibles;
      if (cached != null && cached.isNotEmpty) {
        _options = cached.map((e) => HabilidadOption.fromJson(e)).toList();
        setState(() { _loading = false; });
        return;
      }
      // Fallback: si por alguna razón no hay cache, intenta una única petición HTTP
      final headers = <String, String>{ 'Content-Type': 'application/json' };
      final token = userProv.idToken ?? widget.authToken;
      if (token != null && token.isNotEmpty) { headers['Authorization'] = 'Bearer $token'; }
      final res = await http.get(Uri.parse(_endpoint), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _options = data.map((e) => HabilidadOption.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Error ${res.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  String _selectedSummary() {
    if (_selectedIds.isEmpty) return widget.hintText ?? '';
    final names = _options.where((o) => _selectedIds.contains(o.id)).map((o) => o.habilidad).toSet().toList();
    if (names.isEmpty) return '${_selectedIds.length} seleccionadas';
    final joined = names.take(3).join(', ');
    final extra = names.length - 3;
    return extra > 0 ? '$joined (+$extra)' : joined;
  }

  Future<void> _openSelector() async {
    await _ensureLoaded();
    if (!mounted) return;
    final selected = Set<int>.from(_selectedIds);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SelectorDialog(
        options: _options,
        initialSelected: selected,
        onConfirm: (ids) {
          _selectedIds..clear()..addAll(ids);
          final chosen = _options.where((o) => _selectedIds.contains(o.id)).toList();
          widget.onChanged(chosen);
          setState(() {});
          Navigator.of(ctx).pop();
        },
        errorText: _error,
        loading: _loading,
        allowedTipo: widget.allowedTipo, // pass restriction
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final hasError = (widget.errorText != null && widget.errorText!.isNotEmpty);
    final borderColor = hasError ? Colors.red : theme.secundario();
    final red = Colors.red;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor));
    final errorBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: red, width: 1.6));
    return GestureDetector(
      onTap: widget.enabled ? _openSelector : null,
      child: InputDecorator(
        isFocused: false,
        isEmpty: _selectedIds.isEmpty,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          errorText: widget.errorText,
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 1.6)),
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          enabled: widget.enabled,
          suffixIcon: Icon(Icons.arrow_drop_down, color: borderColor),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: -6,
          children: _selectedIds.isEmpty
              ? [Text(_selectedSummary(), style: const TextStyle(color: Colors.black54))]
              : _options
                  .where((o) => _selectedIds.contains(o.id))
                  .map((o) => Chip(
                        label: Text(o.habilidad, style: TextStyle(color: theme.primario(), fontWeight: FontWeight.w600)),
                        backgroundColor: theme.secundario().withOpacity(0.15),
                        shape: StadiumBorder(side: BorderSide(color: theme.secundario())),
                        deleteIconColor: Colors.redAccent,
                        onDeleted: widget.enabled
                            ? () {
                                setState(() {
                                  _selectedIds.remove(o.id);
                                  widget.onChanged(_options.where((x) => _selectedIds.contains(x.id)).toList());
                                });
                              }
                            : null,
                      ))
                  .toList(),
        ),
      ),
    );
  }
}

class _SelectorDialog extends StatefulWidget {
  final List<HabilidadOption> options;
  final Set<int> initialSelected;
  final ValueChanged<Set<int>> onConfirm;
  final String errorText;
  final bool loading;
  final String? allowedTipo; // restriction

  const _SelectorDialog({
    required this.options,
    required this.initialSelected,
    required this.onConfirm,
    required this.errorText,
    required this.loading,
    this.allowedTipo,
  });

  @override
  State<_SelectorDialog> createState() => _SelectorDialogState();
}

class _SelectorDialogState extends State<_SelectorDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HabilidadOption> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((o) => o.habilidad.toLowerCase().contains(q) || o.categoria.toLowerCase().contains(q) || o.tipo.toLowerCase().contains(q)).toList();
  }

  Map<String, Map<String, List<HabilidadOption>>> _grouped(List<HabilidadOption> opts) {
    final map = <String, Map<String, List<HabilidadOption>>>{};
    for (final o in opts) { map.putIfAbsent(o.tipo, () => {}); map[o.tipo]!.putIfAbsent(o.categoria, () => []); map[o.tipo]![o.categoria]!.add(o); }
    for (final tipo in map.keys) {
      final catMap = map[tipo]!; final sortedCatKeys = catMap.keys.toList()..sort(); final newCatMap = <String, List<HabilidadOption>>{};
      for (final c in sortedCatKeys) { final skills = List<HabilidadOption>.from(catMap[c]!)..sort((a,b)=>a.habilidad.compareTo(b.habilidad)); newCatMap[c] = skills; }
      map[tipo] = newCatMap;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final grouped = _grouped(_filtered);
    final accent = theme.secundario();
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent));
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    String _norm(String s) => s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    String _baseTipo(String s) {
      final t = _norm(s);
      if (t.contains('tecn')) return 'tecnica';
      if (t.contains('bland')) return 'blanda';
      if (t.contains('idiom')) return 'idioma';
      return t;
    }
    final allowedBase = widget.allowedTipo == null ? null : _baseTipo(widget.allowedTipo!);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: theme.fuente()),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: accent),
                        hintText: 'Filtrar por habilidad, categoría o tipo',
                        hintStyle: const TextStyle(color: Colors.black45),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: accent, width: 1.6)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SimpleButton(
                    title: 'Limpiar',
                    backgroundColor: Colors.blueGrey,
                    textColor: Colors.white,
                    onTap: () {
                      _searchCtrl.clear(); setState(() {}
                      );
                    },
                    icon: Icons.clear,
                  ),
                ],
              ),
            ),
            if (widget.loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(minHeight: 3, color: accent, backgroundColor: accent.withOpacity(.25)),
              ),
            if (widget.errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(widget.errorText, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: grouped.entries.map((tipoEntry) {
                        final tipo = tipoEntry.key; final categorias = tipoEntry.value;
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(tipo, style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
                            iconColor: accent,
                            collapsedIconColor: accent,
                            childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                            children: categorias.entries.map((catEntry) {
                              final categoria = catEntry.key; final habilidades = catEntry.value;
                              return ExpansionTile(
                                title: Text(categoria, style: const TextStyle(fontWeight: FontWeight.w600)),
                                childrenPadding: const EdgeInsets.only(left: 8, right: 8),
                                iconColor: accent,
                                collapsedIconColor: accent,
                                children: habilidades.map((h) {
                                  final checked = _selected.contains(h.id);
                                  final isAllowed = allowedBase == null ? true : _baseTipo(h.tipo) == allowedBase;
                                  return CheckboxListTile(
                                    dense: true,
                                    activeColor: accent,
                                    checkColor: theme.primario(),
                                    title: Text(h.habilidad, style: TextStyle(color: isAllowed ? theme.fuente() : Colors.black38)),
                                    subtitle: Text('${h.tipo} • ${h.categoria}', style: const TextStyle(fontSize: 12)),
                                    value: checked,
                                    onChanged: isAllowed ? (v) {
                                      setState(() { if (v == true) { _selected.add(h.id); } else { _selected.remove(h.id); } });
                                    } : null,
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Seleccionadas: ${_selected.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        SimpleButton(
                          title: 'Limpiar selección',
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                          icon: Icons.delete_outline,
                          onTap: () { setState(() { _selected.clear(); }); },
                        ),
                        const SizedBox(height: 8),
                        SimpleButton(
                          title: 'Confirmar',
                          backgroundColor: accent,
                          textColor: theme.primario(),
                          icon: Icons.check_circle_outline,
                          onTap: () => widget.onConfirm(_selected),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text('Seleccionadas: ${_selected.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        SimpleButton(
                          title: 'Limpiar selección',
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                          icon: Icons.delete_outline,
                          onTap: () { setState(() { _selected.clear(); }); },
                        ),
                        const SizedBox(width: 8),
                        SimpleButton(
                          title: 'Confirmar',
                          backgroundColor: accent,
                          textColor: theme.primario(),
                          icon: Icons.check_circle_outline,
                          onTap: () => widget.onConfirm(_selected),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
