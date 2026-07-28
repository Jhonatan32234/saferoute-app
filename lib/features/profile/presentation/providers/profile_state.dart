import '../../../../core/errors/failure.dart';
import '../../domain/entities/profile_entity.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  final ProfileEntity? previous;

  const ProfileLoading({this.previous});
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final String? message;

  const ProfileLoaded(this.profile, {this.message});
}

class ProfileSaving extends ProfileState {
  final ProfileEntity profile;

  const ProfileSaving(this.profile);
}

class ProfileError extends ProfileState {
  final Failure failure;
  final ProfileEntity? previous;

  const ProfileError(this.failure, {this.previous});
}
