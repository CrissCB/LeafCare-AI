import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/utils/plant_group_icons.dart';
import 'package:leafcare_ia/features/plants/data/models/plant_group_model.dart';

/// Abre un modal inferior para crear o editar un grupo de plantas.
Future<({String name, String iconName})?> showGroupFormSheet(
  BuildContext context, {
  PlantGroupModel? existingGroup,
}) {
  return showModalBottomSheet<({String name, String iconName})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _GroupFormSheet(existingGroup: existingGroup),
  );
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({this.existingGroup});

  final PlantGroupModel? existingGroup;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIconKey;

  bool get _isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingGroup?.name ?? '',
    );
    _selectedIconKey =
        widget.existingGroup?.iconName ?? PlantGroupIcons.defaultKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context)
        .pop((name: _nameController.text.trim(), iconName: _selectedIconKey));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Editar grupo' : 'Nuevo grupo de plantas',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organiza tus plantas por ubicación o tipo de cuidado.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
            ),
            const SizedBox(height: 18),

            // Nombre del grupo
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo',
                hintText: 'Ej. Sala, Balcón, Suculentas',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe un nombre para el grupo';
                }
                if (value.trim().length > 30) {
                  return 'Máximo 30 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Selector de ícono
            Text(
              'Elige un ícono',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: PlantGroupIcons.options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                final option = PlantGroupIcons.options[index];
                final isSelected = option.key == _selectedIconKey;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = option.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mint : AppColors.pageBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.slate,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Guardar cambios' : 'Crear grupo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
