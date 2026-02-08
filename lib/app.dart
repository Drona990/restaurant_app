/*
import 'package:flutter/material.dart';
import '../../core/utils/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F7),
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_routes.dart';
import 'core/theme/app_color.dart';
import 'features/auth/presentation/block/login_bloc.dart';
import 'features/main/presentation/bloc/category_bloc.dart';
import 'features/main/presentation/bloc/menu_bloc.dart';
import 'features/main/presentation/bloc/table_bloc.dart';
import 'injection.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => sl<LoginBloc>()),
        BlocProvider<MenuBloc>(create: (_) => sl<MenuBloc>()),
        BlocProvider<TableBloc>(create: (_) => sl<TableBloc>()),
        BlocProvider<CategoryBloc>(create: (_) => sl<CategoryBloc>())
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.backgroundGrey,

          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryCyan,
            primary: AppColors.primaryCyan,
            onPrimary: AppColors.pureWhite,
            surface: AppColors.pureWhite,
            onSurface: AppColors.deepBlack,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(color: AppColors.deepBlack),
            bodyMedium: TextStyle(color: AppColors.textGrey),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.pureWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryCyan, width: 2),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}