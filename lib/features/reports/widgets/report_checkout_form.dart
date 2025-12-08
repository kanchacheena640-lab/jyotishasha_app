// lib/features/reports/widgets/report_checkout_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// ⭐ AUTOFILL KE LIYE IMPORT
import 'package:firebase_auth/firebase_auth.dart';

class ReportCheckoutForm extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  final Function(Map<String, dynamic>) onFormUpdated;

  const ReportCheckoutForm({
    super.key,
    required this.initialProfile,
    required this.onFormUpdated,
  });

  @override
  State<ReportCheckoutForm> createState() => _ReportCheckoutFormState();
}

class _ReportCheckoutFormState extends State<ReportCheckoutForm> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController tobCtrl;
  late TextEditingController pobCtrl;

  String dob = "";
  String tob = "";
  double? lat;
  double? lng;
  String language = "en";

  @override
  void initState() {
    super.initState();

    Map<String, dynamic> p = {};
    if (widget.initialProfile.isNotEmpty) {
      p = Map<String, dynamic>.from(widget.initialProfile);
    }

    debugPrint("🧾 ReportCheckoutForm → initialProfile: $p");

    // NAME
    nameCtrl = TextEditingController(text: p["name"]?.toString() ?? "");

    // ⭐ EMAIL AUTOFILL — Firebase se pull
    final firebaseEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    emailCtrl = TextEditingController(text: firebaseEmail);

    // POB
    pobCtrl = TextEditingController(text: p["pob"]?.toString() ?? "");

    // DOB
    dob = p["dob"]?.toString() ?? "";
    if (dob.isNotEmpty) {
      try {
        final d = DateTime.parse(dob);
        dobCtrl = TextEditingController(
          text: DateFormat('dd MMM yyyy').format(d),
        );
      } catch (_) {
        dobCtrl = TextEditingController();
      }
    } else {
      dobCtrl = TextEditingController();
    }

    // TOB
    tob = p["tob"]?.toString() ?? "";
    if (tob.isNotEmpty) {
      try {
        final parts = tob.split(":");
        final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
        tobCtrl = TextEditingController(text: DateFormat('hh:mm a').format(dt));
      } catch (_) {
        tobCtrl = TextEditingController();
      }
    } else {
      tobCtrl = TextEditingController();
    }

    lat = (p["lat"] is num) ? (p["lat"] as num).toDouble() : null;
    lng = (p["lng"] is num) ? (p["lng"] as num).toDouble() : null;
    language = p["language"]?.toString() ?? "en";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  void _notifyParent() {
    widget.onFormUpdated({
      "name": nameCtrl.text,
      "email": emailCtrl.text,
      "dob": dob,
      "tob": tob,
      "pob": pobCtrl.text,
      "lat": lat,
      "lng": lng,
      "language": language,
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob.isNotEmpty
          ? DateTime.parse(dob)
          : DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      dob =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      dobCtrl.text = DateFormat('dd MMM yyyy').format(picked);
      _notifyParent();
    }
  }

  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      tob =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      final dt = DateTime(0, 1, 1, picked.hour, picked.minute);
      tobCtrl.text = DateFormat('hh:mm a').format(dt);
      _notifyParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ NOTE
        Text(
          "Ordering for someone else? Update the birth details below.",
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // NAME
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: t.checkout_name),
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 12),

        // EMAIL — autofilled + required
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: t.checkout_email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 20),

        // DOB
        TextFormField(
          controller: dobCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: t.checkout_dob,
            suffixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          onTap: _pickDob,
        ),
        const SizedBox(height: 12),

        // TOB
        TextFormField(
          controller: tobCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: t.checkout_tob,
            suffixIcon: const Icon(Icons.access_time_rounded),
          ),
          onTap: _pickTob,
        ),
        const SizedBox(height: 12),

        // POB
        Text(
          t.checkout_pob,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade700,
          ),
        ),
        const SizedBox(height: 6),

        GooglePlaceAutoCompleteTextField(
          textEditingController: pobCtrl,
          googleAPIKey: dotenv.env["GOOGLE_MAPS_API_KEY"] ?? "",
          debounceTime: 800,
          isLatLngRequired: true,
          itemClick: (Prediction p) {
            pobCtrl.text = p.description ?? "";
            _notifyParent();
          },
          getPlaceDetailWithLatLng: (Prediction p) {
            final lt = double.tryParse(p.lat ?? "");
            final ln = double.tryParse(p.lng ?? "");
            if (lt != null && ln != null) {
              lat = lt;
              lng = ln;
              pobCtrl.text = p.description ?? "";
              _notifyParent();
            }
          },
          inputDecoration: InputDecoration(
            hintText: t.checkout_pob,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // LANGUAGE
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: InputDecoration(labelText: t.checkout_language),
          items: [
            DropdownMenuItem(value: "en", child: Text(t.checkout_language_en)),
            DropdownMenuItem(value: "hi", child: Text(t.checkout_language_hi)),
          ],
          onChanged: (v) {
            language = v ?? "en";
            _notifyParent();
          },
        ),
      ],
    );
  }
}
