import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/top_bar.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  AppState? _appState;
  bool _listenerAttached = false;
  bool _submitting = false;
  int _detectedCount = 0;
  final List<String> _suggestions = <String>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = context.read<AppState>();
    if (!_listenerAttached) {
      _controller.addListener(_handleTextChanged);
      _listenerAttached = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final state = _appState;
    if (!mounted || state == null) return;

    final prefix = _activePrefix();
    final suggestions =
        prefix.length >= 2 ? state.resolver.suggest(prefix) : const <String>[];
    final text = _controller.text.trim();
    final count = text.isEmpty ? 0 : state.parser.parse(text).length;

    setState(() {
      _suggestions
        ..clear()
        ..addAll(suggestions);
      _detectedCount = count;
    });
  }

  String _activePrefix() {
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return '';

    final text = _controller.text;
    final rawOffset = selection.baseOffset;
    final offset = rawOffset < 0
        ? text.length
        : (rawOffset > text.length ? text.length : rawOffset);
    final before = text.substring(0, offset);
    final match = RegExp(r'#?[A-Za-zА-Яа-яЁё0-9_]+$').firstMatch(before);
    if (match == null) return '';

    var word = match.group(0) ?? '';
    if (word.startsWith('#')) word = word.substring(1);
    return word.length >= 2 ? word : '';
  }

  int _safeCursor() {
    final selection = _controller.selection;
    if (!selection.isValid) return _controller.text.length;
    if (selection.baseOffset < 0) return _controller.text.length;
    if (selection.baseOffset > _controller.text.length) {
      return _controller.text.length;
    }
    return selection.baseOffset;
  }

  void _insertSubject(String subject, {required bool replaceActiveWord}) {
    final state = _appState;
    if (state == null) return;

    final tag = '#${state.resolver.tagFor(subject)}';
    final text = _controller.text;
    final cursor = _safeCursor();
    final before = text.substring(0, cursor);
    var start = cursor;

    if (replaceActiveWord) {
      final match = RegExp(r'#?[A-Za-zА-Яа-яЁё0-9_]*$').firstMatch(before);
      if (match != null) start = match.start;
    }

    final beforeInsertion = text.substring(0, start);
    final afterInsertion = text.substring(cursor);
    final needsSpace = beforeInsertion.isNotEmpty &&
        !beforeInsertion.endsWith(' ') &&
        !beforeInsertion.endsWith('\n');
    final needsTrailingSpace =
        afterInsertion.isEmpty || !afterInsertion.startsWith(' ');
    final insertion =
        '${needsSpace ? ' ' : ''}$tag${needsTrailingSpace ? ' ' : ''}';
    final updated = text.replaceRange(start, cursor, insertion);
    final newOffset = start + insertion.length;

    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _focusNode.requestFocus();
  }

  Future<void> _distribute() async {
    final state = _appState;
    if (state == null || _submitting) return;

    final strings = state.strings;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      showAppSnackBar(
        context,
        strings.emptyInputMessage,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      _focusNode.requestFocus();
      return;
    }

    setState(() => _submitting = true);
    final count = await state.distribute(text);
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _detectedCount = 0;
      _suggestions.clear();
    });
    _controller.clear();
    _focusNode.unfocus();

    if (count == 0) {
      showAppSnackBar(
        context,
        strings.parseFailedMessage,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }

    showAppSnackBar(
      context,
      strings.addedTasks(count),
      icon: Icons.auto_awesome_rounded,
    );
  }

  void _toggleTheme() {
    final state = _appState;
    if (state == null) return;
    state.setThemeMode(
      context.isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return SafeArea(
      bottom: false,
      child: MaxWidthBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: keyboardOpen
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        children: <Widget>[
                          TopBar(
                            title: strings.newTitle,
                            trailing: RoundIconButton(
                              icon: context.isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              tooltip: context.isDark
                                  ? strings.lightTheme
                                  : strings.darkTheme,
                              onTap: _toggleTheme,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: palette.border),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.28 : 0.04,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: palette.accent,
                            style: TextStyle(
                              fontSize: 16.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: strings.inputHint,
                              hintStyle: TextStyle(
                                fontSize: 16.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _suggestions.isEmpty
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: palette.accentSoft,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 7),
                                          child: Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 15,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: <Widget>[
                                              for (final suggestion
                                                  in _suggestions)
                                                SoftChip(
                                                  label: suggestion,
                                                  accent: true,
                                                  icon:
                                                      Icons.north_west_rounded,
                                                  onTap: () => _insertSubject(
                                                    suggestion,
                                                    replaceActiveWord: true,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.resolver.subjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final subject = state.resolver.subjects[index];
                              return SoftChip(
                                label: subject,
                                onTap: () => _insertSubject(
                                  subject,
                                  replaceActiveWord: false,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _submitting ? null : _distribute,
                            child: _submitting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: palette.onAccent,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        strings.distributeLabel(
                                          _detectedCount,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
