-- Community Board: phân loại, ghim, xác nhận đã đọc và danh sách người thích.
-- Dựa trên schema được cung cấp trong phiên làm việc.
-- Chạy toàn bộ file trong SQL Editor, sau khi sao lưu schema/dữ liệu.
-- Không thay thế các RPC/view cũ; ứng dụng mới dùng các tên board_* bên dưới.
begin;

alter table public.posts
  add column if not exists category text not null default 'announcement',
  add column if not exists is_pinned boolean not null default false,
  add column if not exists requires_acknowledgement boolean not null default false,
  add column if not exists content_version integer not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.posts'::regclass and conname = 'posts_category_check'
  ) then
    alter table public.posts add constraint posts_category_check
      check (category in ('announcement', 'policy', 'activity'));
  end if;
end $$;

create index if not exists posts_board_order_idx
  on public.posts (is_pinned desc, created_at desc, id);
create index if not exists posts_board_category_idx
  on public.posts (category, is_pinned desc, created_at desc, id);

create table if not exists public.post_acknowledgements (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  acknowledged_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.post_acknowledgements enable row level security;
drop policy if exists board_ack_read on public.post_acknowledgements;
create policy board_ack_read on public.post_acknowledgements
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin((select auth.uid())));

-- Chỉ RPC mới được ghi xác nhận, không cho client tự chọn user_id/thời điểm.
revoke all on public.post_acknowledgements from anon, authenticated;
grant select on public.post_acknowledgements to authenticated;

create or replace view public.board_post_display_view
with (security_invoker = on) as
select v.*,
       p.category,
       p.is_pinned,
       p.requires_acknowledgement,
       exists (
         select 1 from public.post_acknowledgements a
         where a.post_id = p.id and a.user_id = (select auth.uid())
       ) as current_user_acknowledged,
       (
         select count(*)::integer from public.post_acknowledgements a
         where a.post_id = p.id
       ) as acknowledgements_count,
       p.content_version
from public.post_display_view v
join public.posts p on p.id = v.post_id;
revoke all on public.board_post_display_view from anon;
grant select on public.board_post_display_view to authenticated;

-- Nếu nội dung đổi, các xác nhận cũ không được xem là xác nhận nội dung mới.
-- Thay đổi likes_count/comments_count/category/is_pinned không làm mất xác nhận.
create or replace function public.board_increment_content_version()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.title is distinct from old.title
     or new.content is distinct from old.content
     or new.image_url is distinct from old.image_url
     or new.requires_acknowledgement is distinct from old.requires_acknowledgement then
    new.content_version := old.content_version + 1;
  else
    new.content_version := old.content_version;
  end if;
  return new;
end;
$$;
revoke all on function public.board_increment_content_version() from public, anon, authenticated;
drop trigger if exists board_increment_content_version on public.posts;
create trigger board_increment_content_version
  before update on public.posts
  for each row execute function public.board_increment_content_version();

create or replace function public.board_reset_acknowledgements()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.title is distinct from old.title
     or new.content is distinct from old.content
     or new.image_url is distinct from old.image_url
     or (old.requires_acknowledgement and not new.requires_acknowledgement) then
    delete from public.post_acknowledgements where post_id = new.id;
  end if;
  return new;
end;
$$;
revoke all on function public.board_reset_acknowledgements() from public, anon, authenticated;
drop trigger if exists board_reset_acknowledgements on public.posts;
create trigger board_reset_acknowledgements
  after update of title, content, image_url, requires_acknowledgement on public.posts
  for each row execute function public.board_reset_acknowledgements();

create or replace function public.create_board_post(
  p_post_id uuid, p_title text, p_content text, p_image_url text,
  p_category text, p_is_pinned boolean, p_requires_acknowledgement boolean
)
returns setof public.board_post_display_view
language plpgsql security invoker set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập.' using errcode = '42501';
  end if;
  if coalesce(btrim(p_title), '') = '' or coalesce(btrim(p_content), '') = '' then
    raise exception 'Tiêu đề và nội dung không được để trống.';
  end if;
  insert into public.posts (
    id, author_id, title, content, image_url, category, is_pinned, requires_acknowledgement
  ) values (
    p_post_id, auth.uid(), btrim(p_title), btrim(p_content), p_image_url,
    p_category, p_is_pinned, p_requires_acknowledgement
  );
  return query select * from public.board_post_display_view where post_id = p_post_id;
end;
$$;

create or replace function public.update_board_post(
  p_post_id uuid, p_title text, p_content text, p_image_url text,
  p_category text, p_is_pinned boolean, p_requires_acknowledgement boolean
)
returns setof public.board_post_display_view
language plpgsql security invoker set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập.' using errcode = '42501';
  end if;
  if coalesce(btrim(p_title), '') = '' or coalesce(btrim(p_content), '') = '' then
    raise exception 'Tiêu đề và nội dung không được để trống.';
  end if;
  update public.posts set
    title = btrim(p_title), content = btrim(p_content), image_url = p_image_url,
    category = p_category, is_pinned = p_is_pinned,
    requires_acknowledgement = p_requires_acknowledgement
  where id = p_post_id;
  if not found then
    raise exception 'Bạn không có quyền sửa bài viết này hoặc bài đã bị xóa.' using errcode = '42501';
  end if;
  return query select * from public.board_post_display_view where post_id = p_post_id;
end;
$$;

