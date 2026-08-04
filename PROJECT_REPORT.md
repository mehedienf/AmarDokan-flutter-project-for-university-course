# Amar Dokan — Project Report

> **Amar Dokan** is a Flutter-based, cross-platform Inventory & Sales
> Management app designed for small and medium shop owners. It uses Firebase
> (Auth + Firestore + Storage) as the backend and Provider for state
> management, running on Android, iOS, Web, macOS, Linux, and Windows from
> a single codebase.

---

## 1. Introduction

- **App name:** Amar Dokan (Inventory & Sales Management App)
- **Technology:** Flutter (Dart SDK `^3.11.1`), Material 3, Firebase
- **Target audience:** Shop owners who want a single app to manage stock,
  sales, purchases, customers/suppliers, and basic accounting.
- **Platforms:** Android, iOS, Web, macOS, Linux, Windows.

---

## 2. Codebase Statistics

| Metric | Value |
| --- | --- |
| Total Dart files | **86** |
| Total lines of code | **22,428** |
| Largest screen | `add_purchase_screen.dart` (1,283 lines) |
| Model files | 11 (Product, Sale, SaleItem, Purchase, PurchaseItem, Customer, Supplier, Transaction, User, ReportSummary, DashboardStats) |

---

## 3. Technology Stack

### 3.1 Dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
| --- | --- | --- |
| `flutter` (SDK) | 3.11.1 | UI framework |
| `provider` | ^6.1.5 | State management |
| `firebase_core` | ^3.12.1 | Firebase init |
| `firebase_auth` | ^5.5.1 | Email/Google sign-in |
| `cloud_firestore` | ^5.6.5 | NoSQL database |
| `firebase_storage` | ^12.4.4 | Image upload |
| `google_sign_in` | ^6.3.0 | Google account auth |
| `intl` | ^0.19.0 | Date/number/currency formatting |
| `uuid` | ^4.5.1 | Document ID generation |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `flutter_lints` (dev) | ^6.0.0 | Static analysis |

---

## 4. Architecture

The project follows a **feature-first layered architecture**. Each feature
lives in its own folder and is split internally into three layers:

```
features/<feature_name>/
├── data/
│   ├── models/        # POJOs + Firestore serialization
│   └── services/      # Firebase and aggregation logic
├── presentation/
│   ├── screens/       # Full-page UI
│   └── widgets/       # Reusable widgets
└── providers/         # ChangeNotifier (Provider)
```

### 4.1 Layer responsibilities

1. **Models** — Immutable data classes with `fromFirestore()` and
   `toFirestore()` mappers, plus business getters (e.g. `isLowStock`,
   `balance`, `totalProfit`).
2. **Services** — Firebase API calls, aggregations, and filter helpers.
3. **Providers** — `ChangeNotifier`s that expose reactive state to the UI.
4. **Presentation** — UI only. Reads state from providers and calls
   services for actions.

### 4.2 App Boot Flow (`main.dart`)

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

