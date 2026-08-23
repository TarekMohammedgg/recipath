import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipath/l10n/app_localizations.dart';
import 'package:recipath/widgets/authentication/reset_state_action.dart';
import 'package:recipath/widgets/screens/settings_screen/data/dialogs/clear_all_data_dialog.dart';

class ClearAllData extends ConsumerWidget {
  const ClearAllData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => ClearAllDataDialog(),
        );

        if (result == true) {
          resetStateAction.run(ref);
        }
      },
      icon: Icon(Icons.delete_forever),
      label: Text(AppLocalizations.of(context)!.clearAllData),
    );
  }
}
