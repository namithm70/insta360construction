import 'package:dartz/dartz.dart';

import 'app_exception.dart';

typedef Result<T> = Either<AppException, T>;
