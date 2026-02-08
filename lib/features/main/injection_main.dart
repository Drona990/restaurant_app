
import 'package:get_it/get_it.dart';
import 'package:restaurant/features/main/presentation/bloc/category_bloc.dart';
import 'package:restaurant/features/main/presentation/bloc/menu_bloc.dart';
import 'package:restaurant/features/main/presentation/bloc/table_bloc.dart';
import 'data/data_source/category_remote_data_source.dart';
import 'data/data_source/menu_remote_data_source.dart';
import 'data/data_source/table_remote_datasource.dart';
import 'domain/repository/category_repository.dart';
import 'domain/repository/category_repository_impl.dart';
import 'domain/repository/menu_repository.dart';
import 'domain/repository/menu_repository_impl.dart';
import 'domain/repository/table_repository.dart';
import 'domain/repository/table_repository_imp.dart';

Future<void> initMainInjection(GetIt sl) async {
  sl.registerLazySingleton<TableRemoteDataSource>(
        () => TableRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(() => CategoryRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<MenuRemoteDataSource>(
        () => MenuRemoteDataSourceImpl(sl()),
  );



  sl.registerLazySingleton<TableRepository>(
        () => TableRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(sl()));
  sl.registerLazySingleton<MenuItemRepository>(
        () => MenuRepositoryImpl(sl()),
  );



  sl.registerFactory(() => TableBloc(sl()));
  sl.registerFactory(() => CategoryBloc(sl()));
  sl.registerFactory(() => MenuBloc(sl()));

}