-- Chạy sau supabase_board_upgrade.sql. Chỉ đọc catalog, không đọc dữ liệu cá nhân.
-- Mọi hàng phải có passed = true. Vẫn cần kiểm thử hai tài khoản theo báo cáo.
select 'Board view' as check_name,
       to_regclass('public.board_post_display_view') is not null as passed
union all
select 'Post metadata columns', count(*) = 4
from information_schema.columns
where table_schema = 'public' and table_name = 'posts'
  and column_name in ('category', 'is_pinned', 'requires_acknowledgement', 'content_version')
union all
select 'Acknowledgement table RLS', coalesce((
  select relrowsecurity from pg_class where oid = to_regclass('public.post_acknowledgements')
), false)
union all
select 'Member can read own acknowledgement via RLS',
  has_table_privilege('authenticated', 'public.post_acknowledgements', 'select')
union all
select 'Member cannot insert acknowledgement directly',
  not has_table_privilege('authenticated', 'public.post_acknowledgements', 'insert')
union all
select 'Member cannot update acknowledgement directly',
  not has_table_privilege('authenticated', 'public.post_acknowledgements', 'update')
union all
select 'Member cannot delete acknowledgement directly',
  not has_table_privilege('authenticated', 'public.post_acknowledgements', 'delete')
union all
select 'Create RPC', to_regprocedure('public.create_board_post(uuid,text,text,text,text,boolean,boolean)') is not null
union all
select 'Update RPC', to_regprocedure('public.update_board_post(uuid,text,text,text,text,boolean,boolean)') is not null
union all
select 'Search RPC', to_regprocedure('public.search_board_posts(text)') is not null
union all
select 'People RPC', to_regprocedure('public.get_board_post_people(uuid,text,integer,integer)') is not null
union all
select 'Versioned acknowledgement RPC', to_regprocedure('public.acknowledge_board_post(uuid,integer)') is not null
union all
select 'Authenticated can call acknowledgement RPC',
  has_function_privilege('authenticated', 'public.acknowledge_board_post(uuid,integer)', 'execute')
union all
select 'Anonymous cannot call acknowledgement RPC',
  not has_function_privilege('anon', 'public.acknowledge_board_post(uuid,integer)', 'execute');
