import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:provider/provider.dart';

class EmojiPickerPage extends StatefulWidget {
  const EmojiPickerPage({super.key});

  @override
  State<EmojiPickerPage> createState() => _EmojiPickerPageState();
}

class _EmojiPickerPageState extends State<EmojiPickerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: EmojiService.getCategoryNames().length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final stateProvider = context.watch<StateProvider>();
    final categories = EmojiService.getCategoryNames();

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      appBar: AppBar(
        backgroundColor: tp.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: tp.primaryColor,
          unselectedLabelColor: tp.secondaryTextColor,
          indicatorColor: tp.primaryColor,
          tabs: categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            categories
                .map(
                  (category) =>
                      _buildEmojiGrid(context, category, tp, stateProvider),
                )
                .toList(),
      ),
    );
  }

  Widget _buildEmojiGrid(
    BuildContext context,
    String category,
    ThemeProvider tp,
    StateProvider stateProvider,
  ) {
    final emojis = EmojiService.getEmojisForCategory(category);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () {
            stateProvider.iconPath = emoji;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
        );
      },
    );
  }
}
