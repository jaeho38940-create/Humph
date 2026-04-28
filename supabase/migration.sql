-- ============================================
-- Humph App - Supabase Database Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Profiles table (extends auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text not null,
  avatar_url text,
  manner_temp float default 36.5,
  created_at timestamptz default now() not null
);

alter table public.profiles enable row level security;

drop policy if exists "Public profiles are viewable by everyone" on profiles;
create policy "Public profiles are viewable by everyone"
  on profiles for select using (true);

drop policy if exists "Users can insert their own profile" on profiles;
create policy "Users can insert their own profile"
  on profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on profiles;
create policy "Users can update their own profile"
  on profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'User'),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Posts table
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  price int default 0,
  is_free boolean default false,
  category text default 'Other',
  status text default 'selling' check (status in ('selling', 'reserved', 'sold')),
  location text default 'Camp Humphreys',
  view_count int default 0,
  like_count int default 0,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

alter table public.posts enable row level security;

drop policy if exists "Posts are viewable by everyone" on posts;
create policy "Posts are viewable by everyone"
  on posts for select using (true);

drop policy if exists "Authenticated users can create posts" on posts;
create policy "Authenticated users can create posts"
  on posts for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update their own posts" on posts;
create policy "Users can update their own posts"
  on posts for update using (auth.uid() = user_id);

drop policy if exists "Users can delete their own posts" on posts;
create policy "Users can delete their own posts"
  on posts for delete using (auth.uid() = user_id);

-- 3. Post images table
create table if not exists public.post_images (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  image_url text not null,
  display_order int default 0,
  created_at timestamptz default now() not null
);

alter table public.post_images enable row level security;

drop policy if exists "Post images are viewable by everyone" on post_images;
create policy "Post images are viewable by everyone"
  on post_images for select using (true);

drop policy if exists "Post owners can insert images" on post_images;
create policy "Post owners can insert images"
  on post_images for insert with check (
    auth.uid() = (select user_id from posts where id = post_id)
  );

drop policy if exists "Post owners can delete images" on post_images;
create policy "Post owners can delete images"
  on post_images for delete using (
    auth.uid() = (select user_id from posts where id = post_id)
  );

-- 4. Likes table
create table if not exists public.likes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  post_id uuid references public.posts(id) on delete cascade not null,
  created_at timestamptz default now() not null,
  unique(user_id, post_id)
);

alter table public.likes enable row level security;

drop policy if exists "Likes are viewable by everyone" on likes;
create policy "Likes are viewable by everyone"
  on likes for select using (true);

drop policy if exists "Authenticated users can like" on likes;
create policy "Authenticated users can like"
  on likes for insert with check (auth.uid() = user_id);

drop policy if exists "Users can remove their own likes" on likes;
create policy "Users can remove their own likes"
  on likes for delete using (auth.uid() = user_id);

-- Update like_count on posts via trigger
create or replace function public.update_like_count()
returns trigger as $$
begin
  if TG_OP = 'INSERT' then
    update posts set like_count = like_count + 1 where id = NEW.post_id;
    return NEW;
  elsif TG_OP = 'DELETE' then
    update posts set like_count = like_count - 1 where id = OLD.post_id;
    return OLD;
  end if;
end;
$$ language plpgsql security definer;

drop trigger if exists on_like_change on likes;
create trigger on_like_change
  after insert or delete on likes
  for each row execute function public.update_like_count();

-- 5. Chat rooms table
create table if not exists public.chat_rooms (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete set null,
  buyer_id uuid references public.profiles(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  last_message text,
  last_message_at timestamptz default now(),
  created_at timestamptz default now() not null,
  unique(post_id, buyer_id, seller_id)
);

alter table public.chat_rooms enable row level security;

drop policy if exists "Users can view their own chat rooms" on chat_rooms;
create policy "Users can view their own chat rooms"
  on chat_rooms for select using (
    auth.uid() = buyer_id or auth.uid() = seller_id
  );

drop policy if exists "Authenticated users can create chat rooms" on chat_rooms;
create policy "Authenticated users can create chat rooms"
  on chat_rooms for insert with check (auth.uid() = buyer_id);

drop policy if exists "Participants can update chat rooms" on chat_rooms;
create policy "Participants can update chat rooms"
  on chat_rooms for update using (
    auth.uid() = buyer_id or auth.uid() = seller_id
  );

-- 6. Messages table
create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  chat_room_id uuid references public.chat_rooms(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  is_read boolean default false,
  created_at timestamptz default now() not null
);

alter table public.messages enable row level security;

drop policy if exists "Chat participants can view messages" on messages;
create policy "Chat participants can view messages"
  on messages for select using (
    auth.uid() in (
      select buyer_id from chat_rooms where id = chat_room_id
      union
      select seller_id from chat_rooms where id = chat_room_id
    )
  );

drop policy if exists "Chat participants can send messages" on messages;
create policy "Chat participants can send messages"
  on messages for insert with check (
    auth.uid() = sender_id and
    auth.uid() in (
      select buyer_id from chat_rooms where id = chat_room_id
      union
      select seller_id from chat_rooms where id = chat_room_id
    )
  );

drop policy if exists "Recipients can mark messages as read" on messages;
create policy "Recipients can mark messages as read"
  on messages for update using (
    auth.uid() in (
      select buyer_id from chat_rooms where id = chat_room_id
      union
      select seller_id from chat_rooms where id = chat_room_id
    )
  );

-- Auto-update chat room last_message on new message
create or replace function public.update_chat_room_last_message()
returns trigger as $$
begin
  update chat_rooms
  set last_message = NEW.content,
      last_message_at = NEW.created_at
  where id = NEW.chat_room_id;
  return NEW;
end;
$$ language plpgsql security definer;

drop trigger if exists on_new_message on messages;
create trigger on_new_message
  after insert on messages
  for each row execute function public.update_chat_room_last_message();

-- 7. Enable realtime for key tables
-- Note: alter publication might fail if tables are already added, but usually it just warns.
-- We wrap it in a DO block to be safe.
do $$
begin
  alter publication supabase_realtime add table posts;
exception when others then
  raise notice 'Table posts already in publication';
end $$;

do $$
begin
  alter publication supabase_realtime add table messages;
exception when others then
  raise notice 'Table messages already in publication';
end $$;

do $$
begin
  alter publication supabase_realtime add table chat_rooms;
exception when others then
  raise notice 'Table chat_rooms already in publication';
end $$;

-- 8. Create storage bucket for post images
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

drop policy if exists "Anyone can view post images" on storage.objects;
create policy "Anyone can view post images"
  on storage.objects for select
  using (bucket_id = 'post-images');

drop policy if exists "Authenticated users can upload post images" on storage.objects;
create policy "Authenticated users can upload post images"
  on storage.objects for insert
  with check (bucket_id = 'post-images' and auth.role() = 'authenticated');

drop policy if exists "Users can delete their own images" on storage.objects;
create policy "Users can delete their own images"
  on storage.objects for delete
  using (bucket_id = 'post-images' and auth.uid()::text = (storage.foldername(name))[1]);

-- 9. Indexes for performance
create index if not exists idx_posts_created_at on posts(created_at desc);
create index if not exists idx_posts_user_id on posts(user_id);
create index if not exists idx_posts_category on posts(category);
create index if not exists idx_post_images_post_id on post_images(post_id);
create index if not exists idx_likes_user_post on likes(user_id, post_id);
create index if not exists idx_chat_rooms_buyer on chat_rooms(buyer_id);
create index if not exists idx_chat_rooms_seller on chat_rooms(seller_id);
create index if not exists idx_messages_chat_room on messages(chat_room_id, created_at);
