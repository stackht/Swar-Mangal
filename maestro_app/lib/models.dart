DateTime at(DateTime d, int hour, [int min = 0]) =>
    DateTime(d.year, d.month, d.day, hour, min);

DateTime onDay(int offset, int hour, [int min = 0]) =>
    at(DateTime.now().add(Duration(days: offset)), hour, min);

const List<String> weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final ap = t.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ap';
}

String fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
  if (d.year == now.year && d.month == now.month && d.day == now.day + 1) return 'Tomorrow';
  return '${months[d.month - 1]} ${d.day}';
}

// ---------- Models ----------

class Lesson {
  final String id;
  final String title;
  final String instrument;
  final String teacher;
  final DateTime start;
  final DateTime end;
  final String room;
  final String mode;
  final String color;

  int get minutes => end.difference(start).inMinutes;

  const Lesson({
    required this.id,
    required this.title,
    required this.instrument,
    required this.teacher,
    required this.start,
    required this.end,
    required this.room,
    required this.mode,
    required this.color,
  });
}

class Student {
  final String id;
  final String name;
  final String instrument;
  final String level;
  final String fee;
  const Student({required this.id, required this.name, required this.instrument, required this.level, required this.fee});
}

class Assignment {
  final String id;
  final String title;
  final String detail;
  final String teacher;
  final DateTime due;
  final String difficulty;
  String status;
  Assignment({required this.id, required this.title, required this.detail, required this.teacher, required this.due, this.difficulty = 'Intermediate', this.status = 'pending'});
}

class PracticeSession {
  final String id;
  final String instrument;
  final String activity;
  final int minutes;
  final DateTime date;
  const PracticeSession({required this.id, required this.instrument, required this.activity, required this.minutes, required this.date});
}

class ResourceItem {
  final String id;
  final String title;
  final String instrument;
  final String level;
  final String type;
  final String? author;
  bool favorite;
  ResourceItem({required this.id, required this.title, required this.instrument, required this.level, required this.type, this.author, this.favorite = false});
}

class Skill {
  final String name;
  final int score;
  const Skill(this.name, this.score);
}

class FeedbackItem {
  final String teacher;
  final String category;
  final String body;
  final DateTime date;
  const FeedbackItem({required this.teacher, required this.category, required this.body, required this.date});
}

class Achievement {
  final String title;
  final String detail;
  final String icon;
  const Achievement(this.title, this.detail, this.icon);
}

class ActivityItem {
  final String title;
  final String detail;
  final DateTime date;
  const ActivityItem(this.title, this.detail, this.date);
}

class NotificationItem {
  final String title;
  final String body;
  final DateTime date;
  bool read;
  NotificationItem({required this.title, required this.body, required this.date, this.read = false});
}

class Invoice {
  final String description;
  final double amount;
  final DateTime due;
  String status;
  Invoice({required this.description, required this.amount, required this.due, this.status = 'pending'});
}

// ---------- State (in-memory, survives within the session) ----------

const Map<String, List<String>> lessonStudents = {
  'c1': ['s1', 's3'],
  'c2': ['s1'],
  'c3': ['s2', 's5'],
  'c4': ['s4'],
  'c5': ['s2'],
  'c6': ['s6'],
  'c7': ['s5'],
};

const Map<String, Student> students = {
  's1': Student(id: 's1', name: 'Aarav Sharma', instrument: 'Piano', level: 'Grade 3', fee: 'paid'),
  's2': Student(id: 's2', name: 'Meera Patel', instrument: 'Guitar', level: 'Beginner', fee: 'pending'),
  's3': Student(id: 's3', name: 'Kai Tanaka', instrument: 'Piano', level: 'Grade 4', fee: 'paid'),
  's4': Student(id: 's4', name: 'Zara Khan', instrument: 'Vocals', level: 'Intermediate', fee: 'overdue'),
  's5': Student(id: 's5', name: 'Leo Rossi', instrument: 'Drums', level: 'Grade 2', fee: 'paid'),
  's6': Student(id: 's6', name: 'Isha Reddy', instrument: 'Violin', level: 'Grade 3', fee: 'pending'),
};

String instrumentIcon(String name) {
  switch (name) {
    case 'Piano':
    case 'Keyboard':
      return '🎹';
    case 'Guitar':
      return '🎸';
    case 'Violin':
    case 'Flute':
      return '🎻';
    case 'Drums':
      return '🥁';
    case 'Vocals':
      return '🎤';
    default:
      return '🎼';
  }
}

