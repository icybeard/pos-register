import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

/// First-run setup wizard. Shown when no owner account exists.
/// Steps:
///   0) Language
///   1) Owner account
///   2) Store details (name, BIN/IIN, address, phone)
///   3) Hardware setup (printer, scanner, scales)
///   4) Initial data (import / demo / skip)
class SetupWizard extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onComplete;

  const SetupWizard({super.key, required this.api, required this.onComplete});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  static const _totalSteps = 5;

  int _step = 0;
  String _language = 'ru';
  bool _loading = false;
  String? _error;

  // Step 1: Owner
  final _nameC = TextEditingController();
  final _pinC = TextEditingController();
  final _confirmC = TextEditingController();

  // Step 2: Store details
  final _storeNameC = TextEditingController();
  final _storeBinC = TextEditingController();
  final _storeAddressC = TextEditingController();
  final _storePhoneC = TextEditingController();

  // Step 3: Hardware
  String _printerType = 'none'; // none | 58mm | 80mm
  bool _scannerEnabled = false;
  bool _scaleEnabled = false;

  @override
  void dispose() {
    _nameC.dispose();
    _pinC.dispose();
    _confirmC.dispose();
    _storeNameC.dispose();
    _storeBinC.dispose();
    _storeAddressC.dispose();
    _storePhoneC.dispose();
    super.dispose();
  }

  // ─── helpers ────────────────────────────────────────────────

  String _t(String ru, String kk) => _language == 'kk' ? kk : ru;

  Future<void> _createOwner() async {
    final pin = _pinC.text;
    if (pin.length != 4) {
      setState(() => _error = _t('PIN должен быть 4 цифры', 'PIN 4 сан болуы керек'));
      return;
    }
    if (pin != _confirmC.text) {
      setState(() => _error = _t('PIN-коды не совпадают', 'PIN-кодтар сәйкес келмейді'));
      return;
    }
    if (_nameC.text.trim().isEmpty) {
      setState(() => _error = _t('Введите имя', 'Атыңызды енгізіңіз'));
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await widget.api.createCashier(name: _nameC.text.trim(), pin: pin, role: 'owner');
      await widget.api.setSetting('ui_language', _language);
      setState(() { _step = 2; _loading = false; });
    } on Exception catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveStoreDetails() async {
    final name = _storeNameC.text.trim();
    if (name.isEmpty) {
      setState(() => _error = _t('Введите название магазина', 'Дүкен атауын енгізіңіз'));
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await widget.api.setSetting('store_name', name);
      final bin = _storeBinC.text.trim();
      if (bin.isNotEmpty) {
        await widget.api.setSetting('store_bin', bin);
      }
      final addr = _storeAddressC.text.trim();
      if (addr.isNotEmpty) {
        await widget.api.setSetting('store_address', addr);
      }
      final phone = _storePhoneC.text.trim();
      if (phone.isNotEmpty) {
        await widget.api.setSetting('store_phone', phone);
      }
      setState(() { _step = 3; _loading = false; });
    } on Exception catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveHardwareSettings() async {
    setState(() { _loading = true; _error = null; });
    try {
      await widget.api.setSetting('printer_type', _printerType);
      await widget.api.setSetting('scanner_enabled', _scannerEnabled.toString());
      await widget.api.setSetting('scale_enabled', _scaleEnabled.toString());
      setState(() { _step = 4; _loading = false; });
    } on Exception catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _seedDemo() async {
    setState(() => _loading = true);
    try {
      await widget.api.seedDemo();
    } on Exception catch (_) {
      // non-critical
    }
    await _finish();
  }

  Future<void> _finish() async {
    try {
      await widget.api.setSetting('setup_complete', 'true');
    } on Exception catch (_) {}
    widget.onComplete();
  }

  // ─── build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.store_rounded, size: 34, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'POS System Kazakhstan',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 8),
                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalSteps, (i) => Container(
                        width: i == _step ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppTheme.primary : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                    // Step label
                    Text(
                      _stepLabel(),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 24),

                    if (_step == 0) _buildLanguageStep(),
                    if (_step == 1) _buildOwnerStep(),
                    if (_step == 2) _buildStoreDetailsStep(),
                    if (_step == 3) _buildHardwareStep(),
                    if (_step == 4) _buildInitialDataStep(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepLabel() {
    switch (_step) {
      case 0: return _t('Шаг 1 из 5 — Язык', '1-қадам, 5-тен — Тіл');
      case 1: return _t('Шаг 2 из 5 — Владелец', '2-қадам, 5-тен — Иесі');
      case 2: return _t('Шаг 3 из 5 — Магазин', '3-қадам, 5-тен — Дүкен');
      case 3: return _t('Шаг 4 из 5 — Оборудование', '4-қадам, 5-тен — Жабдық');
      case 4: return _t('Шаг 5 из 5 — Данные', '5-қадам, 5-тен — Деректер');
      default: return '';
    }
  }

  // ─── Step 0: Language ───────────────────────────────────────

  Widget _buildLanguageStep() {
    return Column(children: [
      const Text(
        'Тілді таңдаңыз / Выберите язык',
        style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 20),
      _LanguageOption(
        label: 'Русский',
        subtitle: 'Все элементы интерфейса на русском языке',
        selected: _language == 'ru',
        onTap: () => setState(() => _language = 'ru'),
      ),
      const SizedBox(height: 10),
      _LanguageOption(
        label: 'Қазақша',
        subtitle: 'Интерфейс қазақ тілінде',
        selected: _language == 'kk',
        onTap: () => setState(() => _language = 'kk'),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => setState(() => _step = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _t('Далее', 'Келесі'),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ]);
  }

  // ─── Step 1: Owner account ─────────────────────────────────

  Widget _buildOwnerStep() {
    return Column(children: [
      Text(
        _t('Создайте владельца', 'Иесін жасаңыз'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        _t('Этот аккаунт будет иметь полный доступ', 'Бұл аккаунтта толық рұқсат болады'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF74777D)),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _nameC,
        decoration: InputDecoration(
          labelText: _t('Имя', 'Аты'),
          prefixIcon: const Icon(Icons.person_outline),
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _pinC,
        decoration: InputDecoration(
          labelText: _t('PIN-код (4 цифры)', 'PIN-код (4 сан)'),
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmC,
        decoration: InputDecoration(
          labelText: _t('Подтвердите PIN', 'PIN-ді растаңыз'),
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      _buildErrorBanner(),
      const SizedBox(height: 20),
      _buildNavRow(
        onBack: () => setState(() { _step = 0; _error = null; }),
        onNext: _loading ? null : _createOwner,
        nextLabel: _t('Создать', 'Жасау'),
      ),
    ]);
  }

  // ─── Step 2: Store details ─────────────────────────────────

  Widget _buildStoreDetailsStep() {
    return Column(children: [
      const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.primary),
      const SizedBox(height: 12),
      Text(
        _t('Реквизиты магазина', 'Дүкен деректемелері'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        _t(
          'Эти данные будут печататься на чеках',
          'Бұл деректер чектерде басылады',
        ),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF74777D)),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _storeNameC,
        decoration: InputDecoration(
          labelText: _t('Название магазина *', 'Дүкен атауы *'),
          prefixIcon: const Icon(Icons.store_outlined),
          hintText: _t('ИП Иванов / ТОО "Мой Магазин"', 'ЖК Иванов / ЖШС "Менің Дүкенім"'),
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _storeBinC,
        decoration: InputDecoration(
          labelText: _t('БИН / ИИН', 'БСН / ЖСН'),
          prefixIcon: const Icon(Icons.badge_outlined),
          hintText: '123456789012',
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
        keyboardType: TextInputType.number,
        maxLength: 12,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _storeAddressC,
        decoration: InputDecoration(
          labelText: _t('Адрес', 'Мекенжай'),
          prefixIcon: const Icon(Icons.location_on_outlined),
          hintText: _t('г. Алматы, ул. Абая 1', 'Алматы қ., Абай к-сі 1'),
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _storePhoneC,
        decoration: InputDecoration(
          labelText: _t('Телефон', 'Телефон'),
          prefixIcon: const Icon(Icons.phone_outlined),
          hintText: '+7 (7xx) xxx-xx-xx',
        ),
        style: const TextStyle(fontFamily: 'Inter', ),
        keyboardType: TextInputType.phone,
      ),
      _buildErrorBanner(),
      const SizedBox(height: 20),
      _buildNavRow(
        onBack: () => setState(() { _step = 1; _error = null; }),
        onNext: _loading ? null : _saveStoreDetails,
        nextLabel: _t('Далее', 'Келесі'),
      ),
    ]);
  }

  // ─── Step 3: Hardware setup ─────────────────────────────────

  Widget _buildHardwareStep() {
    return Column(children: [
      const Icon(Icons.print_rounded, size: 40, color: AppTheme.primary),
      const SizedBox(height: 12),
      Text(
        _t('Оборудование', 'Жабдық'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        _t(
          'Настройте подключённое оборудование',
          'Қосылған жабдықты баптаңыз',
        ),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF74777D)),
      ),
      const SizedBox(height: 20),

      // Printer
      _SectionLabel(label: _t('Принтер чеков', 'Чек принтері')),
      const SizedBox(height: 8),
      Row(children: [
        _HardwareChip(
          label: _t('Нет', 'Жоқ'),
          icon: Icons.cancel_outlined,
          selected: _printerType == 'none',
          onTap: () => setState(() => _printerType = 'none'),
        ),
        const SizedBox(width: 8),
        _HardwareChip(
          label: '58 mm',
          icon: Icons.receipt_long_outlined,
          selected: _printerType == '58mm',
          onTap: () => setState(() => _printerType = '58mm'),
        ),
        const SizedBox(width: 8),
        _HardwareChip(
          label: '80 mm',
          icon: Icons.receipt_outlined,
          selected: _printerType == '80mm',
          onTap: () => setState(() => _printerType = '80mm'),
        ),
      ]),

      const SizedBox(height: 20),

      // Scanner
      _SectionLabel(label: _t('Сканер штрих-кодов', 'Штрих-код сканері')),
      const SizedBox(height: 8),
      _ToggleTile(
        label: _t(
          'USB / Bluetooth сканер подключён',
          'USB / Bluetooth сканер қосылған',
        ),
        icon: Icons.qr_code_scanner_rounded,
        value: _scannerEnabled,
        onChanged: (v) => setState(() => _scannerEnabled = v),
      ),

      const SizedBox(height: 16),

      // Scale
      _SectionLabel(label: _t('Весы', 'Таразы')),
      const SizedBox(height: 8),
      _ToggleTile(
        label: _t(
          'Электронные весы подключены',
          'Электронды таразы қосылған',
        ),
        icon: Icons.scale_rounded,
        value: _scaleEnabled,
        onChanged: (v) => setState(() => _scaleEnabled = v),
      ),

      _buildErrorBanner(),
      const SizedBox(height: 24),
      _buildNavRow(
        onBack: () => setState(() { _step = 2; _error = null; }),
        onNext: _loading ? null : _saveHardwareSettings,
        nextLabel: _t('Далее', 'Келесі'),
        skipLabel: _t('Пропустить', 'Өткізу'),
        onSkip: () {
          setState(() { _step = 4; _error = null; });
        },
        skipHint: _t(
          'Можно настроить позже в разделе Настройки',
          'Кейін Баптаулар бөлімінде баптауға болады',
        ),
      ),
    ]);
  }

  // ─── Step 4: Initial data ──────────────────────────────────

  Widget _buildInitialDataStep() {
    return Column(children: [
      const Icon(Icons.check_circle_rounded, size: 56, color: Color(0xFF4EDEA3)),
      const SizedBox(height: 12),
      Text(
        _t('Почти готово!', 'Дерлік дайын!'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary),
      ),
      const SizedBox(height: 6),
      Text(
        _t('Выберите, как наполнить каталог товаров', 'Тауар каталогін қалай толтыруды таңдаңыз'),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF74777D)),
      ),
      const SizedBox(height: 24),

      // Option 1: Import
      _DataOptionCard(
        icon: Icons.upload_file_rounded,
        title: _t('Импорт из Excel / CSV', 'Excel / CSV импорты'),
        subtitle: _t(
          'Подготовьте файл с товарами и загрузите его в разделе Товары после завершения настройки',
          'Тауарлар бар файлды дайындап, баптау аяқталғаннан кейін Тауарлар бөлімінде жүктеңіз',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _t('Скоро', 'Жақында'),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF856404)),
          ),
        ),
      ),

      const SizedBox(height: 10),

      // Option 2: Demo data
      _DataOptionCard(
        icon: Icons.science_rounded,
        title: _t('Загрузить демо-данные', 'Демо-деректерді жүктеу'),
        subtitle: _t(
          '17 товаров, 6 категорий, 3 клиента — для ознакомления с системой',
          '17 тауар, 6 санат, 3 клиент — жүйемен танысу үшін',
        ),
        actionLabel: _t('Загрузить', 'Жүктеу'),
        onAction: _loading ? null : _seedDemo,
        isLoading: _loading,
      ),

      const SizedBox(height: 10),

      // Option 3: Start empty
      _DataOptionCard(
        icon: Icons.add_shopping_cart_rounded,
        title: _t('Начать с пустого каталога', 'Бос каталогтан бастау'),
        subtitle: _t(
          'Добавляйте товары вручную или сканером по мере работы',
          'Тауарларды жұмыс барысында қолмен немесе сканермен қосыңыз',
        ),
        actionLabel: _t('Начать работу', 'Жұмысты бастау'),
        onAction: _loading ? null : _finish,
      ),

      const SizedBox(height: 16),
      // Back
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() { _step = 3; _error = null; }),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(_t('Назад', 'Артқа')),
        ),
      ),
    ]);
  }

  // ─── shared widgets ─────────────────────────────────────────

  Widget _buildErrorBanner() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(fontFamily: 'Inter', color: AppTheme.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required VoidCallback? onBack,
    required VoidCallback? onNext,
    required String nextLabel,
    String? skipLabel,
    VoidCallback? onSkip,
    String? skipHint,
  }) {
    return Column(
      children: [
        Row(children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(_t('Назад', 'Артқа')),
          ),
          const Spacer(),
          if (skipLabel != null && onSkip != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: onSkip,
                child: Text(skipLabel),
              ),
            ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(nextLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        if (skipHint != null) ...[
          const SizedBox(height: 8),
          Text(
            skipHint,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable private widgets
// ═══════════════════════════════════════════════════════════════

class _LanguageOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6EEFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppTheme.primary : const Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.primary : const Color(0xFF374151),
                ),
              ),
              Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF74777D))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      ),
    );
  }
}

class _HardwareChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _HardwareChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6EEFF) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? AppTheme.primary : const Color(0xFF6B7280)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppTheme.primary : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFE6EEFF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primary : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(children: [
        Icon(icon, size: 22, color: value ? AppTheme.primary : const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value ? AppTheme.primary : const Color(0xFF374151),
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primary,
        ),
      ]),
    );
  }
}

class _DataOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool isLoading;

  const _DataOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF74777D)),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(actionLabel!, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
