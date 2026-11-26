CREATE TABLE IF NOT EXISTS users (
  uid TEXT PRIMARY KEY,
  display_name TEXT NOT NULL DEFAULT 'User',
  email TEXT UNIQUE,
  phone_number TEXT,
  photo_url TEXT,
  bio TEXT,
  community TEXT,
  region TEXT,
  age SMALLINT,
  college TEXT,
  interests TEXT[] NOT NULL DEFAULT '{}',
  languages TEXT[] NOT NULL DEFAULT '{}',
  match_mode TEXT NOT NULL DEFAULT 'different' CHECK (match_mode IN ('familiar', 'different')),
  is_onboarded BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS languages TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS match_mode TEXT NOT NULL DEFAULT 'different';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_onboarded BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS festivals (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  community TEXT NOT NULL,
  region TEXT NOT NULL,
  event_date TEXT NOT NULL,
  etiquette_notes TEXT,
  description TEXT,
  banner_url TEXT
);

ALTER TABLE festivals ADD COLUMN IF NOT EXISTS banner_url TEXT;

-- Tracks Home Page profile swaps (Pass vs. Send Namaste / Bond)
CREATE TABLE IF NOT EXISTS profile_swipes (
  swiper_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  target_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('pass', 'bond')),
  match_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (swiper_uid, target_uid),
  CHECK (swiper_uid <> target_uid)
);

CREATE INDEX IF NOT EXISTS idx_profile_swipes_target ON profile_swipes(target_uid, action);

CREATE TABLE IF NOT EXISTS bonds (
  id TEXT PRIMARY KEY,
  user1_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  user2_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  initiator_uid TEXT REFERENCES users(uid) ON DELETE SET NULL,
  stage SMALLINT NOT NULL DEFAULT 0 CHECK (stage BETWEEN 0 AND 3),
  match_reason TEXT,
  festivals_shared INT NOT NULL DEFAULT 0,
  message_count INT NOT NULL DEFAULT 0,
  upcoming_festival_id INT REFERENCES festivals(id) ON DELETE SET NULL,
  upcoming_event_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (user1_uid <> user2_uid)
);

ALTER TABLE bonds ADD COLUMN IF NOT EXISTS initiator_uid TEXT REFERENCES users(uid) ON DELETE SET NULL;
ALTER TABLE bonds ADD COLUMN IF NOT EXISTS match_reason TEXT;
ALTER TABLE bonds ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE bonds DROP CONSTRAINT IF EXISTS bonds_stage_check;
ALTER TABLE bonds ADD CONSTRAINT bonds_stage_check CHECK (stage BETWEEN 0 AND 3);

CREATE INDEX IF NOT EXISTS idx_bonds_user1 ON bonds(user1_uid);
CREATE INDEX IF NOT EXISTS idx_bonds_user2 ON bonds(user2_uid);
CREATE INDEX IF NOT EXISTS idx_bonds_initiator ON bonds(initiator_uid);
CREATE INDEX IF NOT EXISTS idx_bonds_upcoming_festival ON bonds(upcoming_festival_id);

CREATE TABLE IF NOT EXISTS bond_confirmations (
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  user_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  stage_target SMALLINT NOT NULL CHECK (stage_target BETWEEN 2 AND 3),
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (bond_id, user_uid, stage_target)
);

CREATE INDEX IF NOT EXISTS idx_bond_confirmations_user ON bond_confirmations(user_uid);

