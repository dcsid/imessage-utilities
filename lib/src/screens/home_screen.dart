import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/utility_kind_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onOpenLink,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final bool Function(String rawLink) onOpenLink;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    final sampleUtility = widget.utilities.first;
    _linkController = TextEditingController(
      text: UtilityLink.forUtility(
        sampleUtility.id,
        kind: sampleUtility.kind.name,
      ).toString(),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFF102A43), Color(0xFF0D5C63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33102A43),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Messages-first utility hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Start in Messages. Go deeper in the app.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'V1 is a When2Meet-style availability utility. The architecture stays generic so polls, checklists, and group picks can slot in later without redoing the app shell.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFE7F0F4),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        widget.onOpenUtility(widget.utilities.first.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4D35E),
                      foregroundColor: const Color(0xFF102A43),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open the availability prototype'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Live utility',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.utilities.map(_buildUtilityCard),
            const SizedBox(height: 24),
            Text(
              'Try a share link',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is the handoff the native iMessage extension will use to drop someone into the Flutter app.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _linkController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Utility link',
                        hintText:
                            'chatutilitieshub://utility/design-sprint-sync',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _previewLink,
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Preview linked utility'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _copySampleLink,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy sample link'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Expansion path',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...UtilityKind.values
                .where((kind) => kind != UtilityKind.availability)
                .map(_buildFutureUtilityCard),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard(UtilityInstance utility) {
    final theme = Theme.of(context);
    final topScore = utility.optionScores.first;
    final accent = utilityKindColor(utility.kind);
    final shareUri = UtilityLink.forUtility(
      utility.id,
      kind: utility.kind.name,
    ).toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => widget.onOpenUtility(utility.id),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(utilityKindIcon(utility.kind), color: accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          utility.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          utility.prompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: const Color(0xFF52667A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatChip(label: utility.kind.label, accent: accent),
                  _StatChip(
                    label:
                        '${utility.responseCount}/${utility.participants.length} responses',
                    accent: accent,
                  ),
                  if (utility.closesAt != null)
                    _StatChip(
                      label: 'Closes ${formatDeadline(utility.closesAt!)}',
                      accent: accent,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best overlap right now',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatUtilityOption(topScore.option),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${topScore.votes} of ${utility.participants.length} people can make it',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52667A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      shareUri,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7C6F64),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFutureUtilityCard(UtilityKind kind) {
    final theme = Theme.of(context);
    final accent = utilityKindColor(kind);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(utilityKindIcon(kind), color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kind.blurb,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF52667A),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copySampleLink() async {
    await Clipboard.setData(ClipboardData(text: _linkController.text));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sample link copied.')));
  }

  void _previewLink() {
    final wasOpened = widget.onOpenLink(_linkController.text);
    if (wasOpened || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That link does not match a known utility yet.'),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
      ),
    );
  }
}
