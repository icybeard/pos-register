// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'POS System';

  @override
  String get appRegion => 'KAZAKHSTAN';

  @override
  String get navPos => 'КАССА';

  @override
  String get navShift => 'ИСТОРИЯ';

  @override
  String get navProducts => 'ТОВАРЫ';

  @override
  String get navStaff => 'ПЕРСОНАЛ';

  @override
  String get navDebts => 'ДОЛГИ';

  @override
  String get navAnalytics => 'АНАЛИТИКА';

  @override
  String get navDelivery => 'ПОСТАВКИ';

  @override
  String get navApproval => 'ОДОБРЕНИЕ';

  @override
  String get navAudit => 'АУДИТ';

  @override
  String get navSettings => 'НАСТРОЙКИ';

  @override
  String get navPosShort => 'Касса';

  @override
  String get navShiftShort => 'История';

  @override
  String get navMore => 'Ещё';

  @override
  String get navProductsShort => 'Товары';

  @override
  String get navStaffShort => 'Персонал';

  @override
  String get navDebtsShort => 'Долги';

  @override
  String get navAnalyticsShort => 'Аналитика';

  @override
  String get navDeliveryShort => 'Поставки';

  @override
  String get navApprovalShort => 'Одобрение';

  @override
  String get navAuditShort => 'Аудит';

  @override
  String get navSettingsShort => 'Настройки';

  @override
  String get modeCashier => 'Касса';

  @override
  String get modeOwner => 'Владелец';

  @override
  String get logout => 'Выйти из системы';

  @override
  String get systemOnline => 'Система онлайн';

  @override
  String get shiftOpened => 'Смена открыта';

  @override
  String get shiftClosed => 'Смена закрыта';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleSeniorCashier => 'Старший кассир';

  @override
  String get roleSeniorCashierShort => 'Ст. кассир';

  @override
  String get roleCashier => 'Кассир';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Закрыть';

  @override
  String get create => 'Создать';

  @override
  String get delete => 'Удалить';

  @override
  String get refresh => 'Обновить';

  @override
  String get add => 'Добавить';

  @override
  String get save => 'Сохранить';

  @override
  String get search => 'Поиск';

  @override
  String get loadMore => 'Загрузить ещё';

  @override
  String get noData => 'Нет данных';

  @override
  String errorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get pinTerminal => 'Терминал #001';

  @override
  String get pinSelectProfile => 'ВЫБЕРИТЕ ПРОФИЛЬ';

  @override
  String get pinCashierLabel => 'Кассир';

  @override
  String get pinEnterForLogin => 'Введите PIN для входа';

  @override
  String get pinChangeTerminal => 'Сменить терминал';

  @override
  String get pinWelcome => 'Добро пожаловать';

  @override
  String get pinEnterCode => 'Введите 4-значный PIN-код';

  @override
  String get pinEncryptedAccess => 'ЗАШИФРОВАННЫЙ ДОСТУП';

  @override
  String get pinFirstRunTitle => 'Добро пожаловать!';

  @override
  String get pinFirstRunSubtitle => 'Создайте первого пользователя';

  @override
  String get pinFieldName => 'Имя';

  @override
  String get pinFieldPin => 'PIN-код (4 цифры)';

  @override
  String get pinFieldConfirm => 'Подтвердите PIN';

  @override
  String get pinErrorLength => 'PIN должен быть 4 цифры';

  @override
  String get pinErrorMismatch => 'PIN-коды не совпадают';

  @override
  String get pinCreateAndLogin => 'Создать и войти';

  @override
  String pinLockedMessage(String display) {
    return 'Заблокировано: $display';
  }

  @override
  String get pinSec => 'сек.';

  @override
  String get paymentTitle => 'Оплата';

  @override
  String get paymentToPay => 'К оплате';

  @override
  String paymentVatLine(String amount) {
    return 'в т.ч. НДС 12%: $amount';
  }

  @override
  String get paymentCash => 'Наличные';

  @override
  String get paymentCard => 'Карта';

  @override
  String get paymentKaspiQR => 'Kaspi QR';

  @override
  String get paymentMix => 'Микс';

  @override
  String get paymentChange => 'Сдача';

  @override
  String get paymentCardHint => 'Приложите карту к терминалу';

  @override
  String get paymentQRHint => 'Покажите QR-код покупателю';

  @override
  String paymentPayButton(String amount) {
    return 'Оплатить $amount';
  }

  @override
  String paymentPendingButton(String amount) {
    return 'Внесите $amount';
  }

  @override
  String get shiftNotOpened => 'Смена не открыта';

  @override
  String shiftCashierLabel(String name) {
    return 'Кассир: $name';
  }

  @override
  String get shiftCashInDrawer => 'Наличные в кассе (₸)';

  @override
  String get shiftOpen => 'Открыть смену';

  @override
  String get shiftReconciliation => 'Сверка смены';

  @override
  String get shiftCountCash => 'Пересчёт наличных';

  @override
  String get shiftCountInstruction =>
      'Введите количество каждой купюры в кассе.';

  @override
  String get shiftBanknote => 'КУПЮРА';

  @override
  String get shiftCoin => 'МОНЕТЫ';

  @override
  String get shiftSubtotal => 'Подитого';

  @override
  String get shiftManualAdjust => 'Ручная корректировка';

  @override
  String get shiftAdjustSubtitle => 'Заметки о недостачах или излишках';

  @override
  String get shiftNote => 'Заметка';

  @override
  String get shiftStatCash => 'НАЛИЧНЫЕ';

  @override
  String get shiftStatCard => 'КАРТА';

  @override
  String get shiftStatKaspiQR => 'KASPI QR';

  @override
  String get shiftStatReturns => 'ВОЗВРАТЫ';

  @override
  String get shiftSummary => 'Итоги смены';

  @override
  String get shiftStartBalance => 'Начальный остаток';

  @override
  String get shiftCashSales => 'Наличные продажи';

  @override
  String get shiftReturnsPayouts => 'Возвраты/Выплаты';

  @override
  String get shiftExpectedBalance => 'ОЖИДАЕМЫЙ ОСТАТОК';

  @override
  String get shiftCounted => 'ПОДСЧИТАНО';

  @override
  String get shiftDiscrepancy => 'Расхождение';

  @override
  String get shiftLabel => 'Смена';

  @override
  String shiftNumber(int number) {
    return 'Смена №$number';
  }

  @override
  String get shiftReceipts => 'чеков';

  @override
  String get shiftCashStart => 'Наличные на начало';

  @override
  String get shiftCurrentBalance => 'Текущий остаток';

  @override
  String get shiftCloseZReport => 'Закрыть смену (Z-отчёт)';

  @override
  String get shiftCloseConfirmTitle => 'Закрыть смену?';

  @override
  String get shiftCloseConfirmBody =>
      'Будет сформирован Z-отчёт. Это действие нельзя отменить.';

  @override
  String get shiftCloseButton => 'Закрыть смену';

  @override
  String get shiftCloseFooter =>
      'Закрывая смену, вы подтверждаете пересчёт наличных в кассе.';

  @override
  String get productsTitle => 'Товары';

  @override
  String productsCountLabel(int count) {
    return '$count позиций в каталоге';
  }

  @override
  String get productsTotalStat => 'ВСЕГО ТОВАРОВ';

  @override
  String get productsWeightedStat => 'ВЕСОВЫХ';

  @override
  String get productsPieceStat => 'ШТУЧНЫХ';

  @override
  String get productsAvgPriceStat => 'СРЕДНЯЯ ЦЕНА';

  @override
  String get productsTotalShort => 'ВСЕГО';

  @override
  String get productsAvgPriceShort => 'СР. ЦЕНА';

  @override
  String get productsSearchHint => 'Поиск по названию или штрих-коду...';

  @override
  String productsTabAll(int count) {
    return 'Все ($count)';
  }

  @override
  String productsTabWeighted(int count) {
    return 'Весовые ($count)';
  }

  @override
  String productsTabPiece(int count) {
    return 'Штучные ($count)';
  }

  @override
  String get productsColName => 'ТОВАР';

  @override
  String get productsColBarcode => 'ШТРИХ-КОД';

  @override
  String get productsColVat => 'НДС';

  @override
  String get productsColPrice => 'ЦЕНА';

  @override
  String get productsNotFound => 'Ничего не найдено';

  @override
  String get productsEmpty => 'Нет товаров';

  @override
  String get productsTryAnother => 'Попробуйте другой запрос';

  @override
  String get productsEmptyHint =>
      'Добавьте первый товар или\nзагрузите демо-данные в настройках';

  @override
  String get productsDeleteConfirm => 'Удалить товар?';

  @override
  String get productsNew => 'Новый товар';

  @override
  String get productsFieldBarcode => 'Штрих-код (GTIN)';

  @override
  String get productsNkt => 'НКТ';

  @override
  String get productsEnterBarcode => 'Введите штрих-код';

  @override
  String get productsNktNotFound => 'Не найден в НКТ';

  @override
  String productsNktError(String error) {
    return 'Ошибка НКТ: $error';
  }

  @override
  String get productsFieldName => 'Название';

  @override
  String get productsFieldPrice => 'Цена (₸)';

  @override
  String get productsWeighted => 'Весовой товар';

  @override
  String get productsWeightedSubPriceKg => 'Цена за кг';

  @override
  String get productsWeightedSubPricePcs => 'Цена за штуку';

  @override
  String get productsTypeWeighted => 'Весовой';

  @override
  String get productsTypePiece => 'Штучный';

  @override
  String get cashiersTitle => 'Персонал';

  @override
  String cashiersCountLabel(int count) {
    return '$count сотрудников';
  }

  @override
  String get cashiersStatTotal => 'Всего';

  @override
  String get cashiersStatOwners => 'Владельцев';

  @override
  String get cashiersStatManagers => 'Менеджеров';

  @override
  String get cashiersColName => 'ИМЯ';

  @override
  String get cashiersColRole => 'РОЛЬ';

  @override
  String get cashiersEmpty => 'Нет кассиров';

  @override
  String get cashiersNew => 'Новый кассир';

  @override
  String get cashiersFieldName => 'Имя';

  @override
  String get cashiersFieldPin => 'PIN (4 цифры)';

  @override
  String get cashiersFieldRole => 'Роль';

  @override
  String get cashiersEnterName => 'Введите имя';

  @override
  String get debtsTitle => 'Долги';

  @override
  String debtsCountLabel(int open, int clients) {
    return '$open открытых, $clients клиентов';
  }

  @override
  String get debtsNewDebt => 'Новый долг';

  @override
  String get debtsTotalBanner => 'ОБЩАЯ ЗАДОЛЖЕННОСТЬ';

  @override
  String get debtsRecordsLabel => 'записей';

  @override
  String debtsTabOpen(int count) {
    return 'Открытые ($count)';
  }

  @override
  String debtsTabAll(int count) {
    return 'Все ($count)';
  }

  @override
  String get debtsEmpty => 'Нет долгов';

  @override
  String get debtsPayTitle => 'Погашение долга';

  @override
  String debtsPayRemaining(String amount) {
    return 'Остаток: $amount';
  }

  @override
  String get debtsFieldAmount => 'Сумма (₸)';

  @override
  String get debtsEnterAmount => 'Введите сумму';

  @override
  String get debtsPay => 'Оплатить';

  @override
  String get debtsCreateTitle => 'Продажа в долг';

  @override
  String get debtsFieldClient => 'Клиент';

  @override
  String get debtsFieldNote => 'Примечание';

  @override
  String get debtsSelectClient => 'Выберите клиента';

  @override
  String get debtsRecord => 'Записать долг';

  @override
  String get debtsClientDefault => 'Клиент';

  @override
  String get debtsPaid => 'Погашено';

  @override
  String debtsOfTotal(String amount) {
    return 'из $amount';
  }

  @override
  String get debtsPayment => 'Оплата';

  @override
  String get debtsClosed => 'Закрыт';

  @override
  String debtsPaidLabel(String amount) {
    return 'Оплачено: $amount';
  }

  @override
  String get analyticsTitle => 'Аналитика';

  @override
  String get analyticsSubtitle => 'Обзор бизнеса';

  @override
  String get analyticsToday => 'СЕГОДНЯ';

  @override
  String get analyticsYesterday => 'ВЧЕРА';

  @override
  String get analyticsWeek => 'НЕДЕЛЯ';

  @override
  String get analyticsMonth => 'МЕСЯЦ';

  @override
  String get analyticsReceipts => 'чеков';

  @override
  String get analyticsPaymentTypes => 'Оплата по типам';

  @override
  String get analyticsTopProducts => 'Топ товаров (30 дней)';

  @override
  String get analyticsCashiers => 'Кассиры';

  @override
  String get analyticsLowStock => 'Остатки (низкие)';

  @override
  String get analyticsDebts => 'Долги';

  @override
  String get analyticsAllNormal => 'Все в норме';

  @override
  String get analyticsCash => 'Наличные';

  @override
  String get analyticsCard => 'Карта';

  @override
  String get analyticsKaspiQR => 'Kaspi QR';

  @override
  String get analyticsOpenDebts => 'Открытых';

  @override
  String get analyticsToPayDebts => 'К оплате';

  @override
  String get analyticsPaidDebts => 'Погашено';

  @override
  String get deliveryTitle => 'Поставка товаров';

  @override
  String get deliverySearchHint => 'Поиск товара...';

  @override
  String deliveryCostLabel(String amount) {
    return 'Себестоимость: $amount';
  }

  @override
  String deliveryLinesLabel(int count) {
    return 'Позиции ($count)';
  }

  @override
  String get deliveryEmptyHint => 'Добавьте товары для поставки';

  @override
  String get deliveryFieldQty => 'Кол-во';

  @override
  String get deliveryFieldCost => 'Себестоимость (тиын)';

  @override
  String get deliverySubmit => 'Оформить поставку';

  @override
  String get deliverySuccess => 'Поставка оформлена';

  @override
  String get approvalTitle => 'Одобрение товаров';

  @override
  String get approvalSubtitle => 'НКТ товары ожидают проверки';

  @override
  String get approvalEmpty => 'Нет ожидающих товаров';

  @override
  String get approvalPending => 'ОЖИДАЕТ';

  @override
  String approvalFrom(String name) {
    return 'от: $name';
  }

  @override
  String get approvalBarcode => 'Штрих-код';

  @override
  String get approvalNtin => 'НТИН';

  @override
  String get approvalSalePrice => 'Цена продажи';

  @override
  String get approvalReject => 'Отклонить';

  @override
  String get approvalApprove => 'Одобрить';

  @override
  String get approvalApproveTitle => 'Одобрить товар';

  @override
  String get approvalFieldName => 'Название';

  @override
  String get approvalFieldPrice => 'Цена продажи (тиын)';

  @override
  String get approvalRejectTitle => 'Отклонить товар';

  @override
  String get approvalRejectReason => 'Причина (необязательно)';

  @override
  String get approvalApproved => 'Товар одобрен';

  @override
  String get approvalRejected => 'Товар отклонён';

  @override
  String get auditTitle => 'Журнал аудита';

  @override
  String auditTotalLabel(int count) {
    return 'Всего записей: $count';
  }

  @override
  String get auditEmpty => 'Нет записей';

  @override
  String get auditActionReceiptCreated => 'Чек создан';

  @override
  String get auditActionShiftOpened => 'Смена открыта';

  @override
  String get auditActionShiftClosed => 'Смена закрыта';

  @override
  String get auditActionNktApproved => 'НКТ товар одобрен';

  @override
  String get auditActionNktRejected => 'НКТ товар отклонён';

  @override
  String get auditActionProductCreated => 'Товар создан';

  @override
  String get auditActionProductEdited => 'Товар изменён';

  @override
  String get auditActionProductDeleted => 'Товар удалён';

  @override
  String get auditActionDebtCreated => 'Долг создан';

  @override
  String get auditActionDebtPaid => 'Долг погашен';

  @override
  String get auditActionCashierCreated => 'Кассир добавлен';

  @override
  String get auditActionDeliveryReceived => 'Поставка оформлена';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSubtitle => 'Конфигурация системы';

  @override
  String get settingsActions => 'Действия';

  @override
  String get settingsSeedDemo => 'Загрузить демо-данные';

  @override
  String get settingsSeedDemoSub => '17 товаров, 6 категорий, 3 клиента';

  @override
  String get settingsCheckNkt => 'Проверить НКТ';

  @override
  String get settingsCheckNktSub => 'Поиск товара по штрих-коду или названию';

  @override
  String get settingsSystem => 'Система';

  @override
  String get settingsAbout => 'О системе';

  @override
  String get settingsAboutSub => 'POS System Kazakhstan v0.1.0';

  @override
  String get settingsServer => 'Сервер';

  @override
  String get settingsServerStatus => 'Статус сервера';

  @override
  String get settingsServerConnected => 'Подключен';

  @override
  String get settingsServerUnavailable => 'Не доступен';

  @override
  String get settingsIntegrations => 'Интеграции';

  @override
  String get settingsLanguage => 'Язык / Тiл';

  @override
  String get settingsLanguageSub => 'Русский';

  @override
  String get settingsLanguageKk => 'Қазақша';

  @override
  String get settingsFiscal => 'Фискализация';

  @override
  String get settingsNotConnected => 'Не подключено';

  @override
  String get settingsNktTitle => 'НКТ (Национальный каталог)';

  @override
  String get settingsNktConnected => 'Подключено';

  @override
  String get settingsNktNotConfigured => 'Не настроено';

  @override
  String get settingsNktSearch => 'Поиск в НКТ';

  @override
  String get settingsNktBarcode => 'Штрих-код';

  @override
  String get settingsNktName => 'Название';

  @override
  String get settingsNktGtinHint => 'GTIN (штрих-код)';

  @override
  String get settingsNktNameHint => 'Название товара';

  @override
  String get settingsNktNotFound => 'Ничего не найдено';

  @override
  String get settingsNktSocial => 'СЗТ';

  @override
  String get posTabProducts => 'Товары';

  @override
  String get posTabReceipt => 'Чек';

  @override
  String get posSearchHint => 'Поиск товара или скан штрих-кода...';

  @override
  String get posCatAll => 'Все';

  @override
  String get posCatFood => 'Продукты';

  @override
  String get posCatDrinks => 'Напитки';

  @override
  String get posCatGrocery => 'Бакалея';

  @override
  String get posCatDairy => 'Молочные';

  @override
  String get posCatOther => 'Прочее';

  @override
  String get posOnline => 'Онлайн';

  @override
  String get posEnterNameOr => 'Введите название или';

  @override
  String get posScanBarcode => 'отсканируйте штрих-код';

  @override
  String get posNotFoundLocally => 'Не найдено локально';

  @override
  String get posEnterFullBarcode => 'Введите полный штрих-код (8–14 цифр)';

  @override
  String get posForAutoNkt => 'для автоматического поиска в НКТ';

  @override
  String posBarcodeProgress(int current) {
    return 'Введено $current из 8–14 цифр';
  }

  @override
  String posNotFoundQuery(String query) {
    return 'По запросу «$query» ничего не найдено';
  }

  @override
  String get posSearchingNkt => 'Поиск в НКТ...';

  @override
  String get posNotFoundLocallyHeader => 'Товар не найден локально';

  @override
  String posNktFoundCount(int count, String barcode) {
    return 'Найдено $count в Национальном каталоге (НКТ) по штрих-коду $barcode';
  }

  @override
  String get posNktSelectInstruction =>
      'Выберите товар для добавления в каталог:';

  @override
  String get posNktAddTitle => 'Добавить товар из НКТ';

  @override
  String get posNktPriceKg => 'Цена за кг (₸)';

  @override
  String get posNktPricePcs => 'Цена (₸)';

  @override
  String get posNktAddAndSell => 'Добавить и продать';

  @override
  String get posNktSentForApproval => 'Товар отправлен на одобрение владельцу';

  @override
  String posNktCreateError(String error) {
    return 'Ошибка создания товара: $error';
  }

  @override
  String get posCartTitle => 'Текущий чек';

  @override
  String get posCartItems => 'поз.';

  @override
  String get posCartEmpty => 'Чек пуст';

  @override
  String get posCartEmptyHint => 'Найдите товар слева';

  @override
  String get posQuantity => 'Количество';

  @override
  String get posVat12 => 'НДС 12%';

  @override
  String get posTotal => 'Итого';

  @override
  String get posPayment => 'ОПЛАТА';

  @override
  String posPaymentWithAmount(String amount) {
    return 'ОПЛАТА  $amount';
  }

  @override
  String get posTakeaway => 'С собой';

  @override
  String get posCancelSale => 'Отмена';

  @override
  String get posOpenShiftFirst => 'Сначала откройте смену';

  @override
  String get analyticsAllTime => 'Всё время';

  @override
  String get analyticsAutoRefresh => 'Автообновление';

  @override
  String get analyticsAvgReceipt => 'Средний чек';

  @override
  String get analyticsClearFilter => 'Сбросить фильтр';

  @override
  String get analyticsDateRange => 'Период';

  @override
  String get analyticsExport => 'Экспорт';

  @override
  String get analyticsExportSuccess => 'Экспорт выполнен';

  @override
  String get analyticsProductName => 'Товар';

  @override
  String get analyticsQty => 'Кол-во';

  @override
  String get analyticsRevenue => 'Выручка';

  @override
  String get analyticsRevenueByProduct => 'Выручка по товарам';

  @override
  String get approvalBatchApprove => 'Одобрить выбранные';

  @override
  String approvalBatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String get approvalDefaultMarkup => 'Наценка по умолчанию';

  @override
  String get cashiersDeactivate => 'Деактивировать';

  @override
  String get cashiersDeactivateConfirm => 'Деактивировать кассира?';

  @override
  String get cashiersDeactivateHint =>
      'Кассир не сможет войти. Активацию можно вернуть позже.';

  @override
  String get cashiersDeactivated => 'Кассир деактивирован';

  @override
  String get cashiersEdit => 'Изменить';

  @override
  String get cashiersNewPin => 'Новый PIN';

  @override
  String get cashiersPinConfirm => 'Подтвердите PIN';

  @override
  String get cashiersResetPin => 'Сбросить PIN';

  @override
  String get cashiersResetPinSuccess => 'PIN сброшен';

  @override
  String get cashiersRoleAdminDesc => 'Полный доступ кроме владельца';

  @override
  String get cashiersRoleCashierDesc => 'Только продажи и смены';

  @override
  String get cashiersRoleSeniorDesc => 'Кассир + возвраты и скидки';

  @override
  String get debtsOverdue => 'Просрочено';

  @override
  String get debtsRemainingAmount => 'Остаток к погашению';

  @override
  String get debtsSearch => 'Поиск по клиенту или телефону';

  @override
  String get deliveryActualQty => 'Факт';

  @override
  String get deliveryAddSupplier => 'Добавить поставщика';

  @override
  String get deliveryCreateProduct => 'Создать товар';

  @override
  String get deliveryDiscrepancy => 'Расхождение';

  @override
  String get deliveryDocNumber => 'Номер документа';

  @override
  String get deliveryExpectedQty => 'Ожидалось';

  @override
  String get deliveryHistory => 'История поставок';

  @override
  String get deliveryNoHistory => 'Нет истории поставок';

  @override
  String get deliverySupplier => 'Поставщик';

  @override
  String get done => 'Готово';

  @override
  String get importConfirm => 'Подтвердить импорт';

  @override
  String get importCreate => 'Создано';

  @override
  String get importDone => 'Импорт завершён';

  @override
  String get importDownloadTemplate => 'Скачать шаблон';

  @override
  String get importErrors => 'Ошибки';

  @override
  String get importSelectFile => 'Выбрать файл';

  @override
  String get importSkipped => 'Пропущено';

  @override
  String get importTemplateSaved => 'Шаблон сохранён';

  @override
  String get importTitle => 'Импорт товаров';

  @override
  String get importUpdate => 'Обновлено';

  @override
  String get importUploadHint => 'Поддерживается CSV или Excel';

  @override
  String get paymentCancelTimeout => 'Отменить ожидание';

  @override
  String get paymentDebt => 'В долг';

  @override
  String get paymentDebtHint => 'Запишется как долг клиента';

  @override
  String get paymentNewReceipt => 'Новый чек';

  @override
  String get paymentNoShift => 'Откройте смену';

  @override
  String get paymentPrintCopy => 'Копия чека';

  @override
  String get paymentProcessing => 'Обработка платежа';

  @override
  String paymentReceiptNumber(String number) {
    return 'Чек № $number';
  }

  @override
  String get paymentSelectClient => 'Выбрать клиента';

  @override
  String get paymentSuccess => 'Оплачено';

  @override
  String get paymentTimeout => 'Время ожидания истекло';

  @override
  String get posDelete => 'Удалить';

  @override
  String get posEnterDiscount => 'Скидка';

  @override
  String get posItemDiscount => 'Скидка на позицию';

  @override
  String get posMultiAdd => 'Добавить несколько';

  @override
  String get posParkCart => 'Отложить';

  @override
  String get posParkedCarts => 'Отложенные чеки';

  @override
  String get posResume => 'Продолжить';

  @override
  String get posUndoRemove => 'Отменить удаление';

  @override
  String get productsEdit => 'Редактировать';

  @override
  String get productsMargin => 'Наценка';

  @override
  String get productsPurchasePrice => 'Цена закупки';

  @override
  String get productsSalePrice => 'Цена продажи';

  @override
  String get productsStock => 'Остаток';

  @override
  String get settingsBackup => 'Резервная копия';

  @override
  String get settingsBackupExport => 'Экспорт';

  @override
  String get settingsBackupSub => 'Сохранить и восстановить данные';

  @override
  String get settingsPrinter => 'Принтер чеков';

  @override
  String get settingsPrinterSub => 'Подключение и тест печати';

  @override
  String get settingsReceiptFormat => 'Формат чека';

  @override
  String get settingsReceiptFormatSub => 'Шапка, подвал, реквизиты';

  @override
  String get settingsScanner => 'Сканер штрих-кодов';

  @override
  String get settingsScannerSub => 'Камера или USB';

  @override
  String get settingsSyncStatus => 'Состояние синхронизации';

  @override
  String get settingsWebkassa => 'Webkassa';

  @override
  String get settingsWebkassaLogin => 'Логин';

  @override
  String get settingsWebkassPwd => 'Пароль';

  @override
  String get settingsWebkassaSub => 'Фискализация чеков (онлайн-ККМ)';

  @override
  String get settingsWebkassaTestMode => 'Тестовый режим';

  @override
  String get shellNoNotifications => 'Нет уведомлений';

  @override
  String get switchCashier => 'Сменить кассира';

  @override
  String get shiftDeposit => 'Внесение';

  @override
  String get shiftDepositSuccess => 'Внесено';

  @override
  String get shiftDiscrepancyNote => 'Комментарий к расхождению';

  @override
  String get shiftEnterAmount => 'Сумма';

  @override
  String get shiftEnterNote => 'Комментарий';

  @override
  String get shiftNoReceipts => 'Чеков не было';

  @override
  String get shiftOverdue24h => 'Смена открыта более 24 часов';

  @override
  String get shiftOverdueWarning => 'Закройте смену вовремя';

  @override
  String get shiftPrintReport => 'Печать отчёта';

  @override
  String get shiftReceiptList => 'Чеки за смену';

  @override
  String get shiftSkipDenomination => 'Пропустить номиналы';

  @override
  String get shiftManualTotalTitle => 'Ввести итог вручную';

  @override
  String get shiftManualTotalBody =>
      'Укажите подсчитанную сумму наличных в кассе. Введённое значение заменит сумму по номиналам.';

  @override
  String get shiftManualTotalLabel => 'Итого наличных';

  @override
  String get shiftManualTotalClear => 'Сбросить';

  @override
  String get shiftWithdraw => 'Изъятие';

  @override
  String get shiftWithdrawSuccess => 'Изъято';

  @override
  String get shiftXReport => 'X-отчёт';

  @override
  String posStockExceeded(String qty) {
    return 'Превышен остаток: доступно $qty';
  }

  @override
  String posParkedCartLabel(int itemCount, String total) {
    return '$itemCount поз. · $total';
  }
}