CREATE TABLE IF NOT EXISTS bond_history (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  entry TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bond_history_bond_created ON bond_history(bond_id, created_at ASC);

CREATE TABLE IF NOT EXISTS festival_invitations (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  festival_id INT NOT NULL REFERENCES festivals(id) ON DELETE CASCADE,
  host_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  guest_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_invitations_bond ON festival_invitations(bond_id);
CREATE INDEX IF NOT EXISTS idx_festival_invitations_festival ON festival_invitations(festival_id);
CREATE INDEX IF NOT EXISTS idx_festival_invitations_host ON festival_invitations(host_uid);
CREATE INDEX IF NOT EXISTS idx_festival_invitations_guest ON festival_invitations(guest_uid);

-- Stores shared festival / cultural milestone photos uploaded to Supabase Storage
CREATE TABLE IF NOT EXISTS festival_memories (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  festival_id INT REFERENCES festivals(id) ON DELETE SET NULL,
  uploader_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_festival_memories_bond ON festival_memories(bond_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_festival_memories_festival ON festival_memories(festival_id);
CREATE INDEX IF NOT EXISTS idx_festival_memories_uploader ON festival_memories(uploader_uid);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  sender_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  text TEXT NOT NULL,
  media_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url TEXT;

CREATE INDEX IF NOT EXISTS idx_messages_bond_created ON messages(bond_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_uid);

CREATE TABLE IF NOT EXISTS reports_blocks (
  reporter_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  target_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  reason TEXT,
  is_block BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (reporter_uid, target_uid)
);

CREATE INDEX IF NOT EXISTS idx_reports_blocks_target ON reports_blocks(target_uid);

-- Seed core Nepali cultural festivals
INSERT INTO festivals (name, community, region, event_date, etiquette_notes, description) VALUES
  ('Udhauli', 'Rai / Limbu', 'Hill region', '15 Dec', 'Remove shoes before entering sacred spaces; join Sakela circle respectfully.', 'Kirat festival marking the migration of birds and harvest thanksgiving.'),
  ('Yomari Punhi', 'Newar', 'Valley', '26 Dec', 'Accept yomari with both hands; ask before photographing home shrines.', 'Post-harvest Newar festival celebrating rice harvest with steamed yomari.'),
  ('Tamu Lhosar', 'Gurung', 'Hill region', '30 Dec', 'Greet elders with Tashi Delek / Phyafulla.', 'Gurung New Year celebrated with traditional dress, dances, and feasting.'),
  ('Maghe Sankranti', 'Tharu / Magar', 'Terai & Hills', '15 Jan', 'Share til ko laddu and yam with hosts.', 'Mid-winter festival celebrating the end of the winter solstice.')
ON CONFLICT (name) DO NOTHING;

-- (Seed demo accounts removed; all users are real Firebase Auth accounts synced to public.users)


-- ============================================================================
-- Triggers, Row Level Security (RLS), and Supabase Storage Buckets
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.bonds
  SET message_count = message_count + 1,
      updated_at = NOW()
  WHERE id = NEW.bond_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_after_insert ON public.messages;
CREATE TRIGGER trg_messages_after_insert
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message();

CREATE OR REPLACE FUNCTION public.handle_profile_swipe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_u1 TEXT;
  v_u2 TEXT;
  v_bond_id TEXT;
  v_mutual BOOLEAN;
BEGIN
  IF NEW.action <> 'bond' THEN
    RETURN NEW;
  END IF;

  IF NEW.swiper_uid < NEW.target_uid THEN
    v_u1 := NEW.swiper_uid;
    v_u2 := NEW.target_uid;
  ELSE
    v_u1 := NEW.target_uid;
    v_u2 := NEW.swiper_uid;
  END IF;
  v_bond_id := v_u1 || '_' || v_u2;

  SELECT EXISTS (
    SELECT 1 FROM public.profile_swipes
    WHERE swiper_uid = NEW.target_uid
      AND target_uid = NEW.swiper_uid
      AND action = 'bond'
  ) INTO v_mutual;

  INSERT INTO public.bonds (id, user1_uid, user2_uid, initiator_uid, stage, match_reason)
  VALUES (
    v_bond_id,
    v_u1,
    v_u2,
    NEW.swiper_uid,
    CASE WHEN v_mutual THEN 1 ELSE 0 END,
    NEW.match_reason
  )
  ON CONFLICT (id) DO UPDATE
  SET stage = CASE WHEN public.bonds.stage = 0 AND (v_mutual OR public.bonds.initiator_uid <> NEW.swiper_uid) THEN 1 ELSE public.bonds.stage END,
      updated_at = NOW();

  IF v_mutual THEN
    INSERT INTO public.bond_history (bond_id, entry)
    SELECT v_bond_id, 'Bonded at Chinari'
    WHERE NOT EXISTS (
      SELECT 1 FROM public.bond_history
      WHERE bond_id = v_bond_id AND entry = 'Bonded at Chinari'
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profile_swipes_after_upsert ON public.profile_swipes;
CREATE TRIGGER trg_profile_swipes_after_upsert
AFTER INSERT OR UPDATE ON public.profile_swipes
FOR EACH ROW
EXECUTE FUNCTION public.handle_profile_swipe();

-- Enable Row Level Security on all public tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festivals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bonds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bond_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bond_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festival_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.festival_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports_blocks ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Firebase Third-Party Auth: auth.jwt() ->> 'sub' = Firebase UID)
CREATE POLICY "users_select_all" ON public.users
  FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT TO authenticated WITH CHECK (uid = (SELECT auth.jwt() ->> 'sub'));
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE TO authenticated
  USING (uid = (SELECT auth.jwt() ->> 'sub'))
  WITH CHECK (uid = (SELECT auth.jwt() ->> 'sub'));

CREATE POLICY "festivals_select_all" ON public.festivals
  FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "profile_swipes_select_participants" ON public.profile_swipes
  FOR SELECT TO authenticated USING ((SELECT auth.jwt() ->> 'sub') IN (swiper_uid, target_uid));
CREATE POLICY "profile_swipes_insert_own" ON public.profile_swipes
  FOR INSERT TO authenticated WITH CHECK (swiper_uid = (SELECT auth.jwt() ->> 'sub'));
CREATE POLICY "profile_swipes_update_own" ON public.profile_swipes
  FOR UPDATE TO authenticated
  USING (swiper_uid = (SELECT auth.jwt() ->> 'sub'))
  WITH CHECK (swiper_uid = (SELECT auth.jwt() ->> 'sub'));

CREATE POLICY "bonds_select_participants" ON public.bonds
  FOR SELECT TO authenticated USING ((SELECT auth.jwt() ->> 'sub') IN (user1_uid, user2_uid));
CREATE POLICY "bonds_insert_participants" ON public.bonds
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.jwt() ->> 'sub') IN (user1_uid, user2_uid));
CREATE POLICY "bonds_update_participants" ON public.bonds
  FOR UPDATE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') IN (user1_uid, user2_uid))
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') IN (user1_uid, user2_uid));

CREATE POLICY "bond_confirmations_select_participants" ON public.bond_confirmations
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid)));
CREATE POLICY "bond_confirmations_insert_own" ON public.bond_confirmations
  FOR INSERT TO authenticated
  WITH CHECK (
    user_uid = (SELECT auth.jwt() ->> 'sub')
    AND EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid))
  );

