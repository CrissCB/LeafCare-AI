import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/plant_detail/data/datasources/plant_remote_datasource.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_detail_model.dart';
import 'package:leafcare_ia/features/plant_detail/data/repositories/plant_repository.dart';

class EditPlantDialog extends StatefulWidget {
  const EditPlantDialog({super.key, required this.plant, required this.onSave});

  final PlantDetailModel plant;
  final void Function(String newName, String? newGroupId) onSave;

  @override
  State<EditPlantDialog> createState() => _EditPlantDialogState();
}

class _EditPlantDialogState extends State<EditPlantDialog> {
  late final TextEditingController _nameController;
  final _repository = const PlantRepository(
    datasource: PlantRemoteDatasource(),
  );

  String? _selectedGroupId;
  List<Map<String, dynamic>> _userGroups = [];
  bool _isLoadingGroups = true;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.customName);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _repository.getUserGroups();
    if (!mounted) return;

    setState(() {
      _userGroups = groups;
      final currentGroup = _userGroups
          .where((g) => g['name'] == widget.plant.groupName)
          .firstOrNull;
      if (currentGroup != null) {
        _selectedGroupId = currentGroup['id'] as String?;
      }
      _isLoadingGroups = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'El nombre no puede estar vacío');
      return;
    }
    Navigator.pop(context);
    widget.onSave(trimmed, _selectedGroupId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar Planta',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 16),

            // Campo de texto para el nombre
            Text(
              'Nombre',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                errorText: _nameError,
                filled: true,
                fillColor: AppColors.pageBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selector único de grupo
            Text(
              'Grupo asignado',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 10),
            _isLoadingGroups
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _userGroups.isEmpty
                ? Text(
                    'No hay grupos disponibles',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.slateLight,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _userGroups.map((group) {
                      final groupId = group['id'] as String?;
                      final isSelected = _selectedGroupId == groupId;
                      return ChoiceChip(
                        label: Text(group['name'] as String? ?? ''),
                        selected: isSelected,
                        selectedColor: AppColors.mint,
                        backgroundColor: AppColors.pageBg,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.slate,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedGroupId = selected ? groupId : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            // Botones Guardar / Cancelar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(color: AppColors.slate),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
