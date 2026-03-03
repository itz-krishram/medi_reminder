// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/log_provider.dart';
import '../utils/constants.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final medicineProvider = Provider.of<MedicineProvider>(
      context,
      listen: false,
    );
    final logProvider = Provider.of<LogProvider>(context, listen: false);

    await Future.wait([
      medicineProvider.loadMedicines(),
      logProvider.loadLogs(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _navigateToAddMedicine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
    ).then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? _buildHomeAppBar() : null,
      body: _currentIndex == 0 ? _buildHomeBody() : const HistoryScreen(),
      floatingActionButton: _currentIndex == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: const AssetImage('assets/images/app_logo.png'),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 10),
          const Text('Today\'s Medicines'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildHomeBody() {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, child) {
        if (medicineProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (medicineProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.withOpacity(0.5),
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Text(
                  'Error loading medicines',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  medicineProvider.error!,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final todayMedicines = medicineProvider.todayMedicines;

        if (todayMedicines.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMedium,
            ),
            itemCount: todayMedicines.length,
            itemBuilder: (context, index) {
              final medicine = todayMedicines[index];
              return MedicineCard(
                medicine: medicine,
                onTap: () => _showMedicineDetails(medicine),
                onToggle: () => _toggleMedicine(medicine.id),
                onDelete: () => _deleteMedicine(medicine.id, medicine.name),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 120,
              color: AppColors.textDisabled.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              'No medicines scheduled today',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Tap the + button to add your first medicine reminder',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToAddMedicine,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
    );
  }

  void _showMedicineDetails(medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.access_time, 'Time', medicine.formattedTime),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildDetailRow(Icons.repeat, 'Schedule', medicine.repeatSchedule),
            const SizedBox(height: AppConstants.spacingSmall),
            _buildDetailRow(
              Icons.calendar_today,
              'Start Date',
              '${medicine.startDate.day}/${medicine.startDate.month}/${medicine.startDate.year}',
            ),
            if (medicine.endDate != null) ...[
              const SizedBox(height: AppConstants.spacingSmall),
              _buildDetailRow(
                Icons.event,
                'End Date',
                '${medicine.endDate!.day}/${medicine.endDate!.month}/${medicine.endDate!.year}',
              ),
            ],
            const SizedBox(height: AppConstants.spacingSmall),
            _buildDetailRow(
              Icons.power_settings_new,
              'Status',
              medicine.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppConstants.iconSizeSmall, color: AppColors.primary),
        const SizedBox(width: AppConstants.spacingSmall),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
      ],
    );
  }

  Future<void> _toggleMedicine(String id) async {
    final medicineProvider = Provider.of<MedicineProvider>(
      context,
      listen: false,
    );

    try {
      await medicineProvider.toggleMedicineStatus(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMedicine(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medicineProvider = Provider.of<MedicineProvider>(
        context,
        listen: false,
      );

      try {
        await medicineProvider.deleteMedicine(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting medicine: $e')),
          );
        }
      }
    }
  }
}
