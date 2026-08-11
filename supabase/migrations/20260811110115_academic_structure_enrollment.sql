-- TASK-003: academic structure, enrollment, timetables, and branch-scoped access.
-- The hosted migration version is reconciled after controlled live apply.

alter table public.branch_memberships
  add constraint branch_memberships_organization_branch_membership_key
  unique (organization_id, branch_id, organization_membership_id);

create table public.syllabuses (
  id bigint generated always as identity primary key,
  organization_id bigint references public.organizations (id) on delete restrict,
  scope text not null,
  code text not null,
  title text not null,
  description text,
  status text not null default 'draft',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint syllabuses_scope_owner_check check (
    (scope = 'platform_library' and organization_id is null)
    or (scope = 'organization_custom' and organization_id is not null)
  ),
  constraint syllabuses_code_format check (
    char_length(code) between 2 and 40
    and code ~ '^[A-Z0-9]+(?:-[A-Z0-9]+)*$'
  ),
  constraint syllabuses_title_length check (char_length(title) between 2 and 180),
  constraint syllabuses_description_length check (
    description is null or char_length(description) between 1 and 2000
  ),
  constraint syllabuses_status_check check (status in ('draft', 'published', 'archived'))
);

create unique index syllabuses_platform_code_key
  on public.syllabuses (code)
  where organization_id is null;
create unique index syllabuses_organization_code_key
  on public.syllabuses (organization_id, code)
  where organization_id is not null;

create table public.syllabus_versions (
  id bigint generated always as identity primary key,
  syllabus_id bigint not null references public.syllabuses (id) on delete restrict,
  organization_id bigint references public.organizations (id) on delete restrict,
  version_label text not null,
  status text not null default 'draft',
  published_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint syllabus_versions_label_length check (
    char_length(version_label) between 1 and 80
  ),
  constraint syllabus_versions_status_check check (
    status in ('draft', 'published', 'archived')
  ),
  constraint syllabus_versions_published_at_check check (
    (status = 'draft' and published_at is null)
    or (status in ('published', 'archived') and published_at is not null)
  ),
  constraint syllabus_versions_syllabus_label_key unique (syllabus_id, version_label),
  constraint syllabus_versions_syllabus_id_id_key unique (syllabus_id, id)
);

create table public.syllabus_objectives (
  id bigint generated always as identity primary key,
  syllabus_id bigint not null,
  syllabus_version_id bigint not null,
  organization_id bigint references public.organizations (id) on delete restrict,
  parent_objective_id bigint,
  code text not null,
  title text not null,
  description text,
  sequence_number integer not null default 1,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint syllabus_objectives_version_fkey foreign key (syllabus_id, syllabus_version_id)
    references public.syllabus_versions (syllabus_id, id) on delete restrict,
  constraint syllabus_objectives_parent_fkey foreign key (
    syllabus_version_id,
    parent_objective_id
  ) references public.syllabus_objectives (syllabus_version_id, id) on delete restrict,
  constraint syllabus_objectives_code_format check (
    char_length(code) between 1 and 50
    and code ~ '^[A-Z0-9]+(?:[.-][A-Z0-9]+)*$'
  ),
  constraint syllabus_objectives_title_length check (char_length(title) between 2 and 240),
  constraint syllabus_objectives_description_length check (
    description is null or char_length(description) between 1 and 4000
  ),
  constraint syllabus_objectives_sequence_positive check (sequence_number > 0),
  constraint syllabus_objectives_version_code_key unique (syllabus_version_id, code),
  constraint syllabus_objectives_version_id_id_key unique (syllabus_version_id, id),
  constraint syllabus_objectives_lineage_key unique (
    syllabus_id,
    syllabus_version_id,
    id
  )
);

create table public.subjects (
  id bigint generated always as identity primary key,
  organization_id bigint not null references public.organizations (id) on delete restrict,
  syllabus_id bigint not null,
  syllabus_version_id bigint not null,
  code text not null,
  name text not null,
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint subjects_syllabus_version_fkey foreign key (syllabus_id, syllabus_version_id)
    references public.syllabus_versions (syllabus_id, id) on delete restrict,
  constraint subjects_code_format check (
    char_length(code) between 2 and 32
    and code ~ '^[A-Z0-9]+(?:-[A-Z0-9]+)*$'
  ),
  constraint subjects_name_length check (char_length(name) between 2 and 120),
  constraint subjects_status_check check (status in ('active', 'archived')),
  constraint subjects_organization_code_key unique (organization_id, code),
  constraint subjects_organization_id_id_key unique (organization_id, id),
  constraint subjects_academic_lineage_key unique (
    organization_id,
    id,
    syllabus_id,
    syllabus_version_id
  )
);

