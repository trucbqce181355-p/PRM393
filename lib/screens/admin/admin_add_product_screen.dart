import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/data_service.dart';
import '../../utils/app_image_helper.dart';

class AdminAddProductScreen extends StatefulWidget {
  final Product? product; // Nếu null => Thêm mới, nếu có => Chỉnh sửa
  
  const AdminAddProductScreen({super.key, this.product});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  double _price = 0.0;
  String _unit = 'kg';
  int _stock = 0;
  String _category = DataService.categories.isNotEmpty ? DataService.categories.first.name : 'Khác';
  String _imageUrl = ''; // Rỗng mặc định, nếu có thì là URL hoặc đường dẫn file

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!.name;
      _description = widget.product!.description;
      _price = widget.product!.price;
      _unit = widget.product!.unit;
      _stock = widget.product!.stock;
      _category = widget.product!.category;
      _imageUrl = widget.product!.imageUrl;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newProduct = Product(
        id: widget.product?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        description: _description,
        price: _price,
        unit: _unit,
        imageUrl: _imageUrl,
        stock: _stock,
        category: _category,
        rating: widget.product?.rating ?? 0.0,
      );

      // Save to Hive DB and MongoDB
      if (widget.product != null) {
        await DataService.updateProduct(newProduct);
      } else {
        await DataService.addProduct(newProduct);
      }

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, widget.product != null ? 'Cập nhật thành công' : 'Đã thêm sản phẩm thành công');
      Navigator.pop(context, true); // Return true to refresh previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(
          widget.product != null ? 'Sửa sản phẩm' : 'Thêm trái cây mới',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Tên sản phẩm', (val) => _name = val!, 'Nhập tên sản phẩm', initialValue: _name),
              const SizedBox(height: 16),
              _buildTextField('Mô tả', (val) => _description = val!, 'Nhập mô tả', maxLines: 3, initialValue: _description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Giá (₫)', 
                      (val) => _price = double.tryParse(val!) ?? 0.0, 
                      '0',
                      keyboardType: TextInputType.number,
                      initialValue: widget.product != null ? _price.toStringAsFixed(0) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đơn vị', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: ['kg', 'hộp', 'quả', 'nải', 'thùng', 'bó', 'gram'].contains(_unit) ? _unit : 'kg',
                          style: const TextStyle(color: Colors.black87),
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green, width: 1.5),
                            ),
                          ),
                          items: ['kg', 'hộp', 'quả', 'nải', 'thùng', 'bó', 'gram'].map((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item, style: const TextStyle(color: Colors.black87)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _unit = val);
                          },
                          onSaved: (val) {
                            if (val != null) _unit = val;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Số lượng tồn kho', 
                      (val) => _stock = int.tryParse(val!) ?? 0, 
                      '0',
                      keyboardType: TextInputType.number,
                      initialValue: widget.product != null ? _stock.toString() : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phân loại', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final cats = DataService.categories.isNotEmpty 
                                ? DataService.categories 
                                : [
                                    Category(id: 'c1', name: 'Trái Cây Nhập Khẩu'),
                                    Category(id: 'c2', name: 'Trái Cây Việt Nam'),
                                    Category(id: 'c3', name: 'Trái Cây Cắt Sẵn'),
                                    Category(id: 'c4', name: 'Trái Cây Thùng'),
                                    Category(id: 'c5', name: 'Trái Cây Mùa Hè'),
                                  ];
                                  
                            return DropdownButtonFormField<String>(
                              value: cats.any((c) => c.name == _category) ? _category : cats.first.name,
                              style: const TextStyle(color: Colors.black87),
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.green, width: 1.5),
                                ),
                              ),
                              items: cats.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.name,
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                              onSaved: (val) {
                                if (val != null) _category = val;
                              },
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Hình ảnh sản phẩm (Tùy chọn)', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImageHelper.buildImage(
                        imageUrl: _imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Chọn hình ảnh từ máy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade800,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.green.shade200),
                            ),
                          ),
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                _imageUrl = image.path;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _imageUrl.startsWith('http') ? _imageUrl : null,
                          decoration: InputDecoration(
                            hintText: 'Hoặc dán URL ảnh (https://...)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _imageUrl = val.trim();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    widget.product != null ? 'Cập nhật sản phẩm' : 'Lưu sản phẩm',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSave, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool isRequired = true, String? initialValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: Colors.black87),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 1.5),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Trường này không được để trống';
            }
            return null;
          },
          onSaved: onSave,
        ),
      ],
    );
  }
}
