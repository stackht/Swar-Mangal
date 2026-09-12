-- Swar Mangal Academy — seed data (Railway Postgres)
-- Demo-faithful IDs (s1, t1, c1, th1…) so existing screen filters keep resolving.
-- Idempotent: safe to run repeatedly.

insert into users (email, password_hash, role) values
  ('admin@maestro.app', '7502bb4665e6aff99c4f7b3f89dbfd49594aa359f669b6bca065e6755522b843d50085f48e260447ed05ab5403269a47ff2d6df4aa93341345e0bb7d4cc54c4e', 'admin'),
  ('sarah.mitchell@maestro.app', '7502bb4665e6aff99c4f7b3f89dbfd49594aa359f669b6bca065e6755522b843d50085f48e260447ed05ab5403269a47ff2d6df4aa93341345e0bb7d4cc54c4e', 'teacher'),
  ('aarav.sharma@maestro.app', '7502bb4665e6aff99c4f7b3f89dbfd49594aa359f669b6bca065e6755522b843d50085f48e260447ed05ab5403269a47ff2d6df4aa93341345e0bb7d4cc54c4e', 'student')
on conflict (email) do nothing;

insert into instruments (id, name, icon, color) values
  ('inst-1', 'Piano', 'Piano', '#8d6bf6'),
  ('inst-2', 'Guitar', 'Guitar', '#2dbd7f'),
  ('inst-3', 'Violin', 'Violin', '#ff8f3f'),
  ('inst-4', 'Drums', 'Drum', '#5b8def'),
  ('inst-5', 'Keyboard', 'KeyboardMusic', '#e0608a'),
  ('inst-6', 'Vocals', 'Mic2', '#8d6bf6'),
  ('inst-7', 'Flute', 'Waves', '#2dbd7f')
on conflict (id) do nothing;

insert into courses (id, name, instrument_id, level, description, color) values
  ('co1', 'Piano Fundamentals', 'inst-1', 'Beginner', 'Foundational piano technique', '#8d6bf6'),
  ('co2', 'Piano Advanced', 'inst-1', 'Advanced', 'Advanced repertoire and performance', '#8d6bf6')
on conflict (id) do nothing;

insert into teachers (id, full_name, email, instrument, rating) values
  ('t1', 'Sarah Mitchell', 'sarah.mitchell@maestro.app', 'Piano', 4.9),
  ('t2', 'David Chen', 'david.chen@maestro.app', 'Guitar', 4.8),
  ('t3', 'Emma Davis', 'emma.davis@maestro.app', 'Vocals', 4.7),
  ('t4', 'Liam Nguyen', 'liam.nguyen@maestro.app', 'Violin', 4.6)
on conflict (id) do nothing;

insert into students (id, full_name, email, instrument, level, fee_status) values
  ('s1', 'Aarav Sharma', 'aarav.sharma@maestro.app', 'Piano', 'Grade 3', 'paid'),
  ('s2', 'Meera Patel', 'meera.patel@maestro.app', 'Guitar', 'Beginner', 'pending'),
  ('s3', 'Kai Tanaka', 'kai.tanaka@maestro.app', 'Piano', 'Grade 4', 'paid'),
  ('s4', 'Zara Khan', 'zara.khan@maestro.app', 'Vocals', 'Intermediate', 'overdue'),
  ('s5', 'Leo Rossi', 'leo.rossi@maestro.app', 'Drums', 'Grade 2', 'paid'),
  ('s6', 'Isha Reddy', 'isha.reddy@maestro.app', 'Violin', 'Grade 3', 'pending'),
  ('s7', 'Noah Wilson', 'noah.wilson@maestro.app', 'Guitar', 'Intermediate', 'paid'),
  ('s8', 'Aisha Ali', 'aisha.ali@maestro.app', 'Flute', 'Beginner', 'paid'),
  ('s9', 'Ethan Moore', 'ethan.moore@maestro.app', 'Keyboard', 'Grade 2', 'partial'),
  ('s10', 'Priya Nair', 'priya.nair@maestro.app', 'Piano', 'Grade 5', 'paid')
on conflict (id) do nothing;

