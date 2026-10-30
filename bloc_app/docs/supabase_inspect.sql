-- Chạy trong Supabase SQL Editor. Chỉ đọc cấu trúc, không đọc dữ liệu cá nhân.
-- Sao chép ô schema_snapshot trong kết quả và gửi lại.
select jsonb_pretty(jsonb_build_object(
  'columns', (
    select jsonb_agg(to_jsonb(c))
    from (
      select table_name, column_name, data_type, udt_name,
             is_nullable, column_default
      from information_schema.columns
      where table_schema = 'public'
      order by table_name, ordinal_position
    ) c
  ),
  'constraints', (
    select jsonb_agg(jsonb_build_object(
      'table', c.conrelid::regclass::text,
      'name', c.conname,
      'definition', pg_get_constraintdef(c.oid)
    ))
    from pg_constraint c
    join pg_namespace n on n.oid = c.connamespace
    where n.nspname = 'public'
  ),
  'views', (
    select jsonb_agg(jsonb_build_object(
      'name', viewname, 'definition', definition
    ))
    from pg_views where schemaname = 'public'
  ),
  'functions', (
    select jsonb_agg(jsonb_build_object(
      'name', p.proname, 'definition', pg_get_functiondef(p.oid)
    ))
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prokind = 'f'
      and not exists (
        select 1 from pg_depend d
        where d.classid = 'pg_proc'::regclass and d.objid = p.oid
          and d.deptype = 'e'
      )
  ),
  'policies', (
    select jsonb_agg(to_jsonb(p))
    from pg_policies p where schemaname in ('public', 'storage')
  ),
  'rls', (
    select jsonb_agg(jsonb_build_object(
      'table', c.relname, 'enabled', c.relrowsecurity,
      'forced', c.relforcerowsecurity
    ))
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
  ),
  'triggers', (
    select jsonb_agg(pg_get_triggerdef(t.oid))
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('public', 'auth') and not t.tgisinternal
  )
)) as schema_snapshot;
