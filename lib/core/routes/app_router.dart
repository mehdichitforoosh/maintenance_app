import 'package:go_router/go_router.dart';

import '../storage/key_value_storage.dart';

final router = GoRouter(
  initialLocation: KeyValueStorage.instance.isFirstRun ? '/onboarding' : '/',
  routes: [
    // GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    // GoRoute(
    //     path: '/initial-setup', builder: (_, _) => const InitialSetupScreen()),
    // GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    // GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
    // GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
    // // Business
    // GoRoute(
    //   path: '/business/edit',
    //   builder: (context, state) => const EditBusinessScreen(),
    // ),
    // // Materials & Inventory
    // GoRoute(
    //   path: '/materials',
    //   builder: (context, state) => MaterialListScreen(
    //     onAddMaterialPressed: () => context.push('/materials/add'),
    //     onEditMaterialPressed: (material) =>
    //         context.push('/materials/edit', extra: material),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) => const AddMaterialScreen(),
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final material = state.extra as RawMaterial?;
    //         return AddMaterialScreen(materialToEdit: material);
    //       },
    //     ),
    //   ],
    // ),
    // // Products
    // GoRoute(
    //   path: '/products',
    //   builder: (context, state) => ProductListScreen(
    //     onAddProductPressed: () => context.push('/products/add'),
    //     onEditProductPressed: (product) =>
    //         context.push('/products/edit', extra: product),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) => const AddProductScreen(),
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final product = state.extra as Product?;
    //         return AddProductScreen(productToEdit: product);
    //       },
    //     ),
    //   ],
    // ),
    // // Categories
    // GoRoute(
    //   path: '/categories',
    //   builder: (context, state) => CategoryListScreen(
    //     onAddCategoryPressed: () => context.push('/categories/add'),
    //     onEditCategoryPressed: (category) =>
    //         context.push('/categories/edit', extra: category),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) => const AddCategoryScreen(),
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final category = state.extra as Category?;
    //         return AddCategoryScreen(categoryToEdit: category);
    //       },
    //     ),
    //   ],
    // ),
    // // Expenses
    // GoRoute(
    //   path: '/expenses',
    //   builder: (context, state) => ExpenseListScreen(
    //     onAddExpensePressed: () => context.push('/expenses/add'),
    //     onEditExpensePressed: (expense) =>
    //         context.push('/expenses/edit', extra: expense),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) {
    //         final initialDate = state.extra as DateTime?;
    //         return AddExpenseScreen(initialDate: initialDate);
    //       },
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final expense = state.extra as Expense?;
    //         return AddExpenseScreen(expenseToEdit: expense);
    //       },
    //     ),
    //   ],
    // ),
    // // Sales
    // GoRoute(
    //   path: '/sales',
    //   builder: (context, state) => SaleListScreen(
    //     onAddSalePressed: () => context.push('/sales/add'),
    //     onEditSalePressed: (sale) => context.push('/sales/edit', extra: sale),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) {
    //         final initialDate = state.extra as DateTime?;
    //         return AddSaleScreen(initialDate: initialDate);
    //       },
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final sale = state.extra as Sale?;
    //         return AddSaleScreen(saleToEdit: sale);
    //       },
    //     ),
    //   ],
    // ),
    // // Purchases
    // GoRoute(
    //   path: '/purchases',
    //   builder: (context, state) => PurchaseListScreen(
    //     onAddPurchasePressed: () => context.push('/purchases/add'),
    //     onEditPurchasePressed: (purchase) =>
    //         context.push('/purchases/edit', extra: purchase),
    //   ),
    //   routes: [
    //     GoRoute(
    //       path: 'add',
    //       builder: (context, state) {
    //         final initialDate = state.extra as DateTime?;
    //         return AddPurchaseScreen(initialDate: initialDate);
    //       },
    //     ),
    //     GoRoute(
    //       path: 'edit',
    //       builder: (context, state) {
    //         final purchase = state.extra as Purchase?;
    //         return AddPurchaseScreen(purchaseToEdit: purchase);
    //       },
    //     ),
    //   ],
    // ),
    // // Settings
    // GoRoute(
    //   path: '/settings',
    //   builder: (context, state) => const SettingsScreen(),
    // ),
  ],
);
