import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/home/data/datasources/insta360_sdk_data_source.dart';
import 'features/home/data/repositories/insta360_repository_impl.dart';
import 'features/home/presentation/bloc/insta360_bloc.dart';

void main() {
  final apiClient = ApiClient(baseUrl: AppConfig.backendBaseUrl);
  final authRepository = AuthRepositoryImpl(apiClient: apiClient);
  final repository = Insta360RepositoryImpl(
    dataSource: Insta360SdkDataSource(),
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => Insta360Bloc(repository: repository),
        ),
        BlocProvider(
          create: (_) => AuthCubit(repository: authRepository),
        ),
      ],
      child: const Insta360App(),
    ),
  );
}