CREATE POLICY "bond_history_select_participants" ON public.bond_history
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid)));
CREATE POLICY "bond_history_insert_participants" ON public.bond_history
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid)));

CREATE POLICY "festival_invitations_select_participants" ON public.festival_invitations
  FOR SELECT TO authenticated USING ((SELECT auth.jwt() ->> 'sub') IN (host_uid, guest_uid));
CREATE POLICY "festival_invitations_insert_host" ON public.festival_invitations
  FOR INSERT TO authenticated WITH CHECK (host_uid = (SELECT auth.jwt() ->> 'sub'));
CREATE POLICY "festival_invitations_update_participants" ON public.festival_invitations
  FOR UPDATE TO authenticated
  USING ((SELECT auth.jwt() ->> 'sub') IN (host_uid, guest_uid))
  WITH CHECK ((SELECT auth.jwt() ->> 'sub') IN (host_uid, guest_uid));

CREATE POLICY "festival_memories_select_participants" ON public.festival_memories
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid)));
CREATE POLICY "festival_memories_insert_uploader" ON public.festival_memories
  FOR INSERT TO authenticated
  WITH CHECK (
    uploader_uid = (SELECT auth.jwt() ->> 'sub')
    AND EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid))
  );

CREATE POLICY "messages_select_participants" ON public.messages
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid)));
CREATE POLICY "messages_insert_sender" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_uid = (SELECT auth.jwt() ->> 'sub')
    AND EXISTS (SELECT 1 FROM public.bonds b WHERE b.id = bond_id AND (SELECT auth.jwt() ->> 'sub') IN (b.user1_uid, b.user2_uid))
  );

