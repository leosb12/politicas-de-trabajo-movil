import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tarea_formulario_remote_datasource.dart';
import 'mis_tramites_providers.dart';

final tareaFormularioDataSourceProvider = Provider<TareaFormularioDataSource>((
  ref,
) {
  return TareaFormularioRemoteDataSource(ref.watch(misTramitesDioProvider));
});
