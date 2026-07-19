import 'package:dartz/dartz.dart';

import '../errors/failure.dart';
import '../errors/failure_mapper.dart';

Future<Either<Failure, T>> guardUseCase<T>(
    Future<T> Function() operation) async {
  try {
    return Right(await operation());
  } catch (error) {
    return Left(mapExceptionToFailure(error));
  }
}
