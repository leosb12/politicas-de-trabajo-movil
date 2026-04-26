import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../datos/origenes/guia_usuario_movil_remota.dart';
import '../../datos/origenes/respaldo_guia_usuario_movil_local.dart';
import '../../dominio/servicios/clasificador_intencion_guia_usuario_movil.dart';
import '../../dominio/servicios/servicio_guia_usuario_movil.dart';

final clasificadorIntencionGuiaUsuarioMovilProvider =
    Provider<ClasificadorIntencionGuiaUsuarioMovil>((ref) {
      return ClasificadorIntencionGuiaUsuarioMovil();
    });

final respaldoGuiaUsuarioMovilLocalProvider =
    Provider<RespaldoGuiaUsuarioMovilLocal>((ref) {
      return RespaldoGuiaUsuarioMovilLocal(
        ref.watch(clasificadorIntencionGuiaUsuarioMovilProvider),
      );
    });

final guiaUsuarioMovilRemotaProvider = Provider<GuiaUsuarioMovilRemota>((ref) {
  return GuiaUsuarioMovilRemota(ref.watch(dioProvider));
});

final servicioGuiaUsuarioMovilProvider = Provider<ServicioGuiaUsuarioMovil>((
  ref,
) {
  return ServicioGuiaUsuarioMovil(
    remota: ref.watch(guiaUsuarioMovilRemotaProvider),
    respaldoLocal: ref.watch(respaldoGuiaUsuarioMovilLocalProvider),
  );
});
