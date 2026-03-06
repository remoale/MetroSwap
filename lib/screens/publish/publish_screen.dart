import 'package:flutter/material.dart';
import 'package:metroswap/screens/publish/Sucess_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override

  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen>{
  //Controlar dropdown
  String? _selectedCategory;
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: true, heading: 'Publicar'),
          Expanded(
            child:SingleChildScrollView(
              padding : const EdgeInsets.all(40.0),
              child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),

                child: Row(
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children: [
                    //lado izq
                    Expanded(
                      flex:1,
                      child: _buildImagePlaceholder(),),
                      const SizedBox(width: 50),

                      // lado derecho
                      Expanded(
                        flex: 1,
                        child: _buildFormFields(),
                      ),
                  ],
                  ),
              ),
            ),
          ),
          ),
          const MetroSwapFooter(),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(){

    return GestureDetector(
      onTap : ()=> print("Abrir galeria"),
      child : Container(
        height: 400,
        decoration: BoxDecoration(
          color : const Color(0xFFD9D9D9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child : const Icon(Icons.image_outlined,size : 100,color:Colors.black26),
      ),
    );
  }

  Widget _buildFormFields(){
    return Column (crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Añadir foto",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),

      _buildLabel("Titulo de Material"),
      _buildTextField("Insertar"),

      const SizedBox(height: 20),

      Row (
        children: [
        Expanded(
          child: Column (
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Categoria"),
            _buildDropdown(
              value : _selectedCategory,
              items: ["Libros","Guias","Otros"],
              onChanged :(val)=> setState(() => _selectedCategory=val), 
            ),
            
          ],
          ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column (
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel ("Método"),
                _buildDropdown(
                  value : _selectedMethod,
                  items:["Intercambio","Venta","Donacion"],
                  onChanged: (val)=> setState(() => _selectedMethod=val),
                    
                  ),
                
              ],
              ),
              ),
      ],
      ),
      const SizedBox(height: 20),
      _buildLabel("Descripcion detallada"),
      _buildTextField("", maxLines:4),
      
      const SizedBox (height:30),

      _buildPublishButton(),

    ],
    );
  }
  //creacion de widgets

  Widget _buildLabel (String text)=>Padding(
    padding: const EdgeInsets.only(bottom:8.0),
    child: Text (text,style :const TextStyle(fontWeight: FontWeight.w500)),
    );

    Widget _buildTextField (String hint,{int maxLines =1})=> Container(
      decoration : BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(5)),
      child : TextField(
        maxLines: maxLines,
        decoration : InputDecoration(hintText: hint,border: InputBorder.none,contentPadding: const EdgeInsets.all(12)),
      ),
      );
      
      Widget _buildDropdown({ required String? value, required List<String>items, required ValueChanged<String?> onChanged})=>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(5)),
          child :DropdownButtonHideUnderline(
            child: DropdownButton<String>
            ( value :value,
            hint: const Text ("Seleccionar"),
            isExpanded:true,
            items : items.map((i)=> DropdownMenuItem(value :i ,child :Text(i))).toList(),
             onChanged: onChanged,
             ),
        ),
              );

              Widget _buildPublishButton()=>SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style :ElevatedButton.styleFrom(
                    backgroundColor:const Color (0xFF2E2E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context)=> const SuccessScreen()),
                        );
                    },
                      child:const Text ("Publicar"),
              ),
              );

}