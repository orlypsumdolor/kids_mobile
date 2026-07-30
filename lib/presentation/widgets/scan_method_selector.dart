import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ScanMethodSelector extends StatelessWidget {
  final VoidCallback onQRScan;
  final VoidCallback onRFIDScan;

  const ScanMethodSelector({
    super.key,
    required this.onQRScan,
    required this.onRFIDScan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Scan Method',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onQRScan,
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.navy),
                    label: const Text('QR Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRFIDScan,
                    icon: const Icon(Icons.nfc, color: AppTheme.textSecondary),
                    label: const Text('RFID Tag'),
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