insert into classes (id, title, instrument, teacher_id, teacher_name, course_id, room, mode, status, recurring, start_time, end_time, duration_min, color) values
  ('c1', 'Piano Fundamentals', 'Piano', 't1', 'Sarah Mitchell', 'co1', 'Studio A', 'offline', 'scheduled', 'weekly', now() + interval '1 hour' * 17 + interval '30 minutes', now() + interval '1 hour' * 18 + interval '15 minutes', 45, '#8d6bf6'),
  ('c2', 'Piano Advanced', 'Piano', 't1', 'Sarah Mitchell', 'co2', 'Studio A', 'offline', 'scheduled', 'weekly', now() + interval '1 hour' * 10, now() + interval '1 hour' * 10 + interval '45 minutes', 45, '#8d6bf6'),
  ('c3', 'Guitar Beginner', 'Guitar', 't2', 'David Chen', null, 'Studio B', 'offline', 'scheduled', 'weekly', now() + interval '1 hour' * 11, now() + interval '1 hour' * 11 + interval '45 minutes', 45, '#2dbd7f'),
  ('c4', 'Guitar Intermediate', 'Guitar', 't2', 'David Chen', null, 'Room 2', 'offline', 'scheduled', 'weekly', now() + interval '1 day' + interval '1 hour' * 9, now() + interval '1 day' + interval '1 hour' * 9 + interval '45 minutes', 45, '#2dbd7f'),
  ('c5', 'Vocal Training', 'Vocals', 't3', 'Emma Davis', null, 'Zoom', 'online', 'scheduled', 'weekly', now() + interval '1 hour' * 12, now() + interval '1 hour' * 12 + interval '45 minutes', 45, '#e0608a'),
  ('c6', 'Violin Essentials', 'Violin', 't4', 'Liam Nguyen', null, 'Studio C', 'offline', 'scheduled', 'weekly', now() + interval '1 day' + interval '1 hour' * 18, now() + interval '1 day' + interval '1 hour' * 18 + interval '45 minutes', 45, '#ff8f3f'),
  ('c7', 'Drum Basics', 'Drums', 't4', 'Liam Nguyen', null, 'Drum Room', 'offline', 'scheduled', 'weekly', now() + interval '2 days' + interval '1 hour' * 16, now() + interval '2 days' + interval '1 hour' * 16 + interval '45 minutes', 45, '#5b8def')
on conflict (id) do nothing;

insert into class_students (class_id, student_id) values
  ('c1', 's1'), ('c1', 's3'), ('c2', 's10'), ('c3', 's2'), ('c3', 's8'),
  ('c4', 's7'), ('c5', 's4'), ('c6', 's6'), ('c7', 's5')
on conflict do nothing;

insert into attendance (id, class_id, student_id, status, date, marked_by) values
  ('a1', 'c1', 's1', 'present', now() - interval '7 days' + interval '1 hour' * 17 + interval '30 minutes', 't1'),
  ('a2', 'c1', 's3', 'present', now() - interval '7 days' + interval '1 hour' * 17 + interval '30 minutes', 't1'),
  ('a3', 'c1', 's1', 'late', now() - interval '14 days' + interval '1 hour' * 17 + interval '30 minutes', 't1'),
  ('a4', 'c1', 's3', 'absent', now() - interval '14 days' + interval '1 hour' * 17 + interval '30 minutes', 't1'),
  ('a5', 'c1', 's1', 'present', now() - interval '21 days' + interval '1 hour' * 17 + interval '30 minutes', 't1')
on conflict (id) do nothing;

insert into practice_sessions (id, student_id, instrument, activity, minutes, date, notes, goal_met) values
  ('p1', 's1', 'Piano', 'Scales & Arpeggios', 25, now() + interval '1 hour' * 8, 'Working on C major arpeggios', true),
  ('p2', 's1', 'Piano', 'Fur Elise', 30, now() - interval '1 day' + interval '1 hour' * 19, 'Section B needs work', true),
  ('p3', 's1', 'Piano', 'Sight Reading', 15, now() - interval '2 days' + interval '1 hour' * 7 + interval '30 minutes', null, false),
  ('p4', 's1', 'Piano', 'Scales & Arpeggios', 20, now() - interval '3 days' + interval '1 hour' * 18 + interval '30 minutes', null, true),
  ('p5', 's1', 'Piano', 'Warm-up Exercises', 10, now() - interval '4 days' + interval '1 hour' * 8 + interval '15 minutes', null, false),
  ('p6', 's1', 'Piano', 'Fur Elise', 35, now() - interval '5 days' + interval '1 hour' * 19 + interval '30 minutes', null, true),
  ('p7', 's2', 'Guitar', 'Chord Changes', 20, now() + interval '1 hour' * 9, null, null),
  ('p8', 's2', 'Guitar', 'Strumming Patterns', 15, now() - interval '1 day' + interval '1 hour' * 10, null, null)
