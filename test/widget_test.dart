import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_kebaya/main_common.dart';
import 'package:flutter_kebaya/config/app_config.dart';
import 'package:flutter_kebaya/providers/auth_provider.dart';
import 'package:flutter_kebaya/providers/rental_provider.dart';
import 'package:flutter_kebaya/providers/job_order_provider.dart';
import 'package:flutter_kebaya/providers/inventory_provider.dart';
import 'package:flutter_kebaya/models/rental.dart';
import 'package:flutter_kebaya/models/job_order.dart';
import 'package:flutter_kebaya/models/user.dart';
import 'package:flutter_kebaya/models/inventory_item.dart';
import 'package:flutter_kebaya/screens/schedule_tab.dart';
import 'package:flutter_kebaya/screens/mix_match_tab.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockAuthProvider extends AuthProvider {
  final User? mockUser;
  MockAuthProvider(this.mockUser);

  @override
  User? get user => mockUser;

  @override
  bool get isAuthenticated => mockUser != null;
}

class MockRentalProvider extends RentalProvider {
  final List<Rental> mockRentals;
  MockRentalProvider(this.mockRentals);

  @override
  List<Rental> get rentals => mockRentals;

  @override
  Future<void> fetchRentals() async {}
}

class MockJobOrderProvider extends JobOrderProvider {
  final List<JobOrder> mockJobs;
  MockJobOrderProvider(this.mockJobs);

  @override
  List<JobOrder> get jobs => mockJobs;

  @override
  Future<void> fetchJobOrders() async {}
}

class MockInventoryProvider extends InventoryProvider {
  final List<InventoryItem> mockItems;
  MockInventoryProvider(this.mockItems);

  @override
  List<InventoryItem> get items => mockItems;

  @override
  Future<void> fetchInventory() async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id', null);
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    final mockConfig = AppConfig(
      apiBaseUrl: 'http://localhost',
      environmentName: 'Test',
    );

    await tester.pumpWidget(MyApp(config: mockConfig));

    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('ScheduleTab render test', (WidgetTester tester) async {
    final now = DateTime.now();
    final testUser = User(id: 1, name: 'Caroline Lauda', email: 'owner@lauda.com', roles: ['owner']);
    
    final testRental = Rental(
      id: 1,
      invoiceNumber: 'INV-001',
      customerName: 'Test Customer',
      customerPhone: '123456789',
      eventDate: now,
      status: 'booked',
      groupOrderName: 'Test Group',
      totalAmount: 500000.0,
      beforePhotos: [],
      afterPhotos: [],
      items: [
        RentalComponent(
          id: 1,
          inventoryItemId: 1,
          name: 'Kebaya Gold',
          sku: 'KB-GLD-M',
          type: 'top',
          size: 'M',
          color: 'Gold',
          rentalPrice: 250000.0,
        ),
      ],
      createdAt: now,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: MockAuthProvider(testUser)),
          ChangeNotifierProvider<RentalProvider>.value(value: MockRentalProvider([testRental])),
          ChangeNotifierProvider<JobOrderProvider>.value(value: MockJobOrderProvider([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ScheduleTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pemesanan Aktif (1)'), findsOneWidget);
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('Faktur: INV-001'), findsOneWidget);
    expect(find.textContaining('Kebaya Gold'), findsOneWidget);
  });

  testWidgets('MixMatchTab render and select test', (WidgetTester tester) async {
    final testUser = User(id: 1, name: 'Caroline Lauda', email: 'owner@lauda.com', roles: ['owner']);
    
    final topItem = InventoryItem(
      id: 1,
      name: 'Brocade Top Spec',
      sku: 'KB-TOP-M',
      type: 'top',
      size: 'M',
      color: 'Gold',
      rentalRate: 150000.0,
      imagePath: '',
    );
    
    final bottomItem = InventoryItem(
      id: 2,
      name: 'Songket Bottom Spec',
      sku: 'KB-BOT-M',
      type: 'bottom',
      size: 'M',
      color: 'Wine',
      rentalRate: 100000.0,
      imagePath: '',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: MockAuthProvider(testUser)),
          ChangeNotifierProvider<RentalProvider>.value(value: MockRentalProvider([])),
          ChangeNotifierProvider<InventoryProvider>.value(value: MockInventoryProvider([topItem, bottomItem])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MixMatchTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify lists are rendered
    expect(find.text('ATASAN (TOPS)'), findsOneWidget);
    expect(find.text('Brocade Top Spec'), findsOneWidget);

    // Verify initial placeholders
    expect(find.text('Pilih Atasan'), findsOneWidget);
    expect(find.text('Pilih Bawahan'), findsOneWidget);

    // Select Top
    await tester.tap(find.text('Brocade Top Spec'));
    await tester.pumpAndSettle();

    // Switch to Bawahan tab
    await tester.tap(find.widgetWithText(Tab, 'Bawahan'));
    await tester.pumpAndSettle();

    expect(find.text('BAWAHAN (BOTTOMS)'), findsOneWidget);
    expect(find.text('Songket Bottom Spec'), findsOneWidget);

    // Select Bottom
    await tester.tap(find.text('Songket Bottom Spec'));
    await tester.pumpAndSettle();

    // Verify total price is displayed (for owner user)
    expect(find.text('Rp 250.000'), findsOneWidget);
  });
}
