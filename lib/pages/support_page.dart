import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  // Function to launch a URL (mailto, tel, https)
  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // FIX: Check if the widget is still in the tree after an async gap.
      if (!context.mounted) return;
      // If it fails, show a notification to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF36067e);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // A more dynamic and attractive header
          const SliverAppBar(
            expandedHeight: 220.0,
            backgroundColor: primaryColor,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              // The title has been removed as requested
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, Color(0xFF6A1B9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.support_agent,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          // Page content in a list format
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FAQ section title
                      _buildSectionTitle('Frequently Asked Questions (FAQ)'),
                      const SizedBox(height: 16),
                      _buildFaqSection(),
                      const SizedBox(height: 30),

                      // Contact section title
                      _buildSectionTitle('Contact Us'),
                      const SizedBox(height: 16),
                      _buildContactCard(
                        context: context,
                        icon: Icons.email_outlined,
                        title: 'Send an Email',
                        subtitle: 'Get help via email',
                        onTap: () => _launchURL(
                            context, 'mailto:joseparhusip7@gmail.com'),
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildContactCard(
                        context: context,
                        icon: Icons.phone_in_talk_outlined,
                        title: 'Phone Call',
                        subtitle: 'Speak directly with our team',
                        onTap: () => _launchURL(context, 'tel:+6281292690095'),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildContactCard(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: 'WhatsApp',
                        subtitle: 'Chat with us for a quick response',
                        onTap: () =>
                            _launchURL(context, 'https://wa.me/6281292690095'),
                        color: Colors.green,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the title of each section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Widget for the FAQ list
  Widget _buildFaqSection() {
    return const Column(
      children: [
        FaqTile(
          question: 'How do I change my profile?',
          answer:
              'You can change your profile by going to the profile page and pressing the "Edit Profile" button. There you can change your name, email, and profile picture.',
        ),
        FaqTile(
          question: 'Is my data secure?',
          answer:
              'Of course. We use end-to-end encryption to protect all user data. Your privacy and security are our top priorities.',
        ),
        FaqTile(
          question: 'How do I delete my account?',
          answer:
              'To delete your account, go to the "Settings" menu on the profile page, then select the "Delete Account" option. Please note that this action is permanent and cannot be undone.',
        ),
      ],
    );
  }

  // Widget for the redesigned contact card
  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Widget for each FAQ item, now with a cleaner design
class FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const FaqTile({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        iconColor: const Color(0xFF36067e),
        collapsedIconColor: Colors.grey[600],
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}
