import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState()=>_RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>{
  //SE CREARON CONTROLADORES PARA CADA CAMPO
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build (BuildContext context){
    return Scaffold (
      backgroundColor: Colors.white,//fondo
      appBar:AppBar (
        title: const Text("Crear cuenta"),
        backgroundColor: const Color.fromARGB(255, 244, 88, 41) ,
        elevation: 0,
      ),
      body : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child :Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text (
                "Unete a MetroSwap" ,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                const SizedBox(height: 8),
                const Text ('Regístrate con tu correo UNIMET para intercambiar material.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,),
                const SizedBox(height:30),
                 
              _crearCampoTexto('Nombre', 'Ej: Juan', _nombreController, false),
              
              
              _crearCampoTexto('Apellido', 'Ej: Pérez', _apellidoController, false),
              
              // 3. Campo Carnet
              _crearCampoTexto('Carnet', 'Ej: 202112345', _carnetController, false),
              
              // 4. Campo Teléfono
              _crearCampoTexto('Teléfono', 'Ej: 0414-1234567', _telefonoController, false),
              
              // 5. Campo Correo Institucional
              _crearCampoTexto('Correo Institucional', 'Ej: jperez@correo.unimet.edu.ve', _correoController, false),
              
              // 6. Campo Contraseña (oculta el texto)
              _crearCampoTexto('Contraseña', 'Mínimo 6 caracteres', _passwordController, true),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (){
                  print ("boton presionado: ${_correoController.text}");
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange, // Cambia al color de tu Figma
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
              ),
              ),
              child: const Text(
                "Registrarse",
              style: TextStyle(fontSize: 18,color:Colors.white),
              ),
            ),
          ],
        ),
       ),
      ),
    );
  }
  Widget _crearCampoTexto(String titulo, String pista, TextEditingController controlador, bool esPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controlador,
        obscureText: esPassword, // Si es true, oculta el texto (para la contraseña)
        decoration: InputDecoration(
          labelText: titulo,
          hintText: pista,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}