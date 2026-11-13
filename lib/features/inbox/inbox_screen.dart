import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/ghost_text_controller.dart';
import '../../widgets/soft_chip.dart';
import '../../widgets/top_bar.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final GhostTextController _controller = GhostTextController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  AppState? _appState;
  bool _listenerAttached = false;
  bool _submitting = false;
  int _detectedCount = 0;

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
    _glow.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final state = _appState;
    if (!mounted || state == null) return;

    final prefix = _activePrefix();
    final completion =
        prefix.isEmpty ? null : state.resolver.completionFor(prefix);
    _controller.ghost = completion?.completion ?? '';

    final text = _controller.text.trim();
    final count = text.isEmpty ? 0 : state.parseText(text).length;

    setState(() => _detectedCount = count);
  }

  /// Слово под курсором без решётки, если курсор стоит сразу после него.
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

    _controller.ghost = '';
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

    // Без снекбара: мягкое зелёное свечение по контуру кнопки.
    HapticFeedback.mediumImpact();
    _glow.forward(from: 0);
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
    _controller.ghostColor = palette.textMuted.withValues(alpha: 0.55);

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
                            // Пробел после известного слова превращает его
                            // в хэштег: «ал» → «#алгебра».
                            inputFormatters: <TextInputFormatter>[
                              HashtagAutocompleteFormatter(
                                resolver: state.resolver,
                              ),
                            ],
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
                        const SizedBox(height: 6),
                        Text(
                          strings.hashtagHint,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) {
                            final t = _glow.value;
                            final intensity = t == 0
                                ? 0.0
                                : (t <= 0.45 ? t / 0.45 : (1 - t) / 0.55);
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: <BoxShadow>[
                                  if (intensity > 0)
                                    BoxShadow(
                                      color: palette.success.withValues(
                                        alpha: 0.40 * intensity,
                                      ),
                                      blurRadius: 18 + 14 * intensity,
                                      spreadRadius: 1 + 3 * intensity,
                                    ),
                                ],
                                border: Border.all(
                                  color: palette.success.withValues(
                                    alpha: 0.85 * intensity,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _submitting ? null : _distribute,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
