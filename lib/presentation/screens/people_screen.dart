import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/person_item.dart';
import '../../domain/services/people_service.dart';
import '../../domain/services/dhar_service.dart';
import '../../data/repositories/entries_repository.dart';

class PeopleScreen extends StatefulWidget {
  final PeopleService peopleService;
  final EntriesRepository entriesRepo;
  final DharService? dharService;
  final bool isBangla;

  const PeopleScreen({
    super.key,
    required this.peopleService,
    required this.entriesRepo,
    this.dharService,
    this.isBangla = false,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  void _showAddPersonDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cadenceController = TextEditingController(text: '7');
    final giftController = TextEditingController();
    final notesController = TextEditingController();
    PersonRelationship rel = PersonRelationship.family;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isBangla ? 'নতুন পরিচিতি যোগ করুন' : 'Add Person Profile',
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'নাম' : 'Name',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<PersonRelationship>(
                    value: rel,
                    dropdownColor: AppColors.surface2,
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'সম্পর্ক' : 'Relationship',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: PersonRelationship.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.label(isBangla: widget.isBangla), style: const TextStyle(color: AppColors.textPrimary)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => rel = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: cadenceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'যোগাযোগের ব্যবধান (দিন)' : 'Keep-in-Touch Cadence (Days)',
                      hintText: 'e.g. 7 (weekly call)',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'ফোন নম্বর (ঐচ্ছিক)' : 'Phone (Optional)',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: giftController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: widget.isBangla ? 'উপহারের আইডিয়া (কমা দিয়ে আলাদা)' : 'Gift Ideas (comma-separated)',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        final cadence = int.tryParse(cadenceController.text.trim());
                        final gifts = giftController.text
                            .split(',')
                            .map((g) => g.trim())
                            .where((g) => g.isNotEmpty)
                            .toList();

                        if (name.isNotEmpty) {
                          widget.peopleService.addPerson(
                            name: name,
                            relationship: rel,
                            phone: phoneController.text.trim(),
                            cadenceDays: cadence,
                            giftIdeas: gifts,
                            notes: notesController.text.trim(),
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      child: Text(
                        widget.isBangla ? 'সংরক্ষণ করুন' : 'Save Person Profile',
                        style: AppTypography.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final people = widget.peopleService.allPeople;
    final overdue = widget.peopleService.overduePeople;
    final birthdays = widget.peopleService.upcomingBirthdays;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(
          widget.isBangla ? 'পরিচিতি ও সম্পর্ক' : 'People & Connections',
          style: AppTypography.screenTitle,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.bg,
        onPressed: _showAddPersonDialog,
        child: const Icon(Icons.person_add_alt_1, size: 26),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overdue Banner Alert
          if (overdue.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                border: Border.all(color: AppColors.errorRed),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notification_important, size: 18, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Text(
                        widget.isBangla ? 'যোগাযোগের সময় হয়েছে!' : 'TIME TO CONNECT!',
                        style: AppTypography.caption.copyWith(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isBangla
                        ? '${overdue.length} জনের সাথে যোগাযোগের নির্ধারিত সময় পার হয়েছে।'
                        : '${overdue.length} contact${overdue.length > 1 ? 's' : ''} overdue for regular check-in.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),

          // Upcoming Birthdays
          if (birthdays.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                border: Border.all(color: AppColors.accentLime),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, size: 20, color: AppColors.accentLime),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isBangla
                          ? 'আসন্ন জন্মদিন: ${birthdays.map((p) => p.name).join(', ')}'
                          : 'Upcoming birthdays: ${birthdays.map((p) => p.name).join(', ')}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

          // People List
          if (people.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      widget.isBangla ? 'কোনো পরিচিতি সংরক্ষিত নেই' : 'No people recorded yet',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isBangla
                          ? 'মা-বাবা, পরিবার, বন্ধু এবং শিক্ষকদের নিয়মিত খোঁজখবর রাখতে পরিচিতি যোগ করুন।'
                          : 'Add profiles with keep-in-touch cadence to stay connected intentionally.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...people.map((person) {
              final health = person.cadenceHealth;
              Color healthColor = AppColors.textSecondary;
              String healthLabel = 'No Cadence';

              switch (health) {
                case CadenceHealth.fresh:
                  healthColor = AppColors.accentLime;
                  healthLabel = widget.isBangla ? 'নিয়মিত' : 'Fresh';
                  break;
                case CadenceHealth.dueSoon:
                  healthColor = const Color(0xFFFFD700);
                  healthLabel = widget.isBangla ? 'শীঘ্রই' : 'Due Soon';
                  break;
                case CadenceHealth.overdue:
                  healthColor = AppColors.errorRed;
                  healthLabel = widget.isBangla ? 'বাকি আছে' : 'Overdue';
                  break;
                case CadenceHealth.none:
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surface2,
                      child: Text(
                        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(person.name, style: AppTypography.headingSmall),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  person.relationship.label(isBangla: widget.isBangla),
                                  style: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                person.cadenceDays != null
                                    ? '$healthLabel (Every ${person.cadenceDays}d)'
                                    : 'No cadence set',
                                style: AppTypography.caption.copyWith(color: healthColor),
                              ),
                            ],
                          ),
                          if (person.giftIdeas.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Gifts: ${person.giftIdeas.join(', ')}',
                              style: AppTypography.caption.copyWith(color: AppColors.accentLime),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_callback_outlined, color: AppColors.accentLime),
                      tooltip: widget.isBangla ? 'আজ যোগাযোগ হয়েছে' : 'Mark Contacted Today',
                      onPressed: () {
                        widget.peopleService.logInteraction(
                          person.id,
                          entriesRepo: widget.entriesRepo,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.isBangla
                                  ? '${person.name} এর সাথে যোগাযোগ লগ হয়েছে!'
                                  : 'Logged contact with ${person.name}!',
                            ),
                            backgroundColor: AppColors.accentLime,
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
