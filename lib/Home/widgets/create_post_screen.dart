import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/AppUser.dart';
import '../../services/Post_Service.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> tags = [];
  File? _image;
  bool _loading = false;

  // Pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // Upload post to Firebase
  Future<void> handlePost() async {
    final user = Provider.of<AppUser?>(context, listen: false);
    if (user == null) return;

    if (_textController.text.trim().isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Write something or add an image.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await PostService().createPost(
        user: user,
        text: _textController.text.trim(),
        imageFile: _image,
        tags: tags,
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post. Try again.")),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // screen background color
      appBar: AppBar(
        title: Text("Create Post"),
        backgroundColor: Colors.deepPurple, // app bar color
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : handlePost,
            child: _loading
                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text("Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // Text input container
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Image preview container
              if (_image != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _image = null),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 10),

              // Pick image button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.deepPurple),
                ),
                icon: Icon(Icons.image, color: Colors.deepPurple),
                label: Text("Add Image", style: TextStyle(color: Colors.deepPurple)),
                onPressed: pickImage,
              ),

              SizedBox(height: 20),

              // Tags input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: "Add tag",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.deepPurple),
                    onPressed: () {
                      if (_tagController.text.trim().isNotEmpty) {
                        setState(() {
                          tags.add(_tagController.text.trim());
                        });
                        _tagController.clear();
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Display added tags
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (t) => Chip(
                      label: Text(t),
                      backgroundColor: Colors.deepPurple[100],
                      deleteIcon: Icon(Icons.close),
                      onDeleted: () => setState(() => tags.remove(t)),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
