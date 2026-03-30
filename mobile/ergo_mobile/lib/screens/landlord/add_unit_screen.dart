import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/building_service.dart';

class AddUnitScreen extends StatefulWidget {
  final Map<String, dynamic> building;

  const AddUnitScreen({super.key, required this.building});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _rentController = TextEditingController();
  bool _isLoading = false;

  final _buildingService = BuildingService();

  @override
  void dispose() {
    _unitNumberController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Convert Naira to Kobo
    final rentNaira = double.tryParse(_rentController.text) ?? 0;
    final rentKobo = (rentNaira * 100).toInt();

    final success = await _buildingService.createUnit(
      buildingId: widget.building['id'],
      unitNumber: _unitNumberController.text.trim(),
      rentAmountKobo: rentKobo,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true); // Return true to refresh list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add unit. Please try again.'),
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
        title: const Text('Add Unit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              Text(
                'Adding Unit to ${widget.building['name']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the details of the apartment, flat, or shop.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              
              const Text('Unit Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unitNumberController,
                validator: (value) => value!.isEmpty ? 'Please enter unit number' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Flat A1, Unit 4, Shop 10',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Monthly Rent (₦)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter rent amount' : null,
                decoration: InputDecoration(
                  hintText: 'Amount in Naira',
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: '₦ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateUnit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
