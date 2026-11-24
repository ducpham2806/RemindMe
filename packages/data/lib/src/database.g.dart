// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ListsTable extends Lists with TableInfo<$ListsTable, TaskList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInboxMeta = const VerificationMeta(
    'isInbox',
  );
  @override
  late final GeneratedColumn<bool> isInbox = GeneratedColumn<bool>(
    'is_inbox',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_inbox" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    name,
    color,
    icon,
    sortOrder,
    isInbox,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_inbox')) {
      context.handle(
        _isInboxMeta,
        isInbox.isAcceptableOrUnknown(data['is_inbox']!, _isInboxMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskList(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
      isInbox: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_inbox'],
      ),
    );
  }

  @override
  $ListsTable createAlias(String alias) {
    return $ListsTable(attachedDatabase, alias);
  }
}

class TaskList extends DataClass implements Insertable<TaskList> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String id;
  final String? name;
  final String? color;
  final String? icon;
  final int? sortOrder;
  final bool? isInbox;
  const TaskList({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.id,
    this.name,
    this.color,
    this.icon,
    this.sortOrder,
    this.isInbox,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    if (!nullToAbsent || isInbox != null) {
      map['is_inbox'] = Variable<bool>(isInbox);
    }
    return map;
  }

  ListsCompanion toCompanion(bool nullToAbsent) {
    return ListsCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      isInbox: isInbox == null && nullToAbsent
          ? const Value.absent()
          : Value(isInbox),
    );
  }

  factory TaskList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskList(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      isInbox: serializer.fromJson<bool?>(json['isInbox']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'isInbox': serializer.toJson<bool?>(isInbox),
    };
  }

  TaskList copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<int?> sortOrder = const Value.absent(),
    Value<bool?> isInbox = const Value.absent(),
  }) => TaskList(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
    isInbox: isInbox.present ? isInbox.value : this.isInbox,
  );
  TaskList copyWithCompanion(ListsCompanion data) {
    return TaskList(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isInbox: data.isInbox.present ? data.isInbox.value : this.isInbox,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskList(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isInbox: $isInbox')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    name,
    color,
    icon,
    sortOrder,
    isInbox,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskList &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.isInbox == this.isInbox);
}

class ListsCompanion extends UpdateCompanion<TaskList> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<int?> sortOrder;
  final Value<bool?> isInbox;
  final Value<int> rowid;
  const ListsCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isInbox = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListsCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String id,
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isInbox = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<TaskList> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<bool>? isInbox,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isInbox != null) 'is_inbox': isInbox,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListsCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? color,
    Value<String?>? icon,
    Value<int?>? sortOrder,
    Value<bool?>? isInbox,
    Value<int>? rowid,
  }) {
    return ListsCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isInbox: isInbox ?? this.isInbox,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isInbox.present) {
      map['is_inbox'] = Variable<bool>(isInbox.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isInbox: $isInbox, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsOnMeta = const VerificationMeta(
    'startsOn',
  );
  @override
  late final GeneratedColumn<String> startsOn = GeneratedColumn<String>(
    'starts_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    title,
    destination,
    startsOn,
    endsOn,
    coverUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('starts_on')) {
      context.handle(
        _startsOnMeta,
        startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta),
      );
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      startsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_on'],
      ),
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String id;
  final String? title;
  final String? destination;
  final String? startsOn;
  final String? endsOn;
  final String? coverUrl;
  const Trip({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.id,
    this.title,
    this.destination,
    this.startsOn,
    this.endsOn,
    this.coverUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || startsOn != null) {
      map['starts_on'] = Variable<String>(startsOn);
    }
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      startsOn: startsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(startsOn),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      destination: serializer.fromJson<String?>(json['destination']),
      startsOn: serializer.fromJson<String?>(json['startsOn']),
      endsOn: serializer.fromJson<String?>(json['endsOn']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'destination': serializer.toJson<String?>(destination),
      'startsOn': serializer.toJson<String?>(startsOn),
      'endsOn': serializer.toJson<String?>(endsOn),
      'coverUrl': serializer.toJson<String?>(coverUrl),
    };
  }

  Trip copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? id,
    Value<String?> title = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    Value<String?> startsOn = const Value.absent(),
    Value<String?> endsOn = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
  }) => Trip(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    destination: destination.present ? destination.value : this.destination,
    startsOn: startsOn.present ? startsOn.value : this.startsOn,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('destination: $destination, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('coverUrl: $coverUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    title,
    destination,
    startsOn,
    endsOn,
    coverUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.id == this.id &&
          other.title == this.title &&
          other.destination == this.destination &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.coverUrl == this.coverUrl);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> id;
  final Value<String?> title;
  final Value<String?> destination;
  final Value<String?> startsOn;
  final Value<String?> endsOn;
  final Value<String?> coverUrl;
  final Value<int> rowid;
  const TripsCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.destination = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String id,
    this.title = const Value.absent(),
    this.destination = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Trip> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? destination,
    Expression<String>? startsOn,
    Expression<String>? endsOn,
    Expression<String>? coverUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (destination != null) 'destination': destination,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? id,
    Value<String?>? title,
    Value<String?>? destination,
    Value<String?>? startsOn,
    Value<String?>? endsOn,
    Value<String?>? coverUrl,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      coverUrl: coverUrl ?? this.coverUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<String>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('destination: $destination, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportsTable extends Imports with TableInfo<$ImportsTable, Import> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docLanguageMeta = const VerificationMeta(
    'docLanguage',
  );
  @override
  late final GeneratedColumn<String> docLanguage = GeneratedColumn<String>(
    'doc_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateVersionMeta = const VerificationMeta(
    'templateVersion',
  );
  @override
  late final GeneratedColumn<int> templateVersion = GeneratedColumn<int>(
    'template_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tierUsedMeta = const VerificationMeta(
    'tierUsed',
  );
  @override
  late final GeneratedColumn<String> tierUsed = GeneratedColumn<String>(
    'tier_used',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    kind,
    sha256,
    mime,
    bytes,
    status,
    docType,
    docLanguage,
    templateId,
    templateVersion,
    tierUsed,
    originalPath,
    error,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<Import> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    }
    if (data.containsKey('doc_language')) {
      context.handle(
        _docLanguageMeta,
        docLanguage.isAcceptableOrUnknown(
          data['doc_language']!,
          _docLanguageMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_version')) {
      context.handle(
        _templateVersionMeta,
        templateVersion.isAcceptableOrUnknown(
          data['template_version']!,
          _templateVersionMeta,
        ),
      );
    }
    if (data.containsKey('tier_used')) {
      context.handle(
        _tierUsedMeta,
        tierUsed.isAcceptableOrUnknown(data['tier_used']!, _tierUsedMeta),
      );
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Import map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Import(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      ),
      docLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_language'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      templateVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_version'],
      ),
      tierUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier_used'],
      ),
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ImportsTable createAlias(String alias) {
    return $ImportsTable(attachedDatabase, alias);
  }
}

