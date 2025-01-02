import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/task.dart';

class DetailScreen extends StatefulWidget {
  final CardItem item;
  final bool deletedMode;
  final Function(CardItem updatedItem) onSave;
  final VoidCallback onDelete;

  final VoidCallback onRestore;

  const DetailScreen(
      {Key? key,
      required this.deletedMode,
      required this.item,
      required this.onSave,
      required this.onDelete,
      required this.onRestore})
      : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late bool _isUntilDate;
  late bool _isCompleted;
  late int? _id;
  late String? _firebaseId;
  late bool _isDeleted;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController =
        TextEditingController(text: widget.item.description);
    _selectedDate = widget.item.date;
    _isUntilDate = widget.item.isUntilDate;
    _isCompleted = widget.item.isCompleted;
    _id = widget.item.id;
    _firebaseId = widget.item.firebaseId;
    _isDeleted = widget.item.isDeleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  void _saveChanges() {
    widget.onSave(
      CardItem(
          id: _id,
          firebaseId: _firebaseId,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate,
          isUntilDate: _isUntilDate,
          isDeleted: _isDeleted,
          isCompleted: _isCompleted),
    );
    Navigator.pop(context);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.validationDelete),
          content: Text(
              "${widget.item.title} ${AppLocalizations.of(context)!.willDeleted}"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.no),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: widget.deletedMode
                      ? () {
                          _isDeleted = false;
                          _saveChanges();
                          Navigator.of(context).pop();
                          widget.onRestore();
                        }
                      : () {
                          _isDeleted = true;
                          _saveChanges();
                          Navigator.of(context).pop();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        widget.deletedMode ? Colors.green : Colors.red,
                  ),
                  child: Text(AppLocalizations.of(context)!.yes),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.details),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _saveChanges,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 6,
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.title,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToggleButtons(
                          isSelected: [_isUntilDate, !_isUntilDate],
                          onPressed: (int index) {
                            setState(() {
                              _isUntilDate = index == 0;
                            });
                          },
                          constraints: BoxConstraints(
                            minHeight: 32,
                            minWidth: 48,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          borderWidth: 1.5,
                          borderColor: Theme.of(context).colorScheme.outline,
                          selectedBorderColor:
                              Theme.of(context).colorScheme.primary,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          color: Theme.of(context).colorScheme.onSurface,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.until,
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              AppLocalizations.of(context)!.on,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: widget.deletedMode
                      ? Icon(Icons.restore_from_trash, color: Colors.green)
                      : Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    _showDeleteDialog(context);
                  },
                ),
                Checkbox(
                  value: _isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      _isCompleted = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
