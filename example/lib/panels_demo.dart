import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

class PanelsDemo extends StatefulWidget {
  const PanelsDemo({super.key});

  @override
  State<PanelsDemo> createState() => _PanelsDemoState();
}

class _PanelsDemoState extends State<PanelsDemo> {
  bool dismissed = false;
  String? name;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Alerts & prompts', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      if (!dismissed) ...[
        LiquidGlassAlert(
          title: 'Everything is up to date',
          message: 'Your collection is ready on all your devices.',
          tone: LiquidGlassAlertTone.success,
          onDismiss: () => setState(() => dismissed = true),
        ),
        const SizedBox(height: 16),
      ],
      LiquidGlassPanel(
        title: name ?? 'Your collection',
        subtitle: 'A space for the things you love.',
        icon: Icons.auto_awesome_outlined,
        child: Column(
          children: [
            _DemoAction(
              onPressed: () async {
                final confirmed = await LiquidGlassPrompt.confirm(
                  context,
                  title: 'Start a fresh collection?',
                  message: 'Create a new space for your favorite discoveries.',
                  confirmLabel: 'Create collection',
                  icon: Icons.create_new_folder_outlined,
                );
                if (context.mounted && confirmed == true) {
                  LiquidGlassToast.show(context, message: 'Collection created');
                }
              },
              icon: Icons.add_circle_outline_rounded,
              child: const Text('New collection'),
            ),
            _DemoAction(
              onPressed: () async {
                final result = await LiquidGlassPrompt.show<String>(
                  context,
                  builder: (context) => _NamePrompt(initialName: name),
                );
                if (mounted && result != null) setState(() => name = result);
              },
              icon: Icons.edit_outlined,
              child: const Text('Rename collection'),
            ),
            _DemoAction(
              onPressed: () => LiquidGlassPanel.show<void>(
                context,
                builder: (context) => LiquidGlassPanel(
                  title: 'Collection details',
                  subtitle: 'Keep everything close, with room to breathe.',
                  icon: Icons.layers_outlined,
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                  child: const Text(
                    'Glass panels work with forms, lists, settings and custom content.',
                  ),
                ),
              ),
              icon: Icons.tune_rounded,
              child: const Text('Collection details'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _NamePrompt extends StatefulWidget {
  const _NamePrompt({this.initialName});
  final String? initialName;
  @override
  State<_NamePrompt> createState() => _NamePromptState();
}

class _DemoAction extends StatelessWidget {
  const _DemoAction({
    required this.onPressed,
    required this.icon,
    required this.child,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: DefaultTextStyle.of(context).style.color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    ),
  );
}

class _NamePromptState extends State<_NamePrompt> {
  late final controller = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LiquidGlassPrompt(
    title: 'Name your collection',
    icon: Icons.edit_outlined,
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: 40,
      decoration: const InputDecoration(labelText: 'Collection name'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.pop(context, controller.text.trim());
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}
