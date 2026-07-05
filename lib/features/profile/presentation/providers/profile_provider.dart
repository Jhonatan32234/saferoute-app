import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

@injectable
class ProfileProvider extends ChangeNotifier {
  final IProfileRepository _repository;

  ProfileEntity? _profile;
  bool _isLoading = false;
  String? _error;
  String? _token;

  ProfileProvider(this._repository);

  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  set token(String value) {
    if (_token != value) {
      _token = value;
      if (_token != null && _token!.isNotEmpty) {
        cargarPerfil();
      }
    }
  }

  Future<void> cargarPerfil() async {
    if (_token == null || _token!.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getProfile(_token!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarPerfil({
    required String nombre,
    required String telefono,
    required String email,
  }) async {
    if (_token == null || _token!.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateProfile(_token!, nombre, telefono, email);
      await cargarPerfil();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
