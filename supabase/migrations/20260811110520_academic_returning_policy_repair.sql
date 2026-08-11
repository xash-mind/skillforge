-- Repair INSERT ... RETURNING for newly created syllabuses.
-- The hosted migration version is reconciled after controlled live apply.
--
-- The original select policy delegated through can_view_syllabus(id), which reads the table again.
-- During the same INSERT command that helper cannot observe the not-yet-command-visible row, so a
-- correctly authorized organization owner could insert but not RETURNING the generated identity.
-- Evaluate the row's tenant fields directly while retaining the same visibility rules.

drop policy syllabuses_select_authorized on public.syllabuses;

create policy syllabuses_select_authorized
on public.syllabuses
for select
to authenticated
using (
  (select private.is_platform_owner())
  or (
    scope = 'platform_library'
    and status = 'published'
    and exists (
      select 1
      from public.organization_memberships membership
      where membership.user_id = (select auth.uid())
        and membership.status = 'active'
    )
  )
  or (
    organization_id is not null
    and (select private.is_organization_member(organization_id))
  )
);