create table public.classes (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  subject_id bigint not null,
  code text not null,
  name text not null,
  academic_year text not null,
  status text not null default 'planned',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint classes_branch_fkey foreign key (organization_id, branch_id)
    references public.branches (organization_id, id) on delete restrict,
  constraint classes_subject_fkey foreign key (organization_id, subject_id)
    references public.subjects (organization_id, id) on delete restrict,
  constraint classes_code_format check (
    char_length(code) between 2 and 32
    and code ~ '^[A-Z0-9]+(?:-[A-Z0-9]+)*$'
  ),
  constraint classes_name_length check (char_length(name) between 2 and 140),
  constraint classes_academic_year_length check (char_length(academic_year) between 4 and 24),
  constraint classes_status_check check (status in ('planned', 'active', 'completed', 'archived')),
  constraint classes_branch_code_key unique (branch_id, code),
  constraint classes_organization_branch_id_key unique (organization_id, branch_id, id),
  constraint classes_subject_lineage_key unique (
    organization_id,
    branch_id,
    id,
    subject_id
  )
);

create table public.class_objectives (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  subject_id bigint not null,
  syllabus_id bigint not null,
  syllabus_version_id bigint not null,
  objective_id bigint not null,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  constraint class_objectives_class_fkey foreign key (
    organization_id,
    branch_id,
    class_id,
    subject_id
  ) references public.classes (organization_id, branch_id, id, subject_id) on delete restrict,
  constraint class_objectives_subject_fkey foreign key (
    organization_id,
    subject_id,
    syllabus_id,
    syllabus_version_id
  ) references public.subjects (
    organization_id,
    id,
    syllabus_id,
    syllabus_version_id
  ) on delete restrict,
  constraint class_objectives_objective_fkey foreign key (
    syllabus_id,
    syllabus_version_id,
    objective_id
  ) references public.syllabus_objectives (
    syllabus_id,
    syllabus_version_id,
    id
  ) on delete restrict,
  constraint class_objectives_class_objective_key unique (class_id, objective_id)
);

create table public.class_teachers (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  organization_membership_id bigint not null,
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint class_teachers_class_fkey foreign key (organization_id, branch_id, class_id)
    references public.classes (organization_id, branch_id, id) on delete restrict,
  constraint class_teachers_branch_membership_fkey foreign key (
    organization_id,
    branch_id,
    organization_membership_id
  ) references public.branch_memberships (
    organization_id,
    branch_id,
    organization_membership_id
  ) on delete restrict,
  constraint class_teachers_status_check check (status in ('active', 'removed')),
  constraint class_teachers_class_membership_key unique (class_id, organization_membership_id)
);

create table public.class_enrollments (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  organization_membership_id bigint not null,
  status text not null default 'enrolled',
  enrolled_at timestamptz not null default statement_timestamp(),
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint class_enrollments_class_fkey foreign key (organization_id, branch_id, class_id)
    references public.classes (organization_id, branch_id, id) on delete restrict,
  constraint class_enrollments_branch_membership_fkey foreign key (
    organization_id,
    branch_id,
    organization_membership_id
  ) references public.branch_memberships (
    organization_id,
    branch_id,
    organization_membership_id
  ) on delete restrict,
  constraint class_enrollments_status_check check (
    status in ('enrolled', 'paused', 'withdrawn', 'completed')
  ),
  constraint class_enrollments_class_membership_key unique (
    class_id,
    organization_membership_id
  )
);

create table public.timetable_entries (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  weekday smallint not null,
  starts_at time without time zone not null,
  ends_at time without time zone not null,
  room text,
  effective_from date not null,
  effective_to date,
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint timetable_entries_class_fkey foreign key (organization_id, branch_id, class_id)
    references public.classes (organization_id, branch_id, id) on delete restrict,
  constraint timetable_entries_weekday_check check (weekday between 1 and 7),
  constraint timetable_entries_time_order_check check (ends_at > starts_at),
  constraint timetable_entries_effective_range_check check (
    effective_to is null or effective_to >= effective_from
  ),
  constraint timetable_entries_room_length check (room is null or char_length(room) <= 120),
  constraint timetable_entries_status_check check (status in ('active', 'cancelled')),
  constraint timetable_entries_slot_key unique (
    class_id,
    weekday,
    starts_at,
    effective_from
  )
);

