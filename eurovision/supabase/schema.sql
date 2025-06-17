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