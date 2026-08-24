-- TASK-004 repair: Storage RLS policy helpers must be executable by the authenticated policy role.

revoke execute on function private.can_read_classroom_evidence(bigint, bigint, bigint, bigint)
  from public, anon, service_role;
revoke execute on function private.can_write_classroom_evidence(bigint, bigint, bigint, bigint)
  from public, anon, service_role;

grant execute on function private.can_read_classroom_evidence(bigint, bigint, bigint, bigint)
  to authenticated;
grant execute on function private.can_write_classroom_evidence(bigint, bigint, bigint, bigint)
  to authenticated;
