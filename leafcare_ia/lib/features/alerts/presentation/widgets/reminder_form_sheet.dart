import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/utils/plant_group_icons.dart';
import 'package:leafcare_ia/core/utils/reminder_icons.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/data/repositories/alerts_repository.dart';

class ReminderFormSubmission {
  const ReminderFormSubmission({
    this.plantId,
    required this.treatmentAction,
    required this.iconName,
    required this.scheduledTime,
    required this.isRecurrent,
    this.recurrenceDays,
  });

  final String? plantId;
  final String treatmentAction;
  final String iconName;
  final DateTime scheduledTime;
  final bool isRecurrent;
  final int? recurrenceDays;
}

/// Modal inferior para crear o editar un recordatorio de cuidado.
class ReminderFormSheet extends StatefulWidget {
  const ReminderFormSheet({
    super.key,
    required this.plants,
    required this.groups,
    this.initialReminder,
  });

  final List<PlantSelectOption> plants;
  final List<GroupFilterOption> groups;
  final CareReminderItemModel? initialReminder;

  static Future<ReminderFormSubmission?> show(
    BuildContext context, {
    required List<PlantSelectOption> plants,
    required List<GroupFilterOption> groups,
    CareReminderItemModel? initialReminder,
  }) {
    return showModalBottomSheet<ReminderFormSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReminderFormSheet(
        plants: plants,
        groups: groups,
        initialReminder: initialReminder,
      ),
    );
  }

  @override
  State<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<ReminderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final TextEditingController _plantSearchController = TextEditingController();

  String? _selectedPlantId;
  String? _selectedGroupFilterId;
  String _plantSearchQuery = '';

  late String _selectedIconKey;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isRecurrent;
  late int _recurrenceDays;
  String? _validationError;

  bool get _isEditing => widget.initialReminder != null;

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.initialReminder;

    _titleController = TextEditingController(
      text: existing?.treatmentAction ?? '',
    );
    _selectedIconKey = existing?.iconName ?? ReminderIcons.defaultKey;

    if (existing != null) {
      final rawDay = DateTime(
        existing.scheduledTime.year,
        existing.scheduledTime.month,
        existing.scheduledTime.day,
      );
      _selectedDate = rawDay.isBefore(_todayStart) ? _todayStart : rawDay;
      _selectedTime = TimeOfDay.fromDateTime(existing.scheduledTime);
      _isRecurrent = existing.isRecurrent;
      _recurrenceDays = (existing.recurrenceDays ?? 3).clamp(1, 7);
    } else {
      final defaultTime = DateTime.now().add(const Duration(hours: 1));
      _selectedDate = _todayStart;
      _selectedTime = TimeOfDay(
        hour: defaultTime.hour,
        minute: defaultTime.minute,
      );
      _isRecurrent = false;
      _recurrenceDays = 3;
      if (widget.plants.isNotEmpty) {
        _selectedPlantId = widget.plants.first.id;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _plantSearchController.dispose();
    super.dispose();
  }

  List<PlantSelectOption> get _filteredPlants {
    final query = _plantSearchQuery.trim().toLowerCase();
    return widget.plants
        .where((plant) {
          final matchesGroup =
              _selectedGroupFilterId == null ||
              plant.groupId == _selectedGroupFilterId;
          final matchesName =
              query.isEmpty || plant.name.toLowerCase().contains(query);
          return matchesGroup && matchesName;
        })
        .toList(growable: false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _todayStart, // Deshabilita fechas anteriores a la actual
      lastDate: _todayStart.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _validationError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
        _validationError = null;
      });
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isEditing &&
        (_selectedPlantId == null || _selectedPlantId!.isEmpty)) {
      setState(() => _validationError = 'Selecciona una planta para continuar');
      return;
    }

    final scheduled = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.of(context).pop(
      ReminderFormSubmission(
        plantId: _isEditing ? null : _selectedPlantId,
        treatmentAction: _titleController.text.trim(),
        iconName: _selectedIconKey,
        scheduledTime: scheduled,
        isRecurrent: _isRecurrent,
        recurrenceDays: _isRecurrent ? _recurrenceDays : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador superior
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
                _isEditing ? 'Editar recordatorio' : 'Nuevo recordatorio',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Selección de planta (solo en creación; en edición se muestra fija)
              if (_isEditing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pageBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.initialReminder?.plantName ??
                              'Planta asignada',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.anthracite,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Selecciona la planta',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 8),

                // Filtro por grupo
                if (widget.groups.isNotEmpty) ...[
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _MiniFilterChip(
                          label: 'Todas',
                          icon: Icons.folder_copy_rounded,
                          selected: _selectedGroupFilterId == null,
                          onTap: () =>
                              setState(() => _selectedGroupFilterId = null),
                        ),
                        for (final g in widget.groups) ...[
                          const SizedBox(width: 6),
                          _MiniFilterChip(
                            label: g.name,
                            icon: PlantGroupIcons.resolve(g.iconName),
                            selected: _selectedGroupFilterId == g.id,
                            onTap: () => setState(() {
                              _selectedGroupFilterId =
                                  _selectedGroupFilterId == g.id ? null : g.id;
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Buscador por nombre de planta
                TextField(
                  controller: _plantSearchController,
                  onChanged: (v) => setState(() => _plantSearchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Filtrar planta por nombre...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    suffixIcon: _plantSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _plantSearchController.clear();
                              setState(() => _plantSearchQuery = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Carrusel de plantas filtradas
                if (_filteredPlants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No se encontraron plantas con ese filtro.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.slateLight,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredPlants.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final plant = _filteredPlants[index];
                        final isSelected = plant.id == _selectedPlantId;
                        final img = plant.imageUrl ?? '';

                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedPlantId = plant.id;
                            _validationError = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.mint
                                  : AppColors.pageBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: img.isNotEmpty
                                      ? Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.eco_rounded,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.eco_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plant.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.anthracite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // 2. Título del recordatorio
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Título del cuidado',
                  hintText: 'Ej. Riego profundo, Fertilización...',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título para el recordatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Ícono representativo (lista cerrada)
              Text(
                'Ícono del recordatorio',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ReminderIcons.options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final opt = ReminderIcons.options[index];
                  final selected = opt.key == _selectedIconKey;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconKey = opt.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.mint : AppColors.pageBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            opt.icon,
                            size: 20,
                            color: selected ? opt.accentColor : AppColors.slate,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
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
              const SizedBox(height: 16),

              // 4. Fecha y Hora
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Fecha',
                      value: formattedDate,
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      label: 'Hora',
                      value: formattedTime,
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 5. Frecuencia (máximo 7 días)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recordatorio frecuente',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.anthracite,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _isRecurrent,
                          activeColor: AppColors.primary,
                          onChanged: (val) =>
                              setState(() => _isRecurrent = val),
                        ),
                      ],
                    ),
                    if (_isRecurrent) ...[
                      const Divider(height: 12),
                      Row(
                        children: [
                          Text(
                            'Repetir cada:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.slate,
                            ),
                          ),
                          const Spacer(),
                          for (int d = 1; d <= 7; d++) ...[
                            GestureDetector(
                              onTap: () => setState(() => _recurrenceDays = d),
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(left: 4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _recurrenceDays == d
                                      ? AppColors.primary
                                      : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _recurrenceDays == d
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '${d}d',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _recurrenceDays == d
                                        ? AppColors.white
                                        : AppColors.slate,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _validationError!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 20),

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
                    _isEditing ? 'Guardar cambios' : 'Crear recordatorio',
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
      ),
    );
  }
}

class _MiniFilterChip extends StatelessWidget {
  const _MiniFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.pageBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppColors.neon : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.anthracite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.slateLight,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.anthracite,
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
