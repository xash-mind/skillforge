-- Follow-up generated from the first live database-advisor pass.
-- Hosted migration version: 20260811102701.

create index organizations_created_by_idx on public.organizations (created_by);
create index branches_created_by_idx on public.branches (created_by);
create index organization_memberships_created_by_idx
  on public.organization_memberships (created_by);
create index branch_memberships_organization_membership_fk_idx
  on public.branch_memberships (organization_id, organization_membership_id);
create index branch_memberships_created_by_idx on public.branch_memberships (created_by);
create index role_assignments_assigned_by_idx on public.role_assignments (assigned_by);
create index platform_role_assignments_assigned_by_idx
  on private.platform_role_assignments (assigned_by)
  where assigned_by is not null;

-- The private table is not exposed and has no client grants. An explicit deny policy documents
-- that posture and keeps database-advisor output unambiguous while privileged SQL retains the
-- normal service/owner bypass.
create policy platform_role_assignments_deny_authenticated
on private.platform_role_assignments
for all
to authenticated
using (false)
with check (false);
