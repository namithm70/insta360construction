import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'features/home/data/datasources/insta360_sdk_data_source.dart';
import 'features/home/data/repositories/insta360_repository_impl.dart';
import 'features/home/presentation/bloc/insta360_bloc.dart';

void main() {
  final repository = Insta360RepositoryImpl(
    dataSource: Insta360SdkDataSource(),
  );

  runApp(
    BlocProvider(
      create: (_) => Insta360Bloc(repository: repository),
      child: const Insta360App(),
    ),
  );
}
