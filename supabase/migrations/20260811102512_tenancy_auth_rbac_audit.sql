-- TASK-002: trusted tenancy, authentication, RBAC, and append-only audit foundation.
-- Hosted migration version: 20260811102512.
-- Authorization is derived from database memberships and role assignments. User-editable
-- auth metadata is deliberately excluded from every policy.

create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon, authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges in schema private revoke all on tables from public, anon, authenticated;
alter default privileges in schema private revoke all on sequences from public, anon, authenticated;
alter default privileges in schema private revoke execute on functions from public, anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  status text not null default 'active',
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 120),
  constraint profiles_status_check check (status in ('active', 'suspended', 'deactivated'))
);

create table public.organizations (
  id bigint generated always as identity primary key,
  name text not null,
  slug text not null unique,
  region_code text not null default 'IN',
  status text not null default 'setup',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint organizations_name_length check (char_length(name) between 2 and 160),
  constraint organizations_slug_format check (
    char_length(slug) between 3 and 80
    and slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
  ),
  constraint organizations_region_code_format check (
    char_length(region_code) between 2 and 16
    and region_code ~ '^[A-Z]{2}(?:-[A-Z0-9]{1,8})?$'
  ),
  constraint organizations_status_check check (status in ('setup', 'active', 'suspended', 'closed'))
);

create table public.branches (
  id bigint generated always as identity primary key,
  organization_id bigint not null references public.organizations (id) on delete restrict,
  name text not null,
  code text not null,
  timezone text not null default 'Asia/Kolkata',
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint branches_name_length check (char_length(name) between 2 and 120),
  constraint branches_code_format check (
    char_length(code) between 2 and 24
    and code ~ '^[A-Z0-9]+(?:-[A-Z0-9]+)*$'
  ),
  constraint branches_timezone_length check (char_length(timezone) between 3 and 80),
  constraint branches_status_check check (status in ('active', 'suspended', 'closed')),
  constraint branches_organization_code_key unique (organization_id, code),
  constraint branches_organization_id_id_key unique (organization_id, id)
);

create table public.organization_memberships (
  id bigint generated always as identity primary key,
  organization_id bigint not null references public.organizations (id) on delete restrict,
  user_id uuid not null references public.profiles (id) on delete restrict,
  status text not null default 'invited',
  joined_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint organization_memberships_status_check check (
    status in ('invited', 'active', 'suspended', 'left')
  ),
  constraint organization_memberships_joined_at_check check (
    (status = 'active' and joined_at is not null) or status <> 'active'
  ),
  constraint organization_memberships_organization_user_key unique (organization_id, user_id),
  constraint organization_memberships_organization_id_id_key unique (organization_id, id)
);

create table public.branch_memberships (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  organization_membership_id bigint not null,
  branch_id bigint not null,
  status text not null default 'active',
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint branch_memberships_status_check check (status in ('active', 'suspended', 'left')),
  constraint branch_memberships_membership_fkey foreign key (
    organization_id,
    organization_membership_id
  ) references public.organization_memberships (organization_id, id) on delete restrict,
  constraint branch_memberships_branch_fkey foreign key (organization_id, branch_id)
    references public.branches (organization_id, id) on delete restrict,
  constraint branch_memberships_membership_branch_key unique (
    organization_membership_id,
    branch_id
  )
);

create table public.role_assignments (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  organization_membership_id bigint not null,
  branch_id bigint,
  role text not null,
  status text not null default 'active',
  assigned_by uuid not null references public.profiles (id) on delete restrict,
  assigned_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint role_assignments_role_check check (
    role in ('organization_owner', 'branch_manager', 'teacher', 'student', 'parent')
  ),
  constraint role_assignments_status_check check (status in ('active', 'revoked')),
  constraint role_assignments_scope_check check (
    (role = 'organization_owner' and branch_id is null)
    or (role in ('branch_manager', 'teacher', 'student') and branch_id is not null)
    or role = 'parent'
  ),
  constraint role_assignments_membership_fkey foreign key (
    organization_id,
    organization_membership_id
  ) references public.organization_memberships (organization_id, id) on delete restrict,
  constraint role_assignments_branch_fkey foreign key (organization_id, branch_id)
    references public.branches (organization_id, id) on delete restrict
);

create unique index role_assignments_active_scope_key
  on public.role_assignments (organization_membership_id, role, coalesce(branch_id, 0))
  where status = 'active';