create index syllabus_versions_syllabus_status_idx
  on public.syllabus_versions (syllabus_id, status);
create index syllabus_versions_organization_id_idx
  on public.syllabus_versions (organization_id)
  where organization_id is not null;
create index syllabus_objectives_syllabus_id_idx
  on public.syllabus_objectives (syllabus_id);
create index syllabus_objectives_organization_id_idx
  on public.syllabus_objectives (organization_id)
  where organization_id is not null;
create index syllabus_objectives_parent_idx
  on public.syllabus_objectives (syllabus_version_id, parent_objective_id)
  where parent_objective_id is not null;
create index subjects_syllabus_version_idx
  on public.subjects (syllabus_id, syllabus_version_id);
create index classes_organization_subject_idx
  on public.classes (organization_id, subject_id, status);
create index classes_branch_status_idx
  on public.classes (organization_id, branch_id, status);
create index class_objectives_class_idx
  on public.class_objectives (organization_id, branch_id, class_id);
create index class_objectives_subject_idx
  on public.class_objectives (organization_id, subject_id, syllabus_id, syllabus_version_id);
create index class_objectives_objective_idx
  on public.class_objectives (syllabus_id, syllabus_version_id, objective_id);
create index class_teachers_membership_idx
  on public.class_teachers (organization_id, organization_membership_id, status);
create index class_teachers_branch_class_idx
  on public.class_teachers (organization_id, branch_id, class_id, status);
create index class_enrollments_membership_idx
  on public.class_enrollments (organization_id, organization_membership_id, status);
create index class_enrollments_branch_class_idx
  on public.class_enrollments (organization_id, branch_id, class_id, status);
create index timetable_entries_branch_date_idx
  on public.timetable_entries (organization_id, branch_id, effective_from, effective_to);

create or replace function private.sync_syllabus_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_organization_id bigint;
begin
  select syllabus.organization_id
    into resolved_organization_id
  from public.syllabuses syllabus
  where syllabus.id = new.syllabus_id;

  if not found then
    raise exception 'syllabus does not exist' using errcode = '23503';
  end if;

  new.organization_id := resolved_organization_id;
  return new;
end;
$$;

create or replace function private.sync_objective_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_organization_id bigint;
begin
  select version.organization_id
    into resolved_organization_id
  from public.syllabus_versions version
  where version.id = new.syllabus_version_id
    and version.syllabus_id = new.syllabus_id;

  if not found then
    raise exception 'syllabus version does not exist' using errcode = '23503';
  end if;

  new.organization_id := resolved_organization_id;
  return new;
end;
$$;

create or replace function private.protect_published_objectives()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_version_id bigint;
  version_status text;
begin
  target_version_id := case when tg_op = 'DELETE' then old.syllabus_version_id else new.syllabus_version_id end;

  select version.status
    into version_status
  from public.syllabus_versions version
  where version.id = target_version_id;

  if version_status is distinct from 'draft' then
    raise exception 'published syllabus objectives are immutable' using errcode = '55000';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create or replace function private.enforce_syllabus_version_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'archived' and new is distinct from old then
    raise exception 'archived syllabus versions are immutable' using errcode = '55000';
  end if;

  if old.status = 'published' and new.version_label is distinct from old.version_label then
    raise exception 'published syllabus version labels are immutable' using errcode = '55000';
  end if;

  if old.status = 'published' and new.status not in ('published', 'archived') then
    raise exception 'published syllabus versions may only be archived' using errcode = '55000';
  end if;

  if old.status = 'draft' and new.status = 'published' then
    if not exists (
      select 1
      from public.syllabus_objectives objective
      where objective.syllabus_version_id = old.id
    ) then
      raise exception 'a syllabus version needs at least one objective before publication'
        using errcode = '23514';
    end if;
    new.published_at := statement_timestamp();
  elsif new.status = 'draft' then
    new.published_at := null;
  end if;

  return new;
end;
$$;

create or replace function private.enforce_syllabus_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'published' and old.status is distinct from 'published' and not exists (
    select 1
    from public.syllabus_versions version
    where version.syllabus_id = old.id
      and version.status = 'published'
  ) then
    raise exception 'a syllabus needs a published version before publication' using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.validate_subject_syllabus()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  syllabus_owner bigint;
  syllabus_scope text;
  syllabus_status text;
  version_status text;
