// Import Flutter UI toolkit
import 'package:flutter/material.dart';
// Import Supabase Flutter package
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Make sure Flutter engine is ready before doing anything async
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase with your project URL and anon key
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Replace with your Supabase project URL
    anonKey: 'YOUR_ANNON_KEY', // Replace with your anon/public key
  );

  // Run the Flutter app
  runApp(const NotesApp());
}

// This is the root widget of the app
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is the base for a Material Design app
    return const MaterialApp(
      home: NotesPage(), // Show NotesPage as the home screen
    );
  }
}

// The main screen that displays and manages notes
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

// State class where all logic happens
class _NotesPageState extends State<NotesPage> {
  // Create a reference to Supabase client
  final supabase = Supabase.instance.client;

  // List to store notes fetched from Supabase
  List<Map<String, dynamic>> notes = [];

  // Boolean to track loading state
  bool isLoading = true;

  // Text field controllers to read user input
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load notes when screen first appears
    fetchNotes();
  }

  // 🔁 Function to fetch all notes from Supabase
  Future<void> fetchNotes() async {
    setState(() {
      isLoading = true; // Show loading spinner
    });

    try {
      // Read all notes and order by ID (ascending)
      final response = await supabase.from('notes').select().order('id');

      // Check if response is valid
      // Store the list of notes
      setState(() {
        notes = List<Map<String, dynamic>>.from(response);
      });
        } catch (e) {
      // Catch and print any fetch errors
      debugPrint('Error fetching notes: $e');
    }

    // Stop showing the loading spinner
    setState(() {
      isLoading = false;
    });
  }

  // ➕ Function to add a new note
  Future<void> addNote() async {
    await supabase.from('notes').insert({
      'title': titleController.text,
      'content': contentController.text,
    });

    // Clear input fields
    titleController.clear();
    contentController.clear();

    // Refresh notes
    fetchNotes();
  }

  // ✏️ Function to update an existing note
  Future<void> updateNote(int id) async {
    await supabase.from('notes').update({
      'title': titleController.text,
      'content': contentController.text,
    }).eq('id', id); // Update where id matches

    titleController.clear();
    contentController.clear();

    fetchNotes();
  }

  // 🗑️ Function to delete a note
  Future<void> deleteNote(int id) async {
    await supabase.from('notes').delete().eq('id', id);
    fetchNotes(); // Refresh after delete
  }

  // 🧾 Show a dialog to add or edit a note
  void openNoteDialog({Map<String, dynamic>? note}) {
    if (note != null) {
      // If editing, pre-fill title and content
      titleController.text = note['title'] ?? '';
      contentController.text = note['content'] ?? '';
    } else {
      // If adding, clear fields
      titleController.clear();
      contentController.clear();
    }

    // Show the pop-up dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note == null ? 'Add Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input field for title
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            // Input field for content
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          // Save button
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (note == null) {
                addNote(); // New note
              } else {
                updateNote(note['id']); // Update existing note
              }
            },
            child: const Text('Save'),
          ),
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // 🧱 Build the main user interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Notes')),

      // Body of the screen
      body: isLoading
          // Show loading spinner while fetching notes
          ? const Center(child: CircularProgressIndicator())
          // Show "no notes" if list is empty
          : notes.isEmpty
              ? const Center(child: Text('No notes found.'))
              // Show notes in a scrollable list
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (_, index) {
                    final note = notes[index];

                    return ListTile(
                      title: Text(note['title'] ?? ''),
                      subtitle: Text(note['content'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => openNoteDialog(note: note),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteNote(note['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),

      // Floating button to add a new note
      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
