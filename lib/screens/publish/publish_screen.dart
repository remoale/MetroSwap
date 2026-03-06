import 'package:flutter/material.dart';
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

}