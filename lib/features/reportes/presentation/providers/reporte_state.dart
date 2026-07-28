sealed class ReporteState {
  const ReporteState();
}

class ReporteInitial extends ReporteState {
  const ReporteInitial();
}

class ReporteLoading extends ReporteState {
  const ReporteLoading();
}

class ReporteSuccess extends ReporteState {
  final String? message;
  const ReporteSuccess({this.message});
}

class ReporteError extends ReporteState {
  final String error;
  const ReporteError(this.error);
}
