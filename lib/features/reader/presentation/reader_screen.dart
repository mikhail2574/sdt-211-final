import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/async_state_view.dart';
import '../../library/domain/book.dart';
import '../../library/presentation/library_cubit.dart';
import '../domain/reading_models.dart';
import 'reader_cubit.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.bookId, super.key});

  final String bookId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReaderCubit>().loadBook(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderCubit, ReaderState>(
      listenWhen: (previous, current) {
        return previous.book?.progress != current.book?.progress ||
            previous.errorMessage != current.errorMessage;
      },
      listener: (context, state) {
        final book = state.book;
        if (book != null) {
          context.read<LibraryCubit>().updateBookProgress(
            book.id,
            book.progress,
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final book = state.book;
        final isDark = state.preferences.darkMode;

        return Theme(
          data: isDark ? ThemeData.dark(useMaterial3: true) : Theme.of(context),
          child: Scaffold(
            appBar: AppBar(
              title: Text(book?.title ?? 'Reader'),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: book == null ? null : () => _openSearch(context),
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: 'Reading preferences',
                  onPressed: book == null
                      ? null
                      : () => _openPreferences(context),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            body: switch (state.status) {
              ReaderStatus.initial || ReaderStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ReaderStatus.failure => AsyncStateView(
                icon: Icons.error_outline,
                title: 'Reader unavailable',
                message: state.errorMessage ?? 'Could not open this book.',
                actionLabel: 'Retry',
                onAction: () =>
                    context.read<ReaderCubit>().loadBook(widget.bookId),
              ),
              ReaderStatus.loaded => _ReaderBody(state: state),
            },
          ),
        );
      },
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderCubit>(),
        child: const _SearchSheet(),
      ),
    );
  }

  void _openPreferences(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderCubit>(),
        child: const _PreferencesSheet(),
      ),
    );
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({required this.state});

  final ReaderState state;

  @override
  Widget build(BuildContext context) {
    final book = state.book!;
    final chapter = state.chapter!;
    final preferences = state.preferences;
    final horizontalPadding = preferences.wideMargins ? 30.0 : 18.0;
    final textStyle = TextStyle(
      fontSize: preferences.fontSize,
      height: preferences.lineHeight,
    );

    return Column(
      children: [
        LinearProgressIndicator(value: book.progress.clamp(0, 1)),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              28,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Bookmark chapter',
                    onPressed: () => context.read<ReaderCubit>().addBookmark(),
                    icon: const Icon(Icons.bookmark_add_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ChapterControls(book: book, chapterIndex: state.chapterIndex),
              const SizedBox(height: 16),
              ...chapter.paragraphs.indexed.map(
                (entry) => _ParagraphBlock(
                  paragraph: entry.$2,
                  textStyle: textStyle,
                  isFirst: entry.$1 == 0,
                ),
              ),
              const SizedBox(height: 8),
              if (preferences.aiEnabled && preferences.businessMode)
                _PassiveInsightPrompt(text: chapter.paragraphs.first),
              const SizedBox(height: 16),
              _ReaderCollections(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterControls extends StatelessWidget {
  const _ChapterControls({required this.book, required this.chapterIndex});

  final Book book;
  final int chapterIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: chapterIndex == 0
              ? null
              : () =>
                    context.read<ReaderCubit>().changeChapter(chapterIndex - 1),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        const Spacer(),
        Text('Page ${chapterIndex + 1} / ${book.chapters.length}'),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: chapterIndex >= book.chapters.length - 1
              ? null
              : () =>
                    context.read<ReaderCubit>().changeChapter(chapterIndex + 1),
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({
    required this.paragraph,
    required this.textStyle,
    required this.isFirst,
  });

  final String paragraph;
  final TextStyle textStyle;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(paragraph, style: textStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              IconButton(
                tooltip: 'Highlight paragraph',
                onPressed: () =>
                    context.read<ReaderCubit>().addHighlight(paragraph),
                icon: const Icon(Icons.border_color_outlined),
              ),
              IconButton(
                tooltip: 'Add note',
                onPressed: () => _openNoteEditor(context, paragraph),
                icon: const Icon(Icons.note_add_outlined),
              ),
              _InsightActionButton(
                text: paragraph,
                type: InsightType.summary,
                icon: Icons.summarize_outlined,
              ),
              _InsightActionButton(
                text: paragraph,
                type: InsightType.visual,
                icon: Icons.account_tree_outlined,
              ),
              _InsightActionButton(
                text: paragraph,
                type: InsightType.simpleExplanation,
                icon: Icons.lightbulb_outline,
              ),
              _InsightActionButton(
                text: paragraph,
                type: InsightType.actionSteps,
                icon: Icons.checklist_outlined,
              ),
            ],
          ),
          Divider(
            height: 24,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  void _openNoteEditor(BuildContext context, String selectedText) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderCubit>(),
        child: _NoteEditor(selectedText: selectedText),
      ),
    );
  }
}

class _InsightActionButton extends StatelessWidget {
  const _InsightActionButton({
    required this.text,
    required this.type,
    required this.icon,
  });

  final String text;
  final InsightType type;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        return IconButton.filledTonal(
          tooltip: _insightLabel(type),
          onPressed: state.preferences.aiEnabled && !state.isGeneratingInsight
              ? () => context.read<ReaderCubit>().generateInsight(text, type)
              : null,
          icon: state.isGeneratingInsight
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
        );
      },
    );
  }
}

