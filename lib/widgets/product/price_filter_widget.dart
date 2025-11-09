import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class PriceFilterWidget extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues> onChanged;

  const PriceFilterWidget({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  @override
  State<PriceFilterWidget> createState() => _PriceFilterWidgetState();
}

class _PriceFilterWidgetState extends State<PriceFilterWidget> {
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(widget.minPrice, widget.maxPrice);
  }

  @override
  void didUpdateWidget(PriceFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minPrice != widget.minPrice || oldWidget.maxPrice != widget.maxPrice) {
      _currentRangeValues = RangeValues(widget.minPrice, widget.maxPrice);
    }
  }

  String _formatPriceFull(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppLocalizations.of(context).translate('filter'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Label Price
          Text(
            AppLocalizations.of(context).price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFA0522D),
            ),
          ),
          const SizedBox(height: 8),
          
          // Instruction and unit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('apply'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('price') + ': ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    'VND',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Range slider
          RangeSlider(
            values: _currentRangeValues,
            min: 0,
            max: widget.maxPrice,
            divisions: 100,
            activeColor: const Color(0xFFA0522D),
            inactiveColor: const Color(0xFFA0522D).withOpacity(0.3),
            labels: RangeLabels(
              _formatPriceFull(_currentRangeValues.start),
              _formatPriceFull(_currentRangeValues.end),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentRangeValues = values;
              });
              widget.onChanged(values);
            },
          ),
          
          const SizedBox(height: 8),
          
          // Price values display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPriceFull(_currentRangeValues.start),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA0522D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatPriceFull(_currentRangeValues.end),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA0522D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