begin
  select syllabus.organization_id, syllabus.scope, syllabus.status, version.status
    into syllabus_owner, syllabus_scope, syllabus_status, version_status
  from public.syllabuses syllabus
  join public.syllabus_versions version
    on version.syllabus_id = syllabus.id
   and version.id = new.syllabus_version_id
  where syllabus.id = new.syllabus_id;

  if not found then
    raise exception 'syllabus version does not exist' using errcode = '23503';
  end if;

  if syllabus_status <> 'published' or version_status <> 'published' then
    raise exception 'subjects require a published syllabus version' using errcode = '23514';
  end if;

  if not (
    (syllabus_scope = 'platform_library' and syllabus_owner is null)
    or (
      syllabus_scope = 'organization_custom'
      and syllabus_owner = new.organization_id
    )
  ) then
    raise exception 'syllabus is not available to this organization' using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.validate_class_participant_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  required_role text;
begin
  required_role := case tg_table_name
    when 'class_teachers' then 'teacher'
    when 'class_enrollments' then 'student'
    else null
  end;

  if required_role is null or not exists (
    select 1
    from public.organization_memberships membership
    join public.branch_memberships branch_membership
      on branch_membership.organization_id = membership.organization_id
     and branch_membership.organization_membership_id = membership.id
     and branch_membership.branch_id = new.branch_id
     and branch_membership.status = 'active'
    join public.role_assignments assignment
      on assignment.organization_id = membership.organization_id
     and assignment.organization_membership_id = membership.id
     and assignment.branch_id = new.branch_id
     and assignment.status = 'active'
    where membership.organization_id = new.organization_id
      and membership.id = new.organization_membership_id
      and membership.status = 'active'
      and assignment.role = required_role
  ) then
    raise exception 'class participant lacks the required active branch role'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function private.can_view_syllabus(syllabus_id_to_check bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_platform_owner())
    or exists (
      select 1
      from public.syllabuses syllabus
      where syllabus.id = syllabus_id_to_check
        and (
          (
            syllabus.scope = 'platform_library'
            and syllabus.status = 'published'
            and exists (
              select 1
              from public.organization_memberships membership
              where membership.user_id = (select auth.uid())
                and membership.status = 'active'
            )
          )
          or (
            syllabus.organization_id is not null
            and (select private.is_organization_member(syllabus.organization_id))
          )
        )
    );
$$;

create or replace function private.can_manage_syllabus(syllabus_id_to_check bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.syllabuses syllabus
    where syllabus.id = syllabus_id_to_check
      and (
        (syllabus.organization_id is null and (select private.is_platform_owner()))
        or (
          syllabus.organization_id is not null
          and (select private.can_manage_organization(syllabus.organization_id))
        )
      )
  );
$$;

create or replace function private.can_access_branch(
  organization_id_to_check bigint,
  branch_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.can_manage_organization(organization_id_to_check))
    or exists (
      select 1
      from public.organization_memberships membership
      join public.branch_memberships branch_membership
        on branch_membership.organization_id = membership.organization_id
       and branch_membership.organization_membership_id = membership.id
      where membership.organization_id = organization_id_to_check
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
        and branch_membership.branch_id = branch_id_to_check
        and branch_membership.status = 'active'
    );
$$;

create or replace function private.current_membership_matches(
  organization_id_to_check bigint,
  organization_membership_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = organization_id_to_check
      and membership.id = organization_membership_id_to_check
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
  );
$$;

create or replace function private.is_class_teacher(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  class_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_memberships membership
    join public.class_teachers teacher
      on teacher.organization_id = membership.organization_id
     and teacher.organization_membership_id = membership.id
    where membership.organization_id = organization_id_to_check
      and membership.user_id = (select auth.uid())
      and membership.status = 'active'
      and teacher.branch_id = branch_id_to_check
      and teacher.class_id = class_id_to_check
      and teacher.status = 'active'
  );
$$;

create or replace function private.can_view_class(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  class_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.can_manage_branch(organization_id_to_check, branch_id_to_check))
    or (select private.is_class_teacher(
      organization_id_to_check,
      branch_id_to_check,
      class_id_to_check
    ))
    or exists (
      select 1
      from public.organization_memberships membership
      join public.class_enrollments enrollment
        on enrollment.organization_id = membership.organization_id
       and enrollment.organization_membership_id = membership.id
      where membership.organization_id = organization_id_to_check
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
        and enrollment.branch_id = branch_id_to_check
        and enrollment.class_id = class_id_to_check
        and enrollment.status in ('enrolled', 'paused')
    );
