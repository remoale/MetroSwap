import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:metroswap/models/post_model.dart';
import 'package:metroswap/services/post_deletion_service.dart';
import 'package:metroswap/widgets/metroswap_footer.dart';
import 'package:metroswap/widgets/metroswap_navbar.dart';
import 'package:metroswap/widgets/metroswap_layout.dart'; 

/// Muestra el formulario exclusivamente para editar una publicación existente.
class EditPostScreen extends StatefulWidget {
  final PostModel post; 
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PostDeletionService _postDeletionService = PostDeletionService();

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

  static const List<String> _unimetCareers = [
    'Ciencias Administrativas',
    'Comunicación Social y Empresarial',
    'Contaduría Pública',
    'Derecho',
    'Economía Empresarial',
    'Educación',
    'Estudios Internacionales',
    'Estudios Liberales',
    'Estudios simultáneos',
    'Idiomas Modernos',
    'Ingeniería Civil',
    'Ingeniería de Sistemas',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería Producción',
    'Ingeniería Química',
    'Matemáticas Industriales',
    'Psicología',
    'TSU en Desarrollo de Sistemas Inteligentes',
    'Turismo Sostenible',
    'Otro', 
  ];

  String? _selectedMaterialType;
  String? _selectedKnowledgeArea;
  String? _selectedCondition;
  String? _selectedMethod;
  String? _selectedCareer; 
  bool _isSaving = false;
  int _quantity = 1;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _careerController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  void _loadPostData() {
    final post = widget.post;
    _titleController.text = post.title;
    _descController.text = post.description;
    _subjectController.text = post.subject;
    if (post.priceUsd != null) {
      _priceController.text = post.priceUsd.toString();
    }

    _selectedMaterialType = post.materialType;
    _selectedKnowledgeArea = post.knowledgeArea;
    _selectedCondition = post.condition;
    _selectedMethod = post.method;
    _quantity = post.quantity;

    if (_unimetCareers.contains(post.career)) {
      _selectedCareer = post.career;
    } else {
      _selectedCareer = 'Otro';
      _careerController.text = post.career;
    }
  }

