import 'package:flutter/material.dart';

//impport para las siguientes capas
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tomamos las medidas exactas de la pantalla del dispositivo que esté usando la app
    final altoPantalla = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // El fondo de tu aplicación
      // SAFEAREA: Protege tu diseño de la muesca de la cámara y la batería
      body: SafeArea(
        bottom:
            false, // Lo dejamos falso abajo para que el color llegue hasta el borde inferior
        // COLUMNA: Apilamos la cabecera y luego el formulario
        child: Column(
          children: [
            // 1. LA CABECERA VERDE RESPONSIVA
            Container(
              // En lugar de height: 200, le decimos: "Ocupa el 30% del alto de esta pantalla"
              height: altoPantalla * 0.30,
              width: double.infinity, // Ocupa el 100% del ancho
              color: Colors.green,
              child: const Center(
                child: Text(
                  'LOGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 2. EL RESTO DE LA PANTALLA (El contenedor del formulario)
            // EXPANDED: Este widget le dice al Container que tiene adentro:
            // "Cómete todo el espacio que sobra hacia abajo en la pantalla"
            // 2. EL RESTO DE LA PANTALLA (El contenedor del formulario)
            Expanded(
              child: Container(
                color: Colors.grey[100], // Fondo un poco gris
                width: double.infinity,

                // 1. PADDING: Empuja el contenido hacia adentro para que respire
                padding: const EdgeInsets.all(24.0),

                // 2. COLUMNA: Apila los textos y los alinea a la izquierda (start)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. TEXTO TUNEADO (Título)
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        fontSize: 28, // Tamaño de letra grande
                        fontWeight: FontWeight.bold, // Negrita
                        color: Colors.black87, // Un negro un poco más suave
                      ),
                    ),

                    // SIZEDBOX: Es el truco ninja de Flutter para dejar espacios vacíos
                    const SizedBox(height: 8),

                    // 4. OTRO TEXTO TUNEADO (Subtítulo)
                    Text(
                      'Inicia sesión para comenzar tu ruta de',
                      style: TextStyle(
                        fontSize: 14, // Tamaño más pequeño
                        color: Colors.grey[600], // Color gris como en tu HTML
                      ),
                    ),
                    Text(
                      'reciclaje.',
                      style: TextStyle(
                        fontSize: 14, // Tamaño más pequeño
                        color: Colors.grey[600], // Color gris como en tu HTML
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CORREO ELECTRÓNICO',
                      style: TextStyle(
                        fontSize: 18, // Tamaño más pequeño
                        color: Colors.grey[600], // Color gris como en tu HTML
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ), // Espacio entre los textos y el campo
                    // TU PRIMER INPUT
                    TextField(
                      decoration: InputDecoration(
                        // 1. EL TEXTO DE FONDO (Placeholder)
                        hintText: 'ejemplo@ecociclo.cl',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                        ), // Le bajamos el tono al gris
                        // 2. COLOR DE FONDO DEL CAMPO
                        filled:
                            true, // Hay que decirle que sí queremos rellenarlo de color
                        fillColor: Colors.grey[50], // Un gris casi blanco
                        // 3. LOS BORDES REDONDEADOS
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // ¡Aquí redondeas!
                          borderSide: BorderSide(
                            color: Colors
                                .grey[300]!, // Color de la línea del borde
                            width: 1,
                          ),
                        ),

                        // (Opcional) Esto es para cuando el campo está seleccionado/enfocado
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors
                                .green, // Se pone verde al tocarlo, como en tu diseño
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CONTRASEÑA',
                      style: TextStyle(
                        fontSize: 18, // Tamaño más pequeño
                        color: Colors.grey[600], // Color gris como en tu HTML
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        // 1. EL TEXTO DE FONDO (Placeholder)
                        hintText: '********',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                        ), // Le bajamos el tono al gris
                        // 2. COLOR DE FONDO DEL CAMPO
                        filled:
                            true, // Hay que decirle que sí queremos rellenarlo de color
                        fillColor: Colors.grey[50], // Un gris casi blanco
                        // 3. LOS BORDES REDONDEADOS
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            15,
                          ), // ¡Aquí redondeas!
                          borderSide: BorderSide(
                            color: Colors
                                .grey[300]!, // Color de la línea del borde
                            width: 1,
                          ),
                        ),

                        // (Opcional) Esto es para cuando el campo está seleccionado/enfocado
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors
                                .green, // Se pone verde al tocarlo, como en tu diseño
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // LA FILA PRINCIPAL (Row)
                    Row(
                      // Esto empuja el grupo "Recordarme" a la izquierda y el enlace a la derecha
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // GRUPO 1: El cuadradito y el texto "Recordarme"
                        // Usamos otra Row pequeñita solo para juntar estos dos
                        Row(
                          children: [
                            Checkbox(
                              value: false, // Por ahora desmarcado
                              onChanged: (valor) {
                                // Aquí pondremos la lógica despues
                              },
                              activeColor:
                                  Colors.green, // Color cuando esté marcado
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text(
                              'Recordarme',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),

                        // GRUPO 2: El texto del lado derecho
                        const Text(
                          '¿Olvidaste la clave?',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30), // Espacio antes del botón
                    // ENVOLVEMOS EL BOTÓN para que ocupe todo el ancho (w-full)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // 1. LA ACCIÓN
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },

                        // 2. EL ESTILO (CSS del botón)
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // bg-green-600
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ), // py-4 (hace el botón más alto)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // rounded-2xl
                          ),
                          elevation: 5, // shadow-lg
                        ),

                        // 3. EL CONTENIDO (Tu texto blanco)
                        child: const Text(
                          'ENTRAR AL SISTEMA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      // Esto toma todo el grupo y lo centra perfectamente en la pantalla
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize:
                                14, // Bajé un poco el tamaño para que parezca pie de página
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ), // Esta pequeña separación sí está bien dejarla
                        // GESTUREDETECTOR: Vuelve clickeable cualquier cosa que pongas adentro
                        GestureDetector(
                          onTap: () {
                            print("¡Llevando al usuario a pedir acceso!");
                          },
                          child: const Text(
                            'Pide acceso aquí',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