$$;

create or replace function public.create_custom_syllabus_bundle(
  organization_id_input bigint,
  syllabus_code_input text,
  syllabus_title_input text,
  syllabus_description_input text,
  version_label_input text,
  objective_code_input text,
  objective_title_input text,
  objective_description_input text
)
returns table (syllabus_id bigint, syllabus_version_id bigint, objective_id bigint)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  created_syllabus_id bigint;
  created_version_id bigint;
  created_objective_id bigint;
begin
  insert into public.syllabuses (
    organization_id,
    scope,
    code,
    title,
    description,
    created_by
  ) values (
    organization_id_input,
    'organization_custom',
    syllabus_code_input,
    syllabus_title_input,
    nullif(btrim(syllabus_description_input), ''),
    (select auth.uid())
  ) returning id into created_syllabus_id;

  insert into public.syllabus_versions (
    syllabus_id,
    version_label,
    created_by
  ) values (
    created_syllabus_id,
    version_label_input,
    (select auth.uid())
  ) returning id into created_version_id;

  insert into public.syllabus_objectives (
    syllabus_id,
    syllabus_version_id,
    code,
    title,
    description,
    created_by
  ) values (
    created_syllabus_id,
    created_version_id,
    objective_code_input,
    objective_title_input,
    nullif(btrim(objective_description_input), ''),
    (select auth.uid())
  ) returning id into created_objective_id;

  update public.syllabus_versions
  set status = 'published'
  where id = created_version_id;

  update public.syllabuses
  set status = 'published'
  where id = created_syllabus_id;

  return query select created_syllabus_id, created_version_id, created_objective_id;
end;
$$;

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
  effective_to_input date
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
    syllabus_id,
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

revoke execute on function private.sync_syllabus_owner() from public, anon, authenticated, service_role;
revoke execute on function private.sync_objective_owner() from public, anon, authenticated, service_role;
revoke execute on function private.protect_published_objectives()
  from public, anon, authenticated, service_role;
revoke execute on function private.enforce_syllabus_version_transition()
  from public, anon, authenticated, service_role;
revoke execute on function private.enforce_syllabus_status()
  from public, anon, authenticated, service_role;
revoke execute on function private.validate_subject_syllabus()
  from public, anon, authenticated, service_role;
revoke execute on function private.validate_class_participant_role()
  from public, anon, authenticated, service_role;
