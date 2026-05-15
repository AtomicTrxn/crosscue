// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SourcesTableTable extends SourcesTable
    with TableInfo<$SourcesTableTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _homepageUrlMeta =
      const VerificationMeta('homepageUrl');
  @override
  late final GeneratedColumn<String> homepageUrl = GeneratedColumn<String>(
      'homepage_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _termsUrlMeta =
      const VerificationMeta('termsUrl');
  @override
  late final GeneratedColumn<String> termsUrl = GeneratedColumn<String>(
      'terms_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attributionMeta =
      const VerificationMeta('attribution');
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
      'attribution', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<LicenseStatus, String>
      licenseStatus = GeneratedColumn<String>(
              'license_status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('needs_review'))
          .withConverter<LicenseStatus>(
              $SourcesTableTable.$converterlicenseStatus);
  static const VerificationMeta _licenseUrlMeta =
      const VerificationMeta('licenseUrl');
  @override
  late final GeneratedColumn<String> licenseUrl = GeneratedColumn<String>(
      'license_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _permissionContactMeta =
      const VerificationMeta('permissionContact');
  @override
  late final GeneratedColumn<String> permissionContact =
      GeneratedColumn<String>('permission_contact', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attributionRequiredMeta =
      const VerificationMeta('attributionRequired');
  @override
  late final GeneratedColumn<bool> attributionRequired = GeneratedColumn<bool>(
      'attribution_required', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("attribution_required" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cachePolicyMeta =
      const VerificationMeta('cachePolicy');
  @override
  late final GeneratedColumn<String> cachePolicy = GeneratedColumn<String>(
      'cache_policy', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawPayloadRetentionMeta =
      const VerificationMeta('rawPayloadRetention');
  @override
  late final GeneratedColumn<bool> rawPayloadRetention = GeneratedColumn<bool>(
      'raw_payload_retention', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("raw_payload_retention" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _commercialUseAllowedMeta =
      const VerificationMeta('commercialUseAllowed');
  @override
  late final GeneratedColumn<bool> commercialUseAllowed = GeneratedColumn<bool>(
      'commercial_use_allowed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("commercial_use_allowed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastLegalReviewAtMeta =
      const VerificationMeta('lastLegalReviewAt');
  @override
  late final GeneratedColumn<DateTime> lastLegalReviewAt =
      GeneratedColumn<DateTime>('last_legal_review_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastCheckedAtMeta =
      const VerificationMeta('lastCheckedAt');
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>('last_checked_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSuccessAtMeta =
      const VerificationMeta('lastSuccessAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>('last_success_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
      'etag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        displayName,
        type,
        homepageUrl,
        termsUrl,
        attribution,
        enabled,
        licenseStatus,
        licenseUrl,
        permissionContact,
        attributionRequired,
        cachePolicy,
        rawPayloadRetention,
        commercialUseAllowed,
        lastLegalReviewAt,
        lastCheckedAt,
        lastSuccessAt,
        etag,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(Insertable<SourceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('homepage_url')) {
      context.handle(
          _homepageUrlMeta,
          homepageUrl.isAcceptableOrUnknown(
              data['homepage_url']!, _homepageUrlMeta));
    }
    if (data.containsKey('terms_url')) {
      context.handle(_termsUrlMeta,
          termsUrl.isAcceptableOrUnknown(data['terms_url']!, _termsUrlMeta));
    }
    if (data.containsKey('attribution')) {
      context.handle(
          _attributionMeta,
          attribution.isAcceptableOrUnknown(
              data['attribution']!, _attributionMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('license_url')) {
      context.handle(
          _licenseUrlMeta,
          licenseUrl.isAcceptableOrUnknown(
              data['license_url']!, _licenseUrlMeta));
    }
    if (data.containsKey('permission_contact')) {
      context.handle(
          _permissionContactMeta,
          permissionContact.isAcceptableOrUnknown(
              data['permission_contact']!, _permissionContactMeta));
    }
    if (data.containsKey('attribution_required')) {
      context.handle(
          _attributionRequiredMeta,
          attributionRequired.isAcceptableOrUnknown(
              data['attribution_required']!, _attributionRequiredMeta));
    }
    if (data.containsKey('cache_policy')) {
      context.handle(
          _cachePolicyMeta,
          cachePolicy.isAcceptableOrUnknown(
              data['cache_policy']!, _cachePolicyMeta));
    }
    if (data.containsKey('raw_payload_retention')) {
      context.handle(
          _rawPayloadRetentionMeta,
          rawPayloadRetention.isAcceptableOrUnknown(
              data['raw_payload_retention']!, _rawPayloadRetentionMeta));
    }
    if (data.containsKey('commercial_use_allowed')) {
      context.handle(
          _commercialUseAllowedMeta,
          commercialUseAllowed.isAcceptableOrUnknown(
              data['commercial_use_allowed']!, _commercialUseAllowedMeta));
    }
    if (data.containsKey('last_legal_review_at')) {
      context.handle(
          _lastLegalReviewAtMeta,
          lastLegalReviewAt.isAcceptableOrUnknown(
              data['last_legal_review_at']!, _lastLegalReviewAtMeta));
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
          _lastCheckedAtMeta,
          lastCheckedAt.isAcceptableOrUnknown(
              data['last_checked_at']!, _lastCheckedAtMeta));
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
          _lastSuccessAtMeta,
          lastSuccessAt.isAcceptableOrUnknown(
              data['last_success_at']!, _lastSuccessAtMeta));
    }
    if (data.containsKey('etag')) {
      context.handle(
          _etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      homepageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}homepage_url']),
      termsUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}terms_url']),
      attribution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attribution']),
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      licenseStatus: $SourcesTableTable.$converterlicenseStatus.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}license_status'])!),
      licenseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}license_url']),
      permissionContact: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}permission_contact']),
      attributionRequired: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}attribution_required'])!,
      cachePolicy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_policy']),
      rawPayloadRetention: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}raw_payload_retention'])!,
      commercialUseAllowed: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}commercial_use_allowed'])!,
      lastLegalReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_legal_review_at']),
      lastCheckedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_checked_at']),
      lastSuccessAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_success_at']),
      etag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etag']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SourcesTableTable createAlias(String alias) {
    return $SourcesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<LicenseStatus, String> $converterlicenseStatus =
      const LicenseStatusConverter();
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final String id;
  final String displayName;
  final String type;
  final String? homepageUrl;
  final String? termsUrl;
  final String? attribution;
  final bool enabled;
  final LicenseStatus licenseStatus;
  final String? licenseUrl;
  final String? permissionContact;
  final bool attributionRequired;
  final String? cachePolicy;
  final bool rawPayloadRetention;
  final bool commercialUseAllowed;
  final DateTime? lastLegalReviewAt;
  final DateTime? lastCheckedAt;
  final DateTime? lastSuccessAt;
  final String? etag;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SourceRow(
      {required this.id,
      required this.displayName,
      required this.type,
      this.homepageUrl,
      this.termsUrl,
      this.attribution,
      required this.enabled,
      required this.licenseStatus,
      this.licenseUrl,
      this.permissionContact,
      required this.attributionRequired,
      this.cachePolicy,
      required this.rawPayloadRetention,
      required this.commercialUseAllowed,
      this.lastLegalReviewAt,
      this.lastCheckedAt,
      this.lastSuccessAt,
      this.etag,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || homepageUrl != null) {
      map['homepage_url'] = Variable<String>(homepageUrl);
    }
    if (!nullToAbsent || termsUrl != null) {
      map['terms_url'] = Variable<String>(termsUrl);
    }
    if (!nullToAbsent || attribution != null) {
      map['attribution'] = Variable<String>(attribution);
    }
    map['enabled'] = Variable<bool>(enabled);
    {
      map['license_status'] = Variable<String>(
          $SourcesTableTable.$converterlicenseStatus.toSql(licenseStatus));
    }
    if (!nullToAbsent || licenseUrl != null) {
      map['license_url'] = Variable<String>(licenseUrl);
    }
    if (!nullToAbsent || permissionContact != null) {
      map['permission_contact'] = Variable<String>(permissionContact);
    }
    map['attribution_required'] = Variable<bool>(attributionRequired);
    if (!nullToAbsent || cachePolicy != null) {
      map['cache_policy'] = Variable<String>(cachePolicy);
    }
    map['raw_payload_retention'] = Variable<bool>(rawPayloadRetention);
    map['commercial_use_allowed'] = Variable<bool>(commercialUseAllowed);
    if (!nullToAbsent || lastLegalReviewAt != null) {
      map['last_legal_review_at'] = Variable<DateTime>(lastLegalReviewAt);
    }
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SourcesTableCompanion toCompanion(bool nullToAbsent) {
    return SourcesTableCompanion(
      id: Value(id),
      displayName: Value(displayName),
      type: Value(type),
      homepageUrl: homepageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(homepageUrl),
      termsUrl: termsUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(termsUrl),
      attribution: attribution == null && nullToAbsent
          ? const Value.absent()
          : Value(attribution),
      enabled: Value(enabled),
      licenseStatus: Value(licenseStatus),
      licenseUrl: licenseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseUrl),
      permissionContact: permissionContact == null && nullToAbsent
          ? const Value.absent()
          : Value(permissionContact),
      attributionRequired: Value(attributionRequired),
      cachePolicy: cachePolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(cachePolicy),
      rawPayloadRetention: Value(rawPayloadRetention),
      commercialUseAllowed: Value(commercialUseAllowed),
      lastLegalReviewAt: lastLegalReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLegalReviewAt),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      type: serializer.fromJson<String>(json['type']),
      homepageUrl: serializer.fromJson<String?>(json['homepageUrl']),
      termsUrl: serializer.fromJson<String?>(json['termsUrl']),
      attribution: serializer.fromJson<String?>(json['attribution']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      licenseStatus: serializer.fromJson<LicenseStatus>(json['licenseStatus']),
      licenseUrl: serializer.fromJson<String?>(json['licenseUrl']),
      permissionContact:
          serializer.fromJson<String?>(json['permissionContact']),
      attributionRequired:
          serializer.fromJson<bool>(json['attributionRequired']),
      cachePolicy: serializer.fromJson<String?>(json['cachePolicy']),
      rawPayloadRetention:
          serializer.fromJson<bool>(json['rawPayloadRetention']),
      commercialUseAllowed:
          serializer.fromJson<bool>(json['commercialUseAllowed']),
      lastLegalReviewAt:
          serializer.fromJson<DateTime?>(json['lastLegalReviewAt']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      etag: serializer.fromJson<String?>(json['etag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'type': serializer.toJson<String>(type),
      'homepageUrl': serializer.toJson<String?>(homepageUrl),
      'termsUrl': serializer.toJson<String?>(termsUrl),
      'attribution': serializer.toJson<String?>(attribution),
      'enabled': serializer.toJson<bool>(enabled),
      'licenseStatus': serializer.toJson<LicenseStatus>(licenseStatus),
      'licenseUrl': serializer.toJson<String?>(licenseUrl),
      'permissionContact': serializer.toJson<String?>(permissionContact),
      'attributionRequired': serializer.toJson<bool>(attributionRequired),
      'cachePolicy': serializer.toJson<String?>(cachePolicy),
      'rawPayloadRetention': serializer.toJson<bool>(rawPayloadRetention),
      'commercialUseAllowed': serializer.toJson<bool>(commercialUseAllowed),
      'lastLegalReviewAt': serializer.toJson<DateTime?>(lastLegalReviewAt),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'etag': serializer.toJson<String?>(etag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SourceRow copyWith(
          {String? id,
          String? displayName,
          String? type,
          Value<String?> homepageUrl = const Value.absent(),
          Value<String?> termsUrl = const Value.absent(),
          Value<String?> attribution = const Value.absent(),
          bool? enabled,
          LicenseStatus? licenseStatus,
          Value<String?> licenseUrl = const Value.absent(),
          Value<String?> permissionContact = const Value.absent(),
          bool? attributionRequired,
          Value<String?> cachePolicy = const Value.absent(),
          bool? rawPayloadRetention,
          bool? commercialUseAllowed,
          Value<DateTime?> lastLegalReviewAt = const Value.absent(),
          Value<DateTime?> lastCheckedAt = const Value.absent(),
          Value<DateTime?> lastSuccessAt = const Value.absent(),
          Value<String?> etag = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SourceRow(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        type: type ?? this.type,
        homepageUrl: homepageUrl.present ? homepageUrl.value : this.homepageUrl,
        termsUrl: termsUrl.present ? termsUrl.value : this.termsUrl,
        attribution: attribution.present ? attribution.value : this.attribution,
        enabled: enabled ?? this.enabled,
        licenseStatus: licenseStatus ?? this.licenseStatus,
        licenseUrl: licenseUrl.present ? licenseUrl.value : this.licenseUrl,
        permissionContact: permissionContact.present
            ? permissionContact.value
            : this.permissionContact,
        attributionRequired: attributionRequired ?? this.attributionRequired,
        cachePolicy: cachePolicy.present ? cachePolicy.value : this.cachePolicy,
        rawPayloadRetention: rawPayloadRetention ?? this.rawPayloadRetention,
        commercialUseAllowed: commercialUseAllowed ?? this.commercialUseAllowed,
        lastLegalReviewAt: lastLegalReviewAt.present
            ? lastLegalReviewAt.value
            : this.lastLegalReviewAt,
        lastCheckedAt:
            lastCheckedAt.present ? lastCheckedAt.value : this.lastCheckedAt,
        lastSuccessAt:
            lastSuccessAt.present ? lastSuccessAt.value : this.lastSuccessAt,
        etag: etag.present ? etag.value : this.etag,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SourceRow copyWithCompanion(SourcesTableCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      type: data.type.present ? data.type.value : this.type,
      homepageUrl:
          data.homepageUrl.present ? data.homepageUrl.value : this.homepageUrl,
      termsUrl: data.termsUrl.present ? data.termsUrl.value : this.termsUrl,
      attribution:
          data.attribution.present ? data.attribution.value : this.attribution,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      licenseStatus: data.licenseStatus.present
          ? data.licenseStatus.value
          : this.licenseStatus,
      licenseUrl:
          data.licenseUrl.present ? data.licenseUrl.value : this.licenseUrl,
      permissionContact: data.permissionContact.present
          ? data.permissionContact.value
          : this.permissionContact,
      attributionRequired: data.attributionRequired.present
          ? data.attributionRequired.value
          : this.attributionRequired,
      cachePolicy:
          data.cachePolicy.present ? data.cachePolicy.value : this.cachePolicy,
      rawPayloadRetention: data.rawPayloadRetention.present
          ? data.rawPayloadRetention.value
          : this.rawPayloadRetention,
      commercialUseAllowed: data.commercialUseAllowed.present
          ? data.commercialUseAllowed.value
          : this.commercialUseAllowed,
      lastLegalReviewAt: data.lastLegalReviewAt.present
          ? data.lastLegalReviewAt.value
          : this.lastLegalReviewAt,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      etag: data.etag.present ? data.etag.value : this.etag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('homepageUrl: $homepageUrl, ')
          ..write('termsUrl: $termsUrl, ')
          ..write('attribution: $attribution, ')
          ..write('enabled: $enabled, ')
          ..write('licenseStatus: $licenseStatus, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('permissionContact: $permissionContact, ')
          ..write('attributionRequired: $attributionRequired, ')
          ..write('cachePolicy: $cachePolicy, ')
          ..write('rawPayloadRetention: $rawPayloadRetention, ')
          ..write('commercialUseAllowed: $commercialUseAllowed, ')
          ..write('lastLegalReviewAt: $lastLegalReviewAt, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      displayName,
      type,
      homepageUrl,
      termsUrl,
      attribution,
      enabled,
      licenseStatus,
      licenseUrl,
      permissionContact,
      attributionRequired,
      cachePolicy,
      rawPayloadRetention,
      commercialUseAllowed,
      lastLegalReviewAt,
      lastCheckedAt,
      lastSuccessAt,
      etag,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.type == this.type &&
          other.homepageUrl == this.homepageUrl &&
          other.termsUrl == this.termsUrl &&
          other.attribution == this.attribution &&
          other.enabled == this.enabled &&
          other.licenseStatus == this.licenseStatus &&
          other.licenseUrl == this.licenseUrl &&
          other.permissionContact == this.permissionContact &&
          other.attributionRequired == this.attributionRequired &&
          other.cachePolicy == this.cachePolicy &&
          other.rawPayloadRetention == this.rawPayloadRetention &&
          other.commercialUseAllowed == this.commercialUseAllowed &&
          other.lastLegalReviewAt == this.lastLegalReviewAt &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.etag == this.etag &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SourcesTableCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> type;
  final Value<String?> homepageUrl;
  final Value<String?> termsUrl;
  final Value<String?> attribution;
  final Value<bool> enabled;
  final Value<LicenseStatus> licenseStatus;
  final Value<String?> licenseUrl;
  final Value<String?> permissionContact;
  final Value<bool> attributionRequired;
  final Value<String?> cachePolicy;
  final Value<bool> rawPayloadRetention;
  final Value<bool> commercialUseAllowed;
  final Value<DateTime?> lastLegalReviewAt;
  final Value<DateTime?> lastCheckedAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<String?> etag;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SourcesTableCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.type = const Value.absent(),
    this.homepageUrl = const Value.absent(),
    this.termsUrl = const Value.absent(),
    this.attribution = const Value.absent(),
    this.enabled = const Value.absent(),
    this.licenseStatus = const Value.absent(),
    this.licenseUrl = const Value.absent(),
    this.permissionContact = const Value.absent(),
    this.attributionRequired = const Value.absent(),
    this.cachePolicy = const Value.absent(),
    this.rawPayloadRetention = const Value.absent(),
    this.commercialUseAllowed = const Value.absent(),
    this.lastLegalReviewAt = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesTableCompanion.insert({
    required String id,
    required String displayName,
    required String type,
    this.homepageUrl = const Value.absent(),
    this.termsUrl = const Value.absent(),
    this.attribution = const Value.absent(),
    this.enabled = const Value.absent(),
    this.licenseStatus = const Value.absent(),
    this.licenseUrl = const Value.absent(),
    this.permissionContact = const Value.absent(),
    this.attributionRequired = const Value.absent(),
    this.cachePolicy = const Value.absent(),
    this.rawPayloadRetention = const Value.absent(),
    this.commercialUseAllowed = const Value.absent(),
    this.lastLegalReviewAt = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.etag = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        displayName = Value(displayName),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? type,
    Expression<String>? homepageUrl,
    Expression<String>? termsUrl,
    Expression<String>? attribution,
    Expression<bool>? enabled,
    Expression<String>? licenseStatus,
    Expression<String>? licenseUrl,
    Expression<String>? permissionContact,
    Expression<bool>? attributionRequired,
    Expression<String>? cachePolicy,
    Expression<bool>? rawPayloadRetention,
    Expression<bool>? commercialUseAllowed,
    Expression<DateTime>? lastLegalReviewAt,
    Expression<DateTime>? lastCheckedAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<String>? etag,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (type != null) 'type': type,
      if (homepageUrl != null) 'homepage_url': homepageUrl,
      if (termsUrl != null) 'terms_url': termsUrl,
      if (attribution != null) 'attribution': attribution,
      if (enabled != null) 'enabled': enabled,
      if (licenseStatus != null) 'license_status': licenseStatus,
      if (licenseUrl != null) 'license_url': licenseUrl,
      if (permissionContact != null) 'permission_contact': permissionContact,
      if (attributionRequired != null)
        'attribution_required': attributionRequired,
      if (cachePolicy != null) 'cache_policy': cachePolicy,
      if (rawPayloadRetention != null)
        'raw_payload_retention': rawPayloadRetention,
      if (commercialUseAllowed != null)
        'commercial_use_allowed': commercialUseAllowed,
      if (lastLegalReviewAt != null) 'last_legal_review_at': lastLegalReviewAt,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (etag != null) 'etag': etag,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? displayName,
      Value<String>? type,
      Value<String?>? homepageUrl,
      Value<String?>? termsUrl,
      Value<String?>? attribution,
      Value<bool>? enabled,
      Value<LicenseStatus>? licenseStatus,
      Value<String?>? licenseUrl,
      Value<String?>? permissionContact,
      Value<bool>? attributionRequired,
      Value<String?>? cachePolicy,
      Value<bool>? rawPayloadRetention,
      Value<bool>? commercialUseAllowed,
      Value<DateTime?>? lastLegalReviewAt,
      Value<DateTime?>? lastCheckedAt,
      Value<DateTime?>? lastSuccessAt,
      Value<String?>? etag,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SourcesTableCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      homepageUrl: homepageUrl ?? this.homepageUrl,
      termsUrl: termsUrl ?? this.termsUrl,
      attribution: attribution ?? this.attribution,
      enabled: enabled ?? this.enabled,
      licenseStatus: licenseStatus ?? this.licenseStatus,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      permissionContact: permissionContact ?? this.permissionContact,
      attributionRequired: attributionRequired ?? this.attributionRequired,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      rawPayloadRetention: rawPayloadRetention ?? this.rawPayloadRetention,
      commercialUseAllowed: commercialUseAllowed ?? this.commercialUseAllowed,
      lastLegalReviewAt: lastLegalReviewAt ?? this.lastLegalReviewAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      etag: etag ?? this.etag,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (homepageUrl.present) {
      map['homepage_url'] = Variable<String>(homepageUrl.value);
    }
    if (termsUrl.present) {
      map['terms_url'] = Variable<String>(termsUrl.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (licenseStatus.present) {
      map['license_status'] = Variable<String>($SourcesTableTable
          .$converterlicenseStatus
          .toSql(licenseStatus.value));
    }
    if (licenseUrl.present) {
      map['license_url'] = Variable<String>(licenseUrl.value);
    }
    if (permissionContact.present) {
      map['permission_contact'] = Variable<String>(permissionContact.value);
    }
    if (attributionRequired.present) {
      map['attribution_required'] = Variable<bool>(attributionRequired.value);
    }
    if (cachePolicy.present) {
      map['cache_policy'] = Variable<String>(cachePolicy.value);
    }
    if (rawPayloadRetention.present) {
      map['raw_payload_retention'] = Variable<bool>(rawPayloadRetention.value);
    }
    if (commercialUseAllowed.present) {
      map['commercial_use_allowed'] =
          Variable<bool>(commercialUseAllowed.value);
    }
    if (lastLegalReviewAt.present) {
      map['last_legal_review_at'] = Variable<DateTime>(lastLegalReviewAt.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
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
    return (StringBuffer('SourcesTableCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('type: $type, ')
          ..write('homepageUrl: $homepageUrl, ')
          ..write('termsUrl: $termsUrl, ')
          ..write('attribution: $attribution, ')
          ..write('enabled: $enabled, ')
          ..write('licenseStatus: $licenseStatus, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('permissionContact: $permissionContact, ')
          ..write('attributionRequired: $attributionRequired, ')
          ..write('cachePolicy: $cachePolicy, ')
          ..write('rawPayloadRetention: $rawPayloadRetention, ')
          ..write('commercialUseAllowed: $commercialUseAllowed, ')
          ..write('lastLegalReviewAt: $lastLegalReviewAt, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PuzzlesTableTable extends PuzzlesTable
    with TableInfo<$PuzzlesTableTable, PuzzleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES sources (id) ON DELETE RESTRICT'));
  static const VerificationMeta _sourcePuzzleIdMeta =
      const VerificationMeta('sourcePuzzleId');
  @override
  late final GeneratedColumn<String> sourcePuzzleId = GeneratedColumn<String>(
      'source_puzzle_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _editorMeta = const VerificationMeta('editor');
  @override
  late final GeneratedColumn<String> editor = GeneratedColumn<String>(
      'editor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _publisherMeta =
      const VerificationMeta('publisher');
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
      'publisher', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _copyrightMeta =
      const VerificationMeta('copyright');
  @override
  late final GeneratedColumn<String> copyright = GeneratedColumn<String>(
      'copyright', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _publishDateMeta =
      const VerificationMeta('publishDate');
  @override
  late final GeneratedColumn<DateTime> publishDate = GeneratedColumn<DateTime>(
      'publish_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _canonicalJsonMeta =
      const VerificationMeta('canonicalJson');
  @override
  late final GeneratedColumn<String> canonicalJson = GeneratedColumn<String>(
      'canonical_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawPayloadMeta =
      const VerificationMeta('rawPayload');
  @override
  late final GeneratedColumn<String> rawPayload = GeneratedColumn<String>(
      'raw_payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourceId,
        sourcePuzzleId,
        format,
        title,
        author,
        editor,
        publisher,
        copyright,
        notes,
        publishDate,
        difficulty,
        width,
        height,
        checksum,
        canonicalJson,
        rawPayload,
        fetchedAt,
        expiresAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(Insertable<PuzzleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('source_puzzle_id')) {
      context.handle(
          _sourcePuzzleIdMeta,
          sourcePuzzleId.isAcceptableOrUnknown(
              data['source_puzzle_id']!, _sourcePuzzleIdMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('editor')) {
      context.handle(_editorMeta,
          editor.isAcceptableOrUnknown(data['editor']!, _editorMeta));
    }
    if (data.containsKey('publisher')) {
      context.handle(_publisherMeta,
          publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta));
    }
    if (data.containsKey('copyright')) {
      context.handle(_copyrightMeta,
          copyright.isAcceptableOrUnknown(data['copyright']!, _copyrightMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('publish_date')) {
      context.handle(
          _publishDateMeta,
          publishDate.isAcceptableOrUnknown(
              data['publish_date']!, _publishDateMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('canonical_json')) {
      context.handle(
          _canonicalJsonMeta,
          canonicalJson.isAcceptableOrUnknown(
              data['canonical_json']!, _canonicalJsonMeta));
    } else if (isInserting) {
      context.missing(_canonicalJsonMeta);
    }
    if (data.containsKey('raw_payload')) {
      context.handle(
          _rawPayloadMeta,
          rawPayload.isAcceptableOrUnknown(
              data['raw_payload']!, _rawPayloadMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sourceId, sourcePuzzleId},
      ];
  @override
  PuzzleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      sourcePuzzleId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_puzzle_id']),
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      editor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}editor']),
      publisher: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}publisher']),
      copyright: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}copyright']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      publishDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}publish_date']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum'])!,
      canonicalJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}canonical_json'])!,
      rawPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_payload']),
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PuzzlesTableTable createAlias(String alias) {
    return $PuzzlesTableTable(attachedDatabase, alias);
  }
}

class PuzzleRow extends DataClass implements Insertable<PuzzleRow> {
  final String id;
  final String sourceId;
  final String? sourcePuzzleId;
  final String format;
  final String title;
  final String? author;
  final String? editor;
  final String? publisher;
  final String? copyright;
  final String? notes;
  final DateTime? publishDate;
  final String? difficulty;
  final int width;
  final int height;
  final String checksum;
  final String canonicalJson;
  final String? rawPayload;
  final DateTime? fetchedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PuzzleRow(
      {required this.id,
      required this.sourceId,
      this.sourcePuzzleId,
      required this.format,
      required this.title,
      this.author,
      this.editor,
      this.publisher,
      this.copyright,
      this.notes,
      this.publishDate,
      this.difficulty,
      required this.width,
      required this.height,
      required this.checksum,
      required this.canonicalJson,
      this.rawPayload,
      this.fetchedAt,
      this.expiresAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || sourcePuzzleId != null) {
      map['source_puzzle_id'] = Variable<String>(sourcePuzzleId);
    }
    map['format'] = Variable<String>(format);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || editor != null) {
      map['editor'] = Variable<String>(editor);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || copyright != null) {
      map['copyright'] = Variable<String>(copyright);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || publishDate != null) {
      map['publish_date'] = Variable<DateTime>(publishDate);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['checksum'] = Variable<String>(checksum);
    map['canonical_json'] = Variable<String>(canonicalJson);
    if (!nullToAbsent || rawPayload != null) {
      map['raw_payload'] = Variable<String>(rawPayload);
    }
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PuzzlesTableCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesTableCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      sourcePuzzleId: sourcePuzzleId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePuzzleId),
      format: Value(format),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      editor:
          editor == null && nullToAbsent ? const Value.absent() : Value(editor),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      copyright: copyright == null && nullToAbsent
          ? const Value.absent()
          : Value(copyright),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      publishDate: publishDate == null && nullToAbsent
          ? const Value.absent()
          : Value(publishDate),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      width: Value(width),
      height: Value(height),
      checksum: Value(checksum),
      canonicalJson: Value(canonicalJson),
      rawPayload: rawPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPayload),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PuzzleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourcePuzzleId: serializer.fromJson<String?>(json['sourcePuzzleId']),
      format: serializer.fromJson<String>(json['format']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      editor: serializer.fromJson<String?>(json['editor']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      copyright: serializer.fromJson<String?>(json['copyright']),
      notes: serializer.fromJson<String?>(json['notes']),
      publishDate: serializer.fromJson<DateTime?>(json['publishDate']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      checksum: serializer.fromJson<String>(json['checksum']),
      canonicalJson: serializer.fromJson<String>(json['canonicalJson']),
      rawPayload: serializer.fromJson<String?>(json['rawPayload']),
      fetchedAt: serializer.fromJson<DateTime?>(json['fetchedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourcePuzzleId': serializer.toJson<String?>(sourcePuzzleId),
      'format': serializer.toJson<String>(format),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'editor': serializer.toJson<String?>(editor),
      'publisher': serializer.toJson<String?>(publisher),
      'copyright': serializer.toJson<String?>(copyright),
      'notes': serializer.toJson<String?>(notes),
      'publishDate': serializer.toJson<DateTime?>(publishDate),
      'difficulty': serializer.toJson<String?>(difficulty),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'checksum': serializer.toJson<String>(checksum),
      'canonicalJson': serializer.toJson<String>(canonicalJson),
      'rawPayload': serializer.toJson<String?>(rawPayload),
      'fetchedAt': serializer.toJson<DateTime?>(fetchedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PuzzleRow copyWith(
          {String? id,
          String? sourceId,
          Value<String?> sourcePuzzleId = const Value.absent(),
          String? format,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> editor = const Value.absent(),
          Value<String?> publisher = const Value.absent(),
          Value<String?> copyright = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<DateTime?> publishDate = const Value.absent(),
          Value<String?> difficulty = const Value.absent(),
          int? width,
          int? height,
          String? checksum,
          String? canonicalJson,
          Value<String?> rawPayload = const Value.absent(),
          Value<DateTime?> fetchedAt = const Value.absent(),
          Value<DateTime?> expiresAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PuzzleRow(
        id: id ?? this.id,
        sourceId: sourceId ?? this.sourceId,
        sourcePuzzleId:
            sourcePuzzleId.present ? sourcePuzzleId.value : this.sourcePuzzleId,
        format: format ?? this.format,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        editor: editor.present ? editor.value : this.editor,
        publisher: publisher.present ? publisher.value : this.publisher,
        copyright: copyright.present ? copyright.value : this.copyright,
        notes: notes.present ? notes.value : this.notes,
        publishDate: publishDate.present ? publishDate.value : this.publishDate,
        difficulty: difficulty.present ? difficulty.value : this.difficulty,
        width: width ?? this.width,
        height: height ?? this.height,
        checksum: checksum ?? this.checksum,
        canonicalJson: canonicalJson ?? this.canonicalJson,
        rawPayload: rawPayload.present ? rawPayload.value : this.rawPayload,
        fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PuzzleRow copyWithCompanion(PuzzlesTableCompanion data) {
    return PuzzleRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourcePuzzleId: data.sourcePuzzleId.present
          ? data.sourcePuzzleId.value
          : this.sourcePuzzleId,
      format: data.format.present ? data.format.value : this.format,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      editor: data.editor.present ? data.editor.value : this.editor,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      copyright: data.copyright.present ? data.copyright.value : this.copyright,
      notes: data.notes.present ? data.notes.value : this.notes,
      publishDate:
          data.publishDate.present ? data.publishDate.value : this.publishDate,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      canonicalJson: data.canonicalJson.present
          ? data.canonicalJson.value
          : this.canonicalJson,
      rawPayload:
          data.rawPayload.present ? data.rawPayload.value : this.rawPayload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePuzzleId: $sourcePuzzleId, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('editor: $editor, ')
          ..write('publisher: $publisher, ')
          ..write('copyright: $copyright, ')
          ..write('notes: $notes, ')
          ..write('publishDate: $publishDate, ')
          ..write('difficulty: $difficulty, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('checksum: $checksum, ')
          ..write('canonicalJson: $canonicalJson, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        sourceId,
        sourcePuzzleId,
        format,
        title,
        author,
        editor,
        publisher,
        copyright,
        notes,
        publishDate,
        difficulty,
        width,
        height,
        checksum,
        canonicalJson,
        rawPayload,
        fetchedAt,
        expiresAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.sourcePuzzleId == this.sourcePuzzleId &&
          other.format == this.format &&
          other.title == this.title &&
          other.author == this.author &&
          other.editor == this.editor &&
          other.publisher == this.publisher &&
          other.copyright == this.copyright &&
          other.notes == this.notes &&
          other.publishDate == this.publishDate &&
          other.difficulty == this.difficulty &&
          other.width == this.width &&
          other.height == this.height &&
          other.checksum == this.checksum &&
          other.canonicalJson == this.canonicalJson &&
          other.rawPayload == this.rawPayload &&
          other.fetchedAt == this.fetchedAt &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PuzzlesTableCompanion extends UpdateCompanion<PuzzleRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String?> sourcePuzzleId;
  final Value<String> format;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> editor;
  final Value<String?> publisher;
  final Value<String?> copyright;
  final Value<String?> notes;
  final Value<DateTime?> publishDate;
  final Value<String?> difficulty;
  final Value<int> width;
  final Value<int> height;
  final Value<String> checksum;
  final Value<String> canonicalJson;
  final Value<String?> rawPayload;
  final Value<DateTime?> fetchedAt;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PuzzlesTableCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourcePuzzleId = const Value.absent(),
    this.format = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.editor = const Value.absent(),
    this.publisher = const Value.absent(),
    this.copyright = const Value.absent(),
    this.notes = const Value.absent(),
    this.publishDate = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.checksum = const Value.absent(),
    this.canonicalJson = const Value.absent(),
    this.rawPayload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzlesTableCompanion.insert({
    required String id,
    required String sourceId,
    this.sourcePuzzleId = const Value.absent(),
    required String format,
    required String title,
    this.author = const Value.absent(),
    this.editor = const Value.absent(),
    this.publisher = const Value.absent(),
    this.copyright = const Value.absent(),
    this.notes = const Value.absent(),
    this.publishDate = const Value.absent(),
    this.difficulty = const Value.absent(),
    required int width,
    required int height,
    required String checksum,
    required String canonicalJson,
    this.rawPayload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sourceId = Value(sourceId),
        format = Value(format),
        title = Value(title),
        width = Value(width),
        height = Value(height),
        checksum = Value(checksum),
        canonicalJson = Value(canonicalJson),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PuzzleRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? sourcePuzzleId,
    Expression<String>? format,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? editor,
    Expression<String>? publisher,
    Expression<String>? copyright,
    Expression<String>? notes,
    Expression<DateTime>? publishDate,
    Expression<String>? difficulty,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? checksum,
    Expression<String>? canonicalJson,
    Expression<String>? rawPayload,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (sourcePuzzleId != null) 'source_puzzle_id': sourcePuzzleId,
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (editor != null) 'editor': editor,
      if (publisher != null) 'publisher': publisher,
      if (copyright != null) 'copyright': copyright,
      if (notes != null) 'notes': notes,
      if (publishDate != null) 'publish_date': publishDate,
      if (difficulty != null) 'difficulty': difficulty,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (checksum != null) 'checksum': checksum,
      if (canonicalJson != null) 'canonical_json': canonicalJson,
      if (rawPayload != null) 'raw_payload': rawPayload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzlesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? sourceId,
      Value<String?>? sourcePuzzleId,
      Value<String>? format,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? editor,
      Value<String?>? publisher,
      Value<String?>? copyright,
      Value<String?>? notes,
      Value<DateTime?>? publishDate,
      Value<String?>? difficulty,
      Value<int>? width,
      Value<int>? height,
      Value<String>? checksum,
      Value<String>? canonicalJson,
      Value<String?>? rawPayload,
      Value<DateTime?>? fetchedAt,
      Value<DateTime?>? expiresAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PuzzlesTableCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourcePuzzleId: sourcePuzzleId ?? this.sourcePuzzleId,
      format: format ?? this.format,
      title: title ?? this.title,
      author: author ?? this.author,
      editor: editor ?? this.editor,
      publisher: publisher ?? this.publisher,
      copyright: copyright ?? this.copyright,
      notes: notes ?? this.notes,
      publishDate: publishDate ?? this.publishDate,
      difficulty: difficulty ?? this.difficulty,
      width: width ?? this.width,
      height: height ?? this.height,
      checksum: checksum ?? this.checksum,
      canonicalJson: canonicalJson ?? this.canonicalJson,
      rawPayload: rawPayload ?? this.rawPayload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourcePuzzleId.present) {
      map['source_puzzle_id'] = Variable<String>(sourcePuzzleId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (editor.present) {
      map['editor'] = Variable<String>(editor.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (copyright.present) {
      map['copyright'] = Variable<String>(copyright.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (publishDate.present) {
      map['publish_date'] = Variable<DateTime>(publishDate.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (canonicalJson.present) {
      map['canonical_json'] = Variable<String>(canonicalJson.value);
    }
    if (rawPayload.present) {
      map['raw_payload'] = Variable<String>(rawPayload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
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
    return (StringBuffer('PuzzlesTableCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePuzzleId: $sourcePuzzleId, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('editor: $editor, ')
          ..write('publisher: $publisher, ')
          ..write('copyright: $copyright, ')
          ..write('notes: $notes, ')
          ..write('publishDate: $publishDate, ')
          ..write('difficulty: $difficulty, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('checksum: $checksum, ')
          ..write('canonicalJson: $canonicalJson, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CluesTableTable extends CluesTable
    with TableInfo<$CluesTableTable, ClueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CluesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _puzzleIdMeta =
      const VerificationMeta('puzzleId');
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
      'puzzle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES puzzles (id) ON DELETE CASCADE'));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startRowMeta =
      const VerificationMeta('startRow');
  @override
  late final GeneratedColumn<int> startRow = GeneratedColumn<int>(
      'start_row', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startColMeta =
      const VerificationMeta('startCol');
  @override
  late final GeneratedColumn<int> startCol = GeneratedColumn<int>(
      'start_col', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _clueTextMeta =
      const VerificationMeta('clueText');
  @override
  late final GeneratedColumn<String> clueText = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerLengthMeta =
      const VerificationMeta('answerLength');
  @override
  late final GeneratedColumn<int> answerLength = GeneratedColumn<int>(
      'answer_length', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        puzzleId,
        direction,
        number,
        sortOrder,
        startRow,
        startCol,
        clueText,
        answerLength
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clues';
  @override
  VerificationContext validateIntegrity(Insertable<ClueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(_puzzleIdMeta,
          puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta));
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('start_row')) {
      context.handle(_startRowMeta,
          startRow.isAcceptableOrUnknown(data['start_row']!, _startRowMeta));
    } else if (isInserting) {
      context.missing(_startRowMeta);
    }
    if (data.containsKey('start_col')) {
      context.handle(_startColMeta,
          startCol.isAcceptableOrUnknown(data['start_col']!, _startColMeta));
    } else if (isInserting) {
      context.missing(_startColMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_clueTextMeta,
          clueText.isAcceptableOrUnknown(data['text']!, _clueTextMeta));
    } else if (isInserting) {
      context.missing(_clueTextMeta);
    }
    if (data.containsKey('answer_length')) {
      context.handle(
          _answerLengthMeta,
          answerLength.isAcceptableOrUnknown(
              data['answer_length']!, _answerLengthMeta));
    } else if (isInserting) {
      context.missing(_answerLengthMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {puzzleId, direction, number},
      ];
  @override
  ClueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClueRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      puzzleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}puzzle_id'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      startRow: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_row'])!,
      startCol: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_col'])!,
      clueText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      answerLength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}answer_length'])!,
    );
  }

  @override
  $CluesTableTable createAlias(String alias) {
    return $CluesTableTable(attachedDatabase, alias);
  }
}

class ClueRow extends DataClass implements Insertable<ClueRow> {
  final int id;
  final String puzzleId;
  final String direction;
  final int number;
  final int sortOrder;
  final int startRow;
  final int startCol;
  final String clueText;
  final int answerLength;
  const ClueRow(
      {required this.id,
      required this.puzzleId,
      required this.direction,
      required this.number,
      required this.sortOrder,
      required this.startRow,
      required this.startCol,
      required this.clueText,
      required this.answerLength});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['direction'] = Variable<String>(direction);
    map['number'] = Variable<int>(number);
    map['sort_order'] = Variable<int>(sortOrder);
    map['start_row'] = Variable<int>(startRow);
    map['start_col'] = Variable<int>(startCol);
    map['text'] = Variable<String>(clueText);
    map['answer_length'] = Variable<int>(answerLength);
    return map;
  }

  CluesTableCompanion toCompanion(bool nullToAbsent) {
    return CluesTableCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      direction: Value(direction),
      number: Value(number),
      sortOrder: Value(sortOrder),
      startRow: Value(startRow),
      startCol: Value(startCol),
      clueText: Value(clueText),
      answerLength: Value(answerLength),
    );
  }

  factory ClueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClueRow(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      direction: serializer.fromJson<String>(json['direction']),
      number: serializer.fromJson<int>(json['number']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      startRow: serializer.fromJson<int>(json['startRow']),
      startCol: serializer.fromJson<int>(json['startCol']),
      clueText: serializer.fromJson<String>(json['clueText']),
      answerLength: serializer.fromJson<int>(json['answerLength']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'direction': serializer.toJson<String>(direction),
      'number': serializer.toJson<int>(number),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'startRow': serializer.toJson<int>(startRow),
      'startCol': serializer.toJson<int>(startCol),
      'clueText': serializer.toJson<String>(clueText),
      'answerLength': serializer.toJson<int>(answerLength),
    };
  }

  ClueRow copyWith(
          {int? id,
          String? puzzleId,
          String? direction,
          int? number,
          int? sortOrder,
          int? startRow,
          int? startCol,
          String? clueText,
          int? answerLength}) =>
      ClueRow(
        id: id ?? this.id,
        puzzleId: puzzleId ?? this.puzzleId,
        direction: direction ?? this.direction,
        number: number ?? this.number,
        sortOrder: sortOrder ?? this.sortOrder,
        startRow: startRow ?? this.startRow,
        startCol: startCol ?? this.startCol,
        clueText: clueText ?? this.clueText,
        answerLength: answerLength ?? this.answerLength,
      );
  ClueRow copyWithCompanion(CluesTableCompanion data) {
    return ClueRow(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      direction: data.direction.present ? data.direction.value : this.direction,
      number: data.number.present ? data.number.value : this.number,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      startRow: data.startRow.present ? data.startRow.value : this.startRow,
      startCol: data.startCol.present ? data.startCol.value : this.startCol,
      clueText: data.clueText.present ? data.clueText.value : this.clueText,
      answerLength: data.answerLength.present
          ? data.answerLength.value
          : this.answerLength,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClueRow(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('direction: $direction, ')
          ..write('number: $number, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startRow: $startRow, ')
          ..write('startCol: $startCol, ')
          ..write('clueText: $clueText, ')
          ..write('answerLength: $answerLength')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, puzzleId, direction, number, sortOrder,
      startRow, startCol, clueText, answerLength);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClueRow &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.direction == this.direction &&
          other.number == this.number &&
          other.sortOrder == this.sortOrder &&
          other.startRow == this.startRow &&
          other.startCol == this.startCol &&
          other.clueText == this.clueText &&
          other.answerLength == this.answerLength);
}

class CluesTableCompanion extends UpdateCompanion<ClueRow> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> direction;
  final Value<int> number;
  final Value<int> sortOrder;
  final Value<int> startRow;
  final Value<int> startCol;
  final Value<String> clueText;
  final Value<int> answerLength;
  const CluesTableCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.direction = const Value.absent(),
    this.number = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.startRow = const Value.absent(),
    this.startCol = const Value.absent(),
    this.clueText = const Value.absent(),
    this.answerLength = const Value.absent(),
  });
  CluesTableCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String direction,
    required int number,
    required int sortOrder,
    required int startRow,
    required int startCol,
    required String clueText,
    required int answerLength,
  })  : puzzleId = Value(puzzleId),
        direction = Value(direction),
        number = Value(number),
        sortOrder = Value(sortOrder),
        startRow = Value(startRow),
        startCol = Value(startCol),
        clueText = Value(clueText),
        answerLength = Value(answerLength);
  static Insertable<ClueRow> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? direction,
    Expression<int>? number,
    Expression<int>? sortOrder,
    Expression<int>? startRow,
    Expression<int>? startCol,
    Expression<String>? clueText,
    Expression<int>? answerLength,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (direction != null) 'direction': direction,
      if (number != null) 'number': number,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (startRow != null) 'start_row': startRow,
      if (startCol != null) 'start_col': startCol,
      if (clueText != null) 'text': clueText,
      if (answerLength != null) 'answer_length': answerLength,
    });
  }

  CluesTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? puzzleId,
      Value<String>? direction,
      Value<int>? number,
      Value<int>? sortOrder,
      Value<int>? startRow,
      Value<int>? startCol,
      Value<String>? clueText,
      Value<int>? answerLength}) {
    return CluesTableCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      direction: direction ?? this.direction,
      number: number ?? this.number,
      sortOrder: sortOrder ?? this.sortOrder,
      startRow: startRow ?? this.startRow,
      startCol: startCol ?? this.startCol,
      clueText: clueText ?? this.clueText,
      answerLength: answerLength ?? this.answerLength,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (startRow.present) {
      map['start_row'] = Variable<int>(startRow.value);
    }
    if (startCol.present) {
      map['start_col'] = Variable<int>(startCol.value);
    }
    if (clueText.present) {
      map['text'] = Variable<String>(clueText.value);
    }
    if (answerLength.present) {
      map['answer_length'] = Variable<int>(answerLength.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CluesTableCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('direction: $direction, ')
          ..write('number: $number, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startRow: $startRow, ')
          ..write('startCol: $startCol, ')
          ..write('clueText: $clueText, ')
          ..write('answerLength: $answerLength')
          ..write(')'))
        .toString();
  }
}

class $SolveSessionsTableTable extends SolveSessionsTable
    with TableInfo<$SolveSessionsTableTable, SolveSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolveSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _puzzleIdMeta =
      const VerificationMeta('puzzleId');
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
      'puzzle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES puzzles (id) ON DELETE CASCADE'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_started'));
  static const VerificationMeta _completionTypeMeta =
      const VerificationMeta('completionType');
  @override
  late final GeneratedColumn<String> completionType = GeneratedColumn<String>(
      'completion_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _solvedDateLocalMeta =
      const VerificationMeta('solvedDateLocal');
  @override
  late final GeneratedColumn<String> solvedDateLocal = GeneratedColumn<String>(
      'solved_date_local', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _solvedTimezoneMeta =
      const VerificationMeta('solvedTimezone');
  @override
  late final GeneratedColumn<String> solvedTimezone = GeneratedColumn<String>(
      'solved_timezone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _elapsedMsMeta =
      const VerificationMeta('elapsedMs');
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
      'elapsed_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isPausedMeta =
      const VerificationMeta('isPaused');
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
      'is_paused', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paused" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pausedAtMeta =
      const VerificationMeta('pausedAt');
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
      'paused_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalPausedMsMeta =
      const VerificationMeta('totalPausedMs');
  @override
  late final GeneratedColumn<int> totalPausedMs = GeneratedColumn<int>(
      'total_paused_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mistakeCountMeta =
      const VerificationMeta('mistakeCount');
  @override
  late final GeneratedColumn<int> mistakeCount = GeneratedColumn<int>(
      'mistake_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _checkCountMeta =
      const VerificationMeta('checkCount');
  @override
  late final GeneratedColumn<int> checkCount = GeneratedColumn<int>(
      'check_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _revealCountMeta =
      const VerificationMeta('revealCount');
  @override
  late final GeneratedColumn<int> revealCount = GeneratedColumn<int>(
      'reveal_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _usedCheckMeta =
      const VerificationMeta('usedCheck');
  @override
  late final GeneratedColumn<bool> usedCheck = GeneratedColumn<bool>(
      'used_check', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("used_check" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _usedRevealMeta =
      const VerificationMeta('usedReveal');
  @override
  late final GeneratedColumn<bool> usedReveal = GeneratedColumn<bool>(
      'used_reveal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("used_reveal" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cleanSolveEligibleMeta =
      const VerificationMeta('cleanSolveEligible');
  @override
  late final GeneratedColumn<bool> cleanSolveEligible = GeneratedColumn<bool>(
      'clean_solve_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("clean_solve_eligible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _focusRowMeta =
      const VerificationMeta('focusRow');
  @override
  late final GeneratedColumn<int> focusRow = GeneratedColumn<int>(
      'focus_row', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _focusColMeta =
      const VerificationMeta('focusCol');
  @override
  late final GeneratedColumn<int> focusCol = GeneratedColumn<int>(
      'focus_col', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('across'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncVersionMeta =
      const VerificationMeta('syncVersion');
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
      'sync_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        puzzleId,
        deviceId,
        status,
        completionType,
        startedAt,
        lastPlayedAt,
        completedAt,
        solvedDateLocal,
        solvedTimezone,
        elapsedMs,
        isPaused,
        pausedAt,
        totalPausedMs,
        mistakeCount,
        checkCount,
        revealCount,
        usedCheck,
        usedReveal,
        cleanSolveEligible,
        focusRow,
        focusCol,
        direction,
        isSynced,
        syncVersion,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solve_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<SolveSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(_puzzleIdMeta,
          puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta));
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('completion_type')) {
      context.handle(
          _completionTypeMeta,
          completionType.isAcceptableOrUnknown(
              data['completion_type']!, _completionTypeMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    } else if (isInserting) {
      context.missing(_lastPlayedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('solved_date_local')) {
      context.handle(
          _solvedDateLocalMeta,
          solvedDateLocal.isAcceptableOrUnknown(
              data['solved_date_local']!, _solvedDateLocalMeta));
    }
    if (data.containsKey('solved_timezone')) {
      context.handle(
          _solvedTimezoneMeta,
          solvedTimezone.isAcceptableOrUnknown(
              data['solved_timezone']!, _solvedTimezoneMeta));
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(_elapsedMsMeta,
          elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta));
    }
    if (data.containsKey('is_paused')) {
      context.handle(_isPausedMeta,
          isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta));
    }
    if (data.containsKey('paused_at')) {
      context.handle(_pausedAtMeta,
          pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta));
    }
    if (data.containsKey('total_paused_ms')) {
      context.handle(
          _totalPausedMsMeta,
          totalPausedMs.isAcceptableOrUnknown(
              data['total_paused_ms']!, _totalPausedMsMeta));
    }
    if (data.containsKey('mistake_count')) {
      context.handle(
          _mistakeCountMeta,
          mistakeCount.isAcceptableOrUnknown(
              data['mistake_count']!, _mistakeCountMeta));
    }
    if (data.containsKey('check_count')) {
      context.handle(
          _checkCountMeta,
          checkCount.isAcceptableOrUnknown(
              data['check_count']!, _checkCountMeta));
    }
    if (data.containsKey('reveal_count')) {
      context.handle(
          _revealCountMeta,
          revealCount.isAcceptableOrUnknown(
              data['reveal_count']!, _revealCountMeta));
    }
    if (data.containsKey('used_check')) {
      context.handle(_usedCheckMeta,
          usedCheck.isAcceptableOrUnknown(data['used_check']!, _usedCheckMeta));
    }
    if (data.containsKey('used_reveal')) {
      context.handle(
          _usedRevealMeta,
          usedReveal.isAcceptableOrUnknown(
              data['used_reveal']!, _usedRevealMeta));
    }
    if (data.containsKey('clean_solve_eligible')) {
      context.handle(
          _cleanSolveEligibleMeta,
          cleanSolveEligible.isAcceptableOrUnknown(
              data['clean_solve_eligible']!, _cleanSolveEligibleMeta));
    }
    if (data.containsKey('focus_row')) {
      context.handle(_focusRowMeta,
          focusRow.isAcceptableOrUnknown(data['focus_row']!, _focusRowMeta));
    }
    if (data.containsKey('focus_col')) {
      context.handle(_focusColMeta,
          focusCol.isAcceptableOrUnknown(data['focus_col']!, _focusColMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_version')) {
      context.handle(
          _syncVersionMeta,
          syncVersion.isAcceptableOrUnknown(
              data['sync_version']!, _syncVersionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolveSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolveSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      puzzleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}puzzle_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      completionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}completion_type']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      solvedDateLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}solved_date_local']),
      solvedTimezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}solved_timezone']),
      elapsedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_ms'])!,
      isPaused: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paused'])!,
      pausedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paused_at']),
      totalPausedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_paused_ms'])!,
      mistakeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mistake_count'])!,
      checkCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}check_count'])!,
      revealCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reveal_count'])!,
      usedCheck: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}used_check'])!,
      usedReveal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}used_reveal'])!,
      cleanSolveEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}clean_solve_eligible'])!,
      focusRow: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}focus_row'])!,
      focusCol: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}focus_col'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SolveSessionsTableTable createAlias(String alias) {
    return $SolveSessionsTableTable(attachedDatabase, alias);
  }
}

class SolveSessionRow extends DataClass implements Insertable<SolveSessionRow> {
  final int id;
  final String puzzleId;
  final String deviceId;

  /// DB values: not_started | in_progress | completed | revealed
  final String status;

  /// DB values: clean | checked | hinted | revealed (only set when completed)
  final String? completionType;
  final DateTime startedAt;
  final DateTime lastPlayedAt;
  final DateTime? completedAt;

  /// Calendar date string in device-local timezone: 'yyyy-MM-dd'.
  /// Used by streak algorithm.
  final String? solvedDateLocal;
  final String? solvedTimezone;
  final int elapsedMs;
  final bool isPaused;
  final DateTime? pausedAt;
  final int totalPausedMs;
  final int mistakeCount;
  final int checkCount;
  final int revealCount;
  final bool usedCheck;
  final bool usedReveal;
  final bool cleanSolveEligible;
  final int focusRow;
  final int focusCol;
  final String direction;
  final bool isSynced;
  final int syncVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SolveSessionRow(
      {required this.id,
      required this.puzzleId,
      required this.deviceId,
      required this.status,
      this.completionType,
      required this.startedAt,
      required this.lastPlayedAt,
      this.completedAt,
      this.solvedDateLocal,
      this.solvedTimezone,
      required this.elapsedMs,
      required this.isPaused,
      this.pausedAt,
      required this.totalPausedMs,
      required this.mistakeCount,
      required this.checkCount,
      required this.revealCount,
      required this.usedCheck,
      required this.usedReveal,
      required this.cleanSolveEligible,
      required this.focusRow,
      required this.focusCol,
      required this.direction,
      required this.isSynced,
      required this.syncVersion,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['device_id'] = Variable<String>(deviceId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completionType != null) {
      map['completion_type'] = Variable<String>(completionType);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || solvedDateLocal != null) {
      map['solved_date_local'] = Variable<String>(solvedDateLocal);
    }
    if (!nullToAbsent || solvedTimezone != null) {
      map['solved_timezone'] = Variable<String>(solvedTimezone);
    }
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['is_paused'] = Variable<bool>(isPaused);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    map['total_paused_ms'] = Variable<int>(totalPausedMs);
    map['mistake_count'] = Variable<int>(mistakeCount);
    map['check_count'] = Variable<int>(checkCount);
    map['reveal_count'] = Variable<int>(revealCount);
    map['used_check'] = Variable<bool>(usedCheck);
    map['used_reveal'] = Variable<bool>(usedReveal);
    map['clean_solve_eligible'] = Variable<bool>(cleanSolveEligible);
    map['focus_row'] = Variable<int>(focusRow);
    map['focus_col'] = Variable<int>(focusCol);
    map['direction'] = Variable<String>(direction);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_version'] = Variable<int>(syncVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SolveSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return SolveSessionsTableCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      deviceId: Value(deviceId),
      status: Value(status),
      completionType: completionType == null && nullToAbsent
          ? const Value.absent()
          : Value(completionType),
      startedAt: Value(startedAt),
      lastPlayedAt: Value(lastPlayedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      solvedDateLocal: solvedDateLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(solvedDateLocal),
      solvedTimezone: solvedTimezone == null && nullToAbsent
          ? const Value.absent()
          : Value(solvedTimezone),
      elapsedMs: Value(elapsedMs),
      isPaused: Value(isPaused),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      totalPausedMs: Value(totalPausedMs),
      mistakeCount: Value(mistakeCount),
      checkCount: Value(checkCount),
      revealCount: Value(revealCount),
      usedCheck: Value(usedCheck),
      usedReveal: Value(usedReveal),
      cleanSolveEligible: Value(cleanSolveEligible),
      focusRow: Value(focusRow),
      focusCol: Value(focusCol),
      direction: Value(direction),
      isSynced: Value(isSynced),
      syncVersion: Value(syncVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SolveSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolveSessionRow(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      status: serializer.fromJson<String>(json['status']),
      completionType: serializer.fromJson<String?>(json['completionType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      solvedDateLocal: serializer.fromJson<String?>(json['solvedDateLocal']),
      solvedTimezone: serializer.fromJson<String?>(json['solvedTimezone']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      totalPausedMs: serializer.fromJson<int>(json['totalPausedMs']),
      mistakeCount: serializer.fromJson<int>(json['mistakeCount']),
      checkCount: serializer.fromJson<int>(json['checkCount']),
      revealCount: serializer.fromJson<int>(json['revealCount']),
      usedCheck: serializer.fromJson<bool>(json['usedCheck']),
      usedReveal: serializer.fromJson<bool>(json['usedReveal']),
      cleanSolveEligible: serializer.fromJson<bool>(json['cleanSolveEligible']),
      focusRow: serializer.fromJson<int>(json['focusRow']),
      focusCol: serializer.fromJson<int>(json['focusCol']),
      direction: serializer.fromJson<String>(json['direction']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'deviceId': serializer.toJson<String>(deviceId),
      'status': serializer.toJson<String>(status),
      'completionType': serializer.toJson<String?>(completionType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'solvedDateLocal': serializer.toJson<String?>(solvedDateLocal),
      'solvedTimezone': serializer.toJson<String?>(solvedTimezone),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'isPaused': serializer.toJson<bool>(isPaused),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'totalPausedMs': serializer.toJson<int>(totalPausedMs),
      'mistakeCount': serializer.toJson<int>(mistakeCount),
      'checkCount': serializer.toJson<int>(checkCount),
      'revealCount': serializer.toJson<int>(revealCount),
      'usedCheck': serializer.toJson<bool>(usedCheck),
      'usedReveal': serializer.toJson<bool>(usedReveal),
      'cleanSolveEligible': serializer.toJson<bool>(cleanSolveEligible),
      'focusRow': serializer.toJson<int>(focusRow),
      'focusCol': serializer.toJson<int>(focusCol),
      'direction': serializer.toJson<String>(direction),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SolveSessionRow copyWith(
          {int? id,
          String? puzzleId,
          String? deviceId,
          String? status,
          Value<String?> completionType = const Value.absent(),
          DateTime? startedAt,
          DateTime? lastPlayedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> solvedDateLocal = const Value.absent(),
          Value<String?> solvedTimezone = const Value.absent(),
          int? elapsedMs,
          bool? isPaused,
          Value<DateTime?> pausedAt = const Value.absent(),
          int? totalPausedMs,
          int? mistakeCount,
          int? checkCount,
          int? revealCount,
          bool? usedCheck,
          bool? usedReveal,
          bool? cleanSolveEligible,
          int? focusRow,
          int? focusCol,
          String? direction,
          bool? isSynced,
          int? syncVersion,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SolveSessionRow(
        id: id ?? this.id,
        puzzleId: puzzleId ?? this.puzzleId,
        deviceId: deviceId ?? this.deviceId,
        status: status ?? this.status,
        completionType:
            completionType.present ? completionType.value : this.completionType,
        startedAt: startedAt ?? this.startedAt,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        solvedDateLocal: solvedDateLocal.present
            ? solvedDateLocal.value
            : this.solvedDateLocal,
        solvedTimezone:
            solvedTimezone.present ? solvedTimezone.value : this.solvedTimezone,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        isPaused: isPaused ?? this.isPaused,
        pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
        totalPausedMs: totalPausedMs ?? this.totalPausedMs,
        mistakeCount: mistakeCount ?? this.mistakeCount,
        checkCount: checkCount ?? this.checkCount,
        revealCount: revealCount ?? this.revealCount,
        usedCheck: usedCheck ?? this.usedCheck,
        usedReveal: usedReveal ?? this.usedReveal,
        cleanSolveEligible: cleanSolveEligible ?? this.cleanSolveEligible,
        focusRow: focusRow ?? this.focusRow,
        focusCol: focusCol ?? this.focusCol,
        direction: direction ?? this.direction,
        isSynced: isSynced ?? this.isSynced,
        syncVersion: syncVersion ?? this.syncVersion,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SolveSessionRow copyWithCompanion(SolveSessionsTableCompanion data) {
    return SolveSessionRow(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      status: data.status.present ? data.status.value : this.status,
      completionType: data.completionType.present
          ? data.completionType.value
          : this.completionType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      solvedDateLocal: data.solvedDateLocal.present
          ? data.solvedDateLocal.value
          : this.solvedDateLocal,
      solvedTimezone: data.solvedTimezone.present
          ? data.solvedTimezone.value
          : this.solvedTimezone,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      totalPausedMs: data.totalPausedMs.present
          ? data.totalPausedMs.value
          : this.totalPausedMs,
      mistakeCount: data.mistakeCount.present
          ? data.mistakeCount.value
          : this.mistakeCount,
      checkCount:
          data.checkCount.present ? data.checkCount.value : this.checkCount,
      revealCount:
          data.revealCount.present ? data.revealCount.value : this.revealCount,
      usedCheck: data.usedCheck.present ? data.usedCheck.value : this.usedCheck,
      usedReveal:
          data.usedReveal.present ? data.usedReveal.value : this.usedReveal,
      cleanSolveEligible: data.cleanSolveEligible.present
          ? data.cleanSolveEligible.value
          : this.cleanSolveEligible,
      focusRow: data.focusRow.present ? data.focusRow.value : this.focusRow,
      focusCol: data.focusCol.present ? data.focusCol.value : this.focusCol,
      direction: data.direction.present ? data.direction.value : this.direction,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncVersion:
          data.syncVersion.present ? data.syncVersion.value : this.syncVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolveSessionRow(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('deviceId: $deviceId, ')
          ..write('status: $status, ')
          ..write('completionType: $completionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('isPaused: $isPaused, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('totalPausedMs: $totalPausedMs, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('checkCount: $checkCount, ')
          ..write('revealCount: $revealCount, ')
          ..write('usedCheck: $usedCheck, ')
          ..write('usedReveal: $usedReveal, ')
          ..write('cleanSolveEligible: $cleanSolveEligible, ')
          ..write('focusRow: $focusRow, ')
          ..write('focusCol: $focusCol, ')
          ..write('direction: $direction, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        puzzleId,
        deviceId,
        status,
        completionType,
        startedAt,
        lastPlayedAt,
        completedAt,
        solvedDateLocal,
        solvedTimezone,
        elapsedMs,
        isPaused,
        pausedAt,
        totalPausedMs,
        mistakeCount,
        checkCount,
        revealCount,
        usedCheck,
        usedReveal,
        cleanSolveEligible,
        focusRow,
        focusCol,
        direction,
        isSynced,
        syncVersion,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolveSessionRow &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.deviceId == this.deviceId &&
          other.status == this.status &&
          other.completionType == this.completionType &&
          other.startedAt == this.startedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.completedAt == this.completedAt &&
          other.solvedDateLocal == this.solvedDateLocal &&
          other.solvedTimezone == this.solvedTimezone &&
          other.elapsedMs == this.elapsedMs &&
          other.isPaused == this.isPaused &&
          other.pausedAt == this.pausedAt &&
          other.totalPausedMs == this.totalPausedMs &&
          other.mistakeCount == this.mistakeCount &&
          other.checkCount == this.checkCount &&
          other.revealCount == this.revealCount &&
          other.usedCheck == this.usedCheck &&
          other.usedReveal == this.usedReveal &&
          other.cleanSolveEligible == this.cleanSolveEligible &&
          other.focusRow == this.focusRow &&
          other.focusCol == this.focusCol &&
          other.direction == this.direction &&
          other.isSynced == this.isSynced &&
          other.syncVersion == this.syncVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SolveSessionsTableCompanion extends UpdateCompanion<SolveSessionRow> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> deviceId;
  final Value<String> status;
  final Value<String?> completionType;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastPlayedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> solvedDateLocal;
  final Value<String?> solvedTimezone;
  final Value<int> elapsedMs;
  final Value<bool> isPaused;
  final Value<DateTime?> pausedAt;
  final Value<int> totalPausedMs;
  final Value<int> mistakeCount;
  final Value<int> checkCount;
  final Value<int> revealCount;
  final Value<bool> usedCheck;
  final Value<bool> usedReveal;
  final Value<bool> cleanSolveEligible;
  final Value<int> focusRow;
  final Value<int> focusCol;
  final Value<String> direction;
  final Value<bool> isSynced;
  final Value<int> syncVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SolveSessionsTableCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.status = const Value.absent(),
    this.completionType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.solvedDateLocal = const Value.absent(),
    this.solvedTimezone = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.totalPausedMs = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.checkCount = const Value.absent(),
    this.revealCount = const Value.absent(),
    this.usedCheck = const Value.absent(),
    this.usedReveal = const Value.absent(),
    this.cleanSolveEligible = const Value.absent(),
    this.focusRow = const Value.absent(),
    this.focusCol = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SolveSessionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String deviceId,
    this.status = const Value.absent(),
    this.completionType = const Value.absent(),
    required DateTime startedAt,
    required DateTime lastPlayedAt,
    this.completedAt = const Value.absent(),
    this.solvedDateLocal = const Value.absent(),
    this.solvedTimezone = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.totalPausedMs = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.checkCount = const Value.absent(),
    this.revealCount = const Value.absent(),
    this.usedCheck = const Value.absent(),
    this.usedReveal = const Value.absent(),
    this.cleanSolveEligible = const Value.absent(),
    this.focusRow = const Value.absent(),
    this.focusCol = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncVersion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : puzzleId = Value(puzzleId),
        deviceId = Value(deviceId),
        startedAt = Value(startedAt),
        lastPlayedAt = Value(lastPlayedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SolveSessionRow> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? deviceId,
    Expression<String>? status,
    Expression<String>? completionType,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? solvedDateLocal,
    Expression<String>? solvedTimezone,
    Expression<int>? elapsedMs,
    Expression<bool>? isPaused,
    Expression<DateTime>? pausedAt,
    Expression<int>? totalPausedMs,
    Expression<int>? mistakeCount,
    Expression<int>? checkCount,
    Expression<int>? revealCount,
    Expression<bool>? usedCheck,
    Expression<bool>? usedReveal,
    Expression<bool>? cleanSolveEligible,
    Expression<int>? focusRow,
    Expression<int>? focusCol,
    Expression<String>? direction,
    Expression<bool>? isSynced,
    Expression<int>? syncVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (deviceId != null) 'device_id': deviceId,
      if (status != null) 'status': status,
      if (completionType != null) 'completion_type': completionType,
      if (startedAt != null) 'started_at': startedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (solvedDateLocal != null) 'solved_date_local': solvedDateLocal,
      if (solvedTimezone != null) 'solved_timezone': solvedTimezone,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (isPaused != null) 'is_paused': isPaused,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (totalPausedMs != null) 'total_paused_ms': totalPausedMs,
      if (mistakeCount != null) 'mistake_count': mistakeCount,
      if (checkCount != null) 'check_count': checkCount,
      if (revealCount != null) 'reveal_count': revealCount,
      if (usedCheck != null) 'used_check': usedCheck,
      if (usedReveal != null) 'used_reveal': usedReveal,
      if (cleanSolveEligible != null)
        'clean_solve_eligible': cleanSolveEligible,
      if (focusRow != null) 'focus_row': focusRow,
      if (focusCol != null) 'focus_col': focusCol,
      if (direction != null) 'direction': direction,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SolveSessionsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? puzzleId,
      Value<String>? deviceId,
      Value<String>? status,
      Value<String?>? completionType,
      Value<DateTime>? startedAt,
      Value<DateTime>? lastPlayedAt,
      Value<DateTime?>? completedAt,
      Value<String?>? solvedDateLocal,
      Value<String?>? solvedTimezone,
      Value<int>? elapsedMs,
      Value<bool>? isPaused,
      Value<DateTime?>? pausedAt,
      Value<int>? totalPausedMs,
      Value<int>? mistakeCount,
      Value<int>? checkCount,
      Value<int>? revealCount,
      Value<bool>? usedCheck,
      Value<bool>? usedReveal,
      Value<bool>? cleanSolveEligible,
      Value<int>? focusRow,
      Value<int>? focusCol,
      Value<String>? direction,
      Value<bool>? isSynced,
      Value<int>? syncVersion,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SolveSessionsTableCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      completionType: completionType ?? this.completionType,
      startedAt: startedAt ?? this.startedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      completedAt: completedAt ?? this.completedAt,
      solvedDateLocal: solvedDateLocal ?? this.solvedDateLocal,
      solvedTimezone: solvedTimezone ?? this.solvedTimezone,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isPaused: isPaused ?? this.isPaused,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPausedMs: totalPausedMs ?? this.totalPausedMs,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      checkCount: checkCount ?? this.checkCount,
      revealCount: revealCount ?? this.revealCount,
      usedCheck: usedCheck ?? this.usedCheck,
      usedReveal: usedReveal ?? this.usedReveal,
      cleanSolveEligible: cleanSolveEligible ?? this.cleanSolveEligible,
      focusRow: focusRow ?? this.focusRow,
      focusCol: focusCol ?? this.focusCol,
      direction: direction ?? this.direction,
      isSynced: isSynced ?? this.isSynced,
      syncVersion: syncVersion ?? this.syncVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completionType.present) {
      map['completion_type'] = Variable<String>(completionType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (solvedDateLocal.present) {
      map['solved_date_local'] = Variable<String>(solvedDateLocal.value);
    }
    if (solvedTimezone.present) {
      map['solved_timezone'] = Variable<String>(solvedTimezone.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (totalPausedMs.present) {
      map['total_paused_ms'] = Variable<int>(totalPausedMs.value);
    }
    if (mistakeCount.present) {
      map['mistake_count'] = Variable<int>(mistakeCount.value);
    }
    if (checkCount.present) {
      map['check_count'] = Variable<int>(checkCount.value);
    }
    if (revealCount.present) {
      map['reveal_count'] = Variable<int>(revealCount.value);
    }
    if (usedCheck.present) {
      map['used_check'] = Variable<bool>(usedCheck.value);
    }
    if (usedReveal.present) {
      map['used_reveal'] = Variable<bool>(usedReveal.value);
    }
    if (cleanSolveEligible.present) {
      map['clean_solve_eligible'] = Variable<bool>(cleanSolveEligible.value);
    }
    if (focusRow.present) {
      map['focus_row'] = Variable<int>(focusRow.value);
    }
    if (focusCol.present) {
      map['focus_col'] = Variable<int>(focusCol.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolveSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('deviceId: $deviceId, ')
          ..write('status: $status, ')
          ..write('completionType: $completionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('isPaused: $isPaused, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('totalPausedMs: $totalPausedMs, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('checkCount: $checkCount, ')
          ..write('revealCount: $revealCount, ')
          ..write('usedCheck: $usedCheck, ')
          ..write('usedReveal: $usedReveal, ')
          ..write('cleanSolveEligible: $cleanSolveEligible, ')
          ..write('focusRow: $focusRow, ')
          ..write('focusCol: $focusCol, ')
          ..write('direction: $direction, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CellProgressTableTable extends CellProgressTable
    with TableInfo<$CellProgressTableTable, CellProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CellProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES solve_sessions (id) ON DELETE CASCADE'));
  static const VerificationMeta _rowMeta = const VerificationMeta('row');
  @override
  late final GeneratedColumn<int> row = GeneratedColumn<int>(
      'row', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colMeta = const VerificationMeta('col');
  @override
  late final GeneratedColumn<int> col = GeneratedColumn<int>(
      'col', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _guessMeta = const VerificationMeta('guess');
  @override
  late final GeneratedColumn<String> guess = GeneratedColumn<String>(
      'guess', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('empty'));
  static const VerificationMeta _wasCheckedMeta =
      const VerificationMeta('wasChecked');
  @override
  late final GeneratedColumn<bool> wasChecked = GeneratedColumn<bool>(
      'was_checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("was_checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _wasRevealedMeta =
      const VerificationMeta('wasRevealed');
  @override
  late final GeneratedColumn<bool> wasRevealed = GeneratedColumn<bool>(
      'was_revealed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_revealed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastWrongGuessHashMeta =
      const VerificationMeta('lastWrongGuessHash');
  @override
  late final GeneratedColumn<String> lastWrongGuessHash =
      GeneratedColumn<String>('last_wrong_guess_hash', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPencilMeta =
      const VerificationMeta('isPencil');
  @override
  late final GeneratedColumn<bool> isPencil = GeneratedColumn<bool>(
      'is_pencil', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pencil" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        row,
        col,
        guess,
        state,
        wasChecked,
        wasRevealed,
        lastWrongGuessHash,
        isPencil,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cell_progress';
  @override
  VerificationContext validateIntegrity(Insertable<CellProgressRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('row')) {
      context.handle(
          _rowMeta, row.isAcceptableOrUnknown(data['row']!, _rowMeta));
    } else if (isInserting) {
      context.missing(_rowMeta);
    }
    if (data.containsKey('col')) {
      context.handle(
          _colMeta, col.isAcceptableOrUnknown(data['col']!, _colMeta));
    } else if (isInserting) {
      context.missing(_colMeta);
    }
    if (data.containsKey('guess')) {
      context.handle(
          _guessMeta, guess.isAcceptableOrUnknown(data['guess']!, _guessMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('was_checked')) {
      context.handle(
          _wasCheckedMeta,
          wasChecked.isAcceptableOrUnknown(
              data['was_checked']!, _wasCheckedMeta));
    }
    if (data.containsKey('was_revealed')) {
      context.handle(
          _wasRevealedMeta,
          wasRevealed.isAcceptableOrUnknown(
              data['was_revealed']!, _wasRevealedMeta));
    }
    if (data.containsKey('last_wrong_guess_hash')) {
      context.handle(
          _lastWrongGuessHashMeta,
          lastWrongGuessHash.isAcceptableOrUnknown(
              data['last_wrong_guess_hash']!, _lastWrongGuessHashMeta));
    }
    if (data.containsKey('is_pencil')) {
      context.handle(_isPencilMeta,
          isPencil.isAcceptableOrUnknown(data['is_pencil']!, _isPencilMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, row, col};
  @override
  CellProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CellProgressRow(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      row: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row'])!,
      col: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}col'])!,
      guess: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guess']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      wasChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_checked'])!,
      wasRevealed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_revealed'])!,
      lastWrongGuessHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_wrong_guess_hash']),
      isPencil: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pencil'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CellProgressTableTable createAlias(String alias) {
    return $CellProgressTableTable(attachedDatabase, alias);
  }
}

class CellProgressRow extends DataClass implements Insertable<CellProgressRow> {
  final int sessionId;
  final int row;
  final int col;
  final String? guess;

  /// CellState as string: empty | filled | checkedCorrect | checkedIncorrect | revealed
  final String state;
  final bool wasChecked;
  final bool wasRevealed;

  /// Hash of the last wrong guess to avoid double-counting mistakes.
  final String? lastWrongGuessHash;

  /// Reserved for a future pencil-mode feature — present in the schema now so
  /// adding the feature later does not require a migration.
  final bool isPencil;
  final DateTime updatedAt;
  const CellProgressRow(
      {required this.sessionId,
      required this.row,
      required this.col,
      this.guess,
      required this.state,
      required this.wasChecked,
      required this.wasRevealed,
      this.lastWrongGuessHash,
      required this.isPencil,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['row'] = Variable<int>(row);
    map['col'] = Variable<int>(col);
    if (!nullToAbsent || guess != null) {
      map['guess'] = Variable<String>(guess);
    }
    map['state'] = Variable<String>(state);
    map['was_checked'] = Variable<bool>(wasChecked);
    map['was_revealed'] = Variable<bool>(wasRevealed);
    if (!nullToAbsent || lastWrongGuessHash != null) {
      map['last_wrong_guess_hash'] = Variable<String>(lastWrongGuessHash);
    }
    map['is_pencil'] = Variable<bool>(isPencil);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CellProgressTableCompanion toCompanion(bool nullToAbsent) {
    return CellProgressTableCompanion(
      sessionId: Value(sessionId),
      row: Value(row),
      col: Value(col),
      guess:
          guess == null && nullToAbsent ? const Value.absent() : Value(guess),
      state: Value(state),
      wasChecked: Value(wasChecked),
      wasRevealed: Value(wasRevealed),
      lastWrongGuessHash: lastWrongGuessHash == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWrongGuessHash),
      isPencil: Value(isPencil),
      updatedAt: Value(updatedAt),
    );
  }

  factory CellProgressRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CellProgressRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      row: serializer.fromJson<int>(json['row']),
      col: serializer.fromJson<int>(json['col']),
      guess: serializer.fromJson<String?>(json['guess']),
      state: serializer.fromJson<String>(json['state']),
      wasChecked: serializer.fromJson<bool>(json['wasChecked']),
      wasRevealed: serializer.fromJson<bool>(json['wasRevealed']),
      lastWrongGuessHash:
          serializer.fromJson<String?>(json['lastWrongGuessHash']),
      isPencil: serializer.fromJson<bool>(json['isPencil']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'row': serializer.toJson<int>(row),
      'col': serializer.toJson<int>(col),
      'guess': serializer.toJson<String?>(guess),
      'state': serializer.toJson<String>(state),
      'wasChecked': serializer.toJson<bool>(wasChecked),
      'wasRevealed': serializer.toJson<bool>(wasRevealed),
      'lastWrongGuessHash': serializer.toJson<String?>(lastWrongGuessHash),
      'isPencil': serializer.toJson<bool>(isPencil),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CellProgressRow copyWith(
          {int? sessionId,
          int? row,
          int? col,
          Value<String?> guess = const Value.absent(),
          String? state,
          bool? wasChecked,
          bool? wasRevealed,
          Value<String?> lastWrongGuessHash = const Value.absent(),
          bool? isPencil,
          DateTime? updatedAt}) =>
      CellProgressRow(
        sessionId: sessionId ?? this.sessionId,
        row: row ?? this.row,
        col: col ?? this.col,
        guess: guess.present ? guess.value : this.guess,
        state: state ?? this.state,
        wasChecked: wasChecked ?? this.wasChecked,
        wasRevealed: wasRevealed ?? this.wasRevealed,
        lastWrongGuessHash: lastWrongGuessHash.present
            ? lastWrongGuessHash.value
            : this.lastWrongGuessHash,
        isPencil: isPencil ?? this.isPencil,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CellProgressRow copyWithCompanion(CellProgressTableCompanion data) {
    return CellProgressRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      row: data.row.present ? data.row.value : this.row,
      col: data.col.present ? data.col.value : this.col,
      guess: data.guess.present ? data.guess.value : this.guess,
      state: data.state.present ? data.state.value : this.state,
      wasChecked:
          data.wasChecked.present ? data.wasChecked.value : this.wasChecked,
      wasRevealed:
          data.wasRevealed.present ? data.wasRevealed.value : this.wasRevealed,
      lastWrongGuessHash: data.lastWrongGuessHash.present
          ? data.lastWrongGuessHash.value
          : this.lastWrongGuessHash,
      isPencil: data.isPencil.present ? data.isPencil.value : this.isPencil,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CellProgressRow(')
          ..write('sessionId: $sessionId, ')
          ..write('row: $row, ')
          ..write('col: $col, ')
          ..write('guess: $guess, ')
          ..write('state: $state, ')
          ..write('wasChecked: $wasChecked, ')
          ..write('wasRevealed: $wasRevealed, ')
          ..write('lastWrongGuessHash: $lastWrongGuessHash, ')
          ..write('isPencil: $isPencil, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, row, col, guess, state, wasChecked,
      wasRevealed, lastWrongGuessHash, isPencil, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CellProgressRow &&
          other.sessionId == this.sessionId &&
          other.row == this.row &&
          other.col == this.col &&
          other.guess == this.guess &&
          other.state == this.state &&
          other.wasChecked == this.wasChecked &&
          other.wasRevealed == this.wasRevealed &&
          other.lastWrongGuessHash == this.lastWrongGuessHash &&
          other.isPencil == this.isPencil &&
          other.updatedAt == this.updatedAt);
}

class CellProgressTableCompanion extends UpdateCompanion<CellProgressRow> {
  final Value<int> sessionId;
  final Value<int> row;
  final Value<int> col;
  final Value<String?> guess;
  final Value<String> state;
  final Value<bool> wasChecked;
  final Value<bool> wasRevealed;
  final Value<String?> lastWrongGuessHash;
  final Value<bool> isPencil;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CellProgressTableCompanion({
    this.sessionId = const Value.absent(),
    this.row = const Value.absent(),
    this.col = const Value.absent(),
    this.guess = const Value.absent(),
    this.state = const Value.absent(),
    this.wasChecked = const Value.absent(),
    this.wasRevealed = const Value.absent(),
    this.lastWrongGuessHash = const Value.absent(),
    this.isPencil = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CellProgressTableCompanion.insert({
    required int sessionId,
    required int row,
    required int col,
    this.guess = const Value.absent(),
    this.state = const Value.absent(),
    this.wasChecked = const Value.absent(),
    this.wasRevealed = const Value.absent(),
    this.lastWrongGuessHash = const Value.absent(),
    this.isPencil = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        row = Value(row),
        col = Value(col),
        updatedAt = Value(updatedAt);
  static Insertable<CellProgressRow> custom({
    Expression<int>? sessionId,
    Expression<int>? row,
    Expression<int>? col,
    Expression<String>? guess,
    Expression<String>? state,
    Expression<bool>? wasChecked,
    Expression<bool>? wasRevealed,
    Expression<String>? lastWrongGuessHash,
    Expression<bool>? isPencil,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (row != null) 'row': row,
      if (col != null) 'col': col,
      if (guess != null) 'guess': guess,
      if (state != null) 'state': state,
      if (wasChecked != null) 'was_checked': wasChecked,
      if (wasRevealed != null) 'was_revealed': wasRevealed,
      if (lastWrongGuessHash != null)
        'last_wrong_guess_hash': lastWrongGuessHash,
      if (isPencil != null) 'is_pencil': isPencil,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CellProgressTableCompanion copyWith(
      {Value<int>? sessionId,
      Value<int>? row,
      Value<int>? col,
      Value<String?>? guess,
      Value<String>? state,
      Value<bool>? wasChecked,
      Value<bool>? wasRevealed,
      Value<String?>? lastWrongGuessHash,
      Value<bool>? isPencil,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CellProgressTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      row: row ?? this.row,
      col: col ?? this.col,
      guess: guess ?? this.guess,
      state: state ?? this.state,
      wasChecked: wasChecked ?? this.wasChecked,
      wasRevealed: wasRevealed ?? this.wasRevealed,
      lastWrongGuessHash: lastWrongGuessHash ?? this.lastWrongGuessHash,
      isPencil: isPencil ?? this.isPencil,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (row.present) {
      map['row'] = Variable<int>(row.value);
    }
    if (col.present) {
      map['col'] = Variable<int>(col.value);
    }
    if (guess.present) {
      map['guess'] = Variable<String>(guess.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (wasChecked.present) {
      map['was_checked'] = Variable<bool>(wasChecked.value);
    }
    if (wasRevealed.present) {
      map['was_revealed'] = Variable<bool>(wasRevealed.value);
    }
    if (lastWrongGuessHash.present) {
      map['last_wrong_guess_hash'] = Variable<String>(lastWrongGuessHash.value);
    }
    if (isPencil.present) {
      map['is_pencil'] = Variable<bool>(isPencil.value);
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
    return (StringBuffer('CellProgressTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('row: $row, ')
          ..write('col: $col, ')
          ..write('guess: $guess, ')
          ..write('state: $state, ')
          ..write('wasChecked: $wasChecked, ')
          ..write('wasRevealed: $wasRevealed, ')
          ..write('lastWrongGuessHash: $lastWrongGuessHash, ')
          ..write('isPencil: $isPencil, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueJsonMeta =
      const VerificationMeta('valueJson');
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
      'value_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(_valueJsonMeta,
          valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta));
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      valueJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String valueJson;
  final DateTime updatedAt;
  const AppSettingRow(
      {required this.key, required this.valueJson, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith(
          {String? key, String? valueJson, DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsTableCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    required String key,
    required String valueJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        valueJson = Value(valueJson),
        updatedAt = Value(updatedAt);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsTableCompanion copyWith(
      {Value<String>? key,
      Value<String>? valueJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsTableCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
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
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportedSolveStatsTableTable extends ImportedSolveStatsTable
    with TableInfo<$ImportedSolveStatsTableTable, ImportedSolveStatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportedSolveStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _completionTypeMeta =
      const VerificationMeta('completionType');
  @override
  late final GeneratedColumn<String> completionType = GeneratedColumn<String>(
      'completion_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _elapsedMsMeta =
      const VerificationMeta('elapsedMs');
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
      'elapsed_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _solvedDateLocalMeta =
      const VerificationMeta('solvedDateLocal');
  @override
  late final GeneratedColumn<String> solvedDateLocal = GeneratedColumn<String>(
      'solved_date_local', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _solvedTimezoneMeta =
      const VerificationMeta('solvedTimezone');
  @override
  late final GeneratedColumn<String> solvedTimezone = GeneratedColumn<String>(
      'solved_timezone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _puzzleTitleMeta =
      const VerificationMeta('puzzleTitle');
  @override
  late final GeneratedColumn<String> puzzleTitle = GeneratedColumn<String>(
      'puzzle_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        completionType,
        elapsedMs,
        solvedDateLocal,
        solvedTimezone,
        width,
        height,
        puzzleTitle,
        importedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'imported_solve_stats';
  @override
  VerificationContext validateIntegrity(
      Insertable<ImportedSolveStatRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('completion_type')) {
      context.handle(
          _completionTypeMeta,
          completionType.isAcceptableOrUnknown(
              data['completion_type']!, _completionTypeMeta));
    } else if (isInserting) {
      context.missing(_completionTypeMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(_elapsedMsMeta,
          elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta));
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('solved_date_local')) {
      context.handle(
          _solvedDateLocalMeta,
          solvedDateLocal.isAcceptableOrUnknown(
              data['solved_date_local']!, _solvedDateLocalMeta));
    } else if (isInserting) {
      context.missing(_solvedDateLocalMeta);
    }
    if (data.containsKey('solved_timezone')) {
      context.handle(
          _solvedTimezoneMeta,
          solvedTimezone.isAcceptableOrUnknown(
              data['solved_timezone']!, _solvedTimezoneMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('puzzle_title')) {
      context.handle(
          _puzzleTitleMeta,
          puzzleTitle.isAcceptableOrUnknown(
              data['puzzle_title']!, _puzzleTitleMeta));
    } else if (isInserting) {
      context.missing(_puzzleTitleMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {puzzleTitle, solvedDateLocal},
      ];
  @override
  ImportedSolveStatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportedSolveStatRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      completionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}completion_type'])!,
      elapsedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_ms'])!,
      solvedDateLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}solved_date_local'])!,
      solvedTimezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}solved_timezone']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      puzzleTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}puzzle_title'])!,
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}imported_at'])!,
    );
  }

  @override
  $ImportedSolveStatsTableTable createAlias(String alias) {
    return $ImportedSolveStatsTableTable(attachedDatabase, alias);
  }
}

class ImportedSolveStatRow extends DataClass
    implements Insertable<ImportedSolveStatRow> {
  final int id;
  final String completionType;
  final int elapsedMs;
  final String solvedDateLocal;
  final String? solvedTimezone;
  final int width;
  final int height;
  final String puzzleTitle;
  final DateTime importedAt;
  const ImportedSolveStatRow(
      {required this.id,
      required this.completionType,
      required this.elapsedMs,
      required this.solvedDateLocal,
      this.solvedTimezone,
      required this.width,
      required this.height,
      required this.puzzleTitle,
      required this.importedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['completion_type'] = Variable<String>(completionType);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['solved_date_local'] = Variable<String>(solvedDateLocal);
    if (!nullToAbsent || solvedTimezone != null) {
      map['solved_timezone'] = Variable<String>(solvedTimezone);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['puzzle_title'] = Variable<String>(puzzleTitle);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportedSolveStatsTableCompanion toCompanion(bool nullToAbsent) {
    return ImportedSolveStatsTableCompanion(
      id: Value(id),
      completionType: Value(completionType),
      elapsedMs: Value(elapsedMs),
      solvedDateLocal: Value(solvedDateLocal),
      solvedTimezone: solvedTimezone == null && nullToAbsent
          ? const Value.absent()
          : Value(solvedTimezone),
      width: Value(width),
      height: Value(height),
      puzzleTitle: Value(puzzleTitle),
      importedAt: Value(importedAt),
    );
  }

  factory ImportedSolveStatRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportedSolveStatRow(
      id: serializer.fromJson<int>(json['id']),
      completionType: serializer.fromJson<String>(json['completionType']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      solvedDateLocal: serializer.fromJson<String>(json['solvedDateLocal']),
      solvedTimezone: serializer.fromJson<String?>(json['solvedTimezone']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      puzzleTitle: serializer.fromJson<String>(json['puzzleTitle']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'completionType': serializer.toJson<String>(completionType),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'solvedDateLocal': serializer.toJson<String>(solvedDateLocal),
      'solvedTimezone': serializer.toJson<String?>(solvedTimezone),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'puzzleTitle': serializer.toJson<String>(puzzleTitle),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ImportedSolveStatRow copyWith(
          {int? id,
          String? completionType,
          int? elapsedMs,
          String? solvedDateLocal,
          Value<String?> solvedTimezone = const Value.absent(),
          int? width,
          int? height,
          String? puzzleTitle,
          DateTime? importedAt}) =>
      ImportedSolveStatRow(
        id: id ?? this.id,
        completionType: completionType ?? this.completionType,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        solvedDateLocal: solvedDateLocal ?? this.solvedDateLocal,
        solvedTimezone:
            solvedTimezone.present ? solvedTimezone.value : this.solvedTimezone,
        width: width ?? this.width,
        height: height ?? this.height,
        puzzleTitle: puzzleTitle ?? this.puzzleTitle,
        importedAt: importedAt ?? this.importedAt,
      );
  ImportedSolveStatRow copyWithCompanion(
      ImportedSolveStatsTableCompanion data) {
    return ImportedSolveStatRow(
      id: data.id.present ? data.id.value : this.id,
      completionType: data.completionType.present
          ? data.completionType.value
          : this.completionType,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      solvedDateLocal: data.solvedDateLocal.present
          ? data.solvedDateLocal.value
          : this.solvedDateLocal,
      solvedTimezone: data.solvedTimezone.present
          ? data.solvedTimezone.value
          : this.solvedTimezone,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      puzzleTitle:
          data.puzzleTitle.present ? data.puzzleTitle.value : this.puzzleTitle,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportedSolveStatRow(')
          ..write('id: $id, ')
          ..write('completionType: $completionType, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('puzzleTitle: $puzzleTitle, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, completionType, elapsedMs,
      solvedDateLocal, solvedTimezone, width, height, puzzleTitle, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportedSolveStatRow &&
          other.id == this.id &&
          other.completionType == this.completionType &&
          other.elapsedMs == this.elapsedMs &&
          other.solvedDateLocal == this.solvedDateLocal &&
          other.solvedTimezone == this.solvedTimezone &&
          other.width == this.width &&
          other.height == this.height &&
          other.puzzleTitle == this.puzzleTitle &&
          other.importedAt == this.importedAt);
}

class ImportedSolveStatsTableCompanion
    extends UpdateCompanion<ImportedSolveStatRow> {
  final Value<int> id;
  final Value<String> completionType;
  final Value<int> elapsedMs;
  final Value<String> solvedDateLocal;
  final Value<String?> solvedTimezone;
  final Value<int> width;
  final Value<int> height;
  final Value<String> puzzleTitle;
  final Value<DateTime> importedAt;
  const ImportedSolveStatsTableCompanion({
    this.id = const Value.absent(),
    this.completionType = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.solvedDateLocal = const Value.absent(),
    this.solvedTimezone = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.puzzleTitle = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  ImportedSolveStatsTableCompanion.insert({
    this.id = const Value.absent(),
    required String completionType,
    required int elapsedMs,
    required String solvedDateLocal,
    this.solvedTimezone = const Value.absent(),
    required int width,
    required int height,
    required String puzzleTitle,
    required DateTime importedAt,
  })  : completionType = Value(completionType),
        elapsedMs = Value(elapsedMs),
        solvedDateLocal = Value(solvedDateLocal),
        width = Value(width),
        height = Value(height),
        puzzleTitle = Value(puzzleTitle),
        importedAt = Value(importedAt);
  static Insertable<ImportedSolveStatRow> custom({
    Expression<int>? id,
    Expression<String>? completionType,
    Expression<int>? elapsedMs,
    Expression<String>? solvedDateLocal,
    Expression<String>? solvedTimezone,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? puzzleTitle,
    Expression<DateTime>? importedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completionType != null) 'completion_type': completionType,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (solvedDateLocal != null) 'solved_date_local': solvedDateLocal,
      if (solvedTimezone != null) 'solved_timezone': solvedTimezone,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (puzzleTitle != null) 'puzzle_title': puzzleTitle,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  ImportedSolveStatsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? completionType,
      Value<int>? elapsedMs,
      Value<String>? solvedDateLocal,
      Value<String?>? solvedTimezone,
      Value<int>? width,
      Value<int>? height,
      Value<String>? puzzleTitle,
      Value<DateTime>? importedAt}) {
    return ImportedSolveStatsTableCompanion(
      id: id ?? this.id,
      completionType: completionType ?? this.completionType,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      solvedDateLocal: solvedDateLocal ?? this.solvedDateLocal,
      solvedTimezone: solvedTimezone ?? this.solvedTimezone,
      width: width ?? this.width,
      height: height ?? this.height,
      puzzleTitle: puzzleTitle ?? this.puzzleTitle,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (completionType.present) {
      map['completion_type'] = Variable<String>(completionType.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (solvedDateLocal.present) {
      map['solved_date_local'] = Variable<String>(solvedDateLocal.value);
    }
    if (solvedTimezone.present) {
      map['solved_timezone'] = Variable<String>(solvedTimezone.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (puzzleTitle.present) {
      map['puzzle_title'] = Variable<String>(puzzleTitle.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportedSolveStatsTableCompanion(')
          ..write('id: $id, ')
          ..write('completionType: $completionType, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('puzzleTitle: $puzzleTitle, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

class $PuzzleCompletionsTableTable extends PuzzleCompletionsTable
    with TableInfo<$PuzzleCompletionsTableTable, PuzzleCompletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleCompletionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _puzzleIdMeta =
      const VerificationMeta('puzzleId');
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
      'puzzle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES puzzles (id) ON DELETE CASCADE'));
  static const VerificationMeta _completionTypeMeta =
      const VerificationMeta('completionType');
  @override
  late final GeneratedColumn<String> completionType = GeneratedColumn<String>(
      'completion_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _solvedDateLocalMeta =
      const VerificationMeta('solvedDateLocal');
  @override
  late final GeneratedColumn<String> solvedDateLocal = GeneratedColumn<String>(
      'solved_date_local', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _solvedTimezoneMeta =
      const VerificationMeta('solvedTimezone');
  @override
  late final GeneratedColumn<String> solvedTimezone = GeneratedColumn<String>(
      'solved_timezone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _elapsedMsMeta =
      const VerificationMeta('elapsedMs');
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
      'elapsed_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _checkCountMeta =
      const VerificationMeta('checkCount');
  @override
  late final GeneratedColumn<int> checkCount = GeneratedColumn<int>(
      'check_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _revealCountMeta =
      const VerificationMeta('revealCount');
  @override
  late final GeneratedColumn<int> revealCount = GeneratedColumn<int>(
      'reveal_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        puzzleId,
        completionType,
        completedAt,
        solvedDateLocal,
        solvedTimezone,
        elapsedMs,
        checkCount,
        revealCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_completions';
  @override
  VerificationContext validateIntegrity(
      Insertable<PuzzleCompletionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(_puzzleIdMeta,
          puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta));
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('completion_type')) {
      context.handle(
          _completionTypeMeta,
          completionType.isAcceptableOrUnknown(
              data['completion_type']!, _completionTypeMeta));
    } else if (isInserting) {
      context.missing(_completionTypeMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('solved_date_local')) {
      context.handle(
          _solvedDateLocalMeta,
          solvedDateLocal.isAcceptableOrUnknown(
              data['solved_date_local']!, _solvedDateLocalMeta));
    } else if (isInserting) {
      context.missing(_solvedDateLocalMeta);
    }
    if (data.containsKey('solved_timezone')) {
      context.handle(
          _solvedTimezoneMeta,
          solvedTimezone.isAcceptableOrUnknown(
              data['solved_timezone']!, _solvedTimezoneMeta));
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(_elapsedMsMeta,
          elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta));
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('check_count')) {
      context.handle(
          _checkCountMeta,
          checkCount.isAcceptableOrUnknown(
              data['check_count']!, _checkCountMeta));
    }
    if (data.containsKey('reveal_count')) {
      context.handle(
          _revealCountMeta,
          revealCount.isAcceptableOrUnknown(
              data['reveal_count']!, _revealCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuzzleCompletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleCompletionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      puzzleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}puzzle_id'])!,
      completionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}completion_type'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      solvedDateLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}solved_date_local'])!,
      solvedTimezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}solved_timezone']),
      elapsedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_ms'])!,
      checkCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}check_count'])!,
      revealCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reveal_count'])!,
    );
  }

  @override
  $PuzzleCompletionsTableTable createAlias(String alias) {
    return $PuzzleCompletionsTableTable(attachedDatabase, alias);
  }
}

class PuzzleCompletionRow extends DataClass
    implements Insertable<PuzzleCompletionRow> {
  final int id;
  final String puzzleId;

  /// DB values: clean | checked | hinted | revealed
  final String completionType;
  final DateTime completedAt;

  /// Calendar date string in device-local timezone: 'yyyy-MM-dd'.
  final String solvedDateLocal;
  final String? solvedTimezone;
  final int elapsedMs;
  final int checkCount;
  final int revealCount;
  const PuzzleCompletionRow(
      {required this.id,
      required this.puzzleId,
      required this.completionType,
      required this.completedAt,
      required this.solvedDateLocal,
      this.solvedTimezone,
      required this.elapsedMs,
      required this.checkCount,
      required this.revealCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['completion_type'] = Variable<String>(completionType);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['solved_date_local'] = Variable<String>(solvedDateLocal);
    if (!nullToAbsent || solvedTimezone != null) {
      map['solved_timezone'] = Variable<String>(solvedTimezone);
    }
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['check_count'] = Variable<int>(checkCount);
    map['reveal_count'] = Variable<int>(revealCount);
    return map;
  }

  PuzzleCompletionsTableCompanion toCompanion(bool nullToAbsent) {
    return PuzzleCompletionsTableCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      completionType: Value(completionType),
      completedAt: Value(completedAt),
      solvedDateLocal: Value(solvedDateLocal),
      solvedTimezone: solvedTimezone == null && nullToAbsent
          ? const Value.absent()
          : Value(solvedTimezone),
      elapsedMs: Value(elapsedMs),
      checkCount: Value(checkCount),
      revealCount: Value(revealCount),
    );
  }

  factory PuzzleCompletionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleCompletionRow(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      completionType: serializer.fromJson<String>(json['completionType']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      solvedDateLocal: serializer.fromJson<String>(json['solvedDateLocal']),
      solvedTimezone: serializer.fromJson<String?>(json['solvedTimezone']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      checkCount: serializer.fromJson<int>(json['checkCount']),
      revealCount: serializer.fromJson<int>(json['revealCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'completionType': serializer.toJson<String>(completionType),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'solvedDateLocal': serializer.toJson<String>(solvedDateLocal),
      'solvedTimezone': serializer.toJson<String?>(solvedTimezone),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'checkCount': serializer.toJson<int>(checkCount),
      'revealCount': serializer.toJson<int>(revealCount),
    };
  }

  PuzzleCompletionRow copyWith(
          {int? id,
          String? puzzleId,
          String? completionType,
          DateTime? completedAt,
          String? solvedDateLocal,
          Value<String?> solvedTimezone = const Value.absent(),
          int? elapsedMs,
          int? checkCount,
          int? revealCount}) =>
      PuzzleCompletionRow(
        id: id ?? this.id,
        puzzleId: puzzleId ?? this.puzzleId,
        completionType: completionType ?? this.completionType,
        completedAt: completedAt ?? this.completedAt,
        solvedDateLocal: solvedDateLocal ?? this.solvedDateLocal,
        solvedTimezone:
            solvedTimezone.present ? solvedTimezone.value : this.solvedTimezone,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        checkCount: checkCount ?? this.checkCount,
        revealCount: revealCount ?? this.revealCount,
      );
  PuzzleCompletionRow copyWithCompanion(PuzzleCompletionsTableCompanion data) {
    return PuzzleCompletionRow(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      completionType: data.completionType.present
          ? data.completionType.value
          : this.completionType,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      solvedDateLocal: data.solvedDateLocal.present
          ? data.solvedDateLocal.value
          : this.solvedDateLocal,
      solvedTimezone: data.solvedTimezone.present
          ? data.solvedTimezone.value
          : this.solvedTimezone,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      checkCount:
          data.checkCount.present ? data.checkCount.value : this.checkCount,
      revealCount:
          data.revealCount.present ? data.revealCount.value : this.revealCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleCompletionRow(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('completionType: $completionType, ')
          ..write('completedAt: $completedAt, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('checkCount: $checkCount, ')
          ..write('revealCount: $revealCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, puzzleId, completionType, completedAt,
      solvedDateLocal, solvedTimezone, elapsedMs, checkCount, revealCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleCompletionRow &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.completionType == this.completionType &&
          other.completedAt == this.completedAt &&
          other.solvedDateLocal == this.solvedDateLocal &&
          other.solvedTimezone == this.solvedTimezone &&
          other.elapsedMs == this.elapsedMs &&
          other.checkCount == this.checkCount &&
          other.revealCount == this.revealCount);
}

class PuzzleCompletionsTableCompanion
    extends UpdateCompanion<PuzzleCompletionRow> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> completionType;
  final Value<DateTime> completedAt;
  final Value<String> solvedDateLocal;
  final Value<String?> solvedTimezone;
  final Value<int> elapsedMs;
  final Value<int> checkCount;
  final Value<int> revealCount;
  const PuzzleCompletionsTableCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.completionType = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.solvedDateLocal = const Value.absent(),
    this.solvedTimezone = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.checkCount = const Value.absent(),
    this.revealCount = const Value.absent(),
  });
  PuzzleCompletionsTableCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String completionType,
    required DateTime completedAt,
    required String solvedDateLocal,
    this.solvedTimezone = const Value.absent(),
    required int elapsedMs,
    this.checkCount = const Value.absent(),
    this.revealCount = const Value.absent(),
  })  : puzzleId = Value(puzzleId),
        completionType = Value(completionType),
        completedAt = Value(completedAt),
        solvedDateLocal = Value(solvedDateLocal),
        elapsedMs = Value(elapsedMs);
  static Insertable<PuzzleCompletionRow> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? completionType,
    Expression<DateTime>? completedAt,
    Expression<String>? solvedDateLocal,
    Expression<String>? solvedTimezone,
    Expression<int>? elapsedMs,
    Expression<int>? checkCount,
    Expression<int>? revealCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (completionType != null) 'completion_type': completionType,
      if (completedAt != null) 'completed_at': completedAt,
      if (solvedDateLocal != null) 'solved_date_local': solvedDateLocal,
      if (solvedTimezone != null) 'solved_timezone': solvedTimezone,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (checkCount != null) 'check_count': checkCount,
      if (revealCount != null) 'reveal_count': revealCount,
    });
  }

  PuzzleCompletionsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? puzzleId,
      Value<String>? completionType,
      Value<DateTime>? completedAt,
      Value<String>? solvedDateLocal,
      Value<String?>? solvedTimezone,
      Value<int>? elapsedMs,
      Value<int>? checkCount,
      Value<int>? revealCount}) {
    return PuzzleCompletionsTableCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      completionType: completionType ?? this.completionType,
      completedAt: completedAt ?? this.completedAt,
      solvedDateLocal: solvedDateLocal ?? this.solvedDateLocal,
      solvedTimezone: solvedTimezone ?? this.solvedTimezone,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      checkCount: checkCount ?? this.checkCount,
      revealCount: revealCount ?? this.revealCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (completionType.present) {
      map['completion_type'] = Variable<String>(completionType.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (solvedDateLocal.present) {
      map['solved_date_local'] = Variable<String>(solvedDateLocal.value);
    }
    if (solvedTimezone.present) {
      map['solved_timezone'] = Variable<String>(solvedTimezone.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (checkCount.present) {
      map['check_count'] = Variable<int>(checkCount.value);
    }
    if (revealCount.present) {
      map['reveal_count'] = Variable<int>(revealCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleCompletionsTableCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('completionType: $completionType, ')
          ..write('completedAt: $completedAt, ')
          ..write('solvedDateLocal: $solvedDateLocal, ')
          ..write('solvedTimezone: $solvedTimezone, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('checkCount: $checkCount, ')
          ..write('revealCount: $revealCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourcesTableTable sourcesTable = $SourcesTableTable(this);
  late final $PuzzlesTableTable puzzlesTable = $PuzzlesTableTable(this);
  late final $CluesTableTable cluesTable = $CluesTableTable(this);
  late final $SolveSessionsTableTable solveSessionsTable =
      $SolveSessionsTableTable(this);
  late final $CellProgressTableTable cellProgressTable =
      $CellProgressTableTable(this);
  late final $AppSettingsTableTable appSettingsTable =
      $AppSettingsTableTable(this);
  late final $ImportedSolveStatsTableTable importedSolveStatsTable =
      $ImportedSolveStatsTableTable(this);
  late final $PuzzleCompletionsTableTable puzzleCompletionsTable =
      $PuzzleCompletionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        sourcesTable,
        puzzlesTable,
        cluesTable,
        solveSessionsTable,
        cellProgressTable,
        appSettingsTable,
        importedSolveStatsTable,
        puzzleCompletionsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('puzzles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('clues', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('puzzles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('solve_sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('solve_sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('cell_progress', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('puzzles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('puzzle_completions', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SourcesTableTableCreateCompanionBuilder = SourcesTableCompanion
    Function({
  required String id,
  required String displayName,
  required String type,
  Value<String?> homepageUrl,
  Value<String?> termsUrl,
  Value<String?> attribution,
  Value<bool> enabled,
  Value<LicenseStatus> licenseStatus,
  Value<String?> licenseUrl,
  Value<String?> permissionContact,
  Value<bool> attributionRequired,
  Value<String?> cachePolicy,
  Value<bool> rawPayloadRetention,
  Value<bool> commercialUseAllowed,
  Value<DateTime?> lastLegalReviewAt,
  Value<DateTime?> lastCheckedAt,
  Value<DateTime?> lastSuccessAt,
  Value<String?> etag,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SourcesTableTableUpdateCompanionBuilder = SourcesTableCompanion
    Function({
  Value<String> id,
  Value<String> displayName,
  Value<String> type,
  Value<String?> homepageUrl,
  Value<String?> termsUrl,
  Value<String?> attribution,
  Value<bool> enabled,
  Value<LicenseStatus> licenseStatus,
  Value<String?> licenseUrl,
  Value<String?> permissionContact,
  Value<bool> attributionRequired,
  Value<String?> cachePolicy,
  Value<bool> rawPayloadRetention,
  Value<bool> commercialUseAllowed,
  Value<DateTime?> lastLegalReviewAt,
  Value<DateTime?> lastCheckedAt,
  Value<DateTime?> lastSuccessAt,
  Value<String?> etag,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$SourcesTableTableReferences
    extends BaseReferences<_$AppDatabase, $SourcesTableTable, SourceRow> {
  $$SourcesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzlesTableTable, List<PuzzleRow>>
      _puzzlesTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.puzzlesTable,
              aliasName: $_aliasNameGenerator(
                  db.sourcesTable.id, db.puzzlesTable.sourceId));

  $$PuzzlesTableTableProcessedTableManager get puzzlesTableRefs {
    final manager = $$PuzzlesTableTableTableManager($_db, $_db.puzzlesTable)
        .filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_puzzlesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SourcesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTableTable> {
  $$SourcesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get homepageUrl => $composableBuilder(
      column: $table.homepageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get termsUrl => $composableBuilder(
      column: $table.termsUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attribution => $composableBuilder(
      column: $table.attribution, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LicenseStatus, LicenseStatus, String>
      get licenseStatus => $composableBuilder(
          column: $table.licenseStatus,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get licenseUrl => $composableBuilder(
      column: $table.licenseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permissionContact => $composableBuilder(
      column: $table.permissionContact,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get attributionRequired => $composableBuilder(
      column: $table.attributionRequired,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cachePolicy => $composableBuilder(
      column: $table.cachePolicy, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get rawPayloadRetention => $composableBuilder(
      column: $table.rawPayloadRetention,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get commercialUseAllowed => $composableBuilder(
      column: $table.commercialUseAllowed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLegalReviewAt => $composableBuilder(
      column: $table.lastLegalReviewAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
      column: $table.lastCheckedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> puzzlesTableRefs(
      Expression<bool> Function($$PuzzlesTableTableFilterComposer f) f) {
    final $$PuzzlesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.sourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableFilterComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SourcesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTableTable> {
  $$SourcesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get homepageUrl => $composableBuilder(
      column: $table.homepageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get termsUrl => $composableBuilder(
      column: $table.termsUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attribution => $composableBuilder(
      column: $table.attribution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get licenseStatus => $composableBuilder(
      column: $table.licenseStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get licenseUrl => $composableBuilder(
      column: $table.licenseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permissionContact => $composableBuilder(
      column: $table.permissionContact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get attributionRequired => $composableBuilder(
      column: $table.attributionRequired,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cachePolicy => $composableBuilder(
      column: $table.cachePolicy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get rawPayloadRetention => $composableBuilder(
      column: $table.rawPayloadRetention,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get commercialUseAllowed => $composableBuilder(
      column: $table.commercialUseAllowed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLegalReviewAt => $composableBuilder(
      column: $table.lastLegalReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
      column: $table.lastCheckedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SourcesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTableTable> {
  $$SourcesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get homepageUrl => $composableBuilder(
      column: $table.homepageUrl, builder: (column) => column);

  GeneratedColumn<String> get termsUrl =>
      $composableBuilder(column: $table.termsUrl, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
      column: $table.attribution, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LicenseStatus, String> get licenseStatus =>
      $composableBuilder(
          column: $table.licenseStatus, builder: (column) => column);

  GeneratedColumn<String> get licenseUrl => $composableBuilder(
      column: $table.licenseUrl, builder: (column) => column);

  GeneratedColumn<String> get permissionContact => $composableBuilder(
      column: $table.permissionContact, builder: (column) => column);

  GeneratedColumn<bool> get attributionRequired => $composableBuilder(
      column: $table.attributionRequired, builder: (column) => column);

  GeneratedColumn<String> get cachePolicy => $composableBuilder(
      column: $table.cachePolicy, builder: (column) => column);

  GeneratedColumn<bool> get rawPayloadRetention => $composableBuilder(
      column: $table.rawPayloadRetention, builder: (column) => column);

  GeneratedColumn<bool> get commercialUseAllowed => $composableBuilder(
      column: $table.commercialUseAllowed, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLegalReviewAt => $composableBuilder(
      column: $table.lastLegalReviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
      column: $table.lastCheckedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
      column: $table.lastSuccessAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> puzzlesTableRefs<T extends Object>(
      Expression<T> Function($$PuzzlesTableTableAnnotationComposer a) f) {
    final $$PuzzlesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.sourceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SourcesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SourcesTableTable,
    SourceRow,
    $$SourcesTableTableFilterComposer,
    $$SourcesTableTableOrderingComposer,
    $$SourcesTableTableAnnotationComposer,
    $$SourcesTableTableCreateCompanionBuilder,
    $$SourcesTableTableUpdateCompanionBuilder,
    (SourceRow, $$SourcesTableTableReferences),
    SourceRow,
    PrefetchHooks Function({bool puzzlesTableRefs})> {
  $$SourcesTableTableTableManager(_$AppDatabase db, $SourcesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> homepageUrl = const Value.absent(),
            Value<String?> termsUrl = const Value.absent(),
            Value<String?> attribution = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<LicenseStatus> licenseStatus = const Value.absent(),
            Value<String?> licenseUrl = const Value.absent(),
            Value<String?> permissionContact = const Value.absent(),
            Value<bool> attributionRequired = const Value.absent(),
            Value<String?> cachePolicy = const Value.absent(),
            Value<bool> rawPayloadRetention = const Value.absent(),
            Value<bool> commercialUseAllowed = const Value.absent(),
            Value<DateTime?> lastLegalReviewAt = const Value.absent(),
            Value<DateTime?> lastCheckedAt = const Value.absent(),
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<String?> etag = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SourcesTableCompanion(
            id: id,
            displayName: displayName,
            type: type,
            homepageUrl: homepageUrl,
            termsUrl: termsUrl,
            attribution: attribution,
            enabled: enabled,
            licenseStatus: licenseStatus,
            licenseUrl: licenseUrl,
            permissionContact: permissionContact,
            attributionRequired: attributionRequired,
            cachePolicy: cachePolicy,
            rawPayloadRetention: rawPayloadRetention,
            commercialUseAllowed: commercialUseAllowed,
            lastLegalReviewAt: lastLegalReviewAt,
            lastCheckedAt: lastCheckedAt,
            lastSuccessAt: lastSuccessAt,
            etag: etag,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String displayName,
            required String type,
            Value<String?> homepageUrl = const Value.absent(),
            Value<String?> termsUrl = const Value.absent(),
            Value<String?> attribution = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<LicenseStatus> licenseStatus = const Value.absent(),
            Value<String?> licenseUrl = const Value.absent(),
            Value<String?> permissionContact = const Value.absent(),
            Value<bool> attributionRequired = const Value.absent(),
            Value<String?> cachePolicy = const Value.absent(),
            Value<bool> rawPayloadRetention = const Value.absent(),
            Value<bool> commercialUseAllowed = const Value.absent(),
            Value<DateTime?> lastLegalReviewAt = const Value.absent(),
            Value<DateTime?> lastCheckedAt = const Value.absent(),
            Value<DateTime?> lastSuccessAt = const Value.absent(),
            Value<String?> etag = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SourcesTableCompanion.insert(
            id: id,
            displayName: displayName,
            type: type,
            homepageUrl: homepageUrl,
            termsUrl: termsUrl,
            attribution: attribution,
            enabled: enabled,
            licenseStatus: licenseStatus,
            licenseUrl: licenseUrl,
            permissionContact: permissionContact,
            attributionRequired: attributionRequired,
            cachePolicy: cachePolicy,
            rawPayloadRetention: rawPayloadRetention,
            commercialUseAllowed: commercialUseAllowed,
            lastLegalReviewAt: lastLegalReviewAt,
            lastCheckedAt: lastCheckedAt,
            lastSuccessAt: lastSuccessAt,
            etag: etag,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SourcesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({puzzlesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (puzzlesTableRefs) db.puzzlesTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (puzzlesTableRefs)
                    await $_getPrefetchedData<SourceRow, $SourcesTableTable,
                            PuzzleRow>(
                        currentTable: table,
                        referencedTable: $$SourcesTableTableReferences
                            ._puzzlesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SourcesTableTableReferences(db, table, p0)
                                .puzzlesTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.sourceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SourcesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SourcesTableTable,
    SourceRow,
    $$SourcesTableTableFilterComposer,
    $$SourcesTableTableOrderingComposer,
    $$SourcesTableTableAnnotationComposer,
    $$SourcesTableTableCreateCompanionBuilder,
    $$SourcesTableTableUpdateCompanionBuilder,
    (SourceRow, $$SourcesTableTableReferences),
    SourceRow,
    PrefetchHooks Function({bool puzzlesTableRefs})>;
typedef $$PuzzlesTableTableCreateCompanionBuilder = PuzzlesTableCompanion
    Function({
  required String id,
  required String sourceId,
  Value<String?> sourcePuzzleId,
  required String format,
  required String title,
  Value<String?> author,
  Value<String?> editor,
  Value<String?> publisher,
  Value<String?> copyright,
  Value<String?> notes,
  Value<DateTime?> publishDate,
  Value<String?> difficulty,
  required int width,
  required int height,
  required String checksum,
  required String canonicalJson,
  Value<String?> rawPayload,
  Value<DateTime?> fetchedAt,
  Value<DateTime?> expiresAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PuzzlesTableTableUpdateCompanionBuilder = PuzzlesTableCompanion
    Function({
  Value<String> id,
  Value<String> sourceId,
  Value<String?> sourcePuzzleId,
  Value<String> format,
  Value<String> title,
  Value<String?> author,
  Value<String?> editor,
  Value<String?> publisher,
  Value<String?> copyright,
  Value<String?> notes,
  Value<DateTime?> publishDate,
  Value<String?> difficulty,
  Value<int> width,
  Value<int> height,
  Value<String> checksum,
  Value<String> canonicalJson,
  Value<String?> rawPayload,
  Value<DateTime?> fetchedAt,
  Value<DateTime?> expiresAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$PuzzlesTableTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzlesTableTable, PuzzleRow> {
  $$PuzzlesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTableTable _sourceIdTable(_$AppDatabase db) =>
      db.sourcesTable.createAlias(
          $_aliasNameGenerator(db.puzzlesTable.sourceId, db.sourcesTable.id));

  $$SourcesTableTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$SourcesTableTableTableManager($_db, $_db.sourcesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CluesTableTable, List<ClueRow>>
      _cluesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.cluesTable,
          aliasName:
              $_aliasNameGenerator(db.puzzlesTable.id, db.cluesTable.puzzleId));

  $$CluesTableTableProcessedTableManager get cluesTableRefs {
    final manager = $$CluesTableTableTableManager($_db, $_db.cluesTable)
        .filter((f) => f.puzzleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cluesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SolveSessionsTableTable, List<SolveSessionRow>>
      _solveSessionsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.solveSessionsTable,
              aliasName: $_aliasNameGenerator(
                  db.puzzlesTable.id, db.solveSessionsTable.puzzleId));

  $$SolveSessionsTableTableProcessedTableManager get solveSessionsTableRefs {
    final manager = $$SolveSessionsTableTableTableManager(
            $_db, $_db.solveSessionsTable)
        .filter((f) => f.puzzleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_solveSessionsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PuzzleCompletionsTableTable,
      List<PuzzleCompletionRow>> _puzzleCompletionsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.puzzleCompletionsTable,
          aliasName: $_aliasNameGenerator(
              db.puzzlesTable.id, db.puzzleCompletionsTable.puzzleId));

  $$PuzzleCompletionsTableTableProcessedTableManager
      get puzzleCompletionsTableRefs {
    final manager = $$PuzzleCompletionsTableTableTableManager(
            $_db, $_db.puzzleCompletionsTable)
        .filter((f) => f.puzzleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_puzzleCompletionsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PuzzlesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzlesTableTable> {
  $$PuzzlesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourcePuzzleId => $composableBuilder(
      column: $table.sourcePuzzleId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get editor => $composableBuilder(
      column: $table.editor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publisher => $composableBuilder(
      column: $table.publisher, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get copyright => $composableBuilder(
      column: $table.copyright, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get publishDate => $composableBuilder(
      column: $table.publishDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalJson => $composableBuilder(
      column: $table.canonicalJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawPayload => $composableBuilder(
      column: $table.rawPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$SourcesTableTableFilterComposer get sourceId {
    final $$SourcesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.sourcesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SourcesTableTableFilterComposer(
              $db: $db,
              $table: $db.sourcesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cluesTableRefs(
      Expression<bool> Function($$CluesTableTableFilterComposer f) f) {
    final $$CluesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cluesTable,
        getReferencedColumn: (t) => t.puzzleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CluesTableTableFilterComposer(
              $db: $db,
              $table: $db.cluesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> solveSessionsTableRefs(
      Expression<bool> Function($$SolveSessionsTableTableFilterComposer f) f) {
    final $$SolveSessionsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.solveSessionsTable,
        getReferencedColumn: (t) => t.puzzleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SolveSessionsTableTableFilterComposer(
              $db: $db,
              $table: $db.solveSessionsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> puzzleCompletionsTableRefs(
      Expression<bool> Function($$PuzzleCompletionsTableTableFilterComposer f)
          f) {
    final $$PuzzleCompletionsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.puzzleCompletionsTable,
            getReferencedColumn: (t) => t.puzzleId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PuzzleCompletionsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.puzzleCompletionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$PuzzlesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzlesTableTable> {
  $$PuzzlesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourcePuzzleId => $composableBuilder(
      column: $table.sourcePuzzleId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get editor => $composableBuilder(
      column: $table.editor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publisher => $composableBuilder(
      column: $table.publisher, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get copyright => $composableBuilder(
      column: $table.copyright, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get publishDate => $composableBuilder(
      column: $table.publishDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalJson => $composableBuilder(
      column: $table.canonicalJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawPayload => $composableBuilder(
      column: $table.rawPayload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$SourcesTableTableOrderingComposer get sourceId {
    final $$SourcesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.sourcesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SourcesTableTableOrderingComposer(
              $db: $db,
              $table: $db.sourcesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PuzzlesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzlesTableTable> {
  $$PuzzlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePuzzleId => $composableBuilder(
      column: $table.sourcePuzzleId, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get editor =>
      $composableBuilder(column: $table.editor, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get copyright =>
      $composableBuilder(column: $table.copyright, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get publishDate => $composableBuilder(
      column: $table.publishDate, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get canonicalJson => $composableBuilder(
      column: $table.canonicalJson, builder: (column) => column);

  GeneratedColumn<String> get rawPayload => $composableBuilder(
      column: $table.rawPayload, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourcesTableTableAnnotationComposer get sourceId {
    final $$SourcesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.sourcesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SourcesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.sourcesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cluesTableRefs<T extends Object>(
      Expression<T> Function($$CluesTableTableAnnotationComposer a) f) {
    final $$CluesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cluesTable,
        getReferencedColumn: (t) => t.puzzleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CluesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.cluesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> solveSessionsTableRefs<T extends Object>(
      Expression<T> Function($$SolveSessionsTableTableAnnotationComposer a) f) {
    final $$SolveSessionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.solveSessionsTable,
            getReferencedColumn: (t) => t.puzzleId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SolveSessionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.solveSessionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> puzzleCompletionsTableRefs<T extends Object>(
      Expression<T> Function($$PuzzleCompletionsTableTableAnnotationComposer a)
          f) {
    final $$PuzzleCompletionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.puzzleCompletionsTable,
            getReferencedColumn: (t) => t.puzzleId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PuzzleCompletionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.puzzleCompletionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$PuzzlesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PuzzlesTableTable,
    PuzzleRow,
    $$PuzzlesTableTableFilterComposer,
    $$PuzzlesTableTableOrderingComposer,
    $$PuzzlesTableTableAnnotationComposer,
    $$PuzzlesTableTableCreateCompanionBuilder,
    $$PuzzlesTableTableUpdateCompanionBuilder,
    (PuzzleRow, $$PuzzlesTableTableReferences),
    PuzzleRow,
    PrefetchHooks Function(
        {bool sourceId,
        bool cluesTableRefs,
        bool solveSessionsTableRefs,
        bool puzzleCompletionsTableRefs})> {
  $$PuzzlesTableTableTableManager(_$AppDatabase db, $PuzzlesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzlesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzlesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzlesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String?> sourcePuzzleId = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> editor = const Value.absent(),
            Value<String?> publisher = const Value.absent(),
            Value<String?> copyright = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> publishDate = const Value.absent(),
            Value<String?> difficulty = const Value.absent(),
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<String> canonicalJson = const Value.absent(),
            Value<String?> rawPayload = const Value.absent(),
            Value<DateTime?> fetchedAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PuzzlesTableCompanion(
            id: id,
            sourceId: sourceId,
            sourcePuzzleId: sourcePuzzleId,
            format: format,
            title: title,
            author: author,
            editor: editor,
            publisher: publisher,
            copyright: copyright,
            notes: notes,
            publishDate: publishDate,
            difficulty: difficulty,
            width: width,
            height: height,
            checksum: checksum,
            canonicalJson: canonicalJson,
            rawPayload: rawPayload,
            fetchedAt: fetchedAt,
            expiresAt: expiresAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sourceId,
            Value<String?> sourcePuzzleId = const Value.absent(),
            required String format,
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> editor = const Value.absent(),
            Value<String?> publisher = const Value.absent(),
            Value<String?> copyright = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> publishDate = const Value.absent(),
            Value<String?> difficulty = const Value.absent(),
            required int width,
            required int height,
            required String checksum,
            required String canonicalJson,
            Value<String?> rawPayload = const Value.absent(),
            Value<DateTime?> fetchedAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PuzzlesTableCompanion.insert(
            id: id,
            sourceId: sourceId,
            sourcePuzzleId: sourcePuzzleId,
            format: format,
            title: title,
            author: author,
            editor: editor,
            publisher: publisher,
            copyright: copyright,
            notes: notes,
            publishDate: publishDate,
            difficulty: difficulty,
            width: width,
            height: height,
            checksum: checksum,
            canonicalJson: canonicalJson,
            rawPayload: rawPayload,
            fetchedAt: fetchedAt,
            expiresAt: expiresAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PuzzlesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sourceId = false,
              cluesTableRefs = false,
              solveSessionsTableRefs = false,
              puzzleCompletionsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cluesTableRefs) db.cluesTable,
                if (solveSessionsTableRefs) db.solveSessionsTable,
                if (puzzleCompletionsTableRefs) db.puzzleCompletionsTable
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceId,
                    referencedTable:
                        $$PuzzlesTableTableReferences._sourceIdTable(db),
                    referencedColumn:
                        $$PuzzlesTableTableReferences._sourceIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cluesTableRefs)
                    await $_getPrefetchedData<PuzzleRow, $PuzzlesTableTable,
                            ClueRow>(
                        currentTable: table,
                        referencedTable: $$PuzzlesTableTableReferences
                            ._cluesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PuzzlesTableTableReferences(db, table, p0)
                                .cluesTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.puzzleId == item.id),
                        typedResults: items),
                  if (solveSessionsTableRefs)
                    await $_getPrefetchedData<PuzzleRow, $PuzzlesTableTable,
                            SolveSessionRow>(
                        currentTable: table,
                        referencedTable: $$PuzzlesTableTableReferences
                            ._solveSessionsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PuzzlesTableTableReferences(db, table, p0)
                                .solveSessionsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.puzzleId == item.id),
                        typedResults: items),
                  if (puzzleCompletionsTableRefs)
                    await $_getPrefetchedData<PuzzleRow, $PuzzlesTableTable,
                            PuzzleCompletionRow>(
                        currentTable: table,
                        referencedTable: $$PuzzlesTableTableReferences
                            ._puzzleCompletionsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PuzzlesTableTableReferences(db, table, p0)
                                .puzzleCompletionsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.puzzleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PuzzlesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PuzzlesTableTable,
    PuzzleRow,
    $$PuzzlesTableTableFilterComposer,
    $$PuzzlesTableTableOrderingComposer,
    $$PuzzlesTableTableAnnotationComposer,
    $$PuzzlesTableTableCreateCompanionBuilder,
    $$PuzzlesTableTableUpdateCompanionBuilder,
    (PuzzleRow, $$PuzzlesTableTableReferences),
    PuzzleRow,
    PrefetchHooks Function(
        {bool sourceId,
        bool cluesTableRefs,
        bool solveSessionsTableRefs,
        bool puzzleCompletionsTableRefs})>;
typedef $$CluesTableTableCreateCompanionBuilder = CluesTableCompanion Function({
  Value<int> id,
  required String puzzleId,
  required String direction,
  required int number,
  required int sortOrder,
  required int startRow,
  required int startCol,
  required String clueText,
  required int answerLength,
});
typedef $$CluesTableTableUpdateCompanionBuilder = CluesTableCompanion Function({
  Value<int> id,
  Value<String> puzzleId,
  Value<String> direction,
  Value<int> number,
  Value<int> sortOrder,
  Value<int> startRow,
  Value<int> startCol,
  Value<String> clueText,
  Value<int> answerLength,
});

final class $$CluesTableTableReferences
    extends BaseReferences<_$AppDatabase, $CluesTableTable, ClueRow> {
  $$CluesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTableTable _puzzleIdTable(_$AppDatabase db) =>
      db.puzzlesTable.createAlias(
          $_aliasNameGenerator(db.cluesTable.puzzleId, db.puzzlesTable.id));

  $$PuzzlesTableTableProcessedTableManager get puzzleId {
    final $_column = $_itemColumn<String>('puzzle_id')!;

    final manager = $$PuzzlesTableTableTableManager($_db, $_db.puzzlesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CluesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CluesTableTable> {
  $$CluesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startRow => $composableBuilder(
      column: $table.startRow, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startCol => $composableBuilder(
      column: $table.startCol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clueText => $composableBuilder(
      column: $table.clueText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get answerLength => $composableBuilder(
      column: $table.answerLength, builder: (column) => ColumnFilters(column));

  $$PuzzlesTableTableFilterComposer get puzzleId {
    final $$PuzzlesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableFilterComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CluesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CluesTableTable> {
  $$CluesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startRow => $composableBuilder(
      column: $table.startRow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startCol => $composableBuilder(
      column: $table.startCol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clueText => $composableBuilder(
      column: $table.clueText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get answerLength => $composableBuilder(
      column: $table.answerLength,
      builder: (column) => ColumnOrderings(column));

  $$PuzzlesTableTableOrderingComposer get puzzleId {
    final $$PuzzlesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableOrderingComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CluesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CluesTableTable> {
  $$CluesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get startRow =>
      $composableBuilder(column: $table.startRow, builder: (column) => column);

  GeneratedColumn<int> get startCol =>
      $composableBuilder(column: $table.startCol, builder: (column) => column);

  GeneratedColumn<String> get clueText =>
      $composableBuilder(column: $table.clueText, builder: (column) => column);

  GeneratedColumn<int> get answerLength => $composableBuilder(
      column: $table.answerLength, builder: (column) => column);

  $$PuzzlesTableTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CluesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CluesTableTable,
    ClueRow,
    $$CluesTableTableFilterComposer,
    $$CluesTableTableOrderingComposer,
    $$CluesTableTableAnnotationComposer,
    $$CluesTableTableCreateCompanionBuilder,
    $$CluesTableTableUpdateCompanionBuilder,
    (ClueRow, $$CluesTableTableReferences),
    ClueRow,
    PrefetchHooks Function({bool puzzleId})> {
  $$CluesTableTableTableManager(_$AppDatabase db, $CluesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CluesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CluesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CluesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> puzzleId = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> startRow = const Value.absent(),
            Value<int> startCol = const Value.absent(),
            Value<String> clueText = const Value.absent(),
            Value<int> answerLength = const Value.absent(),
          }) =>
              CluesTableCompanion(
            id: id,
            puzzleId: puzzleId,
            direction: direction,
            number: number,
            sortOrder: sortOrder,
            startRow: startRow,
            startCol: startCol,
            clueText: clueText,
            answerLength: answerLength,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String puzzleId,
            required String direction,
            required int number,
            required int sortOrder,
            required int startRow,
            required int startCol,
            required String clueText,
            required int answerLength,
          }) =>
              CluesTableCompanion.insert(
            id: id,
            puzzleId: puzzleId,
            direction: direction,
            number: number,
            sortOrder: sortOrder,
            startRow: startRow,
            startCol: startCol,
            clueText: clueText,
            answerLength: answerLength,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CluesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({puzzleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (puzzleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.puzzleId,
                    referencedTable:
                        $$CluesTableTableReferences._puzzleIdTable(db),
                    referencedColumn:
                        $$CluesTableTableReferences._puzzleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CluesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CluesTableTable,
    ClueRow,
    $$CluesTableTableFilterComposer,
    $$CluesTableTableOrderingComposer,
    $$CluesTableTableAnnotationComposer,
    $$CluesTableTableCreateCompanionBuilder,
    $$CluesTableTableUpdateCompanionBuilder,
    (ClueRow, $$CluesTableTableReferences),
    ClueRow,
    PrefetchHooks Function({bool puzzleId})>;
typedef $$SolveSessionsTableTableCreateCompanionBuilder
    = SolveSessionsTableCompanion Function({
  Value<int> id,
  required String puzzleId,
  required String deviceId,
  Value<String> status,
  Value<String?> completionType,
  required DateTime startedAt,
  required DateTime lastPlayedAt,
  Value<DateTime?> completedAt,
  Value<String?> solvedDateLocal,
  Value<String?> solvedTimezone,
  Value<int> elapsedMs,
  Value<bool> isPaused,
  Value<DateTime?> pausedAt,
  Value<int> totalPausedMs,
  Value<int> mistakeCount,
  Value<int> checkCount,
  Value<int> revealCount,
  Value<bool> usedCheck,
  Value<bool> usedReveal,
  Value<bool> cleanSolveEligible,
  Value<int> focusRow,
  Value<int> focusCol,
  Value<String> direction,
  Value<bool> isSynced,
  Value<int> syncVersion,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$SolveSessionsTableTableUpdateCompanionBuilder
    = SolveSessionsTableCompanion Function({
  Value<int> id,
  Value<String> puzzleId,
  Value<String> deviceId,
  Value<String> status,
  Value<String?> completionType,
  Value<DateTime> startedAt,
  Value<DateTime> lastPlayedAt,
  Value<DateTime?> completedAt,
  Value<String?> solvedDateLocal,
  Value<String?> solvedTimezone,
  Value<int> elapsedMs,
  Value<bool> isPaused,
  Value<DateTime?> pausedAt,
  Value<int> totalPausedMs,
  Value<int> mistakeCount,
  Value<int> checkCount,
  Value<int> revealCount,
  Value<bool> usedCheck,
  Value<bool> usedReveal,
  Value<bool> cleanSolveEligible,
  Value<int> focusRow,
  Value<int> focusCol,
  Value<String> direction,
  Value<bool> isSynced,
  Value<int> syncVersion,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$SolveSessionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $SolveSessionsTableTable, SolveSessionRow> {
  $$SolveSessionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTableTable _puzzleIdTable(_$AppDatabase db) =>
      db.puzzlesTable.createAlias($_aliasNameGenerator(
          db.solveSessionsTable.puzzleId, db.puzzlesTable.id));

  $$PuzzlesTableTableProcessedTableManager get puzzleId {
    final $_column = $_itemColumn<String>('puzzle_id')!;

    final manager = $$PuzzlesTableTableTableManager($_db, $_db.puzzlesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CellProgressTableTable, List<CellProgressRow>>
      _cellProgressTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cellProgressTable,
              aliasName: $_aliasNameGenerator(
                  db.solveSessionsTable.id, db.cellProgressTable.sessionId));

  $$CellProgressTableTableProcessedTableManager get cellProgressTableRefs {
    final manager =
        $$CellProgressTableTableTableManager($_db, $_db.cellProgressTable)
            .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_cellProgressTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SolveSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SolveSessionsTableTable> {
  $$SolveSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPaused => $composableBuilder(
      column: $table.isPaused, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalPausedMs => $composableBuilder(
      column: $table.totalPausedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get usedCheck => $composableBuilder(
      column: $table.usedCheck, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get usedReveal => $composableBuilder(
      column: $table.usedReveal, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get cleanSolveEligible => $composableBuilder(
      column: $table.cleanSolveEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get focusRow => $composableBuilder(
      column: $table.focusRow, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get focusCol => $composableBuilder(
      column: $table.focusCol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$PuzzlesTableTableFilterComposer get puzzleId {
    final $$PuzzlesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableFilterComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cellProgressTableRefs(
      Expression<bool> Function($$CellProgressTableTableFilterComposer f) f) {
    final $$CellProgressTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cellProgressTable,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CellProgressTableTableFilterComposer(
              $db: $db,
              $table: $db.cellProgressTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SolveSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SolveSessionsTableTable> {
  $$SolveSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaused => $composableBuilder(
      column: $table.isPaused, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
      column: $table.pausedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPausedMs => $composableBuilder(
      column: $table.totalPausedMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get usedCheck => $composableBuilder(
      column: $table.usedCheck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get usedReveal => $composableBuilder(
      column: $table.usedReveal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get cleanSolveEligible => $composableBuilder(
      column: $table.cleanSolveEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get focusRow => $composableBuilder(
      column: $table.focusRow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get focusCol => $composableBuilder(
      column: $table.focusCol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$PuzzlesTableTableOrderingComposer get puzzleId {
    final $$PuzzlesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableOrderingComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SolveSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolveSessionsTableTable> {
  $$SolveSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get completionType => $composableBuilder(
      column: $table.completionType, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal, builder: (column) => column);

  GeneratedColumn<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<int> get totalPausedMs => $composableBuilder(
      column: $table.totalPausedMs, builder: (column) => column);

  GeneratedColumn<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount, builder: (column) => column);

  GeneratedColumn<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => column);

  GeneratedColumn<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => column);

  GeneratedColumn<bool> get usedCheck =>
      $composableBuilder(column: $table.usedCheck, builder: (column) => column);

  GeneratedColumn<bool> get usedReveal => $composableBuilder(
      column: $table.usedReveal, builder: (column) => column);

  GeneratedColumn<bool> get cleanSolveEligible => $composableBuilder(
      column: $table.cleanSolveEligible, builder: (column) => column);

  GeneratedColumn<int> get focusRow =>
      $composableBuilder(column: $table.focusRow, builder: (column) => column);

  GeneratedColumn<int> get focusCol =>
      $composableBuilder(column: $table.focusCol, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PuzzlesTableTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cellProgressTableRefs<T extends Object>(
      Expression<T> Function($$CellProgressTableTableAnnotationComposer a) f) {
    final $$CellProgressTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.cellProgressTable,
            getReferencedColumn: (t) => t.sessionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CellProgressTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.cellProgressTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SolveSessionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SolveSessionsTableTable,
    SolveSessionRow,
    $$SolveSessionsTableTableFilterComposer,
    $$SolveSessionsTableTableOrderingComposer,
    $$SolveSessionsTableTableAnnotationComposer,
    $$SolveSessionsTableTableCreateCompanionBuilder,
    $$SolveSessionsTableTableUpdateCompanionBuilder,
    (SolveSessionRow, $$SolveSessionsTableTableReferences),
    SolveSessionRow,
    PrefetchHooks Function({bool puzzleId, bool cellProgressTableRefs})> {
  $$SolveSessionsTableTableTableManager(
      _$AppDatabase db, $SolveSessionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolveSessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolveSessionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolveSessionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> puzzleId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> completionType = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> lastPlayedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> solvedDateLocal = const Value.absent(),
            Value<String?> solvedTimezone = const Value.absent(),
            Value<int> elapsedMs = const Value.absent(),
            Value<bool> isPaused = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<int> totalPausedMs = const Value.absent(),
            Value<int> mistakeCount = const Value.absent(),
            Value<int> checkCount = const Value.absent(),
            Value<int> revealCount = const Value.absent(),
            Value<bool> usedCheck = const Value.absent(),
            Value<bool> usedReveal = const Value.absent(),
            Value<bool> cleanSolveEligible = const Value.absent(),
            Value<int> focusRow = const Value.absent(),
            Value<int> focusCol = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SolveSessionsTableCompanion(
            id: id,
            puzzleId: puzzleId,
            deviceId: deviceId,
            status: status,
            completionType: completionType,
            startedAt: startedAt,
            lastPlayedAt: lastPlayedAt,
            completedAt: completedAt,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            elapsedMs: elapsedMs,
            isPaused: isPaused,
            pausedAt: pausedAt,
            totalPausedMs: totalPausedMs,
            mistakeCount: mistakeCount,
            checkCount: checkCount,
            revealCount: revealCount,
            usedCheck: usedCheck,
            usedReveal: usedReveal,
            cleanSolveEligible: cleanSolveEligible,
            focusRow: focusRow,
            focusCol: focusCol,
            direction: direction,
            isSynced: isSynced,
            syncVersion: syncVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String puzzleId,
            required String deviceId,
            Value<String> status = const Value.absent(),
            Value<String?> completionType = const Value.absent(),
            required DateTime startedAt,
            required DateTime lastPlayedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> solvedDateLocal = const Value.absent(),
            Value<String?> solvedTimezone = const Value.absent(),
            Value<int> elapsedMs = const Value.absent(),
            Value<bool> isPaused = const Value.absent(),
            Value<DateTime?> pausedAt = const Value.absent(),
            Value<int> totalPausedMs = const Value.absent(),
            Value<int> mistakeCount = const Value.absent(),
            Value<int> checkCount = const Value.absent(),
            Value<int> revealCount = const Value.absent(),
            Value<bool> usedCheck = const Value.absent(),
            Value<bool> usedReveal = const Value.absent(),
            Value<bool> cleanSolveEligible = const Value.absent(),
            Value<int> focusRow = const Value.absent(),
            Value<int> focusCol = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              SolveSessionsTableCompanion.insert(
            id: id,
            puzzleId: puzzleId,
            deviceId: deviceId,
            status: status,
            completionType: completionType,
            startedAt: startedAt,
            lastPlayedAt: lastPlayedAt,
            completedAt: completedAt,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            elapsedMs: elapsedMs,
            isPaused: isPaused,
            pausedAt: pausedAt,
            totalPausedMs: totalPausedMs,
            mistakeCount: mistakeCount,
            checkCount: checkCount,
            revealCount: revealCount,
            usedCheck: usedCheck,
            usedReveal: usedReveal,
            cleanSolveEligible: cleanSolveEligible,
            focusRow: focusRow,
            focusCol: focusCol,
            direction: direction,
            isSynced: isSynced,
            syncVersion: syncVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SolveSessionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {puzzleId = false, cellProgressTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cellProgressTableRefs) db.cellProgressTable
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (puzzleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.puzzleId,
                    referencedTable:
                        $$SolveSessionsTableTableReferences._puzzleIdTable(db),
                    referencedColumn: $$SolveSessionsTableTableReferences
                        ._puzzleIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cellProgressTableRefs)
                    await $_getPrefetchedData<SolveSessionRow,
                            $SolveSessionsTableTable, CellProgressRow>(
                        currentTable: table,
                        referencedTable: $$SolveSessionsTableTableReferences
                            ._cellProgressTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SolveSessionsTableTableReferences(db, table, p0)
                                .cellProgressTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SolveSessionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SolveSessionsTableTable,
    SolveSessionRow,
    $$SolveSessionsTableTableFilterComposer,
    $$SolveSessionsTableTableOrderingComposer,
    $$SolveSessionsTableTableAnnotationComposer,
    $$SolveSessionsTableTableCreateCompanionBuilder,
    $$SolveSessionsTableTableUpdateCompanionBuilder,
    (SolveSessionRow, $$SolveSessionsTableTableReferences),
    SolveSessionRow,
    PrefetchHooks Function({bool puzzleId, bool cellProgressTableRefs})>;
typedef $$CellProgressTableTableCreateCompanionBuilder
    = CellProgressTableCompanion Function({
  required int sessionId,
  required int row,
  required int col,
  Value<String?> guess,
  Value<String> state,
  Value<bool> wasChecked,
  Value<bool> wasRevealed,
  Value<String?> lastWrongGuessHash,
  Value<bool> isPencil,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CellProgressTableTableUpdateCompanionBuilder
    = CellProgressTableCompanion Function({
  Value<int> sessionId,
  Value<int> row,
  Value<int> col,
  Value<String?> guess,
  Value<String> state,
  Value<bool> wasChecked,
  Value<bool> wasRevealed,
  Value<String?> lastWrongGuessHash,
  Value<bool> isPencil,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CellProgressTableTableReferences extends BaseReferences<
    _$AppDatabase, $CellProgressTableTable, CellProgressRow> {
  $$CellProgressTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SolveSessionsTableTable _sessionIdTable(_$AppDatabase db) =>
      db.solveSessionsTable.createAlias($_aliasNameGenerator(
          db.cellProgressTable.sessionId, db.solveSessionsTable.id));

  $$SolveSessionsTableTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager =
        $$SolveSessionsTableTableTableManager($_db, $_db.solveSessionsTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CellProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $CellProgressTableTable> {
  $$CellProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get row => $composableBuilder(
      column: $table.row, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get col => $composableBuilder(
      column: $table.col, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guess => $composableBuilder(
      column: $table.guess, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasChecked => $composableBuilder(
      column: $table.wasChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasRevealed => $composableBuilder(
      column: $table.wasRevealed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastWrongGuessHash => $composableBuilder(
      column: $table.lastWrongGuessHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPencil => $composableBuilder(
      column: $table.isPencil, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$SolveSessionsTableTableFilterComposer get sessionId {
    final $$SolveSessionsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.solveSessionsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SolveSessionsTableTableFilterComposer(
              $db: $db,
              $table: $db.solveSessionsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CellProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CellProgressTableTable> {
  $$CellProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get row => $composableBuilder(
      column: $table.row, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get col => $composableBuilder(
      column: $table.col, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guess => $composableBuilder(
      column: $table.guess, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasChecked => $composableBuilder(
      column: $table.wasChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasRevealed => $composableBuilder(
      column: $table.wasRevealed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastWrongGuessHash => $composableBuilder(
      column: $table.lastWrongGuessHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPencil => $composableBuilder(
      column: $table.isPencil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$SolveSessionsTableTableOrderingComposer get sessionId {
    final $$SolveSessionsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.solveSessionsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SolveSessionsTableTableOrderingComposer(
              $db: $db,
              $table: $db.solveSessionsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CellProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CellProgressTableTable> {
  $$CellProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get row =>
      $composableBuilder(column: $table.row, builder: (column) => column);

  GeneratedColumn<int> get col =>
      $composableBuilder(column: $table.col, builder: (column) => column);

  GeneratedColumn<String> get guess =>
      $composableBuilder(column: $table.guess, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get wasChecked => $composableBuilder(
      column: $table.wasChecked, builder: (column) => column);

  GeneratedColumn<bool> get wasRevealed => $composableBuilder(
      column: $table.wasRevealed, builder: (column) => column);

  GeneratedColumn<String> get lastWrongGuessHash => $composableBuilder(
      column: $table.lastWrongGuessHash, builder: (column) => column);

  GeneratedColumn<bool> get isPencil =>
      $composableBuilder(column: $table.isPencil, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SolveSessionsTableTableAnnotationComposer get sessionId {
    final $$SolveSessionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.sessionId,
            referencedTable: $db.solveSessionsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SolveSessionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.solveSessionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$CellProgressTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CellProgressTableTable,
    CellProgressRow,
    $$CellProgressTableTableFilterComposer,
    $$CellProgressTableTableOrderingComposer,
    $$CellProgressTableTableAnnotationComposer,
    $$CellProgressTableTableCreateCompanionBuilder,
    $$CellProgressTableTableUpdateCompanionBuilder,
    (CellProgressRow, $$CellProgressTableTableReferences),
    CellProgressRow,
    PrefetchHooks Function({bool sessionId})> {
  $$CellProgressTableTableTableManager(
      _$AppDatabase db, $CellProgressTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CellProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CellProgressTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CellProgressTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> sessionId = const Value.absent(),
            Value<int> row = const Value.absent(),
            Value<int> col = const Value.absent(),
            Value<String?> guess = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<bool> wasChecked = const Value.absent(),
            Value<bool> wasRevealed = const Value.absent(),
            Value<String?> lastWrongGuessHash = const Value.absent(),
            Value<bool> isPencil = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CellProgressTableCompanion(
            sessionId: sessionId,
            row: row,
            col: col,
            guess: guess,
            state: state,
            wasChecked: wasChecked,
            wasRevealed: wasRevealed,
            lastWrongGuessHash: lastWrongGuessHash,
            isPencil: isPencil,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int sessionId,
            required int row,
            required int col,
            Value<String?> guess = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<bool> wasChecked = const Value.absent(),
            Value<bool> wasRevealed = const Value.absent(),
            Value<String?> lastWrongGuessHash = const Value.absent(),
            Value<bool> isPencil = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CellProgressTableCompanion.insert(
            sessionId: sessionId,
            row: row,
            col: col,
            guess: guess,
            state: state,
            wasChecked: wasChecked,
            wasRevealed: wasRevealed,
            lastWrongGuessHash: lastWrongGuessHash,
            isPencil: isPencil,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CellProgressTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$CellProgressTableTableReferences._sessionIdTable(db),
                    referencedColumn: $$CellProgressTableTableReferences
                        ._sessionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CellProgressTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CellProgressTableTable,
    CellProgressRow,
    $$CellProgressTableTableFilterComposer,
    $$CellProgressTableTableOrderingComposer,
    $$CellProgressTableTableAnnotationComposer,
    $$CellProgressTableTableCreateCompanionBuilder,
    $$CellProgressTableTableUpdateCompanionBuilder,
    (CellProgressRow, $$CellProgressTableTableReferences),
    CellProgressRow,
    PrefetchHooks Function({bool sessionId})>;
typedef $$AppSettingsTableTableCreateCompanionBuilder
    = AppSettingsTableCompanion Function({
  required String key,
  required String valueJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableTableUpdateCompanionBuilder
    = AppSettingsTableCompanion Function({
  Value<String> key,
  Value<String> valueJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueJson => $composableBuilder(
      column: $table.valueJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingRow,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableTableManager(
      _$AppDatabase db, $AppSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> valueJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion(
            key: key,
            valueJson: valueJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String valueJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion.insert(
            key: key,
            valueJson: valueJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingRow,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()>;
typedef $$ImportedSolveStatsTableTableCreateCompanionBuilder
    = ImportedSolveStatsTableCompanion Function({
  Value<int> id,
  required String completionType,
  required int elapsedMs,
  required String solvedDateLocal,
  Value<String?> solvedTimezone,
  required int width,
  required int height,
  required String puzzleTitle,
  required DateTime importedAt,
});
typedef $$ImportedSolveStatsTableTableUpdateCompanionBuilder
    = ImportedSolveStatsTableCompanion Function({
  Value<int> id,
  Value<String> completionType,
  Value<int> elapsedMs,
  Value<String> solvedDateLocal,
  Value<String?> solvedTimezone,
  Value<int> width,
  Value<int> height,
  Value<String> puzzleTitle,
  Value<DateTime> importedAt,
});

class $$ImportedSolveStatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ImportedSolveStatsTableTable> {
  $$ImportedSolveStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get puzzleTitle => $composableBuilder(
      column: $table.puzzleTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));
}

class $$ImportedSolveStatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportedSolveStatsTableTable> {
  $$ImportedSolveStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get puzzleTitle => $composableBuilder(
      column: $table.puzzleTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));
}

class $$ImportedSolveStatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportedSolveStatsTableTable> {
  $$ImportedSolveStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get completionType => $composableBuilder(
      column: $table.completionType, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal, builder: (column) => column);

  GeneratedColumn<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get puzzleTitle => $composableBuilder(
      column: $table.puzzleTitle, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);
}

class $$ImportedSolveStatsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ImportedSolveStatsTableTable,
    ImportedSolveStatRow,
    $$ImportedSolveStatsTableTableFilterComposer,
    $$ImportedSolveStatsTableTableOrderingComposer,
    $$ImportedSolveStatsTableTableAnnotationComposer,
    $$ImportedSolveStatsTableTableCreateCompanionBuilder,
    $$ImportedSolveStatsTableTableUpdateCompanionBuilder,
    (
      ImportedSolveStatRow,
      BaseReferences<_$AppDatabase, $ImportedSolveStatsTableTable,
          ImportedSolveStatRow>
    ),
    ImportedSolveStatRow,
    PrefetchHooks Function()> {
  $$ImportedSolveStatsTableTableTableManager(
      _$AppDatabase db, $ImportedSolveStatsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportedSolveStatsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportedSolveStatsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportedSolveStatsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> completionType = const Value.absent(),
            Value<int> elapsedMs = const Value.absent(),
            Value<String> solvedDateLocal = const Value.absent(),
            Value<String?> solvedTimezone = const Value.absent(),
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<String> puzzleTitle = const Value.absent(),
            Value<DateTime> importedAt = const Value.absent(),
          }) =>
              ImportedSolveStatsTableCompanion(
            id: id,
            completionType: completionType,
            elapsedMs: elapsedMs,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            width: width,
            height: height,
            puzzleTitle: puzzleTitle,
            importedAt: importedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String completionType,
            required int elapsedMs,
            required String solvedDateLocal,
            Value<String?> solvedTimezone = const Value.absent(),
            required int width,
            required int height,
            required String puzzleTitle,
            required DateTime importedAt,
          }) =>
              ImportedSolveStatsTableCompanion.insert(
            id: id,
            completionType: completionType,
            elapsedMs: elapsedMs,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            width: width,
            height: height,
            puzzleTitle: puzzleTitle,
            importedAt: importedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ImportedSolveStatsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ImportedSolveStatsTableTable,
        ImportedSolveStatRow,
        $$ImportedSolveStatsTableTableFilterComposer,
        $$ImportedSolveStatsTableTableOrderingComposer,
        $$ImportedSolveStatsTableTableAnnotationComposer,
        $$ImportedSolveStatsTableTableCreateCompanionBuilder,
        $$ImportedSolveStatsTableTableUpdateCompanionBuilder,
        (
          ImportedSolveStatRow,
          BaseReferences<_$AppDatabase, $ImportedSolveStatsTableTable,
              ImportedSolveStatRow>
        ),
        ImportedSolveStatRow,
        PrefetchHooks Function()>;
typedef $$PuzzleCompletionsTableTableCreateCompanionBuilder
    = PuzzleCompletionsTableCompanion Function({
  Value<int> id,
  required String puzzleId,
  required String completionType,
  required DateTime completedAt,
  required String solvedDateLocal,
  Value<String?> solvedTimezone,
  required int elapsedMs,
  Value<int> checkCount,
  Value<int> revealCount,
});
typedef $$PuzzleCompletionsTableTableUpdateCompanionBuilder
    = PuzzleCompletionsTableCompanion Function({
  Value<int> id,
  Value<String> puzzleId,
  Value<String> completionType,
  Value<DateTime> completedAt,
  Value<String> solvedDateLocal,
  Value<String?> solvedTimezone,
  Value<int> elapsedMs,
  Value<int> checkCount,
  Value<int> revealCount,
});

final class $$PuzzleCompletionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $PuzzleCompletionsTableTable, PuzzleCompletionRow> {
  $$PuzzleCompletionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTableTable _puzzleIdTable(_$AppDatabase db) =>
      db.puzzlesTable.createAlias($_aliasNameGenerator(
          db.puzzleCompletionsTable.puzzleId, db.puzzlesTable.id));

  $$PuzzlesTableTableProcessedTableManager get puzzleId {
    final $_column = $_itemColumn<String>('puzzle_id')!;

    final manager = $$PuzzlesTableTableTableManager($_db, $_db.puzzlesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PuzzleCompletionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleCompletionsTableTable> {
  $$PuzzleCompletionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => ColumnFilters(column));

  $$PuzzlesTableTableFilterComposer get puzzleId {
    final $$PuzzlesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableFilterComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PuzzleCompletionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleCompletionsTableTable> {
  $$PuzzleCompletionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completionType => $composableBuilder(
      column: $table.completionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
      column: $table.elapsedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => ColumnOrderings(column));

  $$PuzzlesTableTableOrderingComposer get puzzleId {
    final $$PuzzlesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableOrderingComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PuzzleCompletionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleCompletionsTableTable> {
  $$PuzzleCompletionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get completionType => $composableBuilder(
      column: $table.completionType, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get solvedDateLocal => $composableBuilder(
      column: $table.solvedDateLocal, builder: (column) => column);

  GeneratedColumn<String> get solvedTimezone => $composableBuilder(
      column: $table.solvedTimezone, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<int> get checkCount => $composableBuilder(
      column: $table.checkCount, builder: (column) => column);

  GeneratedColumn<int> get revealCount => $composableBuilder(
      column: $table.revealCount, builder: (column) => column);

  $$PuzzlesTableTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzlesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzlesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PuzzleCompletionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PuzzleCompletionsTableTable,
    PuzzleCompletionRow,
    $$PuzzleCompletionsTableTableFilterComposer,
    $$PuzzleCompletionsTableTableOrderingComposer,
    $$PuzzleCompletionsTableTableAnnotationComposer,
    $$PuzzleCompletionsTableTableCreateCompanionBuilder,
    $$PuzzleCompletionsTableTableUpdateCompanionBuilder,
    (PuzzleCompletionRow, $$PuzzleCompletionsTableTableReferences),
    PuzzleCompletionRow,
    PrefetchHooks Function({bool puzzleId})> {
  $$PuzzleCompletionsTableTableTableManager(
      _$AppDatabase db, $PuzzleCompletionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleCompletionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleCompletionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleCompletionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> puzzleId = const Value.absent(),
            Value<String> completionType = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<String> solvedDateLocal = const Value.absent(),
            Value<String?> solvedTimezone = const Value.absent(),
            Value<int> elapsedMs = const Value.absent(),
            Value<int> checkCount = const Value.absent(),
            Value<int> revealCount = const Value.absent(),
          }) =>
              PuzzleCompletionsTableCompanion(
            id: id,
            puzzleId: puzzleId,
            completionType: completionType,
            completedAt: completedAt,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            elapsedMs: elapsedMs,
            checkCount: checkCount,
            revealCount: revealCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String puzzleId,
            required String completionType,
            required DateTime completedAt,
            required String solvedDateLocal,
            Value<String?> solvedTimezone = const Value.absent(),
            required int elapsedMs,
            Value<int> checkCount = const Value.absent(),
            Value<int> revealCount = const Value.absent(),
          }) =>
              PuzzleCompletionsTableCompanion.insert(
            id: id,
            puzzleId: puzzleId,
            completionType: completionType,
            completedAt: completedAt,
            solvedDateLocal: solvedDateLocal,
            solvedTimezone: solvedTimezone,
            elapsedMs: elapsedMs,
            checkCount: checkCount,
            revealCount: revealCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PuzzleCompletionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({puzzleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (puzzleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.puzzleId,
                    referencedTable: $$PuzzleCompletionsTableTableReferences
                        ._puzzleIdTable(db),
                    referencedColumn: $$PuzzleCompletionsTableTableReferences
                        ._puzzleIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PuzzleCompletionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PuzzleCompletionsTableTable,
        PuzzleCompletionRow,
        $$PuzzleCompletionsTableTableFilterComposer,
        $$PuzzleCompletionsTableTableOrderingComposer,
        $$PuzzleCompletionsTableTableAnnotationComposer,
        $$PuzzleCompletionsTableTableCreateCompanionBuilder,
        $$PuzzleCompletionsTableTableUpdateCompanionBuilder,
        (PuzzleCompletionRow, $$PuzzleCompletionsTableTableReferences),
        PuzzleCompletionRow,
        PrefetchHooks Function({bool puzzleId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourcesTableTableTableManager get sourcesTable =>
      $$SourcesTableTableTableManager(_db, _db.sourcesTable);
  $$PuzzlesTableTableTableManager get puzzlesTable =>
      $$PuzzlesTableTableTableManager(_db, _db.puzzlesTable);
  $$CluesTableTableTableManager get cluesTable =>
      $$CluesTableTableTableManager(_db, _db.cluesTable);
  $$SolveSessionsTableTableTableManager get solveSessionsTable =>
      $$SolveSessionsTableTableTableManager(_db, _db.solveSessionsTable);
  $$CellProgressTableTableTableManager get cellProgressTable =>
      $$CellProgressTableTableTableManager(_db, _db.cellProgressTable);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
  $$ImportedSolveStatsTableTableTableManager get importedSolveStatsTable =>
      $$ImportedSolveStatsTableTableTableManager(
          _db, _db.importedSolveStatsTable);
  $$PuzzleCompletionsTableTableTableManager get puzzleCompletionsTable =>
      $$PuzzleCompletionsTableTableTableManager(
          _db, _db.puzzleCompletionsTable);
}