CREATE POLICY "reports_blocks_select_own" ON public.reports_blocks
  FOR SELECT TO authenticated USING (reporter_uid = (SELECT auth.jwt() ->> 'sub'));
CREATE POLICY "reports_blocks_insert_own" ON public.reports_blocks
  FOR INSERT TO authenticated WITH CHECK (reporter_uid = (SELECT auth.jwt() ->> 'sub'));
CREATE POLICY "reports_blocks_update_own" ON public.reports_blocks
  FOR UPDATE TO authenticated
  USING (reporter_uid = (SELECT auth.jwt() ->> 'sub'))
  WITH CHECK (reporter_uid = (SELECT auth.jwt() ->> 'sub'));

-- Supabase Storage Buckets (avatars and bond-media)
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('bond-media', 'bond-media', true)
ON CONFLICT (id) DO NOTHING;

-- Supabase Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE
  public.bonds,
  public.messages,
  public.bond_confirmations,
  public.bond_history,
  public.festival_invitations;

-- ============================================================================
-- Supabase RPC Functions (used by Flutter ChatService, BondService, AuthService)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.ensure_demo_bonds_for_user(p_uid TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_user_profile(
  p_uid TEXT,
  p_display_name TEXT DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_phone_number TEXT DEFAULT NULL,
  p_photo_url TEXT DEFAULT NULL,
  p_community TEXT DEFAULT NULL,
  p_region TEXT DEFAULT NULL,
  p_age SMALLINT DEFAULT NULL,
  p_college TEXT DEFAULT NULL,
  p_interests TEXT[] DEFAULT NULL,
  p_match_mode TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_user public.users;
BEGIN
  INSERT INTO public.users (
    uid, display_name, email, phone_number, photo_url,
    community, region, age, college, interests, match_mode
  ) VALUES (
    p_uid,
    COALESCE(NULLIF(p_display_name, ''), 'User'),
    LOWER(NULLIF(p_email, '')),
    p_phone_number,
    p_photo_url,
    p_community,
    p_region,
    p_age,
    p_college,
    COALESCE(p_interests, '{}'::TEXT[]),
    COALESCE(p_match_mode, 'different')
  )
  ON CONFLICT (uid) DO UPDATE SET
    display_name = COALESCE(NULLIF(EXCLUDED.display_name, ''), public.users.display_name),
    email = COALESCE(EXCLUDED.email, public.users.email),
    phone_number = COALESCE(EXCLUDED.phone_number, public.users.phone_number),
    photo_url = COALESCE(EXCLUDED.photo_url, public.users.photo_url),
    community = COALESCE(EXCLUDED.community, public.users.community),
    region = COALESCE(EXCLUDED.region, public.users.region),
    age = COALESCE(EXCLUDED.age, public.users.age),
    college = COALESCE(EXCLUDED.college, public.users.college),
    interests = CASE WHEN p_interests IS NOT NULL THEN EXCLUDED.interests ELSE public.users.interests END,
    match_mode = COALESCE(p_match_mode, public.users.match_mode),
    updated_at = NOW()
  RETURNING * INTO v_user;

  PERFORM public.ensure_demo_bonds_for_user(p_uid);

  RETURN to_jsonb(v_user);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_bonds(p_uid TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb),
    '[]'::jsonb
  )
  FROM (
    SELECT
      b.id AS bond_id,
      b.stage,
      b.match_reason,
      b.festivals_shared,
      b.message_count,
      b.upcoming_event_note,
      b.created_at,
      u.uid AS other_uid,
      u.display_name AS other_name,
      u.email AS other_email,
      u.phone_number AS other_phone,
      u.photo_url AS other_photo,
      u.community AS other_community,
      u.region AS other_region,
      f.name AS upcoming_event_title,
      f.event_date AS upcoming_event_date,
      COALESCE(
        (SELECT json_agg(h.entry ORDER BY h.created_at ASC, h.id ASC)
         FROM public.bond_history h WHERE h.bond_id = b.id),
        '[]'::json
      ) AS history,
      COALESCE(
        (SELECT json_agg(c.user_uid)
         FROM public.bond_confirmations c
         WHERE c.bond_id = b.id AND c.stage_target = b.stage + 1),
        '[]'::json
      ) AS stage_confirmations
    FROM public.bonds b
    JOIN public.users u ON u.uid = CASE WHEN b.user1_uid = p_uid THEN b.user2_uid ELSE b.user1_uid END
    LEFT JOIN public.festivals f ON f.id = b.upcoming_festival_id
    WHERE (b.user1_uid = p_uid OR b.user2_uid = p_uid)
      AND b.stage >= 1
    ORDER BY b.stage DESC, b.created_at ASC
  ) t;
$$;

CREATE OR REPLACE FUNCTION public.search_bonded_users(p_uid TEXT, p_query TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb),
    '[]'::jsonb
  )
  FROM (
    SELECT
      u.uid,
      u.display_name AS "displayName",
      u.email,
      u.phone_number AS "phoneNumber",
      u.photo_url AS "photoUrl",
      u.community,
      u.region
    FROM public.bonds b
    JOIN public.users u ON u.uid = CASE WHEN b.user1_uid = p_uid THEN b.user2_uid ELSE b.user1_uid END
    WHERE (b.user1_uid = p_uid OR b.user2_uid = p_uid)
      AND b.stage >= 1
      AND (
        u.display_name ILIKE '%' || p_query || '%'
        OR COALESCE(u.email, '') ILIKE '%' || p_query || '%'
        OR COALESCE(u.phone_number, '') ILIKE '%' || p_query || '%'
        OR COALESCE(u.community, '') ILIKE '%' || p_query || '%'
      )
    LIMIT 30
  ) t;
