import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/screens/publish/success_screen.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const List<String> _materialTypes = [
    'Libro',
    'Guía',
    'Material',
    'Otro',
  ];

  static const List<String> _knowledgeAreas = [
    'Ingeniería',
    'Salud',
    'Artes',
    'Ciencias Sociales',
    'Negocios',
    'Otro',
  ];

  static const List<String> _conditions = [
    'Nuevo',
    'Buen estado',
    'Usado',
    'Deteriorado',
  ];

  static const List<String> _methods = [
    PostModel.methodExchange,
    PostModel.methodSale,
    PostModel.methodDonation,
  ];

  String? _selectedMaterialType;
  String? _selectedKnowledgeArea;
  String? _selectedCondition;
  String? _selectedMethod;
  bool _isPublishing = false;
  int _quantity = 1; 

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _publishItem() async {
    if (_isPublishing) return;

    final isValidForm = _formKey.currentState?.validate() ?? false;
    if (!isValidForm) return;

    if (_image == null || _imageBytes == null) {
      _showMessage('Debes agregar una imagen para publicar.');
      return;
    }

    if (_selectedMaterialType == null) {
      _showMessage('Selecciona el tipo de material.');
      return;
    }

    if (_selectedKnowledgeArea == null) {
      _showMessage('Selecciona el área de conocimiento.');
      return;
    }

    if (_selectedCondition == null) {
      _showMessage('Selecciona el estado de conservación.');
      return;
    }

    if (_selectedMethod == null) {
      _showMessage('Selecciona el metodo de publicación.');
      return;
    }

    double? priceUsd;
    if (_selectedMethod == PostModel.methodSale) {
      priceUsd = double.tryParse(_priceController.text.trim());
      if (priceUsd == null || priceUsd <= 0) {
        _showMessage('Ingresa un precio válido en USD para venta.');
        return;
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage('Debes iniciar sesión para publicar.');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final imagePath = _image!.path;
      final extension =
          imagePath.contains('.') ? imagePath.split('.').last.toLowerCase() : 'jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(currentUser.uid)
          .child('${postRef.id}.$extension');

      final metadata = SettableMetadata(
        contentType: _resolveContentType(extension),
      );
      await storageRef.putData(_imageBytes!, metadata);
      final imageUrl = await storageRef.getDownloadURL();

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userSnapshot.data();
      final userName = userData?['name']?.toString().trim() ?? '';
      final ownerName =
          userName.isNotEmpty ? userName : (currentUser.displayName ?? 'Usuario');

      final post = PostModel(
        id: postRef.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        materialType: _selectedMaterialType!,
        knowledgeArea: _selectedKnowledgeArea!,
        career: _careerController.text.trim(),
        subject: _subjectController.text.trim(),
        condition: _selectedCondition!,
        method: _selectedMethod!,
        priceUsd: priceUsd,
        quantity: _quantity,
        imageUrl: imageUrl,
        ownerUid: currentUser.uid,
        ownerName: ownerName,
        ownerEmail: currentUser.email,
      );

      await postRef.set(post.toCreateMap());

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'books': FieldValue.arrayUnion([_titleController.text.trim()]),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } on FirebaseException catch (e) {
      _showMessage('No se pudo publicar. ${e.message ?? 'Intenta nuevamente.'}');
    } catch (_) {
      _showMessage('Ocurrió un error inesperado al publicar.');
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  String _resolveContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _careerController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 750;
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1E6),
      body: Column(
        children: [
          const MetroSwapNavbar(developmentNav: true, heading: 'Publicar'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildImagePlaceholder(),
                            const SizedBox(height: 30),
                            _buildFormFields(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildImagePlaceholder()),
                            const SizedBox(width: 50),
                            Expanded(flex: 1, child: _buildFormFields()),
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

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: _imageBytes == null
            ? const Icon(Icons.image_outlined, size: 100, color: Colors.black26)
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anadir foto',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildLabel('Título del material'),
          _buildTextField(
            'Ej. Cálculo 1',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tipo de material'),
                    _buildDropdown(
                      value: _selectedMaterialType,
                      items: _materialTypes,
                      onChanged: (val) => setState(() => _selectedMaterialType = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Área de conocimiento'),
                    _buildDropdown(
                      value: _selectedKnowledgeArea,
                      items: _knowledgeAreas,
                      onChanged: (val) => setState(() => _selectedKnowledgeArea = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Estado de conservación'),
                    _buildDropdown(
                      value: _selectedCondition,
                      items: _conditions,
                      onChanged: (val) => setState(() => _selectedCondition = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Método'),
                    _buildDropdown(
                      value: _selectedMethod,
                      items: _methods,
                      onChanged: (val) => setState(() => _selectedMethod = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Cantidad'),
                    _buildQuantitySelector(),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedMethod == PostModel.methodSale) ...[
            const SizedBox(height: 20),
            _buildLabel('Precio (USD)'),
            _buildTextField(
              '0.00',
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (_selectedMethod != PostModel.methodSale) return null;
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Ingresa un precio válido';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 20),
          _buildLabel('Carrera'),
          _buildTextField(
            'Ej. Ingenieria de Sistemas',
            controller: _careerController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La carrera es obligatoria';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel('Materia'),
          _buildTextField(
            'Ej. Matematica I',
            controller: _subjectController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La materia es obligatoria';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel('Descripción detallada'),
          _buildTextField(
            'Describe el material',
            controller: _descController,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          _buildPublishButton(),
        ],
      ),
    );
  }

  // Creación de widgets 

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      );

  Widget _buildTextField(
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            errorStyle: const TextStyle(height: 1.2),
          ),
        ),
      );

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        height: 48, 
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: const Text('Seleccionar'),
            isExpanded: true,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _buildQuantitySelector() {
    return Container(
      height: 48, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              if (_quantity > 1) {
                setState(() {
                  _quantity--;
                });
              }
            },
          ),
          Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              setState(() {
                _quantity++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E2E2E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isPublishing ? null : _publishItem,
          child: _isPublishing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Publicar'),
        ),
      );
}