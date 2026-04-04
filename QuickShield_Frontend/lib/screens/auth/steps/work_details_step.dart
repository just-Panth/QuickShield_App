import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';

class WorkDetailsStep extends StatefulWidget {
  final VoidCallback onSuccess;

  const WorkDetailsStep({super.key, required this.onSuccess});

  @override
  State<WorkDetailsStep> createState() => _WorkDetailsStepState();
}

class _WorkDetailsStepState extends State<WorkDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _workerIdController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedState;
  String? _selectedCity;
  String? _selectedStoreId;
  String? _selectedStoreName;

  List<String> _cities = [];
  List<Map<String, String>> _stores = [];

  @override
  void dispose() {
    _workerIdController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _selectedStoreId = null;
      _selectedStoreName = null;
      _cities = state != null ? AuthService.getCities(state) : [];
      _stores = [];
    });
  }

  void _onCityChanged(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedStoreId = null;
      _selectedStoreName = null;
      _stores = city != null ? AuthService.getStoresForCity(city) : [];
    });
  }

  void _onStoreChanged(String? storeId) {
    final store = _stores.firstWhere((s) => s['id'] == storeId,
        orElse: () => {'id': '', 'name': ''});
    setState(() {
      _selectedStoreId = storeId;
      _selectedStoreName = store['name'];
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.setWorkDetails(
      workerId: _workerIdController.text.trim(),
      state: _selectedState!,
      city: _selectedCity!,
      area: _areaController.text.trim(),
      storeId: _selectedStoreId,
      storeName: _selectedStoreName,
    );

    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QSColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: QSColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined,
                      size: 20, color: QSColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your Worker ID is issued by your gig platform partner.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: QSColors.primaryDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Worker ID
            _label('Worker ID'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _workerIdController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Worker ID is required' : null,
              style: GoogleFonts.inter(color: QSColors.textDark, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'GW-1234567',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // State dropdown
            _label('State'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              validator: (v) => v == null ? 'Select a state' : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.map_outlined),
                hintText: 'Select state',
              ),
              dropdownColor: QSColors.card,
              style: GoogleFonts.inter(color: QSColors.textDark, fontSize: 15),
              items: AuthService.states.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: _onStateChanged,
            ),

            const SizedBox(height: 20),

            // City dropdown (dependent)
            _label('City'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              validator: (v) => v == null ? 'Select a city' : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_city_outlined),
                hintText: 'Select city',
              ),
              dropdownColor: QSColors.card,
              style: GoogleFonts.inter(color: QSColors.textDark, fontSize: 15),
              items: _cities.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: _onCityChanged,
            ),

            const SizedBox(height: 20),

            // Area
            _label('Area'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _areaController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Area is required' : null,
              style: GoogleFonts.inter(color: QSColors.textDark, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'e.g. Andheri West',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // Store dropdown (optional — shows if city selected)
            if (_stores.isNotEmpty) ...[
              _label('Partner Store (optional)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStoreId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.store_outlined),
                  hintText: 'Auto-detected on next step',
                ),
                dropdownColor: QSColors.card,
                style:
                    GoogleFonts.inter(color: QSColors.textDark, fontSize: 15),
                items: _stores.map((s) {
                  return DropdownMenuItem(
                    value: s['id'],
                    child: Text(s['name']!),
                  );
                }).toList(),
                onChanged: _onStoreChanged,
              ),
              const SizedBox(height: 8),
              Text(
                'A nearby store will be auto-assigned if you skip this.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: QSColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: QSColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: QSColors.textOnDarkMid,
      ),
    );
  }
}
