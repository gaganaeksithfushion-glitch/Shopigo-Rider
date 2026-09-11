import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

void main() {
  runApp(const ShopiGoRiderApp());
}

class ShopiGoRiderApp extends StatelessWidget {
  const ShopiGoRiderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopiGo Independent Rider',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const SoloRouteScreen(),
    );
  }
}

class SoloRouteScreen extends StatefulWidget {
  const SoloRouteScreen({Key? key}) : super(key: key);

  @override
  _SoloRouteScreenState createState() => _SoloRouteScreenState();
}

class _SoloRouteScreenState extends State<SoloRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;
  String? _generatedMapUrl;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRiderData() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and capture delivery snap!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Connected with your active ngrok local tunnel
      var uri = Uri.parse('https://abroad-creation-verdict.ngrok-free.dev/wp-admin/admin-ajax.php?action=shopigo_ind_rider_upload_snap');
      var request = http.MultipartRequest('POST', uri);

      request.fields['rider_name'] = _nameController.text;
      request.fields['rider_phone'] = _phoneController.text;
      request.fields['delivery_notes'] = _notesController.text;
      request.fields['referred_by'] = _refController.text;

      request.files.add(
        await http.MultipartFile.fromPath('delivery_snap', _imageFile!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _generatedMapUrl = data['data']['map_url'];
          });
        } else {
          _showError('Server Error: Upload failed.');
        }
      } else {
        _showError('Connection Error. Check your internet or ngrok status.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchMap(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not launch Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShopiGo Solo Route Builder'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _generatedMapUrl == null
            ? Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '📸 Upload Delivery Snap',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Snap your delivery sheet to instantly build your Google Maps route and save to database.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Towns / Addresses (e.g. Gampaha, Ragama)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _refController,
                      decoration: const InputDecoration(labelText: 'Referral Code (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 15),
                      Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
                    ],
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitRiderData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('🚀 Generate Private Route & Upload Snap', style: TextStyle(fontSize: 16)),
                          ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Route Generated Successfully!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your delivery snap is securely saved to the admin database.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _launchMap(_generatedMapUrl!),
                    icon: const Icon(Icons.map),
                    label: const Text('🗺️ Open Google Maps Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _generatedMapUrl = null;
                        _imageFile = null;
                        _notesController.clear();
                      });
                    },
                    child: const Text('Upload Another List'),
                  ),
                ],
              ),
      ),
    );
  }
}
