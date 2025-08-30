// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Wislet';

  @override
  String get home => 'Home';

  @override
  String get wallets => 'Wallets';

  @override
  String get settings => 'Settings';

  @override
  String get add => 'Add';

  @override
  String get select_language => 'Select language';

  @override
  String get interface => 'Interface';

  @override
  String get language => 'Language';

  @override
  String get money_and_currencies => 'Money and currencies';

  @override
  String get default_currency => 'Default currency';

  @override
  String get currency_converter => 'Currency converter';

  @override
  String get data_and_sync => 'Data and sync';

  @override
  String get sync_now => 'Sync now';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore from file';

  @override
  String get management => 'Management';

  @override
  String get categories => 'Categories';

  @override
  String get invitations => 'Invitations';

  @override
  String get security => 'Security';

  @override
  String get enable_pin => 'Enable PIN';

  @override
  String get change_pin => 'Change PIN';

  @override
  String get biometrics => 'Biometric authentication';

  @override
  String get biometrics_configured => 'Configured on device';

  @override
  String get biometrics_not_supported => 'Not supported by device';

  @override
  String get logout => 'Log out';

  @override
  String get restore_done => 'Restore completed';

  @override
  String get sync_done => 'Sync completed';

  @override
  String budget_warning_body(String name, String percent) {
    return 'Spending in envelope \"$name\" reached $percent%.';
  }
}
