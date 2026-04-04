import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class LocationPermissionStep extends StatefulWidget {
  final VoidCallback onSuccess;

  const LocationPermissionStep({super.key, required this.onSuccess});

  @override
  State<LocationPermissionStep> createState() => _LocationPermissionStepState();
}

class _LocationPermissionStepState extends State<LocationPermissionStep> {
  bool _granted = false;
  bool _attempted = false;

  Future<void> _requestLocation() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.requestLocationAndCapture();
    if (mounted) {
      setState(() {
        _granted = ok;
        _attempted = true;
      });
    }
  }

  void _finish() {
    final auth = context.read<AuthProvider>();
    // CRITICAL: auto-login after registration — never go back to login
    auth.completeOnboarding();
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  color: QSColors.primary.withOpacity(0.35),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _granted
                        ? Icons.check_circle_rounded
                        : Icons.location_on_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _granted ? 'Location captured!' : 'Enable location access',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _granted
                      ? 'Your GPS coordinates have been saved successfully.'
                      : 'We use your location to calculate accurate risk scores and set your weekly premium.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_granted && auth.userProfile.latitude != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '📍 ${auth.userProfile.latitude!.toStringAsFixed(4)}, ${auth.userProfile.longitude!.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Benefits
          _benefit(Icons.shield_rounded, 'Real-time risk assessment'),
          _benefit(Icons.trending_down_rounded, 'Lower premium in safe zones'),
          _benefit(Icons.speed_rounded, 'Faster claim processing'),

          // Error / denied message
          if (auth.error != null && _attempted) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: QSColors.orangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: QSColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${auth.error!} You can still continue.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: QSColors.orange,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Action button
          if (!_granted)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: auth.isLoading ? null : _requestLocation,
                icon: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(
                  auth.isLoading ? 'Getting location...' : 'Enable Location',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QSColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: QSColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          if (_granted || (_attempted && auth.error != null))
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _granted
                      ? QSColors.green
                      : QSColors.primary,
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
                      _granted ? 'Complete Setup' : 'Skip & Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _granted
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: QSColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: QSColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: QSColors.textOnDarkMid,
            ),
          ),
        ],
      ),
    );
  }
}