List<Lesson> myLessons(String studentId) =>
    allLessons.where((l) => (lessonStudents[l.id] ?? []).contains(studentId)).toList();

List<Lesson> allLessons = [
  Lesson(id: 'c1', title: 'Piano Fundamentals', instrument: 'Piano', teacher: 'Sarah Mitchell',
      start: onDay(0, 17, 30), end: onDay(0, 18, 15), room: 'Studio A', mode: 'offline', color: '#8D6BF6'),
  Lesson(id: 'c2', title: 'Piano Advanced', instrument: 'Piano', teacher: 'Sarah Mitchell',
      start: onDay(0, 10, 0), end: onDay(0, 10, 45), room: 'Studio A', mode: 'offline', color: '#8D6BF6'),
  Lesson(id: 'c3', title: 'Guitar Beginner', instrument: 'Guitar', teacher: 'David Chen',
      start: onDay(0, 11, 0), end: onDay(0, 11, 45), room: 'Studio B', mode: 'offline', color: '#2DBD7F'),
  Lesson(id: 'c4', title: 'Vocal Training', instrument: 'Vocals', teacher: 'Emma Davis',
      start: onDay(0, 12, 0), end: onDay(0, 12, 45), room: 'Zoom', mode: 'online', color: '#E0608A'),
  Lesson(id: 'c5', title: 'Guitar Intermediate', instrument: 'Guitar', teacher: 'David Chen',
      start: onDay(1, 9, 0), end: onDay(1, 9, 45), room: 'Room 2', mode: 'offline', color: '#2DBD7F'),
  Lesson(id: 'c6', title: 'Violin Essentials', instrument: 'Violin', teacher: 'Liam Nguyen',
      start: onDay(1, 18, 0), end: onDay(1, 18, 45), room: 'Studio C', mode: 'offline', color: '#FF8F3F'),
  Lesson(id: 'c7', title: 'Drum Basics', instrument: 'Drums', teacher: 'Liam Nguyen',
      start: onDay(2, 16, 0), end: onDay(2, 16, 45), room: 'Drum Room', mode: 'offline', color: '#5B8DEF'),
  Lesson(id: 'c8', title: 'Flute Beginner', instrument: 'Flute', teacher: 'Emma Davis',
      start: onDay(3, 15, 0), end: onDay(3, 15, 45), room: 'Room 3', mode: 'offline', color: '#52D69B'),
];

final List<Assignment> myAssignments = [
  Assignment(id: 'a1', title: 'Master Fur Elise — Section A',
      detail: 'Play through Section A at a steady tempo with clean articulation.',
      teacher: 'Sarah Mitchell', due: onDay(5, 20)),
  Assignment(id: 'a2', title: 'C Major Scales — Two octaves',
      detail: 'Both hands together at 90 bpm metronome.',
      teacher: 'Sarah Mitchell', due: onDay(3, 20), status: 'submitted'),
  Assignment(id: 'a3', title: 'Review Assessment — Grade 3',
      detail: 'Prepare the three chosen pieces for this week\'s assessment.',
      teacher: 'Sarah Mitchell', due: onDay(7, 20)),
];

final List<PracticeSession> practiceSessions = [
  PracticeSession(id: 'p1', instrument: 'Piano', activity: 'Scales & Arpeggios', minutes: 25, date: onDay(0, 8)),
  PracticeSession(id: 'p2', instrument: 'Piano', activity: 'Fur Elise', minutes: 30, date: onDay(-1, 19)),
  PracticeSession(id: 'p3', instrument: 'Piano', activity: 'Sight Reading', minutes: 15, date: onDay(-2, 7)),
  PracticeSession(id: 'p4', instrument: 'Piano', activity: 'Scales & Arpeggios', minutes: 20, date: onDay(-3, 18)),
  PracticeSession(id: 'p5', instrument: 'Piano', activity: 'Warm-up Exercises', minutes: 10, date: onDay(-4, 8)),
  PracticeSession(id: 'p6', instrument: 'Piano', activity: 'Fur Elise', minutes: 35, date: onDay(-5, 19)),
];

final List<Skill> skills = [
  const Skill('Technique', 78),
  const Skill('Rhythm', 65),
  const Skill('Sight Reading', 52),
  const Skill('Ear Training', 60),
  const Skill('Music Theory', 70),
  const Skill('Performance', 74),
  const Skill('Repertoire', 66),
];