  String _safeImageExtension(XFile file) {
    final fileName = file.name.trim().toLowerCase();
    if (fileName.contains('.')) {
      final ext = fileName.split('.').last;
      if (RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) {
        return ext;
      }
    }
    return 'jpg';
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que deseas eliminar este material? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar')
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        final result = await _postDeletionService.deletePost(
          postId: widget.post.id,
          ownerUid: widget.post.ownerUid,
          title: widget.post.title,
          imageUrl: widget.post.imageUrl,
        );

        if (mounted) {
          _showMessage(result.message);
          Navigator.of(context).popUntil((route) => route.isFirst); 
        }
      } catch (e) {
        _showMessage('Error al eliminar: $e');
        if (mounted) setState(() => _isSaving = false);
      } 
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final isValidForm = _formKey.currentState?.validate() ?? false;
    if (!isValidForm) return;

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
      _showMessage('Selecciona el método de publicación.');
      return;
    }

    if (_selectedCareer == null) {
      _showMessage('Selecciona una carrera.');
      return;
    }

    if (_selectedCareer == 'Otro' && _careerController.text.trim().isEmpty) {
      _showMessage('Por favor, especifica tu carrera.');
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
      _showMessage('Debes iniciar sesión para editar.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
      
      String imageUrl = widget.post.imageUrl; 

      if (_imageBytes != null && _image != null) {
        if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          } catch (e) {
            debugPrint('No se pudo borrar la imagen anterior: $e');
          }
        }

        final extension = _safeImageExtension(_image!);
        final contentType = _resolveContentType(extension);
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('posts')
            .child(currentUser.uid)
            .child('${postRef.id}_$uniqueId.$extension');

        try {
          final metadata = SettableMetadata(contentType: contentType);
          await storageRef.putData(_imageBytes!, metadata);
          imageUrl = await storageRef.getDownloadURL();
        } on FirebaseException catch (e) {
          _showMessage('Fallo al subir nueva imagen (${e.code}).');
          setState(() => _isSaving = false);
          return;
        }
      }

      final finalCareer = _selectedCareer == 'Otro' 
          ? _careerController.text.trim() 
          : _selectedCareer!;

      final Map<String, dynamic> postData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'materialType': _selectedMaterialType!,
        'knowledgeArea': _selectedKnowledgeArea!,
        'career': finalCareer, 
        'subject': _subjectController.text.trim(),
        'condition': _selectedCondition!,
        'method': _selectedMethod!,
        'priceUsd': priceUsd,
        'quantity': _quantity,
        'imageUrl': imageUrl, 
        'updatedAt': FieldValue.serverTimestamp(), 
      };

      await postRef.update(postData);
      
      _showMessage('Publicación actualizada correctamente.');
      if (!mounted) return;
      
      Navigator.pop(context, true); 
      
    } on FirebaseException catch (e) {
      _showMessage('Error con la base de datos (${e.code}).');
    } catch (_) {
      _showMessage('Ocurrió un error inesperado.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _resolveContentType(String extension) {
    switch (extension) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif': return 'image/gif';
      default: return 'image/jpeg';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    
    return MetroSwapLayout(
      body: Container(
        color: const Color(0xFFE4E1E6),
        child: Column(
          children: [
            if (!isMobile)
               const MetroSwapNavbar(developmentNav: true, heading: 'Editar Material'),
              
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: isMobile
                        ? Column(
                            children: [
                              _buildImagePlaceholder(isMobile),
                              const SizedBox(height: 30),
                              _buildFormFields(isMobile),
                            ],
                          )
                        : Row( 
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: _buildImagePlaceholder(isMobile)),
                              const SizedBox(width: 50),
                              Expanded(flex: 1, child: _buildFormFields(isMobile)),
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

  Widget _buildImagePlaceholder(bool isMobile) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: isMobile ? 250 : 400,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : widget.post.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 80, color: Colors.black26),
                    ),
                  )
                : const Icon(Icons.image_outlined, size: 80, color: Colors.black26),
      ),
    );
  }

  Widget _buildFormFields(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar detalles',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildLabel('Título del material'),
          _buildTextField(
            'Ej. Cálculo 1',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'El título es obligatorio';
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (isMobile) ...[
            _buildFieldGroup(
              label: 'Tipo de material',
              child: _buildDropdown(
                value: _selectedMaterialType,
                items: _materialTypes,
                onChanged: (val) => setState(() => _selectedMaterialType = val),
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldGroup(
              label: 'Área de conocimiento',
              child: _buildDropdown(
                value: _selectedKnowledgeArea,
                items: _knowledgeAreas,
                onChanged: (val) => setState(() => _selectedKnowledgeArea = val),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildFieldGroup(
                    label: 'Tipo de material',
                    child: _buildDropdown(
                      value: _selectedMaterialType,
                      items: _materialTypes,
                      onChanged: (val) => setState(() => _selectedMaterialType = val),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildFieldGroup(
                    label: 'Área de conocimiento',
                    child: _buildDropdown(
                      value: _selectedKnowledgeArea,
                      items: _knowledgeAreas,
                      onChanged: (val) => setState(() => _selectedKnowledgeArea = val),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          
          if (isMobile) ...[
            _buildFieldGroup(
              label: 'Estado de conservación',
              child: _buildDropdown(
                value: _selectedCondition,
                items: _conditions,
                onChanged: (val) => setState(() => _selectedCondition = val),
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldGroup(
              label: 'Método',
              child: _buildDropdown(
                value: _selectedMethod,
                items: _methods,
                onChanged: (val) => setState(() => _selectedMethod = val),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: _buildFieldGroup(
                label: 'Cantidad',
                child: _buildQuantitySelector(),
              ),
            ),
          ] else ...[
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
          ],
          
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
                if (parsed == null || parsed <= 0) return 'Ingresa un precio válido';
                return null;
              },
            ),
          ],
          const SizedBox(height: 20),
          
          _buildLabel('Carrera'),
          _buildDropdown(
            value: _selectedCareer,
            items: _unimetCareers,
            onChanged: (val) {
              setState(() {
                _selectedCareer = val;
                if (val != 'Otro') _careerController.clear();
              });
            },
          ),
          
          if (_selectedCareer == 'Otro') ...[
            const SizedBox(height: 10),
            _buildTextField(
              'Escribe tu carrera',
              controller: _careerController,
              validator: (value) {
                if (_selectedCareer == 'Otro' && (value == null || value.trim().isEmpty)) {
                  return 'Especifica tu carrera';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 20),
          _buildLabel('Materia'),
          _buildTextField(
            'Ej. Matemática I',
            controller: _subjectController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'La materia es obligatoria';
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
              if (value == null || value.trim().isEmpty) return 'La descripción es obligatoria';
              return null;
            },
          ),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFieldGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        child,
      ],
    );
  }

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
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              setState(() => _quantity++);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E2E2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            onPressed: _isSaving ? null : _deleteItem,
            child: const Text('Eliminar Publicación', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
