// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_database.dart';

// ignore_for_file: type=lint
class $StoredServersTable extends StoredServers
    with TableInfo<$StoredServersTable, StoredServer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredServersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    username,
    password,
    accessToken,
    serverId,
    userId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredServer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessTokenMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredServer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredServer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
    );
  }

  @override
  $StoredServersTable createAlias(String alias) {
    return $StoredServersTable(attachedDatabase, alias);
  }
}

class StoredServer extends DataClass implements Insertable<StoredServer> {
  final int id;
  final String name;
  final String address;
  final String username;
  final String password;
  final String accessToken;
  final String serverId;
  final String? userId;
  const StoredServer({
    required this.id,
    required this.name,
    required this.address,
    required this.username,
    required this.password,
    required this.accessToken,
    required this.serverId,
    this.userId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['access_token'] = Variable<String>(accessToken);
    map['server_id'] = Variable<String>(serverId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    return map;
  }

  StoredServersCompanion toCompanion(bool nullToAbsent) {
    return StoredServersCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      username: Value(username),
      password: Value(password),
      accessToken: Value(accessToken),
      serverId: Value(serverId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
    );
  }

  factory StoredServer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredServer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      serverId: serializer.fromJson<String>(json['serverId']),
      userId: serializer.fromJson<String?>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'accessToken': serializer.toJson<String>(accessToken),
      'serverId': serializer.toJson<String>(serverId),
      'userId': serializer.toJson<String?>(userId),
    };
  }

  StoredServer copyWith({
    int? id,
    String? name,
    String? address,
    String? username,
    String? password,
    String? accessToken,
    String? serverId,
    Value<String?> userId = const Value.absent(),
  }) => StoredServer(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    username: username ?? this.username,
    password: password ?? this.password,
    accessToken: accessToken ?? this.accessToken,
    serverId: serverId ?? this.serverId,
    userId: userId.present ? userId.value : this.userId,
  );
  StoredServer copyWithCompanion(StoredServersCompanion data) {
    return StoredServer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredServer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('accessToken: $accessToken, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    username,
    password,
    accessToken,
    serverId,
    userId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredServer &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.username == this.username &&
          other.password == this.password &&
          other.accessToken == this.accessToken &&
          other.serverId == this.serverId &&
          other.userId == this.userId);
}

class StoredServersCompanion extends UpdateCompanion<StoredServer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> username;
  final Value<String> password;
  final Value<String> accessToken;
  final Value<String> serverId;
  final Value<String?> userId;
  const StoredServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
  });
  StoredServersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String address,
    required String username,
    required String password,
    required String accessToken,
    required String serverId,
    this.userId = const Value.absent(),
  }) : name = Value(name),
       address = Value(address),
       username = Value(username),
       password = Value(password),
       accessToken = Value(accessToken),
       serverId = Value(serverId);
  static Insertable<StoredServer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? accessToken,
    Expression<String>? serverId,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (accessToken != null) 'access_token': accessToken,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
    });
  }

  StoredServersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? username,
    Value<String>? password,
    Value<String>? accessToken,
    Value<String>? serverId,
    Value<String?>? userId,
  }) {
    return StoredServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      username: username ?? this.username,
      password: password ?? this.password,
      accessToken: accessToken ?? this.accessToken,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('accessToken: $accessToken, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

abstract class _$ServerDatabase extends GeneratedDatabase {
  _$ServerDatabase(QueryExecutor e) : super(e);
  $ServerDatabaseManager get managers => $ServerDatabaseManager(this);
  late final $StoredServersTable storedServers = $StoredServersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [storedServers];
}

typedef $$StoredServersTableCreateCompanionBuilder =
    StoredServersCompanion Function({
      Value<int> id,
      required String name,
      required String address,
      required String username,
      required String password,
      required String accessToken,
      required String serverId,
      Value<String?> userId,
    });
typedef $$StoredServersTableUpdateCompanionBuilder =
    StoredServersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> address,
      Value<String> username,
      Value<String> password,
      Value<String> accessToken,
      Value<String> serverId,
      Value<String?> userId,
    });

class $$StoredServersTableFilterComposer
    extends Composer<_$ServerDatabase, $StoredServersTable> {
  $$StoredServersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredServersTableOrderingComposer
    extends Composer<_$ServerDatabase, $StoredServersTable> {
  $$StoredServersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredServersTableAnnotationComposer
    extends Composer<_$ServerDatabase, $StoredServersTable> {
  $$StoredServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$StoredServersTableTableManager
    extends
        RootTableManager<
          _$ServerDatabase,
          $StoredServersTable,
          StoredServer,
          $$StoredServersTableFilterComposer,
          $$StoredServersTableOrderingComposer,
          $$StoredServersTableAnnotationComposer,
          $$StoredServersTableCreateCompanionBuilder,
          $$StoredServersTableUpdateCompanionBuilder,
          (
            StoredServer,
            BaseReferences<_$ServerDatabase, $StoredServersTable, StoredServer>,
          ),
          StoredServer,
          PrefetchHooks Function()
        > {
  $$StoredServersTableTableManager(
    _$ServerDatabase db,
    $StoredServersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
              }) => StoredServersCompanion(
                id: id,
                name: name,
                address: address,
                username: username,
                password: password,
                accessToken: accessToken,
                serverId: serverId,
                userId: userId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String address,
                required String username,
                required String password,
                required String accessToken,
                required String serverId,
                Value<String?> userId = const Value.absent(),
              }) => StoredServersCompanion.insert(
                id: id,
                name: name,
                address: address,
                username: username,
                password: password,
                accessToken: accessToken,
                serverId: serverId,
                userId: userId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredServersTable, StoredServer>(table),
                  BaseReferences<
                    _$ServerDatabase,
                    $StoredServersTable,
                    StoredServer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredServersTableProcessedTableManager =
    ProcessedTableManager<
      _$ServerDatabase,
      $StoredServersTable,
      StoredServer,
      $$StoredServersTableFilterComposer,
      $$StoredServersTableOrderingComposer,
      $$StoredServersTableAnnotationComposer,
      $$StoredServersTableCreateCompanionBuilder,
      $$StoredServersTableUpdateCompanionBuilder,
      (
        StoredServer,
        BaseReferences<_$ServerDatabase, $StoredServersTable, StoredServer>,
      ),
      StoredServer,
      PrefetchHooks Function()
    >;

class $ServerDatabaseManager {
  final _$ServerDatabase _db;
  $ServerDatabaseManager(this._db);
  $$StoredServersTableTableManager get storedServers =>
      $$StoredServersTableTableManager(_db, _db.storedServers);
}