revoke execute on function private.can_view_syllabus(bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.can_manage_syllabus(bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.can_access_branch(bigint, bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.current_membership_matches(bigint, bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.is_class_teacher(bigint, bigint, bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.can_view_class(bigint, bigint, bigint)
  from public, anon, authenticated, service_role;

grant execute on function private.can_view_syllabus(bigint) to authenticated;
grant execute on function private.can_manage_syllabus(bigint) to authenticated;
grant execute on function private.can_access_branch(bigint, bigint) to authenticated;
grant execute on function private.current_membership_matches(bigint, bigint) to authenticated;
grant execute on function private.is_class_teacher(bigint, bigint, bigint) to authenticated;
grant execute on function private.can_view_class(bigint, bigint, bigint) to authenticated;

revoke execute on function public.create_custom_syllabus_bundle(
  bigint,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) from public, anon, authenticated, service_role;
revoke execute on function public.create_class_bundle(
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
) from public, anon, authenticated, service_role;
grant execute on function public.create_custom_syllabus_bundle(
  bigint,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) to authenticated;
grant execute on function public.create_class_bundle(
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
) to authenticated;

create trigger syllabus_versions_sync_owner
before insert or update on public.syllabus_versions
for each row execute function private.sync_syllabus_owner();

create trigger syllabus_objectives_sync_owner
before insert or update on public.syllabus_objectives
for each row execute function private.sync_objective_owner();

create trigger syllabus_objectives_protect_published
before insert or update or delete on public.syllabus_objectives
for each row execute function private.protect_published_objectives();

create trigger syllabus_versions_enforce_transition
before update on public.sylabus_versions
for each row execute function private.enforce_syllabus_version_transition();

create trigger syllabuses_enforce_status
before update on public.syllabuses
for each row execute function private.enforce_syllabus_status();

create trigger subjects_validate_syllabus
before insert or update on public.subjects
for each row execute function private.validate_subject_syllabus();

create trigger class_teachers_validate_role
before insert or update on public.class_teachers
for each row execute function private.validate_class_participant_role();

create trigger class_enrollments_validate_role
before insert or update on public.class_enrollments
for each row execute function private.validate_class_participant_role();

create trigger syllabuses_set_updated_at
before update on public.sylabuses
for each row execute function private.set_updated_at();
create trigger syllabus_versions_set_updated_at
before update on public.sylabus_versions
for each row execute function private.set_updated_at();
create trigger syllabus_objectives_set_updated_at
before update on public.syllabus_objectives
for each row execute function private.set_updated_at();
create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function private.set_updated_at();
create trigger classes_set_updated_at
before update on public.classes
for each row execute function private.set_updated_at();
create trigger class_teachers_set_updated_at
before update on public.class_teachers
for each row execute function private.set_updated_at();
create trigger class_enrollments_set_updated_at
before update on public.class_enrollments
for each row execute function private.set_updated_at();
create trigger timetable_entries_set_updated_at
before update on public.timetable_entries
for each row execute function private.set_updated_at();

create trigger syllabuses_write_audit
after insert or update or delete on public.syllabuses
for each row execute function private.write_audit_event('organization_id', '', 'id');
create trigger syllabus_versions_write_audit
after insert or update or delete on public.sylabus_versions
for each row execute function private.write_audit_event('organization_id', '', 'id');
create trigger syllabus_objectives_write_audit
after insert or update or delete on public.syllabus_objectives
for each row execute function private.write_audit_event('organization_id', '', 'id');
create trigger subjects_write_audit
after insert or update or delete on public.subjects
for each row execute function private.write_audit_event('organization_id', '', 'id');
create trigger classes_write_audit
after insert or update or delete on public.classes
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger class_objectives_write_audit
after insert or update or delete on public.class_objectives
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger class_teachers_write_audit
after insert or update or delete on public.class_teachers
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger class_enrollments_write_audit
after insert or update or delete on public.class_enrollments
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger timetable_entries_write_audit
after insert or update or delete on public.timetable_entries
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');

alter table public.syllabuses enable row level security;
alter table public.syllabuses force row level security;
alter table public.syllabus_versions enable row level security;
alter table public.syllabus_versions force row level security;
alter table public.syllabus_objectives enable row level security;
alter table public.syllabus_objectives force row level security;
alter table public.subjects enable row level security;
alter table public.subjects force row level security;
alter table public.classes enable row level security;
alter table public.classes force row level security;
alter table public.class_objectives enable row level security;
alter table public.class_objectives force row level security;
alter table public.class_teachers enable row level security;
alter table public.class_teachers force row level security;
alter table public.class_enrollments enable row level security;
alter table public.class_enrolments force row level security;
alter table public.timetable_entries enable row level security;
alter table public.timetable_entries force row level security;

create policy syllabuses_select_authorized
on public.syllabuses
for select
to authenticated
using ((select private.can_view_syllabus(id)));

create policy syllabuses_insert_manager
on public.syllabuses
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (
    (scope = 'platform_library' and (select private.is_platform_owner()))
    or (
      scope = 'organization_custom'
      and organization_id is not null
      and (select private.can_manage_organization(organization_id))
   )
  )
);

create policy syllabuses_update_manager
on public.syllabuses
for update
to authenticated
using ((select private.can_manage_syllabus(id)))
with check ((select private.can_manage_syllabus(id)));

create policy syllabus_versions_select_authorized
on public.syllabus_versions
for select
to authenticated
using ((select private.can_view_syllabus(syllabus_id)));

create policy syllabus_versions_insert_manager
on public.syllabus_versions
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_syllabus(syllabus_id))
);

create policy syllabus_versions_update_manager
on public.syllabus_versions
for update
to authenticated
using ((select private.can_manage_syllabus(syllabus_id)))
with check ((select private.can_manage_syllabus(syllabus_id)));

create policy syllabus_objectives_select_authorized
on public.syllabus_objectives
for select
to authenticated
using ((select private.can_view_syllabus(syllabus_id)));

create policy syllabus_objectives_insert_manager
on public.syllabus_objectives
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_syllabus(syllabus_id))
);

