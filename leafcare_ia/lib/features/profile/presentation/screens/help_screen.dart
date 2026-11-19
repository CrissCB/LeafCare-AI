import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/profile/data/help_content_data.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/help_hero_header.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/help_tab_sections.dart';

enum HelpSectionTab { support, about }

/// Pantalla unificada de "Ayuda y LeafCare AI" (`/help`).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, this.initialTab = HelpSectionTab.support});

  final HelpSectionTab initialTab;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late HelpSectionTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant HelpScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() => _selectedTab = widget.initialTab);
    }
  }

  Future<void> _copySupportEmail() async {
    await Clipboard.setData(
      const ClipboardData(text: HelpContentData.supportEmail),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Correo ${HelpContentData.supportEmail} copiado'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HelpHeroHeader(
              selectedTab: _selectedTab,
              onTabChanged: (tab) => setState(() => _selectedTab = tab),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.paddingOf(context).bottom + 36,
            ),
            sliver: SliverToBoxAdapter(
              child: _selectedTab == HelpSectionTab.support
                  ? HelpSupportSection(onCopyEmail: _copySupportEmail)
                  : const HelpAboutSection(),
            ),
          ),
        ],
      ),
    );
  }
}
