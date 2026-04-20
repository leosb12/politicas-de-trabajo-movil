class CrearInstanciaRequestModel {
  const CrearInstanciaRequestModel({required this.politicaId});

  final String politicaId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'politicaId': politicaId};
  }
}
