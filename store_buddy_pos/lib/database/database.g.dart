// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitOfMeasureMeta =
      const VerificationMeta('unitOfMeasure');
  @override
  late final GeneratedColumn<String> unitOfMeasure = GeneratedColumn<String>(
      'unit_of_measure', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<double> stock = GeneratedColumn<double>(
      'stock', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minStockMeta =
      const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<double> minStock = GeneratedColumn<double>(
      'min_stock', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reorderLevelMeta =
      const VerificationMeta('reorderLevel');
  @override
  late final GeneratedColumn<double> reorderLevel = GeneratedColumn<double>(
      'reorder_level', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _warrantyMonthsMeta =
      const VerificationMeta('warrantyMonths');
  @override
  late final GeneratedColumn<int> warrantyMonths = GeneratedColumn<int>(
      'warranty_months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supplierIdMeta =
      const VerificationMeta('supplierId');
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
      'supplier_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _batchNumberMeta =
      const VerificationMeta('batchNumber');
  @override
  late final GeneratedColumn<String> batchNumber = GeneratedColumn<String>(
      'batch_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _commissionEligibleMeta =
      const VerificationMeta('commissionEligible');
  @override
  late final GeneratedColumn<bool> commissionEligible = GeneratedColumn<bool>(
      'commission_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("commission_eligible" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _agentCommissionPercentMeta =
      const VerificationMeta('agentCommissionPercent');
  @override
  late final GeneratedColumn<double> agentCommissionPercent =
      GeneratedColumn<double>('agent_commission_percent', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _bonusCommissionMeta =
      const VerificationMeta('bonusCommission');
  @override
  late final GeneratedColumn<double> bonusCommission = GeneratedColumn<double>(
      'bonus_commission', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _profitMarginMeta =
      const VerificationMeta('profitMargin');
  @override
  late final GeneratedColumn<double> profitMargin = GeneratedColumn<double>(
      'profit_margin', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minPriceMeta =
      const VerificationMeta('minPrice');
  @override
  late final GeneratedColumn<double> minPrice = GeneratedColumn<double>(
      'min_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imeisMeta = const VerificationMeta('imeis');
  @override
  late final GeneratedColumn<String> imeis = GeneratedColumn<String>(
      'imeis', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        name,
        description,
        sku,
        barcode,
        price,
        costPrice,
        category,
        type,
        unitOfMeasure,
        stock,
        minStock,
        reorderLevel,
        warrantyMonths,
        locationId,
        supplierId,
        batchNumber,
        expiryDate,
        commissionEligible,
        agentCommissionPercent,
        bonusCommission,
        profitMargin,
        minPrice,
        imageUrl,
        imeis,
        synced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('unit_of_measure')) {
      context.handle(
          _unitOfMeasureMeta,
          unitOfMeasure.isAcceptableOrUnknown(
              data['unit_of_measure']!, _unitOfMeasureMeta));
    } else if (isInserting) {
      context.missing(_unitOfMeasureMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta,
          minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
          _reorderLevelMeta,
          reorderLevel.isAcceptableOrUnknown(
              data['reorder_level']!, _reorderLevelMeta));
    }
    if (data.containsKey('warranty_months')) {
      context.handle(
          _warrantyMonthsMeta,
          warrantyMonths.isAcceptableOrUnknown(
              data['warranty_months']!, _warrantyMonthsMeta));
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
          _supplierIdMeta,
          supplierId.isAcceptableOrUnknown(
              data['supplier_id']!, _supplierIdMeta));
    }
    if (data.containsKey('batch_number')) {
      context.handle(
          _batchNumberMeta,
          batchNumber.isAcceptableOrUnknown(
              data['batch_number']!, _batchNumberMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('commission_eligible')) {
      context.handle(
          _commissionEligibleMeta,
          commissionEligible.isAcceptableOrUnknown(
              data['commission_eligible']!, _commissionEligibleMeta));
    }
    if (data.containsKey('agent_commission_percent')) {
      context.handle(
          _agentCommissionPercentMeta,
          agentCommissionPercent.isAcceptableOrUnknown(
              data['agent_commission_percent']!, _agentCommissionPercentMeta));
    }
    if (data.containsKey('bonus_commission')) {
      context.handle(
          _bonusCommissionMeta,
          bonusCommission.isAcceptableOrUnknown(
              data['bonus_commission']!, _bonusCommissionMeta));
    }
    if (data.containsKey('profit_margin')) {
      context.handle(
          _profitMarginMeta,
          profitMargin.isAcceptableOrUnknown(
              data['profit_margin']!, _profitMarginMeta));
    }
    if (data.containsKey('min_price')) {
      context.handle(_minPriceMeta,
          minPrice.isAcceptableOrUnknown(data['min_price']!, _minPriceMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('imeis')) {
      context.handle(
          _imeisMeta, imeis.isAcceptableOrUnknown(data['imeis']!, _imeisMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      unitOfMeasure: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unit_of_measure'])!,
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stock'])!,
      minStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_stock'])!,
      reorderLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reorder_level'])!,
      warrantyMonths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warranty_months'])!,
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id']),
      supplierId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplier_id'])!,
      batchNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_number']),
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date']),
      commissionEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}commission_eligible'])!,
      agentCommissionPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}agent_commission_percent'])!,
      bonusCommission: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}bonus_commission'])!,
      profitMargin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}profit_margin'])!,
      minPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_price'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      imeis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imeis']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final String category;
  final String type;
  final String unitOfMeasure;
  final double stock;
  final double minStock;
  final double reorderLevel;
  final int warrantyMonths;
  final String? locationId;
  final String supplierId;
  final String? batchNumber;
  final DateTime? expiryDate;
  final bool commissionEligible;
  final double agentCommissionPercent;
  final double bonusCommission;
  final double profitMargin;
  final double minPrice;
  final String? imageUrl;
  final String? imeis;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const Product(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.description,
      this.sku,
      this.barcode,
      required this.price,
      this.costPrice,
      required this.category,
      required this.type,
      required this.unitOfMeasure,
      required this.stock,
      required this.minStock,
      required this.reorderLevel,
      required this.warrantyMonths,
      this.locationId,
      required this.supplierId,
      this.batchNumber,
      this.expiryDate,
      required this.commissionEligible,
      required this.agentCommissionPercent,
      required this.bonusCommission,
      required this.profitMargin,
      required this.minPrice,
      this.imageUrl,
      this.imeis,
      required this.synced,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<double>(costPrice);
    }
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    map['unit_of_measure'] = Variable<String>(unitOfMeasure);
    map['stock'] = Variable<double>(stock);
    map['min_stock'] = Variable<double>(minStock);
    map['reorder_level'] = Variable<double>(reorderLevel);
    map['warranty_months'] = Variable<int>(warrantyMonths);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    map['supplier_id'] = Variable<String>(supplierId);
    if (!nullToAbsent || batchNumber != null) {
      map['batch_number'] = Variable<String>(batchNumber);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    map['commission_eligible'] = Variable<bool>(commissionEligible);
    map['agent_commission_percent'] = Variable<double>(agentCommissionPercent);
    map['bonus_commission'] = Variable<double>(bonusCommission);
    map['profit_margin'] = Variable<double>(profitMargin);
    map['min_price'] = Variable<double>(minPrice);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || imeis != null) {
      map['imeis'] = Variable<String>(imeis);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      description: Value(description),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      price: Value(price),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      category: Value(category),
      type: Value(type),
      unitOfMeasure: Value(unitOfMeasure),
      stock: Value(stock),
      minStock: Value(minStock),
      reorderLevel: Value(reorderLevel),
      warrantyMonths: Value(warrantyMonths),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      supplierId: Value(supplierId),
      batchNumber: batchNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNumber),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      commissionEligible: Value(commissionEligible),
      agentCommissionPercent: Value(agentCommissionPercent),
      bonusCommission: Value(bonusCommission),
      profitMargin: Value(profitMargin),
      minPrice: Value(minPrice),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      imeis:
          imeis == null && nullToAbsent ? const Value.absent() : Value(imeis),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      price: serializer.fromJson<double>(json['price']),
      costPrice: serializer.fromJson<double?>(json['costPrice']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      unitOfMeasure: serializer.fromJson<String>(json['unitOfMeasure']),
      stock: serializer.fromJson<double>(json['stock']),
      minStock: serializer.fromJson<double>(json['minStock']),
      reorderLevel: serializer.fromJson<double>(json['reorderLevel']),
      warrantyMonths: serializer.fromJson<int>(json['warrantyMonths']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      supplierId: serializer.fromJson<String>(json['supplierId']),
      batchNumber: serializer.fromJson<String?>(json['batchNumber']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      commissionEligible: serializer.fromJson<bool>(json['commissionEligible']),
      agentCommissionPercent:
          serializer.fromJson<double>(json['agentCommissionPercent']),
      bonusCommission: serializer.fromJson<double>(json['bonusCommission']),
      profitMargin: serializer.fromJson<double>(json['profitMargin']),
      minPrice: serializer.fromJson<double>(json['minPrice']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      imeis: serializer.fromJson<String?>(json['imeis']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'price': serializer.toJson<double>(price),
      'costPrice': serializer.toJson<double?>(costPrice),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'unitOfMeasure': serializer.toJson<String>(unitOfMeasure),
      'stock': serializer.toJson<double>(stock),
      'minStock': serializer.toJson<double>(minStock),
      'reorderLevel': serializer.toJson<double>(reorderLevel),
      'warrantyMonths': serializer.toJson<int>(warrantyMonths),
      'locationId': serializer.toJson<String?>(locationId),
      'supplierId': serializer.toJson<String>(supplierId),
      'batchNumber': serializer.toJson<String?>(batchNumber),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'commissionEligible': serializer.toJson<bool>(commissionEligible),
      'agentCommissionPercent':
          serializer.toJson<double>(agentCommissionPercent),
      'bonusCommission': serializer.toJson<double>(bonusCommission),
      'profitMargin': serializer.toJson<double>(profitMargin),
      'minPrice': serializer.toJson<double>(minPrice),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'imeis': serializer.toJson<String?>(imeis),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Product copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? description,
          Value<String?> sku = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          double? price,
          Value<double?> costPrice = const Value.absent(),
          String? category,
          String? type,
          String? unitOfMeasure,
          double? stock,
          double? minStock,
          double? reorderLevel,
          int? warrantyMonths,
          Value<String?> locationId = const Value.absent(),
          String? supplierId,
          Value<String?> batchNumber = const Value.absent(),
          Value<DateTime?> expiryDate = const Value.absent(),
          bool? commissionEligible,
          double? agentCommissionPercent,
          double? bonusCommission,
          double? profitMargin,
          double? minPrice,
          Value<String?> imageUrl = const Value.absent(),
          Value<String?> imeis = const Value.absent(),
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Product(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        description: description ?? this.description,
        sku: sku.present ? sku.value : this.sku,
        barcode: barcode.present ? barcode.value : this.barcode,
        price: price ?? this.price,
        costPrice: costPrice.present ? costPrice.value : this.costPrice,
        category: category ?? this.category,
        type: type ?? this.type,
        unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
        stock: stock ?? this.stock,
        minStock: minStock ?? this.minStock,
        reorderLevel: reorderLevel ?? this.reorderLevel,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        locationId: locationId.present ? locationId.value : this.locationId,
        supplierId: supplierId ?? this.supplierId,
        batchNumber: batchNumber.present ? batchNumber.value : this.batchNumber,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        commissionEligible: commissionEligible ?? this.commissionEligible,
        agentCommissionPercent:
            agentCommissionPercent ?? this.agentCommissionPercent,
        bonusCommission: bonusCommission ?? this.bonusCommission,
        profitMargin: profitMargin ?? this.profitMargin,
        minPrice: minPrice ?? this.minPrice,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        imeis: imeis.present ? imeis.value : this.imeis,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      price: data.price.present ? data.price.value : this.price,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      unitOfMeasure: data.unitOfMeasure.present
          ? data.unitOfMeasure.value
          : this.unitOfMeasure,
      stock: data.stock.present ? data.stock.value : this.stock,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      warrantyMonths: data.warrantyMonths.present
          ? data.warrantyMonths.value
          : this.warrantyMonths,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      supplierId:
          data.supplierId.present ? data.supplierId.value : this.supplierId,
      batchNumber:
          data.batchNumber.present ? data.batchNumber.value : this.batchNumber,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      commissionEligible: data.commissionEligible.present
          ? data.commissionEligible.value
          : this.commissionEligible,
      agentCommissionPercent: data.agentCommissionPercent.present
          ? data.agentCommissionPercent.value
          : this.agentCommissionPercent,
      bonusCommission: data.bonusCommission.present
          ? data.bonusCommission.value
          : this.bonusCommission,
      profitMargin: data.profitMargin.present
          ? data.profitMargin.value
          : this.profitMargin,
      minPrice: data.minPrice.present ? data.minPrice.value : this.minPrice,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      imeis: data.imeis.present ? data.imeis.value : this.imeis,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('stock: $stock, ')
          ..write('minStock: $minStock, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('locationId: $locationId, ')
          ..write('supplierId: $supplierId, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('commissionEligible: $commissionEligible, ')
          ..write('agentCommissionPercent: $agentCommissionPercent, ')
          ..write('bonusCommission: $bonusCommission, ')
          ..write('profitMargin: $profitMargin, ')
          ..write('minPrice: $minPrice, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imeis: $imeis, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        tenantId,
        name,
        description,
        sku,
        barcode,
        price,
        costPrice,
        category,
        type,
        unitOfMeasure,
        stock,
        minStock,
        reorderLevel,
        warrantyMonths,
        locationId,
        supplierId,
        batchNumber,
        expiryDate,
        commissionEligible,
        agentCommissionPercent,
        bonusCommission,
        profitMargin,
        minPrice,
        imageUrl,
        imeis,
        synced,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.description == this.description &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.price == this.price &&
          other.costPrice == this.costPrice &&
          other.category == this.category &&
          other.type == this.type &&
          other.unitOfMeasure == this.unitOfMeasure &&
          other.stock == this.stock &&
          other.minStock == this.minStock &&
          other.reorderLevel == this.reorderLevel &&
          other.warrantyMonths == this.warrantyMonths &&
          other.locationId == this.locationId &&
          other.supplierId == this.supplierId &&
          other.batchNumber == this.batchNumber &&
          other.expiryDate == this.expiryDate &&
          other.commissionEligible == this.commissionEligible &&
          other.agentCommissionPercent == this.agentCommissionPercent &&
          other.bonusCommission == this.bonusCommission &&
          other.profitMargin == this.profitMargin &&
          other.minPrice == this.minPrice &&
          other.imageUrl == this.imageUrl &&
          other.imeis == this.imeis &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> description;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<double> price;
  final Value<double?> costPrice;
  final Value<String> category;
  final Value<String> type;
  final Value<String> unitOfMeasure;
  final Value<double> stock;
  final Value<double> minStock;
  final Value<double> reorderLevel;
  final Value<int> warrantyMonths;
  final Value<String?> locationId;
  final Value<String> supplierId;
  final Value<String?> batchNumber;
  final Value<DateTime?> expiryDate;
  final Value<bool> commissionEligible;
  final Value<double> agentCommissionPercent;
  final Value<double> bonusCommission;
  final Value<double> profitMargin;
  final Value<double> minPrice;
  final Value<String?> imageUrl;
  final Value<String?> imeis;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.price = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.unitOfMeasure = const Value.absent(),
    this.stock = const Value.absent(),
    this.minStock = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.locationId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.commissionEligible = const Value.absent(),
    this.agentCommissionPercent = const Value.absent(),
    this.bonusCommission = const Value.absent(),
    this.profitMargin = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imeis = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    required double price,
    this.costPrice = const Value.absent(),
    required String category,
    required String type,
    required String unitOfMeasure,
    this.stock = const Value.absent(),
    this.minStock = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.warrantyMonths = const Value.absent(),
    this.locationId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.commissionEligible = const Value.absent(),
    this.agentCommissionPercent = const Value.absent(),
    this.bonusCommission = const Value.absent(),
    this.profitMargin = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imeis = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        price = Value(price),
        category = Value(category),
        type = Value(type),
        unitOfMeasure = Value(unitOfMeasure);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<double>? price,
    Expression<double>? costPrice,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? unitOfMeasure,
    Expression<double>? stock,
    Expression<double>? minStock,
    Expression<double>? reorderLevel,
    Expression<int>? warrantyMonths,
    Expression<String>? locationId,
    Expression<String>? supplierId,
    Expression<String>? batchNumber,
    Expression<DateTime>? expiryDate,
    Expression<bool>? commissionEligible,
    Expression<double>? agentCommissionPercent,
    Expression<double>? bonusCommission,
    Expression<double>? profitMargin,
    Expression<double>? minPrice,
    Expression<String>? imageUrl,
    Expression<String>? imeis,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (price != null) 'price': price,
      if (costPrice != null) 'cost_price': costPrice,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (unitOfMeasure != null) 'unit_of_measure': unitOfMeasure,
      if (stock != null) 'stock': stock,
      if (minStock != null) 'min_stock': minStock,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (warrantyMonths != null) 'warranty_months': warrantyMonths,
      if (locationId != null) 'location_id': locationId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (commissionEligible != null) 'commission_eligible': commissionEligible,
      if (agentCommissionPercent != null)
        'agent_commission_percent': agentCommissionPercent,
      if (bonusCommission != null) 'bonus_commission': bonusCommission,
      if (profitMargin != null) 'profit_margin': profitMargin,
      if (minPrice != null) 'min_price': minPrice,
      if (imageUrl != null) 'image_url': imageUrl,
      if (imeis != null) 'imeis': imeis,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? description,
      Value<String?>? sku,
      Value<String?>? barcode,
      Value<double>? price,
      Value<double?>? costPrice,
      Value<String>? category,
      Value<String>? type,
      Value<String>? unitOfMeasure,
      Value<double>? stock,
      Value<double>? minStock,
      Value<double>? reorderLevel,
      Value<int>? warrantyMonths,
      Value<String?>? locationId,
      Value<String>? supplierId,
      Value<String?>? batchNumber,
      Value<DateTime?>? expiryDate,
      Value<bool>? commissionEligible,
      Value<double>? agentCommissionPercent,
      Value<double>? bonusCommission,
      Value<double>? profitMargin,
      Value<double>? minPrice,
      Value<String?>? imageUrl,
      Value<String?>? imeis,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      type: type ?? this.type,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      locationId: locationId ?? this.locationId,
      supplierId: supplierId ?? this.supplierId,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      commissionEligible: commissionEligible ?? this.commissionEligible,
      agentCommissionPercent:
          agentCommissionPercent ?? this.agentCommissionPercent,
      bonusCommission: bonusCommission ?? this.bonusCommission,
      profitMargin: profitMargin ?? this.profitMargin,
      minPrice: minPrice ?? this.minPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      imeis: imeis ?? this.imeis,
      synced: synced ?? this.synced,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unitOfMeasure.present) {
      map['unit_of_measure'] = Variable<String>(unitOfMeasure.value);
    }
    if (stock.present) {
      map['stock'] = Variable<double>(stock.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<double>(minStock.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<double>(reorderLevel.value);
    }
    if (warrantyMonths.present) {
      map['warranty_months'] = Variable<int>(warrantyMonths.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<String>(batchNumber.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (commissionEligible.present) {
      map['commission_eligible'] = Variable<bool>(commissionEligible.value);
    }
    if (agentCommissionPercent.present) {
      map['agent_commission_percent'] =
          Variable<double>(agentCommissionPercent.value);
    }
    if (bonusCommission.present) {
      map['bonus_commission'] = Variable<double>(bonusCommission.value);
    }
    if (profitMargin.present) {
      map['profit_margin'] = Variable<double>(profitMargin.value);
    }
    if (minPrice.present) {
      map['min_price'] = Variable<double>(minPrice.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (imeis.present) {
      map['imeis'] = Variable<String>(imeis.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
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
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('stock: $stock, ')
          ..write('minStock: $minStock, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('warrantyMonths: $warrantyMonths, ')
          ..write('locationId: $locationId, ')
          ..write('supplierId: $supplierId, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('commissionEligible: $commissionEligible, ')
          ..write('agentCommissionPercent: $agentCommissionPercent, ')
          ..write('bonusCommission: $bonusCommission, ')
          ..write('profitMargin: $profitMargin, ')
          ..write('minPrice: $minPrice, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imeis: $imeis, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
      'tax', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _invoiceDiscountMeta =
      const VerificationMeta('invoiceDiscount');
  @override
  late final GeneratedColumn<double> invoiceDiscount = GeneratedColumn<double>(
      'invoice_discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountTypeMeta =
      const VerificationMeta('discountType');
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
      'discount_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('FIXED'));
  static const VerificationMeta _loyaltyPointsUsedMeta =
      const VerificationMeta('loyaltyPointsUsed');
  @override
  late final GeneratedColumn<double> loyaltyPointsUsed =
      GeneratedColumn<double>('loyalty_points_used', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _loyaltyPointsEarnedMeta =
      const VerificationMeta('loyaltyPointsEarned');
  @override
  late final GeneratedColumn<double> loyaltyPointsEarned =
      GeneratedColumn<double>('loyalty_points_earned', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
      'invoice_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cashAmountMeta =
      const VerificationMeta('cashAmount');
  @override
  late final GeneratedColumn<double> cashAmount = GeneratedColumn<double>(
      'cash_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cardAmountMeta =
      const VerificationMeta('cardAmount');
  @override
  late final GeneratedColumn<double> cardAmount = GeneratedColumn<double>(
      'card_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shippingChargesMeta =
      const VerificationMeta('shippingCharges');
  @override
  late final GeneratedColumn<double> shippingCharges = GeneratedColumn<double>(
      'shipping_charges', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _agentNameMeta =
      const VerificationMeta('agentName');
  @override
  late final GeneratedColumn<String> agentName = GeneratedColumn<String>(
      'agent_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _agentCommissionMeta =
      const VerificationMeta('agentCommission');
  @override
  late final GeneratedColumn<double> agentCommission = GeneratedColumn<double>(
      'agent_commission', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _agentCommissionTypeMeta =
      const VerificationMeta('agentCommissionType');
  @override
  late final GeneratedColumn<String> agentCommissionType =
      GeneratedColumn<String>('agent_commission_type', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('PERCENT'));
  static const VerificationMeta _agentCommissionPaidMeta =
      const VerificationMeta('agentCommissionPaid');
  @override
  late final GeneratedColumn<bool> agentCommissionPaid = GeneratedColumn<bool>(
      'agent_commission_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("agent_commission_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _shippingAddressMeta =
      const VerificationMeta('shippingAddress');
  @override
  late final GeneratedColumn<String> shippingAddress = GeneratedColumn<String>(
      'shipping_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        customerId,
        employeeId,
        total,
        subtotal,
        tax,
        discount,
        invoiceDiscount,
        discountType,
        loyaltyPointsUsed,
        loyaltyPointsEarned,
        invoiceNumber,
        notes,
        paymentMethod,
        cashAmount,
        cardAmount,
        status,
        locationId,
        shippingCharges,
        agentName,
        agentCommission,
        agentCommissionType,
        agentCommissionPaid,
        synced,
        createdAt,
        updatedAt,
        shippingAddress
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(Insertable<Sale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('tax')) {
      context.handle(
          _taxMeta, tax.isAcceptableOrUnknown(data['tax']!, _taxMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('invoice_discount')) {
      context.handle(
          _invoiceDiscountMeta,
          invoiceDiscount.isAcceptableOrUnknown(
              data['invoice_discount']!, _invoiceDiscountMeta));
    }
    if (data.containsKey('discount_type')) {
      context.handle(
          _discountTypeMeta,
          discountType.isAcceptableOrUnknown(
              data['discount_type']!, _discountTypeMeta));
    }
    if (data.containsKey('loyalty_points_used')) {
      context.handle(
          _loyaltyPointsUsedMeta,
          loyaltyPointsUsed.isAcceptableOrUnknown(
              data['loyalty_points_used']!, _loyaltyPointsUsedMeta));
    }
    if (data.containsKey('loyalty_points_earned')) {
      context.handle(
          _loyaltyPointsEarnedMeta,
          loyaltyPointsEarned.isAcceptableOrUnknown(
              data['loyalty_points_earned']!, _loyaltyPointsEarnedMeta));
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
          _cashAmountMeta,
          cashAmount.isAcceptableOrUnknown(
              data['cash_amount']!, _cashAmountMeta));
    }
    if (data.containsKey('card_amount')) {
      context.handle(
          _cardAmountMeta,
          cardAmount.isAcceptableOrUnknown(
              data['card_amount']!, _cardAmountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('shipping_charges')) {
      context.handle(
          _shippingChargesMeta,
          shippingCharges.isAcceptableOrUnknown(
              data['shipping_charges']!, _shippingChargesMeta));
    }
    if (data.containsKey('agent_name')) {
      context.handle(_agentNameMeta,
          agentName.isAcceptableOrUnknown(data['agent_name']!, _agentNameMeta));
    }
    if (data.containsKey('agent_commission')) {
      context.handle(
          _agentCommissionMeta,
          agentCommission.isAcceptableOrUnknown(
              data['agent_commission']!, _agentCommissionMeta));
    }
    if (data.containsKey('agent_commission_type')) {
      context.handle(
          _agentCommissionTypeMeta,
          agentCommissionType.isAcceptableOrUnknown(
              data['agent_commission_type']!, _agentCommissionTypeMeta));
    }
    if (data.containsKey('agent_commission_paid')) {
      context.handle(
          _agentCommissionPaidMeta,
          agentCommissionPaid.isAcceptableOrUnknown(
              data['agent_commission_paid']!, _agentCommissionPaidMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('shipping_address')) {
      context.handle(
          _shippingAddressMeta,
          shippingAddress.isAcceptableOrUnknown(
              data['shipping_address']!, _shippingAddressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      tax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      invoiceDiscount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}invoice_discount'])!,
      discountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_type'])!,
      loyaltyPointsUsed: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}loyalty_points_used'])!,
      loyaltyPointsEarned: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}loyalty_points_earned'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_number']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      cashAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_amount'])!,
      cardAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}card_amount'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id'])!,
      shippingCharges: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}shipping_charges'])!,
      agentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_name']),
      agentCommission: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}agent_commission'])!,
      agentCommissionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}agent_commission_type'])!,
      agentCommissionPaid: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}agent_commission_paid'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      shippingAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}shipping_address']),
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String id;
  final String tenantId;
  final String? customerId;
  final String employeeId;
  final double total;
  final double subtotal;
  final double tax;
  final double discount;
  final double invoiceDiscount;
  final String discountType;
  final double loyaltyPointsUsed;
  final double loyaltyPointsEarned;
  final String? invoiceNumber;
  final String? notes;
  final String paymentMethod;
  final double cashAmount;
  final double cardAmount;
  final String status;
  final String locationId;
  final double shippingCharges;
  final String? agentName;
  final double agentCommission;
  final String agentCommissionType;
  final bool agentCommissionPaid;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? shippingAddress;
  const Sale(
      {required this.id,
      required this.tenantId,
      this.customerId,
      required this.employeeId,
      required this.total,
      required this.subtotal,
      required this.tax,
      required this.discount,
      required this.invoiceDiscount,
      required this.discountType,
      required this.loyaltyPointsUsed,
      required this.loyaltyPointsEarned,
      this.invoiceNumber,
      this.notes,
      required this.paymentMethod,
      required this.cashAmount,
      required this.cardAmount,
      required this.status,
      required this.locationId,
      required this.shippingCharges,
      this.agentName,
      required this.agentCommission,
      required this.agentCommissionType,
      required this.agentCommissionPaid,
      required this.synced,
      this.createdAt,
      this.updatedAt,
      this.shippingAddress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['employee_id'] = Variable<String>(employeeId);
    map['total'] = Variable<double>(total);
    map['subtotal'] = Variable<double>(subtotal);
    map['tax'] = Variable<double>(tax);
    map['discount'] = Variable<double>(discount);
    map['invoice_discount'] = Variable<double>(invoiceDiscount);
    map['discount_type'] = Variable<String>(discountType);
    map['loyalty_points_used'] = Variable<double>(loyaltyPointsUsed);
    map['loyalty_points_earned'] = Variable<double>(loyaltyPointsEarned);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['cash_amount'] = Variable<double>(cashAmount);
    map['card_amount'] = Variable<double>(cardAmount);
    map['status'] = Variable<String>(status);
    map['location_id'] = Variable<String>(locationId);
    map['shipping_charges'] = Variable<double>(shippingCharges);
    if (!nullToAbsent || agentName != null) {
      map['agent_name'] = Variable<String>(agentName);
    }
    map['agent_commission'] = Variable<double>(agentCommission);
    map['agent_commission_type'] = Variable<String>(agentCommissionType);
    map['agent_commission_paid'] = Variable<bool>(agentCommissionPaid);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || shippingAddress != null) {
      map['shipping_address'] = Variable<String>(shippingAddress);
    }
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      employeeId: Value(employeeId),
      total: Value(total),
      subtotal: Value(subtotal),
      tax: Value(tax),
      discount: Value(discount),
      invoiceDiscount: Value(invoiceDiscount),
      discountType: Value(discountType),
      loyaltyPointsUsed: Value(loyaltyPointsUsed),
      loyaltyPointsEarned: Value(loyaltyPointsEarned),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      paymentMethod: Value(paymentMethod),
      cashAmount: Value(cashAmount),
      cardAmount: Value(cardAmount),
      status: Value(status),
      locationId: Value(locationId),
      shippingCharges: Value(shippingCharges),
      agentName: agentName == null && nullToAbsent
          ? const Value.absent()
          : Value(agentName),
      agentCommission: Value(agentCommission),
      agentCommissionType: Value(agentCommissionType),
      agentCommissionPaid: Value(agentCommissionPaid),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      shippingAddress: shippingAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(shippingAddress),
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      total: serializer.fromJson<double>(json['total']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      tax: serializer.fromJson<double>(json['tax']),
      discount: serializer.fromJson<double>(json['discount']),
      invoiceDiscount: serializer.fromJson<double>(json['invoiceDiscount']),
      discountType: serializer.fromJson<String>(json['discountType']),
      loyaltyPointsUsed: serializer.fromJson<double>(json['loyaltyPointsUsed']),
      loyaltyPointsEarned:
          serializer.fromJson<double>(json['loyaltyPointsEarned']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      cashAmount: serializer.fromJson<double>(json['cashAmount']),
      cardAmount: serializer.fromJson<double>(json['cardAmount']),
      status: serializer.fromJson<String>(json['status']),
      locationId: serializer.fromJson<String>(json['locationId']),
      shippingCharges: serializer.fromJson<double>(json['shippingCharges']),
      agentName: serializer.fromJson<String?>(json['agentName']),
      agentCommission: serializer.fromJson<double>(json['agentCommission']),
      agentCommissionType:
          serializer.fromJson<String>(json['agentCommissionType']),
      agentCommissionPaid:
          serializer.fromJson<bool>(json['agentCommissionPaid']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      shippingAddress: serializer.fromJson<String?>(json['shippingAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'customerId': serializer.toJson<String?>(customerId),
      'employeeId': serializer.toJson<String>(employeeId),
      'total': serializer.toJson<double>(total),
      'subtotal': serializer.toJson<double>(subtotal),
      'tax': serializer.toJson<double>(tax),
      'discount': serializer.toJson<double>(discount),
      'invoiceDiscount': serializer.toJson<double>(invoiceDiscount),
      'discountType': serializer.toJson<String>(discountType),
      'loyaltyPointsUsed': serializer.toJson<double>(loyaltyPointsUsed),
      'loyaltyPointsEarned': serializer.toJson<double>(loyaltyPointsEarned),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'notes': serializer.toJson<String?>(notes),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'cashAmount': serializer.toJson<double>(cashAmount),
      'cardAmount': serializer.toJson<double>(cardAmount),
      'status': serializer.toJson<String>(status),
      'locationId': serializer.toJson<String>(locationId),
      'shippingCharges': serializer.toJson<double>(shippingCharges),
      'agentName': serializer.toJson<String?>(agentName),
      'agentCommission': serializer.toJson<double>(agentCommission),
      'agentCommissionType': serializer.toJson<String>(agentCommissionType),
      'agentCommissionPaid': serializer.toJson<bool>(agentCommissionPaid),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'shippingAddress': serializer.toJson<String?>(shippingAddress),
    };
  }

  Sale copyWith(
          {String? id,
          String? tenantId,
          Value<String?> customerId = const Value.absent(),
          String? employeeId,
          double? total,
          double? subtotal,
          double? tax,
          double? discount,
          double? invoiceDiscount,
          String? discountType,
          double? loyaltyPointsUsed,
          double? loyaltyPointsEarned,
          Value<String?> invoiceNumber = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? paymentMethod,
          double? cashAmount,
          double? cardAmount,
          String? status,
          String? locationId,
          double? shippingCharges,
          Value<String?> agentName = const Value.absent(),
          double? agentCommission,
          String? agentCommissionType,
          bool? agentCommissionPaid,
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<String?> shippingAddress = const Value.absent()}) =>
      Sale(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        customerId: customerId.present ? customerId.value : this.customerId,
        employeeId: employeeId ?? this.employeeId,
        total: total ?? this.total,
        subtotal: subtotal ?? this.subtotal,
        tax: tax ?? this.tax,
        discount: discount ?? this.discount,
        invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
        discountType: discountType ?? this.discountType,
        loyaltyPointsUsed: loyaltyPointsUsed ?? this.loyaltyPointsUsed,
        loyaltyPointsEarned: loyaltyPointsEarned ?? this.loyaltyPointsEarned,
        invoiceNumber:
            invoiceNumber.present ? invoiceNumber.value : this.invoiceNumber,
        notes: notes.present ? notes.value : this.notes,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        cashAmount: cashAmount ?? this.cashAmount,
        cardAmount: cardAmount ?? this.cardAmount,
        status: status ?? this.status,
        locationId: locationId ?? this.locationId,
        shippingCharges: shippingCharges ?? this.shippingCharges,
        agentName: agentName.present ? agentName.value : this.agentName,
        agentCommission: agentCommission ?? this.agentCommission,
        agentCommissionType: agentCommissionType ?? this.agentCommissionType,
        agentCommissionPaid: agentCommissionPaid ?? this.agentCommissionPaid,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        shippingAddress: shippingAddress.present
            ? shippingAddress.value
            : this.shippingAddress,
      );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      total: data.total.present ? data.total.value : this.total,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      tax: data.tax.present ? data.tax.value : this.tax,
      discount: data.discount.present ? data.discount.value : this.discount,
      invoiceDiscount: data.invoiceDiscount.present
          ? data.invoiceDiscount.value
          : this.invoiceDiscount,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      loyaltyPointsUsed: data.loyaltyPointsUsed.present
          ? data.loyaltyPointsUsed.value
          : this.loyaltyPointsUsed,
      loyaltyPointsEarned: data.loyaltyPointsEarned.present
          ? data.loyaltyPointsEarned.value
          : this.loyaltyPointsEarned,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      cashAmount:
          data.cashAmount.present ? data.cashAmount.value : this.cashAmount,
      cardAmount:
          data.cardAmount.present ? data.cardAmount.value : this.cardAmount,
      status: data.status.present ? data.status.value : this.status,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      shippingCharges: data.shippingCharges.present
          ? data.shippingCharges.value
          : this.shippingCharges,
      agentName: data.agentName.present ? data.agentName.value : this.agentName,
      agentCommission: data.agentCommission.present
          ? data.agentCommission.value
          : this.agentCommission,
      agentCommissionType: data.agentCommissionType.present
          ? data.agentCommissionType.value
          : this.agentCommissionType,
      agentCommissionPaid: data.agentCommissionPaid.present
          ? data.agentCommissionPaid.value
          : this.agentCommissionPaid,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      shippingAddress: data.shippingAddress.present
          ? data.shippingAddress.value
          : this.shippingAddress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('total: $total, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('discount: $discount, ')
          ..write('invoiceDiscount: $invoiceDiscount, ')
          ..write('discountType: $discountType, ')
          ..write('loyaltyPointsUsed: $loyaltyPointsUsed, ')
          ..write('loyaltyPointsEarned: $loyaltyPointsEarned, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('cardAmount: $cardAmount, ')
          ..write('status: $status, ')
          ..write('locationId: $locationId, ')
          ..write('shippingCharges: $shippingCharges, ')
          ..write('agentName: $agentName, ')
          ..write('agentCommission: $agentCommission, ')
          ..write('agentCommissionType: $agentCommissionType, ')
          ..write('agentCommissionPaid: $agentCommissionPaid, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('shippingAddress: $shippingAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        tenantId,
        customerId,
        employeeId,
        total,
        subtotal,
        tax,
        discount,
        invoiceDiscount,
        discountType,
        loyaltyPointsUsed,
        loyaltyPointsEarned,
        invoiceNumber,
        notes,
        paymentMethod,
        cashAmount,
        cardAmount,
        status,
        locationId,
        shippingCharges,
        agentName,
        agentCommission,
        agentCommissionType,
        agentCommissionPaid,
        synced,
        createdAt,
        updatedAt,
        shippingAddress
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.customerId == this.customerId &&
          other.employeeId == this.employeeId &&
          other.total == this.total &&
          other.subtotal == this.subtotal &&
          other.tax == this.tax &&
          other.discount == this.discount &&
          other.invoiceDiscount == this.invoiceDiscount &&
          other.discountType == this.discountType &&
          other.loyaltyPointsUsed == this.loyaltyPointsUsed &&
          other.loyaltyPointsEarned == this.loyaltyPointsEarned &&
          other.invoiceNumber == this.invoiceNumber &&
          other.notes == this.notes &&
          other.paymentMethod == this.paymentMethod &&
          other.cashAmount == this.cashAmount &&
          other.cardAmount == this.cardAmount &&
          other.status == this.status &&
          other.locationId == this.locationId &&
          other.shippingCharges == this.shippingCharges &&
          other.agentName == this.agentName &&
          other.agentCommission == this.agentCommission &&
          other.agentCommissionType == this.agentCommissionType &&
          other.agentCommissionPaid == this.agentCommissionPaid &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.shippingAddress == this.shippingAddress);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> customerId;
  final Value<String> employeeId;
  final Value<double> total;
  final Value<double> subtotal;
  final Value<double> tax;
  final Value<double> discount;
  final Value<double> invoiceDiscount;
  final Value<String> discountType;
  final Value<double> loyaltyPointsUsed;
  final Value<double> loyaltyPointsEarned;
  final Value<String?> invoiceNumber;
  final Value<String?> notes;
  final Value<String> paymentMethod;
  final Value<double> cashAmount;
  final Value<double> cardAmount;
  final Value<String> status;
  final Value<String> locationId;
  final Value<double> shippingCharges;
  final Value<String?> agentName;
  final Value<double> agentCommission;
  final Value<String> agentCommissionType;
  final Value<bool> agentCommissionPaid;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String?> shippingAddress;
  final Value<int> rowid;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.total = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.discount = const Value.absent(),
    this.invoiceDiscount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.loyaltyPointsUsed = const Value.absent(),
    this.loyaltyPointsEarned = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.cardAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.locationId = const Value.absent(),
    this.shippingCharges = const Value.absent(),
    this.agentName = const Value.absent(),
    this.agentCommission = const Value.absent(),
    this.agentCommissionType = const Value.absent(),
    this.agentCommissionPaid = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.shippingAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String id,
    required String tenantId,
    this.customerId = const Value.absent(),
    required String employeeId,
    required double total,
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.discount = const Value.absent(),
    this.invoiceDiscount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.loyaltyPointsUsed = const Value.absent(),
    this.loyaltyPointsEarned = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.notes = const Value.absent(),
    required String paymentMethod,
    this.cashAmount = const Value.absent(),
    this.cardAmount = const Value.absent(),
    required String status,
    required String locationId,
    this.shippingCharges = const Value.absent(),
    this.agentName = const Value.absent(),
    this.agentCommission = const Value.absent(),
    this.agentCommissionType = const Value.absent(),
    this.agentCommissionPaid = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.shippingAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        employeeId = Value(employeeId),
        total = Value(total),
        paymentMethod = Value(paymentMethod),
        status = Value(status),
        locationId = Value(locationId);
  static Insertable<Sale> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? customerId,
    Expression<String>? employeeId,
    Expression<double>? total,
    Expression<double>? subtotal,
    Expression<double>? tax,
    Expression<double>? discount,
    Expression<double>? invoiceDiscount,
    Expression<String>? discountType,
    Expression<double>? loyaltyPointsUsed,
    Expression<double>? loyaltyPointsEarned,
    Expression<String>? invoiceNumber,
    Expression<String>? notes,
    Expression<String>? paymentMethod,
    Expression<double>? cashAmount,
    Expression<double>? cardAmount,
    Expression<String>? status,
    Expression<String>? locationId,
    Expression<double>? shippingCharges,
    Expression<String>? agentName,
    Expression<double>? agentCommission,
    Expression<String>? agentCommissionType,
    Expression<bool>? agentCommissionPaid,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? shippingAddress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (customerId != null) 'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (total != null) 'total': total,
      if (subtotal != null) 'subtotal': subtotal,
      if (tax != null) 'tax': tax,
      if (discount != null) 'discount': discount,
      if (invoiceDiscount != null) 'invoice_discount': invoiceDiscount,
      if (discountType != null) 'discount_type': discountType,
      if (loyaltyPointsUsed != null) 'loyalty_points_used': loyaltyPointsUsed,
      if (loyaltyPointsEarned != null)
        'loyalty_points_earned': loyaltyPointsEarned,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (cardAmount != null) 'card_amount': cardAmount,
      if (status != null) 'status': status,
      if (locationId != null) 'location_id': locationId,
      if (shippingCharges != null) 'shipping_charges': shippingCharges,
      if (agentName != null) 'agent_name': agentName,
      if (agentCommission != null) 'agent_commission': agentCommission,
      if (agentCommissionType != null)
        'agent_commission_type': agentCommissionType,
      if (agentCommissionPaid != null)
        'agent_commission_paid': agentCommissionPaid,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String?>? customerId,
      Value<String>? employeeId,
      Value<double>? total,
      Value<double>? subtotal,
      Value<double>? tax,
      Value<double>? discount,
      Value<double>? invoiceDiscount,
      Value<String>? discountType,
      Value<double>? loyaltyPointsUsed,
      Value<double>? loyaltyPointsEarned,
      Value<String?>? invoiceNumber,
      Value<String?>? notes,
      Value<String>? paymentMethod,
      Value<double>? cashAmount,
      Value<double>? cardAmount,
      Value<String>? status,
      Value<String>? locationId,
      Value<double>? shippingCharges,
      Value<String?>? agentName,
      Value<double>? agentCommission,
      Value<String>? agentCommissionType,
      Value<bool>? agentCommissionPaid,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String?>? shippingAddress,
      Value<int>? rowid}) {
    return SalesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      discountType: discountType ?? this.discountType,
      loyaltyPointsUsed: loyaltyPointsUsed ?? this.loyaltyPointsUsed,
      loyaltyPointsEarned: loyaltyPointsEarned ?? this.loyaltyPointsEarned,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashAmount: cashAmount ?? this.cashAmount,
      cardAmount: cardAmount ?? this.cardAmount,
      status: status ?? this.status,
      locationId: locationId ?? this.locationId,
      shippingCharges: shippingCharges ?? this.shippingCharges,
      agentName: agentName ?? this.agentName,
      agentCommission: agentCommission ?? this.agentCommission,
      agentCommissionType: agentCommissionType ?? this.agentCommissionType,
      agentCommissionPaid: agentCommissionPaid ?? this.agentCommissionPaid,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
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
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (invoiceDiscount.present) {
      map['invoice_discount'] = Variable<double>(invoiceDiscount.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (loyaltyPointsUsed.present) {
      map['loyalty_points_used'] = Variable<double>(loyaltyPointsUsed.value);
    }
    if (loyaltyPointsEarned.present) {
      map['loyalty_points_earned'] =
          Variable<double>(loyaltyPointsEarned.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<double>(cashAmount.value);
    }
    if (cardAmount.present) {
      map['card_amount'] = Variable<double>(cardAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (shippingCharges.present) {
      map['shipping_charges'] = Variable<double>(shippingCharges.value);
    }
    if (agentName.present) {
      map['agent_name'] = Variable<String>(agentName.value);
    }
    if (agentCommission.present) {
      map['agent_commission'] = Variable<double>(agentCommission.value);
    }
    if (agentCommissionType.present) {
      map['agent_commission_type'] =
          Variable<String>(agentCommissionType.value);
    }
    if (agentCommissionPaid.present) {
      map['agent_commission_paid'] = Variable<bool>(agentCommissionPaid.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (shippingAddress.present) {
      map['shipping_address'] = Variable<String>(shippingAddress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('employeeId: $employeeId, ')
          ..write('total: $total, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('discount: $discount, ')
          ..write('invoiceDiscount: $invoiceDiscount, ')
          ..write('discountType: $discountType, ')
          ..write('loyaltyPointsUsed: $loyaltyPointsUsed, ')
          ..write('loyaltyPointsEarned: $loyaltyPointsEarned, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('notes: $notes, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('cardAmount: $cardAmount, ')
          ..write('status: $status, ')
          ..write('locationId: $locationId, ')
          ..write('shippingCharges: $shippingCharges, ')
          ..write('agentName: $agentName, ')
          ..write('agentCommission: $agentCommission, ')
          ..write('agentCommissionType: $agentCommissionType, ')
          ..write('agentCommissionPaid: $agentCommissionPaid, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('shippingAddress: $shippingAddress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _originalPriceMeta =
      const VerificationMeta('originalPrice');
  @override
  late final GeneratedColumn<double> originalPrice = GeneratedColumn<double>(
      'original_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountTypeMeta =
      const VerificationMeta('discountType');
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
      'discount_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('FIXED'));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _commissionAmountMeta =
      const VerificationMeta('commissionAmount');
  @override
  late final GeneratedColumn<double> commissionAmount = GeneratedColumn<double>(
      'commission_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imeiMeta = const VerificationMeta('imei');
  @override
  late final GeneratedColumn<String> imei = GeneratedColumn<String>(
      'imei', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        saleId,
        productId,
        productName,
        quantity,
        unitPrice,
        originalPrice,
        discount,
        discountType,
        total,
        commissionAmount,
        tenantId,
        imei
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(Insertable<SaleItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('original_price')) {
      context.handle(
          _originalPriceMeta,
          originalPrice.isAcceptableOrUnknown(
              data['original_price']!, _originalPriceMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('discount_type')) {
      context.handle(
          _discountTypeMeta,
          discountType.isAcceptableOrUnknown(
              data['discount_type']!, _discountTypeMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('commission_amount')) {
      context.handle(
          _commissionAmountMeta,
          commissionAmount.isAcceptableOrUnknown(
              data['commission_amount']!, _commissionAmountMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('imei')) {
      context.handle(
          _imeiMeta, imei.isAcceptableOrUnknown(data['imei']!, _imeiMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price'])!,
      originalPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}original_price'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      discountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_type'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      commissionAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}commission_amount'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      imei: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imei']),
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double originalPrice;
  final double discount;
  final String discountType;
  final double total;
  final double commissionAmount;
  final String tenantId;
  final String? imei;
  const SaleItem(
      {required this.id,
      required this.saleId,
      required this.productId,
      required this.productName,
      required this.quantity,
      required this.unitPrice,
      required this.originalPrice,
      required this.discount,
      required this.discountType,
      required this.total,
      required this.commissionAmount,
      required this.tenantId,
      this.imei});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['original_price'] = Variable<double>(originalPrice);
    map['discount'] = Variable<double>(discount);
    map['discount_type'] = Variable<String>(discountType);
    map['total'] = Variable<double>(total);
    map['commission_amount'] = Variable<double>(commissionAmount);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || imei != null) {
      map['imei'] = Variable<String>(imei);
    }
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      originalPrice: Value(originalPrice),
      discount: Value(discount),
      discountType: Value(discountType),
      total: Value(total),
      commissionAmount: Value(commissionAmount),
      tenantId: Value(tenantId),
      imei: imei == null && nullToAbsent ? const Value.absent() : Value(imei),
    );
  }

  factory SaleItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      originalPrice: serializer.fromJson<double>(json['originalPrice']),
      discount: serializer.fromJson<double>(json['discount']),
      discountType: serializer.fromJson<String>(json['discountType']),
      total: serializer.fromJson<double>(json['total']),
      commissionAmount: serializer.fromJson<double>(json['commissionAmount']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      imei: serializer.fromJson<String?>(json['imei']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'originalPrice': serializer.toJson<double>(originalPrice),
      'discount': serializer.toJson<double>(discount),
      'discountType': serializer.toJson<String>(discountType),
      'total': serializer.toJson<double>(total),
      'commissionAmount': serializer.toJson<double>(commissionAmount),
      'tenantId': serializer.toJson<String>(tenantId),
      'imei': serializer.toJson<String?>(imei),
    };
  }

  SaleItem copyWith(
          {String? id,
          String? saleId,
          String? productId,
          String? productName,
          double? quantity,
          double? unitPrice,
          double? originalPrice,
          double? discount,
          String? discountType,
          double? total,
          double? commissionAmount,
          String? tenantId,
          Value<String?> imei = const Value.absent()}) =>
      SaleItem(
        id: id ?? this.id,
        saleId: saleId ?? this.saleId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        originalPrice: originalPrice ?? this.originalPrice,
        discount: discount ?? this.discount,
        discountType: discountType ?? this.discountType,
        total: total ?? this.total,
        commissionAmount: commissionAmount ?? this.commissionAmount,
        tenantId: tenantId ?? this.tenantId,
        imei: imei.present ? imei.value : this.imei,
      );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      originalPrice: data.originalPrice.present
          ? data.originalPrice.value
          : this.originalPrice,
      discount: data.discount.present ? data.discount.value : this.discount,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      total: data.total.present ? data.total.value : this.total,
      commissionAmount: data.commissionAmount.present
          ? data.commissionAmount.value
          : this.commissionAmount,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      imei: data.imei.present ? data.imei.value : this.imei,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('discount: $discount, ')
          ..write('discountType: $discountType, ')
          ..write('total: $total, ')
          ..write('commissionAmount: $commissionAmount, ')
          ..write('tenantId: $tenantId, ')
          ..write('imei: $imei')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      saleId,
      productId,
      productName,
      quantity,
      unitPrice,
      originalPrice,
      discount,
      discountType,
      total,
      commissionAmount,
      tenantId,
      imei);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.originalPrice == this.originalPrice &&
          other.discount == this.discount &&
          other.discountType == this.discountType &&
          other.total == this.total &&
          other.commissionAmount == this.commissionAmount &&
          other.tenantId == this.tenantId &&
          other.imei == this.imei);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> originalPrice;
  final Value<double> discount;
  final Value<String> discountType;
  final Value<double> total;
  final Value<double> commissionAmount;
  final Value<String> tenantId;
  final Value<String?> imei;
  final Value<int> rowid;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.discount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.total = const Value.absent(),
    this.commissionAmount = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.imei = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    this.originalPrice = const Value.absent(),
    this.discount = const Value.absent(),
    this.discountType = const Value.absent(),
    required double total,
    this.commissionAmount = const Value.absent(),
    required String tenantId,
    this.imei = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        saleId = Value(saleId),
        productId = Value(productId),
        productName = Value(productName),
        quantity = Value(quantity),
        unitPrice = Value(unitPrice),
        total = Value(total),
        tenantId = Value(tenantId);
  static Insertable<SaleItem> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? originalPrice,
    Expression<double>? discount,
    Expression<String>? discountType,
    Expression<double>? total,
    Expression<double>? commissionAmount,
    Expression<String>? tenantId,
    Expression<String>? imei,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (originalPrice != null) 'original_price': originalPrice,
      if (discount != null) 'discount': discount,
      if (discountType != null) 'discount_type': discountType,
      if (total != null) 'total': total,
      if (commissionAmount != null) 'commission_amount': commissionAmount,
      if (tenantId != null) 'tenant_id': tenantId,
      if (imei != null) 'imei': imei,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? saleId,
      Value<String>? productId,
      Value<String>? productName,
      Value<double>? quantity,
      Value<double>? unitPrice,
      Value<double>? originalPrice,
      Value<double>? discount,
      Value<String>? discountType,
      Value<double>? total,
      Value<double>? commissionAmount,
      Value<String>? tenantId,
      Value<String?>? imei,
      Value<int>? rowid}) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      total: total ?? this.total,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      tenantId: tenantId ?? this.tenantId,
      imei: imei ?? this.imei,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (originalPrice.present) {
      map['original_price'] = Variable<double>(originalPrice.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (commissionAmount.present) {
      map['commission_amount'] = Variable<double>(commissionAmount.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (imei.present) {
      map['imei'] = Variable<String>(imei.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('discount: $discount, ')
          ..write('discountType: $discountType, ')
          ..write('total: $total, ')
          ..write('commissionAmount: $commissionAmount, ')
          ..write('tenantId: $tenantId, ')
          ..write('imei: $imei, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vehicleNumberMeta =
      const VerificationMeta('vehicleNumber');
  @override
  late final GeneratedColumn<String> vehicleNumber = GeneratedColumn<String>(
      'vehicle_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _creditLimitMeta =
      const VerificationMeta('creditLimit');
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
      'credit_limit', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentBalanceMeta =
      const VerificationMeta('currentBalance');
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
      'current_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _loyaltyPointsMeta =
      const VerificationMeta('loyaltyPoints');
  @override
  late final GeneratedColumn<double> loyaltyPoints = GeneratedColumn<double>(
      'loyalty_points', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalPurchasesMeta =
      const VerificationMeta('totalPurchases');
  @override
  late final GeneratedColumn<double> totalPurchases = GeneratedColumn<double>(
      'total_purchases', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _customerTypeMeta =
      const VerificationMeta('customerType');
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
      'customer_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('RETAIL'));
  static const VerificationMeta _discountPercentMeta =
      const VerificationMeta('discountPercent');
  @override
  late final GeneratedColumn<double> discountPercent = GeneratedColumn<double>(
      'discount_percent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
      'birthday', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _shippingAddressMeta =
      const VerificationMeta('shippingAddress');
  @override
  late final GeneratedColumn<String> shippingAddress = GeneratedColumn<String>(
      'shipping_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        name,
        phone,
        email,
        address,
        vehicleNumber,
        creditLimit,
        currentBalance,
        loyaltyPoints,
        totalPurchases,
        customerType,
        discountPercent,
        birthday,
        notes,
        synced,
        createdAt,
        updatedAt,
        shippingAddress
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('vehicle_number')) {
      context.handle(
          _vehicleNumberMeta,
          vehicleNumber.isAcceptableOrUnknown(
              data['vehicle_number']!, _vehicleNumberMeta));
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
          _creditLimitMeta,
          creditLimit.isAcceptableOrUnknown(
              data['credit_limit']!, _creditLimitMeta));
    }
    if (data.containsKey('current_balance')) {
      context.handle(
          _currentBalanceMeta,
          currentBalance.isAcceptableOrUnknown(
              data['current_balance']!, _currentBalanceMeta));
    }
    if (data.containsKey('loyalty_points')) {
      context.handle(
          _loyaltyPointsMeta,
          loyaltyPoints.isAcceptableOrUnknown(
              data['loyalty_points']!, _loyaltyPointsMeta));
    }
    if (data.containsKey('total_purchases')) {
      context.handle(
          _totalPurchasesMeta,
          totalPurchases.isAcceptableOrUnknown(
              data['total_purchases']!, _totalPurchasesMeta));
    }
    if (data.containsKey('customer_type')) {
      context.handle(
          _customerTypeMeta,
          customerType.isAcceptableOrUnknown(
              data['customer_type']!, _customerTypeMeta));
    }
    if (data.containsKey('discount_percent')) {
      context.handle(
          _discountPercentMeta,
          discountPercent.isAcceptableOrUnknown(
              data['discount_percent']!, _discountPercentMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('shipping_address')) {
      context.handle(
          _shippingAddressMeta,
          shippingAddress.isAcceptableOrUnknown(
              data['shipping_address']!, _shippingAddressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      vehicleNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_number']),
      creditLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}credit_limit'])!,
      currentBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_balance'])!,
      loyaltyPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}loyalty_points'])!,
      totalPurchases: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_purchases'])!,
      customerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_type'])!,
      discountPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_percent'])!,
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}birthday']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      shippingAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}shipping_address']),
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? vehicleNumber;
  final double creditLimit;
  final double currentBalance;
  final double loyaltyPoints;
  final double totalPurchases;
  final String customerType;
  final double discountPercent;
  final DateTime? birthday;
  final String? notes;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? shippingAddress;
  const Customer(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.phone,
      this.email,
      this.address,
      this.vehicleNumber,
      required this.creditLimit,
      required this.currentBalance,
      required this.loyaltyPoints,
      required this.totalPurchases,
      required this.customerType,
      required this.discountPercent,
      this.birthday,
      this.notes,
      required this.synced,
      this.createdAt,
      this.updatedAt,
      this.shippingAddress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || vehicleNumber != null) {
      map['vehicle_number'] = Variable<String>(vehicleNumber);
    }
    map['credit_limit'] = Variable<double>(creditLimit);
    map['current_balance'] = Variable<double>(currentBalance);
    map['loyalty_points'] = Variable<double>(loyaltyPoints);
    map['total_purchases'] = Variable<double>(totalPurchases);
    map['customer_type'] = Variable<String>(customerType);
    map['discount_percent'] = Variable<double>(discountPercent);
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || shippingAddress != null) {
      map['shipping_address'] = Variable<String>(shippingAddress);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      phone: Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      vehicleNumber: vehicleNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleNumber),
      creditLimit: Value(creditLimit),
      currentBalance: Value(currentBalance),
      loyaltyPoints: Value(loyaltyPoints),
      totalPurchases: Value(totalPurchases),
      customerType: Value(customerType),
      discountPercent: Value(discountPercent),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      shippingAddress: shippingAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(shippingAddress),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      vehicleNumber: serializer.fromJson<String?>(json['vehicleNumber']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      loyaltyPoints: serializer.fromJson<double>(json['loyaltyPoints']),
      totalPurchases: serializer.fromJson<double>(json['totalPurchases']),
      customerType: serializer.fromJson<String>(json['customerType']),
      discountPercent: serializer.fromJson<double>(json['discountPercent']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      notes: serializer.fromJson<String?>(json['notes']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      shippingAddress: serializer.fromJson<String?>(json['shippingAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'vehicleNumber': serializer.toJson<String?>(vehicleNumber),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'loyaltyPoints': serializer.toJson<double>(loyaltyPoints),
      'totalPurchases': serializer.toJson<double>(totalPurchases),
      'customerType': serializer.toJson<String>(customerType),
      'discountPercent': serializer.toJson<double>(discountPercent),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'notes': serializer.toJson<String?>(notes),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'shippingAddress': serializer.toJson<String?>(shippingAddress),
    };
  }

  Customer copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? phone,
          Value<String?> email = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> vehicleNumber = const Value.absent(),
          double? creditLimit,
          double? currentBalance,
          double? loyaltyPoints,
          double? totalPurchases,
          String? customerType,
          double? discountPercent,
          Value<DateTime?> birthday = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<String?> shippingAddress = const Value.absent()}) =>
      Customer(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email.present ? email.value : this.email,
        address: address.present ? address.value : this.address,
        vehicleNumber:
            vehicleNumber.present ? vehicleNumber.value : this.vehicleNumber,
        creditLimit: creditLimit ?? this.creditLimit,
        currentBalance: currentBalance ?? this.currentBalance,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        totalPurchases: totalPurchases ?? this.totalPurchases,
        customerType: customerType ?? this.customerType,
        discountPercent: discountPercent ?? this.discountPercent,
        birthday: birthday.present ? birthday.value : this.birthday,
        notes: notes.present ? notes.value : this.notes,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        shippingAddress: shippingAddress.present
            ? shippingAddress.value
            : this.shippingAddress,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      vehicleNumber: data.vehicleNumber.present
          ? data.vehicleNumber.value
          : this.vehicleNumber,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      loyaltyPoints: data.loyaltyPoints.present
          ? data.loyaltyPoints.value
          : this.loyaltyPoints,
      totalPurchases: data.totalPurchases.present
          ? data.totalPurchases.value
          : this.totalPurchases,
      customerType: data.customerType.present
          ? data.customerType.value
          : this.customerType,
      discountPercent: data.discountPercent.present
          ? data.discountPercent.value
          : this.discountPercent,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      notes: data.notes.present ? data.notes.value : this.notes,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      shippingAddress: data.shippingAddress.present
          ? data.shippingAddress.value
          : this.shippingAddress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('customerType: $customerType, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('birthday: $birthday, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('shippingAddress: $shippingAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      name,
      phone,
      email,
      address,
      vehicleNumber,
      creditLimit,
      currentBalance,
      loyaltyPoints,
      totalPurchases,
      customerType,
      discountPercent,
      birthday,
      notes,
      synced,
      createdAt,
      updatedAt,
      shippingAddress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.vehicleNumber == this.vehicleNumber &&
          other.creditLimit == this.creditLimit &&
          other.currentBalance == this.currentBalance &&
          other.loyaltyPoints == this.loyaltyPoints &&
          other.totalPurchases == this.totalPurchases &&
          other.customerType == this.customerType &&
          other.discountPercent == this.discountPercent &&
          other.birthday == this.birthday &&
          other.notes == this.notes &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.shippingAddress == this.shippingAddress);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> vehicleNumber;
  final Value<double> creditLimit;
  final Value<double> currentBalance;
  final Value<double> loyaltyPoints;
  final Value<double> totalPurchases;
  final Value<String> customerType;
  final Value<double> discountPercent;
  final Value<DateTime?> birthday;
  final Value<String?> notes;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String?> shippingAddress;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.vehicleNumber = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    this.customerType = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.birthday = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.shippingAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String phone,
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.vehicleNumber = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.loyaltyPoints = const Value.absent(),
    this.totalPurchases = const Value.absent(),
    this.customerType = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.birthday = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.shippingAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        phone = Value(phone);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? vehicleNumber,
    Expression<double>? creditLimit,
    Expression<double>? currentBalance,
    Expression<double>? loyaltyPoints,
    Expression<double>? totalPurchases,
    Expression<String>? customerType,
    Expression<double>? discountPercent,
    Expression<DateTime>? birthday,
    Expression<String>? notes,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? shippingAddress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (loyaltyPoints != null) 'loyalty_points': loyaltyPoints,
      if (totalPurchases != null) 'total_purchases': totalPurchases,
      if (customerType != null) 'customer_type': customerType,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (birthday != null) 'birthday': birthday,
      if (notes != null) 'notes': notes,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? phone,
      Value<String?>? email,
      Value<String?>? address,
      Value<String?>? vehicleNumber,
      Value<double>? creditLimit,
      Value<double>? currentBalance,
      Value<double>? loyaltyPoints,
      Value<double>? totalPurchases,
      Value<String>? customerType,
      Value<double>? discountPercent,
      Value<DateTime?>? birthday,
      Value<String?>? notes,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String?>? shippingAddress,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      customerType: customerType ?? this.customerType,
      discountPercent: discountPercent ?? this.discountPercent,
      birthday: birthday ?? this.birthday,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (vehicleNumber.present) {
      map['vehicle_number'] = Variable<String>(vehicleNumber.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (loyaltyPoints.present) {
      map['loyalty_points'] = Variable<double>(loyaltyPoints.value);
    }
    if (totalPurchases.present) {
      map['total_purchases'] = Variable<double>(totalPurchases.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (discountPercent.present) {
      map['discount_percent'] = Variable<double>(discountPercent.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (shippingAddress.present) {
      map['shipping_address'] = Variable<String>(shippingAddress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('loyaltyPoints: $loyaltyPoints, ')
          ..write('totalPurchases: $totalPurchases, ')
          ..write('customerType: $customerType, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('birthday: $birthday, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('shippingAddress: $shippingAddress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, Employee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _commissionTypeMeta =
      const VerificationMeta('commissionType');
  @override
  late final GeneratedColumn<String> commissionType = GeneratedColumn<String>(
      'commission_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('NONE'));
  static const VerificationMeta _commissionValueMeta =
      const VerificationMeta('commissionValue');
  @override
  late final GeneratedColumn<double> commissionValue = GeneratedColumn<double>(
      'commission_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minSalesTargetMeta =
      const VerificationMeta('minSalesTarget');
  @override
  late final GeneratedColumn<double> minSalesTarget = GeneratedColumn<double>(
      'min_sales_target', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isAgentMeta =
      const VerificationMeta('isAgent');
  @override
  late final GeneratedColumn<bool> isAgent = GeneratedColumn<bool>(
      'is_agent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_agent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _joiningDateMeta =
      const VerificationMeta('joiningDate');
  @override
  late final GeneratedColumn<DateTime> joiningDate = GeneratedColumn<DateTime>(
      'joining_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        name,
        email,
        phone,
        role,
        locationId,
        commissionType,
        commissionValue,
        minSalesTarget,
        isAgent,
        joiningDate,
        synced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(Insertable<Employee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('commission_type')) {
      context.handle(
          _commissionTypeMeta,
          commissionType.isAcceptableOrUnknown(
              data['commission_type']!, _commissionTypeMeta));
    }
    if (data.containsKey('commission_value')) {
      context.handle(
          _commissionValueMeta,
          commissionValue.isAcceptableOrUnknown(
              data['commission_value']!, _commissionValueMeta));
    }
    if (data.containsKey('min_sales_target')) {
      context.handle(
          _minSalesTargetMeta,
          minSalesTarget.isAcceptableOrUnknown(
              data['min_sales_target']!, _minSalesTargetMeta));
    }
    if (data.containsKey('is_agent')) {
      context.handle(_isAgentMeta,
          isAgent.isAcceptableOrUnknown(data['is_agent']!, _isAgentMeta));
    }
    if (data.containsKey('joining_date')) {
      context.handle(
          _joiningDateMeta,
          joiningDate.isAcceptableOrUnknown(
              data['joining_date']!, _joiningDateMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Employee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employee(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id'])!,
      commissionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}commission_type'])!,
      commissionValue: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}commission_value'])!,
      minSalesTarget: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}min_sales_target'])!,
      isAgent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_agent'])!,
      joiningDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joining_date']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class Employee extends DataClass implements Insertable<Employee> {
  final String id;
  final String tenantId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String locationId;
  final String commissionType;
  final double commissionValue;
  final double minSalesTarget;
  final bool isAgent;
  final DateTime? joiningDate;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const Employee(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.email,
      this.phone,
      required this.role,
      required this.locationId,
      required this.commissionType,
      required this.commissionValue,
      required this.minSalesTarget,
      required this.isAgent,
      this.joiningDate,
      required this.synced,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['role'] = Variable<String>(role);
    map['location_id'] = Variable<String>(locationId);
    map['commission_type'] = Variable<String>(commissionType);
    map['commission_value'] = Variable<double>(commissionValue);
    map['min_sales_target'] = Variable<double>(minSalesTarget);
    map['is_agent'] = Variable<bool>(isAgent);
    if (!nullToAbsent || joiningDate != null) {
      map['joining_date'] = Variable<DateTime>(joiningDate);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      email: Value(email),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      role: Value(role),
      locationId: Value(locationId),
      commissionType: Value(commissionType),
      commissionValue: Value(commissionValue),
      minSalesTarget: Value(minSalesTarget),
      isAgent: Value(isAgent),
      joiningDate: joiningDate == null && nullToAbsent
          ? const Value.absent()
          : Value(joiningDate),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employee(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      locationId: serializer.fromJson<String>(json['locationId']),
      commissionType: serializer.fromJson<String>(json['commissionType']),
      commissionValue: serializer.fromJson<double>(json['commissionValue']),
      minSalesTarget: serializer.fromJson<double>(json['minSalesTarget']),
      isAgent: serializer.fromJson<bool>(json['isAgent']),
      joiningDate: serializer.fromJson<DateTime?>(json['joiningDate']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String?>(phone),
      'role': serializer.toJson<String>(role),
      'locationId': serializer.toJson<String>(locationId),
      'commissionType': serializer.toJson<String>(commissionType),
      'commissionValue': serializer.toJson<double>(commissionValue),
      'minSalesTarget': serializer.toJson<double>(minSalesTarget),
      'isAgent': serializer.toJson<bool>(isAgent),
      'joiningDate': serializer.toJson<DateTime?>(joiningDate),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Employee copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? email,
          Value<String?> phone = const Value.absent(),
          String? role,
          String? locationId,
          String? commissionType,
          double? commissionValue,
          double? minSalesTarget,
          bool? isAgent,
          Value<DateTime?> joiningDate = const Value.absent(),
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Employee(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone.present ? phone.value : this.phone,
        role: role ?? this.role,
        locationId: locationId ?? this.locationId,
        commissionType: commissionType ?? this.commissionType,
        commissionValue: commissionValue ?? this.commissionValue,
        minSalesTarget: minSalesTarget ?? this.minSalesTarget,
        isAgent: isAgent ?? this.isAgent,
        joiningDate: joiningDate.present ? joiningDate.value : this.joiningDate,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Employee copyWithCompanion(EmployeesCompanion data) {
    return Employee(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      role: data.role.present ? data.role.value : this.role,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      commissionType: data.commissionType.present
          ? data.commissionType.value
          : this.commissionType,
      commissionValue: data.commissionValue.present
          ? data.commissionValue.value
          : this.commissionValue,
      minSalesTarget: data.minSalesTarget.present
          ? data.minSalesTarget.value
          : this.minSalesTarget,
      isAgent: data.isAgent.present ? data.isAgent.value : this.isAgent,
      joiningDate:
          data.joiningDate.present ? data.joiningDate.value : this.joiningDate,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employee(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('locationId: $locationId, ')
          ..write('commissionType: $commissionType, ')
          ..write('commissionValue: $commissionValue, ')
          ..write('minSalesTarget: $minSalesTarget, ')
          ..write('isAgent: $isAgent, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      name,
      email,
      phone,
      role,
      locationId,
      commissionType,
      commissionValue,
      minSalesTarget,
      isAgent,
      joiningDate,
      synced,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.locationId == this.locationId &&
          other.commissionType == this.commissionType &&
          other.commissionValue == this.commissionValue &&
          other.minSalesTarget == this.minSalesTarget &&
          other.isAgent == this.isAgent &&
          other.joiningDate == this.joiningDate &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeesCompanion extends UpdateCompanion<Employee> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> phone;
  final Value<String> role;
  final Value<String> locationId;
  final Value<String> commissionType;
  final Value<double> commissionValue;
  final Value<double> minSalesTarget;
  final Value<bool> isAgent;
  final Value<DateTime?> joiningDate;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.locationId = const Value.absent(),
    this.commissionType = const Value.absent(),
    this.commissionValue = const Value.absent(),
    this.minSalesTarget = const Value.absent(),
    this.isAgent = const Value.absent(),
    this.joiningDate = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String email,
    this.phone = const Value.absent(),
    required String role,
    required String locationId,
    this.commissionType = const Value.absent(),
    this.commissionValue = const Value.absent(),
    this.minSalesTarget = const Value.absent(),
    this.isAgent = const Value.absent(),
    this.joiningDate = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        email = Value(email),
        role = Value(role),
        locationId = Value(locationId);
  static Insertable<Employee> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? locationId,
    Expression<String>? commissionType,
    Expression<double>? commissionValue,
    Expression<double>? minSalesTarget,
    Expression<bool>? isAgent,
    Expression<DateTime>? joiningDate,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (locationId != null) 'location_id': locationId,
      if (commissionType != null) 'commission_type': commissionType,
      if (commissionValue != null) 'commission_value': commissionValue,
      if (minSalesTarget != null) 'min_sales_target': minSalesTarget,
      if (isAgent != null) 'is_agent': isAgent,
      if (joiningDate != null) 'joining_date': joiningDate,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? email,
      Value<String?>? phone,
      Value<String>? role,
      Value<String>? locationId,
      Value<String>? commissionType,
      Value<double>? commissionValue,
      Value<double>? minSalesTarget,
      Value<bool>? isAgent,
      Value<DateTime?>? joiningDate,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return EmployeesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      locationId: locationId ?? this.locationId,
      commissionType: commissionType ?? this.commissionType,
      commissionValue: commissionValue ?? this.commissionValue,
      minSalesTarget: minSalesTarget ?? this.minSalesTarget,
      isAgent: isAgent ?? this.isAgent,
      joiningDate: joiningDate ?? this.joiningDate,
      synced: synced ?? this.synced,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (commissionType.present) {
      map['commission_type'] = Variable<String>(commissionType.value);
    }
    if (commissionValue.present) {
      map['commission_value'] = Variable<double>(commissionValue.value);
    }
    if (minSalesTarget.present) {
      map['min_sales_target'] = Variable<double>(minSalesTarget.value);
    }
    if (isAgent.present) {
      map['is_agent'] = Variable<bool>(isAgent.value);
    }
    if (joiningDate.present) {
      map['joining_date'] = Variable<DateTime>(joiningDate.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
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
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('locationId: $locationId, ')
          ..write('commissionType: $commissionType, ')
          ..write('commissionValue: $commissionValue, ')
          ..write('minSalesTarget: $minSalesTarget, ')
          ..write('isAgent: $isAgent, ')
          ..write('joiningDate: $joiningDate, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommissionRulesTable extends CommissionRules
    with TableInfo<$CommissionRulesTable, CommissionRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommissionRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ruleTypeMeta =
      const VerificationMeta('ruleType');
  @override
  late final GeneratedColumn<String> ruleType = GeneratedColumn<String>(
      'rule_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        name,
        ruleType,
        value,
        productId,
        category,
        employeeId,
        active,
        synced,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commission_rules';
  @override
  VerificationContext validateIntegrity(Insertable<CommissionRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rule_type')) {
      context.handle(_ruleTypeMeta,
          ruleType.isAcceptableOrUnknown(data['rule_type']!, _ruleTypeMeta));
    } else if (isInserting) {
      context.missing(_ruleTypeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommissionRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommissionRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ruleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rule_type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $CommissionRulesTable createAlias(String alias) {
    return $CommissionRulesTable(attachedDatabase, alias);
  }
}

class CommissionRule extends DataClass implements Insertable<CommissionRule> {
  final String id;
  final String tenantId;
  final String name;
  final String ruleType;
  final double value;
  final String? productId;
  final String? category;
  final String? employeeId;
  final bool active;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const CommissionRule(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.ruleType,
      required this.value,
      this.productId,
      this.category,
      this.employeeId,
      required this.active,
      required this.synced,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['rule_type'] = Variable<String>(ruleType);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<String>(employeeId);
    }
    map['active'] = Variable<bool>(active);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  CommissionRulesCompanion toCompanion(bool nullToAbsent) {
    return CommissionRulesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      ruleType: Value(ruleType),
      value: Value(value),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      active: Value(active),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CommissionRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommissionRule(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      ruleType: serializer.fromJson<String>(json['ruleType']),
      value: serializer.fromJson<double>(json['value']),
      productId: serializer.fromJson<String?>(json['productId']),
      category: serializer.fromJson<String?>(json['category']),
      employeeId: serializer.fromJson<String?>(json['employeeId']),
      active: serializer.fromJson<bool>(json['active']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'ruleType': serializer.toJson<String>(ruleType),
      'value': serializer.toJson<double>(value),
      'productId': serializer.toJson<String?>(productId),
      'category': serializer.toJson<String?>(category),
      'employeeId': serializer.toJson<String?>(employeeId),
      'active': serializer.toJson<bool>(active),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  CommissionRule copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? ruleType,
          double? value,
          Value<String?> productId = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> employeeId = const Value.absent(),
          bool? active,
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      CommissionRule(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        ruleType: ruleType ?? this.ruleType,
        value: value ?? this.value,
        productId: productId.present ? productId.value : this.productId,
        category: category.present ? category.value : this.category,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        active: active ?? this.active,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  CommissionRule copyWithCompanion(CommissionRulesCompanion data) {
    return CommissionRule(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      ruleType: data.ruleType.present ? data.ruleType.value : this.ruleType,
      value: data.value.present ? data.value.value : this.value,
      productId: data.productId.present ? data.productId.value : this.productId,
      category: data.category.present ? data.category.value : this.category,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      active: data.active.present ? data.active.value : this.active,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommissionRule(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('ruleType: $ruleType, ')
          ..write('value: $value, ')
          ..write('productId: $productId, ')
          ..write('category: $category, ')
          ..write('employeeId: $employeeId, ')
          ..write('active: $active, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, name, ruleType, value,
      productId, category, employeeId, active, synced, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommissionRule &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.ruleType == this.ruleType &&
          other.value == this.value &&
          other.productId == this.productId &&
          other.category == this.category &&
          other.employeeId == this.employeeId &&
          other.active == this.active &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CommissionRulesCompanion extends UpdateCompanion<CommissionRule> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> ruleType;
  final Value<double> value;
  final Value<String?> productId;
  final Value<String?> category;
  final Value<String?> employeeId;
  final Value<bool> active;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const CommissionRulesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.ruleType = const Value.absent(),
    this.value = const Value.absent(),
    this.productId = const Value.absent(),
    this.category = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.active = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommissionRulesCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String ruleType,
    this.value = const Value.absent(),
    this.productId = const Value.absent(),
    this.category = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.active = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        ruleType = Value(ruleType);
  static Insertable<CommissionRule> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? ruleType,
    Expression<double>? value,
    Expression<String>? productId,
    Expression<String>? category,
    Expression<String>? employeeId,
    Expression<bool>? active,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (ruleType != null) 'rule_type': ruleType,
      if (value != null) 'value': value,
      if (productId != null) 'product_id': productId,
      if (category != null) 'category': category,
      if (employeeId != null) 'employee_id': employeeId,
      if (active != null) 'active': active,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommissionRulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? ruleType,
      Value<double>? value,
      Value<String?>? productId,
      Value<String?>? category,
      Value<String?>? employeeId,
      Value<bool>? active,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return CommissionRulesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      ruleType: ruleType ?? this.ruleType,
      value: value ?? this.value,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      employeeId: employeeId ?? this.employeeId,
      active: active ?? this.active,
      synced: synced ?? this.synced,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ruleType.present) {
      map['rule_type'] = Variable<String>(ruleType.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
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
    return (StringBuffer('CommissionRulesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('ruleType: $ruleType, ')
          ..write('value: $value, ')
          ..write('productId: $productId, ')
          ..write('category: $category, ')
          ..write('employeeId: $employeeId, ')
          ..write('active: $active, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientOpIdMeta =
      const VerificationMeta('clientOpId');
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
      'client_op_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastRetryAtMeta =
      const VerificationMeta('lastRetryAt');
  @override
  late final GeneratedColumn<DateTime> lastRetryAt = GeneratedColumn<DateTime>(
      'last_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operation,
        entityTable,
        recordId,
        clientOpId,
        data,
        createdAt,
        retryCount,
        lastRetryAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('client_op_id')) {
      context.handle(
          _clientOpIdMeta,
          clientOpId.isAcceptableOrUnknown(
              data['client_op_id']!, _clientOpIdMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_retry_at')) {
      context.handle(
          _lastRetryAtMeta,
          lastRetryAt.isAcceptableOrUnknown(
              data['last_retry_at']!, _lastRetryAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      clientOpId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_op_id']),
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_retry_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String operation;
  final String entityTable;
  final String recordId;
  final String? clientOpId;
  final String data;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  const SyncQueueData(
      {required this.id,
      required this.operation,
      required this.entityTable,
      required this.recordId,
      this.clientOpId,
      required this.data,
      required this.createdAt,
      required this.retryCount,
      this.lastRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['entity_table'] = Variable<String>(entityTable);
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || clientOpId != null) {
      map['client_op_id'] = Variable<String>(clientOpId);
    }
    map['data'] = Variable<String>(data);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetryAt != null) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operation: Value(operation),
      entityTable: Value(entityTable),
      recordId: Value(recordId),
      clientOpId: clientOpId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientOpId),
      data: Value(data),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastRetryAt: lastRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetryAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      clientOpId: serializer.fromJson<String?>(json['clientOpId']),
      data: serializer.fromJson<String>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetryAt: serializer.fromJson<DateTime?>(json['lastRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'entityTable': serializer.toJson<String>(entityTable),
      'recordId': serializer.toJson<String>(recordId),
      'clientOpId': serializer.toJson<String?>(clientOpId),
      'data': serializer.toJson<String>(data),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetryAt': serializer.toJson<DateTime?>(lastRetryAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? operation,
          String? entityTable,
          String? recordId,
          Value<String?> clientOpId = const Value.absent(),
          String? data,
          DateTime? createdAt,
          int? retryCount,
          Value<DateTime?> lastRetryAt = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        entityTable: entityTable ?? this.entityTable,
        recordId: recordId ?? this.recordId,
        clientOpId: clientOpId.present ? clientOpId.value : this.clientOpId,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastRetryAt: lastRetryAt.present ? lastRetryAt.value : this.lastRetryAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      clientOpId:
          data.clientOpId.present ? data.clientOpId.value : this.clientOpId,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastRetryAt:
          data.lastRetryAt.present ? data.lastRetryAt.value : this.lastRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operation, entityTable, recordId,
      clientOpId, data, createdAt, retryCount, lastRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.entityTable == this.entityTable &&
          other.recordId == this.recordId &&
          other.clientOpId == this.clientOpId &&
          other.data == this.data &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastRetryAt == this.lastRetryAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> entityTable;
  final Value<String> recordId;
  final Value<String?> clientOpId;
  final Value<String> data;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetryAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String entityTable,
    required String recordId,
    this.clientOpId = const Value.absent(),
    required String data,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastRetryAt = const Value.absent(),
  })  : operation = Value(operation),
        entityTable = Value(entityTable),
        recordId = Value(recordId),
        data = Value(data),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? entityTable,
    Expression<String>? recordId,
    Expression<String>? clientOpId,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (entityTable != null) 'entity_table': entityTable,
      if (recordId != null) 'record_id': recordId,
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetryAt != null) 'last_retry_at': lastRetryAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? operation,
      Value<String>? entityTable,
      Value<String>? recordId,
      Value<String?>? clientOpId,
      Value<String>? data,
      Value<DateTime>? createdAt,
      Value<int>? retryCount,
      Value<DateTime?>? lastRetryAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityTable: entityTable ?? this.entityTable,
      recordId: recordId ?? this.recordId,
      clientOpId: clientOpId ?? this.clientOpId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetryAt.present) {
      map['last_retry_at'] = Variable<DateTime>(lastRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetryAt: $lastRetryAt')
          ..write(')'))
        .toString();
  }
}

class $SyncJournalTable extends SyncJournal
    with TableInfo<$SyncJournalTable, SyncJournalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJournalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientOpIdMeta =
      const VerificationMeta('clientOpId');
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
      'client_op_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverSeqMeta =
      const VerificationMeta('serverSeq');
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
      'server_seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorReasonMeta =
      const VerificationMeta('errorReason');
  @override
  late final GeneratedColumn<String> errorReason = GeneratedColumn<String>(
      'error_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceDeviceIdMeta =
      const VerificationMeta('sourceDeviceId');
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
      'source_device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceUserIdMeta =
      const VerificationMeta('sourceUserId');
  @override
  late final GeneratedColumn<String> sourceUserId = GeneratedColumn<String>(
      'source_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
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
        clientOpId,
        serverSeq,
        direction,
        status,
        operation,
        entityTable,
        recordId,
        payload,
        errorReason,
        sourceDeviceId,
        sourceUserId,
        retryCount,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_journal';
  @override
  VerificationContext validateIntegrity(Insertable<SyncJournalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_op_id')) {
      context.handle(
          _clientOpIdMeta,
          clientOpId.isAcceptableOrUnknown(
              data['client_op_id']!, _clientOpIdMeta));
    }
    if (data.containsKey('server_seq')) {
      context.handle(_serverSeqMeta,
          serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta));
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('error_reason')) {
      context.handle(
          _errorReasonMeta,
          errorReason.isAcceptableOrUnknown(
              data['error_reason']!, _errorReasonMeta));
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
          _sourceDeviceIdMeta,
          sourceDeviceId.isAcceptableOrUnknown(
              data['source_device_id']!, _sourceDeviceIdMeta));
    }
    if (data.containsKey('source_user_id')) {
      context.handle(
          _sourceUserIdMeta,
          sourceUserId.isAcceptableOrUnknown(
              data['source_user_id']!, _sourceUserIdMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
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
  SyncJournalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJournalData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientOpId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_op_id']),
      serverSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_seq']),
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload']),
      errorReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_reason']),
      sourceDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_device_id']),
      sourceUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_user_id']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncJournalTable createAlias(String alias) {
    return $SyncJournalTable(attachedDatabase, alias);
  }
}

class SyncJournalData extends DataClass implements Insertable<SyncJournalData> {
  final int id;
  final String? clientOpId;
  final int? serverSeq;
  final String direction;
  final String status;
  final String operation;
  final String entityTable;
  final String recordId;
  final String? payload;
  final String? errorReason;
  final String? sourceDeviceId;
  final String? sourceUserId;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncJournalData(
      {required this.id,
      this.clientOpId,
      this.serverSeq,
      required this.direction,
      required this.status,
      required this.operation,
      required this.entityTable,
      required this.recordId,
      this.payload,
      this.errorReason,
      this.sourceDeviceId,
      this.sourceUserId,
      required this.retryCount,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientOpId != null) {
      map['client_op_id'] = Variable<String>(clientOpId);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['direction'] = Variable<String>(direction);
    map['status'] = Variable<String>(status);
    map['operation'] = Variable<String>(operation);
    map['entity_table'] = Variable<String>(entityTable);
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || errorReason != null) {
      map['error_reason'] = Variable<String>(errorReason);
    }
    if (!nullToAbsent || sourceDeviceId != null) {
      map['source_device_id'] = Variable<String>(sourceDeviceId);
    }
    if (!nullToAbsent || sourceUserId != null) {
      map['source_user_id'] = Variable<String>(sourceUserId);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncJournalCompanion toCompanion(bool nullToAbsent) {
    return SyncJournalCompanion(
      id: Value(id),
      clientOpId: clientOpId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientOpId),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      direction: Value(direction),
      status: Value(status),
      operation: Value(operation),
      entityTable: Value(entityTable),
      recordId: Value(recordId),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      errorReason: errorReason == null && nullToAbsent
          ? const Value.absent()
          : Value(errorReason),
      sourceDeviceId: sourceDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDeviceId),
      sourceUserId: sourceUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUserId),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncJournalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJournalData(
      id: serializer.fromJson<int>(json['id']),
      clientOpId: serializer.fromJson<String?>(json['clientOpId']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
      direction: serializer.fromJson<String>(json['direction']),
      status: serializer.fromJson<String>(json['status']),
      operation: serializer.fromJson<String>(json['operation']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      payload: serializer.fromJson<String?>(json['payload']),
      errorReason: serializer.fromJson<String?>(json['errorReason']),
      sourceDeviceId: serializer.fromJson<String?>(json['sourceDeviceId']),
      sourceUserId: serializer.fromJson<String?>(json['sourceUserId']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientOpId': serializer.toJson<String?>(clientOpId),
      'serverSeq': serializer.toJson<int?>(serverSeq),
      'direction': serializer.toJson<String>(direction),
      'status': serializer.toJson<String>(status),
      'operation': serializer.toJson<String>(operation),
      'entityTable': serializer.toJson<String>(entityTable),
      'recordId': serializer.toJson<String>(recordId),
      'payload': serializer.toJson<String?>(payload),
      'errorReason': serializer.toJson<String?>(errorReason),
      'sourceDeviceId': serializer.toJson<String?>(sourceDeviceId),
      'sourceUserId': serializer.toJson<String?>(sourceUserId),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncJournalData copyWith(
          {int? id,
          Value<String?> clientOpId = const Value.absent(),
          Value<int?> serverSeq = const Value.absent(),
          String? direction,
          String? status,
          String? operation,
          String? entityTable,
          String? recordId,
          Value<String?> payload = const Value.absent(),
          Value<String?> errorReason = const Value.absent(),
          Value<String?> sourceDeviceId = const Value.absent(),
          Value<String?> sourceUserId = const Value.absent(),
          int? retryCount,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncJournalData(
        id: id ?? this.id,
        clientOpId: clientOpId.present ? clientOpId.value : this.clientOpId,
        serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
        direction: direction ?? this.direction,
        status: status ?? this.status,
        operation: operation ?? this.operation,
        entityTable: entityTable ?? this.entityTable,
        recordId: recordId ?? this.recordId,
        payload: payload.present ? payload.value : this.payload,
        errorReason: errorReason.present ? errorReason.value : this.errorReason,
        sourceDeviceId:
            sourceDeviceId.present ? sourceDeviceId.value : this.sourceDeviceId,
        sourceUserId:
            sourceUserId.present ? sourceUserId.value : this.sourceUserId,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncJournalData copyWithCompanion(SyncJournalCompanion data) {
    return SyncJournalData(
      id: data.id.present ? data.id.value : this.id,
      clientOpId:
          data.clientOpId.present ? data.clientOpId.value : this.clientOpId,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      payload: data.payload.present ? data.payload.value : this.payload,
      errorReason:
          data.errorReason.present ? data.errorReason.value : this.errorReason,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      sourceUserId: data.sourceUserId.present
          ? data.sourceUserId.value
          : this.sourceUserId,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJournalData(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('operation: $operation, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('errorReason: $errorReason, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('sourceUserId: $sourceUserId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientOpId,
      serverSeq,
      direction,
      status,
      operation,
      entityTable,
      recordId,
      payload,
      errorReason,
      sourceDeviceId,
      sourceUserId,
      retryCount,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJournalData &&
          other.id == this.id &&
          other.clientOpId == this.clientOpId &&
          other.serverSeq == this.serverSeq &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.operation == this.operation &&
          other.entityTable == this.entityTable &&
          other.recordId == this.recordId &&
          other.payload == this.payload &&
          other.errorReason == this.errorReason &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.sourceUserId == this.sourceUserId &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncJournalCompanion extends UpdateCompanion<SyncJournalData> {
  final Value<int> id;
  final Value<String?> clientOpId;
  final Value<int?> serverSeq;
  final Value<String> direction;
  final Value<String> status;
  final Value<String> operation;
  final Value<String> entityTable;
  final Value<String> recordId;
  final Value<String?> payload;
  final Value<String?> errorReason;
  final Value<String?> sourceDeviceId;
  final Value<String?> sourceUserId;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncJournalCompanion({
    this.id = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.payload = const Value.absent(),
    this.errorReason = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.sourceUserId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncJournalCompanion.insert({
    this.id = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.serverSeq = const Value.absent(),
    required String direction,
    required String status,
    required String operation,
    required String entityTable,
    required String recordId,
    this.payload = const Value.absent(),
    this.errorReason = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.sourceUserId = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : direction = Value(direction),
        status = Value(status),
        operation = Value(operation),
        entityTable = Value(entityTable),
        recordId = Value(recordId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncJournalData> custom({
    Expression<int>? id,
    Expression<String>? clientOpId,
    Expression<int>? serverSeq,
    Expression<String>? direction,
    Expression<String>? status,
    Expression<String>? operation,
    Expression<String>? entityTable,
    Expression<String>? recordId,
    Expression<String>? payload,
    Expression<String>? errorReason,
    Expression<String>? sourceDeviceId,
    Expression<String>? sourceUserId,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (operation != null) 'operation': operation,
      if (entityTable != null) 'entity_table': entityTable,
      if (recordId != null) 'record_id': recordId,
      if (payload != null) 'payload': payload,
      if (errorReason != null) 'error_reason': errorReason,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (sourceUserId != null) 'source_user_id': sourceUserId,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncJournalCompanion copyWith(
      {Value<int>? id,
      Value<String?>? clientOpId,
      Value<int?>? serverSeq,
      Value<String>? direction,
      Value<String>? status,
      Value<String>? operation,
      Value<String>? entityTable,
      Value<String>? recordId,
      Value<String?>? payload,
      Value<String?>? errorReason,
      Value<String?>? sourceDeviceId,
      Value<String?>? sourceUserId,
      Value<int>? retryCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SyncJournalCompanion(
      id: id ?? this.id,
      clientOpId: clientOpId ?? this.clientOpId,
      serverSeq: serverSeq ?? this.serverSeq,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      operation: operation ?? this.operation,
      entityTable: entityTable ?? this.entityTable,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
      errorReason: errorReason ?? this.errorReason,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceUserId: sourceUserId ?? this.sourceUserId,
      retryCount: retryCount ?? this.retryCount,
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
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (errorReason.present) {
      map['error_reason'] = Variable<String>(errorReason.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (sourceUserId.present) {
      map['source_user_id'] = Variable<String>(sourceUserId.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
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
    return (StringBuffer('SyncJournalCompanion(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('operation: $operation, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('payload: $payload, ')
          ..write('errorReason: $errorReason, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('sourceUserId: $sourceUserId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CommissionLogsTable extends CommissionLogs
    with TableInfo<$CommissionLogsTable, CommissionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommissionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
      'sale_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _saleAmountMeta =
      const VerificationMeta('saleAmount');
  @override
  late final GeneratedColumn<double> saleAmount = GeneratedColumn<double>(
      'sale_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _commissionAmountMeta =
      const VerificationMeta('commissionAmount');
  @override
  late final GeneratedColumn<double> commissionAmount = GeneratedColumn<double>(
      'commission_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _commissionTypeMeta =
      const VerificationMeta('commissionType');
  @override
  late final GeneratedColumn<String> commissionType = GeneratedColumn<String>(
      'commission_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
      'is_paid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paid" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        saleId,
        employeeId,
        productId,
        saleAmount,
        commissionAmount,
        commissionType,
        isPaid,
        paidAt,
        synced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commission_logs';
  @override
  VerificationContext validateIntegrity(Insertable<CommissionLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('sale_amount')) {
      context.handle(
          _saleAmountMeta,
          saleAmount.isAcceptableOrUnknown(
              data['sale_amount']!, _saleAmountMeta));
    }
    if (data.containsKey('commission_amount')) {
      context.handle(
          _commissionAmountMeta,
          commissionAmount.isAcceptableOrUnknown(
              data['commission_amount']!, _commissionAmountMeta));
    } else if (isInserting) {
      context.missing(_commissionAmountMeta);
    }
    if (data.containsKey('commission_type')) {
      context.handle(
          _commissionTypeMeta,
          commissionType.isAcceptableOrUnknown(
              data['commission_type']!, _commissionTypeMeta));
    } else if (isInserting) {
      context.missing(_commissionTypeMeta);
    }
    if (data.containsKey('is_paid')) {
      context.handle(_isPaidMeta,
          isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommissionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommissionLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      saleAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sale_amount'])!,
      commissionAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}commission_amount'])!,
      commissionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}commission_type'])!,
      isPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paid'])!,
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $CommissionLogsTable createAlias(String alias) {
    return $CommissionLogsTable(attachedDatabase, alias);
  }
}

class CommissionLog extends DataClass implements Insertable<CommissionLog> {
  final String id;
  final String tenantId;
  final String saleId;
  final String employeeId;
  final String? productId;
  final double saleAmount;
  final double commissionAmount;
  final String commissionType;
  final bool isPaid;
  final DateTime? paidAt;
  final bool synced;
  final DateTime? createdAt;
  const CommissionLog(
      {required this.id,
      required this.tenantId,
      required this.saleId,
      required this.employeeId,
      this.productId,
      required this.saleAmount,
      required this.commissionAmount,
      required this.commissionType,
      required this.isPaid,
      this.paidAt,
      required this.synced,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['sale_id'] = Variable<String>(saleId);
    map['employee_id'] = Variable<String>(employeeId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['sale_amount'] = Variable<double>(saleAmount);
    map['commission_amount'] = Variable<double>(commissionAmount);
    map['commission_type'] = Variable<String>(commissionType);
    map['is_paid'] = Variable<bool>(isPaid);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  CommissionLogsCompanion toCompanion(bool nullToAbsent) {
    return CommissionLogsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      saleId: Value(saleId),
      employeeId: Value(employeeId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      saleAmount: Value(saleAmount),
      commissionAmount: Value(commissionAmount),
      commissionType: Value(commissionType),
      isPaid: Value(isPaid),
      paidAt:
          paidAt == null && nullToAbsent ? const Value.absent() : Value(paidAt),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory CommissionLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommissionLog(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      productId: serializer.fromJson<String?>(json['productId']),
      saleAmount: serializer.fromJson<double>(json['saleAmount']),
      commissionAmount: serializer.fromJson<double>(json['commissionAmount']),
      commissionType: serializer.fromJson<String>(json['commissionType']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'saleId': serializer.toJson<String>(saleId),
      'employeeId': serializer.toJson<String>(employeeId),
      'productId': serializer.toJson<String?>(productId),
      'saleAmount': serializer.toJson<double>(saleAmount),
      'commissionAmount': serializer.toJson<double>(commissionAmount),
      'commissionType': serializer.toJson<String>(commissionType),
      'isPaid': serializer.toJson<bool>(isPaid),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  CommissionLog copyWith(
          {String? id,
          String? tenantId,
          String? saleId,
          String? employeeId,
          Value<String?> productId = const Value.absent(),
          double? saleAmount,
          double? commissionAmount,
          String? commissionType,
          bool? isPaid,
          Value<DateTime?> paidAt = const Value.absent(),
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      CommissionLog(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        saleId: saleId ?? this.saleId,
        employeeId: employeeId ?? this.employeeId,
        productId: productId.present ? productId.value : this.productId,
        saleAmount: saleAmount ?? this.saleAmount,
        commissionAmount: commissionAmount ?? this.commissionAmount,
        commissionType: commissionType ?? this.commissionType,
        isPaid: isPaid ?? this.isPaid,
        paidAt: paidAt.present ? paidAt.value : this.paidAt,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  CommissionLog copyWithCompanion(CommissionLogsCompanion data) {
    return CommissionLog(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      saleAmount:
          data.saleAmount.present ? data.saleAmount.value : this.saleAmount,
      commissionAmount: data.commissionAmount.present
          ? data.commissionAmount.value
          : this.commissionAmount,
      commissionType: data.commissionType.present
          ? data.commissionType.value
          : this.commissionType,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommissionLog(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('saleId: $saleId, ')
          ..write('employeeId: $employeeId, ')
          ..write('productId: $productId, ')
          ..write('saleAmount: $saleAmount, ')
          ..write('commissionAmount: $commissionAmount, ')
          ..write('commissionType: $commissionType, ')
          ..write('isPaid: $isPaid, ')
          ..write('paidAt: $paidAt, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      saleId,
      employeeId,
      productId,
      saleAmount,
      commissionAmount,
      commissionType,
      isPaid,
      paidAt,
      synced,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommissionLog &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.saleId == this.saleId &&
          other.employeeId == this.employeeId &&
          other.productId == this.productId &&
          other.saleAmount == this.saleAmount &&
          other.commissionAmount == this.commissionAmount &&
          other.commissionType == this.commissionType &&
          other.isPaid == this.isPaid &&
          other.paidAt == this.paidAt &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt);
}

class CommissionLogsCompanion extends UpdateCompanion<CommissionLog> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> saleId;
  final Value<String> employeeId;
  final Value<String?> productId;
  final Value<double> saleAmount;
  final Value<double> commissionAmount;
  final Value<String> commissionType;
  final Value<bool> isPaid;
  final Value<DateTime?> paidAt;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const CommissionLogsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.saleAmount = const Value.absent(),
    this.commissionAmount = const Value.absent(),
    this.commissionType = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommissionLogsCompanion.insert({
    required String id,
    required String tenantId,
    required String saleId,
    required String employeeId,
    this.productId = const Value.absent(),
    this.saleAmount = const Value.absent(),
    required double commissionAmount,
    required String commissionType,
    this.isPaid = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        saleId = Value(saleId),
        employeeId = Value(employeeId),
        commissionAmount = Value(commissionAmount),
        commissionType = Value(commissionType);
  static Insertable<CommissionLog> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? saleId,
    Expression<String>? employeeId,
    Expression<String>? productId,
    Expression<double>? saleAmount,
    Expression<double>? commissionAmount,
    Expression<String>? commissionType,
    Expression<bool>? isPaid,
    Expression<DateTime>? paidAt,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (saleId != null) 'sale_id': saleId,
      if (employeeId != null) 'employee_id': employeeId,
      if (productId != null) 'product_id': productId,
      if (saleAmount != null) 'sale_amount': saleAmount,
      if (commissionAmount != null) 'commission_amount': commissionAmount,
      if (commissionType != null) 'commission_type': commissionType,
      if (isPaid != null) 'is_paid': isPaid,
      if (paidAt != null) 'paid_at': paidAt,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommissionLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? saleId,
      Value<String>? employeeId,
      Value<String?>? productId,
      Value<double>? saleAmount,
      Value<double>? commissionAmount,
      Value<String>? commissionType,
      Value<bool>? isPaid,
      Value<DateTime?>? paidAt,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return CommissionLogsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      saleId: saleId ?? this.saleId,
      employeeId: employeeId ?? this.employeeId,
      productId: productId ?? this.productId,
      saleAmount: saleAmount ?? this.saleAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      commissionType: commissionType ?? this.commissionType,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
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
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (saleAmount.present) {
      map['sale_amount'] = Variable<double>(saleAmount.value);
    }
    if (commissionAmount.present) {
      map['commission_amount'] = Variable<double>(commissionAmount.value);
    }
    if (commissionType.present) {
      map['commission_type'] = Variable<String>(commissionType.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommissionLogsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('saleId: $saleId, ')
          ..write('employeeId: $employeeId, ')
          ..write('productId: $productId, ')
          ..write('saleAmount: $saleAmount, ')
          ..write('commissionAmount: $commissionAmount, ')
          ..write('commissionType: $commissionType, ')
          ..write('isPaid: $isPaid, ')
          ..write('paidAt: $paidAt, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _expenseDateMeta =
      const VerificationMeta('expenseDate');
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
      'expense_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        category,
        description,
        amount,
        employeeId,
        locationId,
        receiptUrl,
        notes,
        synced,
        expenseDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('expense_date')) {
      context.handle(
          _expenseDateMeta,
          expenseDate.isAcceptableOrUnknown(
              data['expense_date']!, _expenseDateMeta));
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id']),
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id']),
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      expenseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expense_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String tenantId;
  final String category;
  final String description;
  final double amount;
  final String? employeeId;
  final String? locationId;
  final String? receiptUrl;
  final String? notes;
  final bool synced;
  final DateTime expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const Expense(
      {required this.id,
      required this.tenantId,
      required this.category,
      required this.description,
      required this.amount,
      this.employeeId,
      this.locationId,
      this.receiptUrl,
      this.notes,
      required this.synced,
      required this.expenseDate,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<String>(employeeId);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['synced'] = Variable<bool>(synced);
    map['expense_date'] = Variable<DateTime>(expenseDate);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      category: Value(category),
      description: Value(description),
      amount: Value(amount),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      synced: Value(synced),
      expenseDate: Value(expenseDate),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      employeeId: serializer.fromJson<String?>(json['employeeId']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      synced: serializer.fromJson<bool>(json['synced']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'employeeId': serializer.toJson<String?>(employeeId),
      'locationId': serializer.toJson<String?>(locationId),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'notes': serializer.toJson<String?>(notes),
      'synced': serializer.toJson<bool>(synced),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Expense copyWith(
          {String? id,
          String? tenantId,
          String? category,
          String? description,
          double? amount,
          Value<String?> employeeId = const Value.absent(),
          Value<String?> locationId = const Value.absent(),
          Value<String?> receiptUrl = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? synced,
          DateTime? expenseDate,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Expense(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        locationId: locationId.present ? locationId.value : this.locationId,
        receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
        notes: notes.present ? notes.value : this.notes,
        synced: synced ?? this.synced,
        expenseDate: expenseDate ?? this.expenseDate,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      category: data.category.present ? data.category.value : this.category,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      synced: data.synced.present ? data.synced.value : this.synced,
      expenseDate:
          data.expenseDate.present ? data.expenseDate.value : this.expenseDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('employeeId: $employeeId, ')
          ..write('locationId: $locationId, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      category,
      description,
      amount,
      employeeId,
      locationId,
      receiptUrl,
      notes,
      synced,
      expenseDate,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.category == this.category &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.employeeId == this.employeeId &&
          other.locationId == this.locationId &&
          other.receiptUrl == this.receiptUrl &&
          other.notes == this.notes &&
          other.synced == this.synced &&
          other.expenseDate == this.expenseDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> category;
  final Value<String> description;
  final Value<double> amount;
  final Value<String?> employeeId;
  final Value<String?> locationId;
  final Value<String?> receiptUrl;
  final Value<String?> notes;
  final Value<bool> synced;
  final Value<DateTime> expenseDate;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String tenantId,
    required String category,
    this.description = const Value.absent(),
    required double amount,
    this.employeeId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    required DateTime expenseDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        category = Value(category),
        amount = Value(amount),
        expenseDate = Value(expenseDate);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? category,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? employeeId,
    Expression<String>? locationId,
    Expression<String>? receiptUrl,
    Expression<String>? notes,
    Expression<bool>? synced,
    Expression<DateTime>? expenseDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (employeeId != null) 'employee_id': employeeId,
      if (locationId != null) 'location_id': locationId,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (notes != null) 'notes': notes,
      if (synced != null) 'synced': synced,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? category,
      Value<String>? description,
      Value<double>? amount,
      Value<String?>? employeeId,
      Value<String?>? locationId,
      Value<String?>? receiptUrl,
      Value<String?>? notes,
      Value<bool>? synced,
      Value<DateTime>? expenseDate,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      employeeId: employeeId ?? this.employeeId,
      locationId: locationId ?? this.locationId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      expenseDate: expenseDate ?? this.expenseDate,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
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
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('employeeId: $employeeId, ')
          ..write('locationId: $locationId, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiscountsTable extends Discounts
    with TableInfo<$DiscountsTable, Discount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountModeMeta =
      const VerificationMeta('discountMode');
  @override
  late final GeneratedColumn<String> discountMode = GeneratedColumn<String>(
      'discount_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerTypeMeta =
      const VerificationMeta('customerType');
  @override
  late final GeneratedColumn<String> customerType = GeneratedColumn<String>(
      'customer_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conditionsMeta =
      const VerificationMeta('conditions');
  @override
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
      'conditions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        name,
        type,
        discountMode,
        value,
        productId,
        category,
        customerType,
        conditions,
        isActive,
        expiresAt,
        synced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discounts';
  @override
  VerificationContext validateIntegrity(Insertable<Discount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('discount_mode')) {
      context.handle(
          _discountModeMeta,
          discountMode.isAcceptableOrUnknown(
              data['discount_mode']!, _discountModeMeta));
    } else if (isInserting) {
      context.missing(_discountModeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('customer_type')) {
      context.handle(
          _customerTypeMeta,
          customerType.isAcceptableOrUnknown(
              data['customer_type']!, _customerTypeMeta));
    }
    if (data.containsKey('conditions')) {
      context.handle(
          _conditionsMeta,
          conditions.isAcceptableOrUnknown(
              data['conditions']!, _conditionsMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Discount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Discount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      discountMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_mode'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      customerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_type']),
      conditions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conditions']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $DiscountsTable createAlias(String alias) {
    return $DiscountsTable(attachedDatabase, alias);
  }
}

class Discount extends DataClass implements Insertable<Discount> {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final String discountMode;
  final double value;
  final String? productId;
  final String? category;
  final String? customerType;
  final String? conditions;
  final bool isActive;
  final DateTime? expiresAt;
  final bool synced;
  final DateTime? createdAt;
  const Discount(
      {required this.id,
      required this.tenantId,
      required this.name,
      required this.type,
      required this.discountMode,
      required this.value,
      this.productId,
      this.category,
      this.customerType,
      this.conditions,
      required this.isActive,
      this.expiresAt,
      required this.synced,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['discount_mode'] = Variable<String>(discountMode);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || customerType != null) {
      map['customer_type'] = Variable<String>(customerType);
    }
    if (!nullToAbsent || conditions != null) {
      map['conditions'] = Variable<String>(conditions);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  DiscountsCompanion toCompanion(bool nullToAbsent) {
    return DiscountsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      type: Value(type),
      discountMode: Value(discountMode),
      value: Value(value),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      customerType: customerType == null && nullToAbsent
          ? const Value.absent()
          : Value(customerType),
      conditions: conditions == null && nullToAbsent
          ? const Value.absent()
          : Value(conditions),
      isActive: Value(isActive),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      synced: Value(synced),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Discount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Discount(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      discountMode: serializer.fromJson<String>(json['discountMode']),
      value: serializer.fromJson<double>(json['value']),
      productId: serializer.fromJson<String?>(json['productId']),
      category: serializer.fromJson<String?>(json['category']),
      customerType: serializer.fromJson<String?>(json['customerType']),
      conditions: serializer.fromJson<String?>(json['conditions']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'discountMode': serializer.toJson<String>(discountMode),
      'value': serializer.toJson<double>(value),
      'productId': serializer.toJson<String?>(productId),
      'category': serializer.toJson<String?>(category),
      'customerType': serializer.toJson<String?>(customerType),
      'conditions': serializer.toJson<String?>(conditions),
      'isActive': serializer.toJson<bool>(isActive),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Discount copyWith(
          {String? id,
          String? tenantId,
          String? name,
          String? type,
          String? discountMode,
          double? value,
          Value<String?> productId = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> customerType = const Value.absent(),
          Value<String?> conditions = const Value.absent(),
          bool? isActive,
          Value<DateTime?> expiresAt = const Value.absent(),
          bool? synced,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      Discount(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        type: type ?? this.type,
        discountMode: discountMode ?? this.discountMode,
        value: value ?? this.value,
        productId: productId.present ? productId.value : this.productId,
        category: category.present ? category.value : this.category,
        customerType:
            customerType.present ? customerType.value : this.customerType,
        conditions: conditions.present ? conditions.value : this.conditions,
        isActive: isActive ?? this.isActive,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        synced: synced ?? this.synced,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  Discount copyWithCompanion(DiscountsCompanion data) {
    return Discount(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      discountMode: data.discountMode.present
          ? data.discountMode.value
          : this.discountMode,
      value: data.value.present ? data.value.value : this.value,
      productId: data.productId.present ? data.productId.value : this.productId,
      category: data.category.present ? data.category.value : this.category,
      customerType: data.customerType.present
          ? data.customerType.value
          : this.customerType,
      conditions:
          data.conditions.present ? data.conditions.value : this.conditions,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Discount(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('discountMode: $discountMode, ')
          ..write('value: $value, ')
          ..write('productId: $productId, ')
          ..write('category: $category, ')
          ..write('customerType: $customerType, ')
          ..write('conditions: $conditions, ')
          ..write('isActive: $isActive, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tenantId,
      name,
      type,
      discountMode,
      value,
      productId,
      category,
      customerType,
      conditions,
      isActive,
      expiresAt,
      synced,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Discount &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.type == this.type &&
          other.discountMode == this.discountMode &&
          other.value == this.value &&
          other.productId == this.productId &&
          other.category == this.category &&
          other.customerType == this.customerType &&
          other.conditions == this.conditions &&
          other.isActive == this.isActive &&
          other.expiresAt == this.expiresAt &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt);
}

class DiscountsCompanion extends UpdateCompanion<Discount> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> discountMode;
  final Value<double> value;
  final Value<String?> productId;
  final Value<String?> category;
  final Value<String?> customerType;
  final Value<String?> conditions;
  final Value<bool> isActive;
  final Value<DateTime?> expiresAt;
  final Value<bool> synced;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const DiscountsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.discountMode = const Value.absent(),
    this.value = const Value.absent(),
    this.productId = const Value.absent(),
    this.category = const Value.absent(),
    this.customerType = const Value.absent(),
    this.conditions = const Value.absent(),
    this.isActive = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscountsCompanion.insert({
    required String id,
    required String tenantId,
    required String name,
    required String type,
    required String discountMode,
    required double value,
    this.productId = const Value.absent(),
    this.category = const Value.absent(),
    this.customerType = const Value.absent(),
    this.conditions = const Value.absent(),
    this.isActive = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        name = Value(name),
        type = Value(type),
        discountMode = Value(discountMode),
        value = Value(value);
  static Insertable<Discount> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? discountMode,
    Expression<double>? value,
    Expression<String>? productId,
    Expression<String>? category,
    Expression<String>? customerType,
    Expression<String>? conditions,
    Expression<bool>? isActive,
    Expression<DateTime>? expiresAt,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (discountMode != null) 'discount_mode': discountMode,
      if (value != null) 'value': value,
      if (productId != null) 'product_id': productId,
      if (category != null) 'category': category,
      if (customerType != null) 'customer_type': customerType,
      if (conditions != null) 'conditions': conditions,
      if (isActive != null) 'is_active': isActive,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? type,
      Value<String>? discountMode,
      Value<double>? value,
      Value<String?>? productId,
      Value<String?>? category,
      Value<String?>? customerType,
      Value<String?>? conditions,
      Value<bool>? isActive,
      Value<DateTime?>? expiresAt,
      Value<bool>? synced,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return DiscountsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      type: type ?? this.type,
      discountMode: discountMode ?? this.discountMode,
      value: value ?? this.value,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      customerType: customerType ?? this.customerType,
      conditions: conditions ?? this.conditions,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (discountMode.present) {
      map['discount_mode'] = Variable<String>(discountMode.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (customerType.present) {
      map['customer_type'] = Variable<String>(customerType.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscountsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('discountMode: $discountMode, ')
          ..write('value: $value, ')
          ..write('productId: $productId, ')
          ..write('category: $category, ')
          ..write('customerType: $customerType, ')
          ..write('conditions: $conditions, ')
          ..write('isActive: $isActive, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoyaltyLedgerTable extends LoyaltyLedger
    with TableInfo<$LoyaltyLedgerTable, LoyaltyLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoyaltyLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
      'sale_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<double> points = GeneratedColumn<double>(
      'points', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tenantId, customerId, saleId, points, type, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loyalty_ledger';
  @override
  VerificationContext validateIntegrity(Insertable<LoyaltyLedgerData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(_saleIdMeta,
          saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta));
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoyaltyLedgerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoyaltyLedgerData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      saleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_id']),
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}points'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $LoyaltyLedgerTable createAlias(String alias) {
    return $LoyaltyLedgerTable(attachedDatabase, alias);
  }
}

class LoyaltyLedgerData extends DataClass
    implements Insertable<LoyaltyLedgerData> {
  final String id;
  final String tenantId;
  final String customerId;
  final String? saleId;
  final double points;
  final String type;
  final String? notes;
  final DateTime? createdAt;
  const LoyaltyLedgerData(
      {required this.id,
      required this.tenantId,
      required this.customerId,
      this.saleId,
      required this.points,
      required this.type,
      this.notes,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    map['points'] = Variable<double>(points);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  LoyaltyLedgerCompanion toCompanion(bool nullToAbsent) {
    return LoyaltyLedgerCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      customerId: Value(customerId),
      saleId:
          saleId == null && nullToAbsent ? const Value.absent() : Value(saleId),
      points: Value(points),
      type: Value(type),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LoyaltyLedgerData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoyaltyLedgerData(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      points: serializer.fromJson<double>(json['points']),
      type: serializer.fromJson<String>(json['type']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'customerId': serializer.toJson<String>(customerId),
      'saleId': serializer.toJson<String?>(saleId),
      'points': serializer.toJson<double>(points),
      'type': serializer.toJson<String>(type),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  LoyaltyLedgerData copyWith(
          {String? id,
          String? tenantId,
          String? customerId,
          Value<String?> saleId = const Value.absent(),
          double? points,
          String? type,
          Value<String?> notes = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      LoyaltyLedgerData(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        customerId: customerId ?? this.customerId,
        saleId: saleId.present ? saleId.value : this.saleId,
        points: points ?? this.points,
        type: type ?? this.type,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  LoyaltyLedgerData copyWithCompanion(LoyaltyLedgerCompanion data) {
    return LoyaltyLedgerData(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      points: data.points.present ? data.points.value : this.points,
      type: data.type.present ? data.type.value : this.type,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoyaltyLedgerData(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('saleId: $saleId, ')
          ..write('points: $points, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, tenantId, customerId, saleId, points, type, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoyaltyLedgerData &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.customerId == this.customerId &&
          other.saleId == this.saleId &&
          other.points == this.points &&
          other.type == this.type &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class LoyaltyLedgerCompanion extends UpdateCompanion<LoyaltyLedgerData> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> customerId;
  final Value<String?> saleId;
  final Value<double> points;
  final Value<String> type;
  final Value<String?> notes;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const LoyaltyLedgerCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.points = const Value.absent(),
    this.type = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoyaltyLedgerCompanion.insert({
    required String id,
    required String tenantId,
    required String customerId,
    this.saleId = const Value.absent(),
    required double points,
    required String type,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId),
        customerId = Value(customerId),
        points = Value(points),
        type = Value(type);
  static Insertable<LoyaltyLedgerData> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? customerId,
    Expression<String>? saleId,
    Expression<double>? points,
    Expression<String>? type,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (customerId != null) 'customer_id': customerId,
      if (saleId != null) 'sale_id': saleId,
      if (points != null) 'points': points,
      if (type != null) 'type': type,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoyaltyLedgerCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? customerId,
      Value<String?>? saleId,
      Value<double>? points,
      Value<String>? type,
      Value<String?>? notes,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return LoyaltyLedgerCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      saleId: saleId ?? this.saleId,
      points: points ?? this.points,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (points.present) {
      map['points'] = Variable<double>(points.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoyaltyLedgerCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('customerId: $customerId, ')
          ..write('saleId: $saleId, ')
          ..write('points: $points, ')
          ..write('type: $type, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrintSettingsTable extends PrintSettings
    with TableInfo<$PrintSettingsTable, PrintSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paperSizeMeta =
      const VerificationMeta('paperSize');
  @override
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
      'paper_size', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('80mm'));
  static const VerificationMeta _printerNameMeta =
      const VerificationMeta('printerName');
  @override
  late final GeneratedColumn<String> printerName = GeneratedColumn<String>(
      'printer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _printerTypeMeta =
      const VerificationMeta('printerType');
  @override
  late final GeneratedColumn<String> printerType = GeneratedColumn<String>(
      'printer_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('THERMAL'));
  static const VerificationMeta _invoiceTemplateMeta =
      const VerificationMeta('invoiceTemplate');
  @override
  late final GeneratedColumn<String> invoiceTemplate = GeneratedColumn<String>(
      'invoice_template', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PROFESSIONAL'));
  static const VerificationMeta _autoPrintMeta =
      const VerificationMeta('autoPrint');
  @override
  late final GeneratedColumn<bool> autoPrint = GeneratedColumn<bool>(
      'auto_print', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("auto_print" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _showLogoMeta =
      const VerificationMeta('showLogo');
  @override
  late final GeneratedColumn<bool> showLogo = GeneratedColumn<bool>(
      'show_logo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_logo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showBarcodeMeta =
      const VerificationMeta('showBarcode');
  @override
  late final GeneratedColumn<bool> showBarcode = GeneratedColumn<bool>(
      'show_barcode', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_barcode" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _showQrMeta = const VerificationMeta('showQr');
  @override
  late final GeneratedColumn<bool> showQr = GeneratedColumn<bool>(
      'show_qr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_qr" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showTaxMeta =
      const VerificationMeta('showTax');
  @override
  late final GeneratedColumn<bool> showTax = GeneratedColumn<bool>(
      'show_tax', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_tax" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showDiscountMeta =
      const VerificationMeta('showDiscount');
  @override
  late final GeneratedColumn<bool> showDiscount = GeneratedColumn<bool>(
      'show_discount', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_discount" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showCustomerAddressMeta =
      const VerificationMeta('showCustomerAddress');
  @override
  late final GeneratedColumn<bool> showCustomerAddress = GeneratedColumn<bool>(
      'show_customer_address', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_customer_address" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _marginTopMeta =
      const VerificationMeta('marginTop');
  @override
  late final GeneratedColumn<double> marginTop = GeneratedColumn<double>(
      'margin_top', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _marginLeftMeta =
      const VerificationMeta('marginLeft');
  @override
  late final GeneratedColumn<double> marginLeft = GeneratedColumn<double>(
      'margin_left', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _fontSizeMeta =
      const VerificationMeta('fontSize');
  @override
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
      'font_size', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _lineSpacingMeta =
      const VerificationMeta('lineSpacing');
  @override
  late final GeneratedColumn<double> lineSpacing = GeneratedColumn<double>(
      'line_spacing', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.2));
  static const VerificationMeta _thankYouMessageMeta =
      const VerificationMeta('thankYouMessage');
  @override
  late final GeneratedColumn<String> thankYouMessage = GeneratedColumn<String>(
      'thank_you_message', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Thank you for your business!'));
  static const VerificationMeta _returnPolicyMeta =
      const VerificationMeta('returnPolicy');
  @override
  late final GeneratedColumn<String> returnPolicy = GeneratedColumn<String>(
      'return_policy', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _socialLinksMeta =
      const VerificationMeta('socialLinks');
  @override
  late final GeneratedColumn<String> socialLinks = GeneratedColumn<String>(
      'social_links', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tenantId,
        paperSize,
        printerName,
        printerType,
        invoiceTemplate,
        autoPrint,
        showLogo,
        showBarcode,
        showQr,
        showTax,
        showDiscount,
        showCustomerAddress,
        marginTop,
        marginLeft,
        fontSize,
        lineSpacing,
        thankYouMessage,
        returnPolicy,
        socialLinks,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_settings';
  @override
  VerificationContext validateIntegrity(Insertable<PrintSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('paper_size')) {
      context.handle(_paperSizeMeta,
          paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta));
    }
    if (data.containsKey('printer_name')) {
      context.handle(
          _printerNameMeta,
          printerName.isAcceptableOrUnknown(
              data['printer_name']!, _printerNameMeta));
    }
    if (data.containsKey('printer_type')) {
      context.handle(
          _printerTypeMeta,
          printerType.isAcceptableOrUnknown(
              data['printer_type']!, _printerTypeMeta));
    }
    if (data.containsKey('invoice_template')) {
      context.handle(
          _invoiceTemplateMeta,
          invoiceTemplate.isAcceptableOrUnknown(
              data['invoice_template']!, _invoiceTemplateMeta));
    }
    if (data.containsKey('auto_print')) {
      context.handle(_autoPrintMeta,
          autoPrint.isAcceptableOrUnknown(data['auto_print']!, _autoPrintMeta));
    }
    if (data.containsKey('show_logo')) {
      context.handle(_showLogoMeta,
          showLogo.isAcceptableOrUnknown(data['show_logo']!, _showLogoMeta));
    }
    if (data.containsKey('show_barcode')) {
      context.handle(
          _showBarcodeMeta,
          showBarcode.isAcceptableOrUnknown(
              data['show_barcode']!, _showBarcodeMeta));
    }
    if (data.containsKey('show_qr')) {
      context.handle(_showQrMeta,
          showQr.isAcceptableOrUnknown(data['show_qr']!, _showQrMeta));
    }
    if (data.containsKey('show_tax')) {
      context.handle(_showTaxMeta,
          showTax.isAcceptableOrUnknown(data['show_tax']!, _showTaxMeta));
    }
    if (data.containsKey('show_discount')) {
      context.handle(
          _showDiscountMeta,
          showDiscount.isAcceptableOrUnknown(
              data['show_discount']!, _showDiscountMeta));
    }
    if (data.containsKey('show_customer_address')) {
      context.handle(
          _showCustomerAddressMeta,
          showCustomerAddress.isAcceptableOrUnknown(
              data['show_customer_address']!, _showCustomerAddressMeta));
    }
    if (data.containsKey('margin_top')) {
      context.handle(_marginTopMeta,
          marginTop.isAcceptableOrUnknown(data['margin_top']!, _marginTopMeta));
    }
    if (data.containsKey('margin_left')) {
      context.handle(
          _marginLeftMeta,
          marginLeft.isAcceptableOrUnknown(
              data['margin_left']!, _marginLeftMeta));
    }
    if (data.containsKey('font_size')) {
      context.handle(_fontSizeMeta,
          fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta));
    }
    if (data.containsKey('line_spacing')) {
      context.handle(
          _lineSpacingMeta,
          lineSpacing.isAcceptableOrUnknown(
              data['line_spacing']!, _lineSpacingMeta));
    }
    if (data.containsKey('thank_you_message')) {
      context.handle(
          _thankYouMessageMeta,
          thankYouMessage.isAcceptableOrUnknown(
              data['thank_you_message']!, _thankYouMessageMeta));
    }
    if (data.containsKey('return_policy')) {
      context.handle(
          _returnPolicyMeta,
          returnPolicy.isAcceptableOrUnknown(
              data['return_policy']!, _returnPolicyMeta));
    }
    if (data.containsKey('social_links')) {
      context.handle(
          _socialLinksMeta,
          socialLinks.isAcceptableOrUnknown(
              data['social_links']!, _socialLinksMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      paperSize: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paper_size'])!,
      printerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_name']),
      printerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}printer_type'])!,
      invoiceTemplate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}invoice_template'])!,
      autoPrint: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_print'])!,
      showLogo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_logo'])!,
      showBarcode: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_barcode'])!,
      showQr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_qr'])!,
      showTax: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_tax'])!,
      showDiscount: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_discount'])!,
      showCustomerAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}show_customer_address'])!,
      marginTop: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}margin_top'])!,
      marginLeft: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}margin_left'])!,
      fontSize: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}font_size'])!,
      lineSpacing: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}line_spacing'])!,
      thankYouMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}thank_you_message'])!,
      returnPolicy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}return_policy']),
      socialLinks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}social_links']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PrintSettingsTable createAlias(String alias) {
    return $PrintSettingsTable(attachedDatabase, alias);
  }
}

class PrintSetting extends DataClass implements Insertable<PrintSetting> {
  final String id;
  final String tenantId;
  final String paperSize;
  final String? printerName;
  final String printerType;
  final String invoiceTemplate;
  final bool autoPrint;
  final bool showLogo;
  final bool showBarcode;
  final bool showQr;
  final bool showTax;
  final bool showDiscount;
  final bool showCustomerAddress;
  final double marginTop;
  final double marginLeft;
  final double fontSize;
  final double lineSpacing;
  final String thankYouMessage;
  final String? returnPolicy;
  final String? socialLinks;
  final DateTime? updatedAt;
  const PrintSetting(
      {required this.id,
      required this.tenantId,
      required this.paperSize,
      this.printerName,
      required this.printerType,
      required this.invoiceTemplate,
      required this.autoPrint,
      required this.showLogo,
      required this.showBarcode,
      required this.showQr,
      required this.showTax,
      required this.showDiscount,
      required this.showCustomerAddress,
      required this.marginTop,
      required this.marginLeft,
      required this.fontSize,
      required this.lineSpacing,
      required this.thankYouMessage,
      this.returnPolicy,
      this.socialLinks,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['paper_size'] = Variable<String>(paperSize);
    if (!nullToAbsent || printerName != null) {
      map['printer_name'] = Variable<String>(printerName);
    }
    map['printer_type'] = Variable<String>(printerType);
    map['invoice_template'] = Variable<String>(invoiceTemplate);
    map['auto_print'] = Variable<bool>(autoPrint);
    map['show_logo'] = Variable<bool>(showLogo);
    map['show_barcode'] = Variable<bool>(showBarcode);
    map['show_qr'] = Variable<bool>(showQr);
    map['show_tax'] = Variable<bool>(showTax);
    map['show_discount'] = Variable<bool>(showDiscount);
    map['show_customer_address'] = Variable<bool>(showCustomerAddress);
    map['margin_top'] = Variable<double>(marginTop);
    map['margin_left'] = Variable<double>(marginLeft);
    map['font_size'] = Variable<double>(fontSize);
    map['line_spacing'] = Variable<double>(lineSpacing);
    map['thank_you_message'] = Variable<String>(thankYouMessage);
    if (!nullToAbsent || returnPolicy != null) {
      map['return_policy'] = Variable<String>(returnPolicy);
    }
    if (!nullToAbsent || socialLinks != null) {
      map['social_links'] = Variable<String>(socialLinks);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PrintSettingsCompanion toCompanion(bool nullToAbsent) {
    return PrintSettingsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      paperSize: Value(paperSize),
      printerName: printerName == null && nullToAbsent
          ? const Value.absent()
          : Value(printerName),
      printerType: Value(printerType),
      invoiceTemplate: Value(invoiceTemplate),
      autoPrint: Value(autoPrint),
      showLogo: Value(showLogo),
      showBarcode: Value(showBarcode),
      showQr: Value(showQr),
      showTax: Value(showTax),
      showDiscount: Value(showDiscount),
      showCustomerAddress: Value(showCustomerAddress),
      marginTop: Value(marginTop),
      marginLeft: Value(marginLeft),
      fontSize: Value(fontSize),
      lineSpacing: Value(lineSpacing),
      thankYouMessage: Value(thankYouMessage),
      returnPolicy: returnPolicy == null && nullToAbsent
          ? const Value.absent()
          : Value(returnPolicy),
      socialLinks: socialLinks == null && nullToAbsent
          ? const Value.absent()
          : Value(socialLinks),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PrintSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintSetting(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      paperSize: serializer.fromJson<String>(json['paperSize']),
      printerName: serializer.fromJson<String?>(json['printerName']),
      printerType: serializer.fromJson<String>(json['printerType']),
      invoiceTemplate: serializer.fromJson<String>(json['invoiceTemplate']),
      autoPrint: serializer.fromJson<bool>(json['autoPrint']),
      showLogo: serializer.fromJson<bool>(json['showLogo']),
      showBarcode: serializer.fromJson<bool>(json['showBarcode']),
      showQr: serializer.fromJson<bool>(json['showQr']),
      showTax: serializer.fromJson<bool>(json['showTax']),
      showDiscount: serializer.fromJson<bool>(json['showDiscount']),
      showCustomerAddress:
          serializer.fromJson<bool>(json['showCustomerAddress']),
      marginTop: serializer.fromJson<double>(json['marginTop']),
      marginLeft: serializer.fromJson<double>(json['marginLeft']),
      fontSize: serializer.fromJson<double>(json['fontSize']),
      lineSpacing: serializer.fromJson<double>(json['lineSpacing']),
      thankYouMessage: serializer.fromJson<String>(json['thankYouMessage']),
      returnPolicy: serializer.fromJson<String?>(json['returnPolicy']),
      socialLinks: serializer.fromJson<String?>(json['socialLinks']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'paperSize': serializer.toJson<String>(paperSize),
      'printerName': serializer.toJson<String?>(printerName),
      'printerType': serializer.toJson<String>(printerType),
      'invoiceTemplate': serializer.toJson<String>(invoiceTemplate),
      'autoPrint': serializer.toJson<bool>(autoPrint),
      'showLogo': serializer.toJson<bool>(showLogo),
      'showBarcode': serializer.toJson<bool>(showBarcode),
      'showQr': serializer.toJson<bool>(showQr),
      'showTax': serializer.toJson<bool>(showTax),
      'showDiscount': serializer.toJson<bool>(showDiscount),
      'showCustomerAddress': serializer.toJson<bool>(showCustomerAddress),
      'marginTop': serializer.toJson<double>(marginTop),
      'marginLeft': serializer.toJson<double>(marginLeft),
      'fontSize': serializer.toJson<double>(fontSize),
      'lineSpacing': serializer.toJson<double>(lineSpacing),
      'thankYouMessage': serializer.toJson<String>(thankYouMessage),
      'returnPolicy': serializer.toJson<String?>(returnPolicy),
      'socialLinks': serializer.toJson<String?>(socialLinks),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  PrintSetting copyWith(
          {String? id,
          String? tenantId,
          String? paperSize,
          Value<String?> printerName = const Value.absent(),
          String? printerType,
          String? invoiceTemplate,
          bool? autoPrint,
          bool? showLogo,
          bool? showBarcode,
          bool? showQr,
          bool? showTax,
          bool? showDiscount,
          bool? showCustomerAddress,
          double? marginTop,
          double? marginLeft,
          double? fontSize,
          double? lineSpacing,
          String? thankYouMessage,
          Value<String?> returnPolicy = const Value.absent(),
          Value<String?> socialLinks = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      PrintSetting(
        id: id ?? this.id,
        tenantId: tenantId ?? this.tenantId,
        paperSize: paperSize ?? this.paperSize,
        printerName: printerName.present ? printerName.value : this.printerName,
        printerType: printerType ?? this.printerType,
        invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
        autoPrint: autoPrint ?? this.autoPrint,
        showLogo: showLogo ?? this.showLogo,
        showBarcode: showBarcode ?? this.showBarcode,
        showQr: showQr ?? this.showQr,
        showTax: showTax ?? this.showTax,
        showDiscount: showDiscount ?? this.showDiscount,
        showCustomerAddress: showCustomerAddress ?? this.showCustomerAddress,
        marginTop: marginTop ?? this.marginTop,
        marginLeft: marginLeft ?? this.marginLeft,
        fontSize: fontSize ?? this.fontSize,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        thankYouMessage: thankYouMessage ?? this.thankYouMessage,
        returnPolicy:
            returnPolicy.present ? returnPolicy.value : this.returnPolicy,
        socialLinks: socialLinks.present ? socialLinks.value : this.socialLinks,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  PrintSetting copyWithCompanion(PrintSettingsCompanion data) {
    return PrintSetting(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      printerName:
          data.printerName.present ? data.printerName.value : this.printerName,
      printerType:
          data.printerType.present ? data.printerType.value : this.printerType,
      invoiceTemplate: data.invoiceTemplate.present
          ? data.invoiceTemplate.value
          : this.invoiceTemplate,
      autoPrint: data.autoPrint.present ? data.autoPrint.value : this.autoPrint,
      showLogo: data.showLogo.present ? data.showLogo.value : this.showLogo,
      showBarcode:
          data.showBarcode.present ? data.showBarcode.value : this.showBarcode,
      showQr: data.showQr.present ? data.showQr.value : this.showQr,
      showTax: data.showTax.present ? data.showTax.value : this.showTax,
      showDiscount: data.showDiscount.present
          ? data.showDiscount.value
          : this.showDiscount,
      showCustomerAddress: data.showCustomerAddress.present
          ? data.showCustomerAddress.value
          : this.showCustomerAddress,
      marginTop: data.marginTop.present ? data.marginTop.value : this.marginTop,
      marginLeft:
          data.marginLeft.present ? data.marginLeft.value : this.marginLeft,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      lineSpacing:
          data.lineSpacing.present ? data.lineSpacing.value : this.lineSpacing,
      thankYouMessage: data.thankYouMessage.present
          ? data.thankYouMessage.value
          : this.thankYouMessage,
      returnPolicy: data.returnPolicy.present
          ? data.returnPolicy.value
          : this.returnPolicy,
      socialLinks:
          data.socialLinks.present ? data.socialLinks.value : this.socialLinks,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintSetting(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('paperSize: $paperSize, ')
          ..write('printerName: $printerName, ')
          ..write('printerType: $printerType, ')
          ..write('invoiceTemplate: $invoiceTemplate, ')
          ..write('autoPrint: $autoPrint, ')
          ..write('showLogo: $showLogo, ')
          ..write('showBarcode: $showBarcode, ')
          ..write('showQr: $showQr, ')
          ..write('showTax: $showTax, ')
          ..write('showDiscount: $showDiscount, ')
          ..write('showCustomerAddress: $showCustomerAddress, ')
          ..write('marginTop: $marginTop, ')
          ..write('marginLeft: $marginLeft, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('thankYouMessage: $thankYouMessage, ')
          ..write('returnPolicy: $returnPolicy, ')
          ..write('socialLinks: $socialLinks, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        tenantId,
        paperSize,
        printerName,
        printerType,
        invoiceTemplate,
        autoPrint,
        showLogo,
        showBarcode,
        showQr,
        showTax,
        showDiscount,
        showCustomerAddress,
        marginTop,
        marginLeft,
        fontSize,
        lineSpacing,
        thankYouMessage,
        returnPolicy,
        socialLinks,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintSetting &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.paperSize == this.paperSize &&
          other.printerName == this.printerName &&
          other.printerType == this.printerType &&
          other.invoiceTemplate == this.invoiceTemplate &&
          other.autoPrint == this.autoPrint &&
          other.showLogo == this.showLogo &&
          other.showBarcode == this.showBarcode &&
          other.showQr == this.showQr &&
          other.showTax == this.showTax &&
          other.showDiscount == this.showDiscount &&
          other.showCustomerAddress == this.showCustomerAddress &&
          other.marginTop == this.marginTop &&
          other.marginLeft == this.marginLeft &&
          other.fontSize == this.fontSize &&
          other.lineSpacing == this.lineSpacing &&
          other.thankYouMessage == this.thankYouMessage &&
          other.returnPolicy == this.returnPolicy &&
          other.socialLinks == this.socialLinks &&
          other.updatedAt == this.updatedAt);
}

class PrintSettingsCompanion extends UpdateCompanion<PrintSetting> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> paperSize;
  final Value<String?> printerName;
  final Value<String> printerType;
  final Value<String> invoiceTemplate;
  final Value<bool> autoPrint;
  final Value<bool> showLogo;
  final Value<bool> showBarcode;
  final Value<bool> showQr;
  final Value<bool> showTax;
  final Value<bool> showDiscount;
  final Value<bool> showCustomerAddress;
  final Value<double> marginTop;
  final Value<double> marginLeft;
  final Value<double> fontSize;
  final Value<double> lineSpacing;
  final Value<String> thankYouMessage;
  final Value<String?> returnPolicy;
  final Value<String?> socialLinks;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PrintSettingsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.printerName = const Value.absent(),
    this.printerType = const Value.absent(),
    this.invoiceTemplate = const Value.absent(),
    this.autoPrint = const Value.absent(),
    this.showLogo = const Value.absent(),
    this.showBarcode = const Value.absent(),
    this.showQr = const Value.absent(),
    this.showTax = const Value.absent(),
    this.showDiscount = const Value.absent(),
    this.showCustomerAddress = const Value.absent(),
    this.marginTop = const Value.absent(),
    this.marginLeft = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.thankYouMessage = const Value.absent(),
    this.returnPolicy = const Value.absent(),
    this.socialLinks = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintSettingsCompanion.insert({
    required String id,
    required String tenantId,
    this.paperSize = const Value.absent(),
    this.printerName = const Value.absent(),
    this.printerType = const Value.absent(),
    this.invoiceTemplate = const Value.absent(),
    this.autoPrint = const Value.absent(),
    this.showLogo = const Value.absent(),
    this.showBarcode = const Value.absent(),
    this.showQr = const Value.absent(),
    this.showTax = const Value.absent(),
    this.showDiscount = const Value.absent(),
    this.showCustomerAddress = const Value.absent(),
    this.marginTop = const Value.absent(),
    this.marginLeft = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.thankYouMessage = const Value.absent(),
    this.returnPolicy = const Value.absent(),
    this.socialLinks = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tenantId = Value(tenantId);
  static Insertable<PrintSetting> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? paperSize,
    Expression<String>? printerName,
    Expression<String>? printerType,
    Expression<String>? invoiceTemplate,
    Expression<bool>? autoPrint,
    Expression<bool>? showLogo,
    Expression<bool>? showBarcode,
    Expression<bool>? showQr,
    Expression<bool>? showTax,
    Expression<bool>? showDiscount,
    Expression<bool>? showCustomerAddress,
    Expression<double>? marginTop,
    Expression<double>? marginLeft,
    Expression<double>? fontSize,
    Expression<double>? lineSpacing,
    Expression<String>? thankYouMessage,
    Expression<String>? returnPolicy,
    Expression<String>? socialLinks,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (paperSize != null) 'paper_size': paperSize,
      if (printerName != null) 'printer_name': printerName,
      if (printerType != null) 'printer_type': printerType,
      if (invoiceTemplate != null) 'invoice_template': invoiceTemplate,
      if (autoPrint != null) 'auto_print': autoPrint,
      if (showLogo != null) 'show_logo': showLogo,
      if (showBarcode != null) 'show_barcode': showBarcode,
      if (showQr != null) 'show_qr': showQr,
      if (showTax != null) 'show_tax': showTax,
      if (showDiscount != null) 'show_discount': showDiscount,
      if (showCustomerAddress != null)
        'show_customer_address': showCustomerAddress,
      if (marginTop != null) 'margin_top': marginTop,
      if (marginLeft != null) 'margin_left': marginLeft,
      if (fontSize != null) 'font_size': fontSize,
      if (lineSpacing != null) 'line_spacing': lineSpacing,
      if (thankYouMessage != null) 'thank_you_message': thankYouMessage,
      if (returnPolicy != null) 'return_policy': returnPolicy,
      if (socialLinks != null) 'social_links': socialLinks,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintSettingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tenantId,
      Value<String>? paperSize,
      Value<String?>? printerName,
      Value<String>? printerType,
      Value<String>? invoiceTemplate,
      Value<bool>? autoPrint,
      Value<bool>? showLogo,
      Value<bool>? showBarcode,
      Value<bool>? showQr,
      Value<bool>? showTax,
      Value<bool>? showDiscount,
      Value<bool>? showCustomerAddress,
      Value<double>? marginTop,
      Value<double>? marginLeft,
      Value<double>? fontSize,
      Value<double>? lineSpacing,
      Value<String>? thankYouMessage,
      Value<String?>? returnPolicy,
      Value<String?>? socialLinks,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return PrintSettingsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      paperSize: paperSize ?? this.paperSize,
      printerName: printerName ?? this.printerName,
      printerType: printerType ?? this.printerType,
      invoiceTemplate: invoiceTemplate ?? this.invoiceTemplate,
      autoPrint: autoPrint ?? this.autoPrint,
      showLogo: showLogo ?? this.showLogo,
      showBarcode: showBarcode ?? this.showBarcode,
      showQr: showQr ?? this.showQr,
      showTax: showTax ?? this.showTax,
      showDiscount: showDiscount ?? this.showDiscount,
      showCustomerAddress: showCustomerAddress ?? this.showCustomerAddress,
      marginTop: marginTop ?? this.marginTop,
      marginLeft: marginLeft ?? this.marginLeft,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      socialLinks: socialLinks ?? this.socialLinks,
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
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (printerName.present) {
      map['printer_name'] = Variable<String>(printerName.value);
    }
    if (printerType.present) {
      map['printer_type'] = Variable<String>(printerType.value);
    }
    if (invoiceTemplate.present) {
      map['invoice_template'] = Variable<String>(invoiceTemplate.value);
    }
    if (autoPrint.present) {
      map['auto_print'] = Variable<bool>(autoPrint.value);
    }
    if (showLogo.present) {
      map['show_logo'] = Variable<bool>(showLogo.value);
    }
    if (showBarcode.present) {
      map['show_barcode'] = Variable<bool>(showBarcode.value);
    }
    if (showQr.present) {
      map['show_qr'] = Variable<bool>(showQr.value);
    }
    if (showTax.present) {
      map['show_tax'] = Variable<bool>(showTax.value);
    }
    if (showDiscount.present) {
      map['show_discount'] = Variable<bool>(showDiscount.value);
    }
    if (showCustomerAddress.present) {
      map['show_customer_address'] = Variable<bool>(showCustomerAddress.value);
    }
    if (marginTop.present) {
      map['margin_top'] = Variable<double>(marginTop.value);
    }
    if (marginLeft.present) {
      map['margin_left'] = Variable<double>(marginLeft.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (lineSpacing.present) {
      map['line_spacing'] = Variable<double>(lineSpacing.value);
    }
    if (thankYouMessage.present) {
      map['thank_you_message'] = Variable<String>(thankYouMessage.value);
    }
    if (returnPolicy.present) {
      map['return_policy'] = Variable<String>(returnPolicy.value);
    }
    if (socialLinks.present) {
      map['social_links'] = Variable<String>(socialLinks.value);
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
    return (StringBuffer('PrintSettingsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('paperSize: $paperSize, ')
          ..write('printerName: $printerName, ')
          ..write('printerType: $printerType, ')
          ..write('invoiceTemplate: $invoiceTemplate, ')
          ..write('autoPrint: $autoPrint, ')
          ..write('showLogo: $showLogo, ')
          ..write('showBarcode: $showBarcode, ')
          ..write('showQr: $showQr, ')
          ..write('showTax: $showTax, ')
          ..write('showDiscount: $showDiscount, ')
          ..write('showCustomerAddress: $showCustomerAddress, ')
          ..write('marginTop: $marginTop, ')
          ..write('marginLeft: $marginLeft, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('thankYouMessage: $thankYouMessage, ')
          ..write('returnPolicy: $returnPolicy, ')
          ..write('socialLinks: $socialLinks, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SalesTable sales = $SalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $CommissionRulesTable commissionRules =
      $CommissionRulesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncJournalTable syncJournal = $SyncJournalTable(this);
  late final $CommissionLogsTable commissionLogs = $CommissionLogsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $DiscountsTable discounts = $DiscountsTable(this);
  late final $LoyaltyLedgerTable loyaltyLedger = $LoyaltyLedgerTable(this);
  late final $PrintSettingsTable printSettings = $PrintSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        products,
        sales,
        saleItems,
        customers,
        employees,
        commissionRules,
        syncQueue,
        syncJournal,
        commissionLogs,
        expenses,
        discounts,
        loyaltyLedger,
        printSettings
      ];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String tenantId,
  required String name,
  Value<String> description,
  Value<String?> sku,
  Value<String?> barcode,
  required double price,
  Value<double?> costPrice,
  required String category,
  required String type,
  required String unitOfMeasure,
  Value<double> stock,
  Value<double> minStock,
  Value<double> reorderLevel,
  Value<int> warrantyMonths,
  Value<String?> locationId,
  Value<String> supplierId,
  Value<String?> batchNumber,
  Value<DateTime?> expiryDate,
  Value<bool> commissionEligible,
  Value<double> agentCommissionPercent,
  Value<double> bonusCommission,
  Value<double> profitMargin,
  Value<double> minPrice,
  Value<String?> imageUrl,
  Value<String?> imeis,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> name,
  Value<String> description,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> price,
  Value<double?> costPrice,
  Value<String> category,
  Value<String> type,
  Value<String> unitOfMeasure,
  Value<double> stock,
  Value<double> minStock,
  Value<double> reorderLevel,
  Value<int> warrantyMonths,
  Value<String?> locationId,
  Value<String> supplierId,
  Value<String?> batchNumber,
  Value<DateTime?> expiryDate,
  Value<bool> commissionEligible,
  Value<double> agentCommissionPercent,
  Value<double> bonusCommission,
  Value<double> profitMargin,
  Value<double> minPrice,
  Value<String?> imageUrl,
  Value<String?> imeis,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProductsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProductsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double?> costPrice = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> unitOfMeasure = const Value.absent(),
            Value<double> stock = const Value.absent(),
            Value<double> minStock = const Value.absent(),
            Value<double> reorderLevel = const Value.absent(),
            Value<int> warrantyMonths = const Value.absent(),
            Value<String?> locationId = const Value.absent(),
            Value<String> supplierId = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<bool> commissionEligible = const Value.absent(),
            Value<double> agentCommissionPercent = const Value.absent(),
            Value<double> bonusCommission = const Value.absent(),
            Value<double> profitMargin = const Value.absent(),
            Value<double> minPrice = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> imeis = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            tenantId: tenantId,
            name: name,
            description: description,
            sku: sku,
            barcode: barcode,
            price: price,
            costPrice: costPrice,
            category: category,
            type: type,
            unitOfMeasure: unitOfMeasure,
            stock: stock,
            minStock: minStock,
            reorderLevel: reorderLevel,
            warrantyMonths: warrantyMonths,
            locationId: locationId,
            supplierId: supplierId,
            batchNumber: batchNumber,
            expiryDate: expiryDate,
            commissionEligible: commissionEligible,
            agentCommissionPercent: agentCommissionPercent,
            bonusCommission: bonusCommission,
            profitMargin: profitMargin,
            minPrice: minPrice,
            imageUrl: imageUrl,
            imeis: imeis,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String name,
            Value<String> description = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            required double price,
            Value<double?> costPrice = const Value.absent(),
            required String category,
            required String type,
            required String unitOfMeasure,
            Value<double> stock = const Value.absent(),
            Value<double> minStock = const Value.absent(),
            Value<double> reorderLevel = const Value.absent(),
            Value<int> warrantyMonths = const Value.absent(),
            Value<String?> locationId = const Value.absent(),
            Value<String> supplierId = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
            Value<bool> commissionEligible = const Value.absent(),
            Value<double> agentCommissionPercent = const Value.absent(),
            Value<double> bonusCommission = const Value.absent(),
            Value<double> profitMargin = const Value.absent(),
            Value<double> minPrice = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> imeis = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            tenantId: tenantId,
            name: name,
            description: description,
            sku: sku,
            barcode: barcode,
            price: price,
            costPrice: costPrice,
            category: category,
            type: type,
            unitOfMeasure: unitOfMeasure,
            stock: stock,
            minStock: minStock,
            reorderLevel: reorderLevel,
            warrantyMonths: warrantyMonths,
            locationId: locationId,
            supplierId: supplierId,
            batchNumber: batchNumber,
            expiryDate: expiryDate,
            commissionEligible: commissionEligible,
            agentCommissionPercent: agentCommissionPercent,
            bonusCommission: bonusCommission,
            profitMargin: profitMargin,
            minPrice: minPrice,
            imageUrl: imageUrl,
            imeis: imeis,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$ProductsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get costPrice => $state.composableBuilder(
      column: $state.table.costPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unitOfMeasure => $state.composableBuilder(
      column: $state.table.unitOfMeasure,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get minStock => $state.composableBuilder(
      column: $state.table.minStock,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reorderLevel => $state.composableBuilder(
      column: $state.table.reorderLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get warrantyMonths => $state.composableBuilder(
      column: $state.table.warrantyMonths,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get supplierId => $state.composableBuilder(
      column: $state.table.supplierId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get commissionEligible => $state.composableBuilder(
      column: $state.table.commissionEligible,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get agentCommissionPercent => $state.composableBuilder(
      column: $state.table.agentCommissionPercent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get bonusCommission => $state.composableBuilder(
      column: $state.table.bonusCommission,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get profitMargin => $state.composableBuilder(
      column: $state.table.profitMargin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get minPrice => $state.composableBuilder(
      column: $state.table.minPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imeis => $state.composableBuilder(
      column: $state.table.imeis,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ProductsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sku => $state.composableBuilder(
      column: $state.table.sku,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get barcode => $state.composableBuilder(
      column: $state.table.barcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get price => $state.composableBuilder(
      column: $state.table.price,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get costPrice => $state.composableBuilder(
      column: $state.table.costPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unitOfMeasure => $state.composableBuilder(
      column: $state.table.unitOfMeasure,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get stock => $state.composableBuilder(
      column: $state.table.stock,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get minStock => $state.composableBuilder(
      column: $state.table.minStock,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reorderLevel => $state.composableBuilder(
      column: $state.table.reorderLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get warrantyMonths => $state.composableBuilder(
      column: $state.table.warrantyMonths,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get supplierId => $state.composableBuilder(
      column: $state.table.supplierId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get commissionEligible => $state.composableBuilder(
      column: $state.table.commissionEligible,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get agentCommissionPercent =>
      $state.composableBuilder(
          column: $state.table.agentCommissionPercent,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get bonusCommission => $state.composableBuilder(
      column: $state.table.bonusCommission,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get profitMargin => $state.composableBuilder(
      column: $state.table.profitMargin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get minPrice => $state.composableBuilder(
      column: $state.table.minPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imeis => $state.composableBuilder(
      column: $state.table.imeis,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  required String id,
  required String tenantId,
  Value<String?> customerId,
  required String employeeId,
  required double total,
  Value<double> subtotal,
  Value<double> tax,
  Value<double> discount,
  Value<double> invoiceDiscount,
  Value<String> discountType,
  Value<double> loyaltyPointsUsed,
  Value<double> loyaltyPointsEarned,
  Value<String?> invoiceNumber,
  Value<String?> notes,
  required String paymentMethod,
  Value<double> cashAmount,
  Value<double> cardAmount,
  required String status,
  required String locationId,
  Value<double> shippingCharges,
  Value<String?> agentName,
  Value<double> agentCommission,
  Value<String> agentCommissionType,
  Value<bool> agentCommissionPaid,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> shippingAddress,
  Value<int> rowid,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String?> customerId,
  Value<String> employeeId,
  Value<double> total,
  Value<double> subtotal,
  Value<double> tax,
  Value<double> discount,
  Value<double> invoiceDiscount,
  Value<String> discountType,
  Value<double> loyaltyPointsUsed,
  Value<double> loyaltyPointsEarned,
  Value<String?> invoiceNumber,
  Value<String?> notes,
  Value<String> paymentMethod,
  Value<double> cashAmount,
  Value<double> cardAmount,
  Value<String> status,
  Value<String> locationId,
  Value<double> shippingCharges,
  Value<String?> agentName,
  Value<double> agentCommission,
  Value<String> agentCommissionType,
  Value<bool> agentCommissionPaid,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> shippingAddress,
  Value<int> rowid,
});

class $$SalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder> {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SalesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SalesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> invoiceDiscount = const Value.absent(),
            Value<String> discountType = const Value.absent(),
            Value<double> loyaltyPointsUsed = const Value.absent(),
            Value<double> loyaltyPointsEarned = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<double> cashAmount = const Value.absent(),
            Value<double> cardAmount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> locationId = const Value.absent(),
            Value<double> shippingCharges = const Value.absent(),
            Value<String?> agentName = const Value.absent(),
            Value<double> agentCommission = const Value.absent(),
            Value<String> agentCommissionType = const Value.absent(),
            Value<bool> agentCommissionPaid = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> shippingAddress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion(
            id: id,
            tenantId: tenantId,
            customerId: customerId,
            employeeId: employeeId,
            total: total,
            subtotal: subtotal,
            tax: tax,
            discount: discount,
            invoiceDiscount: invoiceDiscount,
            discountType: discountType,
            loyaltyPointsUsed: loyaltyPointsUsed,
            loyaltyPointsEarned: loyaltyPointsEarned,
            invoiceNumber: invoiceNumber,
            notes: notes,
            paymentMethod: paymentMethod,
            cashAmount: cashAmount,
            cardAmount: cardAmount,
            status: status,
            locationId: locationId,
            shippingCharges: shippingCharges,
            agentName: agentName,
            agentCommission: agentCommission,
            agentCommissionType: agentCommissionType,
            agentCommissionPaid: agentCommissionPaid,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            shippingAddress: shippingAddress,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            Value<String?> customerId = const Value.absent(),
            required String employeeId,
            required double total,
            Value<double> subtotal = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> invoiceDiscount = const Value.absent(),
            Value<String> discountType = const Value.absent(),
            Value<double> loyaltyPointsUsed = const Value.absent(),
            Value<double> loyaltyPointsEarned = const Value.absent(),
            Value<String?> invoiceNumber = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String paymentMethod,
            Value<double> cashAmount = const Value.absent(),
            Value<double> cardAmount = const Value.absent(),
            required String status,
            required String locationId,
            Value<double> shippingCharges = const Value.absent(),
            Value<String?> agentName = const Value.absent(),
            Value<double> agentCommission = const Value.absent(),
            Value<String> agentCommissionType = const Value.absent(),
            Value<bool> agentCommissionPaid = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> shippingAddress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesCompanion.insert(
            id: id,
            tenantId: tenantId,
            customerId: customerId,
            employeeId: employeeId,
            total: total,
            subtotal: subtotal,
            tax: tax,
            discount: discount,
            invoiceDiscount: invoiceDiscount,
            discountType: discountType,
            loyaltyPointsUsed: loyaltyPointsUsed,
            loyaltyPointsEarned: loyaltyPointsEarned,
            invoiceNumber: invoiceNumber,
            notes: notes,
            paymentMethod: paymentMethod,
            cashAmount: cashAmount,
            cardAmount: cardAmount,
            status: status,
            locationId: locationId,
            shippingCharges: shippingCharges,
            agentName: agentName,
            agentCommission: agentCommission,
            agentCommissionType: agentCommissionType,
            agentCommissionPaid: agentCommissionPaid,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            shippingAddress: shippingAddress,
            rowid: rowid,
          ),
        ));
}

class $$SalesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get tax => $state.composableBuilder(
      column: $state.table.tax,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get invoiceDiscount => $state.composableBuilder(
      column: $state.table.invoiceDiscount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get discountType => $state.composableBuilder(
      column: $state.table.discountType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get loyaltyPointsUsed => $state.composableBuilder(
      column: $state.table.loyaltyPointsUsed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get loyaltyPointsEarned => $state.composableBuilder(
      column: $state.table.loyaltyPointsEarned,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get invoiceNumber => $state.composableBuilder(
      column: $state.table.invoiceNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cashAmount => $state.composableBuilder(
      column: $state.table.cashAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get cardAmount => $state.composableBuilder(
      column: $state.table.cardAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get shippingCharges => $state.composableBuilder(
      column: $state.table.shippingCharges,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get agentName => $state.composableBuilder(
      column: $state.table.agentName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get agentCommission => $state.composableBuilder(
      column: $state.table.agentCommission,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get agentCommissionType => $state.composableBuilder(
      column: $state.table.agentCommissionType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get agentCommissionPaid => $state.composableBuilder(
      column: $state.table.agentCommissionPaid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get shippingAddress => $state.composableBuilder(
      column: $state.table.shippingAddress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SalesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get subtotal => $state.composableBuilder(
      column: $state.table.subtotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get tax => $state.composableBuilder(
      column: $state.table.tax,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get invoiceDiscount => $state.composableBuilder(
      column: $state.table.invoiceDiscount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get discountType => $state.composableBuilder(
      column: $state.table.discountType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get loyaltyPointsUsed => $state.composableBuilder(
      column: $state.table.loyaltyPointsUsed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get loyaltyPointsEarned => $state.composableBuilder(
      column: $state.table.loyaltyPointsEarned,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get invoiceNumber => $state.composableBuilder(
      column: $state.table.invoiceNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paymentMethod => $state.composableBuilder(
      column: $state.table.paymentMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cashAmount => $state.composableBuilder(
      column: $state.table.cashAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get cardAmount => $state.composableBuilder(
      column: $state.table.cardAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get shippingCharges => $state.composableBuilder(
      column: $state.table.shippingCharges,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get agentName => $state.composableBuilder(
      column: $state.table.agentName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get agentCommission => $state.composableBuilder(
      column: $state.table.agentCommission,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get agentCommissionType => $state.composableBuilder(
      column: $state.table.agentCommissionType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get agentCommissionPaid => $state.composableBuilder(
      column: $state.table.agentCommissionPaid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get shippingAddress => $state.composableBuilder(
      column: $state.table.shippingAddress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SaleItemsTableCreateCompanionBuilder = SaleItemsCompanion Function({
  required String id,
  required String saleId,
  required String productId,
  required String productName,
  required double quantity,
  required double unitPrice,
  Value<double> originalPrice,
  Value<double> discount,
  Value<String> discountType,
  required double total,
  Value<double> commissionAmount,
  required String tenantId,
  Value<String?> imei,
  Value<int> rowid,
});
typedef $$SaleItemsTableUpdateCompanionBuilder = SaleItemsCompanion Function({
  Value<String> id,
  Value<String> saleId,
  Value<String> productId,
  Value<String> productName,
  Value<double> quantity,
  Value<double> unitPrice,
  Value<double> originalPrice,
  Value<double> discount,
  Value<String> discountType,
  Value<double> total,
  Value<double> commissionAmount,
  Value<String> tenantId,
  Value<String?> imei,
  Value<int> rowid,
});

class $$SaleItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SaleItemsTable,
    SaleItem,
    $$SaleItemsTableFilterComposer,
    $$SaleItemsTableOrderingComposer,
    $$SaleItemsTableCreateCompanionBuilder,
    $$SaleItemsTableUpdateCompanionBuilder> {
  $$SaleItemsTableTableManager(_$AppDatabase db, $SaleItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SaleItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SaleItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> saleId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> unitPrice = const Value.absent(),
            Value<double> originalPrice = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String> discountType = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<double> commissionAmount = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String?> imei = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SaleItemsCompanion(
            id: id,
            saleId: saleId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            originalPrice: originalPrice,
            discount: discount,
            discountType: discountType,
            total: total,
            commissionAmount: commissionAmount,
            tenantId: tenantId,
            imei: imei,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String saleId,
            required String productId,
            required String productName,
            required double quantity,
            required double unitPrice,
            Value<double> originalPrice = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String> discountType = const Value.absent(),
            required double total,
            Value<double> commissionAmount = const Value.absent(),
            required String tenantId,
            Value<String?> imei = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SaleItemsCompanion.insert(
            id: id,
            saleId: saleId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            originalPrice: originalPrice,
            discount: discount,
            discountType: discountType,
            total: total,
            commissionAmount: commissionAmount,
            tenantId: tenantId,
            imei: imei,
            rowid: rowid,
          ),
        ));
}

class $$SaleItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get unitPrice => $state.composableBuilder(
      column: $state.table.unitPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get originalPrice => $state.composableBuilder(
      column: $state.table.originalPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get discountType => $state.composableBuilder(
      column: $state.table.discountType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get commissionAmount => $state.composableBuilder(
      column: $state.table.commissionAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imei => $state.composableBuilder(
      column: $state.table.imei,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SaleItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get unitPrice => $state.composableBuilder(
      column: $state.table.unitPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get originalPrice => $state.composableBuilder(
      column: $state.table.originalPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discount => $state.composableBuilder(
      column: $state.table.discount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get discountType => $state.composableBuilder(
      column: $state.table.discountType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get commissionAmount => $state.composableBuilder(
      column: $state.table.commissionAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imei => $state.composableBuilder(
      column: $state.table.imei,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String tenantId,
  required String name,
  required String phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> vehicleNumber,
  Value<double> creditLimit,
  Value<double> currentBalance,
  Value<double> loyaltyPoints,
  Value<double> totalPurchases,
  Value<String> customerType,
  Value<double> discountPercent,
  Value<DateTime?> birthday,
  Value<String?> notes,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> shippingAddress,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> name,
  Value<String> phone,
  Value<String?> email,
  Value<String?> address,
  Value<String?> vehicleNumber,
  Value<double> creditLimit,
  Value<double> currentBalance,
  Value<double> loyaltyPoints,
  Value<double> totalPurchases,
  Value<String> customerType,
  Value<double> discountPercent,
  Value<DateTime?> birthday,
  Value<String?> notes,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> shippingAddress,
  Value<int> rowid,
});

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CustomersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CustomersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> vehicleNumber = const Value.absent(),
            Value<double> creditLimit = const Value.absent(),
            Value<double> currentBalance = const Value.absent(),
            Value<double> loyaltyPoints = const Value.absent(),
            Value<double> totalPurchases = const Value.absent(),
            Value<String> customerType = const Value.absent(),
            Value<double> discountPercent = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> shippingAddress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            tenantId: tenantId,
            name: name,
            phone: phone,
            email: email,
            address: address,
            vehicleNumber: vehicleNumber,
            creditLimit: creditLimit,
            currentBalance: currentBalance,
            loyaltyPoints: loyaltyPoints,
            totalPurchases: totalPurchases,
            customerType: customerType,
            discountPercent: discountPercent,
            birthday: birthday,
            notes: notes,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            shippingAddress: shippingAddress,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String name,
            required String phone,
            Value<String?> email = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> vehicleNumber = const Value.absent(),
            Value<double> creditLimit = const Value.absent(),
            Value<double> currentBalance = const Value.absent(),
            Value<double> loyaltyPoints = const Value.absent(),
            Value<double> totalPurchases = const Value.absent(),
            Value<String> customerType = const Value.absent(),
            Value<double> discountPercent = const Value.absent(),
            Value<DateTime?> birthday = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> shippingAddress = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            tenantId: tenantId,
            name: name,
            phone: phone,
            email: email,
            address: address,
            vehicleNumber: vehicleNumber,
            creditLimit: creditLimit,
            currentBalance: currentBalance,
            loyaltyPoints: loyaltyPoints,
            totalPurchases: totalPurchases,
            customerType: customerType,
            discountPercent: discountPercent,
            birthday: birthday,
            notes: notes,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            shippingAddress: shippingAddress,
            rowid: rowid,
          ),
        ));
}

class $$CustomersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vehicleNumber => $state.composableBuilder(
      column: $state.table.vehicleNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get creditLimit => $state.composableBuilder(
      column: $state.table.creditLimit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get currentBalance => $state.composableBuilder(
      column: $state.table.currentBalance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get loyaltyPoints => $state.composableBuilder(
      column: $state.table.loyaltyPoints,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalPurchases => $state.composableBuilder(
      column: $state.table.totalPurchases,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerType => $state.composableBuilder(
      column: $state.table.customerType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get discountPercent => $state.composableBuilder(
      column: $state.table.discountPercent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get birthday => $state.composableBuilder(
      column: $state.table.birthday,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get shippingAddress => $state.composableBuilder(
      column: $state.table.shippingAddress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CustomersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get address => $state.composableBuilder(
      column: $state.table.address,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vehicleNumber => $state.composableBuilder(
      column: $state.table.vehicleNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get creditLimit => $state.composableBuilder(
      column: $state.table.creditLimit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get currentBalance => $state.composableBuilder(
      column: $state.table.currentBalance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get loyaltyPoints => $state.composableBuilder(
      column: $state.table.loyaltyPoints,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalPurchases => $state.composableBuilder(
      column: $state.table.totalPurchases,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerType => $state.composableBuilder(
      column: $state.table.customerType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get discountPercent => $state.composableBuilder(
      column: $state.table.discountPercent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get birthday => $state.composableBuilder(
      column: $state.table.birthday,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get shippingAddress => $state.composableBuilder(
      column: $state.table.shippingAddress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$EmployeesTableCreateCompanionBuilder = EmployeesCompanion Function({
  required String id,
  required String tenantId,
  required String name,
  required String email,
  Value<String?> phone,
  required String role,
  required String locationId,
  Value<String> commissionType,
  Value<double> commissionValue,
  Value<double> minSalesTarget,
  Value<bool> isAgent,
  Value<DateTime?> joiningDate,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$EmployeesTableUpdateCompanionBuilder = EmployeesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> name,
  Value<String> email,
  Value<String?> phone,
  Value<String> role,
  Value<String> locationId,
  Value<String> commissionType,
  Value<double> commissionValue,
  Value<double> minSalesTarget,
  Value<bool> isAgent,
  Value<DateTime?> joiningDate,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$EmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder> {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$EmployeesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$EmployeesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> locationId = const Value.absent(),
            Value<String> commissionType = const Value.absent(),
            Value<double> commissionValue = const Value.absent(),
            Value<double> minSalesTarget = const Value.absent(),
            Value<bool> isAgent = const Value.absent(),
            Value<DateTime?> joiningDate = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCompanion(
            id: id,
            tenantId: tenantId,
            name: name,
            email: email,
            phone: phone,
            role: role,
            locationId: locationId,
            commissionType: commissionType,
            commissionValue: commissionValue,
            minSalesTarget: minSalesTarget,
            isAgent: isAgent,
            joiningDate: joiningDate,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String name,
            required String email,
            Value<String?> phone = const Value.absent(),
            required String role,
            required String locationId,
            Value<String> commissionType = const Value.absent(),
            Value<double> commissionValue = const Value.absent(),
            Value<double> minSalesTarget = const Value.absent(),
            Value<bool> isAgent = const Value.absent(),
            Value<DateTime?> joiningDate = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCompanion.insert(
            id: id,
            tenantId: tenantId,
            name: name,
            email: email,
            phone: phone,
            role: role,
            locationId: locationId,
            commissionType: commissionType,
            commissionValue: commissionValue,
            minSalesTarget: minSalesTarget,
            isAgent: isAgent,
            joiningDate: joiningDate,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$EmployeesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get commissionType => $state.composableBuilder(
      column: $state.table.commissionType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get commissionValue => $state.composableBuilder(
      column: $state.table.commissionValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get minSalesTarget => $state.composableBuilder(
      column: $state.table.minSalesTarget,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAgent => $state.composableBuilder(
      column: $state.table.isAgent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get joiningDate => $state.composableBuilder(
      column: $state.table.joiningDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$EmployeesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get commissionType => $state.composableBuilder(
      column: $state.table.commissionType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get commissionValue => $state.composableBuilder(
      column: $state.table.commissionValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get minSalesTarget => $state.composableBuilder(
      column: $state.table.minSalesTarget,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAgent => $state.composableBuilder(
      column: $state.table.isAgent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get joiningDate => $state.composableBuilder(
      column: $state.table.joiningDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CommissionRulesTableCreateCompanionBuilder = CommissionRulesCompanion
    Function({
  required String id,
  required String tenantId,
  required String name,
  required String ruleType,
  Value<double> value,
  Value<String?> productId,
  Value<String?> category,
  Value<String?> employeeId,
  Value<bool> active,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$CommissionRulesTableUpdateCompanionBuilder = CommissionRulesCompanion
    Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> name,
  Value<String> ruleType,
  Value<double> value,
  Value<String?> productId,
  Value<String?> category,
  Value<String?> employeeId,
  Value<bool> active,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$CommissionRulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CommissionRulesTable,
    CommissionRule,
    $$CommissionRulesTableFilterComposer,
    $$CommissionRulesTableOrderingComposer,
    $$CommissionRulesTableCreateCompanionBuilder,
    $$CommissionRulesTableUpdateCompanionBuilder> {
  $$CommissionRulesTableTableManager(
      _$AppDatabase db, $CommissionRulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CommissionRulesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CommissionRulesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> ruleType = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> employeeId = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CommissionRulesCompanion(
            id: id,
            tenantId: tenantId,
            name: name,
            ruleType: ruleType,
            value: value,
            productId: productId,
            category: category,
            employeeId: employeeId,
            active: active,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String name,
            required String ruleType,
            Value<double> value = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> employeeId = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CommissionRulesCompanion.insert(
            id: id,
            tenantId: tenantId,
            name: name,
            ruleType: ruleType,
            value: value,
            productId: productId,
            category: category,
            employeeId: employeeId,
            active: active,
            synced: synced,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$CommissionRulesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CommissionRulesTable> {
  $$CommissionRulesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ruleType => $state.composableBuilder(
      column: $state.table.ruleType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get active => $state.composableBuilder(
      column: $state.table.active,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CommissionRulesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CommissionRulesTable> {
  $$CommissionRulesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ruleType => $state.composableBuilder(
      column: $state.table.ruleType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get active => $state.composableBuilder(
      column: $state.table.active,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String operation,
  required String entityTable,
  required String recordId,
  Value<String?> clientOpId,
  required String data,
  required DateTime createdAt,
  Value<int> retryCount,
  Value<DateTime?> lastRetryAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> operation,
  Value<String> entityTable,
  Value<String> recordId,
  Value<String?> clientOpId,
  Value<String> data,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<DateTime?> lastRetryAt,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String?> clientOpId = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetryAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            operation: operation,
            entityTable: entityTable,
            recordId: recordId,
            clientOpId: clientOpId,
            data: data,
            createdAt: createdAt,
            retryCount: retryCount,
            lastRetryAt: lastRetryAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String operation,
            required String entityTable,
            required String recordId,
            Value<String?> clientOpId = const Value.absent(),
            required String data,
            required DateTime createdAt,
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetryAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            operation: operation,
            entityTable: entityTable,
            recordId: recordId,
            clientOpId: clientOpId,
            data: data,
            createdAt: createdAt,
            retryCount: retryCount,
            lastRetryAt: lastRetryAt,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityTable => $state.composableBuilder(
      column: $state.table.entityTable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get clientOpId => $state.composableBuilder(
      column: $state.table.clientOpId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastRetryAt => $state.composableBuilder(
      column: $state.table.lastRetryAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityTable => $state.composableBuilder(
      column: $state.table.entityTable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get clientOpId => $state.composableBuilder(
      column: $state.table.clientOpId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastRetryAt => $state.composableBuilder(
      column: $state.table.lastRetryAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncJournalTableCreateCompanionBuilder = SyncJournalCompanion
    Function({
  Value<int> id,
  Value<String?> clientOpId,
  Value<int?> serverSeq,
  required String direction,
  required String status,
  required String operation,
  required String entityTable,
  required String recordId,
  Value<String?> payload,
  Value<String?> errorReason,
  Value<String?> sourceDeviceId,
  Value<String?> sourceUserId,
  Value<int> retryCount,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$SyncJournalTableUpdateCompanionBuilder = SyncJournalCompanion
    Function({
  Value<int> id,
  Value<String?> clientOpId,
  Value<int?> serverSeq,
  Value<String> direction,
  Value<String> status,
  Value<String> operation,
  Value<String> entityTable,
  Value<String> recordId,
  Value<String?> payload,
  Value<String?> errorReason,
  Value<String?> sourceDeviceId,
  Value<String?> sourceUserId,
  Value<int> retryCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SyncJournalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncJournalTable,
    SyncJournalData,
    $$SyncJournalTableFilterComposer,
    $$SyncJournalTableOrderingComposer,
    $$SyncJournalTableCreateCompanionBuilder,
    $$SyncJournalTableUpdateCompanionBuilder> {
  $$SyncJournalTableTableManager(_$AppDatabase db, $SyncJournalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncJournalTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncJournalTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> clientOpId = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String?> payload = const Value.absent(),
            Value<String?> errorReason = const Value.absent(),
            Value<String?> sourceDeviceId = const Value.absent(),
            Value<String?> sourceUserId = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncJournalCompanion(
            id: id,
            clientOpId: clientOpId,
            serverSeq: serverSeq,
            direction: direction,
            status: status,
            operation: operation,
            entityTable: entityTable,
            recordId: recordId,
            payload: payload,
            errorReason: errorReason,
            sourceDeviceId: sourceDeviceId,
            sourceUserId: sourceUserId,
            retryCount: retryCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> clientOpId = const Value.absent(),
            Value<int?> serverSeq = const Value.absent(),
            required String direction,
            required String status,
            required String operation,
            required String entityTable,
            required String recordId,
            Value<String?> payload = const Value.absent(),
            Value<String?> errorReason = const Value.absent(),
            Value<String?> sourceDeviceId = const Value.absent(),
            Value<String?> sourceUserId = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              SyncJournalCompanion.insert(
            id: id,
            clientOpId: clientOpId,
            serverSeq: serverSeq,
            direction: direction,
            status: status,
            operation: operation,
            entityTable: entityTable,
            recordId: recordId,
            payload: payload,
            errorReason: errorReason,
            sourceDeviceId: sourceDeviceId,
            sourceUserId: sourceUserId,
            retryCount: retryCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$SyncJournalTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncJournalTable> {
  $$SyncJournalTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get clientOpId => $state.composableBuilder(
      column: $state.table.clientOpId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get serverSeq => $state.composableBuilder(
      column: $state.table.serverSeq,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get entityTable => $state.composableBuilder(
      column: $state.table.entityTable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorReason => $state.composableBuilder(
      column: $state.table.errorReason,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceDeviceId => $state.composableBuilder(
      column: $state.table.sourceDeviceId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceUserId => $state.composableBuilder(
      column: $state.table.sourceUserId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncJournalTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncJournalTable> {
  $$SyncJournalTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get clientOpId => $state.composableBuilder(
      column: $state.table.clientOpId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get serverSeq => $state.composableBuilder(
      column: $state.table.serverSeq,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get direction => $state.composableBuilder(
      column: $state.table.direction,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get entityTable => $state.composableBuilder(
      column: $state.table.entityTable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorReason => $state.composableBuilder(
      column: $state.table.errorReason,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceDeviceId => $state.composableBuilder(
      column: $state.table.sourceDeviceId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceUserId => $state.composableBuilder(
      column: $state.table.sourceUserId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CommissionLogsTableCreateCompanionBuilder = CommissionLogsCompanion
    Function({
  required String id,
  required String tenantId,
  required String saleId,
  required String employeeId,
  Value<String?> productId,
  Value<double> saleAmount,
  required double commissionAmount,
  required String commissionType,
  Value<bool> isPaid,
  Value<DateTime?> paidAt,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$CommissionLogsTableUpdateCompanionBuilder = CommissionLogsCompanion
    Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> saleId,
  Value<String> employeeId,
  Value<String?> productId,
  Value<double> saleAmount,
  Value<double> commissionAmount,
  Value<String> commissionType,
  Value<bool> isPaid,
  Value<DateTime?> paidAt,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$CommissionLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CommissionLogsTable,
    CommissionLog,
    $$CommissionLogsTableFilterComposer,
    $$CommissionLogsTableOrderingComposer,
    $$CommissionLogsTableCreateCompanionBuilder,
    $$CommissionLogsTableUpdateCompanionBuilder> {
  $$CommissionLogsTableTableManager(
      _$AppDatabase db, $CommissionLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CommissionLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CommissionLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> saleId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<double> saleAmount = const Value.absent(),
            Value<double> commissionAmount = const Value.absent(),
            Value<String> commissionType = const Value.absent(),
            Value<bool> isPaid = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CommissionLogsCompanion(
            id: id,
            tenantId: tenantId,
            saleId: saleId,
            employeeId: employeeId,
            productId: productId,
            saleAmount: saleAmount,
            commissionAmount: commissionAmount,
            commissionType: commissionType,
            isPaid: isPaid,
            paidAt: paidAt,
            synced: synced,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String saleId,
            required String employeeId,
            Value<String?> productId = const Value.absent(),
            Value<double> saleAmount = const Value.absent(),
            required double commissionAmount,
            required String commissionType,
            Value<bool> isPaid = const Value.absent(),
            Value<DateTime?> paidAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CommissionLogsCompanion.insert(
            id: id,
            tenantId: tenantId,
            saleId: saleId,
            employeeId: employeeId,
            productId: productId,
            saleAmount: saleAmount,
            commissionAmount: commissionAmount,
            commissionType: commissionType,
            isPaid: isPaid,
            paidAt: paidAt,
            synced: synced,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$CommissionLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CommissionLogsTable> {
  $$CommissionLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get saleAmount => $state.composableBuilder(
      column: $state.table.saleAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get commissionAmount => $state.composableBuilder(
      column: $state.table.commissionAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get commissionType => $state.composableBuilder(
      column: $state.table.commissionType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isPaid => $state.composableBuilder(
      column: $state.table.isPaid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get paidAt => $state.composableBuilder(
      column: $state.table.paidAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CommissionLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CommissionLogsTable> {
  $$CommissionLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get saleAmount => $state.composableBuilder(
      column: $state.table.saleAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get commissionAmount => $state.composableBuilder(
      column: $state.table.commissionAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get commissionType => $state.composableBuilder(
      column: $state.table.commissionType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isPaid => $state.composableBuilder(
      column: $state.table.isPaid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get paidAt => $state.composableBuilder(
      column: $state.table.paidAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String tenantId,
  required String category,
  Value<String> description,
  required double amount,
  Value<String?> employeeId,
  Value<String?> locationId,
  Value<String?> receiptUrl,
  Value<String?> notes,
  Value<bool> synced,
  required DateTime expenseDate,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> category,
  Value<String> description,
  Value<double> amount,
  Value<String?> employeeId,
  Value<String?> locationId,
  Value<String?> receiptUrl,
  Value<String?> notes,
  Value<bool> synced,
  Value<DateTime> expenseDate,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExpensesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExpensesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> employeeId = const Value.absent(),
            Value<String?> locationId = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime> expenseDate = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            tenantId: tenantId,
            category: category,
            description: description,
            amount: amount,
            employeeId: employeeId,
            locationId: locationId,
            receiptUrl: receiptUrl,
            notes: notes,
            synced: synced,
            expenseDate: expenseDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String category,
            Value<String> description = const Value.absent(),
            required double amount,
            Value<String?> employeeId = const Value.absent(),
            Value<String?> locationId = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            required DateTime expenseDate,
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            tenantId: tenantId,
            category: category,
            description: description,
            amount: amount,
            employeeId: employeeId,
            locationId: locationId,
            receiptUrl: receiptUrl,
            notes: notes,
            synced: synced,
            expenseDate: expenseDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$ExpensesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get receiptUrl => $state.composableBuilder(
      column: $state.table.receiptUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expenseDate => $state.composableBuilder(
      column: $state.table.expenseDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExpensesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get employeeId => $state.composableBuilder(
      column: $state.table.employeeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get locationId => $state.composableBuilder(
      column: $state.table.locationId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get receiptUrl => $state.composableBuilder(
      column: $state.table.receiptUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expenseDate => $state.composableBuilder(
      column: $state.table.expenseDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DiscountsTableCreateCompanionBuilder = DiscountsCompanion Function({
  required String id,
  required String tenantId,
  required String name,
  required String type,
  required String discountMode,
  required double value,
  Value<String?> productId,
  Value<String?> category,
  Value<String?> customerType,
  Value<String?> conditions,
  Value<bool> isActive,
  Value<DateTime?> expiresAt,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$DiscountsTableUpdateCompanionBuilder = DiscountsCompanion Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> name,
  Value<String> type,
  Value<String> discountMode,
  Value<double> value,
  Value<String?> productId,
  Value<String?> category,
  Value<String?> customerType,
  Value<String?> conditions,
  Value<bool> isActive,
  Value<DateTime?> expiresAt,
  Value<bool> synced,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$DiscountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiscountsTable,
    Discount,
    $$DiscountsTableFilterComposer,
    $$DiscountsTableOrderingComposer,
    $$DiscountsTableCreateCompanionBuilder,
    $$DiscountsTableUpdateCompanionBuilder> {
  $$DiscountsTableTableManager(_$AppDatabase db, $DiscountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DiscountsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DiscountsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> discountMode = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> productId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> customerType = const Value.absent(),
            Value<String?> conditions = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DiscountsCompanion(
            id: id,
            tenantId: tenantId,
            name: name,
            type: type,
            discountMode: discountMode,
            value: value,
            productId: productId,
            category: category,
            customerType: customerType,
            conditions: conditions,
            isActive: isActive,
            expiresAt: expiresAt,
            synced: synced,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String name,
            required String type,
            required String discountMode,
            required double value,
            Value<String?> productId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> customerType = const Value.absent(),
            Value<String?> conditions = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DiscountsCompanion.insert(
            id: id,
            tenantId: tenantId,
            name: name,
            type: type,
            discountMode: discountMode,
            value: value,
            productId: productId,
            category: category,
            customerType: customerType,
            conditions: conditions,
            isActive: isActive,
            expiresAt: expiresAt,
            synced: synced,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$DiscountsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DiscountsTable> {
  $$DiscountsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get discountMode => $state.composableBuilder(
      column: $state.table.discountMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerType => $state.composableBuilder(
      column: $state.table.customerType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get conditions => $state.composableBuilder(
      column: $state.table.conditions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DiscountsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DiscountsTable> {
  $$DiscountsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get discountMode => $state.composableBuilder(
      column: $state.table.discountMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productId => $state.composableBuilder(
      column: $state.table.productId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerType => $state.composableBuilder(
      column: $state.table.customerType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get conditions => $state.composableBuilder(
      column: $state.table.conditions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isActive => $state.composableBuilder(
      column: $state.table.isActive,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiresAt => $state.composableBuilder(
      column: $state.table.expiresAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get synced => $state.composableBuilder(
      column: $state.table.synced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LoyaltyLedgerTableCreateCompanionBuilder = LoyaltyLedgerCompanion
    Function({
  required String id,
  required String tenantId,
  required String customerId,
  Value<String?> saleId,
  required double points,
  required String type,
  Value<String?> notes,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$LoyaltyLedgerTableUpdateCompanionBuilder = LoyaltyLedgerCompanion
    Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> customerId,
  Value<String?> saleId,
  Value<double> points,
  Value<String> type,
  Value<String?> notes,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$LoyaltyLedgerTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoyaltyLedgerTable,
    LoyaltyLedgerData,
    $$LoyaltyLedgerTableFilterComposer,
    $$LoyaltyLedgerTableOrderingComposer,
    $$LoyaltyLedgerTableCreateCompanionBuilder,
    $$LoyaltyLedgerTableUpdateCompanionBuilder> {
  $$LoyaltyLedgerTableTableManager(_$AppDatabase db, $LoyaltyLedgerTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LoyaltyLedgerTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LoyaltyLedgerTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String?> saleId = const Value.absent(),
            Value<double> points = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoyaltyLedgerCompanion(
            id: id,
            tenantId: tenantId,
            customerId: customerId,
            saleId: saleId,
            points: points,
            type: type,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            required String customerId,
            Value<String?> saleId = const Value.absent(),
            required double points,
            required String type,
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoyaltyLedgerCompanion.insert(
            id: id,
            tenantId: tenantId,
            customerId: customerId,
            saleId: saleId,
            points: points,
            type: type,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$LoyaltyLedgerTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LoyaltyLedgerTable> {
  $$LoyaltyLedgerTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LoyaltyLedgerTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LoyaltyLedgerTable> {
  $$LoyaltyLedgerTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customerId => $state.composableBuilder(
      column: $state.table.customerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get saleId => $state.composableBuilder(
      column: $state.table.saleId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PrintSettingsTableCreateCompanionBuilder = PrintSettingsCompanion
    Function({
  required String id,
  required String tenantId,
  Value<String> paperSize,
  Value<String?> printerName,
  Value<String> printerType,
  Value<String> invoiceTemplate,
  Value<bool> autoPrint,
  Value<bool> showLogo,
  Value<bool> showBarcode,
  Value<bool> showQr,
  Value<bool> showTax,
  Value<bool> showDiscount,
  Value<bool> showCustomerAddress,
  Value<double> marginTop,
  Value<double> marginLeft,
  Value<double> fontSize,
  Value<double> lineSpacing,
  Value<String> thankYouMessage,
  Value<String?> returnPolicy,
  Value<String?> socialLinks,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$PrintSettingsTableUpdateCompanionBuilder = PrintSettingsCompanion
    Function({
  Value<String> id,
  Value<String> tenantId,
  Value<String> paperSize,
  Value<String?> printerName,
  Value<String> printerType,
  Value<String> invoiceTemplate,
  Value<bool> autoPrint,
  Value<bool> showLogo,
  Value<bool> showBarcode,
  Value<bool> showQr,
  Value<bool> showTax,
  Value<bool> showDiscount,
  Value<bool> showCustomerAddress,
  Value<double> marginTop,
  Value<double> marginLeft,
  Value<double> fontSize,
  Value<double> lineSpacing,
  Value<String> thankYouMessage,
  Value<String?> returnPolicy,
  Value<String?> socialLinks,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$PrintSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrintSettingsTable,
    PrintSetting,
    $$PrintSettingsTableFilterComposer,
    $$PrintSettingsTableOrderingComposer,
    $$PrintSettingsTableCreateCompanionBuilder,
    $$PrintSettingsTableUpdateCompanionBuilder> {
  $$PrintSettingsTableTableManager(_$AppDatabase db, $PrintSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PrintSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PrintSettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> paperSize = const Value.absent(),
            Value<String?> printerName = const Value.absent(),
            Value<String> printerType = const Value.absent(),
            Value<String> invoiceTemplate = const Value.absent(),
            Value<bool> autoPrint = const Value.absent(),
            Value<bool> showLogo = const Value.absent(),
            Value<bool> showBarcode = const Value.absent(),
            Value<bool> showQr = const Value.absent(),
            Value<bool> showTax = const Value.absent(),
            Value<bool> showDiscount = const Value.absent(),
            Value<bool> showCustomerAddress = const Value.absent(),
            Value<double> marginTop = const Value.absent(),
            Value<double> marginLeft = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> lineSpacing = const Value.absent(),
            Value<String> thankYouMessage = const Value.absent(),
            Value<String?> returnPolicy = const Value.absent(),
            Value<String?> socialLinks = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrintSettingsCompanion(
            id: id,
            tenantId: tenantId,
            paperSize: paperSize,
            printerName: printerName,
            printerType: printerType,
            invoiceTemplate: invoiceTemplate,
            autoPrint: autoPrint,
            showLogo: showLogo,
            showBarcode: showBarcode,
            showQr: showQr,
            showTax: showTax,
            showDiscount: showDiscount,
            showCustomerAddress: showCustomerAddress,
            marginTop: marginTop,
            marginLeft: marginLeft,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            thankYouMessage: thankYouMessage,
            returnPolicy: returnPolicy,
            socialLinks: socialLinks,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tenantId,
            Value<String> paperSize = const Value.absent(),
            Value<String?> printerName = const Value.absent(),
            Value<String> printerType = const Value.absent(),
            Value<String> invoiceTemplate = const Value.absent(),
            Value<bool> autoPrint = const Value.absent(),
            Value<bool> showLogo = const Value.absent(),
            Value<bool> showBarcode = const Value.absent(),
            Value<bool> showQr = const Value.absent(),
            Value<bool> showTax = const Value.absent(),
            Value<bool> showDiscount = const Value.absent(),
            Value<bool> showCustomerAddress = const Value.absent(),
            Value<double> marginTop = const Value.absent(),
            Value<double> marginLeft = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> lineSpacing = const Value.absent(),
            Value<String> thankYouMessage = const Value.absent(),
            Value<String?> returnPolicy = const Value.absent(),
            Value<String?> socialLinks = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrintSettingsCompanion.insert(
            id: id,
            tenantId: tenantId,
            paperSize: paperSize,
            printerName: printerName,
            printerType: printerType,
            invoiceTemplate: invoiceTemplate,
            autoPrint: autoPrint,
            showLogo: showLogo,
            showBarcode: showBarcode,
            showQr: showQr,
            showTax: showTax,
            showDiscount: showDiscount,
            showCustomerAddress: showCustomerAddress,
            marginTop: marginTop,
            marginLeft: marginLeft,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            thankYouMessage: thankYouMessage,
            returnPolicy: returnPolicy,
            socialLinks: socialLinks,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$PrintSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PrintSettingsTable> {
  $$PrintSettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get paperSize => $state.composableBuilder(
      column: $state.table.paperSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get printerName => $state.composableBuilder(
      column: $state.table.printerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get printerType => $state.composableBuilder(
      column: $state.table.printerType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get invoiceTemplate => $state.composableBuilder(
      column: $state.table.invoiceTemplate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get autoPrint => $state.composableBuilder(
      column: $state.table.autoPrint,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showLogo => $state.composableBuilder(
      column: $state.table.showLogo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showBarcode => $state.composableBuilder(
      column: $state.table.showBarcode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showQr => $state.composableBuilder(
      column: $state.table.showQr,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showTax => $state.composableBuilder(
      column: $state.table.showTax,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showDiscount => $state.composableBuilder(
      column: $state.table.showDiscount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get showCustomerAddress => $state.composableBuilder(
      column: $state.table.showCustomerAddress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get marginTop => $state.composableBuilder(
      column: $state.table.marginTop,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get marginLeft => $state.composableBuilder(
      column: $state.table.marginLeft,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get fontSize => $state.composableBuilder(
      column: $state.table.fontSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lineSpacing => $state.composableBuilder(
      column: $state.table.lineSpacing,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get thankYouMessage => $state.composableBuilder(
      column: $state.table.thankYouMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get returnPolicy => $state.composableBuilder(
      column: $state.table.returnPolicy,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get socialLinks => $state.composableBuilder(
      column: $state.table.socialLinks,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PrintSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PrintSettingsTable> {
  $$PrintSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tenantId => $state.composableBuilder(
      column: $state.table.tenantId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get paperSize => $state.composableBuilder(
      column: $state.table.paperSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get printerName => $state.composableBuilder(
      column: $state.table.printerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get printerType => $state.composableBuilder(
      column: $state.table.printerType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get invoiceTemplate => $state.composableBuilder(
      column: $state.table.invoiceTemplate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get autoPrint => $state.composableBuilder(
      column: $state.table.autoPrint,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showLogo => $state.composableBuilder(
      column: $state.table.showLogo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showBarcode => $state.composableBuilder(
      column: $state.table.showBarcode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showQr => $state.composableBuilder(
      column: $state.table.showQr,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showTax => $state.composableBuilder(
      column: $state.table.showTax,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showDiscount => $state.composableBuilder(
      column: $state.table.showDiscount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get showCustomerAddress => $state.composableBuilder(
      column: $state.table.showCustomerAddress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get marginTop => $state.composableBuilder(
      column: $state.table.marginTop,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get marginLeft => $state.composableBuilder(
      column: $state.table.marginLeft,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get fontSize => $state.composableBuilder(
      column: $state.table.fontSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lineSpacing => $state.composableBuilder(
      column: $state.table.lineSpacing,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get thankYouMessage => $state.composableBuilder(
      column: $state.table.thankYouMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get returnPolicy => $state.composableBuilder(
      column: $state.table.returnPolicy,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get socialLinks => $state.composableBuilder(
      column: $state.table.socialLinks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$CommissionRulesTableTableManager get commissionRules =>
      $$CommissionRulesTableTableManager(_db, _db.commissionRules);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncJournalTableTableManager get syncJournal =>
      $$SyncJournalTableTableManager(_db, _db.syncJournal);
  $$CommissionLogsTableTableManager get commissionLogs =>
      $$CommissionLogsTableTableManager(_db, _db.commissionLogs);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$DiscountsTableTableManager get discounts =>
      $$DiscountsTableTableManager(_db, _db.discounts);
  $$LoyaltyLedgerTableTableManager get loyaltyLedger =>
      $$LoyaltyLedgerTableTableManager(_db, _db.loyaltyLedger);
  $$PrintSettingsTableTableManager get printSettings =>
      $$PrintSettingsTableTableManager(_db, _db.printSettings);
}
