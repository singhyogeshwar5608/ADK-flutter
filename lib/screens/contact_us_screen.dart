import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  static const String routeName = '/contact-us';

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final List<Map<String, dynamic>> _contactInfo = [
    {
      'title': 'Phone',
      'subtitle': 'Call us directly',
      'icon': Icons.phone,
      'color': const Color(0xFF3B82F6),
      'phone': '+918307599904',
      'email': '',
      'whatsapp': '',
    },
    {
      'title': 'Email',
      'subtitle': 'Send us an email',
      'icon': Icons.email,
      'color': const Color(0xFF10B981),
      'phone': '',
      'email': 'familyfarmer26@gmail.com',
      'whatsapp': '',
    },
    {
      'title': 'WhatsApp',
      'subtitle': 'Message us on WhatsApp',
      'icon': Icons.message,
      'color': const Color(0xFF25D366),
      'phone': '',
      'email': '',
      'whatsapp': '+919307599904',
    },
    {
      'title': 'Address',
      'subtitle': 'Visit our office',
      'icon': Icons.location_on,
      'color': const Color(0xFFF59E0B),
      'phone': '',
      'email': '',
      'whatsapp': '',
      'address':
          'Family Farmer Store, Main Gohana Road, Mayur Vihar, Gali Number 4, Near Baroda Bank, Sonipat, Haryana 131001',
    },
  ];

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Could not launch phone dialer');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching phone: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=ADK Support Request',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not launch email app');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching email: $e');
    }
  }

  Future<void> _launchWhatsApp(String whatsappNumber) async {
    final String cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final String whatsappUrl = 'https://wa.me/$cleanNumber';
    final Uri uri = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not launch WhatsApp');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching WhatsApp: $e');
    }
  }

  Future<void> _launchGoogleMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final Uri uri = Uri.parse(googleMapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not launch Google Maps');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching Google Maps: $e');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.mlmGreen,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.mlmGreen,
                    AppColors.mlmGreen.withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mlmGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.contact_support,
                    size: 42,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We\'re here to help! Reach out to us anytime.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('Contact Details'),
            const SizedBox(height: 12),
            _buildContactCard(_contactInfo[0]), // Phone
            const SizedBox(height: 12),
            _buildContactCard(_contactInfo[1]), // Email
            const SizedBox(height: 12),
            _buildContactCard(_contactInfo[2]), // WhatsApp
            const SizedBox(height: 12),
            _buildContactCard(_contactInfo[3]), // Address

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.mlmGreen,
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: contact['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              contact['icon'],
              color: contact['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                contact.containsKey('address')
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['address'] as String,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _launchGoogleMaps(contact['address'] as String),
                            child: Text(
                              'Visit',
                              style: TextStyle(
                                color: AppColors.mlmGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        contact['subtitle'] as String,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildActionButtons(contact),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> contact) {
    final buttons = <Widget>[];

    if (contact['phone'] != null && contact['phone'].toString().isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () => _launchPhone(contact['phone'] as String),
          icon: const Icon(Icons.phone, color: AppColors.mlmGreen),
          tooltip: 'Call',
        ),
      );
    }

    if (contact['email'] != null && contact['email'].toString().isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () => _launchEmail(contact['email'] as String),
          icon: const Icon(Icons.email, color: AppColors.mlmGreen),
          tooltip: 'Email',
        ),
      );
    }

    if (contact['whatsapp'] != null &&
        contact['whatsapp'].toString().isNotEmpty) {
      buttons.add(
        IconButton(
          onPressed: () => _launchWhatsApp(contact['whatsapp'] as String),
          icon: const Icon(Icons.message, color: AppColors.mlmGreen),
          tooltip: 'WhatsApp',
        ),
      );
    }

    if (contact.containsKey('address')) {
      buttons.add(
        IconButton(
          onPressed: () => _copyToClipboard(contact['address'] as String),
          icon: const Icon(Icons.copy, color: AppColors.mlmGreen),
          tooltip: 'Copy Address',
        ),
      );
    }

    return buttons;
  }
}
