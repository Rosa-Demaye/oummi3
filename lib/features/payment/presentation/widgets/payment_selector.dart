import 'package:flutter/material.dart';
import 'package:oummi3/core/theme/app_theme.dart';
import 'package:oummi3/shared/models/payment_model.dart';

class PaymentSelector extends StatelessWidget {
  final PaymentProvider selectedProvider;
  final Function(PaymentProvider) onProviderSelected;

  const PaymentSelector({
    super.key,
    required this.selectedProvider,
    required this.onProviderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de paiement',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: OumiColors.noirDoux),
        ),
        const SizedBox(height: 16),
        _buildProviderItem(
          provider: PaymentProvider.airtel,
          name: 'Airtel Money',
          logoPath: 'assets/logos/airtel_logo.png', // Placeholder for logo
          color: Colors.red.shade700,
        ),
        const SizedBox(height: 12),
        _buildProviderItem(
          provider: PaymentProvider.moov,
          name: 'Moov Money',
          logoPath: 'assets/logos/moov_logo.png', // Placeholder for logo
          color: Colors.blue.shade900,
        ),
        const SizedBox(height: 12),
        _buildProviderItem(
          provider: PaymentProvider.visa,
          name: 'Carte Visa / Mastercard',
          logoPath: 'assets/logos/visa_logo.png', // Placeholder for logo
          color: OumiColors.bleuSante,
        ),
      ],
    );
  }

  Widget _buildProviderItem({
    required PaymentProvider provider,
    required String name,
    required String logoPath,
    required Color color,
  }) {
    final bool isSelected = selectedProvider == provider;

    return InkWell(
      onTap: () => onProviderSelected(provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : OumiColors.grisFond,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Inline Logo Placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                provider == PaymentProvider.visa ? Icons.credit_card : Icons.account_balance_wallet,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : OumiColors.noirDoux,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