$$;

CREATE OR REPLACE FUNCTION public.confirm_bond_stage(p_bond_id TEXT, p_user_uid TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_bond public.bonds;
  v_target SMALLINT;
  v_conf_count INT;
  v_advanced BOOLEAN := FALSE;
  v_stage_names TEXT[] := ARRAY['Pending', 'Chinari', 'Saathi', 'Mit'];
BEGIN
  SELECT * INTO v_bond
  FROM public.bonds
  WHERE id = p_bond_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bond not found';
  END IF;

  IF v_bond.user1_uid <> p_user_uid AND v_bond.user2_uid <> p_user_uid THEN
    RAISE EXCEPTION 'Not a participant of this bond';
  END IF;

  IF v_bond.stage >= 3 OR v_bond.stage < 1 THEN
    RETURN jsonb_build_object('stage', v_bond.stage, 'advanced', false);
  END IF;

  v_target := v_bond.stage + 1;

  INSERT INTO public.bond_confirmations (bond_id, user_uid, stage_target)
  VALUES (p_bond_id, p_user_uid, v_target)
  ON CONFLICT DO NOTHING;

  SELECT COUNT(*)::INT INTO v_conf_count
  FROM public.bond_confirmations
  WHERE bond_id = p_bond_id AND stage_target = v_target;

  IF v_conf_count >= 2 THEN
    UPDATE public.bonds
    SET stage = v_target,
        festivals_shared = festivals_shared + 1,
        updated_at = NOW()
    WHERE id = p_bond_id;

    INSERT INTO public.bond_history (bond_id, entry)
    VALUES (p_bond_id, 'Reached ' || v_stage_names[v_target + 1]);

    v_advanced := TRUE;
  END IF;

  RETURN jsonb_build_object(
    'stage', CASE WHEN v_advanced THEN v_target ELSE v_bond.stage END,
    'advanced', v_advanced
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_chats(p_uid TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb),
    '[]'::jsonb
  )
  FROM (
    SELECT
      b.id AS "chatId",
      b.stage,
      u.uid AS "otherUid",
      u.display_name AS "otherName",
      u.email AS "otherEmail",
      u.phone_number AS "otherPhone",
      u.photo_url AS "otherPhoto",
      u.community AS "otherCommunity",
      u.region AS "otherRegion",
      COALESCE(m.text, '') AS "lastMessage",
      COALESCE(m.sender_uid, '') AS "lastSenderId",
      COALESCE(m.created_at, b.created_at) AS "lastMessageTime"
    FROM public.bonds b
    JOIN public.users u ON u.uid = CASE WHEN b.user1_uid = p_uid THEN b.user2_uid ELSE b.user1_uid END
    LEFT JOIN LATERAL (
      SELECT text, sender_uid, created_at
      FROM public.messages
      WHERE bond_id = b.id
      ORDER BY created_at DESC
      LIMIT 1
    ) m ON TRUE
    WHERE (b.user1_uid = p_uid OR b.user2_uid = p_uid)
      AND b.stage >= 1
    ORDER BY COALESCE(m.created_at, b.created_at) DESC
  ) t;
$$;

CREATE OR REPLACE FUNCTION public.get_bond_messages(p_bond_id TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb),
    '[]'::jsonb
  )
  FROM (
    SELECT
      m.id,
      m.bond_id AS "bondId",
      m.sender_uid AS "senderId",
      u.display_name AS "senderName",
      m.text,
      m.media_url AS "mediaUrl",
      m.created_at AS "timestamp"
    FROM public.messages m
    JOIN public.users u ON u.uid = m.sender_uid
    WHERE m.bond_id = p_bond_id
    ORDER BY m.created_at DESC
    LIMIT 100
  ) t;