create or replace function public.search_board_posts(p_search_query text)
returns setof public.board_post_display_view
language sql stable security invoker set search_path = '' as $$
  select * from public.board_post_display_view
  where length(btrim(p_search_query)) >= 2
    and (
      position(lower(btrim(p_search_query)) in lower(title)) > 0
      or position(lower(btrim(p_search_query)) in lower(content)) > 0
    )
  order by is_pinned desc, post_created_at desc, post_id
  limit 20;
$$;

create or replace function public.acknowledge_board_post(p_post_id uuid, p_content_version integer)
returns setof public.board_post_display_view
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_post public.posts%rowtype;
begin
  if v_user is null or not exists (select 1 from public.profiles where id = v_user) then
    raise exception 'Vui lòng đăng nhập bằng tài khoản thành viên.' using errcode = '42501';
  end if;
  -- Khóa cùng bản ghi mà thao tác sửa bài sẽ khóa, tránh xác nhận/sửa đồng thời.
  select * into v_post from public.posts where id = p_post_id for update;
  if not found then
    raise exception 'Bài viết không còn tồn tại.';
  end if;
  if not v_post.requires_acknowledgement then
    raise exception 'Bài viết này không yêu cầu xác nhận.';
  end if;
  if p_content_version is distinct from v_post.content_version then
    raise exception 'Nội dung đã thay đổi. Vui lòng làm mới và đọc lại trước khi xác nhận.';
  end if;
  if v_post.author_id = v_user then
    raise exception 'Tác giả không cần xác nhận bài viết của mình.';
  end if;
  insert into public.post_acknowledgements (post_id, user_id)
    values (p_post_id, v_user) on conflict (post_id, user_id) do nothing;
  -- Chỉ trả số lượng tổng cho admin; nhân viên chỉ nhận trạng thái của mình,
  -- thống nhất với RLS của view khi truy vấn bằng SECURITY INVOKER.
  return query
    select v.post_id, v.title, v.content, v.image_url, v.post_created_at,
           v.post_updated_at, v.author_id, v.author_username, v.author_avatar_url,
           v.author_role, v.likes_count, v.comments_count, v.current_user_liked,
           v.category, v.is_pinned, v.requires_acknowledgement,
           v.current_user_acknowledged,
           case when public.is_admin(v_user) then v.acknowledgements_count else 1 end,
           v.content_version
    from public.board_post_display_view v where v.post_id = p_post_id;
end;
$$;

create or replace function public.get_board_post_people(
  p_post_id uuid, p_kind text, p_offset integer default 0, p_limit integer default 20
)
returns jsonb language plpgsql stable security invoker set search_path = '' as $$
declare
  v_author uuid;
  v_requires_ack boolean;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Vui lòng đăng nhập.' using errcode = '42501';
  end if;
  if p_kind not in ('likes', 'acknowledged', 'pending') or p_kind is null then
    raise exception 'Loại danh sách không hợp lệ.';
  end if;
  if p_offset is null or p_offset < 0 or p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'Tham số phân trang không hợp lệ.';
  end if;
  if p_kind <> 'likes' and not coalesce(public.is_admin(auth.uid()), false) then
    raise exception 'Chỉ quản trị viên được xem tình hình xác nhận.' using errcode = '42501';
  end if;
  select author_id, requires_acknowledgement into v_author, v_requires_ack
    from public.posts where id = p_post_id;
  if not found then raise exception 'Không tìm thấy bài viết.'; end if;
  if p_kind <> 'likes' and not v_requires_ack then
    raise exception 'Bài viết không yêu cầu xác nhận.';
  end if;
  -- Người nhận: các hồ sơ hiện tại, trừ tác giả; không suy diễn đã đọc từ like.
  with people as (
    select p.id as user_id, p.username, p.avatar_url,
           case when p_kind = 'acknowledged' then a.acknowledged_at else null::timestamptz end as acknowledged_at
    from public.profiles p
    left join public.post_acknowledgements a on a.user_id = p.id and a.post_id = p_post_id
    where
      (p_kind = 'likes' and exists (
        select 1 from public.likes l where l.user_id = p.id and l.post_id = p_post_id
      ))
      or (p_kind = 'acknowledged' and p.id <> v_author and a.user_id is not null)
      or (p_kind = 'pending' and p.id <> v_author and a.user_id is null)
  ), page as (
    select * from people order by username, user_id limit p_limit offset p_offset
  )
  select jsonb_build_object(
    'total_count', (select count(*) from people),
    'people', coalesce((select jsonb_agg(to_jsonb(page) order by username, user_id) from page), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

-- Không dùng role do client truyền trong metadata để cấp quyền quản trị.
-- Quyền admin hiện hữu không bị thay đổi.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username, role)
    values (new.id, new.raw_user_meta_data->>'username', 'user');
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

revoke all on function public.create_board_post(uuid,text,text,text,text,boolean,boolean) from public, anon;
revoke all on function public.update_board_post(uuid,text,text,text,text,boolean,boolean) from public, anon;
revoke all on function public.search_board_posts(text) from public, anon;
revoke all on function public.acknowledge_board_post(uuid,integer) from public, anon;
revoke all on function public.get_board_post_people(uuid,text,integer,integer) from public, anon;
grant execute on function public.create_board_post(uuid,text,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.update_board_post(uuid,text,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.search_board_posts(text) to authenticated;
grant execute on function public.acknowledge_board_post(uuid,integer) to authenticated;
grant execute on function public.get_board_post_people(uuid,text,integer,integer) to authenticated;

notify pgrst, 'reload schema';
commit;
