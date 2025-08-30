// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get app_title => 'Wislet';

  @override
  String get home => 'Головна';

  @override
  String get wallets => 'Гаманці';

  @override
  String get settings => 'Налаштування';

  @override
  String get add => 'Додати';

  @override
  String get select_language => 'Оберіть мову';

  @override
  String get interface => 'Інтерфейс';

  @override
  String get language => 'Мова';

  @override
  String get money_and_currencies => 'Гроші та валюти';

  @override
  String get default_currency => 'Валюта за замовчуванням';

  @override
  String get currency_converter => 'Конвертер валют';

  @override
  String get data_and_sync => 'Дані та синхронізація';

  @override
  String get sync_now => 'Синхронізувати зараз';

  @override
  String get backup => 'Резервна копія';

  @override
  String get restore => 'Відновити з файлу';

  @override
  String get management => 'Керування';

  @override
  String get categories => 'Категорії';

  @override
  String get invitations => 'Запрошення';

  @override
  String get security => 'Безпека';

  @override
  String get enable_pin => 'Увімкнути PIN';

  @override
  String get change_pin => 'Змінити PIN';

  @override
  String get biometrics => 'Біометрична автентифікація';

  @override
  String get biometrics_configured => 'Налаштовано на пристрої';

  @override
  String get biometrics_not_supported => 'Не підтримується пристроєм';

  @override
  String get logout => 'Вийти';

  @override
  String get restore_done => 'Відновлення завершено';

  @override
  String get sync_done => 'Синхронізація завершена';

  @override
  String budget_warning_body(String name, String percent) {
    return 'Витрати в конверті \"$name\" досягли $percent%.';
  }
}