create table private.platform_role_assignments (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete restrict,
  role text not null default 'platform_owner',
  status text not null default 'active',
  assigned_by uuid references public.profiles (id) on delete restrict,
  assigned_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint platform_role_assignments_role_check check (role = 'platform_owner'),
  constraint platform_role_assignments_status_check check (status in ('active', 'revoked'))
);

create unique index platform_role_assignments_active_user_key
  on private.platform_role_assignments (user_id)
  where status = 'active';

create table public.audit_events (
  id bigint generated always as identity primary key,
  organization_id bigint,
  branch_id bigint,
  actor_user_id uuid references public.profiles (id) on delete set null,
  actor_database_role text not null default session_user,
  action text not null,
  target_type text not null,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default statement_timestamp(),
  constraint audit_events_action_length check (char_length(action) between 3 and 120),
  constraint audit_events_target_type_length check (char_length(target_type) between 2 and 120),
  constraint audit_events_details_object check (jsonb_typeof(details) = 'object')
);

create index branches_organization_id_idx on public.branches (organization_id);
create index organization_memberships_user_id_idx on public.organization_memberships (user_id);
create index organization_memberships_active_user_org_idx
  on public.organization_memberships (user_id, organization_id)
  where status = 'active';
create index branch_memberships_organization_branch_idx
  on public.branch_memberships (organization_id, branch_id, status);
create index branch_memberships_membership_idx
  on public.branch_memberships (organization_membership_id, status);
create index role_assignments_organization_membership_idx
  on public.role_assignments (organization_id, organization_membership_id, status);
create index role_assignments_branch_role_idx
  on public.role_assignments (organization_id, branch_id, role)
  where status = 'active';
create index audit_events_organization_occurred_idx
  on public.audit_events (organization_id, occurred_at desc);
create index audit_events_branch_occurred_idx
  on public.audit_events (branch_id, occurred_at desc)
  where branch_id is not null;
create index audit_events_actor_user_id_idx on public.audit_events (actor_user_id);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := statement_timestamp();
  return new;
end;
$$;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_display_name text;
begin
  resolved_display_name := left(
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'SkillForge user'
    ),
    120
  );

  insert into public.profiles (id, display_name)
  values (new.id, resolved_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function private.is_platform_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from private.platform_role_assignments assignment
      where assignment.user_id = (select auth.uid())
        and assignment.role = 'platform_owner'
        and assignment.status = 'active'
    );
$$;

create or replace function private.is_organization_member(organization_id_to_check bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = organization_id_to_check
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
    );
$$;

create or replace function private.has_organization_role(
  organization_id_to_check bigint,
  allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.organization_memberships membership
      join public.role_assignments assignment
        on assignment.organization_id = membership.organization_id
       and assignment.organization_membership_id = membership.id
      where membership.organization_id = organization_id_to_check
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
        and assignment.status = 'active'
        and assignment.branch_id is null
        and assignment.role = any (allowed_roles)
    );
$$;

create or replace function private.has_branch_role(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.organization_memberships membership
      join public.role_assignments assignment
        on assignment.organization_id = membership.organization_id
       and assignment.organization_membership_id = membership.id
      where membership.organization_id = organization_id_to_check
        and membership.user_id = (select auth.uid())
        and membership.status = 'active'
        and assignment.status = 'active'
        and (
          (assignment.role = 'organization_owner' and assignment.branch_id is null)
          or (
            assignment.branch_id = branch_id_to_check
            and assignment.role = any (allowed_roles)
          )
        )
    );
$$;

create or replace function private.can_manage_organization(organization_id_to_check bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_platform_owner())
    or (select private.has_organization_role(organization_id_to_check, array['organization_owner']));
$$;

create or replace function private.can_manage_branch(
  organization_id_to_check bigint,
  branch_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.is_platform_owner())
    or (
      select private.has_branch_role(
        organization_id_to_check,
        branch_id_to_check,
        array['branch_manager']
      )
    );
$$;

