import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/poll_model.dart';

class CreatePollSheet extends StatefulWidget {
  final String creatorId;
  final String creatorName;

  const CreatePollSheet({
    super.key,
    required this.creatorId,
    required this.creatorName,
  });

  static Future<PollModel?> show({
    required BuildContext context,
    required String creatorId,
    required String creatorName,
  }) {
    return showModalBottomSheet<PollModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreatePollSheet(
        creatorId: creatorId,
        creatorName: creatorName,
      ),
    );
  }

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final List<FocusNode> _optionFocusNodes = [];
  final FocusNode _questionFocusNode = FocusNode();

  String? _errorMessage;
  bool _isCreating = false;

  static const int _maxOptions = 12;

  @override
  void initState() {
    super.initState();
    // Default 2 options
    _addOptionController();
    _addOptionController();
  }

  void _addOptionController() {
    if (_optionControllers.length >= _maxOptions) return;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    _optionControllers.add(controller);
    _optionFocusNodes.add(focusNode);
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionFocusNodes[index].dispose();
      _optionControllers.removeAt(index);
      _optionFocusNodes.removeAt(index);
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();
  }

  void _addNewOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() {
      _addOptionController();
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();
    // Focus new field next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_optionFocusNodes.isNotEmpty && mounted) {
        _optionFocusNodes.last.requestFocus();
      }
    });
  }

  void _submit() {
    final l10n = context.l10n;
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() {
        _errorMessage = l10n.pollQuestionEmptyError;
      });
      _questionFocusNode.requestFocus();
      HapticFeedback.vibrate();
      return;
    }

    final rawOptions = _optionControllers.map((c) => c.text.trim()).toList();

    // Check empty options
    for (int i = 0; i < rawOptions.length; i++) {
      if (rawOptions[i].isEmpty) {
        setState(() {
          _errorMessage = l10n.pollEmptyOptionError;
        });
        _optionFocusNodes[i].requestFocus();
        HapticFeedback.vibrate();
        return;
      }
    }

    if (rawOptions.length < 2) {
      setState(() {
        _errorMessage = l10n.pollMinOptionsError;
      });
      HapticFeedback.vibrate();
      return;
    }

    // Check duplicate options (case-insensitive)
    final seen = <String>{};
    for (final opt in rawOptions) {
      final lower = opt.toLowerCase();
      if (seen.contains(lower)) {
        setState(() {
          _errorMessage = l10n.pollDuplicateOptionsError;
        });
        HapticFeedback.vibrate();
        return;
      }
      seen.add(lower);
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    const uuid = Uuid();
    final options = rawOptions.map((text) {
      return PollOptionModel(
        id: uuid.v4(),
        text: text,
        voterIds: const [],
      );
    }).toList();

    final poll = PollModel(
      id: uuid.v4(),
      question: question,
      creatorId: widget.creatorId,
      creatorName: widget.creatorName,
      options: options,
      totalVoterIds: const [],
      createdAt: DateTime.now(),
    );

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(poll);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocusNode.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    for (final f in _optionFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final bgColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2A2B32) : const Color(0xFFF3F4F6);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.black.withValues(alpha: 0.4);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.poll_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.createPollTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Form Body (Scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Label
                      Text(
                        l10n.pollQuestionLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Question TextField
                      TextField(
                        controller: _questionController,
                        focusNode: _questionFocusNode,
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.pollQuestionHint,
                          hintStyle: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.normal,
                            color: hintColor,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor, width: 1.1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      // Options Label & Helper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.pollOptionsLabel,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textColor.withValues(alpha: 0.85),
                            ),
                          ),
                          Text(
                            '${_optionControllers.length}/$_maxOptions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Option Inputs List
                      ...List.generate(_optionControllers.length, (index) {
                        final canRemove = _optionControllers.length > 2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: _optionControllers[index],
                            focusNode: _optionFocusNodes[index],
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.pollOptionHint(index + 1),
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: hintColor,
                              ),
                              filled: true,
                              fillColor: inputBg,
                              prefixIcon: Icon(
                                Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: hintColor,
                              ),
                              suffixIcon: canRemove
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: hintColor,
                                      ),
                                      splashRadius: 18,
                                      onPressed: () => _removeOption(index),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor, width: 1.1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 1.5),
                              ),
                            ),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                          ),
                        );
                      }),

                    // Add Option Button
                    if (_optionControllers.length < _maxOptions)
                      InkWell(
                        onTap: _addNewOption,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.35),
                              style: BorderStyle.solid,
                              width: 1.2,
                            ),
                            color: primaryColor.withValues(alpha: 0.06),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 19,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.addPollOption,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.createPollAction,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
  );
}
}
