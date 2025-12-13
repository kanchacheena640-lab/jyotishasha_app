import 'package:flutter/material.dart';

class DonationWidget extends StatefulWidget {
  final void Function(int amount)? onDonate;

  const DonationWidget({super.key, this.onDonate});

  @override
  State<DonationWidget> createState() => _DonationWidgetState();
}

class _DonationWidgetState extends State<DonationWidget> {
  int? selectedAmount;
  final TextEditingController _customController = TextEditingController();

  final List<int> presetAmounts = [11, 21, 51, 101];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🙏 Offer Chadava",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presetAmounts.map((amt) {
              final isSelected = selectedAmount == amt;
              return ChoiceChip(
                label: Text("₹$amt"),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    selectedAmount = amt;
                    _customController.clear();
                  });
                },
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: Colors.deepPurple,
                backgroundColor: Colors.deepPurple.shade50,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Or enter custom amount",
              labelStyle: const TextStyle(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onTap: () => setState(() => selectedAmount = null),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text("Offer Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final customVal = int.tryParse(_customController.text);
                final amount = selectedAmount ?? customVal;
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter or select a valid amount"),
                    ),
                  );
                  return;
                }

                // ✅ Frontend-only response (later attach Razorpay)
                widget.onDonate?.call(amount);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🙏 Thank you for your ₹$amount Chadava!"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
