import 'package:flutter/material.dart';

class TermsBottomSheet extends StatefulWidget {
  @override
  _TermsBottomSheetState createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<TermsBottomSheet> {
  bool agreed = false;

  // Function for consistent Heading style with Montserrat
  Text heading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat', // Set to Montserrat
      ),
    );
  }

  // Function for consistent Body style with Montserrat
  Text body(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        fontFamily: 'Mont', // Set to Montserrat
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              Text( // Changed to use Text widget with Montserrat
                "Terms of Service",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                  fontFamily: 'Mont', // Set to Montserrat
                ),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. Acceptance of Terms ---
                      heading("1. Acceptance of Terms"),
                      body(
                          "By accessing or using the **Stunify Student Sharing App** (the \"App\"), you agree to be bound by these Terms of Service. If you do not agree, do not use the App. We may update these terms at any time, and your continued use means you accept the changes."),

                      const SizedBox(height: 10),
                      // --- 2. Purpose of the App ---
                      heading("2. Purpose of the App"),
                      body(
                          "The App is a platform designed exclusively for currently enrolled students to **share and access educational resources**, including lecture notes, summaries, study guides, and general academic tips. It is not intended for commercial use or the sale of materials."),

                      const SizedBox(height: 10),
                      // --- 3. User Responsibilities ---
                      heading("3. User Responsibilities & Content Standards"),
                      body(
                          "Users must ensure all uploaded content is **relevant, accurate to the best of their knowledge, and belongs to them** or they have the necessary rights to share it. You are responsible for all activity under your account. Content must be respectful and free of malware, viruses, or inappropriate language."),

                      const SizedBox(height: 10),
                      // --- 4. Prohibited Activities ---
                      heading("4. Prohibited Activities"),
                      body(
                          "You are strictly prohibited from: (a) Uploading **plagiarized or copyrighted materials** without permission. (b) Sharing **exam papers, live assessment materials, or explicit cheating aids**. (c) Impersonating any person or entity. (d) Posting **hate speech, harassment, or offensive/violent content**. (e) Using the App for commercial promotion or unsolicited spam."),

                      const SizedBox(height: 10),
                      // --- 5. Content Ownership ---
                      heading("5. Content Ownership and License"),
                      body(
                          "You **retain all ownership rights** to the content you upload. By posting content, you grant Stunify a worldwide, non-exclusive, royalty-free, and transferrable license to **use, display, reproduce, and distribute** the content *only* within the App for the purpose of operating and promoting the service."),

                      const SizedBox(height: 10),
                      // --- 6. Privacy and Data Protection ---
                      heading("6. Privacy and Data Protection"),
                      body(
                          "We are committed to protecting your privacy. We will only collect personal information necessary for account creation and App functionality (e.g., student ID verification where applicable). **We do not sell your personal data** to third parties. Our full **Privacy Policy** outlines data handling and security in detail."),

                      const SizedBox(height: 10),
                      // --- 7. Safety and Reporting ---
                      heading("7. Content Removal and Account Termination"),
                      body(
                          "Stunify reserves the right to **review, remove, or restrict access** to any content that violates these Terms or is otherwise harmful. Repeated or severe violations will result in the **immediate suspension or permanent termination** of your account without notice."),

                      const SizedBox(height: 10),
                      // --- 8. Disclaimer ---
                      heading("8. Disclaimer of Warranties"),
                      body(
                          "The App and its content are provided \"as is.\" We **do not guarantee the completeness, accuracy, or quality** of any student-uploaded content. Use of the materials is at your own risk. Stunify is not responsible for any academic or other consequences resulting from the use of shared resources."),

                      const SizedBox(height: 30),

                      // Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: agreed,
                            onChanged: (v) =>
                                setState(() => agreed = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to the Terms of Service",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Mont'), // Set to Montserrat
                            ),
                          ),
                        ],
                      ),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: agreed
                              ? () => Navigator.pop(context, true)
                              : null,
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                                fontFamily: 'Mont'), // Set to Montserrat
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}