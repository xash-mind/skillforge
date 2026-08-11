-- Run after the tenancy migration. Every fixture and assertion is rolled back.
begin;

insert into auth.users (id, email, raw_user_meta_data)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'platform@example.invalid',
    '{"display_name":"Platform Owner"}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'teacher@example.invalid',
    '{"display_name":"Teacher","role":"organization_owner"}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'manager@example.invalid',
    '{"display_name":"Branch Manager"}'::jsonb
  ),
  (
    '10000000-0000-0000-0000-000000000004',
    'student@example.invalid',
    '{"display_name":"Other Tenant Student"}'::jsonb
  );

insert into private.platform_role_assignments (user_id)
values ('10000000-0000-0000-0000-000000000001');

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

insert into public.organizations (name, slug, region_code, created_by)
values
  (
    'Northstar Learning',
    'northstar-learning',
    'IN',
    '10000000-0000-0000-0000-000000000001'
  ),
  (
    'Harbour Academy',
    'harbour-academy',
    'IN',
    '10000000-0000-0000-0000-000000000001'
  );

insert into public.branches (organization_id, name, code, timezone, created_by)
select
  organization.id,
  fixture.name,
  fixture.code,
  'Asia/Kolkata',
  '10000000-0000-0000-0000-000000000001'
from (
  values
    ('northstar-learning', 'Northstar Main', 'MAIN'),
    ('northstar-learning', 'Northstar West', 'WEST'),
    ('harbour-academy', 'Harbour Main', 'HARBOUR')
) as fixture(organization_slug, name, code)
join public.organizations organization on organization.slug = fixture.organization_slug;

insert into public.organization_memberships (
  organization_id,
  user_id,
  status,
  joined_at,
  created_by
)
select
  organization.id,
  fixture.user_id,
  'active',
  statement_timestamp(),
  '10000000-0000-0000-0000-000000000001'
from (
  values
    ('northstar-learning', '10000000-0000-0000-0000-000000000001'::uuid),
    ('northstar-learning', '10000000-0000-0000-0000-000000000002'::uuid),
    ('northstar-learning', '10000000-0000-0000-0000-000000000003'::uuid),
    ('harbour-academy', '10000000-0000-0000-0000-000000000004'::uuid)
) as fixture(organization_slug, user_id)
join public.organizations organization on organization.slug = fixture.organization_slug;

insert into public.branch_memberships (
  organization_id,
  organization_membership_id,
  branch_id,
  created_by
)
select
  membership.organization_id,
  membership.id,
  branch.id,
  '10000000-0000-0000-0000-000000000001'
from public.organization_memberships membership
join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = case
   when membership.user_id = '10000000-0000-0000-0000-000000000004' then 'HARBOUR'
   else 'MAIN'
 end
where membership.user_id in (
  '10000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000003',
  '10000000-0000-0000-0000-000000000004'
);

insert into public.role_assignments (
  organization_id,
  organization_membership_id,
  branch_id,
  role,
  assigned_by
)
select
  membership.organization_id,
  membership.id,
  branch.id,
  fixture.role,
  '10000000-0000-0000-0000-000000000001'
from (
  values
    ('10000000-0000-0000-0000-000000000001'::uuid, 'organization_owner'),
    ('10000000-0000-0000-0000-000000000002'::uuid, 'teacher'),
    ('10000000-0000-0000-0000-000000000003'::uuid, 'branch_manager'),
    ('10000000-0000-0000-0000-000000000004'::uuid, 'student')
) as fixture(user_id, role)
join public.organization_memberships membership on membership.user_id = fixture.user_id
left join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = case
   when fixture.role = 'organization_owner' then '__organization_scope__'
   when fixture.user_id = '10000000-0000-0000-0000-000000000004' then 'HARBOUR'
   else 'MAIN'
 end;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);

do $$
declare
  visible_organizations bigint;
  visible_foreign_branches bigint;
  visible_profiles bigint;
  visible_audit_events bigint;
  affected_rows bigint;
begin
  select count(*) into visible_organizations from public.organizations;
  if visible_organizations <> 1 then
    raise exception 'teacher tenant isolation failed: expected 1 organization, saw %',
      visible_organizations;
  end if;

  select count(*) into visible_foreign_branches
  from public.branches branch
  join public.organizations organization on organization.id = branch.organization_id
  where organization.slug = 'harbour-academy';
  if visible_foreign_branches <> 0 then
    raise exception 'teacher could see a foreign-tenant branch';
  end if;

  select count(*) into visible_profiles from public.profiles;
  if visible_profiles <> 3 then
    raise exception 'profile tenant isolation failed: expected 3 profiles, saw %', visible_profiles;
  end if;

  select count(*) into visible_audit_events from public.audit_events;
  if visible_audit_events <> 0 then
    raise exception 'teacher could read privileged audit events';
  end if;

  update public.organizations
  set name = 'Unauthorized rename'
  where slug = 'northstar-learning';
  get diagnostics affected_rows = row_count;
  if affected_rows <> 0 then
    raise exception 'teacher modified organization settings via forged metadata';
  end if;

  begin
    perform private.is_platform_owner();
    raise exception 'private authorization helper was directly callable';
  exception
    when insufficient_privilege then null;
  end;

  begin
    insert into public.role_assignments (
      organization_id,
      organization_membership_id,
      branch_id,
      role,
      assigned_by
    )
    select
      membership.organization_id,
      membership.id,
      null,
      'organization_owner',
      '10000000-0000-0000-0000-000000000002'
    from public.organization_memberships membership
    where membership.user_id = '10000000-0000-0000-0000-000000000002';
    raise exception 'teacher escalated to organization owner';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000003', true);

