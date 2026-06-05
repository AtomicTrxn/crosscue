import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/source_links.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external URL. Injectable so widget tests can assert the launched
/// URL without the `url_launcher` platform channel (mirrors
/// `CompletionSheet.resultShare`).
typedef PuzzleLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLaunch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Shows the reusable puzzle-info bottom sheet: title + attribution and, for
/// sources with a derivable link (Crosshare), an "Open on Crosshare" action.
Future<void> showPuzzleInfoSheet(
  BuildContext context,
  PuzzleMetadata metadata, {
  PuzzleLinkLauncher? launch,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => PuzzleInfoSheet(metadata: metadata, launch: launch),
  );
}

/// Attribution surface for a single puzzle. Local imports show metadata only
/// (no source link); Crosshare puzzles also expose "Open on Crosshare".
class PuzzleInfoSheet extends StatelessWidget {
  const PuzzleInfoSheet({super.key, required this.metadata, this.launch});

  final PuzzleMetadata metadata;
  final PuzzleLinkLauncher? launch;

  @override
  Widget build(BuildContext context) {
    final sourceUrl = crosshareUrlFor(metadata);
    final sourceName = sourceNameFor(metadata.sourceId);
    final author = metadata.author.trim();
    final copyright = metadata.copyright.trim();
    final publishDate = metadata.publishDate;
    final title = metadata.title.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? 'Puzzle info' : title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (author.isNotEmpty) _InfoRow(label: 'Author', value: author),
            if (publishDate != null)
              _InfoRow(
                label: 'Published',
                value: formatPuzzlePublishDateLong(publishDate),
              ),
            if (sourceName != null)
              _InfoRow(label: 'Source', value: sourceName),
            if (copyright.isNotEmpty)
              _InfoRow(label: 'Copyright', value: copyright),
            if (sourceUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _open(context, sourceUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open on Crosshare'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri url) async {
    final navigator = Navigator.of(context);
    await (launch ?? _defaultLaunch)(url);
    await navigator.maybePop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.crosscueOnSurface3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: context.crosscueOnSurface1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
