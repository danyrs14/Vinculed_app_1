import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vinculed_app_1/src/core/controllers/theme_controller.dart';
import 'package:vinculed_app_1/src/ui/widgets/buttons/simple_buttons.dart';
import 'package:provider/provider.dart';
import 'package:vinculed_app_1/src/core/providers/user_provider.dart';

class RoleOption {
  final int id;
  final String area;
  final String nombre;

  const RoleOption({
    required this.id,
    required this.area,
    required this.nombre,
  });

  factory RoleOption.fromJson(Map<String, dynamic> j) => RoleOption(
        id: j['id_roltrabajo'] as int,
        area: (j['area'] ?? '').toString(),
        nombre: (j['nombre'] ?? '').toString(),
      );
}

class RolesMultiDropdown extends StatefulWidget {
  final List<int> initialSelectedIds;
  final ValueChanged<List<RoleOption>> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;
  final String? authToken;
  final String? errorText;

  const RolesMultiDropdown({
    super.key,
    this.initialSelectedIds = const [],
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    this.authToken,
    this.errorText,
  });

  @override
  State<RolesMultiDropdown> createState() => _RolesMultiDropdownState();
}

class _RolesMultiDropdownState extends State<RolesMultiDropdown> {
  static const _endpoint = 'https://oda-talent-back-81413836179.us-central1.run.app/api/roles_trabajo/ver';

  final Set<int> _selectedIds = {};
  List<RoleOption> _options = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
  }

  Future<void> _ensureLoaded() async {
    if (_options.isNotEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final headers =await context.read<UserDataProvider>().getAuthHeaders();
      final res = await http.get(Uri.parse(_endpoint), headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _options = data
            .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
            .toList();
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
    final names = _options
        .where((o) => _selectedIds.contains(o.id))
        .map((o) => o.nombre)
        .toSet()
        .toList();
    if (names.isEmpty) return '${_selectedIds.length} seleccionados';
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
      builder: (ctx) => _RolesSelectorDialog(
        options: _options,
        initialSelected: selected,
        onConfirm: (ids) {
          _selectedIds
            ..clear()
            ..addAll(ids);
          final chosen =
              _options.where((o) => _selectedIds.contains(o.id)).toList();
          widget.onChanged(chosen);
          setState(() {});
          Navigator.of(ctx).pop();
        },
        errorText: _error,
        loading: _loading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final hasError = (widget.errorText != null && widget.errorText!.isNotEmpty);
    final borderColor = hasError ? Colors.red : theme.secundario();
    final red = Colors.red;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: red, width: 1.6),
    );

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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1.6),
          ),
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          enabled: widget.enabled,
          suffixIcon: Icon(Icons.arrow_drop_down, color: borderColor),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: -6,
          children: _selectedIds.isEmpty
              ? [
                  Text(
                    _selectedSummary(),
                    style: const TextStyle(color: Colors.black54),
                  )
                ]
              : _options
                  .where((o) => _selectedIds.contains(o.id))
                  .map(
                    (o) => Chip(
                      label: Text(
                        o.nombre,
                        style: TextStyle(
                          color: theme.primario(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: theme.secundario().withOpacity(0.15),
                      shape: StadiumBorder(
                        side: BorderSide(color: theme.secundario()),
                      ),
                      deleteIconColor: Colors.redAccent,
                      onDeleted: widget.enabled
                          ? () {
                              setState(() {
                                _selectedIds.remove(o.id);
                                widget.onChanged(_options
                                    .where((x) => _selectedIds.contains(x.id))
                                    .toList());
                              });
                            }
                          : null,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _RolesSelectorDialog extends StatefulWidget {
  final List<RoleOption> options;
  final Set<int> initialSelected;
  final ValueChanged<Set<int>> onConfirm;
  final String errorText;
  final bool loading;

  const _RolesSelectorDialog({
    required this.options,
    required this.initialSelected,
    required this.onConfirm,
    required this.errorText,
    required this.loading,
  });

  @override
  State<_RolesSelectorDialog> createState() => _RolesSelectorDialogState();
}

class _RolesSelectorDialogState extends State<_RolesSelectorDialog> {
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

  List<RoleOption> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) =>
            o.nombre.toLowerCase().contains(q) || o.area.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<RoleOption>> _groupedByArea(List<RoleOption> opts) {
    final map = <String, List<RoleOption>>{};
    for (final o in opts) {
      map.putIfAbsent(o.area, () => []);
      map[o.area]!.add(o);
    }
    final sorted = <String, List<RoleOption>>{};
    final keys = map.keys.toList()..sort();
    for (final k in keys) {
      final roles = List<RoleOption>.from(map[k]!)
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      sorted[k] = roles;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final grouped = _groupedByArea(_filtered);
    final accent = theme.secundario();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: accent),
    );
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

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
                        hintText: 'Filtrar por rol o área',
                        hintStyle: const TextStyle(color: Colors.black45),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accent, width: 1.6),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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
                      _searchCtrl.clear();
                      setState(() {});
                    },
                    icon: Icons.clear,
                  ),
                ],
              ),
            ),
            if (widget.loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: accent,
                  backgroundColor: accent.withOpacity(.25),
                ),
              ),
            if (widget.errorText.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(widget.errorText,
                    style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: grouped.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: grouped.entries.map((areaEntry) {
                        final area = areaEntry.key;
                        final roles = areaEntry.value;
                        return Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              area,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            iconColor: accent,
                            collapsedIconColor: accent,
                            childrenPadding: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              bottom: 4,
                            ),
                            children: roles.map((r) {
                              final checked = _selected.contains(r.id);
                              return CheckboxListTile(
                                dense: true,
                                activeColor: accent,
                                checkColor: theme.primario(),
                                title: Text(r.nombre,
                                    style: TextStyle(color: theme.fuente())),
                                subtitle: Text(area, style: const TextStyle(fontSize: 12)),
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(r.id);
                                    } else {
                                      _selected.remove(r.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              alignment:
                  isMobile ? Alignment.center : Alignment.centerRight,
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Seleccionados: ${_selected.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SimpleButton(
                          title: 'Limpiar selección',
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                          icon: Icons.delete_outline,
                          onTap: () {
                            setState(() {
                              _selected.clear();
                            });
                          },
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
                        Text(
                          'Seleccionados: ${_selected.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        SimpleButton(
                          title: 'Limpiar selección',
                          backgroundColor: Colors.blueGrey,
                          textColor: Colors.white,
                          icon: Icons.delete_outline,
                          onTap: () {
                            setState(() {
                              _selected.clear();
                            });
                          },
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
