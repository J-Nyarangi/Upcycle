import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'marketplace_page.dart';
import 'learning_page.dart';
import '../services/image_service.dart';

class CaptureItemPage extends StatefulWidget {
  @override
  _CaptureItemPageState createState() => _CaptureItemPageState();
}

class _CaptureItemPageState extends State<CaptureItemPage> {
  final ImageService _imageService = ImageService();
  File? _capturedImage;
  String? _itemLabel;
  List<String> _upcyclingSuggestions = [];
  bool _isLoading = false;

  // Function to show image source options (camera or gallery)
  Future<void> _showImageSourceOptions() async {
    if (_isLoading) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green[800]),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _captureImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green[800]),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Capture image using the camera
  Future<void> _captureImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _imageService.captureImage();
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
        await _analyzeImage(_capturedImage!);
      } else {
        _showSnackBar('No image captured. Try again.');
      }
    } catch (e) {
      _showSnackBar('Error capturing image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pick image from the gallery
  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
        await _analyzeImage(_capturedImage!);
      } else {
        _showSnackBar('No image selected. Try again.');
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _analyzeImage(File image) async {
    const String apiKey = 'AIzaSyDU_UnwyH9o2Fd_oIzbYowS2BphXJvDiAk';
    final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'LABEL_DETECTION', 'maxResults': 5},
              ],
            },
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final labels = data['responses'][0]['labelAnnotations']
                ?.map<String>((label) => label['description'] as String)
                ?.toList() ??
            [];
        if (labels.isNotEmpty) {
          setState(() {
            _itemLabel = labels[0];
          });
          await _getUpcyclingSuggestions(_itemLabel!);
        } else {
          setState(() {
            _itemLabel = 'Unknown';
            _upcyclingSuggestions = [];
          });
          _showSnackBar('Could not identify the item. Try a clearer image.');
        }
      } else {
        print('Error analyzing image: ${response.statusCode} - ${response.body}');
        setState(() {
          _itemLabel = 'Unknown';
          _upcyclingSuggestions = [];
        });
        _showSnackBar('Error analyzing image. Try again later.');
      }
    } catch (e) {
      print('Exception during image analysis: $e');
      setState(() {
        _itemLabel = 'Unknown';
        _upcyclingSuggestions = [];
      });
      _showSnackBar('Error analyzing image: $e');
    }
  }

  Future<void> _getUpcyclingSuggestions(String item) async {
    const String apiKey = 'AIzaSyDbaUlL_o4Ce3bG3-nPYfb6XCsc3gqCdsw';
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-002:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Provide 3 creative upcycling ideas for a $item. List them as:\n1.\n2.\n3.'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topP': 0.9,
            'maxOutputTokens': 150,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final generatedText =
              data['candidates'][0]['content']['parts'][0]['text'] as String;

          final RegExp regex = RegExp(r'^\d+\.\s*(.+)', multiLine: true);
          final suggestions = regex
              .allMatches(generatedText)
              .map((match) => match.group(1)?.trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();

          setState(() {
            _upcyclingSuggestions = suggestions;
          });
        } else {
          throw Exception('No valid response from API');
        }
      } else {
        print(
            'Error getting suggestions: ${response.statusCode} - ${response.body}');
        setState(() {
          _upcyclingSuggestions = [];
        });
        _showSnackBar('Failed to get upcycling suggestions. Try again later.');
      }
    } catch (e) {
      print('Exception occurred: $e');
      setState(() {
        _upcyclingSuggestions = [];
      });
      _showSnackBar('Failed to get upcycling suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Capture Item',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green[100],
              backgroundImage: const NetworkImage(
                  'https://free-images.com/tn/7497/cherry_tree_blossom_2007.jpg'),
              onBackgroundImageError: (exception, stackTrace) {
                print('Failed to load avatar image: $exception');
              },
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Image Preview Section
              _buildImagePreview(),
              const SizedBox(height: 28),
              // Results Section
              _buildResultsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[400]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green[800],
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing...',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : _capturedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 40,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to Select an Image',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a photo or pick from gallery',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.file(
                          _capturedImage!,
                          fit: BoxFit.cover,
                          height: 240,
                          width: double.infinity,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to change image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_itemLabel == null || _isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Label Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Analysis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _itemLabel!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Upcycling Suggestions
        if (_upcyclingSuggestions.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Upcycling Ideas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: Colors.green[800],
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._upcyclingSuggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  trailing: Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          // "Find More" button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/learning');
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Find More Ideas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 32,
                  color: Colors.grey[500],
                ),
                const SizedBox(height: 12),
                Text(
                  'No upcycling suggestions available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try capturing a clearer image',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.grey[600],
          currentIndex: 1,
          selectedLabelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
          unselectedLabelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
            _buildNavItem(
                Icons.camera_alt_outlined, Icons.camera_alt, 'Scan'),
            _buildNavItem(
                Icons.shopping_bag_outlined, Icons.shopping_bag, 'Market'),
            _buildNavItem(
                Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
          ],
          onTap: (index) => _handleNavTap(context, index),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 26),
      activeIcon: Icon(activeIcon, size: 26),
      label: label,
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/marketplace');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/learning');
          break;
      }
    });
  }
}