runApp(MultiProvider(providers: [
  AuthProvider()..initialize(),
  InventoryProvider(),
  CustomerProvider(),
  SupplierProvider(),
  SaleProvider(),
  PurchaseProvider(),
  TransactionProvider(),
  ReportProvider(),         // after source providers
  DashboardProvider(),      // after source providers
  NavigationProvider(),
], child: MyApp()));
```

`AuthGate` toggles between three states:

- `!isInitialized` → **Splash**
- `!isAuthenticated` → **LoginScreen**
- otherwise → **MainApp** (Dashboard + Inventory + Sales + Report tabs)

On sign-out the root navigator flushes any pushed routes so back-navigation
cannot reveal screens that still expect an authenticated user.

---

## 5. Feature Modules

### 5.1 Auth
**Location:** `features/auth/`

- Sign-in methods: Email/Password, **Google Sign-In**, password reset.
- `AuthProvider` subscribes to FirebaseAuth's `authStateChanges` stream and
  keeps the Firestore user profile in sync with the current uid.
- Friendly error mapping for `invalid-credential`, `user-not-found`,
  `too-many-requests`, etc.
- `GoogleSignInCancelled` is caught separately so it is never shown to the
  user as an error.

### 5.2 Dashboard
**Location:** `features/dashboard/`

- Today's KPI cards: revenue, profit, items sold, sales count.
- Today's cash in / cash out snapshot.
- 5 most recent sales + top-5 low-stock products.
- All aggregation is **in-memory**: `DashboardService` takes the four source
  providers and computes a fresh `DashboardStats`. No extra Firestore reads.

### 5.3 Inventory
**Location:** `features/inventory/`

- `ProductModel` fields: `name`, `sku`, `category`, `purchasePrice`,
  `sellingPrice`, `stock`, `lowStockThreshold`, `description`, `imageUrl`,
  `createdAt`, `updatedAt`.
- Derived getters: `isInStock`, `isLowStock`, `isOutOfStock`,
  `profitPerUnit`, `totalPotentialProfit`, `totalStockValue`,
  `profitMarginPercentage`, `stockStatus`.
- Stock synchronization:
  - **Sale** → stock decreases.
  - **Purchase** → stock increases atomically via `FieldValue.increment`,
    and `purchasePrice` / `sellingPrice` are overwritten with the latest
    unit cost.
  - **Purchase delete** → stock decreases (clamped to 0).
- Default low-stock threshold is 5; out-of-stock is counted separately.

### 5.4 Sales
**Location:** `features/sales/`

- `SaleModel` is a multi-item sale document.
- Money fields: `subtotal`, `itemDiscount`, `extraDiscount`, `tax`, `total`,
  `paidAmount`, `changeAmount`.
- Status: `completed` / `cancelled`. Payment status: `paid` / `partial` /
  `unpaid`.
- Payment method display: `cash`, `card`, `mobile_banking` (incl. bKash,
  Nagad), `bank_transfer`, `credit`.
- Profit is snapshotted per `SaleItemModel` at sale time, so historical
  profit remains stable even if cost-per-unit changes later.
- Filters: invoice number, customer, date range, payment status.

### 5.5 Purchase
**Location:** `features/purchase/`

- `PurchaseModel` is supplier-based with embedded items.
- **Side effect:** `addPurchase()` runs a Firestore transaction per item,
  increments stock atomically with `FieldValue.increment`, and overwrites
  the latest `purchasePrice` / `sellingPrice`.
- `deletePurchase()` decreases stock for every item (clamped to 0) and
  uses `clamp(0, 2^31)` to guard against negative stock.
- Outstanding payable: `(total - paidAmount).clamp(0, ∞)`.
- Invoice auto-generation: `PUR-000001` format, count-based.

### 5.6 Customers and Suppliers
**Location:** `features/customers/`, `features/suppliers/`

- List + Add + Edit + Details screens.
- Each sale/purchase denormalizes the linked customer/supplier ID and name,
  so detail screens render without re-reading the parent doc.

### 5.7 Accounting
**Location:** `features/accounting/`

- `TransactionModel` uses two enums:
  - `TransactionType.income` / `expense`
  - `TransactionCategory` (19 values): `salesRevenue`, `otherIncome`,
    `capitalInjection`, `loanReceived`, `customerPayment`, `refundReceived`,
    `purchasePayment`, `rent`, `salary`, `utilities`, `transport`,
    `marketing`, `maintenance`, `tax`, `ownerWithdrawal`, `loanRepayment`,
    `supplierPayment`, `refundGiven`, `otherExpense`.
- **Reference link:** each transaction can carry a `referenceId` and
  `referenceType` (`sale` / `purchase` / `customer` / `supplier`) so it
  can be tied to a parent document.
- Display helpers: `signedAmount`, `displayPaymentMethod`, and
  category-specific `label`, `shortLabel`, `iconName`.
- A separate Cash Summary screen aggregates incoming vs outgoing totals.

### 5.8 Reports
**Location:** `features/report/`

This is the most data-rich feature. The stateless `ReportService.compute()`
method aggregates everything below for a single `ReportPeriod`:

| Section | Fields |
| --- | --- |
| **Sales** | totalRevenue, totalDiscount, totalTax, completedSales, cancelledSales, averageSaleValue, totalItemsSold, totalProfit, outstandingReceivables |
| **Purchases** | totalPurchaseAmount, totalPurchasePaid, outstandingPayables, totalPurchases |
| **Transactions** | otherIncome, otherExpenses, income/expense count, expensesByCategory |
| **Inventory snapshot** | totalProducts, totalStockUnits, totalInventoryValue, totalInventoryPotentialProfit, lowStockCount, outOfStockCount |
| **Cash flow** | totalCashIn = revenue + otherIncome; totalCashOut = purchasePaid + otherExpenses; netCashFlow |
| **Trends & rankings** | dailySalesTrend, dailyProfitTrend (daily buckets), topProducts, topCustomers, paymentMethodBreakdown, topCategoriesByProfit |

Convenience getters: `profitMargin`, `salesToPurchaseRatio`, `hasAnyData`.
`DailyDataPoint.label` picks smart tick labels (`Mon`, `5/12`, `5/26`) based
on the time distance from today.

### 5.9 Auth Gate and Navigation (core)
**Location:** `core/`

- `app_theme.dart` — Material 3 light/dark themes built with
  `ColorScheme.fromSeed`.
- `AppColors` palette: primary, secondary, surface, error, textPrimary,
  etc.
- `NavigationProvider` holds the current bottom-nav index. The shell uses
  `IndexedStack`, so tab switches preserve list scroll state.
- Theme mode: `ThemeMode.system`.

### 5.10 Shared
**Location:** `shared/widgets/`

- `BottomNavbar`, `AppDrawer`, and reusable custom widgets (custom button,
  text field, loading indicator, empty state, common dialogs).

---

## 6. Data Model and Firestore Schema

```
users/{uid}                                  → User profile (idempotent)
users/{uid}/products/{productId}             → Inventory
users/{uid}/customers/{customerId}           → Customer
users/{uid}/suppliers/{supplierId}           → Supplier
users/{uid}/sales/{saleId}                   → Sale (with embedded items[])
users/{uid}/purchases/{purchaseId}           → Purchase (with embedded items[])
users/{uid}/transactions/{transactionId}     → Accounting entry
```

Models parse Firestore documents null-safely via `fromFirestore()` and
handle `Timestamp` ↔ `DateTime` conversion internally. All models override
`copyWith()`, `==`, and `hashCode`.

---

## 7. Security

`firestore.rules` enforces a **per-user subtree lockdown**:

- `users/{uid}` is read/written/updated/deleted only by the owner.
- Any signed-in user can create their own profile doc (idempotent).
- Every sub-collection under `users/{uid}/**` is readable/writable only by
  the owner.
- A default-deny rule covers anything else.

**API key hygiene:** Firebase config is shipped with the project
(`lib/firebase_options.dart`). For production web builds, App Check +
reCAPTCHA should be added.

---

## 8. Core Business Logic Summary

| Operation | Stock effect | Reference |
| --- | --- | --- |
| New purchase | `FieldValue.increment(qty)` + latest cost/selling price update | `purchase_service.dart:106` |
| Delete purchase | Stock decrement, clamped to 0 | `purchase_service.dart:167` |
| Sale | Per-item stock decrement | `sales_service.dart` (same pattern) |
| Cost change | Per-sale profit is not recomputed (item-level snapshot) | `sale_item_model.dart` |
| Outstanding receivable | Sum of `balance` over completed sales | `report_service.dart:52` |
| Net cash flow | `(Revenue + OtherIncome) − (PurchasePaid + OtherExpenses)` | `report_service.dart:121` |

---

## 9. Provider Registration Order

The order in `main.dart` is significant — it prevents dependency cycles:

```
Auth
↓
Inventory, Customer, Supplier
↓
Sale, Purchase, Transaction   ← source of truth
↓
Report   (reads from Sales/Purchase/Transaction/Inventory)
↓
Dashboard (reads from Sales/Purchase/Transaction/Inventory)
↓
Navigation
```

---

## 10. UI/UX Highlights

- **Material 3** accent generated from `ColorScheme.fromSeed`; both light
  and dark themes.
- `IndexedStack` under the bottom navigation keeps list scroll state across
  tab switches.
- Code mixes inline Bangla comments with English labels, keeping it both
  educational and production-friendly.
- Login and signup screens include form validation and friendly error
  mapping.
- `GoogleSignInCancelled` is swallowed silently for a smoother UX.

---

## 11. Platform Support

| Platform | Folder | Status |
| --- | --- | --- |
| Android | `android/` | Active build, `google-services.json` configured |
| iOS | `ios/Runner` | Runner.xcodeproj + `GoogleService-Info.plist` present |
| Web | `web/` | `index.html`, manifest, icons |
| macOS | `macos/` | Runner scaffold |
| Linux | `linux/` | CMake config |
| Windows | `windows/` | CMake config |

---

## 12. Project Status

### ✅ Implemented
1. Multi-platform Flutter app shell.
2. Firebase Auth (Email/Password + Google + Password Reset).
3. Inventory CRUD with low-stock detection and image support.
4. Multi-item sales with dynamic pricing, discount, tax, and payment status.
5. Purchase with auto stock/price update and invoice auto-generation.
6. Customer and supplier management with purchase history.
7. Accounting with 19 income/expense categories and reference linking.
8. Dashboard today-snapshot, recent sales, and low-stock top-5.
9. Report with 30+ KPIs across sales, purchase, transaction, inventory, and
   cash flow.
10. Per-user Firestore security rules.
11. Light + dark Material 3 themes.

### ⚠️ Suggested Improvements
- **Offline support:** enable Firestore offline persistence
  (`enableIndexedDbPersistence` etc.).
- **Testing:** add service-level unit tests; only the default
  `flutter_test` scaffold is present today.
- **CI:** run lint + tests on GitHub Actions.
- **Image upload pipeline:** `imageUrl` is on the model but the
  firebase_storage upload flow is not yet wired in.
- **Pagination:** lists currently use `count().get()`; add lazy UI
  pagination for very large catalogues.
- **Notifications:** push alerts when items hit low-stock threshold.
- **Export:** PDF/CSV export of reports.
- **Role-based access:** multi-staff RBAC inside one shop.
- **Localization:** full Bangla locale switch (`intl` is already available).
- **Barcode scanner:** SKU field exists; add `mobile_scanner` for
  scan-to-add flows.
- **App Check + reCAPTCHA** for production web builds.

---

## 13. Screen Inventory (Reference)

| Feature | Screens |
| --- | --- |
| Auth | Login, Signup, Forgot Password |
| Dashboard | DashboardScreen |
| Inventory | InventoryList, AddProduct, EditProduct, ProductDetails |
| Sales | SalesList, CreateSale, SaleDetails |
| Purchase | PurchaseList, AddPurchase, PurchaseDetails |
| Customers | CustomersList, AddCustomer, EditCustomer, CustomerDetails |
| Suppliers | SuppliersList, AddSupplier, EditSupplier, SupplierDetails |
| Accounting | Accounting, AddTransaction, TransactionDetails, CashSummary |
| Reports | Report (Sales / Purchase / Profit tabs) |
| Settings | Drawer-based entry |

> `add_purchase_screen.dart` (1,283 LOC) and `create_sale_screen.dart`
> (925 LOC) are the most complex screens — dynamic multi-item forms,
> supplier/customer pickers, live total recomputation, and validation.

---

## 14. Conclusion

**Amar Dokan** is a well-organized Flutter + Firebase application that
delivers:

- A clear **layered architecture** (`data / presentation / providers`).
- **Type-safe Firestore mapping** with `copyWith`, equality, and derived
  getters.
- **Stock consistency** through atomic transactions and clamps.
- **Granular security** with per-uid deny-by-default rules.
- **Rich analytics** (30+ KPIs, daily buckets, top-N rankings).
- **Multi-platform reach** (Android, iOS, Web, and Desktop).

The app already covers the day-to-day needs of a small shop — stock,
sales, purchase, receivables/payables, and profit — and with the
improvements listed in section 12 it can reach production-grade maturity.

---

*Report date: 4 August 2026*
*Flutter SDK: ^3.11.1 · Firebase: ^5.x · Provider: ^6.1.5*