create policy syllabus_objectives_update_manager
on public.syllabus_objectives
for update
to authenticated
using ((select private.can_manage_syllabus(syllabus_id)))
with check ((select private.can_manage_syllabus(syllabus_id)));

create policy subjects_select_member
on public.subjects
for select
to authenticated
using (
  (select private.is_platform_owner())
  or (select private.is_organization_member(organization_id))
);

create policy subjects_insert_manager
on public.subjects
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_organization(organization_id))
);

create policy subjects_update_manager
on public.subjects
for update
to authenticated
using ((select private.can_manage_organization(organization_id)))
with check ((select private.can_manage_organization(organization_id)));

create policy classes_select_authorized
on public.classes
for select
to authenticated
using ((select private.can_view_class(organization_id, branch_id, id)));

create policy classes_insert_manager
on public.classes
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_branch(organization_id, branch_id))
);

create policy classes_update_manager
on public.classes
for update
to authenticated
using ((select private.can_manage_branch(organization_id, branch_id)))
with check ((select private.can_manage_branch(organization_id, branch_id)));

create policy class_objectives_select_authorized
on public.class_objectives
for select
to authenticated
using ((select private.can_view_class(organization_id, branch_id, class_id)));

create policy class_objectives_insert_manager
on public.class_objectives
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_branch(organization_id, branch_id))
);

create policy class_teachers_select_authorized
on public.class_teachers
for select
to authenticated
using (
  (select private.can_manage_branch(organization_id, branch_id))
  or (select private.current_membership_matches(organization_id, organization_membership_id))
  or (select private.is_class_teacher(organization_id, branch_id, class_id))
);

create policy class_teachers_insert_manager
on public.class_teachers
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_branch(organization_id, branch_id))
);

create policy class_teachers_update_manager
on public.class_teachers
for update
to authenticated
using ((select private.can_manage_branch(organization_id, branch_id)))
with check ((select private.can_manage_branch(organization_id, branch_id)));

create policy class_enrollments_select_authorized
on public.class_enrollments
for select
to authenticated
using (
  (select private.can_manage_branch(organization_id, branch_id))
  or (select private.current_membership_matches(organization_id, organization_membership_id))
  or (select private.is_class_teacher(organization_id, branch_id, class_id))
);

create policy class_enrollments_insert_manager
on public.class_enrollments
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_branch(organization_id, branch_id))
);

create policy class_enrollments_update_manager
on public.class_enrollments
for update
to authenticated
using ((select private.can_manage_branch(organization_id, branch_id)))
with check ((select private.can_manage_branch(organization_id, branch_id)));

create policy timetable_entries_select_authorized
on public.timetable_entries
for select
to authenticated
using ((select private.can_view_class(organization_id, branch_id, class_id)));

create policy timetable_entries_insert_manager
on public.timetable_entries
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.can_manage_branch(organization_id, branch_id))
);

create policy timetable_entries_update_manager
on public.timetable_entries
for update
to authenticated
using ((select private.can_manage_branch(organization_id, branch_id)))
with check ((select private.can_manage_branch(organization_id, branch_id)));

revoke all on table public.syllabuses from public, anon, authenticated;
revoke all on table public.syllabus_versions from public, anon, authenticated;
revoke all on table public.syllabus_objectives from public, anon, authenticated;
revoke all on table public.subjects from public, anon, authenticated;
revoke all on table public.classes from public, anon, authenticated;
revoke all on table public.class_objectives from public, anon, authenticated;
revoke all on table public.class_teachers from public, anon, authenticated;
revoke all on table public.class_enrollments from public, anon, authenticated;
revoke all on table public.timetable_entries from public, anon, authenticated;

grant select on table public.syllabuses to authenticated;
grant insert (organization_id, scope, code, title, description, created_by)
  on table public.sylabuses to authenticated;
grant update (code, title, description, status) on table public.syllabuses to authenticated;

grant select on table public.syllabus_versions to authenticated;
grant insert (syllabus_id, version_label, created_by)
  on table public.syllabus_versions to authenticated;
grant update (version_label, status) on table public.syllabus_versions to authenticated;

grant select on table public.syllabus_objectives to authenticated;
grant insert (
  syllabus_id,
  syllabus_version_id,
  parent_objective_id,
  code,
  title,
  description,
  sequence_number,
  created_by
) on table public.syllabus_objectives to authenticated;
grant update (parent_objective_id, code, title, description, sequence_number)
  on table public.syllabus_objectives to authenticated;

