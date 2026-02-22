import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState()=>_RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>{
  //Creacion de CONTROLADORES para cada campo
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Colores que se usaran
  final Color naranjaM = const Color(0xFFFF6B00);
  final Color grisoscuro = const Color(0xFF333330);
  final Color grisclaro = const Color (0xFFD1CED6);
  final Color columnaGris= const Color.fromARGB(255, 144, 143, 143);

   @override
  Widget build (BuildContext context){
    return Scaffold (
      backgroundColor: grisclaro,//Color de fondo
      body : SafeArea(
        child: Column(
          children : [
            Container(
              color :grisoscuro,
              padding : const EdgeInsets.symmetric(vertical:15, horizontal:20),
              child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  Image.asset("assets/assets/images/logo_metroswap.png"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      const Icon(Icons.swap_horizontal_circle,color:Colors.orange,size:40),
                      Text ("MetroSwap", style: TextStyle(color:Colors.black,fontWeight: FontWeight.bold,backgroundColor: Colors.white.withValues(alpha: 0.1))),
                ],
                ),
                Container(
                  padding:const EdgeInsets.symmetric(horizontal:40,vertical:12),
                  decoration:BoxDecoration(
                    color:naranjaM,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child :const Text("Crea tu cuenta",
                  style:TextStyle(color:Colors.white,fontWeight: FontWeight.bold,fontSize:18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child:Column(
                children: [
                  const SizedBox(height:20),
                  //Columnas
                  Row(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children :[
                      Expanded (
                        child: _cuadrogris([
                          _crearCampoTexto("Nombre completo:", _nombreController, false),
                          _crearCampoTexto("Carrera:", _carreraController, false),
                          _crearCampoTexto("Telefono", _telefonoController, false),
                        ]),
                        ),
                        const SizedBox( width:30),
                        Expanded(
                          child: _cuadrogris([
                            _crearCampoTexto("Correo Unimet:", _correoController, false),
                            _crearCampoTexto("Contraseña:", _passwordController, false),
                            _crearCampoTexto("Carnet:", _carnetController, false),
                          ]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                     ElevatedButton(
                        onPressed:(){
                          debugPrint("Registrando:${_correoController.text}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: naranjaM,
                          padding:const EdgeInsets.symmetric(horizontal:60,vertical:15),
                          shape :RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text ("Registrarse",style:TextStyle(color:Colors.white,fontSize: 17)),
                        ),
                ],
              ),
            ),
          ),

          //Pie de pagina

          Container(
            width: double.infinity,
            color:grisclaro,
            padding:const EdgeInsets.symmetric(vertical: 20),
            child: const Text("© 2026 MetroSwap - Universidad Metropolitana.",textAlign: TextAlign.center,
            style: TextStyle(color:Colors.white70,fontSize: 13),
            ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _cuadrogris(List<Widget> hijos){
    return Container(
      padding: const EdgeInsets.all(25),
      decoration : BoxDecoration(
        color:columnaGris,
        borderRadius: BorderRadius.circular(15),
      ),
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:hijos,),

    );
  }

  Widget _crearCampoTexto(String titulo, TextEditingController controlador,bool esPassword){
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 20.0) ,
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(titulo,style: const TextStyle(color: Colors.white,fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: controlador,
            obscureText: esPassword,
            style: const TextStyle(color:Colors.white),
            decoration : InputDecoration(
              hintText: "Insertar",
              hintStyle: const TextStyle(color:Colors.white60),
              filled: true,
              fillColor: naranjaM,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15,vertical: 12),
              border:OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
  }