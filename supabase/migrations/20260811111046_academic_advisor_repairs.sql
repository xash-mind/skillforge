-- Follow-up generated from the first live TASK-003 performance-advisor pass.
-- The hosted migration version is reconciled after controlled live apply.

create index syllabuses_created_by_idx on public.syllabuses (created_by);
create index syllabus_versions_created_by_idx on public.syllabus_versions (created_by);
create index syllabus_objectives_created_by_idx on public.syllabus_objectives (created_by);
create index subjects_created_by_idx on public.subjects (created_by);
create index classes_created_by_idx on public.classes (created_by);
create index class_objectives_class_fk_idx
  on public.class_objectives (organization_id, branch_id, class_id, subject_id);
create index class_objectives_created_by_idx on public.class_objectives (created_by);
create index class_teachers_branch_membership_fk_idx
  on public.class_teachers (organization_id, branch_id, organization_membership_id);
create index class_teachers_created_by_idx on public.class_teachers (created_by);
create index class_enrollments_branch_membership_fk_idx
  on public.class_enrollments (organization_id, branch_id, organization_membership_id);
create index class_enrollments_created_by_idx on public.class_enrollments (created_by);
create index timetable_entries_class_fk_idx
  on public.timetable_entries (organization_id, branch_id, class_id);
create index timetable_entries_created_by_idx on public.timetable_entries (created_by);
