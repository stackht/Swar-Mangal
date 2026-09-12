import '../models/models.dart';

/// INITIAL Kandivali timetable (idempotent seed — applied only when the
/// backend timetable has never been initialised; founder edits are never
/// overwritten). This is BOTH the demo initial state and the reference the
/// held backend seed uses. Times are HH:mm (24h, IST).
const kandivaliTimetableSeed = <TimetableEntry>[
  // Monday [0]
  TimetableEntry(id: 'TT-MON-1', branch: 'KANDIVALI', dayOfWeek: 0, startTime: '17:00', endTime: '18:00', className: 'Keyboard'),
  TimetableEntry(id: 'TT-MON-2', branch: 'KANDIVALI', dayOfWeek: 0, startTime: '18:00', endTime: '19:00', className: 'Keyboard', teacherName: 'Rahul Sir'),
  TimetableEntry(id: 'TT-MON-3', branch: 'KANDIVALI', dayOfWeek: 0, startTime: '19:00', endTime: '20:00', className: 'Vocals', teacherName: 'Manmohan Sir'),
  TimetableEntry(id: 'TT-MON-4', branch: 'KANDIVALI', dayOfWeek: 0, startTime: '20:00', endTime: '21:00', className: 'Vocals', teacherName: 'Shweta Maam'),
  // Tuesday [1]
  TimetableEntry(id: 'TT-TUE-1', branch: 'KANDIVALI', dayOfWeek: 1, startTime: '18:00', endTime: '19:00', className: 'Flute'),
  TimetableEntry(id: 'TT-TUE-2', branch: 'KANDIVALI', dayOfWeek: 1, startTime: '19:00', endTime: '20:00', className: 'Flute'),
  TimetableEntry(id: 'TT-TUE-3', branch: 'KANDIVALI', dayOfWeek: 1, startTime: '20:00', endTime: '21:00', className: 'Flute', teacherName: 'Sharvil Sir'),
  // Wednesday [2]
  TimetableEntry(id: 'TT-WED-1', branch: 'KANDIVALI', dayOfWeek: 2, startTime: '14:00', endTime: '15:00', className: 'Vocals', teacherName: 'Manmohan Sir'),
  TimetableEntry(id: 'TT-WED-2', branch: 'KANDIVALI', dayOfWeek: 2, startTime: '17:00', endTime: '18:00', className: 'Keyboard'),
  TimetableEntry(id: 'TT-WED-3', branch: 'KANDIVALI', dayOfWeek: 2, startTime: '18:00', endTime: '19:00', className: 'Keyboard'),
  TimetableEntry(id: 'TT-WED-4', branch: 'KANDIVALI', dayOfWeek: 2, startTime: '19:00', endTime: '20:00', className: 'Keyboard'),
  // Thursday [3]
  TimetableEntry(id: 'TT-THU-1', branch: 'KANDIVALI', dayOfWeek: 3, startTime: '19:00', endTime: '20:00', className: 'Vocals', teacherName: 'Shweta Maam'),
  // Friday [4]
  TimetableEntry(id: 'TT-FRI-1', branch: 'KANDIVALI', dayOfWeek: 4, startTime: '18:00', endTime: '19:00', className: 'Flute'),
  TimetableEntry(id: 'TT-FRI-2', branch: 'KANDIVALI', dayOfWeek: 4, startTime: '19:00', endTime: '20:00', className: 'Flute'),
  TimetableEntry(id: 'TT-FRI-3', branch: 'KANDIVALI', dayOfWeek: 4, startTime: '20:00', endTime: '21:00', className: 'Flute'),
  // Saturday [5]
  TimetableEntry(id: 'TT-SAT-1', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '09:00', endTime: '10:00', className: 'Tabla', teacherName: 'Piyush Sir'),
  TimetableEntry(id: 'TT-SAT-2', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '10:00', endTime: '11:00', className: 'Violin', teacherName: 'Piyush Sir'),
  TimetableEntry(id: 'TT-SAT-3', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '14:00', endTime: '15:00', className: 'Vocals', teacherName: 'Manmohan Sir'),
  TimetableEntry(id: 'TT-SAT-4', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '15:00', endTime: '16:00', className: 'Vocals', teacherName: 'Manmohan Sir'),
  TimetableEntry(id: 'TT-SAT-5', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '18:00', endTime: '19:00', className: 'Guitar & Keyboard'),
  TimetableEntry(id: 'TT-SAT-6', branch: 'KANDIVALI', dayOfWeek: 5, startTime: '19:00', endTime: '20:00', className: 'Guitar & Keyboard'),
  // Sunday [6]
  TimetableEntry(id: 'TT-SUN-1', branch: 'KANDIVALI', dayOfWeek: 6, startTime: '12:00', endTime: '13:00', className: 'Flute'),
  TimetableEntry(id: 'TT-SUN-2', branch: 'KANDIVALI', dayOfWeek: 6, startTime: '13:00', endTime: '14:00', className: 'Flute'),
  TimetableEntry(id: 'TT-SUN-3', branch: 'KANDIVALI', dayOfWeek: 6, startTime: '14:00', endTime: '15:00', className: 'Vocals', teacherName: 'Piyush Sir'),
  TimetableEntry(id: 'TT-SUN-4', branch: 'KANDIVALI', dayOfWeek: 6, startTime: '16:00', endTime: '17:00', className: 'Mandip Tabla', teacherName: 'Piyush Sir'),
];