grant select on table public.subjects to authenticated;
grant insert (organization_id, syllabus_id, syllabus_version_id, code, name, created_by)
  on table public.subjects to authenticated;
grant update (syllabus_id, syllabus_version_id, code, name, status)
  on table public.subjects to authenticated;

grant select on table public.classes to authenticated;
grant insert (organization_id, branch_id, subject_id, code, name, academic_year, created_by)
  on table public.classes to authenticated;
grant update (subject_id, code, name, academic_year, status)
  on table public.classes to authenticated;

grant select on table public.class_objectives to authenticated;
grant insert (
  organization_id,
  branch_id,
  class_id,
  subject_id,
  syllabus_id,
  syllabus_version_id,
  objective_id,
  created_by
) on table public.class_objectives to authenticated;

grant select on table public.class_teachers to authenticated;
grant insert (
  organization_id,
  branch_id,
  class_id,
  organization_membership_id,
  created_by
) on table public.class_teachers to authenticated;
grant update (status) on table public.class_teachers to authenticated;

grant select on table public.class_enrollments to authenticated;
grant insert (
  organization_id,
  branch_id,
  class_id,
  organization_membership_id,
  status,
  enrolled_at,
  created_by
) on table public.class_enrollments to authenticated;
grant update (status) on table public.class_enrolments to authenticated;

grant select on table public.timetable_entries to authenticated;
grant insert (
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
) on table public.timetable_entries to authenticated;
grant update (
  weekday,
  starts_at,
  ends_at,
  room,
  effective_from,
  effective_to,
  status
) on table public.timetable_entries to authenticated;

grant usage, select on sequence public.syllabuses_id_seq to authenticated;
grant usage, select on sequence public.syllabus_versions_id_seq to authenticated;
grant usage, select on sequence public.syllabus_objectives_id_seq to authenticated;
grant usage, select on sequence public.subjects_id_seq to authenticated;
grant usage, select on sequence public.classes_id_seq to authenticated;
grant usage, select on sequence public.class_objectives_id_seq to authenticated;
grant usage, select on sequence public.class_teachers_id_seq to authenticated;
grant usage, select on sequence public.class_enrollments_id_seq to authenticated;
grant usage, select on sequence public.timetable_entries_id_seq to authenticated;

grant all on table public.sylabuses to service_role;
grant all on table public.syllabus_versions to service_role;
grant all on table public.syllabus_objectives to service_role;
grant all on table public.subjects to service_role;
grant all on table public.classes to service_role;
grant all on table public.class_objectives to service_role;
grant all on table public.class_teachers to service_role;
grant all on table public.class_enrollments to service_role;
grant all on table public.timetable_entries to service_role;
grant all on sequence public.syllabuses_id_seq to service_role;
grant all on sequence public.syllabus_versions_id_seq to service_role;
grant all on sequence public.syllabus_objectives_id_seq to service_role;
grant all on sequence public.subjects_id_seq to service_role;
grant all on sequence public.classes_id_seq to service_role;
grant all on sequence public.class_objectives_id_seq to service_role;
grant all on sequence public.class_teachers_id_seq to service_role;
grant all on sequence public.class_enrollments_id_seq to service_role;
grant all on sequence public.timetable_entries_id_seq to service_role;

comment on table public.syllabuses is 'Platform library or organization-custom syllabus identity.';
comment on table public.syllabus_versions is 'Immutable-after-publication syllabus version boundary.';
comment on table public.syllabus_objectives is 'Versioned learning objective used for evidence lineage.';
comment on table public.subjects is 'Organization subject linked to one published syllabus version.';
comment on table public.classes is 'Branch-scoped teaching cohort for one subject.';
comment on table public.class_objectives is 'Constraint-backed link from a class to objectives in its subject version.';
comment on table public.class_teachers is 'Active teacher assignments for a branch-scoped class.';
comment on table public.class_enrollments is 'Student enrollment and lifecycle state for a branch-scoped class.';
comment on table public.timetable_entries is 'Effective-dated weekly timetable for a branch-scoped class.';
comment on function public.create_custom_syllabus_bundle(
  bigint,
  text,
  text,
  text,
  text,
  text,
  text,
  text
) is 'Atomically creates and publishes an organization-owned syllabus, first version, and objective.';
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
) is 'Atomically creates a class, objective link, and first timetable entry under caller RLS.';
