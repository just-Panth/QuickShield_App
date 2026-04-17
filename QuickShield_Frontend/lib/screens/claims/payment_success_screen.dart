import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const PaymentSuccessScreen({super.key, required this.result});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payoutInr    = widget.result['payout_inr'] ?? 0;
    final claimId      = widget.result['claim_id'] ?? '';
    final txId         = widget.result['upi_reference'] ?? 'QS-${DateTime.now().millisecondsSinceEpoch}';
    final shortClaimId = claimId.length > 8 ? claimId.substring(0, 8).toUpperCase() : claimId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Animated shield icon
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.12),
                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.2),
                        ),
                        child: const Center(
                          child: Text('✅', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Payout amount hero
                Text(
                  '₹$payoutInr',
                  style: GoogleFonts.inter(
                    fontSize: 56, fontWeight: FontWeight.w900,
                    color: Colors.green,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paid to your UPI!',
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'QuickShield has processed your claim successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 36),

                // Transaction details card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Claim ID',
                        value: 'CLM-$shortClaimId',
                        copyable: true,
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _DetailRow(
                        label: 'Transaction ID',
                        value: txId,
                        copyable: true,
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _DetailRow(
                        label: 'Amount transferred',
                        value: '₹$payoutInr',
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Timeline
                _Timeline(),
                const SizedBox(height: 36),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Pop back to the root (Dashboard)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QSColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Done — Back to Home',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        GestureDetector(
          onTap: copyable
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    backgroundColor: QSColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            : null,
          child: Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 6),
                const Icon(Icons.copy, size: 14, color: Colors.white38),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final events = [
      ('Disaster detected',   Icons.warning_amber_rounded, Colors.orange),
      ('Claim verified',      Icons.verified_user,         Colors.blue),
      ('Claim approved',      Icons.thumb_up_alt,          QSColors.primary),
      ('Payment sent',        Icons.payments,              Colors.green),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...List.generate(events.length, (i) {
            final (label, icon, color) = events[i];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    if (i < events.length - 1)
                      Container(width: 2, height: 20, color: Colors.white10),
                  ],
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
