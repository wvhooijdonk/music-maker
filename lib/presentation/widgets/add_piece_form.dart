import 'package:material_ui/material_ui.dart';

class AddPieceForm extends StatefulWidget {
  const AddPieceForm({
    super.key,
    required this.isChecking,
    required this.failure,
    required this.onUpload,
    required this.onCancel,
  });

  static const linkLabel = 'Link naar bladmuziek (PDF)';
  static const uploadLabel = 'Upload';
  static const checkingText = 'Bladmuziek controleren...';

  final bool isChecking;
  final String? failure;
  final ValueChanged<String> onUpload;
  final VoidCallback onCancel;

  @override
  State<AddPieceForm> createState() => _AddPieceFormState();
}

class _AddPieceFormState extends State<AddPieceForm> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _upload() => widget.onUpload(_link.text);

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _link,
          enabled: !widget.isChecking,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: AddPieceForm.linkLabel,
            hintText: 'https://...',
            border: const OutlineInputBorder(),
            errorText: failure,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => _upload(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: widget.isChecking ? null : _upload,
              icon: const Icon(Icons.upload),
              label: const Text(AddPieceForm.uploadLabel),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: widget.isChecking ? null : widget.onCancel,
              child: const Text('Annuleren'),
            ),
          ],
        ),
        if (widget.isChecking) ...[
          const SizedBox(height: 8),
          const Text(AddPieceForm.checkingText),
          const SizedBox(height: 4),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
