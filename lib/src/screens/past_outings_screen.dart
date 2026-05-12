import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/outing_sticker.dart';
import 'package:flutter/material.dart';

/// Archive of wrapped-up outings. Pushed from HomeScreen so it lives
/// outside the main router.
class PastOutingsScreen extends StatefulWidget {
  const PastOutingsScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onCopyLink,
    required this.onDeleteUtility,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final ValueChanged<UtilityInstance> onCopyLink;
  final ValueChanged<UtilityInstance> onDeleteUtility;

  @override
  State<PastOutingsScreen> createState() => _PastOutingsScreenState();
}

class _PastOutingsScreenState extends State<PastOutingsScreen> {
  late List<UtilityInstance> _utilities;

  @override
  void initState() {
    super.initState();
    _utilities = List.of(widget.utilities);
  }

  void _handleDelete(UtilityInstance utility) {
    widget.onDeleteUtility(utility);
    setState(() {
      _utilities.removeWhere((u) => u.id == utility.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${utility.title}" deleted.')),
      );
    }
    if (_utilities.isEmpty && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lazy list: header lives at index 0, archived stickers occupy
    // indices 1..n. ListView.builder only inflates what's near the
    // viewport, which keeps long archives snappy on cold open.
    final itemCount = 1 + _utilities.length;

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ArchiveHeader(
                      theme: theme,
                      count: _utilities.length,
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  }
                  final utility = _utilities[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: RepaintBoundary(
                      child: OutingSticker(
                        utility: utility,
                        muted: true,
                        onOpen: () {
                          widget.onOpenUtility(utility.id);
                          // The route stack still holds the home screen,
                          // so popping back to it lets the router open
                          // the selected utility.
                          Navigator.of(context).maybePop();
                        },
                        onCopyLink: () => widget.onCopyLink(utility),
                        onDelete: () => _handleDelete(utility),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader({
    required this.theme,
    required this.count,
    required this.onBack,
  });

  final ThemeData theme;
  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackButton(onTap: onBack),
            const SizedBox(width: 12),
            Text(
              'Plan Together',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: AppPalette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'THE ARCHIVE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppPalette.mutedText,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontSize: 44,
            ),
            children: const [
              TextSpan(text: 'Plans that\n'),
              TextSpan(
                text: 'happened',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppPalette.primary,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '$count past ${count == 1 ? 'outing' : 'outings'} — reopen any to look back, or remove the ones you no longer need.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppPalette.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border, width: 1.4),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppPalette.ink,
          size: 20,
        ),
      ),
    );
  }
}