on conflict (id) do nothing;

insert into assignments (id, title, description, instrument, difficulty, due_date, expected_minutes, teacher_id, teacher_name, student_id, status) values
  ('as1', 'Master Fur Elise — Section A', 'Play through Section A at a steady tempo. Focus on clean articulation.', 'Piano', 'intermediate', now() + interval '5 days' + interval '1 hour' * 20, 45, 't1', 'Sarah Mitchell', 's1', 'pending'),
  ('as2', 'C Major Scales — Two octaves', 'Both hands, hands together, at 90 bpm metronome.', 'Piano', 'beginner', now() + interval '3 days' + interval '1 hour' * 20, 30, 't1', 'Sarah Mitchell', 's1', 'submitted'),
  ('as3', 'Review Assessment — Grade 3', 'Prepare the three chosen pieces for next week''s assessment.', 'Piano', 'advanced', now() + interval '7 days' + interval '1 hour' * 20, 60, 't1', 'Sarah Mitchell', 's1', 'pending'),
  ('as4', 'Em Chord Transitions', 'Practice A to Em transitions smoothly. Record a video.', 'Guitar', 'beginner', now() + interval '4 days' + interval '1 hour' * 19, 25, 't2', 'David Chen', 's2', 'pending')
on conflict (id) do nothing;

insert into learning_resources (id, title, instrument, level, type, duration_min, author, favorite, audio_url) values
  ('r1', 'Fur Elise — Sheet Music', 'Piano', 'Grade 3', 'sheet_music', null, 'Beethoven', true, null),
  ('r2', 'C Major Scales Worksheet', 'Piano', 'All', 'scales', null, 'Swar Mangal', true, null),
  ('r3', 'Warm-up Exercise #1', 'Piano', 'Beginner', 'exercise', 10, 'Sarah Mitchell', false, null),
  ('r4', 'Basic Chord Progressions', 'Guitar', 'Beginner', 'chords', null, 'David Chen', false, null),
  ('r5', 'Ear Training — Intervals', 'All', 'Intermediate', 'theory', 15, 'Swar Mangal', false, null),
  ('r6', 'Amazing Grace (Audio)', 'Violin', 'Grade 2', 'audio', 4, 'Liam Nguyen', false, '/audio/demo.wav'),
  ('r7', 'Rhythm Counting Exercises', 'All', 'Grade 2', 'exercise', null, 'Sarah Mitchell', false, null),
  ('r8', 'Canon in D (Simplified)', 'Piano', 'Grade 4', 'song', null, 'Pachelbel', false, null),
  ('r9', 'Video Lesson — Posture', 'Piano', 'Beginner', 'video', 12, 'Sarah Mitchell', false, null)
on conflict (id) do nothing;

insert into progress_categories (id, name) values
  ('pc1', 'Technique'), ('pc2', 'Rhythm'), ('pc3', 'Sight Reading'), ('pc4', 'Ear Training'),
  ('pc5', 'Music Theory'), ('pc6', 'Performance'), ('pc7', 'Repertoire')
on conflict (id) do nothing;

insert into progress (id, student_id, category, score, instrument, level) values
  ('pg1', 's1', 'Technique', 78, 'Piano', 'Grade 3'),
  ('pg2', 's1', 'Rhythm', 65, 'Piano', 'Grade 3'),
  ('pg3', 's1', 'Sight Reading', 52, 'Piano', 'Grade 3'),
  ('pg4', 's1', 'Ear Training', 60, 'Piano', 'Grade 3'),
  ('pg5', 's1', 'Music Theory', 70, 'Piano', 'Grade 3'),
  ('pg6', 's1', 'Performance', 74, 'Piano', 'Grade 3'),
  ('pg7', 's1', 'Repertoire', 66, 'Piano', 'Grade 3')
on conflict (id) do nothing;

insert into message_threads (id) values ('th1'), ('th2') on conflict (id) do nothing;

insert into message_participants (thread_id, participant_name, participant_id) values
  ('th1', 'Aarav Sharma', 's1'), ('th1', 'Sarah Mitchell', 't1'),
  ('th2', 'Aarav Sharma', 's1'), ('th2', 'David Chen', 't2')
on conflict do nothing;

