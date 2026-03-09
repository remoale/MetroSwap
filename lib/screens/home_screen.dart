import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const MetroSwapNavbar(developmentNav: true, heading: 'Inicio'),

            SizedBox(
              height: 330,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/fondo_estudiantes.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Todo lo que necesitas para tu trimestre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 600,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SearchAnchor( 
                        builder: (context,controller){
                          return SearchBar(
                            controller: controller,
                            hintText:'Buscar por titulo, material o materia..',
                            hintStyle: WidgetStatePropertyAll(
                              const TextStyle(color: Colors.grey,fontSize: 16)),
                              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                              elevation: WidgetStatePropertyAll(0),
                              onTap: ()=> controller.openView(),
                              onChanged: (_)=> controller.openView(),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 25)),
                                trailing: const [Icon(Icons.search,color: Colors.black54)],
                              );
                        }

                        suggestionsBuilder: (context,controller)async{
                          if (controller.text.isEmpty){
                            return[const Center (child: Padding(
                              padding:EdgeInsets.all(16.0),
                              child: Text("Escribe para buscar..."),
                              ))];
                          }
                          final String searchTerm = controller.text.toLowerCase();
                        }

                        final snapshot = await FirebaseFirestore.instance
                        .collection('post')
                        .where('title_search',isGreaterThanOrEqualTo: searchTerm)
                        .where ('title_search',isLessThanOrEqualTo:'$searchTerm\uf8ff')
                        .get();

                        return snapshot.docs.map((doc){
                          final data= doc.data();
                          return ListTitle(
                            leading: const Icon (Icon.book),
                            title :Text (data['title']),
                            subtitle: Text(data['career']??""),
                            onTap:(){
                              controller.closeView(data['title']);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder :(context)=> ResultDetailScreen(data:data),
                                  ),
                              );
                            },
                            );
                        }).toList();
  },
  ),
  ),
  ),
],
),
),
                        decoration: InputDecoration(
                          hintText: 'Buscar por titulo, material o materia..',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 15.0),
                            child: Icon(Icons.search, color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryCard(
                  title: 'Libros',
                  imagePath: 'assets/images/libros.png',
                ),
                const SizedBox(width: 180),
                _buildCategoryCard(
                  title: 'Materiales',
                  imagePath: 'assets/images/materiales.png',
                ),
              ],
            ),
            const SizedBox(height: 100),

            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({required String title, required String imagePath}) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imagePath,
            width: 300,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(1, 1),
              )
            ],
          ),
        ),
      ],
    );
  }
}
