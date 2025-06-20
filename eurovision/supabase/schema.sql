create table public.users (
  id uuid not null default extensions.uuid_generate_v4 (),
  name text not null,
  group_id uuid null,
  avatar_url text null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint users_pkey primary key (id),
  constraint users_group_id_fkey foreign KEY (group_id) references groups (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.votes (
  user_id uuid not null,
  group_id uuid not null,
  country_id integer not null,
  song integer null,
  performance integer null,
  vocals integer null,
  updated_at timestamp without time zone null default now(),
  is_final boolean not null default false,
  total_score integer null,
  constraint votes_pkey primary key (user_id, country_id),
  constraint unique_user_country_group_final unique (user_id, country_id, group_id, is_final),
  constraint votes_country_id_fkey foreign KEY (country_id) references countries (id),
  constraint votes_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;

create table public.notes (
  user_id uuid not null,
  group_id uuid not null,
  country_id integer not null,
  content text null,
  updated_at timestamp without time zone null default now(),
  constraint notes_pkey primary key (user_id, country_id),
  constraint notes_country_id_fkey foreign KEY (country_id) references countries (id),
  constraint notes_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;

create table public.messages (
  id uuid not null default gen_random_uuid (),
  group_id uuid null,
  sender_id uuid null,
  content text not null,
  created_at timestamp with time zone null default now(),
  is_image boolean null default false,
  image_url text null,
  constraint messages_pkey primary key (id),
  constraint messages_group_id_fkey foreign KEY (group_id) references groups (id) on delete CASCADE,
  constraint messages_sender_id_fkey foreign KEY (sender_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

create table public.countries (
  id serial not null,
  name text not null,
  code text null,
  semi_final integer null,
  final boolean null,
  flag text null,
  artist_name text null,
  song_name text null,
  semi_running_order integer null,
  final_running_order integer null,
  constraint countries_pkey primary key (id)
) TABLESPACE pg_default;

create table public.groups (
  id uuid not null default extensions.uuid_generate_v4 (),
  name text not null,
  invite_code text not null,
  constraint groups_pkey primary key (id),
  constraint groups_invite_code_key unique (invite_code)
) TABLESPACE pg_default;



create table email_whitelist (
  email text primary key
);


alter table users enable row level security;
alter table countries enable row level security;
alter table messagess enable row level security;
alter table votes enable row level security;
alter table notes enable row level security;
alter table groups enable row level security;
ALTER TABLE email_whitelist ENABLE ROW LEVEL SECURITY;


-- create functions

create or replace function generate_unique_invite_code()
returns text
language plpgsql
security definer
as $$
declare
  code text;
  exists boolean;
begin
  loop
    -- Generate a 6-character uppercase alphanumeric code
    code := upper(substring(md5(random()::text) from 1 for 6));
    
    -- Check if the code already exists in the "groups" table
    select exists (
      select 1 from public.groups where invite_code = code
    ) into exists;
    
    -- If the code is unique, return it
    if not exists then
      return code;
    end if;
  end loop;
end;
$$;


create or replace function get_user_group_id(user_id uuid)
returns uuid
language sql
security definer
as $$
  select group_id
  from public.users
  where id = user_id
  limit 1;
$$;

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.users (id, name, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    now()
  );
  return new;
end;
$$;


create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();



create or replace function join_group_with_invite_code(invite_code_param text)
returns json
language plpgsql
security definer
as $$
declare
  target_group_id uuid;
  user_current_group_id uuid;
  result json;
begin
  -- Check if user is authenticated
  if auth.uid() is null then
    return json_build_object('success', false, 'error', 'Not authenticated');
  end if;

  -- Find the group with the invite code
  select id into target_group_id
  from public.groups
  where invite_code = invite_code_param;

  if target_group_id is null then
    return json_build_object('success', false, 'error', 'Invalid invite code');
  end if;

  -- Check user's current group (optional)
  select group_id into user_current_group_id
  from public.users
  where id = auth.uid();

  -- Update user's group
  update public.users
  set group_id = target_group_id
  where id = auth.uid();

  -- Return success with group info
  select json_build_object(
    'success', true,
    'group', json_build_object(
      'id', id,
      'name', name,
      'invite_code', invite_code
    )
  ) into result
  from public.groups
  where id = target_group_id;

  return result;
end;
$$;


create or replace function same_group_as_auth_user(target_group_id uuid)
returns boolean
language sql
security definer
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
    and group_id = target_group_id
  );
$$;

-- policy for email whitelist

-- Allow read access only if the email matches the user's email
CREATE POLICY "Allow access if email is whitelisted"
ON email_whitelist
FOR SELECT
USING true

-- policies for countries

create policy "All users can view countries"
on public.countries
for select
to authenticated
using ( true );

create policy "Authenticated users can read countries"
on public.countries
for select
to public
using (
  auth.role() = 'authenticated'
);

create policy "No deletes"
on public.countries
for delete
to public
using (false);

create policy "No inserts"
on public.countries
for insert
to public
with check (false);

create policy "No updates"
on public.countries
for update
to public
using (false);

-- policies for groups

create policy "Users can view groups with invite code"
on public.groups
for select
to authenticated
using (
  invite_code IS NOT NULL
);

-- policies messages

alter policy "Users can delete their own messages"
on public.messages
for delete
to authenticated
using (
  sender_id = auth.uid()
);

create policy "Users can insert messages to their group"
on public.messages
for insert
to authenticated
with check (
  (sender_id = auth.uid())
  AND
  (group_id IN (
    SELECT group_id
    FROM public.users
    WHERE id = auth.uid()
  ))
);

create policy "Users can read messages from their group"
on public.messages
for select
to authenticated
using (
  exists (
    select 1
    from public.users
    where users.id = auth.uid()
      and users.group_id = messages.group_id
  )
);


create policy "Users can update their own messages"
on public.messages
for update
to authenticated
using (
  sender_id = auth.uid()
);

-- policies for notes

create policy "Read own and group notes"
on public.notes
to authenticated
using (
  (user_id = auth.uid())
  OR
  (
    EXISTS (
      SELECT 1
      FROM users u1
      JOIN users u2 ON u1.group_id = u2.group_id
      WHERE u1.id = auth.uid()
        AND u2.id = notes.user_id
    )
  )
);


create policy "Users can delete their own notes"
on public.notes
for delete
to authenticated
using (
  user_id = auth.uid()
);


create policy "Users can insert their own notes"
on public.notes
for insert
to authenticated
with check (
  user_id = auth.uid()
  AND
  group_id IN (
    SELECT group_id
    FROM users
    WHERE id = auth.uid()
  )
);


create policy "Users can update their own notes"
on public.notes
for update
to authenticated
using (
  user_id = auth.uid()
);

-- policies for users

create policy "Read own and group profile"
on public.users
to public
using (
  (id = auth.uid()) OR same_group_as_auth_user(group_id)
);

create policy "Users can insert their own profile and whitelisted"
on public.users
for insert
to authenticated
with check (
  (auth.uid() = id)
  AND
  EXISTS (
    SELECT 1
    FROM email_whitelist
    WHERE email_whitelist.email = auth.email()
  )
);


create policy "Users can update their own profile"
on public.users
for update
to authenticated
using (
  auth.uid() = id
);


-- policies for votes

create policy "Read own and group votes"
on public.votes
to public
using (
  (user_id = auth.uid())
  OR
  EXISTS (
    SELECT 1
    FROM users u1
    JOIN users u2 ON u1.group_id = u2.group_id
    WHERE u1.id = auth.uid()
      AND u2.id = votes.user_id
  )
);

create policy "Users can delete their own votes"
on public.votes
for delete
to authenticated
using (
  user_id = auth.uid()
);


create policy "Users can insert their own votes"
on public.votes
for insert
to authenticated
with check (
  (user_id = auth.uid())
  AND
  (group_id IN (
    SELECT group_id
    FROM users
    WHERE id = auth.uid()
  ))
);


create policy "Users can update their own votes"
on public.votes
for update
to authenticated
using (
  user_id = auth.uid()
);


-- create the buckets for images

select storage.create_bucket('avatars', public := true);


select storage.create_bucket('chat-images', public := true);


-- create policies for avatars 

create policy "Authenticated users can read avatars from users in their group"
on storage.objects
for select
using (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND EXISTS (
    select 1 from users
    where users.id = split_part(name, '/', 1)::uuid
    and users.group_id = get_user_group_id()
  )
);


create policy "Users can upload to their own avatar folder"
on storage.objects
for insert
using (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND split_part(name, '/', 1) = auth.uid()
);


-- create policies for chat images

create policy "Users can upload to their own chat-images folder"
on storage.objects
for insert
using (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
  AND split_part(name, '/', 1) = auth.uid()
);


create policy "Authenticated users can read chat-images from their group"
on storage.objects
for select
using (
  bucket_id = 'chat-images'
  AND auth.role() = 'authenticated'
  AND split_part(name, '/', 1)::uuid = get_user_group_id()
);