class _PassiveInsightPrompt extends StatelessWidget {
  const _PassiveInsightPrompt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.psychology_outlined),
        title: const Text('Create local AI note'),
        subtitle: const Text('Send this page excerpt to Ollama.'),
        trailing: FilledButton(
          onPressed: () => context.read<ReaderCubit>().generateInsight(
            text,
            InsightType.visual,
          ),
          child: const Text('Generate'),
        ),
      ),
    );
  }
}

class _ReaderCollections extends StatelessWidget {
  const _ReaderCollections({required this.state});

  final ReaderState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.insights.isEmpty)
          const Text(
            'Generated summaries, visuals, and action cards appear here.',
          ),
        ...state.insights.map((insight) => _InsightCardView(insight: insight)),
        const SizedBox(height: 18),
        Text('Bookmarks', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.bookmarks.isEmpty) const Text('No bookmarks yet.'),
        ...state.bookmarks.map(
          (bookmark) => ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text(bookmark.label),
            subtitle: Text('Chapter ${bookmark.chapterIndex + 1}'),
            trailing: IconButton(
              tooltip: 'Delete bookmark',
              onPressed: () =>
                  context.read<ReaderCubit>().deleteBookmark(bookmark.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Highlights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.highlights.isEmpty) const Text('No highlights yet.'),
        ...state.highlights.map(
          (highlight) => ListTile(
            leading: const Icon(Icons.border_color),
            title: Text(
              highlight.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Delete highlight',
              onPressed: () =>
                  context.read<ReaderCubit>().deleteHighlight(highlight.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Notes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.notes.isEmpty) const Text('No notes yet.'),
        ...state.notes.map(
          (note) => ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(note.body),
            subtitle: Text(
              note.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: 'Delete note',
              onPressed: () => context.read<ReaderCubit>().deleteNote(note.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightCardView extends StatelessWidget {
  const _InsightCardView({required this.insight});

  final InsightCard insight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.body),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.points
                  .map((point) => Chip(label: Text(point)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  const _SearchSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                autofocus: true,
                onChanged: context.read<ReaderCubit>().updateSearch,
                decoration: const InputDecoration(
                  labelText: 'Search inside book',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Text('${state.searchResults.length} results'),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: state.searchResults
                      .map(
                        (result) => ListTile(
                          leading: const Icon(Icons.manage_search),
                          title: Text(
                            result,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreferencesSheet extends StatelessWidget {
  const _PreferencesSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        final prefs = state.preferences;
        final cubit = context.read<ReaderCubit>();
        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text(
              'Reading Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Font size ${prefs.fontSize.round()}'),
            Slider(
              value: prefs.fontSize,
              min: 14,
              max: 26,
              divisions: 12,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(fontSize: value)),
            ),
            Text('Line height ${prefs.lineHeight.toStringAsFixed(2)}'),
            Slider(
              value: prefs.lineHeight,
              min: 1.2,
              max: 2,
              divisions: 8,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(lineHeight: value)),
            ),
            SwitchListTile(
              value: prefs.wideMargins,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(wideMargins: value)),
              title: const Text('Wide margins'),
              secondary: const Icon(Icons.format_indent_increase),
            ),
            SwitchListTile(
              value: prefs.darkMode,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(darkMode: value)),
              title: const Text('Dark reader theme'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            SwitchListTile(
              value: prefs.aiEnabled,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(aiEnabled: value)),
              title: const Text('AI augmentation'),
              secondary: const Icon(Icons.auto_awesome_outlined),
            ),
            SwitchListTile(
              value: prefs.businessMode,
              onChanged: (value) =>
                  cubit.updatePreferences(prefs.copyWith(businessMode: value)),
              title: const Text('Business learning mode'),
              subtitle: const Text(
                'Shows diagrams, summaries, examples, and actions.',
              ),
              secondary: const Icon(Icons.business_center_outlined),
            ),
          ],
        );
      },
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.selectedText});

  final String selectedText;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Note', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            widget.selectedText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                context.read<ReaderCubit>().saveNote(
                  text: widget.selectedText,
                  body: _controller.text,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save note'),
            ),
          ),
        ],
      ),
    );
  }
}

String _insightLabel(InsightType type) {
  switch (type) {
    case InsightType.summary:
      return 'Summarize';
    case InsightType.visual:
      return 'Visualize';
    case InsightType.example:
      return 'Generate example';
    case InsightType.actionSteps:
      return 'Create action steps';
    case InsightType.simpleExplanation:
      return 'Explain simpler';
  }
}
