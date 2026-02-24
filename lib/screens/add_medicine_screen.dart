// lib/screens/add_medicine_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/constants.dart';
import '../widgets/day_selector.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeatType = AppConstants.repeatDaily;
  List<int> _selectedDays = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _clearEndDate() {
    setState(() {
      _endDate = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate custom days
    if (_repeatType == AppConstants.repeatCustom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check for duplicates
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final isDuplicate = medicineProvider.isDuplicate(
      _nameController.text.trim(),
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (isDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Medicine'),
          content: const Text(
            'A medicine with the same name and time already exists. Do you want to add it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Anyway'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await medicineProvider.addMedicine(
        name: _nameController.text.trim(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        repeatType: _repeatType,
        selectedDays: _repeatType == AppConstants.repeatDaily 
            ? [1, 2, 3, 4, 5, 6, 7] 
            : _selectedDays,
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // Medicine Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'Enter medicine name',
                prefixIcon: Icon(Icons.medication),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: AppConstants.medicineNameMaxLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medicine name';
                }
                if (value.trim().length < AppConstants.medicineNameMinLength) {
                  return 'Name must be at least ${AppConstants.medicineNameMinLength} characters';
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Time Picker
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('Time'),
              subtitle: Text(_formatTime(_selectedTime)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                side: const BorderSide(color: AppColors.border),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Repeat Type
            Text(
              'Repeat Schedule',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.repeatDaily,
                  label: Text('Daily'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: AppConstants.repeatCustom,
                  label: Text('Custom Days'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {_repeatType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _repeatType = newSelection.first;
                  if (_repeatType == AppConstants.repeatDaily) {
                    _selectedDays = [];
                  }
                });
              },
            ),

            // Day Selector (animated)
            AnimatedSize(
              duration: AppConstants.animationMedium,
              curve: Curves.easeInOut,
              child: _repeatType == AppConstants.repeatCustom
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppConstants.spacingMedium),
                      child: DaySelector(
                        selectedDays: _selectedDays,
                        onDaysChanged: (days) {
                          setState(() {
                            _selectedDays = days;
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Start Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectStartDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                side: const BorderSide(color: AppColors.border),
              ),
            ),

            const SizedBox(height: AppConstants.spacingSmall),

            // End Date
            ListTile(
              leading: const Icon(Icons.event, color: AppColors.primary),
              title: const Text('End Date (Optional)'),
              subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'No end date'),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearEndDate,
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _endDate != null ? null : _selectEndDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                side: const BorderSide(color: AppColors.border),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLarge),

            // Enable Alarm Switch
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active, color: AppColors.primary),
              title: const Text('Enable Alarm'),
              subtitle: Text(_isActive ? 'Alarm will ring at scheduled time' : 'Alarm is disabled'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                side: const BorderSide(color: AppColors.border),
              ),
            ),

            const SizedBox(height: AppConstants.spacingLarge * 2),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMedicine,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Medicine'),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMedium),
          ],
        ),
      ),
    );
  }
}
