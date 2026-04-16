// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loginMeta = const VerificationMeta('login');
  @override
  late final GeneratedColumn<String> login = GeneratedColumn<String>(
    'login',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    name,
    login,
    email,
    pinHash,
    role,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('login')) {
      context.handle(
        _loginMeta,
        login.isAcceptableOrUnknown(data['login']!, _loginMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      login: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String name;
  final String? login;
  final String? email;
  final String? pinHash;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.name,
    this.login,
    this.email,
    this.pinHash,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || login != null) {
      map['login'] = Variable<String>(login);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['role'] = Variable<String>(role);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      login: login == null && nullToAbsent
          ? const Value.absent()
          : Value(login),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      role: Value(role),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      login: serializer.fromJson<String?>(json['login']),
      email: serializer.fromJson<String?>(json['email']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      role: serializer.fromJson<String>(json['role']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'login': serializer.toJson<String?>(login),
      'email': serializer.toJson<String?>(email),
      'pinHash': serializer.toJson<String?>(pinHash),
      'role': serializer.toJson<String>(role),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> login = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> pinHash = const Value.absent(),
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    login: login.present ? login.value : this.login,
    email: email.present ? email.value : this.email,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserRow copyWithCompanion(UsersTableCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      login: data.login.present ? data.login.value : this.login,
      email: data.email.present ? data.email.value : this.email,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      role: data.role.present ? data.role.value : this.role,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('login: $login, ')
          ..write('email: $email, ')
          ..write('pinHash: $pinHash, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    storeId,
    name,
    login,
    email,
    pinHash,
    role,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.login == this.login &&
          other.email == this.email &&
          other.pinHash == this.pinHash &&
          other.role == this.role &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersTableCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> login;
  final Value<String?> email;
  final Value<String?> pinHash;
  final Value<String> role;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.login = const Value.absent(),
    this.email = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.role = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String name,
    this.login = const Value.absent(),
    this.email = const Value.absent(),
    this.pinHash = const Value.absent(),
    required String role,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? login,
    Expression<String>? email,
    Expression<String>? pinHash,
    Expression<String>? role,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (login != null) 'login': login,
      if (email != null) 'email': email,
      if (pinHash != null) 'pin_hash': pinHash,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? login,
    Value<String?>? email,
    Value<String?>? pinHash,
    Value<String>? role,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      login: login ?? this.login,
      email: email ?? this.email,
      pinHash: pinHash ?? this.pinHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (login.present) {
      map['login'] = Variable<String>(login.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('login: $login, ')
          ..write('email: $email, ')
          ..write('pinHash: $pinHash, ')
          ..write('role: $role, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tenantId, key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String tenantId;
  final String key;
  final String value;
  final DateTime updatedAt;
  const SettingRow({
    required this.tenantId,
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      tenantId: Value(tenantId),
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingRow copyWith({
    String? tenantId,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => SettingRow(
    tenantId: tenantId ?? this.tenantId,
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('tenantId: $tenantId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.tenantId == this.tenantId &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> tenantId;
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.tenantId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String tenantId,
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
    Expression<String>? tenantId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      tenantId: tenantId ?? this.tenantId,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKzMeta = const VerificationMeta('nameKz');
  @override
  late final GeneratedColumn<String> nameKz = GeneratedColumn<String>(
    'name_kz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeGtinMeta = const VerificationMeta(
    'barcodeGtin',
  );
  @override
  late final GeneratedColumn<String> barcodeGtin = GeneratedColumn<String>(
    'barcode_gtin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ntinMeta = const VerificationMeta('ntin');
  @override
  late final GeneratedColumn<String> ntin = GeneratedColumn<String>(
    'ntin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xtinMeta = const VerificationMeta('xtin');
  @override
  late final GeneratedColumn<String> xtin = GeneratedColumn<String>(
    'xtin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xtinExpiresAtMeta = const VerificationMeta(
    'xtinExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> xtinExpiresAt =
      GeneratedColumn<DateTime>(
        'xtin_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryOktruMeta = const VerificationMeta(
    'categoryOktru',
  );
  @override
  late final GeneratedColumn<String> categoryOktru = GeneratedColumn<String>(
    'category_oktru',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseUnitMeta = const VerificationMeta(
    'purchaseUnit',
  );
  @override
  late final GeneratedColumn<String> purchaseUnit = GeneratedColumn<String>(
    'purchase_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasePriceTiyinMeta =
      const VerificationMeta('purchasePriceTiyin');
  @override
  late final GeneratedColumn<int> purchasePriceTiyin = GeneratedColumn<int>(
    'purchase_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleUnitMeta = const VerificationMeta(
    'saleUnit',
  );
  @override
  late final GeneratedColumn<String> saleUnit = GeneratedColumn<String>(
    'sale_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salePriceTiyinMeta = const VerificationMeta(
    'salePriceTiyin',
  );
  @override
  late final GeneratedColumn<int> salePriceTiyin = GeneratedColumn<int>(
    'sale_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWeightedMeta = const VerificationMeta(
    'isWeighted',
  );
  @override
  late final GeneratedColumn<bool> isWeighted = GeneratedColumn<bool>(
    'is_weighted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_weighted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _minWeightGramsMeta = const VerificationMeta(
    'minWeightGrams',
  );
  @override
  late final GeneratedColumn<int> minWeightGrams = GeneratedColumn<int>(
    'min_weight_grams',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightStepGramsMeta = const VerificationMeta(
    'weightStepGrams',
  );
  @override
  late final GeneratedColumn<int> weightStepGrams = GeneratedColumn<int>(
    'weight_step_grams',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<int> vatRate = GeneratedColumn<int>(
    'vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _approvalStatusMeta = const VerificationMeta(
    'approvalStatus',
  );
  @override
  late final GeneratedColumn<String> approvalStatus = GeneratedColumn<String>(
    'approval_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    name,
    nameKz,
    barcodeGtin,
    ntin,
    xtin,
    xtinExpiresAt,
    categoryId,
    categoryOktru,
    purchaseUnit,
    purchasePriceTiyin,
    saleUnit,
    salePriceTiyin,
    isWeighted,
    minWeightGrams,
    weightStepGrams,
    vatRate,
    isActive,
    approvalStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_kz')) {
      context.handle(
        _nameKzMeta,
        nameKz.isAcceptableOrUnknown(data['name_kz']!, _nameKzMeta),
      );
    }
    if (data.containsKey('barcode_gtin')) {
      context.handle(
        _barcodeGtinMeta,
        barcodeGtin.isAcceptableOrUnknown(
          data['barcode_gtin']!,
          _barcodeGtinMeta,
        ),
      );
    }
    if (data.containsKey('ntin')) {
      context.handle(
        _ntinMeta,
        ntin.isAcceptableOrUnknown(data['ntin']!, _ntinMeta),
      );
    }
    if (data.containsKey('xtin')) {
      context.handle(
        _xtinMeta,
        xtin.isAcceptableOrUnknown(data['xtin']!, _xtinMeta),
      );
    }
    if (data.containsKey('xtin_expires_at')) {
      context.handle(
        _xtinExpiresAtMeta,
        xtinExpiresAt.isAcceptableOrUnknown(
          data['xtin_expires_at']!,
          _xtinExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_oktru')) {
      context.handle(
        _categoryOktruMeta,
        categoryOktru.isAcceptableOrUnknown(
          data['category_oktru']!,
          _categoryOktruMeta,
        ),
      );
    }
    if (data.containsKey('purchase_unit')) {
      context.handle(
        _purchaseUnitMeta,
        purchaseUnit.isAcceptableOrUnknown(
          data['purchase_unit']!,
          _purchaseUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseUnitMeta);
    }
    if (data.containsKey('purchase_price_tiyin')) {
      context.handle(
        _purchasePriceTiyinMeta,
        purchasePriceTiyin.isAcceptableOrUnknown(
          data['purchase_price_tiyin']!,
          _purchasePriceTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasePriceTiyinMeta);
    }
    if (data.containsKey('sale_unit')) {
      context.handle(
        _saleUnitMeta,
        saleUnit.isAcceptableOrUnknown(data['sale_unit']!, _saleUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUnitMeta);
    }
    if (data.containsKey('sale_price_tiyin')) {
      context.handle(
        _salePriceTiyinMeta,
        salePriceTiyin.isAcceptableOrUnknown(
          data['sale_price_tiyin']!,
          _salePriceTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salePriceTiyinMeta);
    }
    if (data.containsKey('is_weighted')) {
      context.handle(
        _isWeightedMeta,
        isWeighted.isAcceptableOrUnknown(data['is_weighted']!, _isWeightedMeta),
      );
    }
    if (data.containsKey('min_weight_grams')) {
      context.handle(
        _minWeightGramsMeta,
        minWeightGrams.isAcceptableOrUnknown(
          data['min_weight_grams']!,
          _minWeightGramsMeta,
        ),
      );
    }
    if (data.containsKey('weight_step_grams')) {
      context.handle(
        _weightStepGramsMeta,
        weightStepGrams.isAcceptableOrUnknown(
          data['weight_step_grams']!,
          _weightStepGramsMeta,
        ),
      );
    }
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('approval_status')) {
      context.handle(
        _approvalStatusMeta,
        approvalStatus.isAcceptableOrUnknown(
          data['approval_status']!,
          _approvalStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kz'],
      ),
      barcodeGtin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_gtin'],
      ),
      ntin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ntin'],
      ),
      xtin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}xtin'],
      ),
      xtinExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}xtin_expires_at'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryOktru: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_oktru'],
      ),
      purchaseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_unit'],
      )!,
      purchasePriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_tiyin'],
      )!,
      saleUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_unit'],
      )!,
      salePriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sale_price_tiyin'],
      )!,
      isWeighted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_weighted'],
      )!,
      minWeightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_weight_grams'],
      ),
      weightStepGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight_step_grams'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_rate'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      approvalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String name;
  final String? nameKz;
  final String? barcodeGtin;
  final String? ntin;
  final String? xtin;
  final DateTime? xtinExpiresAt;
  final String? categoryId;
  final String? categoryOktru;
  final String purchaseUnit;
  final int purchasePriceTiyin;
  final String saleUnit;
  final int salePriceTiyin;
  final bool isWeighted;
  final int? minWeightGrams;
  final int weightStepGrams;
  final int vatRate;
  final bool isActive;
  final String approvalStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProductRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.name,
    this.nameKz,
    this.barcodeGtin,
    this.ntin,
    this.xtin,
    this.xtinExpiresAt,
    this.categoryId,
    this.categoryOktru,
    required this.purchaseUnit,
    required this.purchasePriceTiyin,
    required this.saleUnit,
    required this.salePriceTiyin,
    required this.isWeighted,
    this.minWeightGrams,
    required this.weightStepGrams,
    required this.vatRate,
    required this.isActive,
    required this.approvalStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameKz != null) {
      map['name_kz'] = Variable<String>(nameKz);
    }
    if (!nullToAbsent || barcodeGtin != null) {
      map['barcode_gtin'] = Variable<String>(barcodeGtin);
    }
    if (!nullToAbsent || ntin != null) {
      map['ntin'] = Variable<String>(ntin);
    }
    if (!nullToAbsent || xtin != null) {
      map['xtin'] = Variable<String>(xtin);
    }
    if (!nullToAbsent || xtinExpiresAt != null) {
      map['xtin_expires_at'] = Variable<DateTime>(xtinExpiresAt);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || categoryOktru != null) {
      map['category_oktru'] = Variable<String>(categoryOktru);
    }
    map['purchase_unit'] = Variable<String>(purchaseUnit);
    map['purchase_price_tiyin'] = Variable<int>(purchasePriceTiyin);
    map['sale_unit'] = Variable<String>(saleUnit);
    map['sale_price_tiyin'] = Variable<int>(salePriceTiyin);
    map['is_weighted'] = Variable<bool>(isWeighted);
    if (!nullToAbsent || minWeightGrams != null) {
      map['min_weight_grams'] = Variable<int>(minWeightGrams);
    }
    map['weight_step_grams'] = Variable<int>(weightStepGrams);
    map['vat_rate'] = Variable<int>(vatRate);
    map['is_active'] = Variable<bool>(isActive);
    map['approval_status'] = Variable<String>(approvalStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      nameKz: nameKz == null && nullToAbsent
          ? const Value.absent()
          : Value(nameKz),
      barcodeGtin: barcodeGtin == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodeGtin),
      ntin: ntin == null && nullToAbsent ? const Value.absent() : Value(ntin),
      xtin: xtin == null && nullToAbsent ? const Value.absent() : Value(xtin),
      xtinExpiresAt: xtinExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(xtinExpiresAt),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryOktru: categoryOktru == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryOktru),
      purchaseUnit: Value(purchaseUnit),
      purchasePriceTiyin: Value(purchasePriceTiyin),
      saleUnit: Value(saleUnit),
      salePriceTiyin: Value(salePriceTiyin),
      isWeighted: Value(isWeighted),
      minWeightGrams: minWeightGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(minWeightGrams),
      weightStepGrams: Value(weightStepGrams),
      vatRate: Value(vatRate),
      isActive: Value(isActive),
      approvalStatus: Value(approvalStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      nameKz: serializer.fromJson<String?>(json['nameKz']),
      barcodeGtin: serializer.fromJson<String?>(json['barcodeGtin']),
      ntin: serializer.fromJson<String?>(json['ntin']),
      xtin: serializer.fromJson<String?>(json['xtin']),
      xtinExpiresAt: serializer.fromJson<DateTime?>(json['xtinExpiresAt']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryOktru: serializer.fromJson<String?>(json['categoryOktru']),
      purchaseUnit: serializer.fromJson<String>(json['purchaseUnit']),
      purchasePriceTiyin: serializer.fromJson<int>(json['purchasePriceTiyin']),
      saleUnit: serializer.fromJson<String>(json['saleUnit']),
      salePriceTiyin: serializer.fromJson<int>(json['salePriceTiyin']),
      isWeighted: serializer.fromJson<bool>(json['isWeighted']),
      minWeightGrams: serializer.fromJson<int?>(json['minWeightGrams']),
      weightStepGrams: serializer.fromJson<int>(json['weightStepGrams']),
      vatRate: serializer.fromJson<int>(json['vatRate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      approvalStatus: serializer.fromJson<String>(json['approvalStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'nameKz': serializer.toJson<String?>(nameKz),
      'barcodeGtin': serializer.toJson<String?>(barcodeGtin),
      'ntin': serializer.toJson<String?>(ntin),
      'xtin': serializer.toJson<String?>(xtin),
      'xtinExpiresAt': serializer.toJson<DateTime?>(xtinExpiresAt),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryOktru': serializer.toJson<String?>(categoryOktru),
      'purchaseUnit': serializer.toJson<String>(purchaseUnit),
      'purchasePriceTiyin': serializer.toJson<int>(purchasePriceTiyin),
      'saleUnit': serializer.toJson<String>(saleUnit),
      'salePriceTiyin': serializer.toJson<int>(salePriceTiyin),
      'isWeighted': serializer.toJson<bool>(isWeighted),
      'minWeightGrams': serializer.toJson<int?>(minWeightGrams),
      'weightStepGrams': serializer.toJson<int>(weightStepGrams),
      'vatRate': serializer.toJson<int>(vatRate),
      'isActive': serializer.toJson<bool>(isActive),
      'approvalStatus': serializer.toJson<String>(approvalStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> nameKz = const Value.absent(),
    Value<String?> barcodeGtin = const Value.absent(),
    Value<String?> ntin = const Value.absent(),
    Value<String?> xtin = const Value.absent(),
    Value<DateTime?> xtinExpiresAt = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> categoryOktru = const Value.absent(),
    String? purchaseUnit,
    int? purchasePriceTiyin,
    String? saleUnit,
    int? salePriceTiyin,
    bool? isWeighted,
    Value<int?> minWeightGrams = const Value.absent(),
    int? weightStepGrams,
    int? vatRate,
    bool? isActive,
    String? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    nameKz: nameKz.present ? nameKz.value : this.nameKz,
    barcodeGtin: barcodeGtin.present ? barcodeGtin.value : this.barcodeGtin,
    ntin: ntin.present ? ntin.value : this.ntin,
    xtin: xtin.present ? xtin.value : this.xtin,
    xtinExpiresAt: xtinExpiresAt.present
        ? xtinExpiresAt.value
        : this.xtinExpiresAt,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryOktru: categoryOktru.present
        ? categoryOktru.value
        : this.categoryOktru,
    purchaseUnit: purchaseUnit ?? this.purchaseUnit,
    purchasePriceTiyin: purchasePriceTiyin ?? this.purchasePriceTiyin,
    saleUnit: saleUnit ?? this.saleUnit,
    salePriceTiyin: salePriceTiyin ?? this.salePriceTiyin,
    isWeighted: isWeighted ?? this.isWeighted,
    minWeightGrams: minWeightGrams.present
        ? minWeightGrams.value
        : this.minWeightGrams,
    weightStepGrams: weightStepGrams ?? this.weightStepGrams,
    vatRate: vatRate ?? this.vatRate,
    isActive: isActive ?? this.isActive,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductRow copyWithCompanion(ProductsTableCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      nameKz: data.nameKz.present ? data.nameKz.value : this.nameKz,
      barcodeGtin: data.barcodeGtin.present
          ? data.barcodeGtin.value
          : this.barcodeGtin,
      ntin: data.ntin.present ? data.ntin.value : this.ntin,
      xtin: data.xtin.present ? data.xtin.value : this.xtin,
      xtinExpiresAt: data.xtinExpiresAt.present
          ? data.xtinExpiresAt.value
          : this.xtinExpiresAt,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryOktru: data.categoryOktru.present
          ? data.categoryOktru.value
          : this.categoryOktru,
      purchaseUnit: data.purchaseUnit.present
          ? data.purchaseUnit.value
          : this.purchaseUnit,
      purchasePriceTiyin: data.purchasePriceTiyin.present
          ? data.purchasePriceTiyin.value
          : this.purchasePriceTiyin,
      saleUnit: data.saleUnit.present ? data.saleUnit.value : this.saleUnit,
      salePriceTiyin: data.salePriceTiyin.present
          ? data.salePriceTiyin.value
          : this.salePriceTiyin,
      isWeighted: data.isWeighted.present
          ? data.isWeighted.value
          : this.isWeighted,
      minWeightGrams: data.minWeightGrams.present
          ? data.minWeightGrams.value
          : this.minWeightGrams,
      weightStepGrams: data.weightStepGrams.present
          ? data.weightStepGrams.value
          : this.weightStepGrams,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      approvalStatus: data.approvalStatus.present
          ? data.approvalStatus.value
          : this.approvalStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('nameKz: $nameKz, ')
          ..write('barcodeGtin: $barcodeGtin, ')
          ..write('ntin: $ntin, ')
          ..write('xtin: $xtin, ')
          ..write('xtinExpiresAt: $xtinExpiresAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryOktru: $categoryOktru, ')
          ..write('purchaseUnit: $purchaseUnit, ')
          ..write('purchasePriceTiyin: $purchasePriceTiyin, ')
          ..write('saleUnit: $saleUnit, ')
          ..write('salePriceTiyin: $salePriceTiyin, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('minWeightGrams: $minWeightGrams, ')
          ..write('weightStepGrams: $weightStepGrams, ')
          ..write('vatRate: $vatRate, ')
          ..write('isActive: $isActive, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    storeId,
    name,
    nameKz,
    barcodeGtin,
    ntin,
    xtin,
    xtinExpiresAt,
    categoryId,
    categoryOktru,
    purchaseUnit,
    purchasePriceTiyin,
    saleUnit,
    salePriceTiyin,
    isWeighted,
    minWeightGrams,
    weightStepGrams,
    vatRate,
    isActive,
    approvalStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.nameKz == this.nameKz &&
          other.barcodeGtin == this.barcodeGtin &&
          other.ntin == this.ntin &&
          other.xtin == this.xtin &&
          other.xtinExpiresAt == this.xtinExpiresAt &&
          other.categoryId == this.categoryId &&
          other.categoryOktru == this.categoryOktru &&
          other.purchaseUnit == this.purchaseUnit &&
          other.purchasePriceTiyin == this.purchasePriceTiyin &&
          other.saleUnit == this.saleUnit &&
          other.salePriceTiyin == this.salePriceTiyin &&
          other.isWeighted == this.isWeighted &&
          other.minWeightGrams == this.minWeightGrams &&
          other.weightStepGrams == this.weightStepGrams &&
          other.vatRate == this.vatRate &&
          other.isActive == this.isActive &&
          other.approvalStatus == this.approvalStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> nameKz;
  final Value<String?> barcodeGtin;
  final Value<String?> ntin;
  final Value<String?> xtin;
  final Value<DateTime?> xtinExpiresAt;
  final Value<String?> categoryId;
  final Value<String?> categoryOktru;
  final Value<String> purchaseUnit;
  final Value<int> purchasePriceTiyin;
  final Value<String> saleUnit;
  final Value<int> salePriceTiyin;
  final Value<bool> isWeighted;
  final Value<int?> minWeightGrams;
  final Value<int> weightStepGrams;
  final Value<int> vatRate;
  final Value<bool> isActive;
  final Value<String> approvalStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKz = const Value.absent(),
    this.barcodeGtin = const Value.absent(),
    this.ntin = const Value.absent(),
    this.xtin = const Value.absent(),
    this.xtinExpiresAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryOktru = const Value.absent(),
    this.purchaseUnit = const Value.absent(),
    this.purchasePriceTiyin = const Value.absent(),
    this.saleUnit = const Value.absent(),
    this.salePriceTiyin = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.minWeightGrams = const Value.absent(),
    this.weightStepGrams = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.approvalStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String name,
    this.nameKz = const Value.absent(),
    this.barcodeGtin = const Value.absent(),
    this.ntin = const Value.absent(),
    this.xtin = const Value.absent(),
    this.xtinExpiresAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryOktru = const Value.absent(),
    required String purchaseUnit,
    required int purchasePriceTiyin,
    required String saleUnit,
    required int salePriceTiyin,
    this.isWeighted = const Value.absent(),
    this.minWeightGrams = const Value.absent(),
    this.weightStepGrams = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.approvalStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       purchaseUnit = Value(purchaseUnit),
       purchasePriceTiyin = Value(purchasePriceTiyin),
       saleUnit = Value(saleUnit),
       salePriceTiyin = Value(salePriceTiyin),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? nameKz,
    Expression<String>? barcodeGtin,
    Expression<String>? ntin,
    Expression<String>? xtin,
    Expression<DateTime>? xtinExpiresAt,
    Expression<String>? categoryId,
    Expression<String>? categoryOktru,
    Expression<String>? purchaseUnit,
    Expression<int>? purchasePriceTiyin,
    Expression<String>? saleUnit,
    Expression<int>? salePriceTiyin,
    Expression<bool>? isWeighted,
    Expression<int>? minWeightGrams,
    Expression<int>? weightStepGrams,
    Expression<int>? vatRate,
    Expression<bool>? isActive,
    Expression<String>? approvalStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (nameKz != null) 'name_kz': nameKz,
      if (barcodeGtin != null) 'barcode_gtin': barcodeGtin,
      if (ntin != null) 'ntin': ntin,
      if (xtin != null) 'xtin': xtin,
      if (xtinExpiresAt != null) 'xtin_expires_at': xtinExpiresAt,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryOktru != null) 'category_oktru': categoryOktru,
      if (purchaseUnit != null) 'purchase_unit': purchaseUnit,
      if (purchasePriceTiyin != null)
        'purchase_price_tiyin': purchasePriceTiyin,
      if (saleUnit != null) 'sale_unit': saleUnit,
      if (salePriceTiyin != null) 'sale_price_tiyin': salePriceTiyin,
      if (isWeighted != null) 'is_weighted': isWeighted,
      if (minWeightGrams != null) 'min_weight_grams': minWeightGrams,
      if (weightStepGrams != null) 'weight_step_grams': weightStepGrams,
      if (vatRate != null) 'vat_rate': vatRate,
      if (isActive != null) 'is_active': isActive,
      if (approvalStatus != null) 'approval_status': approvalStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? nameKz,
    Value<String?>? barcodeGtin,
    Value<String?>? ntin,
    Value<String?>? xtin,
    Value<DateTime?>? xtinExpiresAt,
    Value<String?>? categoryId,
    Value<String?>? categoryOktru,
    Value<String>? purchaseUnit,
    Value<int>? purchasePriceTiyin,
    Value<String>? saleUnit,
    Value<int>? salePriceTiyin,
    Value<bool>? isWeighted,
    Value<int?>? minWeightGrams,
    Value<int>? weightStepGrams,
    Value<int>? vatRate,
    Value<bool>? isActive,
    Value<String>? approvalStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      nameKz: nameKz ?? this.nameKz,
      barcodeGtin: barcodeGtin ?? this.barcodeGtin,
      ntin: ntin ?? this.ntin,
      xtin: xtin ?? this.xtin,
      xtinExpiresAt: xtinExpiresAt ?? this.xtinExpiresAt,
      categoryId: categoryId ?? this.categoryId,
      categoryOktru: categoryOktru ?? this.categoryOktru,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      purchasePriceTiyin: purchasePriceTiyin ?? this.purchasePriceTiyin,
      saleUnit: saleUnit ?? this.saleUnit,
      salePriceTiyin: salePriceTiyin ?? this.salePriceTiyin,
      isWeighted: isWeighted ?? this.isWeighted,
      minWeightGrams: minWeightGrams ?? this.minWeightGrams,
      weightStepGrams: weightStepGrams ?? this.weightStepGrams,
      vatRate: vatRate ?? this.vatRate,
      isActive: isActive ?? this.isActive,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKz.present) {
      map['name_kz'] = Variable<String>(nameKz.value);
    }
    if (barcodeGtin.present) {
      map['barcode_gtin'] = Variable<String>(barcodeGtin.value);
    }
    if (ntin.present) {
      map['ntin'] = Variable<String>(ntin.value);
    }
    if (xtin.present) {
      map['xtin'] = Variable<String>(xtin.value);
    }
    if (xtinExpiresAt.present) {
      map['xtin_expires_at'] = Variable<DateTime>(xtinExpiresAt.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryOktru.present) {
      map['category_oktru'] = Variable<String>(categoryOktru.value);
    }
    if (purchaseUnit.present) {
      map['purchase_unit'] = Variable<String>(purchaseUnit.value);
    }
    if (purchasePriceTiyin.present) {
      map['purchase_price_tiyin'] = Variable<int>(purchasePriceTiyin.value);
    }
    if (saleUnit.present) {
      map['sale_unit'] = Variable<String>(saleUnit.value);
    }
    if (salePriceTiyin.present) {
      map['sale_price_tiyin'] = Variable<int>(salePriceTiyin.value);
    }
    if (isWeighted.present) {
      map['is_weighted'] = Variable<bool>(isWeighted.value);
    }
    if (minWeightGrams.present) {
      map['min_weight_grams'] = Variable<int>(minWeightGrams.value);
    }
    if (weightStepGrams.present) {
      map['weight_step_grams'] = Variable<int>(weightStepGrams.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<int>(vatRate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (approvalStatus.present) {
      map['approval_status'] = Variable<String>(approvalStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('nameKz: $nameKz, ')
          ..write('barcodeGtin: $barcodeGtin, ')
          ..write('ntin: $ntin, ')
          ..write('xtin: $xtin, ')
          ..write('xtinExpiresAt: $xtinExpiresAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryOktru: $categoryOktru, ')
          ..write('purchaseUnit: $purchaseUnit, ')
          ..write('purchasePriceTiyin: $purchasePriceTiyin, ')
          ..write('saleUnit: $saleUnit, ')
          ..write('salePriceTiyin: $salePriceTiyin, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('minWeightGrams: $minWeightGrams, ')
          ..write('weightStepGrams: $weightStepGrams, ')
          ..write('vatRate: $vatRate, ')
          ..write('isActive: $isActive, ')
          ..write('approvalStatus: $approvalStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKzMeta = const VerificationMeta('nameKz');
  @override
  late final GeneratedColumn<String> nameKz = GeneratedColumn<String>(
    'name_kz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oktruCodeMeta = const VerificationMeta(
    'oktruCode',
  );
  @override
  late final GeneratedColumn<String> oktruCode = GeneratedColumn<String>(
    'oktru_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    name,
    nameKz,
    parentId,
    oktruCode,
    sortOrder,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_kz')) {
      context.handle(
        _nameKzMeta,
        nameKz.isAcceptableOrUnknown(data['name_kz']!, _nameKzMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('oktru_code')) {
      context.handle(
        _oktruCodeMeta,
        oktruCode.isAcceptableOrUnknown(data['oktru_code']!, _oktruCodeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_kz'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      oktruCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oktru_code'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String name;
  final String? nameKz;
  final String? parentId;
  final String? oktruCode;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.name,
    this.nameKz,
    this.parentId,
    this.oktruCode,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameKz != null) {
      map['name_kz'] = Variable<String>(nameKz);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || oktruCode != null) {
      map['oktru_code'] = Variable<String>(oktruCode);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      nameKz: nameKz == null && nullToAbsent
          ? const Value.absent()
          : Value(nameKz),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      oktruCode: oktruCode == null && nullToAbsent
          ? const Value.absent()
          : Value(oktruCode),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      nameKz: serializer.fromJson<String?>(json['nameKz']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      oktruCode: serializer.fromJson<String?>(json['oktruCode']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'nameKz': serializer.toJson<String?>(nameKz),
      'parentId': serializer.toJson<String?>(parentId),
      'oktruCode': serializer.toJson<String?>(oktruCode),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> nameKz = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    Value<String?> oktruCode = const Value.absent(),
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    nameKz: nameKz.present ? nameKz.value : this.nameKz,
    parentId: parentId.present ? parentId.value : this.parentId,
    oktruCode: oktruCode.present ? oktruCode.value : this.oktruCode,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(CategoriesTableCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      nameKz: data.nameKz.present ? data.nameKz.value : this.nameKz,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      oktruCode: data.oktruCode.present ? data.oktruCode.value : this.oktruCode,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('nameKz: $nameKz, ')
          ..write('parentId: $parentId, ')
          ..write('oktruCode: $oktruCode, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    storeId,
    name,
    nameKz,
    parentId,
    oktruCode,
    sortOrder,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.nameKz == this.nameKz &&
          other.parentId == this.parentId &&
          other.oktruCode == this.oktruCode &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> nameKz;
  final Value<String?> parentId;
  final Value<String?> oktruCode;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKz = const Value.absent(),
    this.parentId = const Value.absent(),
    this.oktruCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String name,
    this.nameKz = const Value.absent(),
    this.parentId = const Value.absent(),
    this.oktruCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? nameKz,
    Expression<String>? parentId,
    Expression<String>? oktruCode,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (nameKz != null) 'name_kz': nameKz,
      if (parentId != null) 'parent_id': parentId,
      if (oktruCode != null) 'oktru_code': oktruCode,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? nameKz,
    Value<String?>? parentId,
    Value<String?>? oktruCode,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      nameKz: nameKz ?? this.nameKz,
      parentId: parentId ?? this.parentId,
      oktruCode: oktruCode ?? this.oktruCode,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKz.present) {
      map['name_kz'] = Variable<String>(nameKz.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (oktruCode.present) {
      map['oktru_code'] = Variable<String>(oktruCode.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('nameKz: $nameKz, ')
          ..write('parentId: $parentId, ')
          ..write('oktruCode: $oktruCode, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTableTable extends SuppliersTable
    with TableInfo<$SuppliersTableTable, SupplierRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _binMeta = const VerificationMeta('bin');
  @override
  late final GeneratedColumn<String> bin = GeneratedColumn<String>(
    'bin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    name,
    phone,
    bin,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplierRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('bin')) {
      context.handle(
        _binMeta,
        bin.isAcceptableOrUnknown(data['bin']!, _binMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SupplierRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplierRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      bin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bin'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SuppliersTableTable createAlias(String alias) {
    return $SuppliersTableTable(attachedDatabase, alias);
  }
}

class SupplierRow extends DataClass implements Insertable<SupplierRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String name;
  final String? phone;
  final String? bin;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SupplierRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.name,
    this.phone,
    this.bin,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || bin != null) {
      map['bin'] = Variable<String>(bin);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SuppliersTableCompanion toCompanion(bool nullToAbsent) {
    return SuppliersTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      bin: bin == null && nullToAbsent ? const Value.absent() : Value(bin),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SupplierRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplierRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      bin: serializer.fromJson<String?>(json['bin']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'bin': serializer.toJson<String?>(bin),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SupplierRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> bin = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SupplierRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    bin: bin.present ? bin.value : this.bin,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SupplierRow copyWithCompanion(SuppliersTableCompanion data) {
    return SupplierRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      bin: data.bin.present ? data.bin.value : this.bin,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplierRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('bin: $bin, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    storeId,
    name,
    phone,
    bin,
    notes,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.bin == this.bin &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SuppliersTableCompanion extends UpdateCompanion<SupplierRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> bin;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SuppliersTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.bin = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuppliersTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.bin = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SupplierRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? bin,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (bin != null) 'bin': bin,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuppliersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? bin,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SuppliersTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bin: bin ?? this.bin,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (bin.present) {
      map['bin'] = Variable<String>(bin.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('bin: $bin, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClientsTableTable extends ClientsTable
    with TableInfo<$ClientsTableTable, ClientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iinMeta = const VerificationMeta('iin');
  @override
  late final GeneratedColumn<String> iin = GeneratedColumn<String>(
    'iin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debtLimitTiyinMeta = const VerificationMeta(
    'debtLimitTiyin',
  );
  @override
  late final GeneratedColumn<int> debtLimitTiyin = GeneratedColumn<int>(
    'debt_limit_tiyin',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    name,
    phone,
    iin,
    notes,
    debtLimitTiyin,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('iin')) {
      context.handle(
        _iinMeta,
        iin.isAcceptableOrUnknown(data['iin']!, _iinMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('debt_limit_tiyin')) {
      context.handle(
        _debtLimitTiyinMeta,
        debtLimitTiyin.isAcceptableOrUnknown(
          data['debt_limit_tiyin']!,
          _debtLimitTiyinMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      iin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iin'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      debtLimitTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debt_limit_tiyin'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClientsTableTable createAlias(String alias) {
    return $ClientsTableTable(attachedDatabase, alias);
  }
}

class ClientRow extends DataClass implements Insertable<ClientRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String name;
  final String? phone;
  final String? iin;
  final String? notes;
  final int? debtLimitTiyin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ClientRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.name,
    this.phone,
    this.iin,
    this.notes,
    this.debtLimitTiyin,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || iin != null) {
      map['iin'] = Variable<String>(iin);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || debtLimitTiyin != null) {
      map['debt_limit_tiyin'] = Variable<int>(debtLimitTiyin);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClientsTableCompanion toCompanion(bool nullToAbsent) {
    return ClientsTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      iin: iin == null && nullToAbsent ? const Value.absent() : Value(iin),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      debtLimitTiyin: debtLimitTiyin == null && nullToAbsent
          ? const Value.absent()
          : Value(debtLimitTiyin),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClientRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      iin: serializer.fromJson<String?>(json['iin']),
      notes: serializer.fromJson<String?>(json['notes']),
      debtLimitTiyin: serializer.fromJson<int?>(json['debtLimitTiyin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'iin': serializer.toJson<String?>(iin),
      'notes': serializer.toJson<String?>(notes),
      'debtLimitTiyin': serializer.toJson<int?>(debtLimitTiyin),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ClientRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> iin = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> debtLimitTiyin = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ClientRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    iin: iin.present ? iin.value : this.iin,
    notes: notes.present ? notes.value : this.notes,
    debtLimitTiyin: debtLimitTiyin.present
        ? debtLimitTiyin.value
        : this.debtLimitTiyin,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClientRow copyWithCompanion(ClientsTableCompanion data) {
    return ClientRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      iin: data.iin.present ? data.iin.value : this.iin,
      notes: data.notes.present ? data.notes.value : this.notes,
      debtLimitTiyin: data.debtLimitTiyin.present
          ? data.debtLimitTiyin.value
          : this.debtLimitTiyin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('iin: $iin, ')
          ..write('notes: $notes, ')
          ..write('debtLimitTiyin: $debtLimitTiyin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    storeId,
    name,
    phone,
    iin,
    notes,
    debtLimitTiyin,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.iin == this.iin &&
          other.notes == this.notes &&
          other.debtLimitTiyin == this.debtLimitTiyin &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClientsTableCompanion extends UpdateCompanion<ClientRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> iin;
  final Value<String?> notes;
  final Value<int?> debtLimitTiyin;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.iin = const Value.absent(),
    this.notes = const Value.absent(),
    this.debtLimitTiyin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.iin = const Value.absent(),
    this.notes = const Value.absent(),
    this.debtLimitTiyin = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClientRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? iin,
    Expression<String>? notes,
    Expression<int>? debtLimitTiyin,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (iin != null) 'iin': iin,
      if (notes != null) 'notes': notes,
      if (debtLimitTiyin != null) 'debt_limit_tiyin': debtLimitTiyin,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? iin,
    Value<String?>? notes,
    Value<int?>? debtLimitTiyin,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      iin: iin ?? this.iin,
      notes: notes ?? this.notes,
      debtLimitTiyin: debtLimitTiyin ?? this.debtLimitTiyin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (iin.present) {
      map['iin'] = Variable<String>(iin.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (debtLimitTiyin.present) {
      map['debt_limit_tiyin'] = Variable<int>(debtLimitTiyin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('iin: $iin, ')
          ..write('notes: $notes, ')
          ..write('debtLimitTiyin: $debtLimitTiyin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTableTable extends StockMovementsTable
    with TableInfo<$StockMovementsTableTable, StockMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierUserIdMeta = const VerificationMeta(
    'cashierUserId',
  );
  @override
  late final GeneratedColumn<String> cashierUserId = GeneratedColumn<String>(
    'cashier_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideByUserIdMeta = const VerificationMeta(
    'overrideByUserId',
  );
  @override
  late final GeneratedColumn<String> overrideByUserId = GeneratedColumn<String>(
    'override_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    tenantId,
    storeId,
    productId,
    delta,
    reason,
    deviceId,
    cashierUserId,
    overrideByUserId,
    receiptId,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('cashier_user_id')) {
      context.handle(
        _cashierUserIdMeta,
        cashierUserId.isAcceptableOrUnknown(
          data['cashier_user_id']!,
          _cashierUserIdMeta,
        ),
      );
    }
    if (data.containsKey('override_by_user_id')) {
      context.handle(
        _overrideByUserIdMeta,
        overrideByUserId.isAcceptableOrUnknown(
          data['override_by_user_id']!,
          _overrideByUserIdMeta,
        ),
      );
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      cashierUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_user_id'],
      ),
      overrideByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_by_user_id'],
      ),
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $StockMovementsTableTable createAlias(String alias) {
    return $StockMovementsTableTable(attachedDatabase, alias);
  }
}

class StockMovementRow extends DataClass
    implements Insertable<StockMovementRow> {
  /// Local auto-increment surrogate. Central re-keys on push via `client_uuid`;
  /// the register never serialises this id, so drift's default int PK is fine.
  final int id;

  /// Stable UUID generated on this register. Sent to central for dedup.
  /// Unique locally too so a replayed client ops can't double-insert.
  final String clientUuid;
  final String tenantId;
  final String? storeId;
  final String productId;

  /// Signed, in the product's native unit (grams for weighted, pieces for piece).
  final int delta;

  /// One of sale | return | delivery | adjustment | writeoff | recount.
  final String reason;
  final String deviceId;
  final String? cashierUserId;
  final String? overrideByUserId;

  /// FK to `receipts.id` when reason = sale or return. Nullable for
  /// delivery / adjustment / writeoff.
  final String? receiptId;
  final DateTime createdAt;
  final DateTime? syncedAt;
  const StockMovementRow({
    required this.id,
    required this.clientUuid,
    required this.tenantId,
    this.storeId,
    required this.productId,
    required this.delta,
    required this.reason,
    required this.deviceId,
    this.cashierUserId,
    this.overrideByUserId,
    this.receiptId,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['product_id'] = Variable<String>(productId);
    map['delta'] = Variable<int>(delta);
    map['reason'] = Variable<String>(reason);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || cashierUserId != null) {
      map['cashier_user_id'] = Variable<String>(cashierUserId);
    }
    if (!nullToAbsent || overrideByUserId != null) {
      map['override_by_user_id'] = Variable<String>(overrideByUserId);
    }
    if (!nullToAbsent || receiptId != null) {
      map['receipt_id'] = Variable<String>(receiptId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  StockMovementsTableCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsTableCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      productId: Value(productId),
      delta: Value(delta),
      reason: Value(reason),
      deviceId: Value(deviceId),
      cashierUserId: cashierUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierUserId),
      overrideByUserId: overrideByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideByUserId),
      receiptId: receiptId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptId),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory StockMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovementRow(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      productId: serializer.fromJson<String>(json['productId']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      cashierUserId: serializer.fromJson<String?>(json['cashierUserId']),
      overrideByUserId: serializer.fromJson<String?>(json['overrideByUserId']),
      receiptId: serializer.fromJson<String?>(json['receiptId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'productId': serializer.toJson<String>(productId),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(reason),
      'deviceId': serializer.toJson<String>(deviceId),
      'cashierUserId': serializer.toJson<String?>(cashierUserId),
      'overrideByUserId': serializer.toJson<String?>(overrideByUserId),
      'receiptId': serializer.toJson<String?>(receiptId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  StockMovementRow copyWith({
    int? id,
    String? clientUuid,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? productId,
    int? delta,
    String? reason,
    String? deviceId,
    Value<String?> cashierUserId = const Value.absent(),
    Value<String?> overrideByUserId = const Value.absent(),
    Value<String?> receiptId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => StockMovementRow(
    id: id ?? this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    productId: productId ?? this.productId,
    delta: delta ?? this.delta,
    reason: reason ?? this.reason,
    deviceId: deviceId ?? this.deviceId,
    cashierUserId: cashierUserId.present
        ? cashierUserId.value
        : this.cashierUserId,
    overrideByUserId: overrideByUserId.present
        ? overrideByUserId.value
        : this.overrideByUserId,
    receiptId: receiptId.present ? receiptId.value : this.receiptId,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  StockMovementRow copyWithCompanion(StockMovementsTableCompanion data) {
    return StockMovementRow(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      cashierUserId: data.cashierUserId.present
          ? data.cashierUserId.value
          : this.cashierUserId,
      overrideByUserId: data.overrideByUserId.present
          ? data.overrideByUserId.value
          : this.overrideByUserId,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementRow(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('deviceId: $deviceId, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('overrideByUserId: $overrideByUserId, ')
          ..write('receiptId: $receiptId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    tenantId,
    storeId,
    productId,
    delta,
    reason,
    deviceId,
    cashierUserId,
    overrideByUserId,
    receiptId,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovementRow &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.productId == this.productId &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.deviceId == this.deviceId &&
          other.cashierUserId == this.cashierUserId &&
          other.overrideByUserId == this.overrideByUserId &&
          other.receiptId == this.receiptId &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class StockMovementsTableCompanion extends UpdateCompanion<StockMovementRow> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> productId;
  final Value<int> delta;
  final Value<String> reason;
  final Value<String> deviceId;
  final Value<String?> cashierUserId;
  final Value<String?> overrideByUserId;
  final Value<String?> receiptId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  const StockMovementsTableCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.cashierUserId = const Value.absent(),
    this.overrideByUserId = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  StockMovementsTableCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String productId,
    required int delta,
    required String reason,
    required String deviceId,
    this.cashierUserId = const Value.absent(),
    this.overrideByUserId = const Value.absent(),
    this.receiptId = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       tenantId = Value(tenantId),
       productId = Value(productId),
       delta = Value(delta),
       reason = Value(reason),
       deviceId = Value(deviceId),
       createdAt = Value(createdAt);
  static Insertable<StockMovementRow> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? productId,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<String>? deviceId,
    Expression<String>? cashierUserId,
    Expression<String>? overrideByUserId,
    Expression<String>? receiptId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (productId != null) 'product_id': productId,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (deviceId != null) 'device_id': deviceId,
      if (cashierUserId != null) 'cashier_user_id': cashierUserId,
      if (overrideByUserId != null) 'override_by_user_id': overrideByUserId,
      if (receiptId != null) 'receipt_id': receiptId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  StockMovementsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? clientUuid,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? productId,
    Value<int>? delta,
    Value<String>? reason,
    Value<String>? deviceId,
    Value<String?>? cashierUserId,
    Value<String?>? overrideByUserId,
    Value<String?>? receiptId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
  }) {
    return StockMovementsTableCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      deviceId: deviceId ?? this.deviceId,
      cashierUserId: cashierUserId ?? this.cashierUserId,
      overrideByUserId: overrideByUserId ?? this.overrideByUserId,
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (cashierUserId.present) {
      map['cashier_user_id'] = Variable<String>(cashierUserId.value);
    }
    if (overrideByUserId.present) {
      map['override_by_user_id'] = Variable<String>(overrideByUserId.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsTableCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('deviceId: $deviceId, ')
          ..write('cashierUserId: $cashierUserId, ')
          ..write('overrideByUserId: $overrideByUserId, ')
          ..write('receiptId: $receiptId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTableTable extends ReceiptsTable
    with TableInfo<$ReceiptsTableTable, ReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workstationIdMeta = const VerificationMeta(
    'workstationId',
  );
  @override
  late final GeneratedColumn<String> workstationId = GeneratedColumn<String>(
    'workstation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<int> receiptNumber = GeneratedColumn<int>(
    'receipt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountTiyinMeta = const VerificationMeta(
    'totalAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> totalAmountTiyin = GeneratedColumn<int>(
    'total_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatAmountTiyinMeta = const VerificationMeta(
    'vatAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> vatAmountTiyin = GeneratedColumn<int>(
    'vat_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountTiyinMeta =
      const VerificationMeta('discountAmountTiyin');
  @override
  late final GeneratedColumn<int> discountAmountTiyin = GeneratedColumn<int>(
    'discount_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _changeAmountTiyinMeta = const VerificationMeta(
    'changeAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> changeAmountTiyin = GeneratedColumn<int>(
    'change_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashAmountTiyinMeta = const VerificationMeta(
    'cashAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> cashAmountTiyin = GeneratedColumn<int>(
    'cash_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cardAmountTiyinMeta = const VerificationMeta(
    'cardAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> cardAmountTiyin = GeneratedColumn<int>(
    'card_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qrAmountTiyinMeta = const VerificationMeta(
    'qrAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> qrAmountTiyin = GeneratedColumn<int>(
    'qr_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _debtAmountTiyinMeta = const VerificationMeta(
    'debtAmountTiyin',
  );
  @override
  late final GeneratedColumn<int> debtAmountTiyin = GeneratedColumn<int>(
    'debt_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isReturnMeta = const VerificationMeta(
    'isReturn',
  );
  @override
  late final GeneratedColumn<bool> isReturn = GeneratedColumn<bool>(
    'is_return',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_return" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _refundForReceiptIdMeta =
      const VerificationMeta('refundForReceiptId');
  @override
  late final GeneratedColumn<String> refundForReceiptId =
      GeneratedColumn<String>(
        'refund_for_receipt_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalIdMeta = const VerificationMeta(
    'fiscalId',
  );
  @override
  late final GeneratedColumn<String> fiscalId = GeneratedColumn<String>(
    'fiscal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalStatusMeta = const VerificationMeta(
    'fiscalStatus',
  );
  @override
  late final GeneratedColumn<String> fiscalStatus = GeneratedColumn<String>(
    'fiscal_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    workstationId,
    shiftId,
    userId,
    receiptNumber,
    totalAmountTiyin,
    vatAmountTiyin,
    discountAmountTiyin,
    changeAmountTiyin,
    cashAmountTiyin,
    cardAmountTiyin,
    qrAmountTiyin,
    debtAmountTiyin,
    isReturn,
    refundForReceiptId,
    clientId,
    debtId,
    fiscalId,
    fiscalStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('workstation_id')) {
      context.handle(
        _workstationIdMeta,
        workstationId.isAcceptableOrUnknown(
          data['workstation_id']!,
          _workstationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workstationIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
        _receiptNumberMeta,
        receiptNumber.isAcceptableOrUnknown(
          data['receipt_number']!,
          _receiptNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('total_amount_tiyin')) {
      context.handle(
        _totalAmountTiyinMeta,
        totalAmountTiyin.isAcceptableOrUnknown(
          data['total_amount_tiyin']!,
          _totalAmountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountTiyinMeta);
    }
    if (data.containsKey('vat_amount_tiyin')) {
      context.handle(
        _vatAmountTiyinMeta,
        vatAmountTiyin.isAcceptableOrUnknown(
          data['vat_amount_tiyin']!,
          _vatAmountTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vatAmountTiyinMeta);
    }
    if (data.containsKey('discount_amount_tiyin')) {
      context.handle(
        _discountAmountTiyinMeta,
        discountAmountTiyin.isAcceptableOrUnknown(
          data['discount_amount_tiyin']!,
          _discountAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('change_amount_tiyin')) {
      context.handle(
        _changeAmountTiyinMeta,
        changeAmountTiyin.isAcceptableOrUnknown(
          data['change_amount_tiyin']!,
          _changeAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('cash_amount_tiyin')) {
      context.handle(
        _cashAmountTiyinMeta,
        cashAmountTiyin.isAcceptableOrUnknown(
          data['cash_amount_tiyin']!,
          _cashAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('card_amount_tiyin')) {
      context.handle(
        _cardAmountTiyinMeta,
        cardAmountTiyin.isAcceptableOrUnknown(
          data['card_amount_tiyin']!,
          _cardAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('qr_amount_tiyin')) {
      context.handle(
        _qrAmountTiyinMeta,
        qrAmountTiyin.isAcceptableOrUnknown(
          data['qr_amount_tiyin']!,
          _qrAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('debt_amount_tiyin')) {
      context.handle(
        _debtAmountTiyinMeta,
        debtAmountTiyin.isAcceptableOrUnknown(
          data['debt_amount_tiyin']!,
          _debtAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('is_return')) {
      context.handle(
        _isReturnMeta,
        isReturn.isAcceptableOrUnknown(data['is_return']!, _isReturnMeta),
      );
    }
    if (data.containsKey('refund_for_receipt_id')) {
      context.handle(
        _refundForReceiptIdMeta,
        refundForReceiptId.isAcceptableOrUnknown(
          data['refund_for_receipt_id']!,
          _refundForReceiptIdMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    }
    if (data.containsKey('fiscal_id')) {
      context.handle(
        _fiscalIdMeta,
        fiscalId.isAcceptableOrUnknown(data['fiscal_id']!, _fiscalIdMeta),
      );
    }
    if (data.containsKey('fiscal_status')) {
      context.handle(
        _fiscalStatusMeta,
        fiscalStatus.isAcceptableOrUnknown(
          data['fiscal_status']!,
          _fiscalStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      workstationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workstation_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_number'],
      )!,
      totalAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount_tiyin'],
      )!,
      vatAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_amount_tiyin'],
      )!,
      discountAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_amount_tiyin'],
      )!,
      changeAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_amount_tiyin'],
      )!,
      cashAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_amount_tiyin'],
      )!,
      cardAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_amount_tiyin'],
      )!,
      qrAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qr_amount_tiyin'],
      )!,
      debtAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debt_amount_tiyin'],
      )!,
      isReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_return'],
      )!,
      refundForReceiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_for_receipt_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      ),
      fiscalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_id'],
      ),
      fiscalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReceiptsTableTable createAlias(String alias) {
    return $ReceiptsTableTable(attachedDatabase, alias);
  }
}

class ReceiptRow extends DataClass implements Insertable<ReceiptRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String workstationId;
  final String shiftId;
  final String userId;

  /// Per-shift monotonic — printed on the customer slip. Caller computes (eg.
  /// cashier-side counter); no DB-level sequence here because shifts can be
  /// open offline.
  final int receiptNumber;
  final int totalAmountTiyin;
  final int vatAmountTiyin;
  final int discountAmountTiyin;
  final int changeAmountTiyin;
  final int cashAmountTiyin;
  final int cardAmountTiyin;
  final int qrAmountTiyin;
  final int debtAmountTiyin;
  final bool isReturn;

  /// FK to the original receipt for return/refund flows. Null on regular sales.
  final String? refundForReceiptId;
  final String? clientId;
  final String? debtId;

  /// Set by central once Webkassa fiscalises the receipt. Pending until then.
  final String? fiscalId;
  final String fiscalStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReceiptRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.workstationId,
    required this.shiftId,
    required this.userId,
    required this.receiptNumber,
    required this.totalAmountTiyin,
    required this.vatAmountTiyin,
    required this.discountAmountTiyin,
    required this.changeAmountTiyin,
    required this.cashAmountTiyin,
    required this.cardAmountTiyin,
    required this.qrAmountTiyin,
    required this.debtAmountTiyin,
    required this.isReturn,
    this.refundForReceiptId,
    this.clientId,
    this.debtId,
    this.fiscalId,
    required this.fiscalStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['workstation_id'] = Variable<String>(workstationId);
    map['shift_id'] = Variable<String>(shiftId);
    map['user_id'] = Variable<String>(userId);
    map['receipt_number'] = Variable<int>(receiptNumber);
    map['total_amount_tiyin'] = Variable<int>(totalAmountTiyin);
    map['vat_amount_tiyin'] = Variable<int>(vatAmountTiyin);
    map['discount_amount_tiyin'] = Variable<int>(discountAmountTiyin);
    map['change_amount_tiyin'] = Variable<int>(changeAmountTiyin);
    map['cash_amount_tiyin'] = Variable<int>(cashAmountTiyin);
    map['card_amount_tiyin'] = Variable<int>(cardAmountTiyin);
    map['qr_amount_tiyin'] = Variable<int>(qrAmountTiyin);
    map['debt_amount_tiyin'] = Variable<int>(debtAmountTiyin);
    map['is_return'] = Variable<bool>(isReturn);
    if (!nullToAbsent || refundForReceiptId != null) {
      map['refund_for_receipt_id'] = Variable<String>(refundForReceiptId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || debtId != null) {
      map['debt_id'] = Variable<String>(debtId);
    }
    if (!nullToAbsent || fiscalId != null) {
      map['fiscal_id'] = Variable<String>(fiscalId);
    }
    map['fiscal_status'] = Variable<String>(fiscalStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReceiptsTableCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      workstationId: Value(workstationId),
      shiftId: Value(shiftId),
      userId: Value(userId),
      receiptNumber: Value(receiptNumber),
      totalAmountTiyin: Value(totalAmountTiyin),
      vatAmountTiyin: Value(vatAmountTiyin),
      discountAmountTiyin: Value(discountAmountTiyin),
      changeAmountTiyin: Value(changeAmountTiyin),
      cashAmountTiyin: Value(cashAmountTiyin),
      cardAmountTiyin: Value(cardAmountTiyin),
      qrAmountTiyin: Value(qrAmountTiyin),
      debtAmountTiyin: Value(debtAmountTiyin),
      isReturn: Value(isReturn),
      refundForReceiptId: refundForReceiptId == null && nullToAbsent
          ? const Value.absent()
          : Value(refundForReceiptId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      debtId: debtId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtId),
      fiscalId: fiscalId == null && nullToAbsent
          ? const Value.absent()
          : Value(fiscalId),
      fiscalStatus: Value(fiscalStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      workstationId: serializer.fromJson<String>(json['workstationId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      userId: serializer.fromJson<String>(json['userId']),
      receiptNumber: serializer.fromJson<int>(json['receiptNumber']),
      totalAmountTiyin: serializer.fromJson<int>(json['totalAmountTiyin']),
      vatAmountTiyin: serializer.fromJson<int>(json['vatAmountTiyin']),
      discountAmountTiyin: serializer.fromJson<int>(
        json['discountAmountTiyin'],
      ),
      changeAmountTiyin: serializer.fromJson<int>(json['changeAmountTiyin']),
      cashAmountTiyin: serializer.fromJson<int>(json['cashAmountTiyin']),
      cardAmountTiyin: serializer.fromJson<int>(json['cardAmountTiyin']),
      qrAmountTiyin: serializer.fromJson<int>(json['qrAmountTiyin']),
      debtAmountTiyin: serializer.fromJson<int>(json['debtAmountTiyin']),
      isReturn: serializer.fromJson<bool>(json['isReturn']),
      refundForReceiptId: serializer.fromJson<String?>(
        json['refundForReceiptId'],
      ),
      clientId: serializer.fromJson<String?>(json['clientId']),
      debtId: serializer.fromJson<String?>(json['debtId']),
      fiscalId: serializer.fromJson<String?>(json['fiscalId']),
      fiscalStatus: serializer.fromJson<String>(json['fiscalStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'workstationId': serializer.toJson<String>(workstationId),
      'shiftId': serializer.toJson<String>(shiftId),
      'userId': serializer.toJson<String>(userId),
      'receiptNumber': serializer.toJson<int>(receiptNumber),
      'totalAmountTiyin': serializer.toJson<int>(totalAmountTiyin),
      'vatAmountTiyin': serializer.toJson<int>(vatAmountTiyin),
      'discountAmountTiyin': serializer.toJson<int>(discountAmountTiyin),
      'changeAmountTiyin': serializer.toJson<int>(changeAmountTiyin),
      'cashAmountTiyin': serializer.toJson<int>(cashAmountTiyin),
      'cardAmountTiyin': serializer.toJson<int>(cardAmountTiyin),
      'qrAmountTiyin': serializer.toJson<int>(qrAmountTiyin),
      'debtAmountTiyin': serializer.toJson<int>(debtAmountTiyin),
      'isReturn': serializer.toJson<bool>(isReturn),
      'refundForReceiptId': serializer.toJson<String?>(refundForReceiptId),
      'clientId': serializer.toJson<String?>(clientId),
      'debtId': serializer.toJson<String?>(debtId),
      'fiscalId': serializer.toJson<String?>(fiscalId),
      'fiscalStatus': serializer.toJson<String>(fiscalStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceiptRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? workstationId,
    String? shiftId,
    String? userId,
    int? receiptNumber,
    int? totalAmountTiyin,
    int? vatAmountTiyin,
    int? discountAmountTiyin,
    int? changeAmountTiyin,
    int? cashAmountTiyin,
    int? cardAmountTiyin,
    int? qrAmountTiyin,
    int? debtAmountTiyin,
    bool? isReturn,
    Value<String?> refundForReceiptId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    Value<String?> debtId = const Value.absent(),
    Value<String?> fiscalId = const Value.absent(),
    String? fiscalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReceiptRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    workstationId: workstationId ?? this.workstationId,
    shiftId: shiftId ?? this.shiftId,
    userId: userId ?? this.userId,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    totalAmountTiyin: totalAmountTiyin ?? this.totalAmountTiyin,
    vatAmountTiyin: vatAmountTiyin ?? this.vatAmountTiyin,
    discountAmountTiyin: discountAmountTiyin ?? this.discountAmountTiyin,
    changeAmountTiyin: changeAmountTiyin ?? this.changeAmountTiyin,
    cashAmountTiyin: cashAmountTiyin ?? this.cashAmountTiyin,
    cardAmountTiyin: cardAmountTiyin ?? this.cardAmountTiyin,
    qrAmountTiyin: qrAmountTiyin ?? this.qrAmountTiyin,
    debtAmountTiyin: debtAmountTiyin ?? this.debtAmountTiyin,
    isReturn: isReturn ?? this.isReturn,
    refundForReceiptId: refundForReceiptId.present
        ? refundForReceiptId.value
        : this.refundForReceiptId,
    clientId: clientId.present ? clientId.value : this.clientId,
    debtId: debtId.present ? debtId.value : this.debtId,
    fiscalId: fiscalId.present ? fiscalId.value : this.fiscalId,
    fiscalStatus: fiscalStatus ?? this.fiscalStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReceiptRow copyWithCompanion(ReceiptsTableCompanion data) {
    return ReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      workstationId: data.workstationId.present
          ? data.workstationId.value
          : this.workstationId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      userId: data.userId.present ? data.userId.value : this.userId,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      totalAmountTiyin: data.totalAmountTiyin.present
          ? data.totalAmountTiyin.value
          : this.totalAmountTiyin,
      vatAmountTiyin: data.vatAmountTiyin.present
          ? data.vatAmountTiyin.value
          : this.vatAmountTiyin,
      discountAmountTiyin: data.discountAmountTiyin.present
          ? data.discountAmountTiyin.value
          : this.discountAmountTiyin,
      changeAmountTiyin: data.changeAmountTiyin.present
          ? data.changeAmountTiyin.value
          : this.changeAmountTiyin,
      cashAmountTiyin: data.cashAmountTiyin.present
          ? data.cashAmountTiyin.value
          : this.cashAmountTiyin,
      cardAmountTiyin: data.cardAmountTiyin.present
          ? data.cardAmountTiyin.value
          : this.cardAmountTiyin,
      qrAmountTiyin: data.qrAmountTiyin.present
          ? data.qrAmountTiyin.value
          : this.qrAmountTiyin,
      debtAmountTiyin: data.debtAmountTiyin.present
          ? data.debtAmountTiyin.value
          : this.debtAmountTiyin,
      isReturn: data.isReturn.present ? data.isReturn.value : this.isReturn,
      refundForReceiptId: data.refundForReceiptId.present
          ? data.refundForReceiptId.value
          : this.refundForReceiptId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      fiscalId: data.fiscalId.present ? data.fiscalId.value : this.fiscalId,
      fiscalStatus: data.fiscalStatus.present
          ? data.fiscalStatus.value
          : this.fiscalStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('workstationId: $workstationId, ')
          ..write('shiftId: $shiftId, ')
          ..write('userId: $userId, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('totalAmountTiyin: $totalAmountTiyin, ')
          ..write('vatAmountTiyin: $vatAmountTiyin, ')
          ..write('discountAmountTiyin: $discountAmountTiyin, ')
          ..write('changeAmountTiyin: $changeAmountTiyin, ')
          ..write('cashAmountTiyin: $cashAmountTiyin, ')
          ..write('cardAmountTiyin: $cardAmountTiyin, ')
          ..write('qrAmountTiyin: $qrAmountTiyin, ')
          ..write('debtAmountTiyin: $debtAmountTiyin, ')
          ..write('isReturn: $isReturn, ')
          ..write('refundForReceiptId: $refundForReceiptId, ')
          ..write('clientId: $clientId, ')
          ..write('debtId: $debtId, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('fiscalStatus: $fiscalStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    storeId,
    workstationId,
    shiftId,
    userId,
    receiptNumber,
    totalAmountTiyin,
    vatAmountTiyin,
    discountAmountTiyin,
    changeAmountTiyin,
    cashAmountTiyin,
    cardAmountTiyin,
    qrAmountTiyin,
    debtAmountTiyin,
    isReturn,
    refundForReceiptId,
    clientId,
    debtId,
    fiscalId,
    fiscalStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.workstationId == this.workstationId &&
          other.shiftId == this.shiftId &&
          other.userId == this.userId &&
          other.receiptNumber == this.receiptNumber &&
          other.totalAmountTiyin == this.totalAmountTiyin &&
          other.vatAmountTiyin == this.vatAmountTiyin &&
          other.discountAmountTiyin == this.discountAmountTiyin &&
          other.changeAmountTiyin == this.changeAmountTiyin &&
          other.cashAmountTiyin == this.cashAmountTiyin &&
          other.cardAmountTiyin == this.cardAmountTiyin &&
          other.qrAmountTiyin == this.qrAmountTiyin &&
          other.debtAmountTiyin == this.debtAmountTiyin &&
          other.isReturn == this.isReturn &&
          other.refundForReceiptId == this.refundForReceiptId &&
          other.clientId == this.clientId &&
          other.debtId == this.debtId &&
          other.fiscalId == this.fiscalId &&
          other.fiscalStatus == this.fiscalStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReceiptsTableCompanion extends UpdateCompanion<ReceiptRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> workstationId;
  final Value<String> shiftId;
  final Value<String> userId;
  final Value<int> receiptNumber;
  final Value<int> totalAmountTiyin;
  final Value<int> vatAmountTiyin;
  final Value<int> discountAmountTiyin;
  final Value<int> changeAmountTiyin;
  final Value<int> cashAmountTiyin;
  final Value<int> cardAmountTiyin;
  final Value<int> qrAmountTiyin;
  final Value<int> debtAmountTiyin;
  final Value<bool> isReturn;
  final Value<String?> refundForReceiptId;
  final Value<String?> clientId;
  final Value<String?> debtId;
  final Value<String?> fiscalId;
  final Value<String> fiscalStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReceiptsTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.workstationId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.userId = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.totalAmountTiyin = const Value.absent(),
    this.vatAmountTiyin = const Value.absent(),
    this.discountAmountTiyin = const Value.absent(),
    this.changeAmountTiyin = const Value.absent(),
    this.cashAmountTiyin = const Value.absent(),
    this.cardAmountTiyin = const Value.absent(),
    this.qrAmountTiyin = const Value.absent(),
    this.debtAmountTiyin = const Value.absent(),
    this.isReturn = const Value.absent(),
    this.refundForReceiptId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.debtId = const Value.absent(),
    this.fiscalId = const Value.absent(),
    this.fiscalStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String workstationId,
    required String shiftId,
    required String userId,
    required int receiptNumber,
    required int totalAmountTiyin,
    required int vatAmountTiyin,
    this.discountAmountTiyin = const Value.absent(),
    this.changeAmountTiyin = const Value.absent(),
    this.cashAmountTiyin = const Value.absent(),
    this.cardAmountTiyin = const Value.absent(),
    this.qrAmountTiyin = const Value.absent(),
    this.debtAmountTiyin = const Value.absent(),
    this.isReturn = const Value.absent(),
    this.refundForReceiptId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.debtId = const Value.absent(),
    this.fiscalId = const Value.absent(),
    this.fiscalStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       workstationId = Value(workstationId),
       shiftId = Value(shiftId),
       userId = Value(userId),
       receiptNumber = Value(receiptNumber),
       totalAmountTiyin = Value(totalAmountTiyin),
       vatAmountTiyin = Value(vatAmountTiyin),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReceiptRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? workstationId,
    Expression<String>? shiftId,
    Expression<String>? userId,
    Expression<int>? receiptNumber,
    Expression<int>? totalAmountTiyin,
    Expression<int>? vatAmountTiyin,
    Expression<int>? discountAmountTiyin,
    Expression<int>? changeAmountTiyin,
    Expression<int>? cashAmountTiyin,
    Expression<int>? cardAmountTiyin,
    Expression<int>? qrAmountTiyin,
    Expression<int>? debtAmountTiyin,
    Expression<bool>? isReturn,
    Expression<String>? refundForReceiptId,
    Expression<String>? clientId,
    Expression<String>? debtId,
    Expression<String>? fiscalId,
    Expression<String>? fiscalStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (workstationId != null) 'workstation_id': workstationId,
      if (shiftId != null) 'shift_id': shiftId,
      if (userId != null) 'user_id': userId,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (totalAmountTiyin != null) 'total_amount_tiyin': totalAmountTiyin,
      if (vatAmountTiyin != null) 'vat_amount_tiyin': vatAmountTiyin,
      if (discountAmountTiyin != null)
        'discount_amount_tiyin': discountAmountTiyin,
      if (changeAmountTiyin != null) 'change_amount_tiyin': changeAmountTiyin,
      if (cashAmountTiyin != null) 'cash_amount_tiyin': cashAmountTiyin,
      if (cardAmountTiyin != null) 'card_amount_tiyin': cardAmountTiyin,
      if (qrAmountTiyin != null) 'qr_amount_tiyin': qrAmountTiyin,
      if (debtAmountTiyin != null) 'debt_amount_tiyin': debtAmountTiyin,
      if (isReturn != null) 'is_return': isReturn,
      if (refundForReceiptId != null)
        'refund_for_receipt_id': refundForReceiptId,
      if (clientId != null) 'client_id': clientId,
      if (debtId != null) 'debt_id': debtId,
      if (fiscalId != null) 'fiscal_id': fiscalId,
      if (fiscalStatus != null) 'fiscal_status': fiscalStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? workstationId,
    Value<String>? shiftId,
    Value<String>? userId,
    Value<int>? receiptNumber,
    Value<int>? totalAmountTiyin,
    Value<int>? vatAmountTiyin,
    Value<int>? discountAmountTiyin,
    Value<int>? changeAmountTiyin,
    Value<int>? cashAmountTiyin,
    Value<int>? cardAmountTiyin,
    Value<int>? qrAmountTiyin,
    Value<int>? debtAmountTiyin,
    Value<bool>? isReturn,
    Value<String?>? refundForReceiptId,
    Value<String?>? clientId,
    Value<String?>? debtId,
    Value<String?>? fiscalId,
    Value<String>? fiscalStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReceiptsTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      workstationId: workstationId ?? this.workstationId,
      shiftId: shiftId ?? this.shiftId,
      userId: userId ?? this.userId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      totalAmountTiyin: totalAmountTiyin ?? this.totalAmountTiyin,
      vatAmountTiyin: vatAmountTiyin ?? this.vatAmountTiyin,
      discountAmountTiyin: discountAmountTiyin ?? this.discountAmountTiyin,
      changeAmountTiyin: changeAmountTiyin ?? this.changeAmountTiyin,
      cashAmountTiyin: cashAmountTiyin ?? this.cashAmountTiyin,
      cardAmountTiyin: cardAmountTiyin ?? this.cardAmountTiyin,
      qrAmountTiyin: qrAmountTiyin ?? this.qrAmountTiyin,
      debtAmountTiyin: debtAmountTiyin ?? this.debtAmountTiyin,
      isReturn: isReturn ?? this.isReturn,
      refundForReceiptId: refundForReceiptId ?? this.refundForReceiptId,
      clientId: clientId ?? this.clientId,
      debtId: debtId ?? this.debtId,
      fiscalId: fiscalId ?? this.fiscalId,
      fiscalStatus: fiscalStatus ?? this.fiscalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (workstationId.present) {
      map['workstation_id'] = Variable<String>(workstationId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<int>(receiptNumber.value);
    }
    if (totalAmountTiyin.present) {
      map['total_amount_tiyin'] = Variable<int>(totalAmountTiyin.value);
    }
    if (vatAmountTiyin.present) {
      map['vat_amount_tiyin'] = Variable<int>(vatAmountTiyin.value);
    }
    if (discountAmountTiyin.present) {
      map['discount_amount_tiyin'] = Variable<int>(discountAmountTiyin.value);
    }
    if (changeAmountTiyin.present) {
      map['change_amount_tiyin'] = Variable<int>(changeAmountTiyin.value);
    }
    if (cashAmountTiyin.present) {
      map['cash_amount_tiyin'] = Variable<int>(cashAmountTiyin.value);
    }
    if (cardAmountTiyin.present) {
      map['card_amount_tiyin'] = Variable<int>(cardAmountTiyin.value);
    }
    if (qrAmountTiyin.present) {
      map['qr_amount_tiyin'] = Variable<int>(qrAmountTiyin.value);
    }
    if (debtAmountTiyin.present) {
      map['debt_amount_tiyin'] = Variable<int>(debtAmountTiyin.value);
    }
    if (isReturn.present) {
      map['is_return'] = Variable<bool>(isReturn.value);
    }
    if (refundForReceiptId.present) {
      map['refund_for_receipt_id'] = Variable<String>(refundForReceiptId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (fiscalId.present) {
      map['fiscal_id'] = Variable<String>(fiscalId.value);
    }
    if (fiscalStatus.present) {
      map['fiscal_status'] = Variable<String>(fiscalStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('workstationId: $workstationId, ')
          ..write('shiftId: $shiftId, ')
          ..write('userId: $userId, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('totalAmountTiyin: $totalAmountTiyin, ')
          ..write('vatAmountTiyin: $vatAmountTiyin, ')
          ..write('discountAmountTiyin: $discountAmountTiyin, ')
          ..write('changeAmountTiyin: $changeAmountTiyin, ')
          ..write('cashAmountTiyin: $cashAmountTiyin, ')
          ..write('cardAmountTiyin: $cardAmountTiyin, ')
          ..write('qrAmountTiyin: $qrAmountTiyin, ')
          ..write('debtAmountTiyin: $debtAmountTiyin, ')
          ..write('isReturn: $isReturn, ')
          ..write('refundForReceiptId: $refundForReceiptId, ')
          ..write('clientId: $clientId, ')
          ..write('debtId: $debtId, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('fiscalStatus: $fiscalStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptItemsTableTable extends ReceiptItemsTable
    with TableInfo<$ReceiptItemsTableTable, ReceiptItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productBarcodeMeta = const VerificationMeta(
    'productBarcode',
  );
  @override
  late final GeneratedColumn<String> productBarcode = GeneratedColumn<String>(
    'product_barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightGramsMeta = const VerificationMeta(
    'weightGrams',
  );
  @override
  late final GeneratedColumn<int> weightGrams = GeneratedColumn<int>(
    'weight_grams',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceTiyinMeta = const VerificationMeta(
    'unitPriceTiyin',
  );
  @override
  late final GeneratedColumn<int> unitPriceTiyin = GeneratedColumn<int>(
    'unit_price_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTotalTiyinMeta = const VerificationMeta(
    'itemTotalTiyin',
  );
  @override
  late final GeneratedColumn<int> itemTotalTiyin = GeneratedColumn<int>(
    'item_total_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountTiyinMeta =
      const VerificationMeta('discountAmountTiyin');
  @override
  late final GeneratedColumn<int> discountAmountTiyin = GeneratedColumn<int>(
    'discount_amount_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<int> vatRate = GeneratedColumn<int>(
    'vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    receiptId,
    productId,
    productName,
    productBarcode,
    quantity,
    weightGrams,
    unitPriceTiyin,
    itemTotalTiyin,
    discountAmountTiyin,
    vatRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_barcode')) {
      context.handle(
        _productBarcodeMeta,
        productBarcode.isAcceptableOrUnknown(
          data['product_barcode']!,
          _productBarcodeMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('weight_grams')) {
      context.handle(
        _weightGramsMeta,
        weightGrams.isAcceptableOrUnknown(
          data['weight_grams']!,
          _weightGramsMeta,
        ),
      );
    }
    if (data.containsKey('unit_price_tiyin')) {
      context.handle(
        _unitPriceTiyinMeta,
        unitPriceTiyin.isAcceptableOrUnknown(
          data['unit_price_tiyin']!,
          _unitPriceTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceTiyinMeta);
    }
    if (data.containsKey('item_total_tiyin')) {
      context.handle(
        _itemTotalTiyinMeta,
        itemTotalTiyin.isAcceptableOrUnknown(
          data['item_total_tiyin']!,
          _itemTotalTiyinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemTotalTiyinMeta);
    }
    if (data.containsKey('discount_amount_tiyin')) {
      context.handle(
        _discountAmountTiyinMeta,
        discountAmountTiyin.isAcceptableOrUnknown(
          data['discount_amount_tiyin']!,
          _discountAmountTiyinMeta,
        ),
      );
    }
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      productBarcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_barcode'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      weightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight_grams'],
      ),
      unitPriceTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_tiyin'],
      )!,
      itemTotalTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_total_tiyin'],
      )!,
      discountAmountTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_amount_tiyin'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vat_rate'],
      )!,
    );
  }

  @override
  $ReceiptItemsTableTable createAlias(String alias) {
    return $ReceiptItemsTableTable(attachedDatabase, alias);
  }
}

class ReceiptItemRow extends DataClass implements Insertable<ReceiptItemRow> {
  final String id;
  final String tenantId;
  final String receiptId;
  final String productId;

  /// Snapshot taken at sale time so the line displays correctly even if the
  /// product is later renamed/deleted. Kazakh law also requires the printed
  /// name on the receipt to match what the cashier rang up.
  final String productName;
  final String? productBarcode;

  /// For piece goods: count. For weighted: 0 (use [weightGrams]).
  final int quantity;
  final int? weightGrams;

  /// Unit price in tiyin. For weighted, this is price-per-kg (so the line
  /// total = round(weight_grams / 1000 * unit_price_tiyin)).
  final int unitPriceTiyin;

  /// Computed line total after weighted math + discount. Stored (not derived)
  /// so reports replay deterministically even if the calculator is later
  /// adjusted — Kazakhstan tax inspector replays receipts year-on-year.
  final int itemTotalTiyin;
  final int discountAmountTiyin;
  final int vatRate;
  const ReceiptItemRow({
    required this.id,
    required this.tenantId,
    required this.receiptId,
    required this.productId,
    required this.productName,
    this.productBarcode,
    required this.quantity,
    this.weightGrams,
    required this.unitPriceTiyin,
    required this.itemTotalTiyin,
    required this.discountAmountTiyin,
    required this.vatRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['receipt_id'] = Variable<String>(receiptId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || productBarcode != null) {
      map['product_barcode'] = Variable<String>(productBarcode);
    }
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || weightGrams != null) {
      map['weight_grams'] = Variable<int>(weightGrams);
    }
    map['unit_price_tiyin'] = Variable<int>(unitPriceTiyin);
    map['item_total_tiyin'] = Variable<int>(itemTotalTiyin);
    map['discount_amount_tiyin'] = Variable<int>(discountAmountTiyin);
    map['vat_rate'] = Variable<int>(vatRate);
    return map;
  }

  ReceiptItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ReceiptItemsTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      receiptId: Value(receiptId),
      productId: Value(productId),
      productName: Value(productName),
      productBarcode: productBarcode == null && nullToAbsent
          ? const Value.absent()
          : Value(productBarcode),
      quantity: Value(quantity),
      weightGrams: weightGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(weightGrams),
      unitPriceTiyin: Value(unitPriceTiyin),
      itemTotalTiyin: Value(itemTotalTiyin),
      discountAmountTiyin: Value(discountAmountTiyin),
      vatRate: Value(vatRate),
    );
  }

  factory ReceiptItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptItemRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      productBarcode: serializer.fromJson<String?>(json['productBarcode']),
      quantity: serializer.fromJson<int>(json['quantity']),
      weightGrams: serializer.fromJson<int?>(json['weightGrams']),
      unitPriceTiyin: serializer.fromJson<int>(json['unitPriceTiyin']),
      itemTotalTiyin: serializer.fromJson<int>(json['itemTotalTiyin']),
      discountAmountTiyin: serializer.fromJson<int>(
        json['discountAmountTiyin'],
      ),
      vatRate: serializer.fromJson<int>(json['vatRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'receiptId': serializer.toJson<String>(receiptId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'productBarcode': serializer.toJson<String?>(productBarcode),
      'quantity': serializer.toJson<int>(quantity),
      'weightGrams': serializer.toJson<int?>(weightGrams),
      'unitPriceTiyin': serializer.toJson<int>(unitPriceTiyin),
      'itemTotalTiyin': serializer.toJson<int>(itemTotalTiyin),
      'discountAmountTiyin': serializer.toJson<int>(discountAmountTiyin),
      'vatRate': serializer.toJson<int>(vatRate),
    };
  }

  ReceiptItemRow copyWith({
    String? id,
    String? tenantId,
    String? receiptId,
    String? productId,
    String? productName,
    Value<String?> productBarcode = const Value.absent(),
    int? quantity,
    Value<int?> weightGrams = const Value.absent(),
    int? unitPriceTiyin,
    int? itemTotalTiyin,
    int? discountAmountTiyin,
    int? vatRate,
  }) => ReceiptItemRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    receiptId: receiptId ?? this.receiptId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productBarcode: productBarcode.present
        ? productBarcode.value
        : this.productBarcode,
    quantity: quantity ?? this.quantity,
    weightGrams: weightGrams.present ? weightGrams.value : this.weightGrams,
    unitPriceTiyin: unitPriceTiyin ?? this.unitPriceTiyin,
    itemTotalTiyin: itemTotalTiyin ?? this.itemTotalTiyin,
    discountAmountTiyin: discountAmountTiyin ?? this.discountAmountTiyin,
    vatRate: vatRate ?? this.vatRate,
  );
  ReceiptItemRow copyWithCompanion(ReceiptItemsTableCompanion data) {
    return ReceiptItemRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      productBarcode: data.productBarcode.present
          ? data.productBarcode.value
          : this.productBarcode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      weightGrams: data.weightGrams.present
          ? data.weightGrams.value
          : this.weightGrams,
      unitPriceTiyin: data.unitPriceTiyin.present
          ? data.unitPriceTiyin.value
          : this.unitPriceTiyin,
      itemTotalTiyin: data.itemTotalTiyin.present
          ? data.itemTotalTiyin.value
          : this.itemTotalTiyin,
      discountAmountTiyin: data.discountAmountTiyin.present
          ? data.discountAmountTiyin.value
          : this.discountAmountTiyin,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('quantity: $quantity, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('unitPriceTiyin: $unitPriceTiyin, ')
          ..write('itemTotalTiyin: $itemTotalTiyin, ')
          ..write('discountAmountTiyin: $discountAmountTiyin, ')
          ..write('vatRate: $vatRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    receiptId,
    productId,
    productName,
    productBarcode,
    quantity,
    weightGrams,
    unitPriceTiyin,
    itemTotalTiyin,
    discountAmountTiyin,
    vatRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptItemRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.receiptId == this.receiptId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.productBarcode == this.productBarcode &&
          other.quantity == this.quantity &&
          other.weightGrams == this.weightGrams &&
          other.unitPriceTiyin == this.unitPriceTiyin &&
          other.itemTotalTiyin == this.itemTotalTiyin &&
          other.discountAmountTiyin == this.discountAmountTiyin &&
          other.vatRate == this.vatRate);
}

class ReceiptItemsTableCompanion extends UpdateCompanion<ReceiptItemRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> receiptId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String?> productBarcode;
  final Value<int> quantity;
  final Value<int?> weightGrams;
  final Value<int> unitPriceTiyin;
  final Value<int> itemTotalTiyin;
  final Value<int> discountAmountTiyin;
  final Value<int> vatRate;
  final Value<int> rowid;
  const ReceiptItemsTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.productBarcode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.weightGrams = const Value.absent(),
    this.unitPriceTiyin = const Value.absent(),
    this.itemTotalTiyin = const Value.absent(),
    this.discountAmountTiyin = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptItemsTableCompanion.insert({
    required String id,
    required String tenantId,
    required String receiptId,
    required String productId,
    required String productName,
    this.productBarcode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.weightGrams = const Value.absent(),
    required int unitPriceTiyin,
    required int itemTotalTiyin,
    this.discountAmountTiyin = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       receiptId = Value(receiptId),
       productId = Value(productId),
       productName = Value(productName),
       unitPriceTiyin = Value(unitPriceTiyin),
       itemTotalTiyin = Value(itemTotalTiyin);
  static Insertable<ReceiptItemRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? receiptId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? productBarcode,
    Expression<int>? quantity,
    Expression<int>? weightGrams,
    Expression<int>? unitPriceTiyin,
    Expression<int>? itemTotalTiyin,
    Expression<int>? discountAmountTiyin,
    Expression<int>? vatRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (receiptId != null) 'receipt_id': receiptId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (productBarcode != null) 'product_barcode': productBarcode,
      if (quantity != null) 'quantity': quantity,
      if (weightGrams != null) 'weight_grams': weightGrams,
      if (unitPriceTiyin != null) 'unit_price_tiyin': unitPriceTiyin,
      if (itemTotalTiyin != null) 'item_total_tiyin': itemTotalTiyin,
      if (discountAmountTiyin != null)
        'discount_amount_tiyin': discountAmountTiyin,
      if (vatRate != null) 'vat_rate': vatRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? receiptId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String?>? productBarcode,
    Value<int>? quantity,
    Value<int?>? weightGrams,
    Value<int>? unitPriceTiyin,
    Value<int>? itemTotalTiyin,
    Value<int>? discountAmountTiyin,
    Value<int>? vatRate,
    Value<int>? rowid,
  }) {
    return ReceiptItemsTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      receiptId: receiptId ?? this.receiptId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productBarcode: productBarcode ?? this.productBarcode,
      quantity: quantity ?? this.quantity,
      weightGrams: weightGrams ?? this.weightGrams,
      unitPriceTiyin: unitPriceTiyin ?? this.unitPriceTiyin,
      itemTotalTiyin: itemTotalTiyin ?? this.itemTotalTiyin,
      discountAmountTiyin: discountAmountTiyin ?? this.discountAmountTiyin,
      vatRate: vatRate ?? this.vatRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productBarcode.present) {
      map['product_barcode'] = Variable<String>(productBarcode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (weightGrams.present) {
      map['weight_grams'] = Variable<int>(weightGrams.value);
    }
    if (unitPriceTiyin.present) {
      map['unit_price_tiyin'] = Variable<int>(unitPriceTiyin.value);
    }
    if (itemTotalTiyin.present) {
      map['item_total_tiyin'] = Variable<int>(itemTotalTiyin.value);
    }
    if (discountAmountTiyin.present) {
      map['discount_amount_tiyin'] = Variable<int>(discountAmountTiyin.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<int>(vatRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('productBarcode: $productBarcode, ')
          ..write('quantity: $quantity, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('unitPriceTiyin: $unitPriceTiyin, ')
          ..write('itemTotalTiyin: $itemTotalTiyin, ')
          ..write('discountAmountTiyin: $discountAmountTiyin, ')
          ..write('vatRate: $vatRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTableTable extends ShiftsTable
    with TableInfo<$ShiftsTableTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workstationIdMeta = const VerificationMeta(
    'workstationId',
  );
  @override
  late final GeneratedColumn<String> workstationId = GeneratedColumn<String>(
    'workstation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftNumberMeta = const VerificationMeta(
    'shiftNumber',
  );
  @override
  late final GeneratedColumn<int> shiftNumber = GeneratedColumn<int>(
    'shift_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashStartTiyinMeta = const VerificationMeta(
    'cashStartTiyin',
  );
  @override
  late final GeneratedColumn<int> cashStartTiyin = GeneratedColumn<int>(
    'cash_start_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashEndTiyinMeta = const VerificationMeta(
    'cashEndTiyin',
  );
  @override
  late final GeneratedColumn<int> cashEndTiyin = GeneratedColumn<int>(
    'cash_end_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalSalesTiyinMeta = const VerificationMeta(
    'totalSalesTiyin',
  );
  @override
  late final GeneratedColumn<int> totalSalesTiyin = GeneratedColumn<int>(
    'total_sales_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCashTiyinMeta = const VerificationMeta(
    'totalCashTiyin',
  );
  @override
  late final GeneratedColumn<int> totalCashTiyin = GeneratedColumn<int>(
    'total_cash_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCardTiyinMeta = const VerificationMeta(
    'totalCardTiyin',
  );
  @override
  late final GeneratedColumn<int> totalCardTiyin = GeneratedColumn<int>(
    'total_card_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalQrTiyinMeta = const VerificationMeta(
    'totalQrTiyin',
  );
  @override
  late final GeneratedColumn<int> totalQrTiyin = GeneratedColumn<int>(
    'total_qr_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDebtTiyinMeta = const VerificationMeta(
    'totalDebtTiyin',
  );
  @override
  late final GeneratedColumn<int> totalDebtTiyin = GeneratedColumn<int>(
    'total_debt_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalReturnsTiyinMeta = const VerificationMeta(
    'totalReturnsTiyin',
  );
  @override
  late final GeneratedColumn<int> totalReturnsTiyin = GeneratedColumn<int>(
    'total_returns_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDepositsTiyinMeta =
      const VerificationMeta('totalDepositsTiyin');
  @override
  late final GeneratedColumn<int> totalDepositsTiyin = GeneratedColumn<int>(
    'total_deposits_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalWithdrawalsTiyinMeta =
      const VerificationMeta('totalWithdrawalsTiyin');
  @override
  late final GeneratedColumn<int> totalWithdrawalsTiyin = GeneratedColumn<int>(
    'total_withdrawals_tiyin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _receiptCountMeta = const VerificationMeta(
    'receiptCount',
  );
  @override
  late final GeneratedColumn<int> receiptCount = GeneratedColumn<int>(
    'receipt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _returnCountMeta = const VerificationMeta(
    'returnCount',
  );
  @override
  late final GeneratedColumn<int> returnCount = GeneratedColumn<int>(
    'return_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    storeId,
    workstationId,
    userId,
    shiftNumber,
    openedAt,
    closedAt,
    cashStartTiyin,
    cashEndTiyin,
    totalSalesTiyin,
    totalCashTiyin,
    totalCardTiyin,
    totalQrTiyin,
    totalDebtTiyin,
    totalReturnsTiyin,
    totalDepositsTiyin,
    totalWithdrawalsTiyin,
    receiptCount,
    returnCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('workstation_id')) {
      context.handle(
        _workstationIdMeta,
        workstationId.isAcceptableOrUnknown(
          data['workstation_id']!,
          _workstationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workstationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('shift_number')) {
      context.handle(
        _shiftNumberMeta,
        shiftNumber.isAcceptableOrUnknown(
          data['shift_number']!,
          _shiftNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shiftNumberMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('cash_start_tiyin')) {
      context.handle(
        _cashStartTiyinMeta,
        cashStartTiyin.isAcceptableOrUnknown(
          data['cash_start_tiyin']!,
          _cashStartTiyinMeta,
        ),
      );
    }
    if (data.containsKey('cash_end_tiyin')) {
      context.handle(
        _cashEndTiyinMeta,
        cashEndTiyin.isAcceptableOrUnknown(
          data['cash_end_tiyin']!,
          _cashEndTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_sales_tiyin')) {
      context.handle(
        _totalSalesTiyinMeta,
        totalSalesTiyin.isAcceptableOrUnknown(
          data['total_sales_tiyin']!,
          _totalSalesTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_cash_tiyin')) {
      context.handle(
        _totalCashTiyinMeta,
        totalCashTiyin.isAcceptableOrUnknown(
          data['total_cash_tiyin']!,
          _totalCashTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_card_tiyin')) {
      context.handle(
        _totalCardTiyinMeta,
        totalCardTiyin.isAcceptableOrUnknown(
          data['total_card_tiyin']!,
          _totalCardTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_qr_tiyin')) {
      context.handle(
        _totalQrTiyinMeta,
        totalQrTiyin.isAcceptableOrUnknown(
          data['total_qr_tiyin']!,
          _totalQrTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_debt_tiyin')) {
      context.handle(
        _totalDebtTiyinMeta,
        totalDebtTiyin.isAcceptableOrUnknown(
          data['total_debt_tiyin']!,
          _totalDebtTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_returns_tiyin')) {
      context.handle(
        _totalReturnsTiyinMeta,
        totalReturnsTiyin.isAcceptableOrUnknown(
          data['total_returns_tiyin']!,
          _totalReturnsTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_deposits_tiyin')) {
      context.handle(
        _totalDepositsTiyinMeta,
        totalDepositsTiyin.isAcceptableOrUnknown(
          data['total_deposits_tiyin']!,
          _totalDepositsTiyinMeta,
        ),
      );
    }
    if (data.containsKey('total_withdrawals_tiyin')) {
      context.handle(
        _totalWithdrawalsTiyinMeta,
        totalWithdrawalsTiyin.isAcceptableOrUnknown(
          data['total_withdrawals_tiyin']!,
          _totalWithdrawalsTiyinMeta,
        ),
      );
    }
    if (data.containsKey('receipt_count')) {
      context.handle(
        _receiptCountMeta,
        receiptCount.isAcceptableOrUnknown(
          data['receipt_count']!,
          _receiptCountMeta,
        ),
      );
    }
    if (data.containsKey('return_count')) {
      context.handle(
        _returnCountMeta,
        returnCount.isAcceptableOrUnknown(
          data['return_count']!,
          _returnCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      workstationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workstation_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      shiftNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shift_number'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      cashStartTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_start_tiyin'],
      )!,
      cashEndTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_end_tiyin'],
      )!,
      totalSalesTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sales_tiyin'],
      )!,
      totalCashTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cash_tiyin'],
      )!,
      totalCardTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_card_tiyin'],
      )!,
      totalQrTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_qr_tiyin'],
      )!,
      totalDebtTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_debt_tiyin'],
      )!,
      totalReturnsTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_returns_tiyin'],
      )!,
      totalDepositsTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_deposits_tiyin'],
      )!,
      totalWithdrawalsTiyin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_withdrawals_tiyin'],
      )!,
      receiptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_count'],
      )!,
      returnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}return_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShiftsTableTable createAlias(String alias) {
    return $ShiftsTableTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final String id;
  final String tenantId;
  final String? storeId;
  final String workstationId;
  final String userId;

  /// Per-workstation monotonic — printed on Z-reports. Caller computes.
  final int shiftNumber;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int cashStartTiyin;
  final int cashEndTiyin;
  final int totalSalesTiyin;
  final int totalCashTiyin;
  final int totalCardTiyin;
  final int totalQrTiyin;
  final int totalDebtTiyin;
  final int totalReturnsTiyin;
  final int totalDepositsTiyin;
  final int totalWithdrawalsTiyin;
  final int receiptCount;
  final int returnCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ShiftRow({
    required this.id,
    required this.tenantId,
    this.storeId,
    required this.workstationId,
    required this.userId,
    required this.shiftNumber,
    required this.openedAt,
    this.closedAt,
    required this.cashStartTiyin,
    required this.cashEndTiyin,
    required this.totalSalesTiyin,
    required this.totalCashTiyin,
    required this.totalCardTiyin,
    required this.totalQrTiyin,
    required this.totalDebtTiyin,
    required this.totalReturnsTiyin,
    required this.totalDepositsTiyin,
    required this.totalWithdrawalsTiyin,
    required this.receiptCount,
    required this.returnCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['workstation_id'] = Variable<String>(workstationId);
    map['user_id'] = Variable<String>(userId);
    map['shift_number'] = Variable<int>(shiftNumber);
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['cash_start_tiyin'] = Variable<int>(cashStartTiyin);
    map['cash_end_tiyin'] = Variable<int>(cashEndTiyin);
    map['total_sales_tiyin'] = Variable<int>(totalSalesTiyin);
    map['total_cash_tiyin'] = Variable<int>(totalCashTiyin);
    map['total_card_tiyin'] = Variable<int>(totalCardTiyin);
    map['total_qr_tiyin'] = Variable<int>(totalQrTiyin);
    map['total_debt_tiyin'] = Variable<int>(totalDebtTiyin);
    map['total_returns_tiyin'] = Variable<int>(totalReturnsTiyin);
    map['total_deposits_tiyin'] = Variable<int>(totalDepositsTiyin);
    map['total_withdrawals_tiyin'] = Variable<int>(totalWithdrawalsTiyin);
    map['receipt_count'] = Variable<int>(receiptCount);
    map['return_count'] = Variable<int>(returnCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShiftsTableCompanion toCompanion(bool nullToAbsent) {
    return ShiftsTableCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      workstationId: Value(workstationId),
      userId: Value(userId),
      shiftNumber: Value(shiftNumber),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      cashStartTiyin: Value(cashStartTiyin),
      cashEndTiyin: Value(cashEndTiyin),
      totalSalesTiyin: Value(totalSalesTiyin),
      totalCashTiyin: Value(totalCashTiyin),
      totalCardTiyin: Value(totalCardTiyin),
      totalQrTiyin: Value(totalQrTiyin),
      totalDebtTiyin: Value(totalDebtTiyin),
      totalReturnsTiyin: Value(totalReturnsTiyin),
      totalDepositsTiyin: Value(totalDepositsTiyin),
      totalWithdrawalsTiyin: Value(totalWithdrawalsTiyin),
      receiptCount: Value(receiptCount),
      returnCount: Value(returnCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShiftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      workstationId: serializer.fromJson<String>(json['workstationId']),
      userId: serializer.fromJson<String>(json['userId']),
      shiftNumber: serializer.fromJson<int>(json['shiftNumber']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      cashStartTiyin: serializer.fromJson<int>(json['cashStartTiyin']),
      cashEndTiyin: serializer.fromJson<int>(json['cashEndTiyin']),
      totalSalesTiyin: serializer.fromJson<int>(json['totalSalesTiyin']),
      totalCashTiyin: serializer.fromJson<int>(json['totalCashTiyin']),
      totalCardTiyin: serializer.fromJson<int>(json['totalCardTiyin']),
      totalQrTiyin: serializer.fromJson<int>(json['totalQrTiyin']),
      totalDebtTiyin: serializer.fromJson<int>(json['totalDebtTiyin']),
      totalReturnsTiyin: serializer.fromJson<int>(json['totalReturnsTiyin']),
      totalDepositsTiyin: serializer.fromJson<int>(json['totalDepositsTiyin']),
      totalWithdrawalsTiyin: serializer.fromJson<int>(
        json['totalWithdrawalsTiyin'],
      ),
      receiptCount: serializer.fromJson<int>(json['receiptCount']),
      returnCount: serializer.fromJson<int>(json['returnCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'storeId': serializer.toJson<String?>(storeId),
      'workstationId': serializer.toJson<String>(workstationId),
      'userId': serializer.toJson<String>(userId),
      'shiftNumber': serializer.toJson<int>(shiftNumber),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'cashStartTiyin': serializer.toJson<int>(cashStartTiyin),
      'cashEndTiyin': serializer.toJson<int>(cashEndTiyin),
      'totalSalesTiyin': serializer.toJson<int>(totalSalesTiyin),
      'totalCashTiyin': serializer.toJson<int>(totalCashTiyin),
      'totalCardTiyin': serializer.toJson<int>(totalCardTiyin),
      'totalQrTiyin': serializer.toJson<int>(totalQrTiyin),
      'totalDebtTiyin': serializer.toJson<int>(totalDebtTiyin),
      'totalReturnsTiyin': serializer.toJson<int>(totalReturnsTiyin),
      'totalDepositsTiyin': serializer.toJson<int>(totalDepositsTiyin),
      'totalWithdrawalsTiyin': serializer.toJson<int>(totalWithdrawalsTiyin),
      'receiptCount': serializer.toJson<int>(receiptCount),
      'returnCount': serializer.toJson<int>(returnCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ShiftRow copyWith({
    String? id,
    String? tenantId,
    Value<String?> storeId = const Value.absent(),
    String? workstationId,
    String? userId,
    int? shiftNumber,
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    int? cashStartTiyin,
    int? cashEndTiyin,
    int? totalSalesTiyin,
    int? totalCashTiyin,
    int? totalCardTiyin,
    int? totalQrTiyin,
    int? totalDebtTiyin,
    int? totalReturnsTiyin,
    int? totalDepositsTiyin,
    int? totalWithdrawalsTiyin,
    int? receiptCount,
    int? returnCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShiftRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    storeId: storeId.present ? storeId.value : this.storeId,
    workstationId: workstationId ?? this.workstationId,
    userId: userId ?? this.userId,
    shiftNumber: shiftNumber ?? this.shiftNumber,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    cashStartTiyin: cashStartTiyin ?? this.cashStartTiyin,
    cashEndTiyin: cashEndTiyin ?? this.cashEndTiyin,
    totalSalesTiyin: totalSalesTiyin ?? this.totalSalesTiyin,
    totalCashTiyin: totalCashTiyin ?? this.totalCashTiyin,
    totalCardTiyin: totalCardTiyin ?? this.totalCardTiyin,
    totalQrTiyin: totalQrTiyin ?? this.totalQrTiyin,
    totalDebtTiyin: totalDebtTiyin ?? this.totalDebtTiyin,
    totalReturnsTiyin: totalReturnsTiyin ?? this.totalReturnsTiyin,
    totalDepositsTiyin: totalDepositsTiyin ?? this.totalDepositsTiyin,
    totalWithdrawalsTiyin: totalWithdrawalsTiyin ?? this.totalWithdrawalsTiyin,
    receiptCount: receiptCount ?? this.receiptCount,
    returnCount: returnCount ?? this.returnCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShiftRow copyWithCompanion(ShiftsTableCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      workstationId: data.workstationId.present
          ? data.workstationId.value
          : this.workstationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      shiftNumber: data.shiftNumber.present
          ? data.shiftNumber.value
          : this.shiftNumber,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      cashStartTiyin: data.cashStartTiyin.present
          ? data.cashStartTiyin.value
          : this.cashStartTiyin,
      cashEndTiyin: data.cashEndTiyin.present
          ? data.cashEndTiyin.value
          : this.cashEndTiyin,
      totalSalesTiyin: data.totalSalesTiyin.present
          ? data.totalSalesTiyin.value
          : this.totalSalesTiyin,
      totalCashTiyin: data.totalCashTiyin.present
          ? data.totalCashTiyin.value
          : this.totalCashTiyin,
      totalCardTiyin: data.totalCardTiyin.present
          ? data.totalCardTiyin.value
          : this.totalCardTiyin,
      totalQrTiyin: data.totalQrTiyin.present
          ? data.totalQrTiyin.value
          : this.totalQrTiyin,
      totalDebtTiyin: data.totalDebtTiyin.present
          ? data.totalDebtTiyin.value
          : this.totalDebtTiyin,
      totalReturnsTiyin: data.totalReturnsTiyin.present
          ? data.totalReturnsTiyin.value
          : this.totalReturnsTiyin,
      totalDepositsTiyin: data.totalDepositsTiyin.present
          ? data.totalDepositsTiyin.value
          : this.totalDepositsTiyin,
      totalWithdrawalsTiyin: data.totalWithdrawalsTiyin.present
          ? data.totalWithdrawalsTiyin.value
          : this.totalWithdrawalsTiyin,
      receiptCount: data.receiptCount.present
          ? data.receiptCount.value
          : this.receiptCount,
      returnCount: data.returnCount.present
          ? data.returnCount.value
          : this.returnCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('workstationId: $workstationId, ')
          ..write('userId: $userId, ')
          ..write('shiftNumber: $shiftNumber, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cashStartTiyin: $cashStartTiyin, ')
          ..write('cashEndTiyin: $cashEndTiyin, ')
          ..write('totalSalesTiyin: $totalSalesTiyin, ')
          ..write('totalCashTiyin: $totalCashTiyin, ')
          ..write('totalCardTiyin: $totalCardTiyin, ')
          ..write('totalQrTiyin: $totalQrTiyin, ')
          ..write('totalDebtTiyin: $totalDebtTiyin, ')
          ..write('totalReturnsTiyin: $totalReturnsTiyin, ')
          ..write('totalDepositsTiyin: $totalDepositsTiyin, ')
          ..write('totalWithdrawalsTiyin: $totalWithdrawalsTiyin, ')
          ..write('receiptCount: $receiptCount, ')
          ..write('returnCount: $returnCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tenantId,
    storeId,
    workstationId,
    userId,
    shiftNumber,
    openedAt,
    closedAt,
    cashStartTiyin,
    cashEndTiyin,
    totalSalesTiyin,
    totalCashTiyin,
    totalCardTiyin,
    totalQrTiyin,
    totalDebtTiyin,
    totalReturnsTiyin,
    totalDepositsTiyin,
    totalWithdrawalsTiyin,
    receiptCount,
    returnCount,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.storeId == this.storeId &&
          other.workstationId == this.workstationId &&
          other.userId == this.userId &&
          other.shiftNumber == this.shiftNumber &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.cashStartTiyin == this.cashStartTiyin &&
          other.cashEndTiyin == this.cashEndTiyin &&
          other.totalSalesTiyin == this.totalSalesTiyin &&
          other.totalCashTiyin == this.totalCashTiyin &&
          other.totalCardTiyin == this.totalCardTiyin &&
          other.totalQrTiyin == this.totalQrTiyin &&
          other.totalDebtTiyin == this.totalDebtTiyin &&
          other.totalReturnsTiyin == this.totalReturnsTiyin &&
          other.totalDepositsTiyin == this.totalDepositsTiyin &&
          other.totalWithdrawalsTiyin == this.totalWithdrawalsTiyin &&
          other.receiptCount == this.receiptCount &&
          other.returnCount == this.returnCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShiftsTableCompanion extends UpdateCompanion<ShiftRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> storeId;
  final Value<String> workstationId;
  final Value<String> userId;
  final Value<int> shiftNumber;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int> cashStartTiyin;
  final Value<int> cashEndTiyin;
  final Value<int> totalSalesTiyin;
  final Value<int> totalCashTiyin;
  final Value<int> totalCardTiyin;
  final Value<int> totalQrTiyin;
  final Value<int> totalDebtTiyin;
  final Value<int> totalReturnsTiyin;
  final Value<int> totalDepositsTiyin;
  final Value<int> totalWithdrawalsTiyin;
  final Value<int> receiptCount;
  final Value<int> returnCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ShiftsTableCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.workstationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.shiftNumber = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.cashStartTiyin = const Value.absent(),
    this.cashEndTiyin = const Value.absent(),
    this.totalSalesTiyin = const Value.absent(),
    this.totalCashTiyin = const Value.absent(),
    this.totalCardTiyin = const Value.absent(),
    this.totalQrTiyin = const Value.absent(),
    this.totalDebtTiyin = const Value.absent(),
    this.totalReturnsTiyin = const Value.absent(),
    this.totalDepositsTiyin = const Value.absent(),
    this.totalWithdrawalsTiyin = const Value.absent(),
    this.receiptCount = const Value.absent(),
    this.returnCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftsTableCompanion.insert({
    required String id,
    required String tenantId,
    this.storeId = const Value.absent(),
    required String workstationId,
    required String userId,
    required int shiftNumber,
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    this.cashStartTiyin = const Value.absent(),
    this.cashEndTiyin = const Value.absent(),
    this.totalSalesTiyin = const Value.absent(),
    this.totalCashTiyin = const Value.absent(),
    this.totalCardTiyin = const Value.absent(),
    this.totalQrTiyin = const Value.absent(),
    this.totalDebtTiyin = const Value.absent(),
    this.totalReturnsTiyin = const Value.absent(),
    this.totalDepositsTiyin = const Value.absent(),
    this.totalWithdrawalsTiyin = const Value.absent(),
    this.receiptCount = const Value.absent(),
    this.returnCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       workstationId = Value(workstationId),
       userId = Value(userId),
       shiftNumber = Value(shiftNumber),
       openedAt = Value(openedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ShiftRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? storeId,
    Expression<String>? workstationId,
    Expression<String>? userId,
    Expression<int>? shiftNumber,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? cashStartTiyin,
    Expression<int>? cashEndTiyin,
    Expression<int>? totalSalesTiyin,
    Expression<int>? totalCashTiyin,
    Expression<int>? totalCardTiyin,
    Expression<int>? totalQrTiyin,
    Expression<int>? totalDebtTiyin,
    Expression<int>? totalReturnsTiyin,
    Expression<int>? totalDepositsTiyin,
    Expression<int>? totalWithdrawalsTiyin,
    Expression<int>? receiptCount,
    Expression<int>? returnCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (storeId != null) 'store_id': storeId,
      if (workstationId != null) 'workstation_id': workstationId,
      if (userId != null) 'user_id': userId,
      if (shiftNumber != null) 'shift_number': shiftNumber,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (cashStartTiyin != null) 'cash_start_tiyin': cashStartTiyin,
      if (cashEndTiyin != null) 'cash_end_tiyin': cashEndTiyin,
      if (totalSalesTiyin != null) 'total_sales_tiyin': totalSalesTiyin,
      if (totalCashTiyin != null) 'total_cash_tiyin': totalCashTiyin,
      if (totalCardTiyin != null) 'total_card_tiyin': totalCardTiyin,
      if (totalQrTiyin != null) 'total_qr_tiyin': totalQrTiyin,
      if (totalDebtTiyin != null) 'total_debt_tiyin': totalDebtTiyin,
      if (totalReturnsTiyin != null) 'total_returns_tiyin': totalReturnsTiyin,
      if (totalDepositsTiyin != null)
        'total_deposits_tiyin': totalDepositsTiyin,
      if (totalWithdrawalsTiyin != null)
        'total_withdrawals_tiyin': totalWithdrawalsTiyin,
      if (receiptCount != null) 'receipt_count': receiptCount,
      if (returnCount != null) 'return_count': returnCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? storeId,
    Value<String>? workstationId,
    Value<String>? userId,
    Value<int>? shiftNumber,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int>? cashStartTiyin,
    Value<int>? cashEndTiyin,
    Value<int>? totalSalesTiyin,
    Value<int>? totalCashTiyin,
    Value<int>? totalCardTiyin,
    Value<int>? totalQrTiyin,
    Value<int>? totalDebtTiyin,
    Value<int>? totalReturnsTiyin,
    Value<int>? totalDepositsTiyin,
    Value<int>? totalWithdrawalsTiyin,
    Value<int>? receiptCount,
    Value<int>? returnCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ShiftsTableCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeId: storeId ?? this.storeId,
      workstationId: workstationId ?? this.workstationId,
      userId: userId ?? this.userId,
      shiftNumber: shiftNumber ?? this.shiftNumber,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      cashStartTiyin: cashStartTiyin ?? this.cashStartTiyin,
      cashEndTiyin: cashEndTiyin ?? this.cashEndTiyin,
      totalSalesTiyin: totalSalesTiyin ?? this.totalSalesTiyin,
      totalCashTiyin: totalCashTiyin ?? this.totalCashTiyin,
      totalCardTiyin: totalCardTiyin ?? this.totalCardTiyin,
      totalQrTiyin: totalQrTiyin ?? this.totalQrTiyin,
      totalDebtTiyin: totalDebtTiyin ?? this.totalDebtTiyin,
      totalReturnsTiyin: totalReturnsTiyin ?? this.totalReturnsTiyin,
      totalDepositsTiyin: totalDepositsTiyin ?? this.totalDepositsTiyin,
      totalWithdrawalsTiyin:
          totalWithdrawalsTiyin ?? this.totalWithdrawalsTiyin,
      receiptCount: receiptCount ?? this.receiptCount,
      returnCount: returnCount ?? this.returnCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (workstationId.present) {
      map['workstation_id'] = Variable<String>(workstationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (shiftNumber.present) {
      map['shift_number'] = Variable<int>(shiftNumber.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (cashStartTiyin.present) {
      map['cash_start_tiyin'] = Variable<int>(cashStartTiyin.value);
    }
    if (cashEndTiyin.present) {
      map['cash_end_tiyin'] = Variable<int>(cashEndTiyin.value);
    }
    if (totalSalesTiyin.present) {
      map['total_sales_tiyin'] = Variable<int>(totalSalesTiyin.value);
    }
    if (totalCashTiyin.present) {
      map['total_cash_tiyin'] = Variable<int>(totalCashTiyin.value);
    }
    if (totalCardTiyin.present) {
      map['total_card_tiyin'] = Variable<int>(totalCardTiyin.value);
    }
    if (totalQrTiyin.present) {
      map['total_qr_tiyin'] = Variable<int>(totalQrTiyin.value);
    }
    if (totalDebtTiyin.present) {
      map['total_debt_tiyin'] = Variable<int>(totalDebtTiyin.value);
    }
    if (totalReturnsTiyin.present) {
      map['total_returns_tiyin'] = Variable<int>(totalReturnsTiyin.value);
    }
    if (totalDepositsTiyin.present) {
      map['total_deposits_tiyin'] = Variable<int>(totalDepositsTiyin.value);
    }
    if (totalWithdrawalsTiyin.present) {
      map['total_withdrawals_tiyin'] = Variable<int>(
        totalWithdrawalsTiyin.value,
      );
    }
    if (receiptCount.present) {
      map['receipt_count'] = Variable<int>(receiptCount.value);
    }
    if (returnCount.present) {
      map['return_count'] = Variable<int>(returnCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsTableCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('storeId: $storeId, ')
          ..write('workstationId: $workstationId, ')
          ..write('userId: $userId, ')
          ..write('shiftNumber: $shiftNumber, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cashStartTiyin: $cashStartTiyin, ')
          ..write('cashEndTiyin: $cashEndTiyin, ')
          ..write('totalSalesTiyin: $totalSalesTiyin, ')
          ..write('totalCashTiyin: $totalCashTiyin, ')
          ..write('totalCardTiyin: $totalCardTiyin, ')
          ..write('totalQrTiyin: $totalQrTiyin, ')
          ..write('totalDebtTiyin: $totalDebtTiyin, ')
          ..write('totalReturnsTiyin: $totalReturnsTiyin, ')
          ..write('totalDepositsTiyin: $totalDepositsTiyin, ')
          ..write('totalWithdrawalsTiyin: $totalWithdrawalsTiyin, ')
          ..write('receiptCount: $receiptCount, ')
          ..write('returnCount: $returnCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTableTable extends SyncOutboxTable
    with TableInfo<$SyncOutboxTableTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    op,
    uuid,
    payloadJson,
    createdAt,
    syncedAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTableTable createAlias(String alias) {
    return $SyncOutboxTableTable(attachedDatabase, alias);
  }
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  final int id;

  /// Name of the domain table this entry belongs to (e.g. "settings", "users").
  /// Renamed from `tableName` to avoid colliding with drift's table-name override getter.
  final String targetTable;
  final String op;
  final String uuid;
  final String payloadJson;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int attempts;
  final String? lastError;
  const SyncOutboxRow({
    required this.id,
    required this.targetTable,
    required this.op,
    required this.uuid,
    required this.payloadJson,
    required this.createdAt,
    this.syncedAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['op'] = Variable<String>(op);
    map['uuid'] = Variable<String>(uuid);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxTableCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxTableCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      op: Value(op),
      uuid: Value(uuid),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      op: serializer.fromJson<String>(json['op']),
      uuid: serializer.fromJson<String>(json['uuid']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'op': serializer.toJson<String>(op),
      'uuid': serializer.toJson<String>(uuid),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxRow copyWith({
    int? id,
    String? targetTable,
    String? op,
    String? uuid,
    String? payloadJson,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxRow(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    op: op ?? this.op,
    uuid: uuid ?? this.uuid,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxTableCompanion data) {
    return SyncOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      op: data.op.present ? data.op.value : this.op,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('op: $op, ')
          ..write('uuid: $uuid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    op,
    uuid,
    payloadJson,
    createdAt,
    syncedAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.op == this.op &&
          other.uuid == this.uuid &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncOutboxTableCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> op;
  final Value<String> uuid;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const SyncOutboxTableCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.op = const Value.absent(),
    this.uuid = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncOutboxTableCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String op,
    required String uuid,
    required String payloadJson,
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : targetTable = Value(targetTable),
       op = Value(op),
       uuid = Value(uuid),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxRow> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? op,
    Expression<String>? uuid,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (op != null) 'op': op,
      if (uuid != null) 'uuid': uuid,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncOutboxTableCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? op,
    Value<String>? uuid,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<int>? attempts,
    Value<String?>? lastError,
  }) {
    return SyncOutboxTableCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      op: op ?? this.op,
      uuid: uuid ?? this.uuid,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('op: $op, ')
          ..write('uuid: $uuid, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTableTable extends SyncCursorsTable
    with TableInfo<$SyncCursorsTableTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [targetTable, cursor, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetTable};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncCursorsTableTable createAlias(String alias) {
    return $SyncCursorsTableTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  /// Name of the domain table this cursor tracks (e.g. "settings", "users").
  final String targetTable;
  final String cursor;
  final DateTime updatedAt;
  const SyncCursorRow({
    required this.targetTable,
    required this.cursor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_table'] = Variable<String>(targetTable);
    map['cursor'] = Variable<String>(cursor);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncCursorsTableCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsTableCompanion(
      targetTable: Value(targetTable),
      cursor: Value(cursor),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      targetTable: serializer.fromJson<String>(json['targetTable']),
      cursor: serializer.fromJson<String>(json['cursor']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'targetTable': serializer.toJson<String>(targetTable),
      'cursor': serializer.toJson<String>(cursor),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncCursorRow copyWith({
    String? targetTable,
    String? cursor,
    DateTime? updatedAt,
  }) => SyncCursorRow(
    targetTable: targetTable ?? this.targetTable,
    cursor: cursor ?? this.cursor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncCursorRow copyWithCompanion(SyncCursorsTableCompanion data) {
    return SyncCursorRow(
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('targetTable: $targetTable, ')
          ..write('cursor: $cursor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(targetTable, cursor, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.targetTable == this.targetTable &&
          other.cursor == this.cursor &&
          other.updatedAt == this.updatedAt);
}

class SyncCursorsTableCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> targetTable;
  final Value<String> cursor;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncCursorsTableCompanion({
    this.targetTable = const Value.absent(),
    this.cursor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsTableCompanion.insert({
    required String targetTable,
    required String cursor,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : targetTable = Value(targetTable),
       cursor = Value(cursor),
       updatedAt = Value(updatedAt);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? targetTable,
    Expression<String>? cursor,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetTable != null) 'target_table': targetTable,
      if (cursor != null) 'cursor': cursor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsTableCompanion copyWith({
    Value<String>? targetTable,
    Value<String>? cursor,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncCursorsTableCompanion(
      targetTable: targetTable ?? this.targetTable,
      cursor: cursor ?? this.cursor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsTableCompanion(')
          ..write('targetTable: $targetTable, ')
          ..write('cursor: $cursor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $CategoriesTableTable categoriesTable = $CategoriesTableTable(
    this,
  );
  late final $SuppliersTableTable suppliersTable = $SuppliersTableTable(this);
  late final $ClientsTableTable clientsTable = $ClientsTableTable(this);
  late final $StockMovementsTableTable stockMovementsTable =
      $StockMovementsTableTable(this);
  late final $ReceiptsTableTable receiptsTable = $ReceiptsTableTable(this);
  late final $ReceiptItemsTableTable receiptItemsTable =
      $ReceiptItemsTableTable(this);
  late final $ShiftsTableTable shiftsTable = $ShiftsTableTable(this);
  late final $SyncOutboxTableTable syncOutboxTable = $SyncOutboxTableTable(
    this,
  );
  late final $SyncCursorsTableTable syncCursorsTable = $SyncCursorsTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersTable,
    settingsTable,
    productsTable,
    categoriesTable,
    suppliersTable,
    clientsTable,
    stockMovementsTable,
    receiptsTable,
    receiptItemsTable,
    shiftsTable,
    syncOutboxTable,
    syncCursorsTable,
  ];
}

typedef $$UsersTableTableCreateCompanionBuilder =
    UsersTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String name,
      Value<String?> login,
      Value<String?> email,
      Value<String?> pinHash,
      required String role,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableTableUpdateCompanionBuilder =
    UsersTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> name,
      Value<String?> login,
      Value<String?> email,
      Value<String?> pinHash,
      Value<String> role,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get login => $composableBuilder(
    column: $table.login,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get login => $composableBuilder(
    column: $table.login,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get login =>
      $composableBuilder(column: $table.login, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTableTable,
          UserRow,
          $$UsersTableTableFilterComposer,
          $$UsersTableTableOrderingComposer,
          $$UsersTableTableAnnotationComposer,
          $$UsersTableTableCreateCompanionBuilder,
          $$UsersTableTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTableTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> login = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                login: login,
                email: email,
                pinHash: pinHash,
                role: role,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String?> login = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                required String role,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsersTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                login: login,
                email: email,
                pinHash: pinHash,
                role: role,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTableTable,
      UserRow,
      $$UsersTableTableFilterComposer,
      $$UsersTableTableOrderingComposer,
      $$UsersTableTableAnnotationComposer,
      $$UsersTableTableCreateCompanionBuilder,
      $$UsersTableTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTableTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String tenantId,
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> tenantId,
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                tenantId: tenantId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                tenantId: tenantId,
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String name,
      Value<String?> nameKz,
      Value<String?> barcodeGtin,
      Value<String?> ntin,
      Value<String?> xtin,
      Value<DateTime?> xtinExpiresAt,
      Value<String?> categoryId,
      Value<String?> categoryOktru,
      required String purchaseUnit,
      required int purchasePriceTiyin,
      required String saleUnit,
      required int salePriceTiyin,
      Value<bool> isWeighted,
      Value<int?> minWeightGrams,
      Value<int> weightStepGrams,
      Value<int> vatRate,
      Value<bool> isActive,
      Value<String> approvalStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> name,
      Value<String?> nameKz,
      Value<String?> barcodeGtin,
      Value<String?> ntin,
      Value<String?> xtin,
      Value<DateTime?> xtinExpiresAt,
      Value<String?> categoryId,
      Value<String?> categoryOktru,
      Value<String> purchaseUnit,
      Value<int> purchasePriceTiyin,
      Value<String> saleUnit,
      Value<int> salePriceTiyin,
      Value<bool> isWeighted,
      Value<int?> minWeightGrams,
      Value<int> weightStepGrams,
      Value<int> vatRate,
      Value<bool> isActive,
      Value<String> approvalStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKz => $composableBuilder(
    column: $table.nameKz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeGtin => $composableBuilder(
    column: $table.barcodeGtin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ntin => $composableBuilder(
    column: $table.ntin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get xtin => $composableBuilder(
    column: $table.xtin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get xtinExpiresAt => $composableBuilder(
    column: $table.xtinExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryOktru => $composableBuilder(
    column: $table.categoryOktru,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseUnit => $composableBuilder(
    column: $table.purchaseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceTiyin => $composableBuilder(
    column: $table.purchasePriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleUnit => $composableBuilder(
    column: $table.saleUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salePriceTiyin => $composableBuilder(
    column: $table.salePriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minWeightGrams => $composableBuilder(
    column: $table.minWeightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weightStepGrams => $composableBuilder(
    column: $table.weightStepGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKz => $composableBuilder(
    column: $table.nameKz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeGtin => $composableBuilder(
    column: $table.barcodeGtin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ntin => $composableBuilder(
    column: $table.ntin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get xtin => $composableBuilder(
    column: $table.xtin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get xtinExpiresAt => $composableBuilder(
    column: $table.xtinExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryOktru => $composableBuilder(
    column: $table.categoryOktru,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseUnit => $composableBuilder(
    column: $table.purchaseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceTiyin => $composableBuilder(
    column: $table.purchasePriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleUnit => $composableBuilder(
    column: $table.saleUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salePriceTiyin => $composableBuilder(
    column: $table.salePriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minWeightGrams => $composableBuilder(
    column: $table.minWeightGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weightStepGrams => $composableBuilder(
    column: $table.weightStepGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameKz =>
      $composableBuilder(column: $table.nameKz, builder: (column) => column);

  GeneratedColumn<String> get barcodeGtin => $composableBuilder(
    column: $table.barcodeGtin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ntin =>
      $composableBuilder(column: $table.ntin, builder: (column) => column);

  GeneratedColumn<String> get xtin =>
      $composableBuilder(column: $table.xtin, builder: (column) => column);

  GeneratedColumn<DateTime> get xtinExpiresAt => $composableBuilder(
    column: $table.xtinExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryOktru => $composableBuilder(
    column: $table.categoryOktru,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseUnit => $composableBuilder(
    column: $table.purchaseUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceTiyin => $composableBuilder(
    column: $table.purchasePriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleUnit =>
      $composableBuilder(column: $table.saleUnit, builder: (column) => column);

  GeneratedColumn<int> get salePriceTiyin => $composableBuilder(
    column: $table.salePriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minWeightGrams => $composableBuilder(
    column: $table.minWeightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weightStepGrams => $composableBuilder(
    column: $table.weightStepGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get approvalStatus => $composableBuilder(
    column: $table.approvalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductRow,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductRow,
            BaseReferences<_$AppDatabase, $ProductsTableTable, ProductRow>,
          ),
          ProductRow,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameKz = const Value.absent(),
                Value<String?> barcodeGtin = const Value.absent(),
                Value<String?> ntin = const Value.absent(),
                Value<String?> xtin = const Value.absent(),
                Value<DateTime?> xtinExpiresAt = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryOktru = const Value.absent(),
                Value<String> purchaseUnit = const Value.absent(),
                Value<int> purchasePriceTiyin = const Value.absent(),
                Value<String> saleUnit = const Value.absent(),
                Value<int> salePriceTiyin = const Value.absent(),
                Value<bool> isWeighted = const Value.absent(),
                Value<int?> minWeightGrams = const Value.absent(),
                Value<int> weightStepGrams = const Value.absent(),
                Value<int> vatRate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> approvalStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                nameKz: nameKz,
                barcodeGtin: barcodeGtin,
                ntin: ntin,
                xtin: xtin,
                xtinExpiresAt: xtinExpiresAt,
                categoryId: categoryId,
                categoryOktru: categoryOktru,
                purchaseUnit: purchaseUnit,
                purchasePriceTiyin: purchasePriceTiyin,
                saleUnit: saleUnit,
                salePriceTiyin: salePriceTiyin,
                isWeighted: isWeighted,
                minWeightGrams: minWeightGrams,
                weightStepGrams: weightStepGrams,
                vatRate: vatRate,
                isActive: isActive,
                approvalStatus: approvalStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String?> nameKz = const Value.absent(),
                Value<String?> barcodeGtin = const Value.absent(),
                Value<String?> ntin = const Value.absent(),
                Value<String?> xtin = const Value.absent(),
                Value<DateTime?> xtinExpiresAt = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryOktru = const Value.absent(),
                required String purchaseUnit,
                required int purchasePriceTiyin,
                required String saleUnit,
                required int salePriceTiyin,
                Value<bool> isWeighted = const Value.absent(),
                Value<int?> minWeightGrams = const Value.absent(),
                Value<int> weightStepGrams = const Value.absent(),
                Value<int> vatRate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> approvalStatus = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                nameKz: nameKz,
                barcodeGtin: barcodeGtin,
                ntin: ntin,
                xtin: xtin,
                xtinExpiresAt: xtinExpiresAt,
                categoryId: categoryId,
                categoryOktru: categoryOktru,
                purchaseUnit: purchaseUnit,
                purchasePriceTiyin: purchasePriceTiyin,
                saleUnit: saleUnit,
                salePriceTiyin: salePriceTiyin,
                isWeighted: isWeighted,
                minWeightGrams: minWeightGrams,
                weightStepGrams: weightStepGrams,
                vatRate: vatRate,
                isActive: isActive,
                approvalStatus: approvalStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductRow,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductRow,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductRow>,
      ),
      ProductRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableTableCreateCompanionBuilder =
    CategoriesTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String name,
      Value<String?> nameKz,
      Value<String?> parentId,
      Value<String?> oktruCode,
      Value<int> sortOrder,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableTableUpdateCompanionBuilder =
    CategoriesTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> name,
      Value<String?> nameKz,
      Value<String?> parentId,
      Value<String?> oktruCode,
      Value<int> sortOrder,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKz => $composableBuilder(
    column: $table.nameKz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oktruCode => $composableBuilder(
    column: $table.oktruCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKz => $composableBuilder(
    column: $table.nameKz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oktruCode => $composableBuilder(
    column: $table.oktruCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameKz =>
      $composableBuilder(column: $table.nameKz, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get oktruCode =>
      $composableBuilder(column: $table.oktruCode, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoryRow,
          $$CategoriesTableTableFilterComposer,
          $$CategoriesTableTableOrderingComposer,
          $$CategoriesTableTableAnnotationComposer,
          $$CategoriesTableTableCreateCompanionBuilder,
          $$CategoriesTableTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableTableManager(
    _$AppDatabase db,
    $CategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameKz = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> oktruCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                nameKz: nameKz,
                parentId: parentId,
                oktruCode: oktruCode,
                sortOrder: sortOrder,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String?> nameKz = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> oktruCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                nameKz: nameKz,
                parentId: parentId,
                oktruCode: oktruCode,
                sortOrder: sortOrder,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTableTable,
      CategoryRow,
      $$CategoriesTableTableFilterComposer,
      $$CategoriesTableTableOrderingComposer,
      $$CategoriesTableTableAnnotationComposer,
      $$CategoriesTableTableCreateCompanionBuilder,
      $$CategoriesTableTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$SuppliersTableTableCreateCompanionBuilder =
    SuppliersTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String name,
      Value<String?> phone,
      Value<String?> bin,
      Value<String?> notes,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SuppliersTableTableUpdateCompanionBuilder =
    SuppliersTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> name,
      Value<String?> phone,
      Value<String?> bin,
      Value<String?> notes,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SuppliersTableTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bin => $composableBuilder(
    column: $table.bin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SuppliersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bin => $composableBuilder(
    column: $table.bin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuppliersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get bin =>
      $composableBuilder(column: $table.bin, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SuppliersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuppliersTableTable,
          SupplierRow,
          $$SuppliersTableTableFilterComposer,
          $$SuppliersTableTableOrderingComposer,
          $$SuppliersTableTableAnnotationComposer,
          $$SuppliersTableTableCreateCompanionBuilder,
          $$SuppliersTableTableUpdateCompanionBuilder,
          (
            SupplierRow,
            BaseReferences<_$AppDatabase, $SuppliersTableTable, SupplierRow>,
          ),
          SupplierRow,
          PrefetchHooks Function()
        > {
  $$SuppliersTableTableTableManager(
    _$AppDatabase db,
    $SuppliersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> bin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                phone: phone,
                bin: bin,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> bin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SuppliersTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                phone: phone,
                bin: bin,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SuppliersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuppliersTableTable,
      SupplierRow,
      $$SuppliersTableTableFilterComposer,
      $$SuppliersTableTableOrderingComposer,
      $$SuppliersTableTableAnnotationComposer,
      $$SuppliersTableTableCreateCompanionBuilder,
      $$SuppliersTableTableUpdateCompanionBuilder,
      (
        SupplierRow,
        BaseReferences<_$AppDatabase, $SuppliersTableTable, SupplierRow>,
      ),
      SupplierRow,
      PrefetchHooks Function()
    >;
typedef $$ClientsTableTableCreateCompanionBuilder =
    ClientsTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String name,
      Value<String?> phone,
      Value<String?> iin,
      Value<String?> notes,
      Value<int?> debtLimitTiyin,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ClientsTableTableUpdateCompanionBuilder =
    ClientsTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> name,
      Value<String?> phone,
      Value<String?> iin,
      Value<String?> notes,
      Value<int?> debtLimitTiyin,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ClientsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iin => $composableBuilder(
    column: $table.iin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iin => $composableBuilder(
    column: $table.iin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get iin =>
      $composableBuilder(column: $table.iin, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get debtLimitTiyin => $composableBuilder(
    column: $table.debtLimitTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClientsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClientsTableTable,
          ClientRow,
          $$ClientsTableTableFilterComposer,
          $$ClientsTableTableOrderingComposer,
          $$ClientsTableTableAnnotationComposer,
          $$ClientsTableTableCreateCompanionBuilder,
          $$ClientsTableTableUpdateCompanionBuilder,
          (
            ClientRow,
            BaseReferences<_$AppDatabase, $ClientsTableTable, ClientRow>,
          ),
          ClientRow,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableTableManager(_$AppDatabase db, $ClientsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> iin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> debtLimitTiyin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                phone: phone,
                iin: iin,
                notes: notes,
                debtLimitTiyin: debtLimitTiyin,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> iin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> debtLimitTiyin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClientsTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                name: name,
                phone: phone,
                iin: iin,
                notes: notes,
                debtLimitTiyin: debtLimitTiyin,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClientsTableTable,
      ClientRow,
      $$ClientsTableTableFilterComposer,
      $$ClientsTableTableOrderingComposer,
      $$ClientsTableTableAnnotationComposer,
      $$ClientsTableTableCreateCompanionBuilder,
      $$ClientsTableTableUpdateCompanionBuilder,
      (ClientRow, BaseReferences<_$AppDatabase, $ClientsTableTable, ClientRow>),
      ClientRow,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsTableTableCreateCompanionBuilder =
    StockMovementsTableCompanion Function({
      Value<int> id,
      required String clientUuid,
      required String tenantId,
      Value<String?> storeId,
      required String productId,
      required int delta,
      required String reason,
      required String deviceId,
      Value<String?> cashierUserId,
      Value<String?> overrideByUserId,
      Value<String?> receiptId,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
    });
typedef $$StockMovementsTableTableUpdateCompanionBuilder =
    StockMovementsTableCompanion Function({
      Value<int> id,
      Value<String> clientUuid,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> productId,
      Value<int> delta,
      Value<String> reason,
      Value<String> deviceId,
      Value<String?> cashierUserId,
      Value<String?> overrideByUserId,
      Value<String?> receiptId,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
    });

class $$StockMovementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTableTable> {
  $$StockMovementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideByUserId => $composableBuilder(
    column: $table.overrideByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockMovementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTableTable> {
  $$StockMovementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideByUserId => $composableBuilder(
    column: $table.overrideByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockMovementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTableTable> {
  $$StockMovementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get cashierUserId => $composableBuilder(
    column: $table.cashierUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideByUserId => $composableBuilder(
    column: $table.overrideByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$StockMovementsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTableTable,
          StockMovementRow,
          $$StockMovementsTableTableFilterComposer,
          $$StockMovementsTableTableOrderingComposer,
          $$StockMovementsTableTableAnnotationComposer,
          $$StockMovementsTableTableCreateCompanionBuilder,
          $$StockMovementsTableTableUpdateCompanionBuilder,
          (
            StockMovementRow,
            BaseReferences<
              _$AppDatabase,
              $StockMovementsTableTable,
              StockMovementRow
            >,
          ),
          StockMovementRow,
          PrefetchHooks Function()
        > {
  $$StockMovementsTableTableTableManager(
    _$AppDatabase db,
    $StockMovementsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StockMovementsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> cashierUserId = const Value.absent(),
                Value<String?> overrideByUserId = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => StockMovementsTableCompanion(
                id: id,
                clientUuid: clientUuid,
                tenantId: tenantId,
                storeId: storeId,
                productId: productId,
                delta: delta,
                reason: reason,
                deviceId: deviceId,
                cashierUserId: cashierUserId,
                overrideByUserId: overrideByUserId,
                receiptId: receiptId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientUuid,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String productId,
                required int delta,
                required String reason,
                required String deviceId,
                Value<String?> cashierUserId = const Value.absent(),
                Value<String?> overrideByUserId = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => StockMovementsTableCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                tenantId: tenantId,
                storeId: storeId,
                productId: productId,
                delta: delta,
                reason: reason,
                deviceId: deviceId,
                cashierUserId: cashierUserId,
                overrideByUserId: overrideByUserId,
                receiptId: receiptId,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockMovementsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTableTable,
      StockMovementRow,
      $$StockMovementsTableTableFilterComposer,
      $$StockMovementsTableTableOrderingComposer,
      $$StockMovementsTableTableAnnotationComposer,
      $$StockMovementsTableTableCreateCompanionBuilder,
      $$StockMovementsTableTableUpdateCompanionBuilder,
      (
        StockMovementRow,
        BaseReferences<
          _$AppDatabase,
          $StockMovementsTableTable,
          StockMovementRow
        >,
      ),
      StockMovementRow,
      PrefetchHooks Function()
    >;
typedef $$ReceiptsTableTableCreateCompanionBuilder =
    ReceiptsTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String workstationId,
      required String shiftId,
      required String userId,
      required int receiptNumber,
      required int totalAmountTiyin,
      required int vatAmountTiyin,
      Value<int> discountAmountTiyin,
      Value<int> changeAmountTiyin,
      Value<int> cashAmountTiyin,
      Value<int> cardAmountTiyin,
      Value<int> qrAmountTiyin,
      Value<int> debtAmountTiyin,
      Value<bool> isReturn,
      Value<String?> refundForReceiptId,
      Value<String?> clientId,
      Value<String?> debtId,
      Value<String?> fiscalId,
      Value<String> fiscalStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReceiptsTableTableUpdateCompanionBuilder =
    ReceiptsTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> workstationId,
      Value<String> shiftId,
      Value<String> userId,
      Value<int> receiptNumber,
      Value<int> totalAmountTiyin,
      Value<int> vatAmountTiyin,
      Value<int> discountAmountTiyin,
      Value<int> changeAmountTiyin,
      Value<int> cashAmountTiyin,
      Value<int> cardAmountTiyin,
      Value<int> qrAmountTiyin,
      Value<int> debtAmountTiyin,
      Value<bool> isReturn,
      Value<String?> refundForReceiptId,
      Value<String?> clientId,
      Value<String?> debtId,
      Value<String?> fiscalId,
      Value<String> fiscalStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReceiptsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTableTable> {
  $$ReceiptsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmountTiyin => $composableBuilder(
    column: $table.totalAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatAmountTiyin => $composableBuilder(
    column: $table.vatAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeAmountTiyin => $composableBuilder(
    column: $table.changeAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashAmountTiyin => $composableBuilder(
    column: $table.cashAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardAmountTiyin => $composableBuilder(
    column: $table.cardAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qrAmountTiyin => $composableBuilder(
    column: $table.qrAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtAmountTiyin => $composableBuilder(
    column: $table.debtAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReturn => $composableBuilder(
    column: $table.isReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundForReceiptId => $composableBuilder(
    column: $table.refundForReceiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debtId => $composableBuilder(
    column: $table.debtId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalId => $composableBuilder(
    column: $table.fiscalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalStatus => $composableBuilder(
    column: $table.fiscalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTableTable> {
  $$ReceiptsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmountTiyin => $composableBuilder(
    column: $table.totalAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatAmountTiyin => $composableBuilder(
    column: $table.vatAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeAmountTiyin => $composableBuilder(
    column: $table.changeAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashAmountTiyin => $composableBuilder(
    column: $table.cashAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardAmountTiyin => $composableBuilder(
    column: $table.cardAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qrAmountTiyin => $composableBuilder(
    column: $table.qrAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtAmountTiyin => $composableBuilder(
    column: $table.debtAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReturn => $composableBuilder(
    column: $table.isReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundForReceiptId => $composableBuilder(
    column: $table.refundForReceiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debtId => $composableBuilder(
    column: $table.debtId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalId => $composableBuilder(
    column: $table.fiscalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalStatus => $composableBuilder(
    column: $table.fiscalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTableTable> {
  $$ReceiptsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalAmountTiyin => $composableBuilder(
    column: $table.totalAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatAmountTiyin => $composableBuilder(
    column: $table.vatAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changeAmountTiyin => $composableBuilder(
    column: $table.changeAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashAmountTiyin => $composableBuilder(
    column: $table.cashAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cardAmountTiyin => $composableBuilder(
    column: $table.cardAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qrAmountTiyin => $composableBuilder(
    column: $table.qrAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get debtAmountTiyin => $composableBuilder(
    column: $table.debtAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReturn =>
      $composableBuilder(column: $table.isReturn, builder: (column) => column);

  GeneratedColumn<String> get refundForReceiptId => $composableBuilder(
    column: $table.refundForReceiptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get debtId =>
      $composableBuilder(column: $table.debtId, builder: (column) => column);

  GeneratedColumn<String> get fiscalId =>
      $composableBuilder(column: $table.fiscalId, builder: (column) => column);

  GeneratedColumn<String> get fiscalStatus => $composableBuilder(
    column: $table.fiscalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReceiptsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTableTable,
          ReceiptRow,
          $$ReceiptsTableTableFilterComposer,
          $$ReceiptsTableTableOrderingComposer,
          $$ReceiptsTableTableAnnotationComposer,
          $$ReceiptsTableTableCreateCompanionBuilder,
          $$ReceiptsTableTableUpdateCompanionBuilder,
          (
            ReceiptRow,
            BaseReferences<_$AppDatabase, $ReceiptsTableTable, ReceiptRow>,
          ),
          ReceiptRow,
          PrefetchHooks Function()
        > {
  $$ReceiptsTableTableTableManager(_$AppDatabase db, $ReceiptsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> workstationId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> receiptNumber = const Value.absent(),
                Value<int> totalAmountTiyin = const Value.absent(),
                Value<int> vatAmountTiyin = const Value.absent(),
                Value<int> discountAmountTiyin = const Value.absent(),
                Value<int> changeAmountTiyin = const Value.absent(),
                Value<int> cashAmountTiyin = const Value.absent(),
                Value<int> cardAmountTiyin = const Value.absent(),
                Value<int> qrAmountTiyin = const Value.absent(),
                Value<int> debtAmountTiyin = const Value.absent(),
                Value<bool> isReturn = const Value.absent(),
                Value<String?> refundForReceiptId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> debtId = const Value.absent(),
                Value<String?> fiscalId = const Value.absent(),
                Value<String> fiscalStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                workstationId: workstationId,
                shiftId: shiftId,
                userId: userId,
                receiptNumber: receiptNumber,
                totalAmountTiyin: totalAmountTiyin,
                vatAmountTiyin: vatAmountTiyin,
                discountAmountTiyin: discountAmountTiyin,
                changeAmountTiyin: changeAmountTiyin,
                cashAmountTiyin: cashAmountTiyin,
                cardAmountTiyin: cardAmountTiyin,
                qrAmountTiyin: qrAmountTiyin,
                debtAmountTiyin: debtAmountTiyin,
                isReturn: isReturn,
                refundForReceiptId: refundForReceiptId,
                clientId: clientId,
                debtId: debtId,
                fiscalId: fiscalId,
                fiscalStatus: fiscalStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String workstationId,
                required String shiftId,
                required String userId,
                required int receiptNumber,
                required int totalAmountTiyin,
                required int vatAmountTiyin,
                Value<int> discountAmountTiyin = const Value.absent(),
                Value<int> changeAmountTiyin = const Value.absent(),
                Value<int> cashAmountTiyin = const Value.absent(),
                Value<int> cardAmountTiyin = const Value.absent(),
                Value<int> qrAmountTiyin = const Value.absent(),
                Value<int> debtAmountTiyin = const Value.absent(),
                Value<bool> isReturn = const Value.absent(),
                Value<String?> refundForReceiptId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> debtId = const Value.absent(),
                Value<String?> fiscalId = const Value.absent(),
                Value<String> fiscalStatus = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                workstationId: workstationId,
                shiftId: shiftId,
                userId: userId,
                receiptNumber: receiptNumber,
                totalAmountTiyin: totalAmountTiyin,
                vatAmountTiyin: vatAmountTiyin,
                discountAmountTiyin: discountAmountTiyin,
                changeAmountTiyin: changeAmountTiyin,
                cashAmountTiyin: cashAmountTiyin,
                cardAmountTiyin: cardAmountTiyin,
                qrAmountTiyin: qrAmountTiyin,
                debtAmountTiyin: debtAmountTiyin,
                isReturn: isReturn,
                refundForReceiptId: refundForReceiptId,
                clientId: clientId,
                debtId: debtId,
                fiscalId: fiscalId,
                fiscalStatus: fiscalStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTableTable,
      ReceiptRow,
      $$ReceiptsTableTableFilterComposer,
      $$ReceiptsTableTableOrderingComposer,
      $$ReceiptsTableTableAnnotationComposer,
      $$ReceiptsTableTableCreateCompanionBuilder,
      $$ReceiptsTableTableUpdateCompanionBuilder,
      (
        ReceiptRow,
        BaseReferences<_$AppDatabase, $ReceiptsTableTable, ReceiptRow>,
      ),
      ReceiptRow,
      PrefetchHooks Function()
    >;
typedef $$ReceiptItemsTableTableCreateCompanionBuilder =
    ReceiptItemsTableCompanion Function({
      required String id,
      required String tenantId,
      required String receiptId,
      required String productId,
      required String productName,
      Value<String?> productBarcode,
      Value<int> quantity,
      Value<int?> weightGrams,
      required int unitPriceTiyin,
      required int itemTotalTiyin,
      Value<int> discountAmountTiyin,
      Value<int> vatRate,
      Value<int> rowid,
    });
typedef $$ReceiptItemsTableTableUpdateCompanionBuilder =
    ReceiptItemsTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> receiptId,
      Value<String> productId,
      Value<String> productName,
      Value<String?> productBarcode,
      Value<int> quantity,
      Value<int?> weightGrams,
      Value<int> unitPriceTiyin,
      Value<int> itemTotalTiyin,
      Value<int> discountAmountTiyin,
      Value<int> vatRate,
      Value<int> rowid,
    });

class $$ReceiptItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTableTable> {
  $$ReceiptItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productBarcode => $composableBuilder(
    column: $table.productBarcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceTiyin => $composableBuilder(
    column: $table.unitPriceTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemTotalTiyin => $composableBuilder(
    column: $table.itemTotalTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTableTable> {
  $$ReceiptItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productBarcode => $composableBuilder(
    column: $table.productBarcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceTiyin => $composableBuilder(
    column: $table.unitPriceTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemTotalTiyin => $composableBuilder(
    column: $table.itemTotalTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTableTable> {
  $$ReceiptItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productBarcode => $composableBuilder(
    column: $table.productBarcode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPriceTiyin => $composableBuilder(
    column: $table.unitPriceTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemTotalTiyin => $composableBuilder(
    column: $table.itemTotalTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountAmountTiyin => $composableBuilder(
    column: $table.discountAmountTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);
}

class $$ReceiptItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptItemsTableTable,
          ReceiptItemRow,
          $$ReceiptItemsTableTableFilterComposer,
          $$ReceiptItemsTableTableOrderingComposer,
          $$ReceiptItemsTableTableAnnotationComposer,
          $$ReceiptItemsTableTableCreateCompanionBuilder,
          $$ReceiptItemsTableTableUpdateCompanionBuilder,
          (
            ReceiptItemRow,
            BaseReferences<
              _$AppDatabase,
              $ReceiptItemsTableTable,
              ReceiptItemRow
            >,
          ),
          ReceiptItemRow,
          PrefetchHooks Function()
        > {
  $$ReceiptItemsTableTableTableManager(
    _$AppDatabase db,
    $ReceiptItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> productBarcode = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int?> weightGrams = const Value.absent(),
                Value<int> unitPriceTiyin = const Value.absent(),
                Value<int> itemTotalTiyin = const Value.absent(),
                Value<int> discountAmountTiyin = const Value.absent(),
                Value<int> vatRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptItemsTableCompanion(
                id: id,
                tenantId: tenantId,
                receiptId: receiptId,
                productId: productId,
                productName: productName,
                productBarcode: productBarcode,
                quantity: quantity,
                weightGrams: weightGrams,
                unitPriceTiyin: unitPriceTiyin,
                itemTotalTiyin: itemTotalTiyin,
                discountAmountTiyin: discountAmountTiyin,
                vatRate: vatRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String receiptId,
                required String productId,
                required String productName,
                Value<String?> productBarcode = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int?> weightGrams = const Value.absent(),
                required int unitPriceTiyin,
                required int itemTotalTiyin,
                Value<int> discountAmountTiyin = const Value.absent(),
                Value<int> vatRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptItemsTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                receiptId: receiptId,
                productId: productId,
                productName: productName,
                productBarcode: productBarcode,
                quantity: quantity,
                weightGrams: weightGrams,
                unitPriceTiyin: unitPriceTiyin,
                itemTotalTiyin: itemTotalTiyin,
                discountAmountTiyin: discountAmountTiyin,
                vatRate: vatRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptItemsTableTable,
      ReceiptItemRow,
      $$ReceiptItemsTableTableFilterComposer,
      $$ReceiptItemsTableTableOrderingComposer,
      $$ReceiptItemsTableTableAnnotationComposer,
      $$ReceiptItemsTableTableCreateCompanionBuilder,
      $$ReceiptItemsTableTableUpdateCompanionBuilder,
      (
        ReceiptItemRow,
        BaseReferences<_$AppDatabase, $ReceiptItemsTableTable, ReceiptItemRow>,
      ),
      ReceiptItemRow,
      PrefetchHooks Function()
    >;
typedef $$ShiftsTableTableCreateCompanionBuilder =
    ShiftsTableCompanion Function({
      required String id,
      required String tenantId,
      Value<String?> storeId,
      required String workstationId,
      required String userId,
      required int shiftNumber,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
      Value<int> cashStartTiyin,
      Value<int> cashEndTiyin,
      Value<int> totalSalesTiyin,
      Value<int> totalCashTiyin,
      Value<int> totalCardTiyin,
      Value<int> totalQrTiyin,
      Value<int> totalDebtTiyin,
      Value<int> totalReturnsTiyin,
      Value<int> totalDepositsTiyin,
      Value<int> totalWithdrawalsTiyin,
      Value<int> receiptCount,
      Value<int> returnCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ShiftsTableTableUpdateCompanionBuilder =
    ShiftsTableCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String?> storeId,
      Value<String> workstationId,
      Value<String> userId,
      Value<int> shiftNumber,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
      Value<int> cashStartTiyin,
      Value<int> cashEndTiyin,
      Value<int> totalSalesTiyin,
      Value<int> totalCashTiyin,
      Value<int> totalCardTiyin,
      Value<int> totalQrTiyin,
      Value<int> totalDebtTiyin,
      Value<int> totalReturnsTiyin,
      Value<int> totalDepositsTiyin,
      Value<int> totalWithdrawalsTiyin,
      Value<int> receiptCount,
      Value<int> returnCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ShiftsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTableTable> {
  $$ShiftsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shiftNumber => $composableBuilder(
    column: $table.shiftNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashStartTiyin => $composableBuilder(
    column: $table.cashStartTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashEndTiyin => $composableBuilder(
    column: $table.cashEndTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSalesTiyin => $composableBuilder(
    column: $table.totalSalesTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCashTiyin => $composableBuilder(
    column: $table.totalCashTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCardTiyin => $composableBuilder(
    column: $table.totalCardTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQrTiyin => $composableBuilder(
    column: $table.totalQrTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDebtTiyin => $composableBuilder(
    column: $table.totalDebtTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReturnsTiyin => $composableBuilder(
    column: $table.totalReturnsTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDepositsTiyin => $composableBuilder(
    column: $table.totalDepositsTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWithdrawalsTiyin => $composableBuilder(
    column: $table.totalWithdrawalsTiyin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptCount => $composableBuilder(
    column: $table.receiptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get returnCount => $composableBuilder(
    column: $table.returnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShiftsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTableTable> {
  $$ShiftsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shiftNumber => $composableBuilder(
    column: $table.shiftNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashStartTiyin => $composableBuilder(
    column: $table.cashStartTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashEndTiyin => $composableBuilder(
    column: $table.cashEndTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSalesTiyin => $composableBuilder(
    column: $table.totalSalesTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCashTiyin => $composableBuilder(
    column: $table.totalCashTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCardTiyin => $composableBuilder(
    column: $table.totalCardTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQrTiyin => $composableBuilder(
    column: $table.totalQrTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDebtTiyin => $composableBuilder(
    column: $table.totalDebtTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReturnsTiyin => $composableBuilder(
    column: $table.totalReturnsTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDepositsTiyin => $composableBuilder(
    column: $table.totalDepositsTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWithdrawalsTiyin => $composableBuilder(
    column: $table.totalWithdrawalsTiyin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptCount => $composableBuilder(
    column: $table.receiptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get returnCount => $composableBuilder(
    column: $table.returnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTableTable> {
  $$ShiftsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get workstationId => $composableBuilder(
    column: $table.workstationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get shiftNumber => $composableBuilder(
    column: $table.shiftNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get cashStartTiyin => $composableBuilder(
    column: $table.cashStartTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashEndTiyin => $composableBuilder(
    column: $table.cashEndTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSalesTiyin => $composableBuilder(
    column: $table.totalSalesTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCashTiyin => $composableBuilder(
    column: $table.totalCashTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCardTiyin => $composableBuilder(
    column: $table.totalCardTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQrTiyin => $composableBuilder(
    column: $table.totalQrTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDebtTiyin => $composableBuilder(
    column: $table.totalDebtTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalReturnsTiyin => $composableBuilder(
    column: $table.totalReturnsTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDepositsTiyin => $composableBuilder(
    column: $table.totalDepositsTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWithdrawalsTiyin => $composableBuilder(
    column: $table.totalWithdrawalsTiyin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receiptCount => $composableBuilder(
    column: $table.receiptCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get returnCount => $composableBuilder(
    column: $table.returnCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShiftsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftsTableTable,
          ShiftRow,
          $$ShiftsTableTableFilterComposer,
          $$ShiftsTableTableOrderingComposer,
          $$ShiftsTableTableAnnotationComposer,
          $$ShiftsTableTableCreateCompanionBuilder,
          $$ShiftsTableTableUpdateCompanionBuilder,
          (
            ShiftRow,
            BaseReferences<_$AppDatabase, $ShiftsTableTable, ShiftRow>,
          ),
          ShiftRow,
          PrefetchHooks Function()
        > {
  $$ShiftsTableTableTableManager(_$AppDatabase db, $ShiftsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> workstationId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> shiftNumber = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> cashStartTiyin = const Value.absent(),
                Value<int> cashEndTiyin = const Value.absent(),
                Value<int> totalSalesTiyin = const Value.absent(),
                Value<int> totalCashTiyin = const Value.absent(),
                Value<int> totalCardTiyin = const Value.absent(),
                Value<int> totalQrTiyin = const Value.absent(),
                Value<int> totalDebtTiyin = const Value.absent(),
                Value<int> totalReturnsTiyin = const Value.absent(),
                Value<int> totalDepositsTiyin = const Value.absent(),
                Value<int> totalWithdrawalsTiyin = const Value.absent(),
                Value<int> receiptCount = const Value.absent(),
                Value<int> returnCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsTableCompanion(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                workstationId: workstationId,
                userId: userId,
                shiftNumber: shiftNumber,
                openedAt: openedAt,
                closedAt: closedAt,
                cashStartTiyin: cashStartTiyin,
                cashEndTiyin: cashEndTiyin,
                totalSalesTiyin: totalSalesTiyin,
                totalCashTiyin: totalCashTiyin,
                totalCardTiyin: totalCardTiyin,
                totalQrTiyin: totalQrTiyin,
                totalDebtTiyin: totalDebtTiyin,
                totalReturnsTiyin: totalReturnsTiyin,
                totalDepositsTiyin: totalDepositsTiyin,
                totalWithdrawalsTiyin: totalWithdrawalsTiyin,
                receiptCount: receiptCount,
                returnCount: returnCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                Value<String?> storeId = const Value.absent(),
                required String workstationId,
                required String userId,
                required int shiftNumber,
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> cashStartTiyin = const Value.absent(),
                Value<int> cashEndTiyin = const Value.absent(),
                Value<int> totalSalesTiyin = const Value.absent(),
                Value<int> totalCashTiyin = const Value.absent(),
                Value<int> totalCardTiyin = const Value.absent(),
                Value<int> totalQrTiyin = const Value.absent(),
                Value<int> totalDebtTiyin = const Value.absent(),
                Value<int> totalReturnsTiyin = const Value.absent(),
                Value<int> totalDepositsTiyin = const Value.absent(),
                Value<int> totalWithdrawalsTiyin = const Value.absent(),
                Value<int> receiptCount = const Value.absent(),
                Value<int> returnCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ShiftsTableCompanion.insert(
                id: id,
                tenantId: tenantId,
                storeId: storeId,
                workstationId: workstationId,
                userId: userId,
                shiftNumber: shiftNumber,
                openedAt: openedAt,
                closedAt: closedAt,
                cashStartTiyin: cashStartTiyin,
                cashEndTiyin: cashEndTiyin,
                totalSalesTiyin: totalSalesTiyin,
                totalCashTiyin: totalCashTiyin,
                totalCardTiyin: totalCardTiyin,
                totalQrTiyin: totalQrTiyin,
                totalDebtTiyin: totalDebtTiyin,
                totalReturnsTiyin: totalReturnsTiyin,
                totalDepositsTiyin: totalDepositsTiyin,
                totalWithdrawalsTiyin: totalWithdrawalsTiyin,
                receiptCount: receiptCount,
                returnCount: returnCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShiftsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftsTableTable,
      ShiftRow,
      $$ShiftsTableTableFilterComposer,
      $$ShiftsTableTableOrderingComposer,
      $$ShiftsTableTableAnnotationComposer,
      $$ShiftsTableTableCreateCompanionBuilder,
      $$ShiftsTableTableUpdateCompanionBuilder,
      (ShiftRow, BaseReferences<_$AppDatabase, $ShiftsTableTable, ShiftRow>),
      ShiftRow,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableTableCreateCompanionBuilder =
    SyncOutboxTableCompanion Function({
      Value<int> id,
      required String targetTable,
      required String op,
      required String uuid,
      required String payloadJson,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<int> attempts,
      Value<String?> lastError,
    });
typedef $$SyncOutboxTableTableUpdateCompanionBuilder =
    SyncOutboxTableCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> op,
      Value<String> uuid,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<int> attempts,
      Value<String?> lastError,
    });

class $$SyncOutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTableTable,
          SyncOutboxRow,
          $$SyncOutboxTableTableFilterComposer,
          $$SyncOutboxTableTableOrderingComposer,
          $$SyncOutboxTableTableAnnotationComposer,
          $$SyncOutboxTableTableCreateCompanionBuilder,
          $$SyncOutboxTableTableUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<_$AppDatabase, $SyncOutboxTableTable, SyncOutboxRow>,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableTableManager(
    _$AppDatabase db,
    $SyncOutboxTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxTableCompanion(
                id: id,
                targetTable: targetTable,
                op: op,
                uuid: uuid,
                payloadJson: payloadJson,
                createdAt: createdAt,
                syncedAt: syncedAt,
                attempts: attempts,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required String op,
                required String uuid,
                required String payloadJson,
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncOutboxTableCompanion.insert(
                id: id,
                targetTable: targetTable,
                op: op,
                uuid: uuid,
                payloadJson: payloadJson,
                createdAt: createdAt,
                syncedAt: syncedAt,
                attempts: attempts,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTableTable,
      SyncOutboxRow,
      $$SyncOutboxTableTableFilterComposer,
      $$SyncOutboxTableTableOrderingComposer,
      $$SyncOutboxTableTableAnnotationComposer,
      $$SyncOutboxTableTableCreateCompanionBuilder,
      $$SyncOutboxTableTableUpdateCompanionBuilder,
      (
        SyncOutboxRow,
        BaseReferences<_$AppDatabase, $SyncOutboxTableTable, SyncOutboxRow>,
      ),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableTableCreateCompanionBuilder =
    SyncCursorsTableCompanion Function({
      required String targetTable,
      required String cursor,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableTableUpdateCompanionBuilder =
    SyncCursorsTableCompanion Function({
      Value<String> targetTable,
      Value<String> cursor,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncCursorsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTableTable> {
  $$SyncCursorsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTableTable> {
  $$SyncCursorsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTableTable> {
  $$SyncCursorsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncCursorsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTableTable,
          SyncCursorRow,
          $$SyncCursorsTableTableFilterComposer,
          $$SyncCursorsTableTableOrderingComposer,
          $$SyncCursorsTableTableAnnotationComposer,
          $$SyncCursorsTableTableCreateCompanionBuilder,
          $$SyncCursorsTableTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<
              _$AppDatabase,
              $SyncCursorsTableTable,
              SyncCursorRow
            >,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableTableManager(
    _$AppDatabase db,
    $SyncCursorsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> targetTable = const Value.absent(),
                Value<String> cursor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsTableCompanion(
                targetTable: targetTable,
                cursor: cursor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String targetTable,
                required String cursor,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsTableCompanion.insert(
                targetTable: targetTable,
                cursor: cursor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTableTable,
      SyncCursorRow,
      $$SyncCursorsTableTableFilterComposer,
      $$SyncCursorsTableTableOrderingComposer,
      $$SyncCursorsTableTableAnnotationComposer,
      $$SyncCursorsTableTableCreateCompanionBuilder,
      $$SyncCursorsTableTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorsTableTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$SuppliersTableTableTableManager get suppliersTable =>
      $$SuppliersTableTableTableManager(_db, _db.suppliersTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$StockMovementsTableTableTableManager get stockMovementsTable =>
      $$StockMovementsTableTableTableManager(_db, _db.stockMovementsTable);
  $$ReceiptsTableTableTableManager get receiptsTable =>
      $$ReceiptsTableTableTableManager(_db, _db.receiptsTable);
  $$ReceiptItemsTableTableTableManager get receiptItemsTable =>
      $$ReceiptItemsTableTableTableManager(_db, _db.receiptItemsTable);
  $$ShiftsTableTableTableManager get shiftsTable =>
      $$ShiftsTableTableTableManager(_db, _db.shiftsTable);
  $$SyncOutboxTableTableTableManager get syncOutboxTable =>
      $$SyncOutboxTableTableTableManager(_db, _db.syncOutboxTable);
  $$SyncCursorsTableTableTableManager get syncCursorsTable =>
      $$SyncCursorsTableTableTableManager(_db, _db.syncCursorsTable);
}
