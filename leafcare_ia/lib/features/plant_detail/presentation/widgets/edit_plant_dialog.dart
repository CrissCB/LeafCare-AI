import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/utils/plant_group_icons.dart';
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
    datasource: PlantRemoteDatasource(supabaseClient: AppSupabaseClient()),
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
    try {
      final groups = await _repository.getUserGroups();
      if (!mounted) return;

      setState(() {
        _userGroups = groups;
        _selectedGroupId = widget.plant.groupId;
        _isLoadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingGroups = false);
    }
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar planta',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
              textCapitalization: TextCapitalization.sentences,
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

            // Selector único de grupo con su ícono correspondiente
            Text(
              'Grupo asignado',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoadingGroups)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (_userGroups.isEmpty)
              Text(
                'Aún no has creado grupos en "Mis plantas".',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.slateLight,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userGroups.map((group) {
                  final groupId = group['id']?.toString();
                  final groupName = group['name']?.toString() ?? '';
                  final iconData = PlantGroupIcons.resolve(
                    group['icon_name']?.toString(),
                  );
                  final isSelected = _selectedGroupId == groupId;

                  return ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      iconData,
                      size: 16,
                      color: isSelected ? AppColors.primary : AppColors.slate,
                    ),
                    label: Text(groupName),
                    selected: isSelected,
                    selectedColor: AppColors.mint,
                    backgroundColor: AppColors.pageBg,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : AppColors.slate,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSave,
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
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
