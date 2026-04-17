// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'POS System';

  @override
  String get appRegion => 'QAZAQSTAN';

  @override
  String get navPos => 'КАССА';

  @override
  String get navShift => 'ТАРИХ';

  @override
  String get navProducts => 'ТАУАРЛАР';

  @override
  String get navStaff => 'ҚЫЗМЕТКЕРЛЕР';

  @override
  String get navDebts => 'ҚАРЫЗДАР';

  @override
  String get navAnalytics => 'АНАЛИТИКА';

  @override
  String get navDelivery => 'ЖЕТКІЗУ';

  @override
  String get navApproval => 'МАҚҰЛДАУ';

  @override
  String get navAudit => 'АУДИТ';

  @override
  String get navSettings => 'БАПТАУЛАР';

  @override
  String get navPosShort => 'Касса';

  @override
  String get navShiftShort => 'Тарих';

  @override
  String get navMore => 'Тағы';

  @override
  String get navProductsShort => 'Тауарлар';

  @override
  String get navStaffShort => 'Қызметкерлер';

  @override
  String get navDebtsShort => 'Қарыздар';

  @override
  String get navAnalyticsShort => 'Аналитика';

  @override
  String get navDeliveryShort => 'Жеткізу';

  @override
  String get navApprovalShort => 'Мақұлдау';

  @override
  String get navAuditShort => 'Аудит';

  @override
  String get navSettingsShort => 'Баптаулар';

  @override
  String get modeCashier => 'Касса';

  @override
  String get modeOwner => 'Иесі';

  @override
  String get logout => 'Жүйеден шығу';

  @override
  String get systemOnline => 'Жүйе онлайн';

  @override
  String get shiftOpened => 'Ауысым ашық';

  @override
  String get shiftClosed => 'Ауысым жабық';

  @override
  String get roleOwner => 'Иесі';

  @override
  String get roleAdmin => 'Әкімші';

  @override
  String get roleSeniorCashier => 'Аға кассир';

  @override
  String get roleSeniorCashierShort => 'Аға кассир';

  @override
  String get roleCashier => 'Кассир';

  @override
  String get cancel => 'Болдырмау';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Жабу';

  @override
  String get create => 'Жасау';

  @override
  String get delete => 'Жою';

  @override
  String get refresh => 'Жаңарту';

  @override
  String get add => 'Қосу';

  @override
  String get save => 'Сақтау';

  @override
  String get search => 'Іздеу';

  @override
  String get loadMore => 'Тағы жүктеу';

  @override
  String get noData => 'Деректер жоқ';

  @override
  String errorPrefix(String error) {
    return 'Қате: $error';
  }

  @override
  String get pinTerminal => 'Терминал #001';

  @override
  String get pinSelectProfile => 'ПРОФИЛЬДІ ТАҢДАҢЫЗ';

  @override
  String get pinCashierLabel => 'Кассир';

  @override
  String get pinEnterForLogin => 'Кіру үшін PIN енгізіңіз';

  @override
  String get pinChangeTerminal => 'Терминалды ауыстыру';

  @override
  String get pinWelcome => 'Қош келдіңіз';

  @override
  String get pinEnterCode => '4 санды PIN-кодты енгізіңіз';

  @override
  String get pinEncryptedAccess => 'ШИФРЛАНҒАН КІРУ';

  @override
  String get pinFirstRunTitle => 'Қош келдіңіз!';

  @override
  String get pinFirstRunSubtitle => 'Бірінші пайдаланушыны жасаңыз';

  @override
  String get pinFieldName => 'Аты';

  @override
  String get pinFieldPin => 'PIN-код (4 сан)';

  @override
  String get pinFieldConfirm => 'PIN-ді растаңыз';

  @override
  String get pinErrorLength => 'PIN 4 саннан тұруы керек';

  @override
  String get pinErrorMismatch => 'PIN-кодтар сәйкес келмейді';

  @override
  String get pinCreateAndLogin => 'Жасап кіру';

  @override
  String pinLockedMessage(String display) {
    return 'Құлыпталған: $display';
  }

  @override
  String get pinSec => 'сек.';

  @override
  String get paymentTitle => 'Төлем';

  @override
  String get paymentToPay => 'Төлеуге';

  @override
  String paymentVatLine(String amount) {
    return 'оның ішінде ҚҚС 12%: $amount';
  }

  @override
  String get paymentCash => 'Қолма-қол';

  @override
  String get paymentCard => 'Карта';

  @override
  String get paymentKaspiQR => 'Kaspi QR';

  @override
  String get paymentMix => 'Аралас';

  @override
  String get paymentChange => 'Қайтарым';

  @override
  String get paymentCardHint => 'Картаны терминалға тигізіңіз';

  @override
  String get paymentQRHint => 'Сатып алушыға QR-кодты көрсетіңіз';

  @override
  String paymentPayButton(String amount) {
    return 'Төлеу $amount';
  }

  @override
  String paymentPendingButton(String amount) {
    return 'Енгізіңіз $amount';
  }

  @override
  String get shiftNotOpened => 'Ауысым ашылмаған';

  @override
  String shiftCashierLabel(String name) {
    return 'Кассир: $name';
  }

  @override
  String get shiftCashInDrawer => 'Кассадағы қолма-қол (₸)';

  @override
  String get shiftOpen => 'Ауысымды ашу';

  @override
  String get shiftReconciliation => 'Ауысым тексеру';

  @override
  String get shiftCountCash => 'Қолма-қол санау';

  @override
  String get shiftCountInstruction =>
      'Кассадағы әрбір банкнот санын енгізіңіз.';

  @override
  String get shiftBanknote => 'БАНКНОТ';

  @override
  String get shiftCoin => 'ТИЫНДАР';

  @override
  String get shiftSubtotal => 'Жиыны';

  @override
  String get shiftManualAdjust => 'Қолмен түзету';

  @override
  String get shiftAdjustSubtitle =>
      'Тапшылық немесе артықшылық туралы жазбалар';

  @override
  String get shiftNote => 'Жазба';

  @override
  String get shiftStatCash => 'ҚОЛМА-ҚОЛ';

  @override
  String get shiftStatCard => 'КАРТА';

  @override
  String get shiftStatKaspiQR => 'KASPI QR';

  @override
  String get shiftStatReturns => 'ҚАЙТАРЫМДАР';

  @override
  String get shiftSummary => 'Ауысым қорытындысы';

  @override
  String get shiftStartBalance => 'Бастапқы қалдық';

  @override
  String get shiftCashSales => 'Қолма-қол сатылымдар';

  @override
  String get shiftReturnsPayouts => 'Қайтарымдар/Төлемдер';

  @override
  String get shiftExpectedBalance => 'КҮТІЛЕТІН ҚАЛДЫҚ';

  @override
  String get shiftCounted => 'САНАЛДЫ';

  @override
  String get shiftDiscrepancy => 'Алшақтық';

  @override
  String get shiftLabel => 'Ауысым';

  @override
  String shiftNumber(int number) {
    return 'Ауысым №$number';
  }

  @override
  String get shiftReceipts => 'чек';

  @override
  String get shiftCashStart => 'Бастапқы қолма-қол';

  @override
  String get shiftCurrentBalance => 'Ағымдағы қалдық';

  @override
  String get shiftCloseZReport => 'Ауысымды жабу (Z-есеп)';

  @override
  String get shiftCloseConfirmTitle => 'Ауысымды жабу керек пе?';

  @override
  String get shiftCloseConfirmBody =>
      'Z-есеп қалыптастырылады. Бұл әрекетті қайтару мүмкін емес.';

  @override
  String get shiftCloseButton => 'Ауысымды жабу';

  @override
  String get shiftCloseFooter =>
      'Ауысымды жабу арқылы кассадағы қолма-қол санағын растайсыз.';

  @override
  String get productsTitle => 'Тауарлар';

  @override
  String productsCountLabel(int count) {
    return 'каталогта $count позиция';
  }

  @override
  String get productsTotalStat => 'БАРЛЫҚ ТАУАРЛАР';

  @override
  String get productsWeightedStat => 'САЛМАҚТЫҚ';

  @override
  String get productsPieceStat => 'ДАНАЛЫҚ';

  @override
  String get productsAvgPriceStat => 'ОРТАША БАҒА';

  @override
  String get productsTotalShort => 'БАРЛЫҒЫ';

  @override
  String get productsAvgPriceShort => 'ОРТ. БАҒА';

  @override
  String get productsSearchHint => 'Атау немесе штрих-код бойынша іздеу...';

  @override
  String productsTabAll(int count) {
    return 'Барлығы ($count)';
  }

  @override
  String productsTabWeighted(int count) {
    return 'Салмақтық ($count)';
  }

  @override
  String productsTabPiece(int count) {
    return 'Даналық ($count)';
  }

  @override
  String get productsColName => 'ТАУАР';

  @override
  String get productsColBarcode => 'ШТРИХ-КОД';

  @override
  String get productsColVat => 'ҚҚС';

  @override
  String get productsColPrice => 'БАҒА';

  @override
  String get productsNotFound => 'Ештеңе табылмады';

  @override
  String get productsEmpty => 'Тауарлар жоқ';

  @override
  String get productsTryAnother => 'Басқа сұрауды қолданып көріңіз';

  @override
  String get productsEmptyHint =>
      'Бірінші тауарды қосыңыз немесе\nбаптауларда демо-деректерді жүктеңіз';

  @override
  String get productsDeleteConfirm => 'Тауарды жою керек пе?';

  @override
  String get productsNew => 'Жаңа тауар';

  @override
  String get productsFieldBarcode => 'Штрих-код (GTIN)';

  @override
  String get productsNkt => 'ҰТК';

  @override
  String get productsEnterBarcode => 'Штрих-кодты енгізіңіз';

  @override
  String get productsNktNotFound => 'ҰТК-да табылмады';

  @override
  String productsNktError(String error) {
    return 'ҰТК қатесі: $error';
  }

  @override
  String get productsFieldName => 'Атауы';

  @override
  String get productsFieldPrice => 'Бағасы (₸)';

  @override
  String get productsWeighted => 'Салмақтық тауар';

  @override
  String get productsWeightedSubPriceKg => 'Кг үшін баға';

  @override
  String get productsWeightedSubPricePcs => 'Дана үшін баға';

  @override
  String get productsTypeWeighted => 'Салмақтық';

  @override
  String get productsTypePiece => 'Даналық';

  @override
  String get cashiersTitle => 'Қызметкерлер';

  @override
  String cashiersCountLabel(int count) {
    return '$count қызметкер';
  }

  @override
  String get cashiersStatTotal => 'Барлығы';

  @override
  String get cashiersStatOwners => 'Иелері';

  @override
  String get cashiersStatManagers => 'Менеджерлер';

  @override
  String get cashiersColName => 'АТЫ';

  @override
  String get cashiersColRole => 'РӨЛІ';

  @override
  String get cashiersEmpty => 'Кассирлер жоқ';

  @override
  String get cashiersNew => 'Жаңа кассир';

  @override
  String get cashiersFieldName => 'Аты';

  @override
  String get cashiersFieldPin => 'PIN (4 сан)';

  @override
  String get cashiersFieldRole => 'Рөлі';

  @override
  String get cashiersEnterName => 'Атын енгізіңіз';

  @override
  String get debtsTitle => 'Қарыздар';

  @override
  String debtsCountLabel(int open, int clients) {
    return '$open ашық, $clients клиент';
  }

  @override
  String get debtsNewDebt => 'Жаңа қарыз';

  @override
  String get debtsTotalBanner => 'ЖАЛПЫ БЕРЕШЕК';

  @override
  String get debtsRecordsLabel => 'жазба';

  @override
  String debtsTabOpen(int count) {
    return 'Ашық ($count)';
  }

  @override
  String debtsTabAll(int count) {
    return 'Барлығы ($count)';
  }

  @override
  String get debtsEmpty => 'Қарыздар жоқ';

  @override
  String get debtsPayTitle => 'Қарызды өтеу';

  @override
  String debtsPayRemaining(String amount) {
    return 'Қалдық: $amount';
  }

  @override
  String get debtsFieldAmount => 'Сома (₸)';

  @override
  String get debtsEnterAmount => 'Соманы енгізіңіз';

  @override
  String get debtsPay => 'Төлеу';

  @override
  String get debtsCreateTitle => 'Қарызға сату';

  @override
  String get debtsFieldClient => 'Клиент';

  @override
  String get debtsFieldNote => 'Ескертпе';

  @override
  String get debtsSelectClient => 'Клиентті таңдаңыз';

  @override
  String get debtsRecord => 'Қарызды жазу';

  @override
  String get debtsClientDefault => 'Клиент';

  @override
  String get debtsPaid => 'Өтелді';

  @override
  String debtsOfTotal(String amount) {
    return '$amount ішінен';
  }

  @override
  String get debtsPayment => 'Төлем';

  @override
  String get debtsClosed => 'Жабық';

  @override
  String debtsPaidLabel(String amount) {
    return 'Өтелді: $amount';
  }

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get analyticsSubtitle => 'Бизнеске шолу';

  @override
  String get analyticsToday => 'БҮГІН';

  @override
  String get analyticsYesterday => 'КЕШЕ';

  @override
  String get analyticsWeek => 'АПТА';

  @override
  String get analyticsMonth => 'АЙ';

  @override
  String get analyticsReceipts => 'чек';

  @override
  String get analyticsPaymentTypes => 'Төлем түрлері бойынша';

  @override
  String get analyticsTopProducts => 'Топ тауарлар (30 күн)';

  @override
  String get analyticsCashiers => 'Кассирлер';

  @override
  String get analyticsLowStock => 'Қалдықтар (аз)';

  @override
  String get analyticsDebts => 'Қарыздар';

  @override
  String get analyticsAllNormal => 'Бәрі қалыпты';

  @override
  String get analyticsCash => 'Қолма-қол';

  @override
  String get analyticsCard => 'Карта';

  @override
  String get analyticsKaspiQR => 'Kaspi QR';

  @override
  String get analyticsOpenDebts => 'Ашық';

  @override
  String get analyticsToPayDebts => 'Төлеуге';

  @override
  String get analyticsPaidDebts => 'Өтелді';

  @override
  String get deliveryTitle => 'Тауар жеткізу';

  @override
  String get deliverySearchHint => 'Тауар іздеу...';

  @override
  String deliveryCostLabel(String amount) {
    return 'Өзіндік құн: $amount';
  }

  @override
  String deliveryLinesLabel(int count) {
    return 'Позициялар ($count)';
  }

  @override
  String get deliveryEmptyHint => 'Жеткізу үшін тауарларды қосыңыз';

  @override
  String get deliveryFieldQty => 'Саны';

  @override
  String get deliveryFieldCost => 'Өзіндік құн (тиын)';

  @override
  String get deliverySubmit => 'Жеткізуді рәсімдеу';

  @override
  String get deliverySuccess => 'Жеткізу рәсімделді';

  @override
  String get approvalTitle => 'Тауарларды мақұлдау';

  @override
  String get approvalSubtitle => 'ҰТК тауарлары тексеруді күтуде';

  @override
  String get approvalEmpty => 'Күтудегі тауарлар жоқ';

  @override
  String get approvalPending => 'КҮТУДЕ';

  @override
  String approvalFrom(String name) {
    return 'кімнен: $name';
  }

  @override
  String get approvalBarcode => 'Штрих-код';

  @override
  String get approvalNtin => 'ҰТИН';

  @override
  String get approvalSalePrice => 'Сату бағасы';

  @override
  String get approvalReject => 'Қабылдамау';

  @override
  String get approvalApprove => 'Мақұлдау';

  @override
  String get approvalApproveTitle => 'Тауарды мақұлдау';

  @override
  String get approvalFieldName => 'Атауы';

  @override
  String get approvalFieldPrice => 'Сату бағасы (тиын)';

  @override
  String get approvalRejectTitle => 'Тауарды қабылдамау';

  @override
  String get approvalRejectReason => 'Себебі (міндетті емес)';

  @override
  String get approvalApproved => 'Тауар мақұлданды';

  @override
  String get approvalRejected => 'Тауар қабылданбады';

  @override
  String get auditTitle => 'Аудит журналы';

  @override
  String auditTotalLabel(int count) {
    return 'Барлық жазбалар: $count';
  }

  @override
  String get auditEmpty => 'Жазбалар жоқ';

  @override
  String get auditActionReceiptCreated => 'Чек жасалды';

  @override
  String get auditActionShiftOpened => 'Ауысым ашылды';

  @override
  String get auditActionShiftClosed => 'Ауысым жабылды';

  @override
  String get auditActionNktApproved => 'ҰТК тауар мақұлданды';

  @override
  String get auditActionNktRejected => 'ҰТК тауар қабылданбады';

  @override
  String get auditActionProductCreated => 'Тауар жасалды';

  @override
  String get auditActionProductEdited => 'Тауар өзгертілді';

  @override
  String get auditActionProductDeleted => 'Тауар жойылды';

  @override
  String get auditActionDebtCreated => 'Қарыз жасалды';

  @override
  String get auditActionDebtPaid => 'Қарыз өтелді';

  @override
  String get auditActionCashierCreated => 'Кассир қосылды';

  @override
  String get auditActionDeliveryReceived => 'Жеткізу рәсімделді';

  @override
  String get settingsTitle => 'Баптаулар';

  @override
  String get settingsSubtitle => 'Жүйе конфигурациясы';

  @override
  String get settingsActions => 'Әрекеттер';

  @override
  String get settingsSeedDemo => 'Демо-деректерді жүктеу';

  @override
  String get settingsSeedDemoSub => '17 тауар, 6 санат, 3 клиент';

  @override
  String get settingsCheckNkt => 'ҰТК тексеру';

  @override
  String get settingsCheckNktSub => 'Штрих-код немесе атау бойынша тауар іздеу';

  @override
  String get settingsSystem => 'Жүйе';

  @override
  String get settingsAbout => 'Жүйе туралы';

  @override
  String get settingsAboutSub => 'POS System Kazakhstan v0.1.0';

  @override
  String get settingsServer => 'Сервер';

  @override
  String get settingsServerStatus => 'Сервер күйі';

  @override
  String get settingsServerConnected => 'Қосылған';

  @override
  String get settingsServerUnavailable => 'Қол жетімсіз';

  @override
  String get settingsIntegrations => 'Интеграциялар';

  @override
  String get settingsLanguage => 'Тіл / Язык';

  @override
  String get settingsLanguageSub => 'Қазақша';

  @override
  String get settingsLanguageKk => 'Қазақша';

  @override
  String get settingsFiscal => 'Фискализация';

  @override
  String get settingsNotConnected => 'Қосылмаған';

  @override
  String get settingsNktTitle => 'ҰТК (Ұлттық тауар каталогы)';

  @override
  String get settingsNktConnected => 'Қосылған';

  @override
  String get settingsNktNotConfigured => 'Баптау қажет';

  @override
  String get settingsNktSearch => 'ҰТК-дан іздеу';

  @override
  String get settingsNktBarcode => 'Штрих-код';

  @override
  String get settingsNktName => 'Атауы';

  @override
  String get settingsNktGtinHint => 'GTIN (штрих-код)';

  @override
  String get settingsNktNameHint => 'Тауар атауы';

  @override
  String get settingsNktNotFound => 'Ештеңе табылмады';

  @override
  String get settingsNktSocial => 'ӘМТ';

  @override
  String get posTabProducts => 'Тауарлар';

  @override
  String get posTabReceipt => 'Чек';

  @override
  String get posSearchHint => 'Тауар іздеу немесе штрих-код сканерлеу...';

  @override
  String get posCatAll => 'Барлығы';

  @override
  String get posCatFood => 'Тағам';

  @override
  String get posCatDrinks => 'Сусындар';

  @override
  String get posCatGrocery => 'Бакалея';

  @override
  String get posCatDairy => 'Сүт өнімдері';

  @override
  String get posCatOther => 'Басқа';

  @override
  String get posOnline => 'Онлайн';

  @override
  String get posEnterNameOr => 'Атауды енгізіңіз немесе';

  @override
  String get posScanBarcode => 'штрих-кодты сканерлеңіз';

  @override
  String get posNotFoundLocally => 'Жергілікті табылмады';

  @override
  String get posEnterFullBarcode => 'Толық штрих-кодты енгізіңіз (8–14 сан)';

  @override
  String get posForAutoNkt => 'ҰТК-да автоматты іздеу үшін';

  @override
  String posBarcodeProgress(int current) {
    return '$current сан енгізілді, 8–14 қажет';
  }

  @override
  String posNotFoundQuery(String query) {
    return '«$query» сұрауы бойынша ештеңе табылмады';
  }

  @override
  String get posSearchingNkt => 'ҰТК-да іздеу...';

  @override
  String get posNotFoundLocallyHeader => 'Тауар жергілікті табылмады';

  @override
  String posNktFoundCount(int count, String barcode) {
    return '$barcode штрих-коды бойынша ҰТК-да $count табылды';
  }

  @override
  String get posNktSelectInstruction => 'Каталогқа қосу үшін тауарды таңдаңыз:';

  @override
  String get posNktAddTitle => 'ҰТК-дан тауар қосу';

  @override
  String get posNktPriceKg => 'Кг бағасы (₸)';

  @override
  String get posNktPricePcs => 'Бағасы (₸)';

  @override
  String get posNktAddAndSell => 'Қосып сату';

  @override
  String get posNktSentForApproval => 'Тауар иесінің мақұлдауына жіберілді';

  @override
  String posNktCreateError(String error) {
    return 'Тауар жасау қатесі: $error';
  }

  @override
  String get posCartTitle => 'Ағымдағы чек';

  @override
  String get posCartItems => 'поз.';

  @override
  String get posCartEmpty => 'Чек бос';

  @override
  String get posCartEmptyHint => 'Сол жақтан тауар табыңыз';

  @override
  String get posQuantity => 'Саны';

  @override
  String get posVat12 => 'ҚҚС 12%';

  @override
  String get posTotal => 'Жиыны';

  @override
  String get posPayment => 'ТӨЛЕМ';

  @override
  String posPaymentWithAmount(String amount) {
    return 'ТӨЛЕМ  $amount';
  }

  @override
  String get posTakeaway => 'Өзіммен';

  @override
  String get posCancelSale => 'Болдырмау';

  @override
  String get posOpenShiftFirst => 'Алдымен ауысымды ашыңыз';

  @override
  String get analyticsAllTime => 'Барлық уақыт';

  @override
  String get analyticsAutoRefresh => 'Авто жаңарту';

  @override
  String get analyticsAvgReceipt => 'Орташа чек';

  @override
  String get analyticsClearFilter => 'Сүзгіні тазалау';

  @override
  String get analyticsDateRange => 'Кезең';

  @override
  String get analyticsExport => 'Экспорт';

  @override
  String get analyticsExportSuccess => 'Экспорт орындалды';

  @override
  String get analyticsProductName => 'Тауар';

  @override
  String get analyticsQty => 'Саны';

  @override
  String get analyticsRevenue => 'Кіріс';

  @override
  String get analyticsRevenueByProduct => 'Тауар бойынша кіріс';

  @override
  String get approvalBatchApprove => 'Таңдалғандарды бекіту';

  @override
  String approvalBatchCount(int count) {
    return '$count тауар';
  }

  @override
  String get approvalDefaultMarkup => 'Әдепкі үстеме';

  @override
  String get cashiersDeactivate => 'Өшіру';

  @override
  String get cashiersDeactivateConfirm => 'Кассирді өшіресіз бе?';

  @override
  String get cashiersDeactivateHint =>
      'Кассир кіре алмайды. Кейін қайта белсендіруге болады.';

  @override
  String get cashiersDeactivated => 'Кассир өшірілді';

  @override
  String get cashiersEdit => 'Өзгерту';

  @override
  String get cashiersNewPin => 'Жаңа PIN';

  @override
  String get cashiersPinConfirm => 'PIN-ды растаңыз';

  @override
  String get cashiersResetPin => 'PIN-ды қалпына келтіру';

  @override
  String get cashiersResetPinSuccess => 'PIN қалпына келтірілді';

  @override
  String get cashiersRoleAdminDesc => 'Иеленушіден басқа толық қол жеткізу';

  @override
  String get cashiersRoleCashierDesc => 'Тек сатылым және ауысым';

  @override
  String get cashiersRoleSeniorDesc => 'Кассир + қайтарулар мен жеңілдіктер';

  @override
  String get debtsOverdue => 'Мерзімі өткен';

  @override
  String get debtsRemainingAmount => 'Өтеу қалдығы';

  @override
  String get debtsSearch => 'Клиент немесе телефон бойынша іздеу';

  @override
  String get deliveryActualQty => 'Нақты';

  @override
  String get deliveryAddSupplier => 'Жеткізушіні қосу';

  @override
  String get deliveryCreateProduct => 'Тауар құру';

  @override
  String get deliveryDiscrepancy => 'Айырмашылық';

  @override
  String get deliveryDocNumber => 'Құжат нөмірі';

  @override
  String get deliveryExpectedQty => 'Күтілді';

  @override
  String get deliveryHistory => 'Жеткізілім тарихы';

  @override
  String get deliveryNoHistory => 'Жеткізілім тарихы жоқ';

  @override
  String get deliverySupplier => 'Жеткізуші';

  @override
  String get done => 'Дайын';

  @override
  String get importConfirm => 'Импортты растау';

  @override
  String get importCreate => 'Құрылды';

  @override
  String get importDone => 'Импорт аяқталды';

  @override
  String get importDownloadTemplate => 'Үлгіні жүктеу';

  @override
  String get importErrors => 'Қателер';

  @override
  String get importSelectFile => 'Файлды таңдау';

  @override
  String get importSkipped => 'Өткізілді';

  @override
  String get importTemplateSaved => 'Үлгі сақталды';

  @override
  String get importTitle => 'Тауар импорты';

  @override
  String get importUpdate => 'Жаңартылды';

  @override
  String get importUploadHint => 'CSV немесе Excel қолдалынады';

  @override
  String get paymentCancelTimeout => 'Күтуді тоқтату';

  @override
  String get paymentDebt => 'Қарызға';

  @override
  String get paymentDebtHint => 'Клиент қарызы ретінде жазылады';

  @override
  String get paymentNewReceipt => 'Жаңа чек';

  @override
  String get paymentNoShift => 'Ауысым ашыңыз';

  @override
  String get paymentPrintCopy => 'Чек көшірмесі';

  @override
  String get paymentProcessing => 'Төлемді өңдеу';

  @override
  String paymentReceiptNumber(String number) {
    return 'Чек № $number';
  }

  @override
  String get paymentSelectClient => 'Клиентті таңдау';

  @override
  String get paymentSuccess => 'Төленді';

  @override
  String get paymentTimeout => 'Күту уақыты өтті';

  @override
  String get posDelete => 'Жою';

  @override
  String get posEnterDiscount => 'Жеңілдік';

  @override
  String get posItemDiscount => 'Позицияға жеңілдік';

  @override
  String get posMultiAdd => 'Бірнеше қосу';

  @override
  String get posParkCart => 'Кейінге қалдыру';

  @override
  String get posParkedCarts => 'Кейінге қалдырылған чектер';

  @override
  String get posResume => 'Жалғастыру';

  @override
  String get posUndoRemove => 'Жоюды кері қайтару';

  @override
  String get productsEdit => 'Өзгерту';

  @override
  String get productsMargin => 'Үстеме';

  @override
  String get productsPurchasePrice => 'Сатып алу бағасы';

  @override
  String get productsSalePrice => 'Сату бағасы';

  @override
  String get productsStock => 'Қалдық';

  @override
  String get settingsBackup => 'Сақтық көшірме';

  @override
  String get settingsBackupExport => 'Экспорт';

  @override
  String get settingsBackupSub => 'Деректерді сақтау және қалпына келтіру';

  @override
  String get settingsPrinter => 'Чек принтері';

  @override
  String get settingsPrinterSub => 'Қосылу және басып шығаруды тексеру';

  @override
  String get settingsReceiptFormat => 'Чек пішімі';

  @override
  String get settingsReceiptFormatSub => 'Шапка, тұманша, деректемелер';

  @override
  String get settingsScanner => 'Штрих-код сканері';

  @override
  String get settingsScannerSub => 'Камера немесе USB';

  @override
  String get settingsSyncStatus => 'Синхрондау күйі';

  @override
  String get settingsWebkassa => 'Webkassa';

  @override
  String get settingsWebkassaLogin => 'Логин';

  @override
  String get settingsWebkassPwd => 'Құпия сөз';

  @override
  String get settingsWebkassaSub => 'Чектерді фискалдау (онлайн-ККМ)';

  @override
  String get settingsWebkassaTestMode => 'Сынақ режимі';

  @override
  String get shellNoNotifications => 'Хабарландыру жоқ';

  @override
  String get switchCashier => 'Кассирді ауыстыру';

  @override
  String get shiftDeposit => 'Енгізу';

  @override
  String get shiftDepositSuccess => 'Енгізілді';

  @override
  String get shiftDiscrepancyNote => 'Айырмашылық туралы түсініктеме';

  @override
  String get shiftEnterAmount => 'Сома';

  @override
  String get shiftEnterNote => 'Түсініктеме';

  @override
  String get shiftNoReceipts => 'Чектер болған жоқ';

  @override
  String get shiftOverdue24h => 'Ауысым 24 сағаттан астам ашық';

  @override
  String get shiftOverdueWarning => 'Ауысымды уақытында жабыңыз';

  @override
  String get shiftPrintReport => 'Есепті басып шығару';

  @override
  String get shiftReceiptList => 'Ауысым чектері';

  @override
  String get shiftSkipDenomination => 'Номиналдарды өткізу';

  @override
  String get shiftManualTotalTitle => 'Қолмен жиынтық енгізу';

  @override
  String get shiftManualTotalBody =>
      'Кассадағы қолма-қол ақшаның есептелген сомасын көрсетіңіз. Енгізілген мән номиналдар бойынша жиынтықты алмастырады.';

  @override
  String get shiftManualTotalLabel => 'Қолма-қол ақша жиынтығы';

  @override
  String get shiftManualTotalClear => 'Тазарту';

  @override
  String get shiftWithdraw => 'Алу';

  @override
  String get shiftWithdrawSuccess => 'Алынды';

  @override
  String get shiftXReport => 'X-есеп';

  @override
  String posStockExceeded(String qty) {
    return 'Қалдық асқан: қолжетімді $qty';
  }

  @override
  String posParkedCartLabel(int itemCount, String total) {
    return '$itemCount поз. · $total';
  }
}
