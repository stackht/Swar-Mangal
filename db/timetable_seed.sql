-- The real Kandivali timetable (25 weekly classes, Monday = 0), from
-- lib/data/kandivali_timetable_seed.dart. Loaded once, only into an empty timetable.
insert into timetable (id, branch, day_of_week, start_time, end_time, class_name, teacher_id, teacher_name, status) values
  ('TT-MON-1', 'KANDIVALI', 0, '17:00', '18:00', 'Keyboard', null, null, 'ENABLED'),
  ('TT-MON-2', 'KANDIVALI', 0, '18:00', '19:00', 'Keyboard', null, 'Rahul Sir', 'ENABLED'),
  ('TT-MON-3', 'KANDIVALI', 0, '19:00', '20:00', 'Vocals', null, 'Manmohan Sir', 'ENABLED'),
  ('TT-MON-4', 'KANDIVALI', 0, '20:00', '21:00', 'Vocals', null, 'Shweta Maam', 'ENABLED'),
  ('TT-TUE-1', 'KANDIVALI', 1, '18:00', '19:00', 'Flute', null, null, 'ENABLED'),
  ('TT-TUE-2', 'KANDIVALI', 1, '19:00', '20:00', 'Flute', null, null, 'ENABLED'),
  ('TT-TUE-3', 'KANDIVALI', 1, '20:00', '21:00', 'Flute', null, 'Sharvil Sir', 'ENABLED'),
  ('TT-WED-1', 'KANDIVALI', 2, '14:00', '15:00', 'Vocals', null, 'Manmohan Sir', 'ENABLED'),
  ('TT-WED-2', 'KANDIVALI', 2, '17:00', '18:00', 'Keyboard', null, null, 'ENABLED'),
  ('TT-WED-3', 'KANDIVALI', 2, '18:00', '19:00', 'Keyboard', null, null, 'ENABLED'),
  ('TT-WED-4', 'KANDIVALI', 2, '19:00', '20:00', 'Keyboard', null, null, 'ENABLED'),
  ('TT-THU-1', 'KANDIVALI', 3, '19:00', '20:00', 'Vocals', null, 'Shweta Maam', 'ENABLED'),
  ('TT-FRI-1', 'KANDIVALI', 4, '18:00', '19:00', 'Flute', null, null, 'ENABLED'),
  ('TT-FRI-2', 'KANDIVALI', 4, '19:00', '20:00', 'Flute', null, null, 'ENABLED'),
  ('TT-FRI-3', 'KANDIVALI', 4, '20:00', '21:00', 'Flute', null, null, 'ENABLED'),
  ('TT-SAT-1', 'KANDIVALI', 5, '09:00', '10:00', 'Tabla', null, 'Piyush Sir', 'ENABLED'),
  ('TT-SAT-2', 'KANDIVALI', 5, '10:00', '11:00', 'Violin', null, 'Piyush Sir', 'ENABLED'),
  ('TT-SAT-3', 'KANDIVALI', 5, '14:00', '15:00', 'Vocals', null, 'Manmohan Sir', 'ENABLED'),
  ('TT-SAT-4', 'KANDIVALI', 5, '15:00', '16:00', 'Vocals', null, 'Manmohan Sir', 'ENABLED'),
  ('TT-SAT-5', 'KANDIVALI', 5, '18:00', '19:00', 'Guitar & Keyboard', null, null, 'ENABLED'),
  ('TT-SAT-6', 'KANDIVALI', 5, '19:00', '20:00', 'Guitar & Keyboard', null, null, 'ENABLED'),
  ('TT-SUN-1', 'KANDIVALI', 6, '12:00', '13:00', 'Flute', null, null, 'ENABLED'),
  ('TT-SUN-2', 'KANDIVALI', 6, '13:00', '14:00', 'Flute', null, null, 'ENABLED'),
  ('TT-SUN-3', 'KANDIVALI', 6, '14:00', '15:00', 'Vocals', null, 'Piyush Sir', 'ENABLED'),
  ('TT-SUN-4', 'KANDIVALI', 6, '16:00', '17:00', 'Mandip Tabla', null, 'Piyush Sir', 'ENABLED')
on conflict (id) do nothing;
