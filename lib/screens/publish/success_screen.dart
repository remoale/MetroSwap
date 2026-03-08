import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body : Column (
        children: [
          const MetroSwapNavbar(developmentNav: true, heading: ""),
          Expanded(
            child: Stack (
              children :[
                Container (
                  decoration:  const BoxDecoration(
                    image:DecorationImage(
                      image: AssetImage("assets/images/Sucess.png"),
                      fit : BoxFit.cover,
                      ),
                  ),
                ),

                Container (color: Colors.black.withValues(alpha:0.6)),

                Center (child: Column (
                  mainAxisAlignment:MainAxisAlignment.center,
                  children : [
                    const Icon (Icons.check_circle_outline,color : Colors.green,size: 100),
                    const SizedBox(height: 20),
                    const Text ( "Publicacion Exitosa", style : TextStyle(color:Colors.white,fontSize:32,fontWeight: FontWeight.bold),

                  ),
                  const SizedBox (height: 60),
                  Row (
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOption(context,"Seguir publicando",()=>Navigator.pop(context)),
                      const SizedBox(width: 50),
                      _buildOption(context, "Volver al inicio",(){
                        Navigator.pushNamedAndRemoveUntil(context, "/home_screen", (route)=>false,);
                      }),
                    ],
                    ),
              ],
              ),

              ),
        ],
        ),
          

        ),
        const MetroSwapFooter(),
        ],
    ),
    );
  }

  Widget _buildOption (BuildContext context, String title, VoidCallback onTap){
    return Column (
      children: [
        Text (title, style :const TextStyle(color : Colors.white,fontSize: 18)),
        const SizedBox (height: 10),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0XFFFF4500),
            padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 15),

          ),
          child :const Text ("Ir",style: TextStyle(color:Colors.white)),
          ),

      ],
      );
  }
  }