int get overallSkill =>
    skills.fold(0, (sum, s) => sum + s.score) ~/ skills.length;

final List<FeedbackItem> feedbackList = [
  FeedbackItem(teacher: 'Sarah Mitchell', category: 'Technique',
      body: 'Great progress on arpeggios! Keep your wrist relaxed and even your tempo.', date: onDay(-1, 13)),
  FeedbackItem(teacher: 'Sarah Mitchell', category: 'Rhythm',
      body: 'Excellent rhythm on sight-reading. Try tapping your foot to keep time.', date: onDay(-4, 12)),
];

final List<Achievement> achievements = const [
  Achievement('7-Day Streak', 'Practiced 7 days in a row', 'F'),
  Achievement('10 Hours Practiced', 'Reached 10 total practice hours', 'C'),
  Achievement('First Assessment Passed', 'Passed Grade 2 with distinction', 'T'),
];

final List<ActivityItem> activity = [
  ActivityItem('Lesson completed', 'Piano Fundamentals with Sarah Mitchell', onDay(-1, 18)),
  ActivityItem('Assignment submitted', 'C Major Scales — Two octaves', onDay(-1, 19)),
  ActivityItem('Practice session', '30 min — Fur Elise', onDay(-1, 19)),
  ActivityItem('Teacher feedback', 'Sarah left feedback on your performance', onDay(-1, 13)),
];

final List<NotificationItem> notifications = [
  NotificationItem(title: 'Upcoming class', body: 'Piano Fundamentals today at 5:30 PM', date: onDay(0, 8)),
  NotificationItem(title: 'Assignment feedback', body: 'Sarah reviewed your C Major Scales assignment', date: onDay(-1, 14)),
  NotificationItem(title: 'Practice streak', body: 'You\'ve practiced 3 days in a row — keep going!', date: onDay(-1, 20), read: true),
  NotificationItem(title: 'New announcement', body: 'Recital registration now open for November.', date: onDay(-2, 9), read: true),
];

final List<Invoice> invoices = [
  Invoice(description: 'Monthly tuition — October', amount: 120, due: onDay(10, 0), status: 'paid'),
  Invoice(description: 'Monthly tuition — September', amount: 120, due: onDay(-6, 0), status: 'paid'),
];

final List<ResourceItem> library = [
  ResourceItem(id: 'r1', title: 'Fur Elise — Sheet Music', instrument: 'Piano', level: 'Grade 3', type: 'Sheet Music', author: 'Beethoven', favorite: true),
  ResourceItem(id: 'r2', title: 'C Major Scales Worksheet', instrument: 'Piano', level: 'All', type: 'Scales', author: 'Swar Mangal', favorite: true),
  ResourceItem(id: 'r3', title: 'Warm-up Exercise #1', instrument: 'Piano', level: 'Beginner', type: 'Exercise', author: 'Sarah Mitchell'),
  ResourceItem(id: 'r4', title: 'Basic Chord Progressions', instrument: 'Guitar', level: 'Beginner', type: 'Chords', author: 'David Chen'),
  ResourceItem(id: 'r5', title: 'Ear Training — Intervals', instrument: 'All', level: 'Intermediate', type: 'Theory'),
  ResourceItem(id: 'r6', title: 'Rhythm Counting Exercises', instrument: 'All', level: 'Grade 2', type: 'Exercise', author: 'Sarah Mitchell'),
  ResourceItem(id: 'r7', title: 'Canon in D (Simplified)', instrument: 'Piano', level: 'Grade 4', type: 'Song', author: 'Pachelbel'),
];

final List<int> weeklyMinutes = [18, 32, 0, 25, 40, 30, 22];

final List<String> teacherStudentNames = ['Aarav Sharma', 'Kai Tanaka', 'Meera Patel', 'Priya Nair'];
final Map<String, int> teacherPractice = {'Aarav Sharma': 93, 'Kai Tanaka': 71, 'Meera Patel': 32, 'Priya Nair': 108};

int practiceMinutes() => practiceSessions.fold(0, (sum, p) => sum + p.minutes);

int practiceMinutesToday() {
  final now = DateTime.now();
  return practiceSessions
      .where((p) => p.date.year == now.year && p.date.month == now.month && p.date.day == now.day)
      .fold(0, (sum, p) => sum + p.minutes);
}