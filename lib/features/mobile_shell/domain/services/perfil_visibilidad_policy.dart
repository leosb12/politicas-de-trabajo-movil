class PerfilVisibilidadPolicy {
  const PerfilVisibilidadPolicy();

  bool puedeMostrarDepartamento(String rol) {
    return rol.trim().toUpperCase() != 'USUARIO';
  }
}