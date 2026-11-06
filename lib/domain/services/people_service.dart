import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../models/person_item.dart';
import '../../data/repositories/entries_repository.dart';

class PeopleService extends ChangeNotifier {
  static int _peopleCounter = 0;
  final Map<String, PersonItem> _people = {};

  List<PersonItem> get allPeople {
    final list = _people.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<PersonItem> get overduePeople =>
      allPeople.where((p) => p.cadenceHealth == CadenceHealth.overdue).toList();

  List<PersonItem> get upcomingBirthdays =>
      allPeople.where((p) => p.isBirthdaySoon).toList();

  PersonItem? getPersonById(String id) => _people[id];

  void restorePerson(PersonItem person) {
    _people[person.id] = person;
    notifyListeners();
  }

  PersonItem addPerson({
    required String name,
    PersonRelationship relationship = PersonRelationship.friend,
    String phone = '',
    DateTime? birthday,
    int? cadenceDays,
    DateTime? lastContactedAt,
    List<String> giftIdeas = const [],
    String notes = '',
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Person name cannot be empty.');
    }

    final id = 'per_${DateTime.now().microsecondsSinceEpoch}_${++_peopleCounter}';
    final person = PersonItem(
      id: id,
      name: name.trim(),
      relationship: relationship,
      phone: phone.trim(),
      birthday: birthday,
      cadenceDays: cadenceDays,
      lastContactedAt: lastContactedAt,
      giftIdeas: giftIdeas,
      notes: notes.trim(),
    );

    _people[id] = person;
    notifyListeners();
    return person;
  }

  void updatePerson(PersonItem person) {
    _people[person.id] = person;
    notifyListeners();
  }

  bool deletePerson(String id) {
    final removed = _people.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Logs interaction with a person (e.g., phone call, meetup) and updates lastContactedAt
  PersonItem logInteraction(
    String personId, {
    DateTime? date,
    String? notes,
    EntriesRepository? entriesRepo,
  }) {
    final person = _people[personId];
    if (person == null) {
      throw StateError('Person not found for id $personId');
    }

    final contactDate = date ?? DateTime.now();
    final updatedLogs = List<String>.from(person.interactionLogs);
    if (notes != null && notes.isNotEmpty) {
      updatedLogs.add(notes);
    }

    final updated = person.copyWith(
      lastContactedAt: contactDate,
      interactionLogs: updatedLogs,
    );
    _people[personId] = updated;

    // Write to Day Page single event log
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_contact_${contactDate.microsecondsSinceEpoch}',
      type: EntryType.manualNote,
      ts: contactDate,
      dayKey: DayPageModel.formatDayKey(contactDate),
      payload: {
        'personId': personId,
        'personName': person.name,
        'action': 'contact_interaction',
        'notes': notes ?? 'Stayed in touch with ${person.name}',
      },
    ));

    notifyListeners();
    return updated;
  }

  PersonItem markContacted(
    String personId, {
    String? note,
    DateTime? date,
    EntriesRepository? entriesRepo,
  }) =>
      logInteraction(personId, date: date, notes: note, entriesRepo: entriesRepo);
}
