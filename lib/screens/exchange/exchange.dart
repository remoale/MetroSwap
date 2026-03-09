import 'package:flutter/material.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class TradeChatScreen extends StatefulWidget {
  final String tradeId; // ID del intercambio

  const TradeChatScreen({
    super.key,
    required this.tradeId,
  });

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool isLoading = false;

  // === VARIABLES PREPARADAS PARA FIRESTORE ===
  final String applicantName = "Nombre del solicitante";
  final String beneficiaryName = "Nombre del beneficiario";
  final String requestedItem = "Articulo Solicitado";
  final String methodType = "Contribución";
  
  // Lista de mensajes falsos para probar
  final List<Map<String, dynamic>> messages = [
    {"text": "Ok , esta bien", "isMe": false},
    {"text": "Solo las 5 primeras paginas", "isMe": true},
    {"text": "Vale, nos vemos en la biblioteca piso 2", "isMe": true},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    

    setState(() {
      messages.add({"text": _messageController.text, "isMe": true});
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECEF), 
      body: SafeArea(
        child: Column(
          children: [
            const MetroSwapNavbar(
              developmentNav: true,
              heading: 'Tradea',
              showLogoutButton: false,
              showNotificationsButton: true,
              showProfileButton: true,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 10),

                        _buildTradeHeader(context),
                        const SizedBox(height: 20),

                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                return _buildMessageBubble(
                                  text: msg['text'],
                                  isMe: msg['isMe'],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildInputArea(),
                        const SizedBox(height: 20),

                        Center(
                          child: SizedBox(
                            width: 250,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint("Trade finalizado/confirmado");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8A4C), 
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Enviar contribucion",
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const MetroSwapFooter(),
          ],
        ),
      ),
    );
  }

  // === WIDGETS AUXILIARES ===

  Widget _buildTradeHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40), 
          ),
          child: isCompact 
            ? Column(
                children: [
                  _buildUserColumn(applicantName, isRightAligned: false),
                  const Divider(height: 30),
                  _buildItemInfo(),
                  const Divider(height: 30),
                  _buildUserColumn(beneficiaryName, isRightAligned: true),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildUserColumn(applicantName, isRightAligned: false)),
                  Container(height: 80, width: 2, color: Colors.grey.shade300),
                  Expanded(child: _buildItemInfo()),
                  Container(height: 80, width: 2, color: Colors.grey.shade300),
                  Expanded(child: _buildUserColumn(beneficiaryName, isRightAligned: true)),
                ],
              ),
        );
      }
    );
  }

  Widget _buildUserColumn(String name, {required bool isRightAligned}) {
    // Foto de perfil simulada
    Widget avatar = CircleAvatar(
      radius: 40,
      backgroundColor: Colors.orange.shade100,
      backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder
    );

    Widget info = Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Carnet", style: TextStyle(fontSize: 10)),
        const Text("Correo institucional", style: TextStyle(fontSize: 10)),
        const Text("Numero telefonico", style: TextStyle(fontSize: 10)),
        const Text("Carrera", style: TextStyle(fontSize: 10)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRightAligned) _statusDot(),
            if (!isRightAligned) const SizedBox(width: 4),
            const Text("En linea", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            if (isRightAligned) const SizedBox(width: 4),
            if (isRightAligned) _statusDot(),
          ],
        )
      ],
    );

    return Row(
      mainAxisAlignment: isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isRightAligned 
        ? [info, const SizedBox(width: 16), avatar]
        : [avatar, const SizedBox(width: 16), info],
    );
  }

  Widget _statusDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildItemInfo() {
    return Column(
      children: [
        Text(requestedItem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tipo de metodo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(methodType, style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        const Text("Estado de la solicitud", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const Text("Solicitado", style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildMessageBubble({required String text, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFF8A4C) : Colors.transparent, 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: isMe ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Escribe un mensaje",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A4C), 
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30),
            ),
            child: const Text("Enviar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}