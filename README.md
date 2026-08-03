lib/
│
├── main.dart                          # App entry point
├── app.dart                           # Root widget (MaterialApp)
│
├── core/                              # Core utilities & shared code
│   ├── constants/
│   │   ├── app_colors.dart            # Color palette
│   │   ├── app_strings.dart           # All text strings
│   │   └── app_constants.dart         # Other constants
│   │
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 theme
│   │   └── text_styles.dart           # Text styles
│   │
│   ├── utils/
│   │   ├── helpers.dart               # Helper functions
│   │   ├── validators.dart            # Form validators
│   │   └── formatters.dart            # Number/currency formatters
│   │
│   └── errors/
│       └── exceptions.dart            # Custom exceptions
│
├── shared/                            # Reusable across features
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_indicator.dart
│   │   └── empty_state.dart
│   │
│   └── dialogs/
│       ├── confirm_dialog.dart
│       └── alert_dialog.dart
│
├── services/                          # Firebase services (global)
│   ├── auth_service.dart              # Firebase Auth
│   ├── firestore_service.dart         # Firestore helpers
│   └── storage_service.dart           # Firebase Storage
│
├── providers/                         # Global providers
│   └── auth_provider.dart             # Auth state
│
├── models/                            # Data models (shared)
│   ├── user_model.dart
│   └── business_info_model.dart
│
├── config/                            # Configuration files
│   └── firebase_options.dart          # Firebase config
│
└── features/                          # All features here
    │
    ├── auth/                          # Authentication feature
    │   ├── screens/
    │   │   ├── login_screen.dart
    │   │   └── signup_screen.dart
    │   └── widgets/
    │       └── auth_form.dart
    │
    ├── dashboard/
    │   ├── screens/
    │   │   └── dashboard_screen.dart
    │   ├── widgets/
    │   │   ├── today_sales_card.dart
    │   │   ├── today_profit_card.dart
    │   │   ├── stock_summary_card.dart
    │   │   ├── low_stock_alert.dart
    │   │   └── recent_sales_list.dart
    │   ├── providers/
    │   │   └── dashboard_provider.dart
    │   └── services/
    │       └── dashboard_service.dart
    │
    ├── inventory/
    │   ├── screens/
    │   │   ├── inventory_screen.dart
    │   │   ├── add_product_screen.dart
    │   │   ├── edit_product_screen.dart
    │   │   └── product_details_screen.dart
    │   ├── widgets/
    │   │   ├── product_card.dart
    │   │   ├── product_form.dart
    │   │   └── search_bar_widget.dart
    │   ├── providers/
    │   │   └── inventory_provider.dart
    │   ├── services/
    │   │   └── inventory_service.dart
    │   └── models/
    │       └── product_model.dart
    │
    ├── sales/
    │   ├── screens/
    │   │   ├── sales_screen.dart
    │   │   ├── create_sale_screen.dart
    │   │   └── sale_details_screen.dart
    │   ├── widgets/
    │   │   ├── sale_item_card.dart
    │   │   └── sale_summary.dart
    │   ├── providers/
    │   │   └── sales_provider.dart
    │   ├── services/
    │   │   └── sales_service.dart
    │   └── models/
    │       ├── sale_model.dart
    │       └── sale_item_model.dart
    │
    ├── customers/
    │   ├── screens/
    │   │   ├── customers_screen.dart
    │   │   ├── add_customer_screen.dart
    │   │   └── customer_details_screen.dart
    │   ├── widgets/
    │   │   └── customer_card.dart
    │   ├── providers/
    │   │   └── customers_provider.dart
    │   ├── services/
    │   │   └── customers_service.dart
    │   └── models/
    │       └── customer_model.dart
    │
    ├── suppliers/
    │   ├── screens/
    │   │   ├── suppliers_screen.dart
    │   │   ├── add_supplier_screen.dart
    │   │   └── supplier_details_screen.dart
    │   ├── widgets/
    │   │   └── supplier_card.dart
    │   ├── providers/
    │   │   └── suppliers_provider.dart
    │   ├── services/
    │   │   └── suppliers_service.dart
    │   └── models/
    │       └── supplier_model.dart
    │
    ├── purchase/
    │   ├── screens/
    │   │   ├── purchase_screen.dart
    │   │   └── add_purchase_screen.dart
    │   ├── widgets/
    │   │   └── purchase_card.dart
    │   ├── providers/
    │   │   └── purchase_provider.dart
    │   ├── services/
    │   │   └── purchase_service.dart
    │   └── models/
    │       ├── purchase_model.dart
    │       └── purchase_item_model.dart
    │
    ├── accounting/
    │   ├── screens/
    │   │   ├── accounting_screen.dart
    │   │   ├── add_transaction_screen.dart
    │   │   └── cash_summary_screen.dart
    │   ├── widgets/
    │   │   └── transaction_card.dart
    │   ├── providers/
    │   │   └── accounting_provider.dart
    │   ├── services/
    │   │   └── accounting_service.dart
    │   └── models/
    │       └── transaction_model.dart
    │
    ├── reports/
    │   ├── screens/
    │   │   ├── reports_screen.dart
    │   │   ├── sales_report_screen.dart
    │   │   ├── purchase_report_screen.dart
    │   │   └── profit_report_screen.dart
    │   ├── widgets/
    │   │   └── report_chart.dart
    │   ├── providers/
    │   │   └── reports_provider.dart
    │   └── services/
    │       └── reports_service.dart
    │
    └── settings/
        ├── screens/
        │   └── settings_screen.dart
        ├── widgets/
        ├── providers/
        │   └── settings_provider.dart
        ├── services/
        │   └── settings_service.dart
        └── models/
            └── settings_model.dart