do $$
declare
  own_branch_updates bigint;
  foreign_branch_updates bigint;
  visible_branch_audits bigint;
begin
  update public.branches
  set name = 'Northstar Main Campus'
  where code = 'MAIN';
  get diagnostics own_branch_updates = row_count;
  if own_branch_updates <> 1 then
    raise exception 'branch manager could not update own branch';
  end if;

  update public.branches
  set name = 'Unauthorized west rename'
  where code = 'WEST';
  get diagnostics foreign_branch_updates = row_count;
  if foreign_branch_updates <> 0 then
    raise exception 'branch manager modified another branch';
  end if;

  insert into public.role_assignments (
    organization_id,
    organization_membership_id,
    branch_id,
    role,
    assigned_by
  )
  select
    membership.organization_id,
    membership.id,
    branch.id,
    'parent',
    '10000000-0000-0000-0000-000000000003'
  from public.organization_memberships membership
  join public.branches branch
    on branch.organization_id = membership.organization_id
   and branch.code = 'MAIN'
  where membership.user_id = '10000000-0000-0000-0000-000000000002';

  begin
    insert into public.role_assignments (
      organization_id,
      organization_membership_id,
      branch_id,
      role,
      assigned_by
    )
    select
      membership.organization_id,
      membership.id,
      branch.id,
      'branch_manager',
      '10000000-0000-0000-0000-000000000003'
    from public.organization_memberships membership
    join public.branches branch
      on branch.organization_id = membership.organization_id
     and branch.code = 'MAIN'
    where membership.user_id = '10000000-0000-0000-0000-000000000002';
    raise exception 'branch manager delegated branch-manager authority';
  exception
    when insufficient_privilege then null;
  end;

  select count(*) into visible_branch_audits from public.audit_events;
  if visible_branch_audits = 0 then
    raise exception 'branch manager could not read audit history for own branch';
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000004', true);

do $$
declare
  visible_organizations bigint;
  visible_branches bigint;
  visible_profiles bigint;
begin
  select count(*) into visible_organizations from public.organizations;
  select count(*) into visible_branches from public.branches;
  select count(*) into visible_profiles from public.profiles;

  if visible_organizations <> 1 or visible_branches <> 1 or visible_profiles <> 1 then
    raise exception
      'student tenant isolation failed: organizations %, branches %, profiles %',
      visible_organizations,
      visible_branches,
      visible_profiles;
  end if;
end;
$$;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

do $$
begin
  begin
    insert into public.branch_memberships (
      organization_id,
      organization_membership_id,
      branch_id,
      created_by
    )
    select
      northstar.id,
      membership.id,
      harbour_branch.id,
      '10000000-0000-0000-0000-000000000001'
    from public.organizations northstar
    join public.organization_memberships membership
      on membership.organization_id = northstar.id
     and membership.user_id = '10000000-0000-0000-0000-000000000002'
    cross join public.branches harbour_branch
    join public.organizations harbour on harbour.id = harbour_branch.organization_id
    where northstar.slug = 'northstar-learning'
      and harbour.slug = 'harbour-academy';
    raise exception 'cross-tenant branch membership bypassed composite foreign keys';
  exception
    when foreign_key_violation then null;
  end;

  begin
    update public.audit_events
    set details = '{"tampered":true}'::jsonb
    where id = (select min(id) from public.audit_events);
    raise exception 'authenticated platform owner mutated audit history';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

reset role;

do $$
begin
  begin
    update public.audit_events
    set details = '{"tampered":true}'::jsonb
    where id = (select min(id) from public.audit_events);
    raise exception 'database owner mutated append-only audit history';
  exception
    when sqlstate '55000' then null;
  end;
end;
$$;

select jsonb_build_object(
  'result', 'pass',
  'assertions', array[
    'tenant isolation',
    'branch isolation',
    'metadata escalation denial',
    'role delegation limits',
    'composite tenant integrity',
    'private helper isolation',
    'append-only audit history'
  ],
  'audit_events_observed', (select count(*) from public.audit_events)
) as test_summary;

rollback;
