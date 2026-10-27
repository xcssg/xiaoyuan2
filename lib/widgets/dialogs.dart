import 'package:flutter/material.dart';

import '../theme/q_colors.dart';
import 'common.dart';

class QFormOption {
  const QFormOption(this.value, this.label);

  final String value;
  final String label;
}

class QFormFieldSpec {
  const QFormFieldSpec({
    required this.name,
    required this.label,
    this.initialValue,
    this.hint,
    this.password = false,
    this.minLength,
    this.maxLength,
    this.required = true,
    this.options,
  });

  final String name;
  final String label;
  final String? initialValue;
  final String? hint;
  final bool password;
  final int? minLength;
  final int? maxLength;
  final bool required;
  final List<QFormOption>? options;
}

Future<T?> _showLayer<T>(BuildContext context, Widget card) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: const Color(0x6B060C18),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: card,
      ),
    ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.surfaceSolid,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D08143C),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: t.text,
        letterSpacing: -.2,
      ),
    );
  }
}

Future<void> showQDialog(
  BuildContext context, {
  required String title,
  String? desc,
  Widget? content,
  String confirmText = '知道了',
}) async {
  final t = QColors.of(context);
  await _showLayer<bool>(
    context,
    _LayerCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTitle(title),
          if (desc != null) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(fontSize: 12.5, height: 1.7, color: t.text2),
            ),
          ],
          if (content != null) ...[
            const SizedBox(height: 10),
            content,
          ],
          const SizedBox(height: 20),
          QButton(
            label: confirmText,
            height: 46,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showQConfirm(
  BuildContext context, {
  required String title,
  required String desc,
  String confirmText = '确定',
  bool danger = false,
}) async {
  final t = QColors.of(context);
  final result = await _showLayer<bool>(
    context,
    _LayerCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTitle(title),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 12.5, height: 1.7, color: t.text2),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: QButton(
                  label: '取消',
                  style: QButtonStyle.ghost,
                  height: 46,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: QButton(
                  label: confirmText,
                  style: danger ? QButtonStyle.danger : QButtonStyle.primary,
                  height: 46,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

Future<Map<String, String>?> showQForm(
  BuildContext context, {
  required String title,
  String? desc,
  required List<QFormFieldSpec> fields,
  String confirmText = '确定',
}) {
  return _showLayer<Map<String, String>>(
    context,
    _FormCard(
      title: title,
      desc: desc,
      fields: fields,
      confirmText: confirmText,
    ),
  );
}

class _FormCard extends StatefulWidget {
  const _FormCard({
    required this.title,
    required this.desc,
    required this.fields,
    required this.confirmText,
  });

  final String title;
  final String? desc;
  final List<QFormFieldSpec> fields;
  final String confirmText;

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _selections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _selections = {};
    for (final f in widget.fields) {
      if (f.options != null) {
        _selections[f.name] =
            f.initialValue ?? (f.options!.isNotEmpty ? f.options!.first.value : '');
      } else {
        _controllers[f.name] = TextEditingController(text: f.initialValue ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final data = <String, String>{};
    for (final f in widget.fields) {
      if (f.options != null) {
        data[f.name] = _selections[f.name] ?? '';
        continue;
      }
      final value = _controllers[f.name]?.text.trim() ?? '';
      if (f.required && value.isEmpty) {
        setState(() => _error = '请填写${f.label}');
        return;
      }
      if (f.minLength != null && value.isNotEmpty && value.length < f.minLength!) {
        setState(() => _error = '${f.label}至少需要 ${f.minLength} 个字');
        return;
      }
      data[f.name] = value;
    }
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final t = QColors.of(context);
    return _LayerCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTitle(widget.title),
          if (widget.desc != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.desc!,
              style: TextStyle(fontSize: 12.5, height: 1.7, color: t.text2),
            ),
          ],
          const SizedBox(height: 14),
          for (var i = 0; i < widget.fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildField(widget.fields[i], t),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(fontSize: 11.5, color: t.danger),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: QButton(
                  label: '取消',
                  style: QButtonStyle.ghost,
                  height: 46,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: QButton(
                  label: widget.confirmText,
                  height: 46,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(QFormFieldSpec field, QColors t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            field.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.text2,
              letterSpacing: .2,
            ),
          ),
        ),
        if (field.options != null)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.field,
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selections[field.name],
                isExpanded: true,
                icon: Icon(Icons.expand_more_rounded, size: 18, color: t.text3),
                dropdownColor: t.surfaceSolid,
                borderRadius: BorderRadius.circular(14),
                style: TextStyle(fontSize: 14, color: t.text),
                items: [
                  for (final option in field.options!)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _selections[field.name] = value ?? '');
                },
              ),
            ),
          )
        else
          QField(
            controller: _controllers[field.name]!,
            hint: field.hint ?? '',
            icon: field.password ? Icons.lock_outline_rounded : Icons.edit_outlined,
            obscure: field.password,
            maxLength: field.maxLength,
          ),
      ],
    );
  }
}
