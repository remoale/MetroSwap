import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 850;
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    Widget pageContent = Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 850) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );

    if (isLoggedIn) {
      return MetroSwapLayout(
        body: Column(
          children: [
            if (isDesktop)
              const MetroSwapNavbar(
                developmentNav: false, 
                heading: 'Conócenos',
              ),
            pageContent,
            const MetroSwapFooter(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF333333), 
      body: Column(
        children: [
          MetroSwapNavbar(
            developmentNav: true, 
            heading: isDesktop ? 'Conócenos' : '', 
          ),
          pageContent,
          const MetroSwapFooter(), 
        ],
      ),
    );
  }

  // Layout para escritorio.
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Columna izquierda.
        Expanded(
          flex: 6, 
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo_marmol.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primera fila del equipo.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeamMember(name: 'Diego Guzmán', age: '18', ig: '@diego_guzguz', imagePath: 'assets/images/diego.png'),
                        _buildTeamMember(name: 'Derek Carvajal', age: '22', ig: '@dcarvajal_13', imagePath: 'assets/images/derek.png'),
                        _buildTeamMember(name: 'Daniela Pacheco', age: '18', ig: '@dpacc_7', imagePath: 'assets/images/daniela.png'),
                      ],
                    ),
                    const SizedBox(height: 50),
                    // Segunda fila del equipo.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeamMember(name: 'Simón Ananian', age: '20', ig: '@simon_ananian_hurtado', imagePath: 'assets/images/simon.png'),
                        _buildTeamMember(name: 'Andrés Mujica', age: '20', ig: '@mujica550', imagePath: 'assets/images/andres.png'),
                        _buildTeamMember(name: 'Remo Agostinelli', age: '21', ig: '@remoax', imagePath: 'assets/images/remo.png'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Columna derecha.
        Expanded(
          flex: 4, 
          child: Image.asset(
            'assets/images/equipo_trabajando.png', 
            fit: BoxFit.cover,
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  // Layout para móvil.
  Widget _buildMobileLayout() {
    return Container(
      width: double.infinity, 
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fondo_marmol.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
              child: Text(
                'Conócenos',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0, left: 10.0, right: 10.0),
              child: Wrap(
                spacing: 20, 
                runSpacing: 40, 
                alignment: WrapAlignment.center,
                children: [
                  _buildTeamMember(name: 'Diego Guzmán', age: '18', ig: '@diego_guzguz', imagePath: 'assets/images/diego.png'),
                  _buildTeamMember(name: 'Derek Carvajal', age: '22', ig: '@dcarvajal_13', imagePath: 'assets/images/derek.png'),
                  _buildTeamMember(name: 'Daniela Pacheco', age: '18', ig: '@dpacc_7', imagePath: 'assets/images/daniela.png'),
                  _buildTeamMember(name: 'Simón Ananian', age: '20', ig: '@simon_ananian_hurtado', imagePath: 'assets/images/simon.png'),
                  _buildTeamMember(name: 'Andrés Mujica', age: '20', ig: '@mujica550', imagePath: 'assets/images/andres.png'),
                  _buildTeamMember(name: 'Remo Agostinelli', age: '21', ig: '@remoax', imagePath: 'assets/images/remo.png'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de cada integrante.
  Widget _buildTeamMember({
    required String name,
    required String age,
    required String ig,
    required String imagePath,
  }) {
    return SizedBox(
      width: 150, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              width: 150,
              height: 190,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high, 
              isAntiAlias: true, 
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$age años',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.instagram, size: 16, color: Colors.black87), 
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ig,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
