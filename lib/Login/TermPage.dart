import 'package:flutter/material.dart';

class TermsBottomSheet extends StatefulWidget {
  const TermsBottomSheet({super.key});

  @override
  State<TermsBottomSheet> createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<TermsBottomSheet> {
  bool agreed = false;

  // Consistent Heading style
  Widget heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Mont', // keep consistent with your app font
        ),
      ),
    );
  }

  // Consistent Body style
  Widget body(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        fontFamily: 'Mont',
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
        return SafeArea(
          child: Padding(
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

                const Text(
                  "Terms of Service",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                    fontFamily: 'Mont',
                  ),
                ),
                const SizedBox(height: 15),

                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading("1. Acceptance of Terms"),
                        body(
                          "By accessing or using the Stunify Student Sharing App (the “App”), you agree to be bound by these Terms of Service. "
                              "If you do not agree, do not use the App. We may update these terms at any time. Continued use means you accept any changes.",
                        ),

                        const SizedBox(height: 12),
                        heading("2. Who Can Use the App (Students Only)"),
                        body(
                            "The App is designed primarily for students. Verified student accounts (for example, emails ending with “ac.uk”) "
                                "can donate items and can also request/receive items. "
                                "Any account that does not have an email ending with “ac.uk” will be treated as a non-student account. "
                                "Non-student accounts may donate items but cannot request or receive items. "
                                "We may update verification rules and access levels over time to protect the student community."
                        ),

                        const SizedBox(height: 12),
                        heading("3. Purpose of the App"),
                        body(
                          "The App helps students share useful items with other students who may need them. Students frequently move accommodation and often dispose of items "
                              "that can still be useful to others. The App supports donation and student requests. In future we may add exchange, sell, or lend features. "
                              "The App is not intended to be used as a commercial marketplace.",
                        ),

                        const SizedBox(height: 12),
                        heading("4. Your Account & Responsibilities"),
                        body(
                          "You are responsible for all activity under your account. You must keep your login credentials safe and provide accurate information. "
                              "You agree not to misuse the App, and you must follow all applicable laws and university rules.",
                        ),

                        const SizedBox(height: 12),
                        heading("5. Listings, Accuracy & Condition of Items"),
                        body(
                          "When you post a donation or request, you must describe the item honestly (condition, defects, missing parts, safety issues). "
                              "Do not post misleading images or descriptions. You are responsible for checking that the item is safe and lawful to share.",
                        ),

                        const SizedBox(height: 12),
                        heading("6. Prohibited Items"),
                        body(
                          "You must not list or exchange prohibited or unsafe items. Examples include (but are not limited to): illegal items, weapons, drugs, alcohol, "
                              "prescription medication, counterfeit goods, stolen goods, explicit content, hazardous materials, and items recalled for safety reasons. "
                              "We may remove prohibited listings without notice.",
                        ),

                        const SizedBox(height: 12),
                        heading("7. Safety, Meetups & Collection"),
                        body(
                          "You are responsible for your safety during meetups and collections. We recommend meeting in a public location on campus, during daylight hours, "
                              "and bringing a friend if possible. Do not share sensitive personal information. If you feel unsafe, do not proceed.",
                        ),

                        const SizedBox(height: 12),
                        heading("8. No Guarantees, No Background Checks"),
                        body(
                          "We do not run criminal background checks and we do not guarantee the identity, behaviour, or intentions of users. "
                              "Use caution when interacting with other users. Report suspicious behaviour immediately.",
                        ),

                        const SizedBox(height: 12),
                        heading("9. Prohibited Behaviour"),
                        body(
                          "You must not: impersonate others; harass, threaten, or discriminate; post hate speech or violent content; attempt scams or fraud; "
                              "spam or advertise unrelated products/services; upload malware or harmful code; or attempt to bypass student-only access rules.",
                        ),

                        const SizedBox(height: 12),
                        heading("10. Content Standards"),
                        body(
                          "Content must be respectful and relevant. You must own the content you upload (images/text) or have permission to use it. "
                              "Do not upload private information about other people.",
                        ),

                        const SizedBox(height: 12),
                        heading("11. Content Ownership & License"),
                        body(
                          "You retain ownership of content you upload. By posting content, you grant Stunify a non-exclusive, worldwide, royalty-free license to host, "
                              "use, display, reproduce, and distribute that content within the App only for operating, improving, and promoting the service.",
                        ),

                        const SizedBox(height: 12),
                        heading("12. Payments (If Added Later)"),
                        body(
                          "If we introduce paid features (for example, selling or service fees), additional terms may apply. Any future payment rules will be shown clearly "
                              "before you use paid features.",
                        ),

                        const SizedBox(height: 12),
                        heading("13. Privacy & Data Protection"),
                        body(
                          "We collect only the personal information necessary to operate the App (such as account information and verification details). "
                              "We do not sell your personal data to third parties. For full details, see our Privacy Policy. "
                              "We take reasonable steps to protect data, but no system is 100% secure.",
                        ),

                        const SizedBox(height: 12),
                        heading("14. Moderation, Removal & Enforcement"),
                        body(
                          "We may review, remove, restrict, or disable content or accounts that violate these Terms or create risk for the community. "
                              "Repeated or severe violations may result in immediate suspension or permanent termination.",
                        ),

                        const SizedBox(height: 12),
                        heading("15. Disputes Between Users"),
                        body(
                          "Stunify is not responsible for disputes between users (for example, no-shows, item condition disagreements, or misunderstandings). "
                              "However, we may provide reporting tools and may take action against accounts that breach these Terms.",
                        ),

                        const SizedBox(height: 12),
                        heading("16. University Not Affiliated"),
                        body(
                          "Unless clearly stated, Stunify is not affiliated with, endorsed by, or officially connected to any university. "
                              "University names and campus references may be used only to describe location or eligibility.",
                        ),

                        const SizedBox(height: 12),
                        heading("17. Disclaimer of Warranties"),
                        body(
                          "The App is provided “as is” and “as available.” We do not guarantee uninterrupted service, accuracy of listings, or outcomes of user interactions. "
                              "Use the App at your own risk.",
                        ),

                        const SizedBox(height: 12),
                        heading("18. Limitation of Liability"),
                        body(
                          "To the maximum extent permitted by law, Stunify is not liable for any loss, injury, damages, or disputes arising from: "
                              "your use of the App, interactions with other users, item condition, or meetup arrangements.",
                        ),

                        const SizedBox(height: 12),
                        heading("19. Contact"),
                        body(
                          "If you have questions or want to report an issue, contact us via the support option inside the App.",
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Checkbox(
                              value: agreed,
                              onChanged: (v) => setState(() => agreed = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                "I agree to the Terms of Service",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Mont',
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: agreed ? () => Navigator.pop(context, true) : null,
                            child: const Text(
                              "Continue",
                              style: TextStyle(fontFamily: 'Mont'),
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
          ),
        );
      },
    );
  }
}
