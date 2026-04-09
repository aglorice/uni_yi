import 'package:flutter/material.dart';

Future<String?> showPhoneNumberDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _PhoneNumberDialog(),
  );
}

class _PhoneNumberDialog extends StatefulWidget {
  const _PhoneNumberDialog();

  @override
  State<_PhoneNumberDialog> createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<_PhoneNumberDialog> {
  final _controller = TextEditingController();
  String? _error;

  static final _phoneRegex = RegExp(r'^1[3-9]\d{9}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _controller.text.trim();
    if (!_phoneRegex.hasMatch(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    Navigator.of(context).pop(phone);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('填写手机号'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '预约场地需要提供联系电话，号码将自动保存以便下次使用。',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '手机号',
              hintText: '请输入 11 位手机号',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存并继续'),
        ),
      ],
    );
  }
}
