import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/building_service.dart';

class AddBuildingScreen extends StatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  State<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends State<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitsController = TextEditingController();
  bool _isLoading = false;

  final _buildingService = BuildingService();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _buildingService.createBuilding(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      totalUnits: int.tryParse(_unitsController.text) ?? 0,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true); // Return true to indicate success for refresh
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add building. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add New Property', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Property Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Basic information about the building you want to manage.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              
              const Text('Building Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'Please enter building name' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Eko Atlantic Towers',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Full Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                validator: (value) => value!.isEmpty ? 'Please enter full address' : null,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Plot 24, Ahmadu Bello Way, VI, Lagos',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Total Units', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter number of units' : null,
                decoration: InputDecoration(
                  hintText: 'Number of apartments/offices',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateBuilding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Building', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
