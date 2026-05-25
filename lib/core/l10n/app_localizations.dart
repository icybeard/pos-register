import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'POS System'**
  String get appTitle;

  /// No description provided for @appRegion.
  ///
  /// In ru, this message translates to:
  /// **'KAZAKHSTAN'**
  String get appRegion;

  /// No description provided for @navPos.
  ///
  /// In ru, this message translates to:
  /// **'КАССА'**
  String get navPos;

  /// No description provided for @navShift.
  ///
  /// In ru, this message translates to:
  /// **'ИСТОРИЯ'**
  String get navShift;

  /// No description provided for @navProducts.
  ///
  /// In ru, this message translates to:
  /// **'ТОВАРЫ'**
  String get navProducts;

  /// No description provided for @navStaff.
  ///
  /// In ru, this message translates to:
  /// **'ПЕРСОНАЛ'**
  String get navStaff;

  /// No description provided for @navDebts.
  ///
  /// In ru, this message translates to:
  /// **'ДОЛГИ'**
  String get navDebts;

  /// No description provided for @navAnalytics.
  ///
  /// In ru, this message translates to:
  /// **'АНАЛИТИКА'**
  String get navAnalytics;

  /// No description provided for @navDelivery.
  ///
  /// In ru, this message translates to:
  /// **'ПОСТАВКИ'**
  String get navDelivery;

  /// No description provided for @navApproval.
  ///
  /// In ru, this message translates to:
  /// **'ОДОБРЕНИЕ'**
  String get navApproval;

  /// No description provided for @navAudit.
  ///
  /// In ru, this message translates to:
  /// **'АУДИТ'**
  String get navAudit;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'НАСТРОЙКИ'**
  String get navSettings;

  /// No description provided for @navPosShort.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get navPosShort;

  /// No description provided for @navShiftShort.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get navShiftShort;

  /// No description provided for @navMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get navMore;

  /// No description provided for @navProductsShort.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get navProductsShort;

  /// No description provided for @navStaffShort.
  ///
  /// In ru, this message translates to:
  /// **'Персонал'**
  String get navStaffShort;

  /// No description provided for @navDebtsShort.
  ///
  /// In ru, this message translates to:
  /// **'Долги'**
  String get navDebtsShort;

  /// No description provided for @navAnalyticsShort.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get navAnalyticsShort;

  /// No description provided for @navDeliveryShort.
  ///
  /// In ru, this message translates to:
  /// **'Поставки'**
  String get navDeliveryShort;

  /// No description provided for @navApprovalShort.
  ///
  /// In ru, this message translates to:
  /// **'Одобрение'**
  String get navApprovalShort;

  /// No description provided for @navAuditShort.
  ///
  /// In ru, this message translates to:
  /// **'Аудит'**
  String get navAuditShort;

  /// No description provided for @navSettingsShort.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettingsShort;

  /// No description provided for @modeCashier.
  ///
  /// In ru, this message translates to:
  /// **'Касса'**
  String get modeCashier;

  /// No description provided for @modeOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get modeOwner;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из системы'**
  String get logout;

  /// No description provided for @systemOnline.
  ///
  /// In ru, this message translates to:
  /// **'Система онлайн'**
  String get systemOnline;

  /// No description provided for @shiftOpened.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта'**
  String get shiftOpened;

  /// No description provided for @shiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get shiftClosed;

  /// No description provided for @roleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get roleAdmin;

  /// No description provided for @roleSeniorCashier.
  ///
  /// In ru, this message translates to:
  /// **'Старший кассир'**
  String get roleSeniorCashier;

  /// No description provided for @roleSeniorCashierShort.
  ///
  /// In ru, this message translates to:
  /// **'Ст. кассир'**
  String get roleSeniorCashierShort;

  /// No description provided for @roleCashier.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get roleCashier;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get refresh;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @loadMore.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить ещё'**
  String get loadMore;

  /// No description provided for @noData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get noData;

  /// No description provided for @errorPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {error}'**
  String errorPrefix(String error);

  /// No description provided for @pinTerminal.
  ///
  /// In ru, this message translates to:
  /// **'Терминал #001'**
  String get pinTerminal;

  /// No description provided for @pinSelectProfile.
  ///
  /// In ru, this message translates to:
  /// **'ВЫБЕРИТЕ ПРОФИЛЬ'**
  String get pinSelectProfile;

  /// No description provided for @pinCashierLabel.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get pinCashierLabel;

  /// No description provided for @pinEnterForLogin.
  ///
  /// In ru, this message translates to:
  /// **'Введите PIN для входа'**
  String get pinEnterForLogin;

  /// No description provided for @pinChangeTerminal.
  ///
  /// In ru, this message translates to:
  /// **'Сменить терминал'**
  String get pinChangeTerminal;

  /// No description provided for @pinWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать'**
  String get pinWelcome;

  /// No description provided for @pinEnterCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4-значный PIN-код'**
  String get pinEnterCode;

  /// No description provided for @pinEncryptedAccess.
  ///
  /// In ru, this message translates to:
  /// **'ЗАШИФРОВАННЫЙ ДОСТУП'**
  String get pinEncryptedAccess;

  /// No description provided for @pinFirstRunTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get pinFirstRunTitle;

  /// No description provided for @pinFirstRunSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Создайте первого пользователя'**
  String get pinFirstRunSubtitle;

  /// No description provided for @pinFieldName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get pinFieldName;

  /// No description provided for @pinFieldPin.
  ///
  /// In ru, this message translates to:
  /// **'PIN-код (4 цифры)'**
  String get pinFieldPin;

  /// No description provided for @pinFieldConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите PIN'**
  String get pinFieldConfirm;

  /// No description provided for @pinErrorLength.
  ///
  /// In ru, this message translates to:
  /// **'PIN должен быть 4 цифры'**
  String get pinErrorLength;

  /// No description provided for @pinErrorMismatch.
  ///
  /// In ru, this message translates to:
  /// **'PIN-коды не совпадают'**
  String get pinErrorMismatch;

  /// No description provided for @pinCreateAndLogin.
  ///
  /// In ru, this message translates to:
  /// **'Создать и войти'**
  String get pinCreateAndLogin;

  /// No description provided for @pinLockedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировано: {display}'**
  String pinLockedMessage(String display);

  /// No description provided for @pinSec.
  ///
  /// In ru, this message translates to:
  /// **'сек.'**
  String get pinSec;

  /// No description provided for @paymentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get paymentTitle;

  /// No description provided for @paymentToPay.
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get paymentToPay;

  /// No description provided for @paymentVatLine.
  ///
  /// In ru, this message translates to:
  /// **'в т.ч. НДС 12%: {amount}'**
  String paymentVatLine(String amount);

  /// No description provided for @paymentCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get paymentCard;

  /// No description provided for @paymentKaspiQR.
  ///
  /// In ru, this message translates to:
  /// **'Kaspi QR'**
  String get paymentKaspiQR;

  /// No description provided for @paymentMix.
  ///
  /// In ru, this message translates to:
  /// **'Микс'**
  String get paymentMix;

  /// No description provided for @paymentChange.
  ///
  /// In ru, this message translates to:
  /// **'Сдача'**
  String get paymentChange;

  /// No description provided for @paymentCardHint.
  ///
  /// In ru, this message translates to:
  /// **'Приложите карту к терминалу'**
  String get paymentCardHint;

  /// No description provided for @paymentQRHint.
  ///
  /// In ru, this message translates to:
  /// **'Покажите QR-код покупателю'**
  String get paymentQRHint;

  /// No description provided for @paymentPayButton.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить {amount}'**
  String paymentPayButton(String amount);

  /// No description provided for @paymentPendingButton.
  ///
  /// In ru, this message translates to:
  /// **'Внесите {amount}'**
  String paymentPendingButton(String amount);

  /// No description provided for @shiftNotOpened.
  ///
  /// In ru, this message translates to:
  /// **'Смена не открыта'**
  String get shiftNotOpened;

  /// No description provided for @shiftCashierLabel.
  ///
  /// In ru, this message translates to:
  /// **'Кассир: {name}'**
  String shiftCashierLabel(String name);

  /// No description provided for @shiftCashInDrawer.
  ///
  /// In ru, this message translates to:
  /// **'Наличные в кассе (₸)'**
  String get shiftCashInDrawer;

  /// No description provided for @shiftOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть смену'**
  String get shiftOpen;

  /// No description provided for @shiftReconciliation.
  ///
  /// In ru, this message translates to:
  /// **'Сверка смены'**
  String get shiftReconciliation;

  /// No description provided for @shiftCountCash.
  ///
  /// In ru, this message translates to:
  /// **'Пересчёт наличных'**
  String get shiftCountCash;

  /// No description provided for @shiftCountInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Введите количество каждой купюры в кассе.'**
  String get shiftCountInstruction;

  /// No description provided for @shiftBanknote.
  ///
  /// In ru, this message translates to:
  /// **'КУПЮРА'**
  String get shiftBanknote;

  /// No description provided for @shiftCoin.
  ///
  /// In ru, this message translates to:
  /// **'МОНЕТЫ'**
  String get shiftCoin;

  /// No description provided for @shiftSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Подитого'**
  String get shiftSubtotal;

  /// No description provided for @shiftManualAdjust.
  ///
  /// In ru, this message translates to:
  /// **'Ручная корректировка'**
  String get shiftManualAdjust;

  /// No description provided for @shiftAdjustSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Заметки о недостачах или излишках'**
  String get shiftAdjustSubtitle;

  /// No description provided for @shiftNote.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get shiftNote;

  /// No description provided for @shiftStatCash.
  ///
  /// In ru, this message translates to:
  /// **'НАЛИЧНЫЕ'**
  String get shiftStatCash;

  /// No description provided for @shiftStatCard.
  ///
  /// In ru, this message translates to:
  /// **'КАРТА'**
  String get shiftStatCard;

  /// No description provided for @shiftStatKaspiQR.
  ///
  /// In ru, this message translates to:
  /// **'KASPI QR'**
  String get shiftStatKaspiQR;

  /// No description provided for @shiftStatReturns.
  ///
  /// In ru, this message translates to:
  /// **'ВОЗВРАТЫ'**
  String get shiftStatReturns;

  /// No description provided for @shiftSummary.
  ///
  /// In ru, this message translates to:
  /// **'Итоги смены'**
  String get shiftSummary;

  /// No description provided for @shiftStartBalance.
  ///
  /// In ru, this message translates to:
  /// **'Начальный остаток'**
  String get shiftStartBalance;

  /// No description provided for @shiftCashSales.
  ///
  /// In ru, this message translates to:
  /// **'Наличные продажи'**
  String get shiftCashSales;

  /// No description provided for @shiftReturnsPayouts.
  ///
  /// In ru, this message translates to:
  /// **'Возвраты/Выплаты'**
  String get shiftReturnsPayouts;

  /// No description provided for @shiftExpectedBalance.
  ///
  /// In ru, this message translates to:
  /// **'ОЖИДАЕМЫЙ ОСТАТОК'**
  String get shiftExpectedBalance;

  /// No description provided for @shiftCounted.
  ///
  /// In ru, this message translates to:
  /// **'ПОДСЧИТАНО'**
  String get shiftCounted;

  /// No description provided for @shiftDiscrepancy.
  ///
  /// In ru, this message translates to:
  /// **'Расхождение'**
  String get shiftDiscrepancy;

  /// No description provided for @shiftLabel.
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get shiftLabel;

  /// No description provided for @shiftNumber.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number}'**
  String shiftNumber(int number);

  /// No description provided for @shiftReceipts.
  ///
  /// In ru, this message translates to:
  /// **'чеков'**
  String get shiftReceipts;

  /// No description provided for @shiftCashStart.
  ///
  /// In ru, this message translates to:
  /// **'Наличные на начало'**
  String get shiftCashStart;

  /// No description provided for @shiftCurrentBalance.
  ///
  /// In ru, this message translates to:
  /// **'Текущий остаток'**
  String get shiftCurrentBalance;

  /// No description provided for @shiftCloseZReport.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть смену (Z-отчёт)'**
  String get shiftCloseZReport;

  /// No description provided for @shiftCloseConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть смену?'**
  String get shiftCloseConfirmTitle;

  /// No description provided for @shiftCloseConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Будет сформирован Z-отчёт. Это действие нельзя отменить.'**
  String get shiftCloseConfirmBody;

  /// No description provided for @shiftCloseButton.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть смену'**
  String get shiftCloseButton;

  /// No description provided for @shiftCloseFooter.
  ///
  /// In ru, this message translates to:
  /// **'Закрывая смену, вы подтверждаете пересчёт наличных в кассе.'**
  String get shiftCloseFooter;

  /// No description provided for @productsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get productsTitle;

  /// No description provided for @productsCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count} позиций в каталоге'**
  String productsCountLabel(int count);

  /// No description provided for @productsTotalStat.
  ///
  /// In ru, this message translates to:
  /// **'ВСЕГО ТОВАРОВ'**
  String get productsTotalStat;

  /// No description provided for @productsWeightedStat.
  ///
  /// In ru, this message translates to:
  /// **'ВЕСОВЫХ'**
  String get productsWeightedStat;

  /// No description provided for @productsPieceStat.
  ///
  /// In ru, this message translates to:
  /// **'ШТУЧНЫХ'**
  String get productsPieceStat;

  /// No description provided for @productsAvgPriceStat.
  ///
  /// In ru, this message translates to:
  /// **'СРЕДНЯЯ ЦЕНА'**
  String get productsAvgPriceStat;

  /// No description provided for @productsTotalShort.
  ///
  /// In ru, this message translates to:
  /// **'ВСЕГО'**
  String get productsTotalShort;

  /// No description provided for @productsAvgPriceShort.
  ///
  /// In ru, this message translates to:
  /// **'СР. ЦЕНА'**
  String get productsAvgPriceShort;

  /// No description provided for @productsSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию или штрих-коду...'**
  String get productsSearchHint;

  /// No description provided for @productsTabAll.
  ///
  /// In ru, this message translates to:
  /// **'Все ({count})'**
  String productsTabAll(int count);

  /// No description provided for @productsTabWeighted.
  ///
  /// In ru, this message translates to:
  /// **'Весовые ({count})'**
  String productsTabWeighted(int count);

  /// No description provided for @productsTabPiece.
  ///
  /// In ru, this message translates to:
  /// **'Штучные ({count})'**
  String productsTabPiece(int count);

  /// No description provided for @productsColName.
  ///
  /// In ru, this message translates to:
  /// **'ТОВАР'**
  String get productsColName;

  /// No description provided for @productsColBarcode.
  ///
  /// In ru, this message translates to:
  /// **'ШТРИХ-КОД'**
  String get productsColBarcode;

  /// No description provided for @productsColVat.
  ///
  /// In ru, this message translates to:
  /// **'НДС'**
  String get productsColVat;

  /// No description provided for @productsColPrice.
  ///
  /// In ru, this message translates to:
  /// **'ЦЕНА'**
  String get productsColPrice;

  /// No description provided for @productsNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get productsNotFound;

  /// No description provided for @productsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет товаров'**
  String get productsEmpty;

  /// No description provided for @productsTryAnother.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другой запрос'**
  String get productsTryAnother;

  /// No description provided for @productsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первый товар или\nзагрузите демо-данные в настройках'**
  String get productsEmptyHint;

  /// No description provided for @productsDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить товар?'**
  String get productsDeleteConfirm;

  /// No description provided for @productsNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый товар'**
  String get productsNew;

  /// No description provided for @productsFieldBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Штрих-код (GTIN)'**
  String get productsFieldBarcode;

  /// No description provided for @productsNkt.
  ///
  /// In ru, this message translates to:
  /// **'НКТ'**
  String get productsNkt;

  /// No description provided for @productsEnterBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Введите штрих-код'**
  String get productsEnterBarcode;

  /// No description provided for @productsNktNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Не найден в НКТ'**
  String get productsNktNotFound;

  /// No description provided for @productsNktError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка НКТ: {error}'**
  String productsNktError(String error);

  /// No description provided for @productsFieldName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get productsFieldName;

  /// No description provided for @productsFieldPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена (₸)'**
  String get productsFieldPrice;

  /// No description provided for @productsWeighted.
  ///
  /// In ru, this message translates to:
  /// **'Весовой товар'**
  String get productsWeighted;

  /// No description provided for @productsWeightedSubPriceKg.
  ///
  /// In ru, this message translates to:
  /// **'Цена за кг'**
  String get productsWeightedSubPriceKg;

  /// No description provided for @productsWeightedSubPricePcs.
  ///
  /// In ru, this message translates to:
  /// **'Цена за штуку'**
  String get productsWeightedSubPricePcs;

  /// No description provided for @productsTypeWeighted.
  ///
  /// In ru, this message translates to:
  /// **'Весовой'**
  String get productsTypeWeighted;

  /// No description provided for @productsTypePiece.
  ///
  /// In ru, this message translates to:
  /// **'Штучный'**
  String get productsTypePiece;

  /// No description provided for @cashiersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Персонал'**
  String get cashiersTitle;

  /// No description provided for @cashiersCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count} сотрудников'**
  String cashiersCountLabel(int count);

  /// No description provided for @cashiersStatTotal.
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get cashiersStatTotal;

  /// No description provided for @cashiersStatOwners.
  ///
  /// In ru, this message translates to:
  /// **'Владельцев'**
  String get cashiersStatOwners;

  /// No description provided for @cashiersStatManagers.
  ///
  /// In ru, this message translates to:
  /// **'Менеджеров'**
  String get cashiersStatManagers;

  /// No description provided for @cashiersColName.
  ///
  /// In ru, this message translates to:
  /// **'ИМЯ'**
  String get cashiersColName;

  /// No description provided for @cashiersColRole.
  ///
  /// In ru, this message translates to:
  /// **'РОЛЬ'**
  String get cashiersColRole;

  /// No description provided for @cashiersEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет кассиров'**
  String get cashiersEmpty;

  /// No description provided for @cashiersNew.
  ///
  /// In ru, this message translates to:
  /// **'Новый кассир'**
  String get cashiersNew;

  /// No description provided for @cashiersFieldName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get cashiersFieldName;

  /// No description provided for @cashiersFieldPin.
  ///
  /// In ru, this message translates to:
  /// **'PIN (4 цифры)'**
  String get cashiersFieldPin;

  /// No description provided for @cashiersFieldRole.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get cashiersFieldRole;

  /// No description provided for @cashiersEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get cashiersEnterName;

  /// No description provided for @debtsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Долги'**
  String get debtsTitle;

  /// No description provided for @debtsCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'{open} открытых, {clients} клиентов'**
  String debtsCountLabel(int open, int clients);

  /// No description provided for @debtsNewDebt.
  ///
  /// In ru, this message translates to:
  /// **'Новый долг'**
  String get debtsNewDebt;

  /// No description provided for @debtsTotalBanner.
  ///
  /// In ru, this message translates to:
  /// **'ОБЩАЯ ЗАДОЛЖЕННОСТЬ'**
  String get debtsTotalBanner;

  /// No description provided for @debtsRecordsLabel.
  ///
  /// In ru, this message translates to:
  /// **'записей'**
  String get debtsRecordsLabel;

  /// No description provided for @debtsTabOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открытые ({count})'**
  String debtsTabOpen(int count);

  /// No description provided for @debtsTabAll.
  ///
  /// In ru, this message translates to:
  /// **'Все ({count})'**
  String debtsTabAll(int count);

  /// No description provided for @debtsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет долгов'**
  String get debtsEmpty;

  /// No description provided for @debtsPayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Погашение долга'**
  String get debtsPayTitle;

  /// No description provided for @debtsPayRemaining.
  ///
  /// In ru, this message translates to:
  /// **'Остаток: {amount}'**
  String debtsPayRemaining(String amount);

  /// No description provided for @debtsFieldAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма (₸)'**
  String get debtsFieldAmount;

  /// No description provided for @debtsEnterAmount.
  ///
  /// In ru, this message translates to:
  /// **'Введите сумму'**
  String get debtsEnterAmount;

  /// No description provided for @debtsPay.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get debtsPay;

  /// No description provided for @debtsCreateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Продажа в долг'**
  String get debtsCreateTitle;

  /// No description provided for @debtsFieldClient.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get debtsFieldClient;

  /// No description provided for @debtsFieldNote.
  ///
  /// In ru, this message translates to:
  /// **'Примечание'**
  String get debtsFieldNote;

  /// No description provided for @debtsSelectClient.
  ///
  /// In ru, this message translates to:
  /// **'Выберите клиента'**
  String get debtsSelectClient;

  /// No description provided for @debtsRecord.
  ///
  /// In ru, this message translates to:
  /// **'Записать долг'**
  String get debtsRecord;

  /// No description provided for @debtsClientDefault.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get debtsClientDefault;

  /// No description provided for @debtsPaid.
  ///
  /// In ru, this message translates to:
  /// **'Погашено'**
  String get debtsPaid;

  /// No description provided for @debtsOfTotal.
  ///
  /// In ru, this message translates to:
  /// **'из {amount}'**
  String debtsOfTotal(String amount);

  /// No description provided for @debtsPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get debtsPayment;

  /// No description provided for @debtsClosed.
  ///
  /// In ru, this message translates to:
  /// **'Закрыт'**
  String get debtsClosed;

  /// No description provided for @debtsPaidLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено: {amount}'**
  String debtsPaidLabel(String amount);

  /// No description provided for @analyticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Обзор бизнеса'**
  String get analyticsSubtitle;

  /// No description provided for @analyticsToday.
  ///
  /// In ru, this message translates to:
  /// **'СЕГОДНЯ'**
  String get analyticsToday;

  /// No description provided for @analyticsYesterday.
  ///
  /// In ru, this message translates to:
  /// **'ВЧЕРА'**
  String get analyticsYesterday;

  /// No description provided for @analyticsWeek.
  ///
  /// In ru, this message translates to:
  /// **'НЕДЕЛЯ'**
  String get analyticsWeek;

  /// No description provided for @analyticsMonth.
  ///
  /// In ru, this message translates to:
  /// **'МЕСЯЦ'**
  String get analyticsMonth;

  /// No description provided for @analyticsReceipts.
  ///
  /// In ru, this message translates to:
  /// **'чеков'**
  String get analyticsReceipts;

  /// No description provided for @analyticsPaymentTypes.
  ///
  /// In ru, this message translates to:
  /// **'Оплата по типам'**
  String get analyticsPaymentTypes;

  /// No description provided for @analyticsTopProducts.
  ///
  /// In ru, this message translates to:
  /// **'Топ товаров (30 дней)'**
  String get analyticsTopProducts;

  /// No description provided for @analyticsCashiers.
  ///
  /// In ru, this message translates to:
  /// **'Кассиры'**
  String get analyticsCashiers;

  /// No description provided for @analyticsLowStock.
  ///
  /// In ru, this message translates to:
  /// **'Остатки (низкие)'**
  String get analyticsLowStock;

  /// No description provided for @analyticsDebts.
  ///
  /// In ru, this message translates to:
  /// **'Долги'**
  String get analyticsDebts;

  /// No description provided for @analyticsAllNormal.
  ///
  /// In ru, this message translates to:
  /// **'Все в норме'**
  String get analyticsAllNormal;

  /// No description provided for @analyticsCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличные'**
  String get analyticsCash;

  /// No description provided for @analyticsCard.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get analyticsCard;

  /// No description provided for @analyticsKaspiQR.
  ///
  /// In ru, this message translates to:
  /// **'Kaspi QR'**
  String get analyticsKaspiQR;

  /// No description provided for @analyticsOpenDebts.
  ///
  /// In ru, this message translates to:
  /// **'Открытых'**
  String get analyticsOpenDebts;

  /// No description provided for @analyticsToPayDebts.
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get analyticsToPayDebts;

  /// No description provided for @analyticsPaidDebts.
  ///
  /// In ru, this message translates to:
  /// **'Погашено'**
  String get analyticsPaidDebts;

  /// No description provided for @deliveryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Поставка товаров'**
  String get deliveryTitle;

  /// No description provided for @deliverySearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск товара...'**
  String get deliverySearchHint;

  /// No description provided for @deliveryCostLabel.
  ///
  /// In ru, this message translates to:
  /// **'Себестоимость: {amount}'**
  String deliveryCostLabel(String amount);

  /// No description provided for @deliveryLinesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Позиции ({count})'**
  String deliveryLinesLabel(int count);

  /// No description provided for @deliveryEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте товары для поставки'**
  String get deliveryEmptyHint;

  /// No description provided for @deliveryFieldQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get deliveryFieldQty;

  /// No description provided for @deliveryFieldCost.
  ///
  /// In ru, this message translates to:
  /// **'Себестоимость (тиын)'**
  String get deliveryFieldCost;

  /// No description provided for @deliverySubmit.
  ///
  /// In ru, this message translates to:
  /// **'Оформить поставку'**
  String get deliverySubmit;

  /// No description provided for @deliverySuccess.
  ///
  /// In ru, this message translates to:
  /// **'Поставка оформлена'**
  String get deliverySuccess;

  /// No description provided for @approvalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Одобрение товаров'**
  String get approvalTitle;

  /// No description provided for @approvalSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'НКТ товары ожидают проверки'**
  String get approvalSubtitle;

  /// No description provided for @approvalEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет ожидающих товаров'**
  String get approvalEmpty;

  /// No description provided for @approvalPending.
  ///
  /// In ru, this message translates to:
  /// **'ОЖИДАЕТ'**
  String get approvalPending;

  /// No description provided for @approvalFrom.
  ///
  /// In ru, this message translates to:
  /// **'от: {name}'**
  String approvalFrom(String name);

  /// No description provided for @approvalBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Штрих-код'**
  String get approvalBarcode;

  /// No description provided for @approvalNtin.
  ///
  /// In ru, this message translates to:
  /// **'НТИН'**
  String get approvalNtin;

  /// No description provided for @approvalSalePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена продажи'**
  String get approvalSalePrice;

  /// No description provided for @approvalReject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get approvalReject;

  /// No description provided for @approvalApprove.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить'**
  String get approvalApprove;

  /// No description provided for @approvalApproveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить товар'**
  String get approvalApproveTitle;

  /// No description provided for @approvalFieldName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get approvalFieldName;

  /// No description provided for @approvalFieldPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена продажи (тиын)'**
  String get approvalFieldPrice;

  /// No description provided for @approvalRejectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить товар'**
  String get approvalRejectTitle;

  /// No description provided for @approvalRejectReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина (необязательно)'**
  String get approvalRejectReason;

  /// No description provided for @approvalApproved.
  ///
  /// In ru, this message translates to:
  /// **'Товар одобрен'**
  String get approvalApproved;

  /// No description provided for @approvalRejected.
  ///
  /// In ru, this message translates to:
  /// **'Товар отклонён'**
  String get approvalRejected;

  /// No description provided for @auditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Журнал аудита'**
  String get auditTitle;

  /// No description provided for @auditTotalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Всего записей: {count}'**
  String auditTotalLabel(int count);

  /// No description provided for @auditEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет записей'**
  String get auditEmpty;

  /// No description provided for @auditActionReceiptCreated.
  ///
  /// In ru, this message translates to:
  /// **'Чек создан'**
  String get auditActionReceiptCreated;

  /// No description provided for @auditActionShiftOpened.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта'**
  String get auditActionShiftOpened;

  /// No description provided for @auditActionShiftClosed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта'**
  String get auditActionShiftClosed;

  /// No description provided for @auditActionNktApproved.
  ///
  /// In ru, this message translates to:
  /// **'НКТ товар одобрен'**
  String get auditActionNktApproved;

  /// No description provided for @auditActionNktRejected.
  ///
  /// In ru, this message translates to:
  /// **'НКТ товар отклонён'**
  String get auditActionNktRejected;

  /// No description provided for @auditActionProductCreated.
  ///
  /// In ru, this message translates to:
  /// **'Товар создан'**
  String get auditActionProductCreated;

  /// No description provided for @auditActionProductEdited.
  ///
  /// In ru, this message translates to:
  /// **'Товар изменён'**
  String get auditActionProductEdited;

  /// No description provided for @auditActionProductDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Товар удалён'**
  String get auditActionProductDeleted;

  /// No description provided for @auditActionDebtCreated.
  ///
  /// In ru, this message translates to:
  /// **'Долг создан'**
  String get auditActionDebtCreated;

  /// No description provided for @auditActionDebtPaid.
  ///
  /// In ru, this message translates to:
  /// **'Долг погашен'**
  String get auditActionDebtPaid;

  /// No description provided for @auditActionCashierCreated.
  ///
  /// In ru, this message translates to:
  /// **'Кассир добавлен'**
  String get auditActionCashierCreated;

  /// No description provided for @auditActionDeliveryReceived.
  ///
  /// In ru, this message translates to:
  /// **'Поставка оформлена'**
  String get auditActionDeliveryReceived;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Конфигурация системы'**
  String get settingsSubtitle;

  /// No description provided for @settingsActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get settingsActions;

  /// No description provided for @settingsSeedDemo.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить демо-данные'**
  String get settingsSeedDemo;

  /// No description provided for @settingsSeedDemoSub.
  ///
  /// In ru, this message translates to:
  /// **'17 товаров, 6 категорий, 3 клиента'**
  String get settingsSeedDemoSub;

  /// No description provided for @settingsCheckNkt.
  ///
  /// In ru, this message translates to:
  /// **'Проверить НКТ'**
  String get settingsCheckNkt;

  /// No description provided for @settingsCheckNktSub.
  ///
  /// In ru, this message translates to:
  /// **'Поиск товара по штрих-коду или названию'**
  String get settingsCheckNktSub;

  /// No description provided for @settingsSystem.
  ///
  /// In ru, this message translates to:
  /// **'Система'**
  String get settingsSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О системе'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSub.
  ///
  /// In ru, this message translates to:
  /// **'POS System Kazakhstan v0.1.0'**
  String get settingsAboutSub;

  /// No description provided for @settingsServer.
  ///
  /// In ru, this message translates to:
  /// **'Сервер'**
  String get settingsServer;

  /// No description provided for @settingsServerStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус сервера'**
  String get settingsServerStatus;

  /// No description provided for @settingsServerConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключен'**
  String get settingsServerConnected;

  /// No description provided for @settingsServerUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не доступен'**
  String get settingsServerUnavailable;

  /// No description provided for @settingsIntegrations.
  ///
  /// In ru, this message translates to:
  /// **'Интеграции'**
  String get settingsIntegrations;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык / Тiл'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get settingsLanguageSub;

  /// No description provided for @settingsLanguageKk.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get settingsLanguageKk;

  /// No description provided for @settingsFiscal.
  ///
  /// In ru, this message translates to:
  /// **'Фискализация'**
  String get settingsFiscal;

  /// No description provided for @settingsNotConnected.
  ///
  /// In ru, this message translates to:
  /// **'Не подключено'**
  String get settingsNotConnected;

  /// No description provided for @settingsNktTitle.
  ///
  /// In ru, this message translates to:
  /// **'НКТ (Национальный каталог)'**
  String get settingsNktTitle;

  /// No description provided for @settingsNktConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключено'**
  String get settingsNktConnected;

  /// No description provided for @settingsNktNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Не настроено'**
  String get settingsNktNotConfigured;

  /// No description provided for @settingsNktSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск в НКТ'**
  String get settingsNktSearch;

  /// No description provided for @settingsNktBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Штрих-код'**
  String get settingsNktBarcode;

  /// No description provided for @settingsNktName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get settingsNktName;

  /// No description provided for @settingsNktGtinHint.
  ///
  /// In ru, this message translates to:
  /// **'GTIN (штрих-код)'**
  String get settingsNktGtinHint;

  /// No description provided for @settingsNktNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Название товара'**
  String get settingsNktNameHint;

  /// No description provided for @settingsNktNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get settingsNktNotFound;

  /// No description provided for @settingsNktSocial.
  ///
  /// In ru, this message translates to:
  /// **'СЗТ'**
  String get settingsNktSocial;

  /// No description provided for @posTabProducts.
  ///
  /// In ru, this message translates to:
  /// **'Товары'**
  String get posTabProducts;

  /// No description provided for @posTabReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Чек'**
  String get posTabReceipt;

  /// No description provided for @posSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск / штрих-код / SKU'**
  String get posSearchHint;

  /// No description provided for @posCatAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get posCatAll;

  /// No description provided for @posCatFood.
  ///
  /// In ru, this message translates to:
  /// **'Продукты'**
  String get posCatFood;

  /// No description provided for @posCatDrinks.
  ///
  /// In ru, this message translates to:
  /// **'Напитки'**
  String get posCatDrinks;

  /// No description provided for @posCatGrocery.
  ///
  /// In ru, this message translates to:
  /// **'Бакалея'**
  String get posCatGrocery;

  /// No description provided for @posCatDairy.
  ///
  /// In ru, this message translates to:
  /// **'Молочные'**
  String get posCatDairy;

  /// No description provided for @posCatOther.
  ///
  /// In ru, this message translates to:
  /// **'Прочее'**
  String get posCatOther;

  /// No description provided for @posOnline.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн'**
  String get posOnline;

  /// No description provided for @posEnterNameOr.
  ///
  /// In ru, this message translates to:
  /// **'Введите название или'**
  String get posEnterNameOr;

  /// No description provided for @posScanBarcode.
  ///
  /// In ru, this message translates to:
  /// **'отсканируйте штрих-код'**
  String get posScanBarcode;

  /// No description provided for @posNotFoundLocally.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено локально'**
  String get posNotFoundLocally;

  /// No description provided for @posEnterFullBarcode.
  ///
  /// In ru, this message translates to:
  /// **'Введите полный штрих-код (8–14 цифр)'**
  String get posEnterFullBarcode;

  /// No description provided for @posForAutoNkt.
  ///
  /// In ru, this message translates to:
  /// **'для автоматического поиска в НКТ'**
  String get posForAutoNkt;

  /// No description provided for @posBarcodeProgress.
  ///
  /// In ru, this message translates to:
  /// **'Введено {current} из 8–14 цифр'**
  String posBarcodeProgress(int current);

  /// No description provided for @posNotFoundQuery.
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» ничего не найдено'**
  String posNotFoundQuery(String query);

  /// No description provided for @posSearchingNkt.
  ///
  /// In ru, this message translates to:
  /// **'Поиск в НКТ...'**
  String get posSearchingNkt;

  /// No description provided for @posNotFoundLocallyHeader.
  ///
  /// In ru, this message translates to:
  /// **'Товар не найден локально'**
  String get posNotFoundLocallyHeader;

  /// No description provided for @posNktFoundCount.
  ///
  /// In ru, this message translates to:
  /// **'Найдено {count} в Национальном каталоге (НКТ) по штрих-коду {barcode}'**
  String posNktFoundCount(int count, String barcode);

  /// No description provided for @posNktSelectInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Выберите товар для добавления в каталог:'**
  String get posNktSelectInstruction;

  /// No description provided for @posNktAddTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить товар из НКТ'**
  String get posNktAddTitle;

  /// No description provided for @posNktPriceKg.
  ///
  /// In ru, this message translates to:
  /// **'Цена за кг (₸)'**
  String get posNktPriceKg;

  /// No description provided for @posNktPricePcs.
  ///
  /// In ru, this message translates to:
  /// **'Цена (₸)'**
  String get posNktPricePcs;

  /// No description provided for @posNktAddAndSell.
  ///
  /// In ru, this message translates to:
  /// **'Добавить и продать'**
  String get posNktAddAndSell;

  /// No description provided for @posNktSentForApproval.
  ///
  /// In ru, this message translates to:
  /// **'Товар отправлен на одобрение владельцу'**
  String get posNktSentForApproval;

  /// No description provided for @posNktCreateError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка создания товара: {error}'**
  String posNktCreateError(String error);

  /// No description provided for @posCartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Текущий чек'**
  String get posCartTitle;

  /// No description provided for @posCartItems.
  ///
  /// In ru, this message translates to:
  /// **'поз.'**
  String get posCartItems;

  /// No description provided for @posCartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста'**
  String get posCartEmpty;

  /// No description provided for @posCartEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте первый товар'**
  String get posCartEmptyHint;

  /// No description provided for @posQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get posQuantity;

  /// No description provided for @posVat12.
  ///
  /// In ru, this message translates to:
  /// **'НДС 12%'**
  String get posVat12;

  /// No description provided for @posTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get posTotal;

  /// No description provided for @posPayment.
  ///
  /// In ru, this message translates to:
  /// **'ОПЛАТА'**
  String get posPayment;

  /// No description provided for @posPaymentWithAmount.
  ///
  /// In ru, this message translates to:
  /// **'ОПЛАТА  {amount}'**
  String posPaymentWithAmount(String amount);

  /// No description provided for @posTakeaway.
  ///
  /// In ru, this message translates to:
  /// **'С собой'**
  String get posTakeaway;

  /// No description provided for @posCancelSale.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get posCancelSale;

  /// No description provided for @posCancelSaleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить продажу?'**
  String get posCancelSaleTitle;

  /// No description provided for @posCancelSaleBody.
  ///
  /// In ru, this message translates to:
  /// **'В корзине {count} позиций. Восстановить их будет нельзя.'**
  String posCancelSaleBody(int count);

  /// No description provided for @posCancelSaleConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get posCancelSaleConfirm;

  /// No description provided for @posCancelSaleKeep.
  ///
  /// In ru, this message translates to:
  /// **'Оставить'**
  String get posCancelSaleKeep;

  /// No description provided for @posOpenShiftFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала откройте смену'**
  String get posOpenShiftFirst;

  /// No description provided for @analyticsAllTime.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get analyticsAllTime;

  /// No description provided for @analyticsAutoRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Автообновление'**
  String get analyticsAutoRefresh;

  /// No description provided for @analyticsAvgReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get analyticsAvgReceipt;

  /// No description provided for @analyticsClearFilter.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтр'**
  String get analyticsClearFilter;

  /// No description provided for @analyticsDateRange.
  ///
  /// In ru, this message translates to:
  /// **'Период'**
  String get analyticsDateRange;

  /// No description provided for @analyticsExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get analyticsExport;

  /// No description provided for @analyticsExportSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт выполнен'**
  String get analyticsExportSuccess;

  /// No description provided for @analyticsProductName.
  ///
  /// In ru, this message translates to:
  /// **'Товар'**
  String get analyticsProductName;

  /// No description provided for @analyticsQty.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во'**
  String get analyticsQty;

  /// No description provided for @analyticsRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get analyticsRevenue;

  /// No description provided for @analyticsRevenueByProduct.
  ///
  /// In ru, this message translates to:
  /// **'Выручка по товарам'**
  String get analyticsRevenueByProduct;

  /// No description provided for @approvalBatchApprove.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить выбранные'**
  String get approvalBatchApprove;

  /// No description provided for @approvalBatchCount.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} товар} few{{count} товара} other{{count} товаров}}'**
  String approvalBatchCount(int count);

  /// No description provided for @approvalDefaultMarkup.
  ///
  /// In ru, this message translates to:
  /// **'Наценка по умолчанию'**
  String get approvalDefaultMarkup;

  /// No description provided for @cashiersDeactivate.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать'**
  String get cashiersDeactivate;

  /// No description provided for @cashiersDeactivateConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать кассира?'**
  String get cashiersDeactivateConfirm;

  /// No description provided for @cashiersDeactivateHint.
  ///
  /// In ru, this message translates to:
  /// **'Кассир не сможет войти. Активацию можно вернуть позже.'**
  String get cashiersDeactivateHint;

  /// No description provided for @cashiersDeactivated.
  ///
  /// In ru, this message translates to:
  /// **'Кассир деактивирован'**
  String get cashiersDeactivated;

  /// No description provided for @cashiersEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get cashiersEdit;

  /// No description provided for @cashiersNewPin.
  ///
  /// In ru, this message translates to:
  /// **'Новый PIN'**
  String get cashiersNewPin;

  /// No description provided for @cashiersPinConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите PIN'**
  String get cashiersPinConfirm;

  /// No description provided for @cashiersResetPin.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить PIN'**
  String get cashiersResetPin;

  /// No description provided for @cashiersResetPinSuccess.
  ///
  /// In ru, this message translates to:
  /// **'PIN сброшен'**
  String get cashiersResetPinSuccess;

  /// No description provided for @cashiersRoleAdminDesc.
  ///
  /// In ru, this message translates to:
  /// **'Полный доступ кроме владельца'**
  String get cashiersRoleAdminDesc;

  /// No description provided for @cashiersRoleCashierDesc.
  ///
  /// In ru, this message translates to:
  /// **'Только продажи и смены'**
  String get cashiersRoleCashierDesc;

  /// No description provided for @cashiersRoleSeniorDesc.
  ///
  /// In ru, this message translates to:
  /// **'Кассир + возвраты и скидки'**
  String get cashiersRoleSeniorDesc;

  /// No description provided for @debtsOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено'**
  String get debtsOverdue;

  /// No description provided for @debtsRemainingAmount.
  ///
  /// In ru, this message translates to:
  /// **'Остаток к погашению'**
  String get debtsRemainingAmount;

  /// No description provided for @debtsDaysSuffix.
  ///
  /// In ru, this message translates to:
  /// **'{days, plural, one{{days} день} few{{days} дня} many{{days} дней} other{{days} дня}}'**
  String debtsDaysSuffix(int days);

  /// No description provided for @debtsSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по клиенту или телефону'**
  String get debtsSearch;

  /// No description provided for @deliveryActualQty.
  ///
  /// In ru, this message translates to:
  /// **'Факт'**
  String get deliveryActualQty;

  /// No description provided for @deliveryAddSupplier.
  ///
  /// In ru, this message translates to:
  /// **'Добавить поставщика'**
  String get deliveryAddSupplier;

  /// No description provided for @deliveryCreateProduct.
  ///
  /// In ru, this message translates to:
  /// **'Создать товар'**
  String get deliveryCreateProduct;

  /// No description provided for @deliveryDiscrepancy.
  ///
  /// In ru, this message translates to:
  /// **'Расхождение'**
  String get deliveryDiscrepancy;

  /// No description provided for @deliveryDocNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер документа'**
  String get deliveryDocNumber;

  /// No description provided for @deliveryExpectedQty.
  ///
  /// In ru, this message translates to:
  /// **'Ожидалось'**
  String get deliveryExpectedQty;

  /// No description provided for @deliveryHistory.
  ///
  /// In ru, this message translates to:
  /// **'История поставок'**
  String get deliveryHistory;

  /// No description provided for @deliveryNoHistory.
  ///
  /// In ru, this message translates to:
  /// **'Нет истории поставок'**
  String get deliveryNoHistory;

  /// No description provided for @deliverySupplier.
  ///
  /// In ru, this message translates to:
  /// **'Поставщик'**
  String get deliverySupplier;

  /// No description provided for @done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @importConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить импорт'**
  String get importConfirm;

  /// No description provided for @importCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создано'**
  String get importCreate;

  /// No description provided for @importDone.
  ///
  /// In ru, this message translates to:
  /// **'Импорт завершён'**
  String get importDone;

  /// No description provided for @importDownloadTemplate.
  ///
  /// In ru, this message translates to:
  /// **'Скачать шаблон'**
  String get importDownloadTemplate;

  /// No description provided for @importErrors.
  ///
  /// In ru, this message translates to:
  /// **'Ошибки'**
  String get importErrors;

  /// No description provided for @importSelectFile.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать файл'**
  String get importSelectFile;

  /// No description provided for @importSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Пропущено'**
  String get importSkipped;

  /// No description provided for @importTemplateSaved.
  ///
  /// In ru, this message translates to:
  /// **'Шаблон сохранён'**
  String get importTemplateSaved;

  /// No description provided for @importTitle.
  ///
  /// In ru, this message translates to:
  /// **'Импорт товаров'**
  String get importTitle;

  /// No description provided for @importUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено'**
  String get importUpdate;

  /// No description provided for @importUploadHint.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживается CSV или Excel'**
  String get importUploadHint;

  /// No description provided for @paymentCancelTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Отменить ожидание'**
  String get paymentCancelTimeout;

  /// No description provided for @paymentDebt.
  ///
  /// In ru, this message translates to:
  /// **'В долг'**
  String get paymentDebt;

  /// No description provided for @paymentDebtHint.
  ///
  /// In ru, this message translates to:
  /// **'Запишется как долг клиента'**
  String get paymentDebtHint;

  /// No description provided for @paymentNewReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Новый чек'**
  String get paymentNewReceipt;

  /// No description provided for @paymentNoShift.
  ///
  /// In ru, this message translates to:
  /// **'Откройте смену'**
  String get paymentNoShift;

  /// No description provided for @paymentPrintCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копия чека'**
  String get paymentPrintCopy;

  /// No description provided for @paymentProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Обработка платежа'**
  String get paymentProcessing;

  /// No description provided for @paymentReceiptNumber.
  ///
  /// In ru, this message translates to:
  /// **'Чек № {number}'**
  String paymentReceiptNumber(String number);

  /// No description provided for @paymentSelectClient.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать клиента'**
  String get paymentSelectClient;

  /// No description provided for @paymentSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено'**
  String get paymentSuccess;

  /// No description provided for @paymentTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Время ожидания истекло'**
  String get paymentTimeout;

  /// No description provided for @posDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get posDelete;

  /// No description provided for @posEnterDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get posEnterDiscount;

  /// No description provided for @posItemDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка на позицию'**
  String get posItemDiscount;

  /// No description provided for @posMultiAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить несколько'**
  String get posMultiAdd;

  /// No description provided for @posParkCart.
  ///
  /// In ru, this message translates to:
  /// **'Отложить'**
  String get posParkCart;

  /// No description provided for @posParkedCarts.
  ///
  /// In ru, this message translates to:
  /// **'Отложенные чеки'**
  String get posParkedCarts;

  /// No description provided for @posResume.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get posResume;

  /// No description provided for @posUndoRemove.
  ///
  /// In ru, this message translates to:
  /// **'Отменить удаление'**
  String get posUndoRemove;

  /// No description provided for @productsEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get productsEdit;

  /// No description provided for @productsMargin.
  ///
  /// In ru, this message translates to:
  /// **'Наценка'**
  String get productsMargin;

  /// No description provided for @productsPurchasePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена закупки'**
  String get productsPurchasePrice;

  /// No description provided for @productsSalePrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена продажи'**
  String get productsSalePrice;

  /// No description provided for @productsStock.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get productsStock;

  /// No description provided for @settingsBackup.
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия'**
  String get settingsBackup;

  /// No description provided for @settingsBackupExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get settingsBackupExport;

  /// No description provided for @settingsBackupSub.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и восстановить данные'**
  String get settingsBackupSub;

  /// No description provided for @settingsPrinter.
  ///
  /// In ru, this message translates to:
  /// **'Принтер чеков'**
  String get settingsPrinter;

  /// No description provided for @settingsPrinterSub.
  ///
  /// In ru, this message translates to:
  /// **'Подключение и тест печати'**
  String get settingsPrinterSub;

  /// No description provided for @settingsReceiptFormat.
  ///
  /// In ru, this message translates to:
  /// **'Формат чека'**
  String get settingsReceiptFormat;

  /// No description provided for @settingsReceiptFormatSub.
  ///
  /// In ru, this message translates to:
  /// **'Шапка, подвал, реквизиты'**
  String get settingsReceiptFormatSub;

  /// No description provided for @settingsScanner.
  ///
  /// In ru, this message translates to:
  /// **'Сканер штрих-кодов'**
  String get settingsScanner;

  /// No description provided for @settingsScannerSub.
  ///
  /// In ru, this message translates to:
  /// **'Камера или USB'**
  String get settingsScannerSub;

  /// No description provided for @settingsSyncStatus.
  ///
  /// In ru, this message translates to:
  /// **'Состояние синхронизации'**
  String get settingsSyncStatus;

  /// No description provided for @settingsWebkassa.
  ///
  /// In ru, this message translates to:
  /// **'Webkassa'**
  String get settingsWebkassa;

  /// No description provided for @settingsWebkassaLogin.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get settingsWebkassaLogin;

  /// No description provided for @settingsWebkassPwd.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get settingsWebkassPwd;

  /// No description provided for @settingsWebkassaSub.
  ///
  /// In ru, this message translates to:
  /// **'Фискализация чеков (онлайн-ККМ)'**
  String get settingsWebkassaSub;

  /// No description provided for @settingsWebkassaTestMode.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый режим'**
  String get settingsWebkassaTestMode;

  /// No description provided for @shellNoNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений'**
  String get shellNoNotifications;

  /// No description provided for @switchCashier.
  ///
  /// In ru, this message translates to:
  /// **'Сменить кассира'**
  String get switchCashier;

  /// No description provided for @shiftDeposit.
  ///
  /// In ru, this message translates to:
  /// **'Внесение'**
  String get shiftDeposit;

  /// No description provided for @shiftDepositSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Внесено'**
  String get shiftDepositSuccess;

  /// No description provided for @shiftDiscrepancyNote.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий к расхождению'**
  String get shiftDiscrepancyNote;

  /// No description provided for @shiftEnterAmount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get shiftEnterAmount;

  /// No description provided for @shiftEnterNote.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get shiftEnterNote;

  /// No description provided for @shiftNoReceipts.
  ///
  /// In ru, this message translates to:
  /// **'Чеков не было'**
  String get shiftNoReceipts;

  /// No description provided for @shiftOverdue24h.
  ///
  /// In ru, this message translates to:
  /// **'Смена открыта более 24 часов'**
  String get shiftOverdue24h;

  /// No description provided for @shiftOverdueWarning.
  ///
  /// In ru, this message translates to:
  /// **'Закройте смену вовремя'**
  String get shiftOverdueWarning;

  /// No description provided for @shiftPrintReport.
  ///
  /// In ru, this message translates to:
  /// **'Печать отчёта'**
  String get shiftPrintReport;

  /// No description provided for @shiftReceiptList.
  ///
  /// In ru, this message translates to:
  /// **'Чеки за смену'**
  String get shiftReceiptList;

  /// No description provided for @shiftSkipDenomination.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить номиналы'**
  String get shiftSkipDenomination;

  /// No description provided for @shiftManualTotalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ввести итог вручную'**
  String get shiftManualTotalTitle;

  /// No description provided for @shiftManualTotalBody.
  ///
  /// In ru, this message translates to:
  /// **'Укажите подсчитанную сумму наличных в кассе. Введённое значение заменит сумму по номиналам.'**
  String get shiftManualTotalBody;

  /// No description provided for @shiftManualTotalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Итого наличных'**
  String get shiftManualTotalLabel;

  /// No description provided for @shiftManualTotalClear.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get shiftManualTotalClear;

  /// No description provided for @shiftWithdraw.
  ///
  /// In ru, this message translates to:
  /// **'Изъятие'**
  String get shiftWithdraw;

  /// No description provided for @shiftWithdrawSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Изъято'**
  String get shiftWithdrawSuccess;

  /// No description provided for @shiftXReport.
  ///
  /// In ru, this message translates to:
  /// **'X-отчёт'**
  String get shiftXReport;

  /// No description provided for @posStockExceeded.
  ///
  /// In ru, this message translates to:
  /// **'Превышен остаток: доступно {qty}'**
  String posStockExceeded(String qty);

  /// No description provided for @posParkedCartLabel.
  ///
  /// In ru, this message translates to:
  /// **'{itemCount} поз. · {total}'**
  String posParkedCartLabel(int itemCount, String total);

  /// No description provided for @paymentTerminalUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Терминал оплаты не подключён'**
  String get paymentTerminalUnavailable;

  /// No description provided for @pinSelectCashier.
  ///
  /// In ru, this message translates to:
  /// **'Выберите кассира'**
  String get pinSelectCashier;

  /// No description provided for @pinCashierCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} профиль} few{{count} профиля} many{{count} профилей} other{{count} профилей}}'**
  String pinCashierCountLabel(int count);

  /// No description provided for @pinSelectedPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Выбран: '**
  String get pinSelectedPrefix;

  /// No description provided for @pinProceedToPin.
  ///
  /// In ru, this message translates to:
  /// **'Далее → PIN'**
  String get pinProceedToPin;

  /// No description provided for @pinLastBadge.
  ///
  /// In ru, this message translates to:
  /// **'ПОСЛЕДНИЙ'**
  String get pinLastBadge;

  /// No description provided for @pinAdminTile.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get pinAdminTile;

  /// No description provided for @pinAdminTileSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Email + пароль'**
  String get pinAdminTileSubtitle;

  /// No description provided for @pinNewCashier.
  ///
  /// In ru, this message translates to:
  /// **'Новый кассир'**
  String get pinNewCashier;

  /// No description provided for @posActionHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get posActionHistory;

  /// No description provided for @posActionPrintReceipt.
  ///
  /// In ru, this message translates to:
  /// **'Печать чека'**
  String get posActionPrintReceipt;

  /// No description provided for @posActionReportX.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт X'**
  String get posActionReportX;

  /// No description provided for @posActionReportZ.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт Z'**
  String get posActionReportZ;

  /// No description provided for @posActionDeposit.
  ///
  /// In ru, this message translates to:
  /// **'Внесение'**
  String get posActionDeposit;

  /// No description provided for @posActionWithdraw.
  ///
  /// In ru, this message translates to:
  /// **'Изъятие'**
  String get posActionWithdraw;

  /// No description provided for @posActionOpenDrawer.
  ///
  /// In ru, this message translates to:
  /// **'Откр. ящик'**
  String get posActionOpenDrawer;

  /// No description provided for @posActionGoodsCodes.
  ///
  /// In ru, this message translates to:
  /// **'Коды ТРУ'**
  String get posActionGoodsCodes;

  /// No description provided for @posActionLock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get posActionLock;

  /// No description provided for @shellSwitchCashierTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сменить кассира?'**
  String get shellSwitchCashierTitle;

  /// No description provided for @shellSwitchCashierMessage.
  ///
  /// In ru, this message translates to:
  /// **'В корзине есть товары. Смена кассира отменит текущую продажу. Вы уверены, что хотите продолжить?'**
  String get shellSwitchCashierMessage;

  /// No description provided for @shellSwitchCashierConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Сменить'**
  String get shellSwitchCashierConfirm;

  /// No description provided for @managerOverrideTitle.
  ///
  /// In ru, this message translates to:
  /// **'Требуется подтверждение менеджера'**
  String get managerOverrideTitle;

  /// No description provided for @managerOverrideActionLabel.
  ///
  /// In ru, this message translates to:
  /// **'ДЕЙСТВИЕ'**
  String get managerOverrideActionLabel;

  /// No description provided for @managerOverrideLoginLabel.
  ///
  /// In ru, this message translates to:
  /// **'Логин менеджера'**
  String get managerOverrideLoginLabel;

  /// No description provided for @managerOverridePinLabel.
  ///
  /// In ru, this message translates to:
  /// **'PIN менеджера'**
  String get managerOverridePinLabel;

  /// No description provided for @managerOverrideConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get managerOverrideConfirm;

  /// No description provided for @managerOverrideCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get managerOverrideCancel;

  /// No description provided for @managerOverrideLocked.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировано на 30 сек после 3 неверных попыток'**
  String get managerOverrideLocked;

  /// No description provided for @managerOverrideNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Логин не найден'**
  String get managerOverrideNotFound;

  /// No description provided for @managerOverrideWrongPin.
  ///
  /// In ru, this message translates to:
  /// **'Неверный PIN'**
  String get managerOverrideWrongPin;

  /// No description provided for @managerOverrideThisUser.
  ///
  /// In ru, this message translates to:
  /// **'Этот пользователь'**
  String get managerOverrideThisUser;

  /// No description provided for @managerOverrideInsufficientRole.
  ///
  /// In ru, this message translates to:
  /// **'{name} не может авторизовать эту операцию'**
  String managerOverrideInsufficientRole(String name);

  /// No description provided for @managerOverrideInactive.
  ///
  /// In ru, this message translates to:
  /// **'Учётная запись отключена'**
  String get managerOverrideInactive;

  /// No description provided for @paymentRemaining.
  ///
  /// In ru, this message translates to:
  /// **'Осталось'**
  String get paymentRemaining;

  /// No description provided for @posScanPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Отсканируйте товар'**
  String get posScanPrompt;

  /// No description provided for @posScanPromptHint.
  ///
  /// In ru, this message translates to:
  /// **'последний добавленный товар появится здесь'**
  String get posScanPromptHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