create or replace function private.can_view_profile(profile_id_to_check uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select profile_id_to_check = (select auth.uid())
    or (select private.is_platform_owner())
    or exists (
      select 1
      from public.organization_memberships viewer
      join public.organization_memberships subject
        on subject.organization_id = viewer.organization_id
      where viewer.user_id = (select auth.uid())
        and viewer.status = 'active'
        and subject.user_id = profile_id_to_check
        and subject.status = 'active'
    );
$$;

create or replace function private.can_view_organization_membership(
  membership_id_to_check bigint,
  organization_id_to_check bigint,
  user_id_to_check uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select user_id_to_check = (select auth.uid())
    or (select private.can_manage_organization(organization_id_to_check))
    or exists (
      select 1
      from public.branch_memberships subject_branch
      where subject_branch.organization_membership_id = membership_id_to_check
        and subject_branch.organization_id = organization_id_to_check
        and subject_branch.status = 'active'
        and (
          select private.can_manage_branch(
            subject_branch.organization_id,
            subject_branch.branch_id
          )
        )
    );
$$;

create or replace function private.can_assign_role(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  role_to_assign text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select private.can_manage_organization(organization_id_to_check))
    or (
      branch_id_to_check is not null
      and role_to_assign = any (array['teacher', 'student', 'parent'])
      and (
        select private.can_manage_branch(
          organization_id_to_check,
          branch_id_to_check
        )
      )
    );
$$;

create or replace function private.write_audit_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  row_data jsonb;
  organization_value bigint;
  branch_value bigint;
  changed_columns jsonb;
begin
  row_data := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;

  if nullif(tg_argv[0], '') is not null then
    organization_value := nullif(row_data ->> tg_argv[0], '')::bigint;
  end if;

  if nullif(tg_argv[1], '') is not null then
    branch_value := nullif(row_data ->> tg_argv[1], '')::bigint;
  end if;

  if tg_op = 'UPDATE' then
    select coalesce(jsonb_agg(new_value.key order by new_value.key), '[]'::jsonb)
      into changed_columns
    from jsonb_each(to_jsonb(new)) new_value
    full join jsonb_each(to_jsonb(old)) old_value using (key)
    where new_value.value is distinct from old_value.value;
  else
    select coalesce(jsonb_agg(field.key order by field.key), '[]'::jsonb)
      into changed_columns
    from jsonb_each(row_data) field;
  end if;

  insert into public.audit_events (
    organization_id,
    branch_id,
    actor_user_id,
    actor_database_role,
    action,
    target_type,
    target_id,
    details
  )
  values (
    organization_value,
    branch_value,
    (select auth.uid()),
    session_user,
    tg_table_name || '.' || lower(tg_op),
    tg_table_name,
    nullif(row_data ->> tg_argv[2], ''),
    jsonb_build_object('changed_columns', changed_columns)
  );

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create or replace function private.reject_audit_event_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception 'audit events are append-only' using errcode = '55000';
end;
$$;

revoke execute on function private.set_updated_at() from public, anon, authenticated, service_role;
revoke execute on function private.handle_new_auth_user() from public, anon, authenticated, service_role;
revoke execute on function private.is_platform_owner() from public, anon, authenticated, service_role;
revoke execute on function private.is_organization_member(bigint) from public, anon, authenticated, service_role;
revoke execute on function private.has_organization_role(bigint, text[]) from public, anon, authenticated, service_role;
revoke execute on function private.has_branch_role(bigint, bigint, text[]) from public, anon, authenticated, service_role;
revoke execute on function private.can_manage_organization(bigint) from public, anon, authenticated, service_role;
revoke execute on function private.can_manage_branch(bigint, bigint) from public, anon, authenticated, service_role;
revoke execute on function private.can_view_profile(uuid) from public, anon, authenticated, service_role;
revoke execute on function private.can_view_organization_membership(bigint, bigint, uuid)
  from public, anon, authenticated, service_role;
revoke execute on function private.can_assign_role(bigint, bigint, text)
  from public, anon, authenticated, service_role;
revoke execute on function private.write_audit_event() from public, anon, authenticated, service_role;
revoke execute on function private.reject_audit_event_mutation()
  from public, anon, authenticated, service_role;

-- PostgreSQL checks EXECUTE while evaluating policy expressions. Authenticated sessions receive
-- only the helper signatures referenced by RLS; direct calls remain blocked because the private
-- schema deliberately has no USAGE grant.
grant execute on function private.is_platform_owner() to authenticated;
grant execute on function private.is_organization_member(bigint) to authenticated;
grant execute on function private.has_organization_role(bigint, text[]) to authenticated;
grant execute on function private.has_branch_role(bigint, bigint, text[]) to authenticated;
grant execute on function private.can_manage_organization(bigint) to authenticated;
grant execute on function private.can_manage_branch(bigint, bigint) to authenticated;
grant execute on function private.can_view_profile(uuid) to authenticated;
grant execute on function private.can_view_organization_membership(bigint, bigint, uuid)
  to authenticated;
grant execute on function private.can_assign_role(bigint, bigint, text) to authenticated;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function private.set_updated_at();

create trigger branches_set_updated_at
before update on public.branches
for each row execute function private.set_updated_at();

create trigger organization_memberships_set_updated_at
before update on public.organization_memberships
for each row execute function private.set_updated_at();

create trigger branch_memberships_set_updated_at
before update on public.branch_memberships
for each row execute function private.set_updated_at();

create trigger role_assignments_set_updated_at
before update on public.role_assignments
for each row execute function private.set_updated_at();

create trigger platform_role_assignments_set_updated_at
before update on private.platform_role_assignments
for each row execute function private.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

create trigger organizations_write_audit
after insert or update or delete on public.organizations
for each row execute function private.write_audit_event('id', '', 'id');

create trigger branches_write_audit
after insert or update or delete on public.branches
for each row execute function private.write_audit_event('organization_id', 'id', 'id');

create trigger organization_memberships_write_audit
after insert or update or delete on public.organization_memberships
for each row execute function private.write_audit_event('organization_id', '', 'id');

create trigger branch_memberships_write_audit
after insert or update or delete on public.branch_memberships
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');

create trigger role_assignments_write_audit
after insert or update or delete on public.role_assignments
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');

create trigger platform_role_assignments_write_audit
after insert or update or delete on private.platform_role_assignments
for each row execute function private.write_audit_event('', '', 'id');

create trigger audit_events_reject_mutation
before update or delete on public.audit_events
for each row execute function private.reject_audit_event_mutation();

alter table public.profiles enable row level security;
alter table public.profiles force row level security;
alter table public.organizations enable row level security;
alter table public.organizations force row level security;
alter table public.branches enable row level security;
alter table public.branches force row level security;
alter table public.organization_memberships enable row level security;
alter table public.organization_memberships force row level security;
alter table public.branch_memberships enable row level security;
alter table public.branch_memberships force row level security;
alter table public.role_assignments enable row level security;
alter table public.role_assignments force row level security;
alter table public.audit_events enable row level security;
alter table public.audit_events force row level security;
alter table private.platform_role_assignments enable row level security;
alter table private.platform_role_assignments force row level security;

create policy profiles_select_authorized
on public.profiles
for select
to authenticated
using ((select private.can_view_profile(id)));

create policy profiles_update_self
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy organizations_select_member
on public.organizations
for select
to authenticated
using (
  (select private.is_platform_owner())
  or (select private.is_organization_member(id))
);

create policy organizations_insert_platform_owner
on public.organizations
for insert
to authenticated
with check (
  (select private.is_platform_owner())
  and created_by = (select auth.uid())
);

create policy organizations_update_manager
on public.organizations
for update
to authenticated
using ((select private.can_manage_organization(id)))
with check ((select private.can_manage_organization(id)));

create policy branches_select_member
on public.branches
for select
to authenticated
using (
  (select private.is_platform_owner())
  or (select private.is_organization_member(organization_id))
);

create policy branches_insert_organization_manager
on public.branches
for insert
to authenticated
with check (
  (select private.can_manage_organization(organization_id))
  and created_by = (select auth.uid())
);

create policy branches_update_branch_manager
on public.branches
for update
to authenticated
using ((select private.can_manage_branch(organization_id, id)))
with check ((select private.can_manage_branch(organization_id, id)));

create policy organization_memberships_select_authorized
on public.organization_memberships
for select
to authenticated
using (
  (
    select private.can_view_organization_membership(
      id,
      organization_id,
      user_id
    )
  )
);

create policy organization_memberships_insert_manager
on public.organization_memberships
for insert
to authenticated
with check (
  (select private.can_manage_organization(organization_id))
  and created_by = (select auth.uid())
);

create policy organization_memberships_update_manager
on public.organization_memberships
for update
to authenticated
using ((select private.can_manage_organization(organization_id)))
with check ((select private.can_manage_organization(organization_id)));

create policy branch_memberships_select_authorized
on public.branch_memberships
for select
to authenticated
using (
  exists (
    select 1
    from public.organization_memberships membership
    where membership.id = organization_membership_id
      and membership.user_id = (select auth.uid())
  )
  or (select private.can_manage_branch(organization_id, branch_id))
);

create policy branch_memberships_insert_manager
on public.branch_memberships
for insert
to authenticated
with check (
  (select private.can_manage_branch(organization_id, branch_id))
  and created_by = (select auth.uid())
);

create policy branch_memberships_update_manager
on public.branch_memberships
for update
to authenticated
using ((select private.can_manage_branch(organization_id, branch_id)))
with check ((select private.can_manage_branch(organization_id, branch_id)));

create policy role_assignments_select_authorized
on public.role_assignments
for select
to authenticated
using (
  exists (
    select 1
    from public.organization_memberships membership
    where membership.id = organization_membership_id
      and membership.user_id = (select auth.uid())
  )
  or (select private.can_manage_organization(organization_id))
  or (
    branch_id is not null
    and (select private.can_manage_branch(organization_id, branch_id))
  )
);

create policy role_assignments_insert_manager
on public.role_assignments
for insert
to authenticated
with check (
  (select private.can_assign_role(organization_id, branch_id, role))
  and assigned_by = (select auth.uid())
);

create policy role_assignments_update_manager
on public.role_assignments
for update
to authenticated
using ((select private.can_assign_role(organization_id, branch_id, role)))
with check ((select private.can_assign_role(organization_id, branch_id, role)));

create policy audit_events_select_manager
on public.audit_events
for select
to authenticated
using (
  (select private.is_platform_owner())
  or (
    organization_id is not null
    and (select private.can_manage_organization(organization_id))
  )
  or (
    organization_id is not null
    and branch_id is not null
    and (select private.can_manage_branch(organization_id, branch_id))
  )
);

revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.organizations from public, anon, authenticated;
revoke all on table public.branches from public, anon, authenticated;
revoke all on table public.organization_memberships from public, anon, authenticated;
revoke all on table public.branch_memberships from public, anon, authenticated;
revoke all on table public.role_assignments from public, anon, authenticated;
revoke all on table public.audit_events from public, anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (display_name) on table public.profiles to authenticated;

grant select on table public.organizations to authenticated;
grant insert (name, slug, region_code, created_by) on table public.organizations to authenticated;
grant update (name, slug, region_code, status) on table public.organizations to authenticated;

grant select on table public.branches to authenticated;
grant insert (organization_id, name, code, timezone, created_by)
  on table public.branches to authenticated;
grant update (name, code, timezone, status) on table public.branches to authenticated;

grant select on table public.organization_memberships to authenticated;
grant insert (organization_id, user_id, status, joined_at, created_by)
  on table public.organization_memberships to authenticated;
grant update (status, joined_at) on table public.organization_memberships to authenticated;

grant select on table public.branch_memberships to authenticated;
grant insert (
  organization_id,
  organization_membership_id,
  branch_id,
  status,
  created_by
) on table public.branch_memberships to authenticated;
grant update (status) on table public.branch_memberships to authenticated;

grant select on table public.role_assignments to authenticated;
grant insert (
  organization_id,
  organization_membership_id,
  branch_id,
  role,
  assigned_by
) on table public.role_assignments to authenticated;
grant update (status) on table public.role_assignments to authenticated;

grant select on table public.audit_events to authenticated;

grant usage, select on sequence public.organizations_id_seq to authenticated;
grant usage, select on sequence public.branches_id_seq to authenticated;
grant usage, select on sequence public.organization_memberships_id_seq to authenticated;
grant usage, select on sequence public.branch_memberships_id_seq to authenticated;
grant usage, select on sequence public.role_assignments_id_seq to authenticated;

grant all on table public.profiles to service_role;
grant all on table public.organizations to service_role;
grant all on table public.branches to service_role;
grant all on table public.organization_memberships to service_role;
grant all on table public.branch_memberships to service_role;
grant all on table public.role_assignments to service_role;
grant select, insert on table public.audit_events to service_role;
grant all on all sequences in schema public to service_role;

comment on schema private is 'Non-exposed authorization helpers and platform-only access records.';
comment on table public.profiles is 'Application identity projected from auth.users; never an authorization source.';
comment on table public.organizations is 'Top-level SkillForge tenant boundary.';
comment on table public.branches is 'Organization-owned physical or operational branch.';
comment on table public.organization_memberships is 'Trusted organization membership used by RLS.';
comment on table public.branch_memberships is 'Trusted branch scope for an organization membership.';
comment on table public.role_assignments is 'Tenant and branch role grants used by RLS.';
comment on table public.audit_events is 'Append-only record of privileged tenancy and access changes.';
comment on table private.platform_role_assignments is 'Platform-owner grants, isolated from the Data API.';