class Import extends DataClass implements Insertable<Import> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String id;
  final String? kind;
  final String? sha256;
  final String? mime;
  final int? bytes;
  final String? status;
  final String? docType;
  final String? docLanguage;
  final String? templateId;
  final int? templateVersion;
  final String? tierUsed;
  final String? originalPath;
  final String? error;
  final int? createdAt;
  const Import({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.id,
    this.kind,
    this.sha256,
    this.mime,
    this.bytes,
    this.status,
    this.docType,
    this.docLanguage,
    this.templateId,
    this.templateVersion,
    this.tierUsed,
    this.originalPath,
    this.error,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || docType != null) {
      map['doc_type'] = Variable<String>(docType);
    }
    if (!nullToAbsent || docLanguage != null) {
      map['doc_language'] = Variable<String>(docLanguage);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    if (!nullToAbsent || templateVersion != null) {
      map['template_version'] = Variable<int>(templateVersion);
    }
    if (!nullToAbsent || tierUsed != null) {
      map['tier_used'] = Variable<String>(tierUsed);
    }
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    return map;
  }

  ImportsCompanion toCompanion(bool nullToAbsent) {
    return ImportsCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      id: Value(id),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      bytes: bytes == null && nullToAbsent
          ? const Value.absent()
          : Value(bytes),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      docType: docType == null && nullToAbsent
          ? const Value.absent()
          : Value(docType),
      docLanguage: docLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(docLanguage),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      templateVersion: templateVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(templateVersion),
      tierUsed: tierUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(tierUsed),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Import.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Import(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String?>(json['kind']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      mime: serializer.fromJson<String?>(json['mime']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      status: serializer.fromJson<String?>(json['status']),
      docType: serializer.fromJson<String?>(json['docType']),
      docLanguage: serializer.fromJson<String?>(json['docLanguage']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      templateVersion: serializer.fromJson<int?>(json['templateVersion']),
      tierUsed: serializer.fromJson<String?>(json['tierUsed']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String?>(kind),
      'sha256': serializer.toJson<String?>(sha256),
      'mime': serializer.toJson<String?>(mime),
      'bytes': serializer.toJson<int?>(bytes),
      'status': serializer.toJson<String?>(status),
      'docType': serializer.toJson<String?>(docType),
      'docLanguage': serializer.toJson<String?>(docLanguage),
      'templateId': serializer.toJson<String?>(templateId),
      'templateVersion': serializer.toJson<int?>(templateVersion),
      'tierUsed': serializer.toJson<String?>(tierUsed),
      'originalPath': serializer.toJson<String?>(originalPath),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<int?>(createdAt),
    };
  }

  Import copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? id,
    Value<String?> kind = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    Value<String?> mime = const Value.absent(),
    Value<int?> bytes = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> docType = const Value.absent(),
    Value<String?> docLanguage = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
    Value<int?> templateVersion = const Value.absent(),
    Value<String?> tierUsed = const Value.absent(),
    Value<String?> originalPath = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
  }) => Import(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    id: id ?? this.id,
    kind: kind.present ? kind.value : this.kind,
    sha256: sha256.present ? sha256.value : this.sha256,
    mime: mime.present ? mime.value : this.mime,
    bytes: bytes.present ? bytes.value : this.bytes,
    status: status.present ? status.value : this.status,
    docType: docType.present ? docType.value : this.docType,
    docLanguage: docLanguage.present ? docLanguage.value : this.docLanguage,
    templateId: templateId.present ? templateId.value : this.templateId,
    templateVersion: templateVersion.present
        ? templateVersion.value
        : this.templateVersion,
    tierUsed: tierUsed.present ? tierUsed.value : this.tierUsed,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    error: error.present ? error.value : this.error,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Import copyWithCompanion(ImportsCompanion data) {
    return Import(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      mime: data.mime.present ? data.mime.value : this.mime,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      status: data.status.present ? data.status.value : this.status,
      docType: data.docType.present ? data.docType.value : this.docType,
      docLanguage: data.docLanguage.present
          ? data.docLanguage.value
          : this.docLanguage,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateVersion: data.templateVersion.present
          ? data.templateVersion.value
          : this.templateVersion,
      tierUsed: data.tierUsed.present ? data.tierUsed.value : this.tierUsed,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Import(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('docType: $docType, ')
          ..write('docLanguage: $docLanguage, ')
          ..write('templateId: $templateId, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('tierUsed: $tierUsed, ')
          ..write('originalPath: $originalPath, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    kind,
    sha256,
    mime,
    bytes,
    status,
    docType,
    docLanguage,
    templateId,
    templateVersion,
    tierUsed,
    originalPath,
    error,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Import &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.sha256 == this.sha256 &&
          other.mime == this.mime &&
          other.bytes == this.bytes &&
          other.status == this.status &&
          other.docType == this.docType &&
          other.docLanguage == this.docLanguage &&
          other.templateId == this.templateId &&
          other.templateVersion == this.templateVersion &&
          other.tierUsed == this.tierUsed &&
          other.originalPath == this.originalPath &&
          other.error == this.error &&
          other.createdAt == this.createdAt);
}

class ImportsCompanion extends UpdateCompanion<Import> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> id;
  final Value<String?> kind;
  final Value<String?> sha256;
  final Value<String?> mime;
  final Value<int?> bytes;
  final Value<String?> status;
  final Value<String?> docType;
  final Value<String?> docLanguage;
  final Value<String?> templateId;
  final Value<int?> templateVersion;
  final Value<String?> tierUsed;
  final Value<String?> originalPath;
  final Value<String?> error;
  final Value<int?> createdAt;
  final Value<int> rowid;
  const ImportsCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.mime = const Value.absent(),
    this.bytes = const Value.absent(),
    this.status = const Value.absent(),
    this.docType = const Value.absent(),
    this.docLanguage = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.tierUsed = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportsCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String id,
    this.kind = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.mime = const Value.absent(),
    this.bytes = const Value.absent(),
    this.status = const Value.absent(),
    this.docType = const Value.absent(),
    this.docLanguage = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateVersion = const Value.absent(),
    this.tierUsed = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Import> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? sha256,
    Expression<String>? mime,
    Expression<int>? bytes,
    Expression<String>? status,
    Expression<String>? docType,
    Expression<String>? docLanguage,
    Expression<String>? templateId,
    Expression<int>? templateVersion,
    Expression<String>? tierUsed,
    Expression<String>? originalPath,
    Expression<String>? error,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (sha256 != null) 'sha256': sha256,
      if (mime != null) 'mime': mime,
      if (bytes != null) 'bytes': bytes,
      if (status != null) 'status': status,
      if (docType != null) 'doc_type': docType,
      if (docLanguage != null) 'doc_language': docLanguage,
      if (templateId != null) 'template_id': templateId,
      if (templateVersion != null) 'template_version': templateVersion,
      if (tierUsed != null) 'tier_used': tierUsed,
      if (originalPath != null) 'original_path': originalPath,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportsCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? id,
    Value<String?>? kind,
    Value<String?>? sha256,
    Value<String?>? mime,
    Value<int?>? bytes,
    Value<String?>? status,
    Value<String?>? docType,
    Value<String?>? docLanguage,
    Value<String?>? templateId,
    Value<int?>? templateVersion,
    Value<String?>? tierUsed,
    Value<String?>? originalPath,
    Value<String?>? error,
    Value<int?>? createdAt,
    Value<int>? rowid,
  }) {
    return ImportsCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      sha256: sha256 ?? this.sha256,
      mime: mime ?? this.mime,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      docType: docType ?? this.docType,
      docLanguage: docLanguage ?? this.docLanguage,
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      tierUsed: tierUsed ?? this.tierUsed,
      originalPath: originalPath ?? this.originalPath,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (docLanguage.present) {
      map['doc_language'] = Variable<String>(docLanguage.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (templateVersion.present) {
      map['template_version'] = Variable<int>(templateVersion.value);
    }
    if (tierUsed.present) {
      map['tier_used'] = Variable<String>(tierUsed.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportsCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('sha256: $sha256, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('docType: $docType, ')
          ..write('docLanguage: $docLanguage, ')
          ..write('templateId: $templateId, ')
          ..write('templateVersion: $templateVersion, ')
          ..write('tierUsed: $tierUsed, ')
          ..write('originalPath: $originalPath, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importIdMeta = const VerificationMeta(
    'importId',
  );
  @override
  late final GeneratedColumn<String> importId = GeneratedColumn<String>(
    'import_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedReasonMeta = const VerificationMeta(
    'archivedReason',
  );
  @override
  late final GeneratedColumn<String> archivedReason = GeneratedColumn<String>(
    'archived_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<int> startsAt = GeneratedColumn<int>(
    'starts_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<int> endsAt = GeneratedColumn<int>(
    'ends_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
    'tz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTzMeta = const VerificationMeta('endTz');
  @override
  late final GeneratedColumn<String> endTz = GeneratedColumn<String>(
    'end_tz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeModeMeta = const VerificationMeta(
    'timeMode',
  );
  @override
  late final GeneratedColumn<String> timeMode = GeneratedColumn<String>(
    'time_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checklistMeta = const VerificationMeta(
    'checklist',
  );
  @override
  late final GeneratedColumn<String> checklist = GeneratedColumn<String>(
    'checklist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    listId,
    tripId,
    importId,
    kind,
    title,
    notes,
    status,
    archivedReason,
    priority,
    startsAt,
    endsAt,
    allDay,
    startDate,
    endDate,
    tz,
    endTz,
    timeMode,
    location,
    tags,
    source,
    sourceRef,
    checklist,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('import_id')) {
      context.handle(
        _importIdMeta,
        importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('archived_reason')) {
      context.handle(
        _archivedReasonMeta,
        archivedReason.isAcceptableOrUnknown(
          data['archived_reason']!,
          _archivedReasonMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    }
    if (data.containsKey('end_tz')) {
      context.handle(
        _endTzMeta,
        endTz.isAcceptableOrUnknown(data['end_tz']!, _endTzMeta),
      );
    }
    if (data.containsKey('time_mode')) {
      context.handle(
        _timeModeMeta,
        timeMode.isAcceptableOrUnknown(data['time_mode']!, _timeModeMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    }
    if (data.containsKey('checklist')) {
      context.handle(
        _checklistMeta,
        checklist.isAcceptableOrUnknown(data['checklist']!, _checklistMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      importId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      archivedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archived_reason'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      ),
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starts_at'],
      ),
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ends_at'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      tz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz'],
      ),
      endTz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_tz'],
      ),
      timeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_mode'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      ),
      checklist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String id;
  final String? listId;
  final String? tripId;
  final String? importId;
  final String? kind;
  final String? title;
  final String? notes;
  final String? status;
  final String? archivedReason;
  final int? priority;
  final int? startsAt;
  final int? endsAt;
  final bool? allDay;
  final String? startDate;
  final String? endDate;
  final String? tz;
  final String? endTz;
  final String? timeMode;
  final String? location;
  final String? tags;
  final String? source;
  final String? sourceRef;
  final String? checklist;
  final int? completedAt;
  const Item({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.id,
    this.listId,
    this.tripId,
    this.importId,
    this.kind,
    this.title,
    this.notes,
    this.status,
    this.archivedReason,
    this.priority,
    this.startsAt,
    this.endsAt,
    this.allDay,
    this.startDate,
    this.endDate,
    this.tz,
    this.endTz,
    this.timeMode,
    this.location,
    this.tags,
    this.source,
    this.sourceRef,
    this.checklist,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<String>(importId);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || archivedReason != null) {
      map['archived_reason'] = Variable<String>(archivedReason);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<int>(priority);
    }
    if (!nullToAbsent || startsAt != null) {
      map['starts_at'] = Variable<int>(startsAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<int>(endsAt);
    }
    if (!nullToAbsent || allDay != null) {
      map['all_day'] = Variable<bool>(allDay);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || tz != null) {
      map['tz'] = Variable<String>(tz);
    }
    if (!nullToAbsent || endTz != null) {
      map['end_tz'] = Variable<String>(endTz);
    }
    if (!nullToAbsent || timeMode != null) {
      map['time_mode'] = Variable<String>(timeMode);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || sourceRef != null) {
      map['source_ref'] = Variable<String>(sourceRef);
    }
    if (!nullToAbsent || checklist != null) {
      map['checklist'] = Variable<String>(checklist);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      id: Value(id),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      archivedReason: archivedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedReason),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      startsAt: startsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startsAt),
      endsAt: endsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAt),
      allDay: allDay == null && nullToAbsent
          ? const Value.absent()
          : Value(allDay),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      tz: tz == null && nullToAbsent ? const Value.absent() : Value(tz),
      endTz: endTz == null && nullToAbsent
          ? const Value.absent()
          : Value(endTz),
      timeMode: timeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(timeMode),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sourceRef: sourceRef == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRef),
      checklist: checklist == null && nullToAbsent
          ? const Value.absent()
          : Value(checklist),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String?>(json['listId']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      importId: serializer.fromJson<String?>(json['importId']),
      kind: serializer.fromJson<String?>(json['kind']),
      title: serializer.fromJson<String?>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String?>(json['status']),
      archivedReason: serializer.fromJson<String?>(json['archivedReason']),
      priority: serializer.fromJson<int?>(json['priority']),
      startsAt: serializer.fromJson<int?>(json['startsAt']),
      endsAt: serializer.fromJson<int?>(json['endsAt']),
      allDay: serializer.fromJson<bool?>(json['allDay']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      tz: serializer.fromJson<String?>(json['tz']),
      endTz: serializer.fromJson<String?>(json['endTz']),
      timeMode: serializer.fromJson<String?>(json['timeMode']),
      location: serializer.fromJson<String?>(json['location']),
      tags: serializer.fromJson<String?>(json['tags']),
      source: serializer.fromJson<String?>(json['source']),
      sourceRef: serializer.fromJson<String?>(json['sourceRef']),
      checklist: serializer.fromJson<String?>(json['checklist']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String?>(listId),
      'tripId': serializer.toJson<String?>(tripId),
      'importId': serializer.toJson<String?>(importId),
      'kind': serializer.toJson<String?>(kind),
      'title': serializer.toJson<String?>(title),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String?>(status),
      'archivedReason': serializer.toJson<String?>(archivedReason),
      'priority': serializer.toJson<int?>(priority),
      'startsAt': serializer.toJson<int?>(startsAt),
      'endsAt': serializer.toJson<int?>(endsAt),
      'allDay': serializer.toJson<bool?>(allDay),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'tz': serializer.toJson<String?>(tz),
      'endTz': serializer.toJson<String?>(endTz),
      'timeMode': serializer.toJson<String?>(timeMode),
      'location': serializer.toJson<String?>(location),
      'tags': serializer.toJson<String?>(tags),
      'source': serializer.toJson<String?>(source),
      'sourceRef': serializer.toJson<String?>(sourceRef),
      'checklist': serializer.toJson<String?>(checklist),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  Item copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? id,
    Value<String?> listId = const Value.absent(),
    Value<String?> tripId = const Value.absent(),
    Value<String?> importId = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> archivedReason = const Value.absent(),
    Value<int?> priority = const Value.absent(),
    Value<int?> startsAt = const Value.absent(),
    Value<int?> endsAt = const Value.absent(),
    Value<bool?> allDay = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    Value<String?> tz = const Value.absent(),
    Value<String?> endTz = const Value.absent(),
    Value<String?> timeMode = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> sourceRef = const Value.absent(),
    Value<String?> checklist = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
  }) => Item(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    id: id ?? this.id,
    listId: listId.present ? listId.value : this.listId,
    tripId: tripId.present ? tripId.value : this.tripId,
    importId: importId.present ? importId.value : this.importId,
    kind: kind.present ? kind.value : this.kind,
    title: title.present ? title.value : this.title,
    notes: notes.present ? notes.value : this.notes,
    status: status.present ? status.value : this.status,
    archivedReason: archivedReason.present
        ? archivedReason.value
        : this.archivedReason,
    priority: priority.present ? priority.value : this.priority,
    startsAt: startsAt.present ? startsAt.value : this.startsAt,
    endsAt: endsAt.present ? endsAt.value : this.endsAt,
    allDay: allDay.present ? allDay.value : this.allDay,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    tz: tz.present ? tz.value : this.tz,
    endTz: endTz.present ? endTz.value : this.endTz,
    timeMode: timeMode.present ? timeMode.value : this.timeMode,
    location: location.present ? location.value : this.location,
    tags: tags.present ? tags.value : this.tags,
    source: source.present ? source.value : this.source,
    sourceRef: sourceRef.present ? sourceRef.value : this.sourceRef,
    checklist: checklist.present ? checklist.value : this.checklist,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      importId: data.importId.present ? data.importId.value : this.importId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      archivedReason: data.archivedReason.present
          ? data.archivedReason.value
          : this.archivedReason,
      priority: data.priority.present ? data.priority.value : this.priority,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      tz: data.tz.present ? data.tz.value : this.tz,
      endTz: data.endTz.present ? data.endTz.value : this.endTz,
      timeMode: data.timeMode.present ? data.timeMode.value : this.timeMode,
      location: data.location.present ? data.location.value : this.location,
      tags: data.tags.present ? data.tags.value : this.tags,
      source: data.source.present ? data.source.value : this.source,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      checklist: data.checklist.present ? data.checklist.value : this.checklist,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('tripId: $tripId, ')
          ..write('importId: $importId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('archivedReason: $archivedReason, ')
          ..write('priority: $priority, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('allDay: $allDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('tz: $tz, ')
          ..write('endTz: $endTz, ')
          ..write('timeMode: $timeMode, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('checklist: $checklist, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    listId,
    tripId,
    importId,
    kind,
    title,
    notes,
    status,
    archivedReason,
    priority,
    startsAt,
    endsAt,
    allDay,
    startDate,
    endDate,
    tz,
    endTz,
    timeMode,
    location,
    tags,
    source,
    sourceRef,
    checklist,
    completedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.tripId == this.tripId &&
          other.importId == this.importId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.archivedReason == this.archivedReason &&
          other.priority == this.priority &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.allDay == this.allDay &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.tz == this.tz &&
          other.endTz == this.endTz &&
          other.timeMode == this.timeMode &&
          other.location == this.location &&
          other.tags == this.tags &&
          other.source == this.source &&
          other.sourceRef == this.sourceRef &&
          other.checklist == this.checklist &&
          other.completedAt == this.completedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> id;
  final Value<String?> listId;
  final Value<String?> tripId;
  final Value<String?> importId;
  final Value<String?> kind;
  final Value<String?> title;
  final Value<String?> notes;
  final Value<String?> status;
  final Value<String?> archivedReason;
  final Value<int?> priority;
  final Value<int?> startsAt;
  final Value<int?> endsAt;
  final Value<bool?> allDay;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String?> tz;
  final Value<String?> endTz;
  final Value<String?> timeMode;
  final Value<String?> location;
  final Value<String?> tags;
  final Value<String?> source;
  final Value<String?> sourceRef;
  final Value<String?> checklist;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.importId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.archivedReason = const Value.absent(),
    this.priority = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.tz = const Value.absent(),
    this.endTz = const Value.absent(),
    this.timeMode = const Value.absent(),
    this.location = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.checklist = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String id,
    this.listId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.importId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.archivedReason = const Value.absent(),
    this.priority = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.tz = const Value.absent(),
    this.endTz = const Value.absent(),
    this.timeMode = const Value.absent(),
    this.location = const Value.absent(),
    this.tags = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.checklist = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Item> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? tripId,
    Expression<String>? importId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? archivedReason,
    Expression<int>? priority,
    Expression<int>? startsAt,
    Expression<int>? endsAt,
    Expression<bool>? allDay,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? tz,
    Expression<String>? endTz,
    Expression<String>? timeMode,
    Expression<String>? location,
    Expression<String>? tags,
    Expression<String>? source,
    Expression<String>? sourceRef,
    Expression<String>? checklist,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (tripId != null) 'trip_id': tripId,
      if (importId != null) 'import_id': importId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (archivedReason != null) 'archived_reason': archivedReason,
      if (priority != null) 'priority': priority,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (allDay != null) 'all_day': allDay,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (tz != null) 'tz': tz,
      if (endTz != null) 'end_tz': endTz,
      if (timeMode != null) 'time_mode': timeMode,
      if (location != null) 'location': location,
      if (tags != null) 'tags': tags,
      if (source != null) 'source': source,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (checklist != null) 'checklist': checklist,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? id,
    Value<String?>? listId,
    Value<String?>? tripId,
    Value<String?>? importId,
    Value<String?>? kind,
    Value<String?>? title,
    Value<String?>? notes,
    Value<String?>? status,
    Value<String?>? archivedReason,
    Value<int?>? priority,
    Value<int?>? startsAt,
    Value<int?>? endsAt,
    Value<bool?>? allDay,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String?>? tz,
    Value<String?>? endTz,
    Value<String?>? timeMode,
    Value<String?>? location,
    Value<String?>? tags,
    Value<String?>? source,
    Value<String?>? sourceRef,
    Value<String?>? checklist,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      id: id ?? this.id,
      listId: listId ?? this.listId,
      tripId: tripId ?? this.tripId,
      importId: importId ?? this.importId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      archivedReason: archivedReason ?? this.archivedReason,
      priority: priority ?? this.priority,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      allDay: allDay ?? this.allDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tz: tz ?? this.tz,
      endTz: endTz ?? this.endTz,
      timeMode: timeMode ?? this.timeMode,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      sourceRef: sourceRef ?? this.sourceRef,
      checklist: checklist ?? this.checklist,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (importId.present) {
      map['import_id'] = Variable<String>(importId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (archivedReason.present) {
      map['archived_reason'] = Variable<String>(archivedReason.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<int>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<int>(endsAt.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (endTz.present) {
      map['end_tz'] = Variable<String>(endTz.value);
    }
    if (timeMode.present) {
      map['time_mode'] = Variable<String>(timeMode.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (checklist.present) {
      map['checklist'] = Variable<String>(checklist.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('tripId: $tripId, ')
          ..write('importId: $importId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('archivedReason: $archivedReason, ')
          ..write('priority: $priority, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('allDay: $allDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('tz: $tz, ')
          ..write('endTz: $endTz, ')
          ..write('timeMode: $timeMode, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('source: $source, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('checklist: $checklist, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, RecurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calendarMeta = const VerificationMeta(
    'calendar',
  );
  @override
  late final GeneratedColumn<String> calendar = GeneratedColumn<String>(
    'calendar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workdaysRegionMeta = const VerificationMeta(
    'workdaysRegion',
  );
  @override
  late final GeneratedColumn<String> workdaysRegion = GeneratedColumn<String>(
    'workdays_region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dtstartMeta = const VerificationMeta(
    'dtstart',
  );
  @override
  late final GeneratedColumn<int> dtstart = GeneratedColumn<int>(
    'dtstart',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _untilMeta = const VerificationMeta('until');
  @override
  late final GeneratedColumn<int> until = GeneratedColumn<int>(
    'until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exdatesMeta = const VerificationMeta(
    'exdates',
  );
  @override
  late final GeneratedColumn<String> exdates = GeneratedColumn<String>(
    'exdates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    kind,
    rrule,
    calendar,
    intervalDays,
    workdaysRegion,
    dtstart,
    until,
    exdates,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('calendar')) {
      context.handle(
        _calendarMeta,
        calendar.isAcceptableOrUnknown(data['calendar']!, _calendarMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('workdays_region')) {
      context.handle(
        _workdaysRegionMeta,
        workdaysRegion.isAcceptableOrUnknown(
          data['workdays_region']!,
          _workdaysRegionMeta,
        ),
      );
    }
    if (data.containsKey('dtstart')) {
      context.handle(
        _dtstartMeta,
        dtstart.isAcceptableOrUnknown(data['dtstart']!, _dtstartMeta),
      );
    }
    if (data.containsKey('until')) {
      context.handle(
        _untilMeta,
        until.isAcceptableOrUnknown(data['until']!, _untilMeta),
      );
    }
    if (data.containsKey('exdates')) {
      context.handle(
        _exdatesMeta,
        exdates.isAcceptableOrUnknown(data['exdates']!, _exdatesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  RecurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceRow(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      calendar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar'],
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      workdaysRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workdays_region'],
      ),
      dtstart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dtstart'],
      ),
      until: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}until'],
      ),
      exdates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exdates'],
      ),
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }
}

class RecurrenceRow extends DataClass implements Insertable<RecurrenceRow> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String itemId;
  final String? kind;
  final String? rrule;
  final String? calendar;
  final int? intervalDays;
  final String? workdaysRegion;
  final int? dtstart;
  final int? until;
  final String? exdates;
  const RecurrenceRow({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.itemId,
    this.kind,
    this.rrule,
    this.calendar,
    this.intervalDays,
    this.workdaysRegion,
    this.dtstart,
    this.until,
    this.exdates,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || calendar != null) {
      map['calendar'] = Variable<String>(calendar);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || workdaysRegion != null) {
      map['workdays_region'] = Variable<String>(workdaysRegion);
    }
    if (!nullToAbsent || dtstart != null) {
      map['dtstart'] = Variable<int>(dtstart);
    }
    if (!nullToAbsent || until != null) {
      map['until'] = Variable<int>(until);
    }
    if (!nullToAbsent || exdates != null) {
      map['exdates'] = Variable<String>(exdates);
    }
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      itemId: Value(itemId),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      calendar: calendar == null && nullToAbsent
          ? const Value.absent()
          : Value(calendar),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      workdaysRegion: workdaysRegion == null && nullToAbsent
          ? const Value.absent()
          : Value(workdaysRegion),
      dtstart: dtstart == null && nullToAbsent
          ? const Value.absent()
          : Value(dtstart),
      until: until == null && nullToAbsent
          ? const Value.absent()
          : Value(until),
      exdates: exdates == null && nullToAbsent
          ? const Value.absent()
          : Value(exdates),
    );
  }

  factory RecurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceRow(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      itemId: serializer.fromJson<String>(json['itemId']),
      kind: serializer.fromJson<String?>(json['kind']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      calendar: serializer.fromJson<String?>(json['calendar']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      workdaysRegion: serializer.fromJson<String?>(json['workdaysRegion']),
      dtstart: serializer.fromJson<int?>(json['dtstart']),
      until: serializer.fromJson<int?>(json['until']),
      exdates: serializer.fromJson<String?>(json['exdates']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'itemId': serializer.toJson<String>(itemId),
      'kind': serializer.toJson<String?>(kind),
      'rrule': serializer.toJson<String?>(rrule),
      'calendar': serializer.toJson<String?>(calendar),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'workdaysRegion': serializer.toJson<String?>(workdaysRegion),
      'dtstart': serializer.toJson<int?>(dtstart),
      'until': serializer.toJson<int?>(until),
      'exdates': serializer.toJson<String?>(exdates),
    };
  }

  RecurrenceRow copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? itemId,
    Value<String?> kind = const Value.absent(),
    Value<String?> rrule = const Value.absent(),
    Value<String?> calendar = const Value.absent(),
    Value<int?> intervalDays = const Value.absent(),
    Value<String?> workdaysRegion = const Value.absent(),
    Value<int?> dtstart = const Value.absent(),
    Value<int?> until = const Value.absent(),
    Value<String?> exdates = const Value.absent(),
  }) => RecurrenceRow(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    itemId: itemId ?? this.itemId,
    kind: kind.present ? kind.value : this.kind,
    rrule: rrule.present ? rrule.value : this.rrule,
    calendar: calendar.present ? calendar.value : this.calendar,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    workdaysRegion: workdaysRegion.present
        ? workdaysRegion.value
        : this.workdaysRegion,
    dtstart: dtstart.present ? dtstart.value : this.dtstart,
    until: until.present ? until.value : this.until,
    exdates: exdates.present ? exdates.value : this.exdates,
  );
  RecurrenceRow copyWithCompanion(RecurrencesCompanion data) {
    return RecurrenceRow(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      calendar: data.calendar.present ? data.calendar.value : this.calendar,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      workdaysRegion: data.workdaysRegion.present
          ? data.workdaysRegion.value
          : this.workdaysRegion,
      dtstart: data.dtstart.present ? data.dtstart.value : this.dtstart,
      until: data.until.present ? data.until.value : this.until,
      exdates: data.exdates.present ? data.exdates.value : this.exdates,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRow(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('rrule: $rrule, ')
          ..write('calendar: $calendar, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('workdaysRegion: $workdaysRegion, ')
          ..write('dtstart: $dtstart, ')
          ..write('until: $until, ')
          ..write('exdates: $exdates')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    kind,
    rrule,
    calendar,
    intervalDays,
    workdaysRegion,
    dtstart,
    until,
    exdates,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceRow &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.rrule == this.rrule &&
          other.calendar == this.calendar &&
          other.intervalDays == this.intervalDays &&
          other.workdaysRegion == this.workdaysRegion &&
          other.dtstart == this.dtstart &&
          other.until == this.until &&
          other.exdates == this.exdates);
}

class RecurrencesCompanion extends UpdateCompanion<RecurrenceRow> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> itemId;
  final Value<String?> kind;
  final Value<String?> rrule;
  final Value<String?> calendar;
  final Value<int?> intervalDays;
  final Value<String?> workdaysRegion;
  final Value<int?> dtstart;
  final Value<int?> until;
  final Value<String?> exdates;
  final Value<int> rowid;
  const RecurrencesCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.rrule = const Value.absent(),
    this.calendar = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.workdaysRegion = const Value.absent(),
    this.dtstart = const Value.absent(),
    this.until = const Value.absent(),
    this.exdates = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String itemId,
    this.kind = const Value.absent(),
    this.rrule = const Value.absent(),
    this.calendar = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.workdaysRegion = const Value.absent(),
    this.dtstart = const Value.absent(),
    this.until = const Value.absent(),
    this.exdates = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId);
  static Insertable<RecurrenceRow> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? itemId,
    Expression<String>? kind,
    Expression<String>? rrule,
    Expression<String>? calendar,
    Expression<int>? intervalDays,
    Expression<String>? workdaysRegion,
    Expression<int>? dtstart,
    Expression<int>? until,
    Expression<String>? exdates,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (rrule != null) 'rrule': rrule,
      if (calendar != null) 'calendar': calendar,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (workdaysRegion != null) 'workdays_region': workdaysRegion,
      if (dtstart != null) 'dtstart': dtstart,
      if (until != null) 'until': until,
      if (exdates != null) 'exdates': exdates,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrencesCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? itemId,
    Value<String?>? kind,
    Value<String?>? rrule,
    Value<String?>? calendar,
    Value<int?>? intervalDays,
    Value<String?>? workdaysRegion,
    Value<int?>? dtstart,
    Value<int?>? until,
    Value<String?>? exdates,
    Value<int>? rowid,
  }) {
    return RecurrencesCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      rrule: rrule ?? this.rrule,
      calendar: calendar ?? this.calendar,
      intervalDays: intervalDays ?? this.intervalDays,
      workdaysRegion: workdaysRegion ?? this.workdaysRegion,
      dtstart: dtstart ?? this.dtstart,
      until: until ?? this.until,
      exdates: exdates ?? this.exdates,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (calendar.present) {
      map['calendar'] = Variable<String>(calendar.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (workdaysRegion.present) {
      map['workdays_region'] = Variable<String>(workdaysRegion.value);
    }
    if (dtstart.present) {
      map['dtstart'] = Variable<int>(dtstart.value);
    }
    if (until.present) {
      map['until'] = Variable<int>(until.value);
    }
    if (exdates.present) {
      map['exdates'] = Variable<String>(exdates.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('rrule: $rrule, ')
          ..write('calendar: $calendar, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('workdaysRegion: $workdaysRegion, ')
          ..write('dtstart: $dtstart, ')
          ..write('until: $until, ')
          ..write('exdates: $exdates, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerKindMeta = const VerificationMeta(
    'triggerKind',
  );
  @override
  late final GeneratedColumn<String> triggerKind = GeneratedColumn<String>(
    'trigger_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geofenceMeta = const VerificationMeta(
    'geofence',
  );
  @override
  late final GeneratedColumn<String> geofence = GeneratedColumn<String>(
    'geofence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAlarmMeta = const VerificationMeta(
    'isAlarm',
  );
  @override
  late final GeneratedColumn<bool> isAlarm = GeneratedColumn<bool>(
    'is_alarm',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alarm" IN (0, 1))',
    ),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<int> snoozedUntil = GeneratedColumn<int>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    itemId,
    triggerKind,
    at,
    offsetMinutes,
    geofence,
    channel,
    isAlarm,
    snoozedUntil,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('trigger_kind')) {
      context.handle(
        _triggerKindMeta,
        triggerKind.isAcceptableOrUnknown(
          data['trigger_kind']!,
          _triggerKindMeta,
        ),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('geofence')) {
      context.handle(
        _geofenceMeta,
        geofence.isAcceptableOrUnknown(data['geofence']!, _geofenceMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('is_alarm')) {
      context.handle(
        _isAlarmMeta,
        isAlarm.isAcceptableOrUnknown(data['is_alarm']!, _isAlarmMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      triggerKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger_kind'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      ),
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      ),
      geofence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geofence'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      ),
      isAlarm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alarm'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snoozed_until'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String id;
  final String? itemId;
  final String? triggerKind;
  final int? at;
  final int? offsetMinutes;
  final String? geofence;
  final String? channel;
  final bool? isAlarm;
  final int? snoozedUntil;
  const Reminder({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.id,
    this.itemId,
    this.triggerKind,
    this.at,
    this.offsetMinutes,
    this.geofence,
    this.channel,
    this.isAlarm,
    this.snoozedUntil,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || triggerKind != null) {
      map['trigger_kind'] = Variable<String>(triggerKind);
    }
    if (!nullToAbsent || at != null) {
      map['at'] = Variable<int>(at);
    }
    if (!nullToAbsent || offsetMinutes != null) {
      map['offset_minutes'] = Variable<int>(offsetMinutes);
    }
    if (!nullToAbsent || geofence != null) {
      map['geofence'] = Variable<String>(geofence);
    }
    if (!nullToAbsent || channel != null) {
      map['channel'] = Variable<String>(channel);
    }
    if (!nullToAbsent || isAlarm != null) {
      map['is_alarm'] = Variable<bool>(isAlarm);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<int>(snoozedUntil);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      id: Value(id),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      triggerKind: triggerKind == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerKind),
      at: at == null && nullToAbsent ? const Value.absent() : Value(at),
      offsetMinutes: offsetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(offsetMinutes),
      geofence: geofence == null && nullToAbsent
          ? const Value.absent()
          : Value(geofence),
      channel: channel == null && nullToAbsent
          ? const Value.absent()
          : Value(channel),
      isAlarm: isAlarm == null && nullToAbsent
          ? const Value.absent()
          : Value(isAlarm),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      triggerKind: serializer.fromJson<String?>(json['triggerKind']),
      at: serializer.fromJson<int?>(json['at']),
      offsetMinutes: serializer.fromJson<int?>(json['offsetMinutes']),
      geofence: serializer.fromJson<String?>(json['geofence']),
      channel: serializer.fromJson<String?>(json['channel']),
      isAlarm: serializer.fromJson<bool?>(json['isAlarm']),
      snoozedUntil: serializer.fromJson<int?>(json['snoozedUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String?>(itemId),
      'triggerKind': serializer.toJson<String?>(triggerKind),
      'at': serializer.toJson<int?>(at),
      'offsetMinutes': serializer.toJson<int?>(offsetMinutes),
      'geofence': serializer.toJson<String?>(geofence),
      'channel': serializer.toJson<String?>(channel),
      'isAlarm': serializer.toJson<bool?>(isAlarm),
      'snoozedUntil': serializer.toJson<int?>(snoozedUntil),
    };
  }

  Reminder copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? id,
    Value<String?> itemId = const Value.absent(),
    Value<String?> triggerKind = const Value.absent(),
    Value<int?> at = const Value.absent(),
    Value<int?> offsetMinutes = const Value.absent(),
    Value<String?> geofence = const Value.absent(),
    Value<String?> channel = const Value.absent(),
    Value<bool?> isAlarm = const Value.absent(),
    Value<int?> snoozedUntil = const Value.absent(),
  }) => Reminder(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    id: id ?? this.id,
    itemId: itemId.present ? itemId.value : this.itemId,
    triggerKind: triggerKind.present ? triggerKind.value : this.triggerKind,
    at: at.present ? at.value : this.at,
    offsetMinutes: offsetMinutes.present
        ? offsetMinutes.value
        : this.offsetMinutes,
    geofence: geofence.present ? geofence.value : this.geofence,
    channel: channel.present ? channel.value : this.channel,
    isAlarm: isAlarm.present ? isAlarm.value : this.isAlarm,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      triggerKind: data.triggerKind.present
          ? data.triggerKind.value
          : this.triggerKind,
      at: data.at.present ? data.at.value : this.at,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      geofence: data.geofence.present ? data.geofence.value : this.geofence,
      channel: data.channel.present ? data.channel.value : this.channel,
      isAlarm: data.isAlarm.present ? data.isAlarm.value : this.isAlarm,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('triggerKind: $triggerKind, ')
          ..write('at: $at, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('geofence: $geofence, ')
          ..write('channel: $channel, ')
          ..write('isAlarm: $isAlarm, ')
          ..write('snoozedUntil: $snoozedUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    id,
    itemId,
    triggerKind,
    at,
    offsetMinutes,
    geofence,
    channel,
    isAlarm,
    snoozedUntil,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.triggerKind == this.triggerKind &&
          other.at == this.at &&
          other.offsetMinutes == this.offsetMinutes &&
          other.geofence == this.geofence &&
          other.channel == this.channel &&
          other.isAlarm == this.isAlarm &&
          other.snoozedUntil == this.snoozedUntil);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> id;
  final Value<String?> itemId;
  final Value<String?> triggerKind;
  final Value<int?> at;
  final Value<int?> offsetMinutes;
  final Value<String?> geofence;
  final Value<String?> channel;
  final Value<bool?> isAlarm;
  final Value<int?> snoozedUntil;
  final Value<int> rowid;
  const RemindersCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.triggerKind = const Value.absent(),
    this.at = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.geofence = const Value.absent(),
    this.channel = const Value.absent(),
    this.isAlarm = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String id,
    this.itemId = const Value.absent(),
    this.triggerKind = const Value.absent(),
    this.at = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.geofence = const Value.absent(),
    this.channel = const Value.absent(),
    this.isAlarm = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Reminder> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? triggerKind,
    Expression<int>? at,
    Expression<int>? offsetMinutes,
    Expression<String>? geofence,
    Expression<String>? channel,
    Expression<bool>? isAlarm,
    Expression<int>? snoozedUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (triggerKind != null) 'trigger_kind': triggerKind,
      if (at != null) 'at': at,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (geofence != null) 'geofence': geofence,
      if (channel != null) 'channel': channel,
      if (isAlarm != null) 'is_alarm': isAlarm,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? id,
    Value<String?>? itemId,
    Value<String?>? triggerKind,
    Value<int?>? at,
    Value<int?>? offsetMinutes,
    Value<String?>? geofence,
    Value<String?>? channel,
    Value<bool?>? isAlarm,
    Value<int?>? snoozedUntil,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      triggerKind: triggerKind ?? this.triggerKind,
      at: at ?? this.at,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      geofence: geofence ?? this.geofence,
      channel: channel ?? this.channel,
      isAlarm: isAlarm ?? this.isAlarm,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (triggerKind.present) {
      map['trigger_kind'] = Variable<String>(triggerKind.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (geofence.present) {
      map['geofence'] = Variable<String>(geofence.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (isAlarm.present) {
      map['is_alarm'] = Variable<bool>(isAlarm.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<int>(snoozedUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('triggerKind: $triggerKind, ')
          ..write('at: $at, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('geofence: $geofence, ')
          ..write('channel: $channel, ')
          ..write('isAlarm: $isAlarm, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookingDetailsTable extends BookingDetails
    with TableInfo<$BookingDetailsTable, BookingDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookingTypeMeta = const VerificationMeta(
    'bookingType',
  );
  @override
  late final GeneratedColumn<String> bookingType = GeneratedColumn<String>(
    'booking_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmationCodeMeta = const VerificationMeta(
    'confirmationCode',
  );
  @override
  late final GeneratedColumn<String> confirmationCode = GeneratedColumn<String>(
    'confirmation_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carrierCodeMeta = const VerificationMeta(
    'carrierCode',
  );
  @override
  late final GeneratedColumn<String> carrierCode = GeneratedColumn<String>(
    'carrier_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seatMeta = const VerificationMeta('seat');
  @override
  late final GeneratedColumn<String> seat = GeneratedColumn<String>(
    'seat',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _class_Meta = const VerificationMeta('class_');
  @override
  late final GeneratedColumn<String> class_ = GeneratedColumn<String>(
    'class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passengersMeta = const VerificationMeta(
    'passengers',
  );
  @override
  late final GeneratedColumn<String> passengers = GeneratedColumn<String>(
    'passengers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkInAtMeta = const VerificationMeta(
    'checkInAt',
  );
  @override
  late final GeneratedColumn<int> checkInAt = GeneratedColumn<int>(
    'check_in_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkOutAtMeta = const VerificationMeta(
    'checkOutAt',
  );
  @override
  late final GeneratedColumn<int> checkOutAt = GeneratedColumn<int>(
    'check_out_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractionMetaMeta = const VerificationMeta(
    'extractionMeta',
  );
  @override
  late final GeneratedColumn<String> extractionMeta = GeneratedColumn<String>(
    'extraction_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    bookingType,
    provider,
    confirmationCode,
    carrierCode,
    number,
    origin,
    destination,
    seat,
    class_,
    passengers,
    checkInAt,
    checkOutAt,
    price,
    extractionMeta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'booking_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookingDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('booking_type')) {
      context.handle(
        _bookingTypeMeta,
        bookingType.isAcceptableOrUnknown(
          data['booking_type']!,
          _bookingTypeMeta,
        ),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('confirmation_code')) {
      context.handle(
        _confirmationCodeMeta,
        confirmationCode.isAcceptableOrUnknown(
          data['confirmation_code']!,
          _confirmationCodeMeta,
        ),
      );
    }
    if (data.containsKey('carrier_code')) {
      context.handle(
        _carrierCodeMeta,
        carrierCode.isAcceptableOrUnknown(
          data['carrier_code']!,
          _carrierCodeMeta,
        ),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('seat')) {
      context.handle(
        _seatMeta,
        seat.isAcceptableOrUnknown(data['seat']!, _seatMeta),
      );
    }
    if (data.containsKey('class')) {
      context.handle(
        _class_Meta,
        class_.isAcceptableOrUnknown(data['class']!, _class_Meta),
      );
    }
    if (data.containsKey('passengers')) {
      context.handle(
        _passengersMeta,
        passengers.isAcceptableOrUnknown(data['passengers']!, _passengersMeta),
      );
    }
    if (data.containsKey('check_in_at')) {
      context.handle(
        _checkInAtMeta,
        checkInAt.isAcceptableOrUnknown(data['check_in_at']!, _checkInAtMeta),
      );
    }
    if (data.containsKey('check_out_at')) {
      context.handle(
        _checkOutAtMeta,
        checkOutAt.isAcceptableOrUnknown(
          data['check_out_at']!,
          _checkOutAtMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('extraction_meta')) {
      context.handle(
        _extractionMetaMeta,
        extractionMeta.isAcceptableOrUnknown(
          data['extraction_meta']!,
          _extractionMetaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  BookingDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookingDetail(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      bookingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_type'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      confirmationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmation_code'],
      ),
      carrierCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carrier_code'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      seat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seat'],
      ),
      class_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class'],
      ),
      passengers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passengers'],
      ),
      checkInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}check_in_at'],
      ),
      checkOutAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}check_out_at'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      ),
      extractionMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extraction_meta'],
      ),
    );
  }

  @override
  $BookingDetailsTable createAlias(String alias) {
    return $BookingDetailsTable(attachedDatabase, alias);
  }
}

class BookingDetail extends DataClass implements Insertable<BookingDetail> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String itemId;
  final String? bookingType;
  final String? provider;
  final String? confirmationCode;
  final String? carrierCode;
  final String? number;
  final String? origin;
  final String? destination;
  final String? seat;
  final String? class_;
  final String? passengers;
  final int? checkInAt;
  final int? checkOutAt;
  final String? price;
  final String? extractionMeta;
  const BookingDetail({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.itemId,
    this.bookingType,
    this.provider,
    this.confirmationCode,
    this.carrierCode,
    this.number,
    this.origin,
    this.destination,
    this.seat,
    this.class_,
    this.passengers,
    this.checkInAt,
    this.checkOutAt,
    this.price,
    this.extractionMeta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || bookingType != null) {
      map['booking_type'] = Variable<String>(bookingType);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || confirmationCode != null) {
      map['confirmation_code'] = Variable<String>(confirmationCode);
    }
    if (!nullToAbsent || carrierCode != null) {
      map['carrier_code'] = Variable<String>(carrierCode);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    if (!nullToAbsent || seat != null) {
      map['seat'] = Variable<String>(seat);
    }
    if (!nullToAbsent || class_ != null) {
      map['class'] = Variable<String>(class_);
    }
    if (!nullToAbsent || passengers != null) {
      map['passengers'] = Variable<String>(passengers);
    }
    if (!nullToAbsent || checkInAt != null) {
      map['check_in_at'] = Variable<int>(checkInAt);
    }
    if (!nullToAbsent || checkOutAt != null) {
      map['check_out_at'] = Variable<int>(checkOutAt);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<String>(price);
    }
    if (!nullToAbsent || extractionMeta != null) {
      map['extraction_meta'] = Variable<String>(extractionMeta);
    }
    return map;
  }

  BookingDetailsCompanion toCompanion(bool nullToAbsent) {
    return BookingDetailsCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      itemId: Value(itemId),
      bookingType: bookingType == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingType),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      confirmationCode: confirmationCode == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmationCode),
      carrierCode: carrierCode == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierCode),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      seat: seat == null && nullToAbsent ? const Value.absent() : Value(seat),
      class_: class_ == null && nullToAbsent
          ? const Value.absent()
          : Value(class_),
      passengers: passengers == null && nullToAbsent
          ? const Value.absent()
          : Value(passengers),
      checkInAt: checkInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInAt),
      checkOutAt: checkOutAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOutAt),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      extractionMeta: extractionMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionMeta),
    );
  }

  factory BookingDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookingDetail(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      itemId: serializer.fromJson<String>(json['itemId']),
      bookingType: serializer.fromJson<String?>(json['bookingType']),
      provider: serializer.fromJson<String?>(json['provider']),
      confirmationCode: serializer.fromJson<String?>(json['confirmationCode']),
      carrierCode: serializer.fromJson<String?>(json['carrierCode']),
      number: serializer.fromJson<String?>(json['number']),
      origin: serializer.fromJson<String?>(json['origin']),
      destination: serializer.fromJson<String?>(json['destination']),
      seat: serializer.fromJson<String?>(json['seat']),
      class_: serializer.fromJson<String?>(json['class_']),
      passengers: serializer.fromJson<String?>(json['passengers']),
      checkInAt: serializer.fromJson<int?>(json['checkInAt']),
      checkOutAt: serializer.fromJson<int?>(json['checkOutAt']),
      price: serializer.fromJson<String?>(json['price']),
      extractionMeta: serializer.fromJson<String?>(json['extractionMeta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'itemId': serializer.toJson<String>(itemId),
      'bookingType': serializer.toJson<String?>(bookingType),
      'provider': serializer.toJson<String?>(provider),
      'confirmationCode': serializer.toJson<String?>(confirmationCode),
      'carrierCode': serializer.toJson<String?>(carrierCode),
      'number': serializer.toJson<String?>(number),
      'origin': serializer.toJson<String?>(origin),
      'destination': serializer.toJson<String?>(destination),
      'seat': serializer.toJson<String?>(seat),
      'class_': serializer.toJson<String?>(class_),
      'passengers': serializer.toJson<String?>(passengers),
      'checkInAt': serializer.toJson<int?>(checkInAt),
      'checkOutAt': serializer.toJson<int?>(checkOutAt),
      'price': serializer.toJson<String?>(price),
      'extractionMeta': serializer.toJson<String?>(extractionMeta),
    };
  }

  BookingDetail copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? itemId,
    Value<String?> bookingType = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    Value<String?> confirmationCode = const Value.absent(),
    Value<String?> carrierCode = const Value.absent(),
    Value<String?> number = const Value.absent(),
    Value<String?> origin = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    Value<String?> seat = const Value.absent(),
    Value<String?> class_ = const Value.absent(),
    Value<String?> passengers = const Value.absent(),
    Value<int?> checkInAt = const Value.absent(),
    Value<int?> checkOutAt = const Value.absent(),
    Value<String?> price = const Value.absent(),
    Value<String?> extractionMeta = const Value.absent(),
  }) => BookingDetail(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    itemId: itemId ?? this.itemId,
    bookingType: bookingType.present ? bookingType.value : this.bookingType,
    provider: provider.present ? provider.value : this.provider,
    confirmationCode: confirmationCode.present
        ? confirmationCode.value
        : this.confirmationCode,
    carrierCode: carrierCode.present ? carrierCode.value : this.carrierCode,
    number: number.present ? number.value : this.number,
    origin: origin.present ? origin.value : this.origin,
    destination: destination.present ? destination.value : this.destination,
    seat: seat.present ? seat.value : this.seat,
    class_: class_.present ? class_.value : this.class_,
    passengers: passengers.present ? passengers.value : this.passengers,
    checkInAt: checkInAt.present ? checkInAt.value : this.checkInAt,
    checkOutAt: checkOutAt.present ? checkOutAt.value : this.checkOutAt,
    price: price.present ? price.value : this.price,
    extractionMeta: extractionMeta.present
        ? extractionMeta.value
        : this.extractionMeta,
  );
  BookingDetail copyWithCompanion(BookingDetailsCompanion data) {
    return BookingDetail(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      bookingType: data.bookingType.present
          ? data.bookingType.value
          : this.bookingType,
      provider: data.provider.present ? data.provider.value : this.provider,
      confirmationCode: data.confirmationCode.present
          ? data.confirmationCode.value
          : this.confirmationCode,
      carrierCode: data.carrierCode.present
          ? data.carrierCode.value
          : this.carrierCode,
      number: data.number.present ? data.number.value : this.number,
      origin: data.origin.present ? data.origin.value : this.origin,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      seat: data.seat.present ? data.seat.value : this.seat,
      class_: data.class_.present ? data.class_.value : this.class_,
      passengers: data.passengers.present
          ? data.passengers.value
          : this.passengers,
      checkInAt: data.checkInAt.present ? data.checkInAt.value : this.checkInAt,
      checkOutAt: data.checkOutAt.present
          ? data.checkOutAt.value
          : this.checkOutAt,
      price: data.price.present ? data.price.value : this.price,
      extractionMeta: data.extractionMeta.present
          ? data.extractionMeta.value
          : this.extractionMeta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookingDetail(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('bookingType: $bookingType, ')
          ..write('provider: $provider, ')
          ..write('confirmationCode: $confirmationCode, ')
          ..write('carrierCode: $carrierCode, ')
          ..write('number: $number, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('seat: $seat, ')
          ..write('class_: $class_, ')
          ..write('passengers: $passengers, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt, ')
          ..write('price: $price, ')
          ..write('extractionMeta: $extractionMeta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    bookingType,
    provider,
    confirmationCode,
    carrierCode,
    number,
    origin,
    destination,
    seat,
    class_,
    passengers,
    checkInAt,
    checkOutAt,
    price,
    extractionMeta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookingDetail &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.itemId == this.itemId &&
          other.bookingType == this.bookingType &&
          other.provider == this.provider &&
          other.confirmationCode == this.confirmationCode &&
          other.carrierCode == this.carrierCode &&
          other.number == this.number &&
          other.origin == this.origin &&
          other.destination == this.destination &&
          other.seat == this.seat &&
          other.class_ == this.class_ &&
          other.passengers == this.passengers &&
          other.checkInAt == this.checkInAt &&
          other.checkOutAt == this.checkOutAt &&
          other.price == this.price &&
          other.extractionMeta == this.extractionMeta);
}

class BookingDetailsCompanion extends UpdateCompanion<BookingDetail> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> itemId;
  final Value<String?> bookingType;
  final Value<String?> provider;
  final Value<String?> confirmationCode;
  final Value<String?> carrierCode;
  final Value<String?> number;
  final Value<String?> origin;
  final Value<String?> destination;
  final Value<String?> seat;
  final Value<String?> class_;
  final Value<String?> passengers;
  final Value<int?> checkInAt;
  final Value<int?> checkOutAt;
  final Value<String?> price;
  final Value<String?> extractionMeta;
  final Value<int> rowid;
  const BookingDetailsCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.itemId = const Value.absent(),
    this.bookingType = const Value.absent(),
    this.provider = const Value.absent(),
    this.confirmationCode = const Value.absent(),
    this.carrierCode = const Value.absent(),
    this.number = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    this.seat = const Value.absent(),
    this.class_ = const Value.absent(),
    this.passengers = const Value.absent(),
    this.checkInAt = const Value.absent(),
    this.checkOutAt = const Value.absent(),
    this.price = const Value.absent(),
    this.extractionMeta = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookingDetailsCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String itemId,
    this.bookingType = const Value.absent(),
    this.provider = const Value.absent(),
    this.confirmationCode = const Value.absent(),
    this.carrierCode = const Value.absent(),
    this.number = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    this.seat = const Value.absent(),
    this.class_ = const Value.absent(),
    this.passengers = const Value.absent(),
    this.checkInAt = const Value.absent(),
    this.checkOutAt = const Value.absent(),
    this.price = const Value.absent(),
    this.extractionMeta = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId);
  static Insertable<BookingDetail> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? itemId,
    Expression<String>? bookingType,
    Expression<String>? provider,
    Expression<String>? confirmationCode,
    Expression<String>? carrierCode,
    Expression<String>? number,
    Expression<String>? origin,
    Expression<String>? destination,
    Expression<String>? seat,
    Expression<String>? class_,
    Expression<String>? passengers,
    Expression<int>? checkInAt,
    Expression<int>? checkOutAt,
    Expression<String>? price,
    Expression<String>? extractionMeta,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (itemId != null) 'item_id': itemId,
      if (bookingType != null) 'booking_type': bookingType,
      if (provider != null) 'provider': provider,
      if (confirmationCode != null) 'confirmation_code': confirmationCode,
      if (carrierCode != null) 'carrier_code': carrierCode,
      if (number != null) 'number': number,
      if (origin != null) 'origin': origin,
      if (destination != null) 'destination': destination,
      if (seat != null) 'seat': seat,
      if (class_ != null) 'class': class_,
      if (passengers != null) 'passengers': passengers,
      if (checkInAt != null) 'check_in_at': checkInAt,
      if (checkOutAt != null) 'check_out_at': checkOutAt,
      if (price != null) 'price': price,
      if (extractionMeta != null) 'extraction_meta': extractionMeta,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookingDetailsCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? itemId,
    Value<String?>? bookingType,
    Value<String?>? provider,
    Value<String?>? confirmationCode,
    Value<String?>? carrierCode,
    Value<String?>? number,
    Value<String?>? origin,
    Value<String?>? destination,
    Value<String?>? seat,
    Value<String?>? class_,
    Value<String?>? passengers,
    Value<int?>? checkInAt,
    Value<int?>? checkOutAt,
    Value<String?>? price,
    Value<String?>? extractionMeta,
    Value<int>? rowid,
  }) {
    return BookingDetailsCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      itemId: itemId ?? this.itemId,
      bookingType: bookingType ?? this.bookingType,
      provider: provider ?? this.provider,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      carrierCode: carrierCode ?? this.carrierCode,
      number: number ?? this.number,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      seat: seat ?? this.seat,
      class_: class_ ?? this.class_,
      passengers: passengers ?? this.passengers,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      price: price ?? this.price,
      extractionMeta: extractionMeta ?? this.extractionMeta,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (bookingType.present) {
      map['booking_type'] = Variable<String>(bookingType.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (confirmationCode.present) {
      map['confirmation_code'] = Variable<String>(confirmationCode.value);
    }
    if (carrierCode.present) {
      map['carrier_code'] = Variable<String>(carrierCode.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (seat.present) {
      map['seat'] = Variable<String>(seat.value);
    }
    if (class_.present) {
      map['class'] = Variable<String>(class_.value);
    }
    if (passengers.present) {
      map['passengers'] = Variable<String>(passengers.value);
    }
    if (checkInAt.present) {
      map['check_in_at'] = Variable<int>(checkInAt.value);
    }
    if (checkOutAt.present) {
      map['check_out_at'] = Variable<int>(checkOutAt.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (extractionMeta.present) {
      map['extraction_meta'] = Variable<String>(extractionMeta.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingDetailsCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('bookingType: $bookingType, ')
          ..write('provider: $provider, ')
          ..write('confirmationCode: $confirmationCode, ')
          ..write('carrierCode: $carrierCode, ')
          ..write('number: $number, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('seat: $seat, ')
          ..write('class_: $class_, ')
          ..write('passengers: $passengers, ')
          ..write('checkInAt: $checkInAt, ')
          ..write('checkOutAt: $checkOutAt, ')
          ..write('price: $price, ')
          ..write('extractionMeta: $extractionMeta, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrenceLogTable extends OccurrenceLog
    with TableInfo<$OccurrenceLogTable, OccurrenceLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrenceLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldClockMeta = const VerificationMeta(
    'fieldClock',
  );
  @override
  late final GeneratedColumn<String> fieldClock = GeneratedColumn<String>(
    'field_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceAtMeta = const VerificationMeta(
    'occurrenceAt',
  );
  @override
  late final GeneratedColumn<int> occurrenceAt = GeneratedColumn<int>(
    'occurrence_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    occurrenceAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrence_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('field_clock')) {
      context.handle(
        _fieldClockMeta,
        fieldClock.isAcceptableOrUnknown(data['field_clock']!, _fieldClockMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('occurrence_at')) {
      context.handle(
        _occurrenceAtMeta,
        occurrenceAt.isAcceptableOrUnknown(
          data['occurrence_at']!,
          _occurrenceAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, occurrenceAt};
  @override
  OccurrenceLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceLogData(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      fieldClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_clock'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      occurrenceAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
    );
  }

  @override
  $OccurrenceLogTable createAlias(String alias) {
    return $OccurrenceLogTable(attachedDatabase, alias);
  }
}

class OccurrenceLogData extends DataClass
    implements Insertable<OccurrenceLogData> {
  final int version;
  final int? updatedAt;
  final int? deletedAt;
  final String? deviceId;
  final String fieldClock;
  final String itemId;
  final int occurrenceAt;
  final String? status;
  const OccurrenceLogData({
    required this.version,
    this.updatedAt,
    this.deletedAt,
    this.deviceId,
    required this.fieldClock,
    required this.itemId,
    required this.occurrenceAt,
    this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['field_clock'] = Variable<String>(fieldClock);
    map['item_id'] = Variable<String>(itemId);
    map['occurrence_at'] = Variable<int>(occurrenceAt);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  OccurrenceLogCompanion toCompanion(bool nullToAbsent) {
    return OccurrenceLogCompanion(
      version: Value(version),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      fieldClock: Value(fieldClock),
      itemId: Value(itemId),
      occurrenceAt: Value(occurrenceAt),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
    );
  }

  factory OccurrenceLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceLogData(
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      fieldClock: serializer.fromJson<String>(json['fieldClock']),
      itemId: serializer.fromJson<String>(json['itemId']),
      occurrenceAt: serializer.fromJson<int>(json['occurrenceAt']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'fieldClock': serializer.toJson<String>(fieldClock),
      'itemId': serializer.toJson<String>(itemId),
      'occurrenceAt': serializer.toJson<int>(occurrenceAt),
      'status': serializer.toJson<String?>(status),
    };
  }

  OccurrenceLogData copyWith({
    int? version,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    String? fieldClock,
    String? itemId,
    int? occurrenceAt,
    Value<String?> status = const Value.absent(),
  }) => OccurrenceLogData(
    version: version ?? this.version,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    fieldClock: fieldClock ?? this.fieldClock,
    itemId: itemId ?? this.itemId,
    occurrenceAt: occurrenceAt ?? this.occurrenceAt,
    status: status.present ? status.value : this.status,
  );
  OccurrenceLogData copyWithCompanion(OccurrenceLogCompanion data) {
    return OccurrenceLogData(
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      fieldClock: data.fieldClock.present
          ? data.fieldClock.value
          : this.fieldClock,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      occurrenceAt: data.occurrenceAt.present
          ? data.occurrenceAt.value
          : this.occurrenceAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceLogData(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    version,
    updatedAt,
    deletedAt,
    deviceId,
    fieldClock,
    itemId,
    occurrenceAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceLogData &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.fieldClock == this.fieldClock &&
          other.itemId == this.itemId &&
          other.occurrenceAt == this.occurrenceAt &&
          other.status == this.status);
}

class OccurrenceLogCompanion extends UpdateCompanion<OccurrenceLogData> {
  final Value<int> version;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<String> fieldClock;
  final Value<String> itemId;
  final Value<int> occurrenceAt;
  final Value<String?> status;
  final Value<int> rowid;
  const OccurrenceLogCompanion({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    this.itemId = const Value.absent(),
    this.occurrenceAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrenceLogCompanion.insert({
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.fieldClock = const Value.absent(),
    required String itemId,
    required int occurrenceAt,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       occurrenceAt = Value(occurrenceAt);
  static Insertable<OccurrenceLogData> custom({
    Expression<int>? version,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? fieldClock,
    Expression<String>? itemId,
    Expression<int>? occurrenceAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (fieldClock != null) 'field_clock': fieldClock,
      if (itemId != null) 'item_id': itemId,
      if (occurrenceAt != null) 'occurrence_at': occurrenceAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrenceLogCompanion copyWith({
    Value<int>? version,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<String?>? deviceId,
    Value<String>? fieldClock,
    Value<String>? itemId,
    Value<int>? occurrenceAt,
    Value<String?>? status,
    Value<int>? rowid,
  }) {
    return OccurrenceLogCompanion(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      fieldClock: fieldClock ?? this.fieldClock,
      itemId: itemId ?? this.itemId,
      occurrenceAt: occurrenceAt ?? this.occurrenceAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (fieldClock.present) {
      map['field_clock'] = Variable<String>(fieldClock.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (occurrenceAt.present) {
      map['occurrence_at'] = Variable<int>(occurrenceAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceLogCompanion(')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('fieldClock: $fieldClock, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mutationMeta = const VerificationMeta(
    'mutation',
  );
  @override
  late final GeneratedColumn<String> mutation = GeneratedColumn<String>(
    'mutation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [seq, mutation, createdAt, attempts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('mutation')) {
      context.handle(
        _mutationMeta,
        mutation.isAcceptableOrUnknown(data['mutation']!, _mutationMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      mutation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final int seq;

  /// JSON của `Mutation` (đúng định dạng gửi `sync_push`).
  final String mutation;
  final int createdAt;
  final int attempts;
  const OutboxEntry({
    required this.seq,
    required this.mutation,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation'] = Variable<String>(mutation);
    map['created_at'] = Variable<int>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      mutation: Value(mutation),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      seq: serializer.fromJson<int>(json['seq']),
      mutation: serializer.fromJson<String>(json['mutation']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutation': serializer.toJson<String>(mutation),
      'createdAt': serializer.toJson<int>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxEntry copyWith({
    int? seq,
    String? mutation,
    int? createdAt,
    int? attempts,
  }) => OutboxEntry(
    seq: seq ?? this.seq,
    mutation: mutation ?? this.mutation,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  OutboxEntry copyWithCompanion(OutboxCompanion data) {
    return OutboxEntry(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutation: data.mutation.present ? data.mutation.value : this.mutation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('seq: $seq, ')
          ..write('mutation: $mutation, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, mutation, createdAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.seq == this.seq &&
          other.mutation == this.mutation &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<int> seq;
  final Value<String> mutation;
  final Value<int> createdAt;
  final Value<int> attempts;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.mutation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String mutation,
    required int createdAt,
    this.attempts = const Value.absent(),
  }) : mutation = Value(mutation),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntry> custom({
    Expression<int>? seq,
    Expression<String>? mutation,
    Expression<int>? createdAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutation != null) 'mutation': mutation,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? mutation,
    Value<int>? createdAt,
    Value<int>? attempts,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      mutation: mutation ?? this.mutation,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutation.present) {
      map['mutation'] = Variable<String>(mutation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('mutation: $mutation, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateEntry extends DataClass implements Insertable<SyncStateEntry> {
  final String key;
  final String value;
  const SyncStateEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateEntry copyWith({String? key, String? value}) =>
      SyncStateEntry(key: key ?? this.key, value: value ?? this.value);
  SyncStateEntry copyWithCompanion(SyncStateCompanion data) {
    return SyncStateEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncIssuesTable extends SyncIssues
    with TableInfo<$SyncIssuesTable, SyncIssue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncIssuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tableName_Meta = const VerificationMeta(
    'tableName_',
  );
  @override
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    tableName_,
    rowId,
    kind,
    detail,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_issues';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncIssue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _tableName_Meta,
        tableName_.isAcceptableOrUnknown(data['table_name']!, _tableName_Meta),
      );
    } else if (isInserting) {
      context.missing(_tableName_Meta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  SyncIssue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncIssue(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      tableName_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncIssuesTable createAlias(String alias) {
    return $SyncIssuesTable(attachedDatabase, alias);
  }
}

class SyncIssue extends DataClass implements Insertable<SyncIssue> {
  final int seq;
  final String tableName_;
  final String rowId;

  /// quota_exceeded | invalid | notes_conflict | deleted
  final String kind;
  final String? detail;
  final int createdAt;
  const SyncIssue({
    required this.seq,
    required this.tableName_,
    required this.rowId,
    required this.kind,
    this.detail,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['table_name'] = Variable<String>(tableName_);
    map['row_id'] = Variable<String>(rowId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SyncIssuesCompanion toCompanion(bool nullToAbsent) {
    return SyncIssuesCompanion(
      seq: Value(seq),
      tableName_: Value(tableName_),
      rowId: Value(rowId),
      kind: Value(kind),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      createdAt: Value(createdAt),
    );
  }

  factory SyncIssue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncIssue(
      seq: serializer.fromJson<int>(json['seq']),
      tableName_: serializer.fromJson<String>(json['tableName_']),
      rowId: serializer.fromJson<String>(json['rowId']),
      kind: serializer.fromJson<String>(json['kind']),
      detail: serializer.fromJson<String?>(json['detail']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'tableName_': serializer.toJson<String>(tableName_),
      'rowId': serializer.toJson<String>(rowId),
      'kind': serializer.toJson<String>(kind),
      'detail': serializer.toJson<String?>(detail),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SyncIssue copyWith({
    int? seq,
    String? tableName_,
    String? rowId,
    String? kind,
    Value<String?> detail = const Value.absent(),
    int? createdAt,
  }) => SyncIssue(
    seq: seq ?? this.seq,
    tableName_: tableName_ ?? this.tableName_,
    rowId: rowId ?? this.rowId,
    kind: kind ?? this.kind,
    detail: detail.present ? detail.value : this.detail,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncIssue copyWithCompanion(SyncIssuesCompanion data) {
    return SyncIssue(
      seq: data.seq.present ? data.seq.value : this.seq,
      tableName_: data.tableName_.present
          ? data.tableName_.value
          : this.tableName_,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      kind: data.kind.present ? data.kind.value : this.kind,
      detail: data.detail.present ? data.detail.value : this.detail,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncIssue(')
          ..write('seq: $seq, ')
          ..write('tableName_: $tableName_, ')
          ..write('rowId: $rowId, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, tableName_, rowId, kind, detail, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncIssue &&
          other.seq == this.seq &&
          other.tableName_ == this.tableName_ &&
          other.rowId == this.rowId &&
          other.kind == this.kind &&
          other.detail == this.detail &&
          other.createdAt == this.createdAt);
}

class SyncIssuesCompanion extends UpdateCompanion<SyncIssue> {
  final Value<int> seq;
  final Value<String> tableName_;
  final Value<String> rowId;
  final Value<String> kind;
  final Value<String?> detail;
  final Value<int> createdAt;
  const SyncIssuesCompanion({
    this.seq = const Value.absent(),
    this.tableName_ = const Value.absent(),
    this.rowId = const Value.absent(),
    this.kind = const Value.absent(),
    this.detail = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncIssuesCompanion.insert({
    this.seq = const Value.absent(),
    required String tableName_,
    required String rowId,
    required String kind,
    this.detail = const Value.absent(),
    required int createdAt,
  }) : tableName_ = Value(tableName_),
       rowId = Value(rowId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<SyncIssue> custom({
    Expression<int>? seq,
    Expression<String>? tableName_,
    Expression<String>? rowId,
    Expression<String>? kind,
    Expression<String>? detail,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (tableName_ != null) 'table_name': tableName_,
      if (rowId != null) 'row_id': rowId,
      if (kind != null) 'kind': kind,
      if (detail != null) 'detail': detail,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncIssuesCompanion copyWith({
    Value<int>? seq,
    Value<String>? tableName_,
    Value<String>? rowId,
    Value<String>? kind,
    Value<String?>? detail,
    Value<int>? createdAt,
  }) {
    return SyncIssuesCompanion(
      seq: seq ?? this.seq,
      tableName_: tableName_ ?? this.tableName_,
      rowId: rowId ?? this.rowId,
      kind: kind ?? this.kind,
      detail: detail ?? this.detail,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncIssuesCompanion(')
          ..write('seq: $seq, ')
          ..write('tableName_: $tableName_, ')
          ..write('rowId: $rowId, ')
          ..write('kind: $kind, ')
          ..write('detail: $detail, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduledNotificationsTable extends ScheduledNotifications
    with TableInfo<$ScheduledNotificationsTable, ScheduledNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceAtMeta = const VerificationMeta(
    'occurrenceAt',
  );
  @override
  late final GeneratedColumn<int> occurrenceAt = GeneratedColumn<int>(
    'occurrence_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<int> fireAt = GeneratedColumn<int>(
    'fire_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    notificationId,
    reminderId,
    itemId,
    occurrenceAt,
    fireAt,
    contentHash,
    locale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduledNotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('occurrence_at')) {
      context.handle(
        _occurrenceAtMeta,
        occurrenceAt.isAcceptableOrUnknown(
          data['occurrence_at']!,
          _occurrenceAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceAtMeta);
    }
    if (data.containsKey('fire_at')) {
      context.handle(
        _fireAtMeta,
        fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notificationId};
  @override
  ScheduledNotificationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledNotificationRow(
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      occurrenceAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_at'],
      )!,
      fireAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fire_at'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
    );
  }

  @override
  $ScheduledNotificationsTable createAlias(String alias) {
    return $ScheduledNotificationsTable(attachedDatabase, alias);
  }
}

class ScheduledNotificationRow extends DataClass
    implements Insertable<ScheduledNotificationRow> {
  final int notificationId;
  final String reminderId;
  final String itemId;

  /// Thời điểm của lần (UTC ms) mà nhắc này thuộc về.
  final int occurrenceAt;

  /// Thời điểm kêu (UTC ms).
  final int fireAt;

  /// Hash tiêu đề + nội dung + kiểu kêu: đổi thì hủy và lập lại.
  final String contentHash;
  final String locale;
  const ScheduledNotificationRow({
    required this.notificationId,
    required this.reminderId,
    required this.itemId,
    required this.occurrenceAt,
    required this.fireAt,
    required this.contentHash,
    required this.locale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notification_id'] = Variable<int>(notificationId);
    map['reminder_id'] = Variable<String>(reminderId);
    map['item_id'] = Variable<String>(itemId);
    map['occurrence_at'] = Variable<int>(occurrenceAt);
    map['fire_at'] = Variable<int>(fireAt);
    map['content_hash'] = Variable<String>(contentHash);
    map['locale'] = Variable<String>(locale);
    return map;
  }

  ScheduledNotificationsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledNotificationsCompanion(
      notificationId: Value(notificationId),
      reminderId: Value(reminderId),
      itemId: Value(itemId),
      occurrenceAt: Value(occurrenceAt),
      fireAt: Value(fireAt),
      contentHash: Value(contentHash),
      locale: Value(locale),
    );
  }

  factory ScheduledNotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledNotificationRow(
      notificationId: serializer.fromJson<int>(json['notificationId']),
      reminderId: serializer.fromJson<String>(json['reminderId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      occurrenceAt: serializer.fromJson<int>(json['occurrenceAt']),
      fireAt: serializer.fromJson<int>(json['fireAt']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      locale: serializer.fromJson<String>(json['locale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notificationId': serializer.toJson<int>(notificationId),
      'reminderId': serializer.toJson<String>(reminderId),
      'itemId': serializer.toJson<String>(itemId),
      'occurrenceAt': serializer.toJson<int>(occurrenceAt),
      'fireAt': serializer.toJson<int>(fireAt),
      'contentHash': serializer.toJson<String>(contentHash),
      'locale': serializer.toJson<String>(locale),
    };
  }

  ScheduledNotificationRow copyWith({
    int? notificationId,
    String? reminderId,
    String? itemId,
    int? occurrenceAt,
    int? fireAt,
    String? contentHash,
    String? locale,
  }) => ScheduledNotificationRow(
    notificationId: notificationId ?? this.notificationId,
    reminderId: reminderId ?? this.reminderId,
    itemId: itemId ?? this.itemId,
    occurrenceAt: occurrenceAt ?? this.occurrenceAt,
    fireAt: fireAt ?? this.fireAt,
    contentHash: contentHash ?? this.contentHash,
    locale: locale ?? this.locale,
  );
  ScheduledNotificationRow copyWithCompanion(
    ScheduledNotificationsCompanion data,
  ) {
    return ScheduledNotificationRow(
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      occurrenceAt: data.occurrenceAt.present
          ? data.occurrenceAt.value
          : this.occurrenceAt,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      locale: data.locale.present ? data.locale.value : this.locale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationRow(')
          ..write('notificationId: $notificationId, ')
          ..write('reminderId: $reminderId, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('fireAt: $fireAt, ')
          ..write('contentHash: $contentHash, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    notificationId,
    reminderId,
    itemId,
    occurrenceAt,
    fireAt,
    contentHash,
    locale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledNotificationRow &&
          other.notificationId == this.notificationId &&
          other.reminderId == this.reminderId &&
          other.itemId == this.itemId &&
          other.occurrenceAt == this.occurrenceAt &&
          other.fireAt == this.fireAt &&
          other.contentHash == this.contentHash &&
          other.locale == this.locale);
}

class ScheduledNotificationsCompanion
    extends UpdateCompanion<ScheduledNotificationRow> {
  final Value<int> notificationId;
  final Value<String> reminderId;
  final Value<String> itemId;
  final Value<int> occurrenceAt;
  final Value<int> fireAt;
  final Value<String> contentHash;
  final Value<String> locale;
  const ScheduledNotificationsCompanion({
    this.notificationId = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.occurrenceAt = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.locale = const Value.absent(),
  });
  ScheduledNotificationsCompanion.insert({
    this.notificationId = const Value.absent(),
    required String reminderId,
    required String itemId,
    required int occurrenceAt,
    required int fireAt,
    required String contentHash,
    required String locale,
  }) : reminderId = Value(reminderId),
       itemId = Value(itemId),
       occurrenceAt = Value(occurrenceAt),
       fireAt = Value(fireAt),
       contentHash = Value(contentHash),
       locale = Value(locale);
  static Insertable<ScheduledNotificationRow> custom({
    Expression<int>? notificationId,
    Expression<String>? reminderId,
    Expression<String>? itemId,
    Expression<int>? occurrenceAt,
    Expression<int>? fireAt,
    Expression<String>? contentHash,
    Expression<String>? locale,
  }) {
    return RawValuesInsertable({
      if (notificationId != null) 'notification_id': notificationId,
      if (reminderId != null) 'reminder_id': reminderId,
      if (itemId != null) 'item_id': itemId,
      if (occurrenceAt != null) 'occurrence_at': occurrenceAt,
      if (fireAt != null) 'fire_at': fireAt,
      if (contentHash != null) 'content_hash': contentHash,
      if (locale != null) 'locale': locale,
    });
  }

  ScheduledNotificationsCompanion copyWith({
    Value<int>? notificationId,
    Value<String>? reminderId,
    Value<String>? itemId,
    Value<int>? occurrenceAt,
    Value<int>? fireAt,
    Value<String>? contentHash,
    Value<String>? locale,
  }) {
    return ScheduledNotificationsCompanion(
      notificationId: notificationId ?? this.notificationId,
      reminderId: reminderId ?? this.reminderId,
      itemId: itemId ?? this.itemId,
      occurrenceAt: occurrenceAt ?? this.occurrenceAt,
      fireAt: fireAt ?? this.fireAt,
      contentHash: contentHash ?? this.contentHash,
      locale: locale ?? this.locale,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (occurrenceAt.present) {
      map['occurrence_at'] = Variable<int>(occurrenceAt.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<int>(fireAt.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationsCompanion(')
          ..write('notificationId: $notificationId, ')
          ..write('reminderId: $reminderId, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('fireAt: $fireAt, ')
          ..write('contentHash: $contentHash, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ListsTable lists = $ListsTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $ImportsTable imports = $ImportsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $BookingDetailsTable bookingDetails = $BookingDetailsTable(this);
  late final $OccurrenceLogTable occurrenceLog = $OccurrenceLogTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SyncIssuesTable syncIssues = $SyncIssuesTable(this);
  late final $ScheduledNotificationsTable scheduledNotifications =
      $ScheduledNotificationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lists,
    trips,
    imports,
    items,
    recurrences,
    reminders,
    bookingDetails,
    occurrenceLog,
    outbox,
    syncState,
    syncIssues,
    scheduledNotifications,
  ];
}

typedef $$ListsTableCreateCompanionBuilder =
    ListsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String id,
      Value<String?> name,
      Value<String?> color,
      Value<String?> icon,
      Value<int?> sortOrder,
      Value<bool?> isInbox,
      Value<int> rowid,
    });
typedef $$ListsTableUpdateCompanionBuilder =
    ListsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> id,
      Value<String?> name,
      Value<String?> color,
      Value<String?> icon,
      Value<int?> sortOrder,
      Value<bool?> isInbox,
      Value<int> rowid,
    });

class $$ListsTableFilterComposer extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInbox => $composableBuilder(
    column: $table.isInbox,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInbox => $composableBuilder(
    column: $table.isInbox,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListsTable> {
  $$ListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isInbox =>
      $composableBuilder(column: $table.isInbox, builder: (column) => column);
}

class $$ListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListsTable,
          TaskList,
          $$ListsTableFilterComposer,
          $$ListsTableOrderingComposer,
          $$ListsTableAnnotationComposer,
          $$ListsTableCreateCompanionBuilder,
          $$ListsTableUpdateCompanionBuilder,
          (TaskList, BaseReferences<_$AppDatabase, $ListsTable, TaskList>),
          TaskList,
          PrefetchHooks Function()
        > {
  $$ListsTableTableManager(_$AppDatabase db, $ListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<bool?> isInbox = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                name: name,
                color: color,
                icon: icon,
                sortOrder: sortOrder,
                isInbox: isInbox,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<bool?> isInbox = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                name: name,
                color: color,
                icon: icon,
                sortOrder: sortOrder,
                isInbox: isInbox,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListsTable, TaskList>(table),
                  BaseReferences<_$AppDatabase, $ListsTable, TaskList>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListsTable,
      TaskList,
      $$ListsTableFilterComposer,
      $$ListsTableOrderingComposer,
      $$ListsTableAnnotationComposer,
      $$ListsTableCreateCompanionBuilder,
      $$ListsTableUpdateCompanionBuilder,
      (TaskList, BaseReferences<_$AppDatabase, $ListsTable, TaskList>),
      TaskList,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String id,
      Value<String?> title,
      Value<String?> destination,
      Value<String?> startsOn,
      Value<String?> endsOn,
      Value<String?> coverUrl,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> id,
      Value<String?> title,
      Value<String?> destination,
      Value<String?> startsOn,
      Value<String?> endsOn,
      Value<String?> coverUrl,
      Value<int> rowid,
    });

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
          Trip,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                title: title,
                destination: destination,
                startsOn: startsOn,
                endsOn: endsOn,
                coverUrl: coverUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String id,
                Value<String?> title = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                title: title,
                destination: destination,
                startsOn: startsOn,
                endsOn: endsOn,
                coverUrl: coverUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TripsTable, Trip>(table),
                  BaseReferences<_$AppDatabase, $TripsTable, Trip>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
      Trip,
      PrefetchHooks Function()
    >;
typedef $$ImportsTableCreateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String id,
      Value<String?> kind,
      Value<String?> sha256,
      Value<String?> mime,
      Value<int?> bytes,
      Value<String?> status,
      Value<String?> docType,
      Value<String?> docLanguage,
      Value<String?> templateId,
      Value<int?> templateVersion,
      Value<String?> tierUsed,
      Value<String?> originalPath,
      Value<String?> error,
      Value<int?> createdAt,
      Value<int> rowid,
    });
typedef $$ImportsTableUpdateCompanionBuilder =
    ImportsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> id,
      Value<String?> kind,
      Value<String?> sha256,
      Value<String?> mime,
      Value<int?> bytes,
      Value<String?> status,
      Value<String?> docType,
      Value<String?> docLanguage,
      Value<String?> templateId,
      Value<int?> templateVersion,
      Value<String?> tierUsed,
      Value<String?> originalPath,
      Value<String?> error,
      Value<int?> createdAt,
      Value<int> rowid,
    });

class $$ImportsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docLanguage => $composableBuilder(
    column: $table.docLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tierUsed => $composableBuilder(
    column: $table.tierUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docLanguage => $composableBuilder(
    column: $table.docLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tierUsed => $composableBuilder(
    column: $table.tierUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportsTable> {
  $$ImportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get docLanguage => $composableBuilder(
    column: $table.docLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get templateVersion => $composableBuilder(
    column: $table.templateVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tierUsed =>
      $composableBuilder(column: $table.tierUsed, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ImportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportsTable,
          Import,
          $$ImportsTableFilterComposer,
          $$ImportsTableOrderingComposer,
          $$ImportsTableAnnotationComposer,
          $$ImportsTableCreateCompanionBuilder,
          $$ImportsTableUpdateCompanionBuilder,
          (Import, BaseReferences<_$AppDatabase, $ImportsTable, Import>),
          Import,
          PrefetchHooks Function()
        > {
  $$ImportsTableTableManager(_$AppDatabase db, $ImportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> docType = const Value.absent(),
                Value<String?> docLanguage = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int?> templateVersion = const Value.absent(),
                Value<String?> tierUsed = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportsCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                kind: kind,
                sha256: sha256,
                mime: mime,
                bytes: bytes,
                status: status,
                docType: docType,
                docLanguage: docLanguage,
                templateId: templateId,
                templateVersion: templateVersion,
                tierUsed: tierUsed,
                originalPath: originalPath,
                error: error,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String id,
                Value<String?> kind = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> docType = const Value.absent(),
                Value<String?> docLanguage = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int?> templateVersion = const Value.absent(),
                Value<String?> tierUsed = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportsCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                kind: kind,
                sha256: sha256,
                mime: mime,
                bytes: bytes,
                status: status,
                docType: docType,
                docLanguage: docLanguage,
                templateId: templateId,
                templateVersion: templateVersion,
                tierUsed: tierUsed,
                originalPath: originalPath,
                error: error,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportsTable, Import>(table),
                  BaseReferences<_$AppDatabase, $ImportsTable, Import>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportsTable,
      Import,
      $$ImportsTableFilterComposer,
      $$ImportsTableOrderingComposer,
      $$ImportsTableAnnotationComposer,
      $$ImportsTableCreateCompanionBuilder,
      $$ImportsTableUpdateCompanionBuilder,
      (Import, BaseReferences<_$AppDatabase, $ImportsTable, Import>),
      Import,
      PrefetchHooks Function()
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String id,
      Value<String?> listId,
      Value<String?> tripId,
      Value<String?> importId,
      Value<String?> kind,
      Value<String?> title,
      Value<String?> notes,
      Value<String?> status,
      Value<String?> archivedReason,
      Value<int?> priority,
      Value<int?> startsAt,
      Value<int?> endsAt,
      Value<bool?> allDay,
      Value<String?> startDate,
      Value<String?> endDate,
      Value<String?> tz,
      Value<String?> endTz,
      Value<String?> timeMode,
      Value<String?> location,
      Value<String?> tags,
      Value<String?> source,
      Value<String?> sourceRef,
      Value<String?> checklist,
      Value<int?> completedAt,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> id,
      Value<String?> listId,
      Value<String?> tripId,
      Value<String?> importId,
      Value<String?> kind,
      Value<String?> title,
      Value<String?> notes,
      Value<String?> status,
      Value<String?> archivedReason,
      Value<int?> priority,
      Value<int?> startsAt,
      Value<int?> endsAt,
      Value<bool?> allDay,
      Value<String?> startDate,
      Value<String?> endDate,
      Value<String?> tz,
      Value<String?> endTz,
      Value<String?> timeMode,
      Value<String?> location,
      Value<String?> tags,
      Value<String?> source,
      Value<String?> sourceRef,
      Value<String?> checklist,
      Value<int?> completedAt,
      Value<int> rowid,
    });

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importId => $composableBuilder(
    column: $table.importId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivedReason => $composableBuilder(
    column: $table.archivedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTz => $composableBuilder(
    column: $table.endTz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeMode => $composableBuilder(
    column: $table.timeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklist => $composableBuilder(
    column: $table.checklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importId => $composableBuilder(
    column: $table.importId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedReason => $composableBuilder(
    column: $table.archivedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTz => $composableBuilder(
    column: $table.endTz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeMode => $composableBuilder(
    column: $table.timeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklist => $composableBuilder(
    column: $table.checklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get importId =>
      $composableBuilder(column: $table.importId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get archivedReason => $composableBuilder(
    column: $table.archivedReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<String> get endTz =>
      $composableBuilder(column: $table.endTz, builder: (column) => column);

  GeneratedColumn<String> get timeMode =>
      $composableBuilder(column: $table.timeMode, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<String> get checklist =>
      $composableBuilder(column: $table.checklist, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
          Item,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String?> importId = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> archivedReason = const Value.absent(),
                Value<int?> priority = const Value.absent(),
                Value<int?> startsAt = const Value.absent(),
                Value<int?> endsAt = const Value.absent(),
                Value<bool?> allDay = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> tz = const Value.absent(),
                Value<String?> endTz = const Value.absent(),
                Value<String?> timeMode = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceRef = const Value.absent(),
                Value<String?> checklist = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                listId: listId,
                tripId: tripId,
                importId: importId,
                kind: kind,
                title: title,
                notes: notes,
                status: status,
                archivedReason: archivedReason,
                priority: priority,
                startsAt: startsAt,
                endsAt: endsAt,
                allDay: allDay,
                startDate: startDate,
                endDate: endDate,
                tz: tz,
                endTz: endTz,
                timeMode: timeMode,
                location: location,
                tags: tags,
                source: source,
                sourceRef: sourceRef,
                checklist: checklist,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String id,
                Value<String?> listId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String?> importId = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> archivedReason = const Value.absent(),
                Value<int?> priority = const Value.absent(),
                Value<int?> startsAt = const Value.absent(),
                Value<int?> endsAt = const Value.absent(),
                Value<bool?> allDay = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> tz = const Value.absent(),
                Value<String?> endTz = const Value.absent(),
                Value<String?> timeMode = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceRef = const Value.absent(),
                Value<String?> checklist = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                listId: listId,
                tripId: tripId,
                importId: importId,
                kind: kind,
                title: title,
                notes: notes,
                status: status,
                archivedReason: archivedReason,
                priority: priority,
                startsAt: startsAt,
                endsAt: endsAt,
                allDay: allDay,
                startDate: startDate,
                endDate: endDate,
                tz: tz,
                endTz: endTz,
                timeMode: timeMode,
                location: location,
                tags: tags,
                source: source,
                sourceRef: sourceRef,
                checklist: checklist,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  BaseReferences<_$AppDatabase, $ItemsTable, Item>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
      Item,
      PrefetchHooks Function()
    >;
typedef $$RecurrencesTableCreateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String itemId,
      Value<String?> kind,
      Value<String?> rrule,
      Value<String?> calendar,
      Value<int?> intervalDays,
      Value<String?> workdaysRegion,
      Value<int?> dtstart,
      Value<int?> until,
      Value<String?> exdates,
      Value<int> rowid,
    });
typedef $$RecurrencesTableUpdateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> itemId,
      Value<String?> kind,
      Value<String?> rrule,
      Value<String?> calendar,
      Value<int?> intervalDays,
      Value<String?> workdaysRegion,
      Value<int?> dtstart,
      Value<int?> until,
      Value<String?> exdates,
      Value<int> rowid,
    });

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendar => $composableBuilder(
    column: $table.calendar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workdaysRegion => $composableBuilder(
    column: $table.workdaysRegion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dtstart => $composableBuilder(
    column: $table.dtstart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get until => $composableBuilder(
    column: $table.until,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exdates => $composableBuilder(
    column: $table.exdates,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendar => $composableBuilder(
    column: $table.calendar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workdaysRegion => $composableBuilder(
    column: $table.workdaysRegion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dtstart => $composableBuilder(
    column: $table.dtstart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get until => $composableBuilder(
    column: $table.until,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exdates => $composableBuilder(
    column: $table.exdates,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get calendar =>
      $composableBuilder(column: $table.calendar, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workdaysRegion => $composableBuilder(
    column: $table.workdaysRegion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dtstart =>
      $composableBuilder(column: $table.dtstart, builder: (column) => column);

  GeneratedColumn<int> get until =>
      $composableBuilder(column: $table.until, builder: (column) => column);

  GeneratedColumn<String> get exdates =>
      $composableBuilder(column: $table.exdates, builder: (column) => column);
}

class $$RecurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurrencesTable,
          RecurrenceRow,
          $$RecurrencesTableFilterComposer,
          $$RecurrencesTableOrderingComposer,
          $$RecurrencesTableAnnotationComposer,
          $$RecurrencesTableCreateCompanionBuilder,
          $$RecurrencesTableUpdateCompanionBuilder,
          (
            RecurrenceRow,
            BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
          ),
          RecurrenceRow,
          PrefetchHooks Function()
        > {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> calendar = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<String?> workdaysRegion = const Value.absent(),
                Value<int?> dtstart = const Value.absent(),
                Value<int?> until = const Value.absent(),
                Value<String?> exdates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                kind: kind,
                rrule: rrule,
                calendar: calendar,
                intervalDays: intervalDays,
                workdaysRegion: workdaysRegion,
                dtstart: dtstart,
                until: until,
                exdates: exdates,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String itemId,
                Value<String?> kind = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> calendar = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<String?> workdaysRegion = const Value.absent(),
                Value<int?> dtstart = const Value.absent(),
                Value<int?> until = const Value.absent(),
                Value<String?> exdates = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                kind: kind,
                rrule: rrule,
                calendar: calendar,
                intervalDays: intervalDays,
                workdaysRegion: workdaysRegion,
                dtstart: dtstart,
                until: until,
                exdates: exdates,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurrencesTable, RecurrenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecurrencesTable,
                    RecurrenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurrencesTable,
      RecurrenceRow,
      $$RecurrencesTableFilterComposer,
      $$RecurrencesTableOrderingComposer,
      $$RecurrencesTableAnnotationComposer,
      $$RecurrencesTableCreateCompanionBuilder,
      $$RecurrencesTableUpdateCompanionBuilder,
      (
        RecurrenceRow,
        BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
      ),
      RecurrenceRow,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String id,
      Value<String?> itemId,
      Value<String?> triggerKind,
      Value<int?> at,
      Value<int?> offsetMinutes,
      Value<String?> geofence,
      Value<String?> channel,
      Value<bool?> isAlarm,
      Value<int?> snoozedUntil,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> id,
      Value<String?> itemId,
      Value<String?> triggerKind,
      Value<int?> at,
      Value<int?> offsetMinutes,
      Value<String?> geofence,
      Value<String?> channel,
      Value<bool?> isAlarm,
      Value<int?> snoozedUntil,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerKind => $composableBuilder(
    column: $table.triggerKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geofence => $composableBuilder(
    column: $table.geofence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlarm => $composableBuilder(
    column: $table.isAlarm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerKind => $composableBuilder(
    column: $table.triggerKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geofence => $composableBuilder(
    column: $table.geofence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlarm => $composableBuilder(
    column: $table.isAlarm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get triggerKind => $composableBuilder(
    column: $table.triggerKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geofence =>
      $composableBuilder(column: $table.geofence, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<bool> get isAlarm =>
      $composableBuilder(column: $table.isAlarm, builder: (column) => column);

  GeneratedColumn<int> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> triggerKind = const Value.absent(),
                Value<int?> at = const Value.absent(),
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> geofence = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<bool?> isAlarm = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                itemId: itemId,
                triggerKind: triggerKind,
                at: at,
                offsetMinutes: offsetMinutes,
                geofence: geofence,
                channel: channel,
                isAlarm: isAlarm,
                snoozedUntil: snoozedUntil,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String id,
                Value<String?> itemId = const Value.absent(),
                Value<String?> triggerKind = const Value.absent(),
                Value<int?> at = const Value.absent(),
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> geofence = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<bool?> isAlarm = const Value.absent(),
                Value<int?> snoozedUntil = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                id: id,
                itemId: itemId,
                triggerKind: triggerKind,
                at: at,
                offsetMinutes: offsetMinutes,
                geofence: geofence,
                channel: channel,
                isAlarm: isAlarm,
                snoozedUntil: snoozedUntil,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  BaseReferences<_$AppDatabase, $RemindersTable, Reminder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$BookingDetailsTableCreateCompanionBuilder =
    BookingDetailsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String itemId,
      Value<String?> bookingType,
      Value<String?> provider,
      Value<String?> confirmationCode,
      Value<String?> carrierCode,
      Value<String?> number,
      Value<String?> origin,
      Value<String?> destination,
      Value<String?> seat,
      Value<String?> class_,
      Value<String?> passengers,
      Value<int?> checkInAt,
      Value<int?> checkOutAt,
      Value<String?> price,
      Value<String?> extractionMeta,
      Value<int> rowid,
    });
typedef $$BookingDetailsTableUpdateCompanionBuilder =
    BookingDetailsCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> itemId,
      Value<String?> bookingType,
      Value<String?> provider,
      Value<String?> confirmationCode,
      Value<String?> carrierCode,
      Value<String?> number,
      Value<String?> origin,
      Value<String?> destination,
      Value<String?> seat,
      Value<String?> class_,
      Value<String?> passengers,
      Value<int?> checkInAt,
      Value<int?> checkOutAt,
      Value<String?> price,
      Value<String?> extractionMeta,
      Value<int> rowid,
    });

class $$BookingDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $BookingDetailsTable> {
  $$BookingDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingType => $composableBuilder(
    column: $table.bookingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carrierCode => $composableBuilder(
    column: $table.carrierCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seat => $composableBuilder(
    column: $table.seat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get class_ => $composableBuilder(
    column: $table.class_,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passengers => $composableBuilder(
    column: $table.passengers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkInAt => $composableBuilder(
    column: $table.checkInAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractionMeta => $composableBuilder(
    column: $table.extractionMeta,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookingDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookingDetailsTable> {
  $$BookingDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingType => $composableBuilder(
    column: $table.bookingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carrierCode => $composableBuilder(
    column: $table.carrierCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seat => $composableBuilder(
    column: $table.seat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get class_ => $composableBuilder(
    column: $table.class_,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passengers => $composableBuilder(
    column: $table.passengers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkInAt => $composableBuilder(
    column: $table.checkInAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractionMeta => $composableBuilder(
    column: $table.extractionMeta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookingDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookingDetailsTable> {
  $$BookingDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get bookingType => $composableBuilder(
    column: $table.bookingType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carrierCode => $composableBuilder(
    column: $table.carrierCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seat =>
      $composableBuilder(column: $table.seat, builder: (column) => column);

  GeneratedColumn<String> get class_ =>
      $composableBuilder(column: $table.class_, builder: (column) => column);

  GeneratedColumn<String> get passengers => $composableBuilder(
    column: $table.passengers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get checkInAt =>
      $composableBuilder(column: $table.checkInAt, builder: (column) => column);

  GeneratedColumn<int> get checkOutAt => $composableBuilder(
    column: $table.checkOutAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get extractionMeta => $composableBuilder(
    column: $table.extractionMeta,
    builder: (column) => column,
  );
}

class $$BookingDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookingDetailsTable,
          BookingDetail,
          $$BookingDetailsTableFilterComposer,
          $$BookingDetailsTableOrderingComposer,
          $$BookingDetailsTableAnnotationComposer,
          $$BookingDetailsTableCreateCompanionBuilder,
          $$BookingDetailsTableUpdateCompanionBuilder,
          (
            BookingDetail,
            BaseReferences<_$AppDatabase, $BookingDetailsTable, BookingDetail>,
          ),
          BookingDetail,
          PrefetchHooks Function()
        > {
  $$BookingDetailsTableTableManager(
    _$AppDatabase db,
    $BookingDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> bookingType = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> confirmationCode = const Value.absent(),
                Value<String?> carrierCode = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> seat = const Value.absent(),
                Value<String?> class_ = const Value.absent(),
                Value<String?> passengers = const Value.absent(),
                Value<int?> checkInAt = const Value.absent(),
                Value<int?> checkOutAt = const Value.absent(),
                Value<String?> price = const Value.absent(),
                Value<String?> extractionMeta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingDetailsCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                bookingType: bookingType,
                provider: provider,
                confirmationCode: confirmationCode,
                carrierCode: carrierCode,
                number: number,
                origin: origin,
                destination: destination,
                seat: seat,
                class_: class_,
                passengers: passengers,
                checkInAt: checkInAt,
                checkOutAt: checkOutAt,
                price: price,
                extractionMeta: extractionMeta,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String itemId,
                Value<String?> bookingType = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> confirmationCode = const Value.absent(),
                Value<String?> carrierCode = const Value.absent(),
                Value<String?> number = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<String?> seat = const Value.absent(),
                Value<String?> class_ = const Value.absent(),
                Value<String?> passengers = const Value.absent(),
                Value<int?> checkInAt = const Value.absent(),
                Value<int?> checkOutAt = const Value.absent(),
                Value<String?> price = const Value.absent(),
                Value<String?> extractionMeta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingDetailsCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                bookingType: bookingType,
                provider: provider,
                confirmationCode: confirmationCode,
                carrierCode: carrierCode,
                number: number,
                origin: origin,
                destination: destination,
                seat: seat,
                class_: class_,
                passengers: passengers,
                checkInAt: checkInAt,
                checkOutAt: checkOutAt,
                price: price,
                extractionMeta: extractionMeta,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookingDetailsTable, BookingDetail>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BookingDetailsTable,
                    BookingDetail
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookingDetailsTable,
      BookingDetail,
      $$BookingDetailsTableFilterComposer,
      $$BookingDetailsTableOrderingComposer,
      $$BookingDetailsTableAnnotationComposer,
      $$BookingDetailsTableCreateCompanionBuilder,
      $$BookingDetailsTableUpdateCompanionBuilder,
      (
        BookingDetail,
        BaseReferences<_$AppDatabase, $BookingDetailsTable, BookingDetail>,
      ),
      BookingDetail,
      PrefetchHooks Function()
    >;
typedef $$OccurrenceLogTableCreateCompanionBuilder =
    OccurrenceLogCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      required String itemId,
      required int occurrenceAt,
      Value<String?> status,
      Value<int> rowid,
    });
typedef $$OccurrenceLogTableUpdateCompanionBuilder =
    OccurrenceLogCompanion Function({
      Value<int> version,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<String?> deviceId,
      Value<String> fieldClock,
      Value<String> itemId,
      Value<int> occurrenceAt,
      Value<String?> status,
      Value<int> rowid,
    });

class $$OccurrenceLogTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrenceLogTable> {
  $$OccurrenceLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OccurrenceLogTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrenceLogTable> {
  $$OccurrenceLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OccurrenceLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrenceLogTable> {
  $$OccurrenceLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get fieldClock => $composableBuilder(
    column: $table.fieldClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OccurrenceLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrenceLogTable,
          OccurrenceLogData,
          $$OccurrenceLogTableFilterComposer,
          $$OccurrenceLogTableOrderingComposer,
          $$OccurrenceLogTableAnnotationComposer,
          $$OccurrenceLogTableCreateCompanionBuilder,
          $$OccurrenceLogTableUpdateCompanionBuilder,
          (
            OccurrenceLogData,
            BaseReferences<
              _$AppDatabase,
              $OccurrenceLogTable,
              OccurrenceLogData
            >,
          ),
          OccurrenceLogData,
          PrefetchHooks Function()
        > {
  $$OccurrenceLogTableTableManager(_$AppDatabase db, $OccurrenceLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrenceLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrenceLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrenceLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> occurrenceAt = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceLogCompanion(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                occurrenceAt: occurrenceAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> fieldClock = const Value.absent(),
                required String itemId,
                required int occurrenceAt,
                Value<String?> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceLogCompanion.insert(
                version: version,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                fieldClock: fieldClock,
                itemId: itemId,
                occurrenceAt: occurrenceAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrenceLogTable, OccurrenceLogData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OccurrenceLogTable,
                    OccurrenceLogData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OccurrenceLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrenceLogTable,
      OccurrenceLogData,
      $$OccurrenceLogTableFilterComposer,
      $$OccurrenceLogTableOrderingComposer,
      $$OccurrenceLogTableAnnotationComposer,
      $$OccurrenceLogTableCreateCompanionBuilder,
      $$OccurrenceLogTableUpdateCompanionBuilder,
      (
        OccurrenceLogData,
        BaseReferences<_$AppDatabase, $OccurrenceLogTable, OccurrenceLogData>,
      ),
      OccurrenceLogData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      required String mutation,
      required int createdAt,
      Value<int> attempts,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      Value<String> mutation,
      Value<int> createdAt,
      Value<int> attempts,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutation => $composableBuilder(
    column: $table.mutation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutation => $composableBuilder(
    column: $table.mutation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get mutation =>
      $composableBuilder(column: $table.mutation, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxEntry,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> mutation = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                mutation: mutation,
                createdAt: createdAt,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String mutation,
                required int createdAt,
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion.insert(
                seq: seq,
                mutation: mutation,
                createdAt: createdAt,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxEntry>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxEntry,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxEntry, BaseReferences<_$AppDatabase, $OutboxTable, OutboxEntry>),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateEntry,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateEntry,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntry>,
          ),
          SyncStateEntry,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncStateTable,
                    SyncStateEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateEntry,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateEntry,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntry>,
      ),
      SyncStateEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncIssuesTableCreateCompanionBuilder =
    SyncIssuesCompanion Function({
      Value<int> seq,
      required String tableName_,
      required String rowId,
      required String kind,
      Value<String?> detail,
      required int createdAt,
    });
typedef $$SyncIssuesTableUpdateCompanionBuilder =
    SyncIssuesCompanion Function({
      Value<int> seq,
      Value<String> tableName_,
      Value<String> rowId,
      Value<String> kind,
      Value<String?> detail,
      Value<int> createdAt,
    });

class $$SyncIssuesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncIssuesTable> {
  $$SyncIssuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableName_ => $composableBuilder(
    column: $table.tableName_,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncIssuesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncIssuesTable> {
  $$SyncIssuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableName_ => $composableBuilder(
    column: $table.tableName_,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncIssuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncIssuesTable> {
  $$SyncIssuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get tableName_ => $composableBuilder(
    column: $table.tableName_,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncIssuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncIssuesTable,
          SyncIssue,
          $$SyncIssuesTableFilterComposer,
          $$SyncIssuesTableOrderingComposer,
          $$SyncIssuesTableAnnotationComposer,
          $$SyncIssuesTableCreateCompanionBuilder,
          $$SyncIssuesTableUpdateCompanionBuilder,
          (
            SyncIssue,
            BaseReferences<_$AppDatabase, $SyncIssuesTable, SyncIssue>,
          ),
          SyncIssue,
          PrefetchHooks Function()
        > {
  $$SyncIssuesTableTableManager(_$AppDatabase db, $SyncIssuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncIssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncIssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncIssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> tableName_ = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => SyncIssuesCompanion(
                seq: seq,
                tableName_: tableName_,
                rowId: rowId,
                kind: kind,
                detail: detail,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String tableName_,
                required String rowId,
                required String kind,
                Value<String?> detail = const Value.absent(),
                required int createdAt,
              }) => SyncIssuesCompanion.insert(
                seq: seq,
                tableName_: tableName_,
                rowId: rowId,
                kind: kind,
                detail: detail,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncIssuesTable, SyncIssue>(table),
                  BaseReferences<_$AppDatabase, $SyncIssuesTable, SyncIssue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncIssuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncIssuesTable,
      SyncIssue,
      $$SyncIssuesTableFilterComposer,
      $$SyncIssuesTableOrderingComposer,
      $$SyncIssuesTableAnnotationComposer,
      $$SyncIssuesTableCreateCompanionBuilder,
      $$SyncIssuesTableUpdateCompanionBuilder,
      (SyncIssue, BaseReferences<_$AppDatabase, $SyncIssuesTable, SyncIssue>),
      SyncIssue,
      PrefetchHooks Function()
    >;
typedef $$ScheduledNotificationsTableCreateCompanionBuilder =
    ScheduledNotificationsCompanion Function({
      Value<int> notificationId,
      required String reminderId,
      required String itemId,
      required int occurrenceAt,
      required int fireAt,
      required String contentHash,
      required String locale,
    });
typedef $$ScheduledNotificationsTableUpdateCompanionBuilder =
    ScheduledNotificationsCompanion Function({
      Value<int> notificationId,
      Value<String> reminderId,
      Value<String> itemId,
      Value<int> occurrenceAt,
      Value<int> fireAt,
      Value<String> contentHash,
      Value<String> locale,
    });

class $$ScheduledNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduledNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduledNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);
}

class $$ScheduledNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledNotificationsTable,
          ScheduledNotificationRow,
          $$ScheduledNotificationsTableFilterComposer,
          $$ScheduledNotificationsTableOrderingComposer,
          $$ScheduledNotificationsTableAnnotationComposer,
          $$ScheduledNotificationsTableCreateCompanionBuilder,
          $$ScheduledNotificationsTableUpdateCompanionBuilder,
          (
            ScheduledNotificationRow,
            BaseReferences<
              _$AppDatabase,
              $ScheduledNotificationsTable,
              ScheduledNotificationRow
            >,
          ),
          ScheduledNotificationRow,
          PrefetchHooks Function()
        > {
  $$ScheduledNotificationsTableTableManager(
    _$AppDatabase db,
    $ScheduledNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledNotificationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ScheduledNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ScheduledNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> notificationId = const Value.absent(),
                Value<String> reminderId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> occurrenceAt = const Value.absent(),
                Value<int> fireAt = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> locale = const Value.absent(),
              }) => ScheduledNotificationsCompanion(
                notificationId: notificationId,
                reminderId: reminderId,
                itemId: itemId,
                occurrenceAt: occurrenceAt,
                fireAt: fireAt,
                contentHash: contentHash,
                locale: locale,
              ),
          createCompanionCallback:
              ({
                Value<int> notificationId = const Value.absent(),
                required String reminderId,
                required String itemId,
                required int occurrenceAt,
                required int fireAt,
                required String contentHash,
                required String locale,
              }) => ScheduledNotificationsCompanion.insert(
                notificationId: notificationId,
                reminderId: reminderId,
                itemId: itemId,
                occurrenceAt: occurrenceAt,
                fireAt: fireAt,
                contentHash: contentHash,
                locale: locale,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ScheduledNotificationsTable,
                    ScheduledNotificationRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ScheduledNotificationsTable,
                    ScheduledNotificationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduledNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledNotificationsTable,
      ScheduledNotificationRow,
      $$ScheduledNotificationsTableFilterComposer,
      $$ScheduledNotificationsTableOrderingComposer,
      $$ScheduledNotificationsTableAnnotationComposer,
      $$ScheduledNotificationsTableCreateCompanionBuilder,
      $$ScheduledNotificationsTableUpdateCompanionBuilder,
      (
        ScheduledNotificationRow,
        BaseReferences<
          _$AppDatabase,
          $ScheduledNotificationsTable,
          ScheduledNotificationRow
        >,
      ),
      ScheduledNotificationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ListsTableTableManager get lists =>
      $$ListsTableTableManager(_db, _db.lists);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$ImportsTableTableManager get imports =>
      $$ImportsTableTableManager(_db, _db.imports);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$BookingDetailsTableTableManager get bookingDetails =>
      $$BookingDetailsTableTableManager(_db, _db.bookingDetails);
  $$OccurrenceLogTableTableManager get occurrenceLog =>
      $$OccurrenceLogTableTableManager(_db, _db.occurrenceLog);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$SyncIssuesTableTableManager get syncIssues =>
      $$SyncIssuesTableTableManager(_db, _db.syncIssues);
  $$ScheduledNotificationsTableTableManager get scheduledNotifications =>
      $$ScheduledNotificationsTableTableManager(
        _db,
        _db.scheduledNotifications,
      );
}