insert into messages (id, thread_id, sender_id, sender_name, body, created_at) values
  ('m1', 'th1', 't1', 'Sarah Mitchell', 'Great progress today! Let''s keep working on the arpeggios.', now() + interval '1 hour' * 13 + interval '30 minutes'),
  ('m2', 'th1', 's1', 'Aarav Sharma', 'Thank you! I''ll practice the E minor section tonight.', now() + interval '1 hour' * 13 + interval '45 minutes'),
  ('m3', 'th1', 't1', 'Sarah Mitchell', 'Perfect. See you Thursday for the assessment.', now() + interval '1 hour' * 13 + interval '50 minutes')
on conflict (id) do nothing;

insert into notifications (id, user_id, title, body, type, read, created_at) values
  ('n1', 's1', 'Upcoming class', 'Piano Fundamentals today at 5:30 PM', 'class', false, now() + interval '1 hour' * 8),
  ('n2', 's1', 'Assignment feedback', 'Sarah reviewed your C Major Scales assignment', 'assignment', false, now() - interval '1 day' + interval '1 hour' * 14),
  ('n3', 's1', 'Practice streak', 'You''ve practiced 3 days in a row! Keep going.', 'practice', true, now() - interval '1 day' + interval '1 hour' * 20),
  ('n4', 's1', 'New announcement', 'Recital registration now open for November.', 'announcement', true, now() - interval '2 days' + interval '1 hour' * 9)
on conflict (id) do nothing;

insert into announcements (id, title, body, author, audience, pinned, created_at) values
  ('an1', 'November Recital — Registration Open', 'We''re excited to announce our upcoming student recital. Register your slot by October 20.', 'The Swar Mangal Team', 'All students', true, now() - interval '2 days' + interval '1 hour' * 9),
  ('an2', 'Holiday Notice — Diwali', 'The academy will be closed from Oct 30 – Nov 1 for Diwali.', 'Academy Office', 'All', false, now() - interval '5 days' + interval '1 hour' * 12),
  ('an3', 'New Practice Challenge', 'Complete 20 practice hours this quarter and earn a special badge!', 'The Swar Mangal Team', 'All students', false, now() - interval '9 days' + interval '1 hour' * 10)
on conflict (id) do nothing;

insert into invoices (id, student_id, student_name, description, amount, status, issued_date, due_date) values
  ('inv1', 's1', 'Aarav Sharma', 'Monthly tuition — October', 120, 'paid', now() - interval '20 days', now() + interval '10 days'),
  ('inv2', 's2', 'Meera Patel', 'Monthly tuition — October', 120, 'pending', now() - interval '5 days', now() + interval '15 days'),
  ('inv3', 's4', 'Zara Khan', 'Monthly tuition — September', 120, 'overdue', now() - interval '25 days', now() - interval '5 days'),
  ('inv4', 's10', 'Priya Nair', 'Monthly tuition — October', 150, 'paid', now() - interval '3 days', now() + interval '12 days')
on conflict (id) do nothing;

insert into payments (id, invoice_id, student_name, amount, method, status, paid_at) values
  ('pay1', 'inv1', 'Aarav Sharma', 120, 'Card', 'paid', now() - interval '3 days'),
  ('pay2', 'inv4', 'Priya Nair', 150, 'UPI', 'paid', now() - interval '2 days'),
  ('pay3', null, 'Leo Rossi', 130, 'Bank transfer', 'paid', now() - interval '1 day')
on conflict (id) do nothing;

insert into achievements (id, student_id, title, description, icon, earned_at) values
  ('ach1', 's1', '7-Day Streak', 'Practiced for 7 days in a row', 'Flame', now() - interval '3 days'),
  ('ach2', 's1', '10 Hours Practiced', 'Reached 10 total practice hours', 'Clock', now() - interval '10 days'),
  ('ach3', 's1', 'First Assessment Passed', 'Passed Grade 2 assessment with distinction', 'Trophy', now() - interval '40 days')
on conflict (id) do nothing;

insert into teacher_feedback (id, student_id, teacher_id, teacher_name, body, category, created_at) values
  ('fb1', 's1', 't1', 'Sarah Mitchell', 'Great progress on arpeggios! Keep your wrist relaxed and focus on even tempo.', 'Technique', now() - interval '1 day' + interval '1 hour' * 13),
  ('fb2', 's1', 't1', 'Sarah Mitchell', 'Excellent rhythm on the sight-reading today. Try tapping your foot to keep time.', 'Rhythm', now() - interval '4 days' + interval '1 hour' * 12 + interval '30 minutes')
on conflict (id) do nothing;