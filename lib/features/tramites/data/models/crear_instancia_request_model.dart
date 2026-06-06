class CrearInstanciaRequestModel {
  const CrearInstanciaRequestModel({
    required this.politicaId,
    this.respuestasRequisitosIniciales,
  });

  final String politicaId;
  final Map<String, dynamic>? respuestasRequisitosIniciales;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'politicaId': politicaId,
      if (respuestasRequisitosIniciales != null)
        'respuestasRequisitosIniciales': respuestasRequisitosIniciales,
    };
  }
}