$$;

CREATE OR REPLACE FUNCTION public.create_or_get_bond(
  p_user1_uid TEXT,
  p_user2_uid TEXT,
  p_initiator_uid TEXT DEFAULT NULL,
  p_stage SMALLINT DEFAULT 1,
  p_match_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_u1 TEXT;
  v_u2 TEXT;
  v_bond_id TEXT;
  v_inserted BOOLEAN := FALSE;
BEGIN
  IF p_user1_uid IS NULL OR p_user2_uid IS NULL OR p_user1_uid = p_user2_uid THEN
    RAISE EXCEPTION 'Two distinct user UIDs are required';
  END IF;

  IF p_user1_uid < p_user2_uid THEN
    v_u1 := p_user1_uid;
    v_u2 := p_user2_uid;
  ELSE
    v_u1 := p_user2_uid;
    v_u2 := p_user1_uid;
  END IF;
  v_bond_id := v_u1 || '_' || v_u2;

  INSERT INTO public.bonds (id, user1_uid, user2_uid, initiator_uid, stage, match_reason)
  VALUES (v_bond_id, v_u1, v_u2, COALESCE(p_initiator_uid, p_user1_uid), p_stage, p_match_reason)
  ON CONFLICT (id) DO NOTHING;

  IF FOUND AND p_stage >= 1 THEN
    v_inserted := TRUE;
    INSERT INTO public.bond_history (bond_id, entry)
    VALUES (v_bond_id, 'Bonded at Chinari');
  END IF;

  RETURN jsonb_build_object('bondId', v_bond_id, 'created', v_inserted);
END;
$$;

-- ============================================================================
-- Dynamic Bond Stages, Festival Scheduling, Discoverable Users, & Nav Badges
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.bond_stages (
  stage SMALLINT PRIMARY KEY,
  name TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  description TEXT NOT NULL
);

ALTER TABLE public.bond_stages ENABLE ROW LEVEL SECURITY;

INSERT INTO public.bond_stages (stage, name, subtitle, description) VALUES
  (1, 'Chinari', 'Acquaintance & Cultural Introduction', 'You have connected across communities. Chat, share stories, and learn about each other''s traditions and festivals.'),
  (2, 'Saathi', 'Trusted Companion', 'You have met in person at a cultural festival or event and both confirmed it. Your friendship now bridges both communities.'),
  (3, 'Mit', 'Sacred Miteri Bond', 'A lifelong cultural kinship chosen mutually after sharing festivals and milestones together.')
ON CONFLICT (stage) DO UPDATE SET
  name = EXCLUDED.name,
  subtitle = EXCLUDED.subtitle,
  description = EXCLUDED.description;

CREATE OR REPLACE FUNCTION public.set_bond_festival(
  p_bond_id TEXT,
  p_user_uid TEXT,
  p_festival_id INT,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_bond public.bonds;
  v_fest public.festivals;
  v_guest_uid TEXT;
BEGIN
  SELECT * INTO v_bond FROM public.bonds WHERE id = p_bond_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bond not found';
  END IF;

  IF p_festival_id IS NULL THEN
    UPDATE public.bonds
    SET upcoming_festival_id = NULL,
        upcoming_event_note = NULL,
        updated_at = NOW()
    WHERE id = p_bond_id;
    RETURN jsonb_build_object('ok', true);
  END IF;

  SELECT * INTO v_fest FROM public.festivals WHERE id = p_festival_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Festival not found';
  END IF;

  v_guest_uid := CASE WHEN v_bond.user1_uid = p_user_uid THEN v_bond.user2_uid ELSE v_bond.user1_uid END;

  UPDATE public.bonds
  SET upcoming_festival_id = p_festival_id,
      upcoming_event_note = COALESCE(
        NULLIF(p_note, ''),
        CASE
          WHEN v_bond.stage = 1 THEN 'After you meet, you both confirm it to reach Saathi.'
          WHEN v_bond.stage = 2 THEN 'After you meet, you both confirm it. Mit is a choice for later.'
          ELSE 'Celebrating your Miteri bond together.'
        END
      ),
      updated_at = NOW()
  WHERE id = p_bond_id;

  INSERT INTO public.festival_invitations (bond_id, festival_id, host_uid, guest_uid, status)
  VALUES (p_bond_id, p_festival_id, p_user_uid, v_guest_uid, 'accepted');

  INSERT INTO public.bond_history (bond_id, entry)
  VALUES (p_bond_id, 'Planned ' || v_fest.name || ' (' || v_fest.event_date || ')');

  RETURN jsonb_build_object('ok', true, 'festival', v_fest.name);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_nav_badges(p_uid TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'eventsCount', (
      SELECT COUNT(*)::INT
      FROM public.bonds b
      WHERE (b.user1_uid = p_uid OR b.user2_uid = p_uid)
        AND b.stage >= 1
        AND b.upcoming_festival_id IS NOT NULL
    ),
    'chatsCount', (
      SELECT COUNT(*)::INT
      FROM public.bonds b
      WHERE (b.user1_uid = p_uid OR b.user2_uid = p_uid)
        AND b.stage >= 1
        AND EXISTS (
          SELECT 1 FROM public.messages m
          WHERE m.bond_id = b.id
            AND m.sender_uid <> p_uid
            AND m.created_at = (
              SELECT MAX(m2.created_at) FROM public.messages m2 WHERE m2.bond_id = b.id
            )
        )
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.get_discoverable_users(p_uid TEXT)
RETURNS JSONB
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb),
    '[]'::jsonb
  )
  FROM (
    SELECT
      u.uid,
      u.display_name AS "displayName",
      u.email,
      u.phone_number AS "phoneNumber",
      u.photo_url AS "photoUrl",
      u.community,
      u.region,
      u.bio,
      u.interests
    FROM public.users u
    WHERE u.uid <> p_uid
      AND NOT EXISTS (
        SELECT 1 FROM public.bonds b
        WHERE (b.user1_uid = p_uid AND b.user2_uid = u.uid)
           OR (b.user1_uid = u.uid AND b.user2_uid = p_uid)
      )
    ORDER BY u.created_at DESC
    LIMIT 50
  ) t;
$$;
