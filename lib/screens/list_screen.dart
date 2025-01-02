import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/database/firebasehelper.dart';
import 'package:flutter_application_2/screens/login_screen.dart';
import 'package:flutter_application_2/theme/theme_provider.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/databasehelper.dart';
import '../models/task.dart';
import '../providers/locale_provider.dart';
import 'detail_screen.dart';

class SearchableListView extends StatefulWidget {
  @override
  _SearchableListViewState createState() => _SearchableListViewState();
}

class _SearchableListViewState extends State<SearchableListView> {
  List<CardItem> allTasksFromDatabase = [];
  List<CardItem> allTasksForSelectedMode = [];
  List<CardItem> tasksFilteredBySearchBar = [];
  List<CardItem> tasksFilteredAfterSearchBar = [];
  List<CardItem> tasksToDisplay = [];

  bool isLoading = true;

  bool deletedsMode = false;

  String searchQuery = "";

  DatabaseHelper dbHelper = DatabaseHelper.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController searchController = TextEditingController();

  List<bool> isSelected = [false, true, false];

  bool sortAscending = true;
  User? user;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();

    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      setState(() {
        user = firebaseUser;
        isUserLoggedIn = true;
      });
    }

    fetchCardItems();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    isUserLoggedIn = false;
    fetchCardItems();
  }

  Future<void> fetchCardItems() async {
    setState(() {
      isLoading = true;
    });
    List<CardItem> items;
    try {
      if (isUserLoggedIn) {
        items = await FirestoreHelper().getCardItems(user!.uid);
      } else {
        items = await DatabaseHelper.instance.getCardItems();
      }

      setState(() {
        allTasksFromDatabase = items;
        isLoading = false;
      });
    } catch (e) {}
    handleModeSet();
    setState(() {
      isLoading = false;
    });
  }

  void handleModeSet() {
    if (deletedsMode) {
      setState(() {
        allTasksForSelectedMode =
            allTasksFromDatabase.where((item) => item.isDeleted).toList();
      });
    } else {
      setState(() {
        allTasksForSelectedMode =
            allTasksFromDatabase.where((item) => !item.isDeleted).toList();
      });
    }
    filterItems(searchQuery);
  }

  void handleOtherFilters() {
    if (isSelected[2] == true) {
      setState(() {
        tasksFilteredAfterSearchBar =
            tasksFilteredBySearchBar.where((item) => item.isCompleted).toList();
      });
    } else if (isSelected[1] == true) {
      setState(() {
        tasksFilteredAfterSearchBar = tasksFilteredBySearchBar
            .where((item) => !item.isCompleted)
            .toList();
      });
    } else {
      setState(() {
        tasksFilteredAfterSearchBar = tasksFilteredBySearchBar;
      });
    }

    handleSorting();
  }

  void handleSorting() {
    tasksToDisplay = List.from(tasksFilteredAfterSearchBar);
    if (sortAscending) {
      setState(() {
        tasksToDisplay.sort((a, b) => a.date.compareTo(b.date));
      });
    } else {
      setState(() {
        tasksToDisplay.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> updateItem(CardItem cardItem, int index) async {
    await dbHelper.updateCardItem(cardItem);
    fetchCardItems();
  }

  Future<void> updateItemFirestore(
      CardItem cardItem, int index, String documentId) async {
    await FirestoreHelper().updateDocument(user!.uid, documentId, cardItem);
    fetchCardItems();
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'card_items.db');

    await deleteDatabase(path);
  }

  void filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        tasksFilteredBySearchBar = allTasksForSelectedMode;
        searchQuery = query;
      });
    } else {
      setState(() {
        tasksFilteredBySearchBar = allTasksForSelectedMode.where((task) {
          final titleMatch =
              task.title.toLowerCase().contains(query.toLowerCase());
          final descriptionMatch =
              task.description.toLowerCase().contains(query.toLowerCase());
          return titleMatch || descriptionMatch;
        }).toList();
        searchQuery = query;
      });
    }

    handleOtherFilters();
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(deletedsMode
              ? AppLocalizations.of(context)!.validationRestore
              : AppLocalizations.of(context)!.validationDelete),
          content: Text(deletedsMode
              ? "${isLoading} ${AppLocalizations.of(context)!.willRestored} "
              : "${isLoading}  ${AppLocalizations.of(context)!.willRestored}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
            SizedBox(
              width: 12,
            ),
            TextButton(
              onPressed: deletedsMode
                  ? () {
                      CardItem temp = tasksToDisplay.elementAt(index);
                      temp.isDeleted = false;
                      if (isUserLoggedIn == true) {
                        updateItemFirestore(temp, index, temp.firebaseId!);
                      } else {
                        updateItem(temp, index);
                      }

                      Navigator.of(context).pop();
                    }
                  : () {
                      CardItem temp = tasksToDisplay.elementAt(index);
                      temp.isDeleted = true;
                      if (isUserLoggedIn) {
                        updateItemFirestore(temp, index, temp.firebaseId!);
                      } else {
                        updateItem(temp, index);
                      }

                      Navigator.of(context).pop();
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: deletedsMode ? Colors.green : Colors.red,
              ),
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var tasksFilteredBySearchBar = allTasksForSelectedMode.where((item) {
      return item.title
              .toLowerCase()
              .contains(searchController.text.toLowerCase()) ||
          item.description
              .toLowerCase()
              .contains(searchController.text.toLowerCase());
    }).toList();

    handleOtherFilters();

    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
            child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: Icon(Icons.work),
                title: Text(AppLocalizations.of(context)!.tasks),
                onTap: () {
                  deletedsMode = false;
                  handleModeSet();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text(AppLocalizations.of(context)!.deletedItems),
                onTap: () {
                  deletedsMode = true;
                  handleModeSet();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.sunny),
                title: Text(AppLocalizations.of(context)!.theme),
                trailing: Switch(
                  value: Provider.of<ThemeProvider>(context).isDarkMode,
                  onChanged: (bool value) {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Theme.of(context).colorScheme.onSurface,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                ),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.language),
                trailing: DropdownButton<Locale>(
                  value: localeProvider.locale,
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      localeProvider.setLocale(newLocale);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: const Locale('tr'),
                      child: Text('Türkçe'),
                    ),
                  ],
                  underline: SizedBox(),
                ),
              ),
              isUserLoggedIn
                  ? ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      title: Text(AppLocalizations.of(context)!.logout),
                      onTap: () {
                        setState(() {
                          signOut();
                        });
                        Navigator.pop(context);
                      },
                    )
                  : ListTile(
                      leading: Icon(Icons.login),
                      title: Text(AppLocalizations.of(context)!.login),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                    ),
            ],
          ),
        )),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            icon: Icon(Icons.menu)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            autofocus: false,
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.search,
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: filterItems,
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ToggleButtons(
                        isSelected: isSelected,
                        onPressed: (int index) {
                          setState(() {
                            for (int i = 0; i < isSelected.length; i++) {
                              isSelected[i] = i == index;
                              handleOtherFilters();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(3),
                        borderColor: Theme.of(context).colorScheme.outline,
                        selectedBorderColor:
                            Theme.of(context).colorScheme.primary,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        selectedColor: Theme.of(context).colorScheme.onPrimary,
                        color: Theme.of(context).colorScheme.onSurface,
                        constraints: const BoxConstraints(
                          minHeight: 24.0,
                          minWidth: 40.0,
                        ),
                        children: [
                          Text(
                            AppLocalizations.of(context)!.all,
                            style: TextStyle(
                                color: isSelected[0]
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 12),
                          ),
                          Icon(
                            Icons.radio_button_off,
                            size: 20.0,
                            color: isSelected[1]
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          Icon(
                            Icons.check_circle_outline,
                            size: 20.0,
                            color: isSelected[2]
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(15, 10, 10, 10),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            sortAscending = !sortAscending;
                            handleSorting();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.all(0),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: CircleBorder(),
                          ),
                          child: Icon(
                            sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 15,
                          ),
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : tasksToDisplay.isEmpty
                            ? Center(child: Text('Hiç kayıt yok!'))
                            : ListView.builder(
                                itemCount: tasksToDisplay.length,
                                itemBuilder: (context, index) {
                                  final item = tasksToDisplay[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: ListTile(
                                      title: Text(item.title),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  if (Localizations.localeOf(
                                                              context)
                                                          .languageCode ==
                                                      'en') ...[
                                                    Text(item.isUntilDate
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .until
                                                        : AppLocalizations.of(
                                                                context)!
                                                            .on),
                                                    Text(
                                                      ' ${item.date.day}/${item.date.month}/${item.date.year}',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    )
                                                  ] else ...[
                                                    Text(
                                                      ' ${item.date.day}/${item.date.month}/${item.date.year}',
                                                      style: TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic),
                                                    ),
                                                    Text(item.isUntilDate
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .until
                                                        : AppLocalizations.of(
                                                                context)!
                                                            .on),
                                                  ],
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _showDeleteDialog(
                                                            context, index);
                                                      });
                                                    },
                                                    icon: deletedsMode
                                                        ? Icon(
                                                            Icons
                                                                .restore_from_trash,
                                                            color: Colors.green,
                                                          )
                                                        : Icon(Icons.delete),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {});
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value:
                                                              item.isCompleted,
                                                          onChanged:
                                                              (bool? value) {
                                                            CardItem temp =
                                                                item;
                                                            temp.isCompleted =
                                                                value!;
                                                            if (isUserLoggedIn) {
                                                              updateItemFirestore(
                                                                  temp,
                                                                  index,
                                                                  temp.firebaseId!);
                                                            } else {
                                                              updateItem(
                                                                  temp, index);
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailScreen(
                                                deletedMode: deletedsMode,
                                                item: item,
                                                onSave: (updatedItem) {
                                                  if (isUserLoggedIn == true) {
                                                    updateItemFirestore(
                                                        updatedItem,
                                                        index,
                                                        updatedItem
                                                            .firebaseId!);
                                                  } else {
                                                    updateItem(
                                                        updatedItem, index);
                                                  }
                                                },
                                                onDelete: () {
                                                  setState(() {
                                                    setState() {}
                                                  });
                                                },
                                                onRestore: () {}),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
              Visibility(
                visible: !deletedsMode,
                child: Positioned(
                  right: 32.0,
                  bottom: 32.0,
                  child: FloatingActionButton(
                    onPressed: () async {
                      CardItem taskToInsert = CardItem(
                          title: "",
                          description: "",
                          date: DateTime.now(),
                          isUntilDate: false);
                      int id = 0;
                      String firestoreId = "";
                      if (isUserLoggedIn) {
                        DocumentReference docref = await FirestoreHelper()
                            .addDocument(user!.uid, taskToInsert);
                        firestoreId = docref.id;
                      } else {
                        id = await dbHelper.insertCardItem(taskToInsert);
                      }
                      CardItem taskToUpdate;
                      if (isUserLoggedIn) {
                        taskToUpdate = CardItem(
                            firebaseId: firestoreId,
                            title: taskToInsert.title,
                            description: taskToInsert.description,
                            date: taskToInsert.date,
                            isUntilDate: taskToInsert.isUntilDate);
                      } else {
                        taskToUpdate = CardItem(
                            id: id,
                            title: taskToInsert.title,
                            description: taskToInsert.description,
                            date: taskToInsert.date,
                            isUntilDate: taskToInsert.isUntilDate);
                      }

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                  deletedMode: false,
                                  item: taskToUpdate,
                                  onSave: (updatedItem) {
                                    if (isUserLoggedIn) {
                                      updateItemFirestore(updatedItem, id,
                                          updatedItem.firebaseId!);
                                    } else {
                                      updateItem(updatedItem, id);
                                    }
                                  },
                                  onDelete: () {
                                    setState(() {
                                      setState() {}
                                    });
                                  },
                                  onRestore: () {})));
                    },
                    child: Icon(Icons.add),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
