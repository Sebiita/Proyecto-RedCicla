from services.services_usuario import services_crear_usuario, services_leer_usuario, services_inicio_de_sesion, services_eliminar_usuario


def rourtes_crear_usuario(nombre: str, correo: str, contraseña: str):
    return services_crear_usuario(nombre, correo, contraseña)


def routes_leer_usuario(correo: str):
    return services_leer_usuario(correo)


def routes_incio_de_sesion(correo: str, contraseña: str):
    return services_inicio_de_sesion(correo, contraseña)


def routes_eliminar_usuario(correo: str):
    return services_eliminar_usuario(correo)





