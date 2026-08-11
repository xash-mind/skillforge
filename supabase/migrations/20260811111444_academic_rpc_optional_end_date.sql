-- Keep open-ended timetables first-class in the generated Data API contract.
-- The hosted migration version is reconciled after controlled live apply.

create or replace function public.create_class_bundle(
  organization_id_input bigint,
  branch_id_input bigint,
  subject_id_input bigint,
  objective_id_input bigint,
  class_code_input text,
  class_name_input text,
  academic_year_input text,
  weekday_input smallint,
  starts_at_input time without time zone,
  ends_at_input time without time zone,
  room_input text,
  effective_from_input date,
  effective_to_input date default null
)
returns table (class_id bigint, timetable_entry_id bigint)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  selected_syllabus_id bigint;
  selected_version_id bigint;
  created_class_id bigint;
  created_timetable_id bigint;
begin
  select subject.syllabus_id, subject.syllabus_version_id
    into selected_syllabus_id, selected_version_id
  from public.subjects subject
  where subject.organization_id = organization_id_input
    and subject.id = subject_id_input
    and subject.status = 'active';

  if not found then
    raise exception 'active subject does not exist in this organization' using errcode = '23503';
  end if;

  insert into public.classes (
    organization_id,
    branch_id,
    subject_id,
    code,
    name,
    academic_year,
    created_by
  ) values (
    organization_id_input,
    branch_id_input,
    subject_id_input,
    class_code_input,
    class_name_input,
    academic_year_input,
    (select auth.uid())
  ) returning id into created_class_id;

  insert into public.class_objectives (
    organization_id,
    branch_id,
    class_id,
    subject_id,
    syllabus_id,
    syllabus_version_id,
    objective_id,
    created_by
  ) values (
    organization_id_input,
    branch_id_input,
    created_class_id,
    subject_id_input,
    selected_syllabus_id,
    selected_version_id,
    objective_id_input,
    (select auth.uid())
 );

  insert into public.timetable_entries (
    organization_id,
    branch_id,
    class_id,
    weekday,
    starts_at,
    ends_at,
    room,
    effective_from,
    effective_to,
    created_by
  ) values (
    organization_id_input,
    branch_id_input,
    created_class_id,
    weekday_input,
    starts_at_input,
    ends_at_input,
    nullif(btrim(room_input), ''),
    effective_from_input,
    effective_to_input,
    (select auth.uid())
  ) returning id into created_timetable_id;

  return query select created_class_id, created_timetable_id;
end;
$$;

comment on function public.create_class_bundle(
  bigint,
  bigint,
  bigint,
  bigint,
  text,
  text,
  text,
  smallint,
  time without time zone,
  time without time zone,
  text,
  date,
  date
) is 'Atomically creates a class, objective link, and open- or closed-ended timetable under caller RLS.';
