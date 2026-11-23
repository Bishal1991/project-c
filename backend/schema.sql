CREATE TABLE IF NOT EXISTS users (
  uid TEXT PRIMARY KEY,
  display_name TEXT NOT NULL DEFAULT 'User',
  email TEXT UNIQUE,
  phone_number TEXT,
  photo_url TEXT,
  community TEXT,
  region TEXT,
  age SMALLINT,
  college TEXT,
  interests TEXT[] NOT NULL DEFAULT '{}',
  match_mode TEXT NOT NULL DEFAULT 'different' CHECK (match_mode IN ('familiar', 'different')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS match_mode TEXT NOT NULL DEFAULT 'different';

CREATE TABLE IF NOT EXISTS festivals (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  community TEXT NOT NULL,
  region TEXT NOT NULL,
  event_date TEXT NOT NULL,
  etiquette_notes TEXT,
  description TEXT
);

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
  CHECK (user1_uid <> user2_uid)
);

ALTER TABLE bonds ADD COLUMN IF NOT EXISTS initiator_uid TEXT REFERENCES users(uid) ON DELETE SET NULL;
ALTER TABLE bonds ADD COLUMN IF NOT EXISTS match_reason TEXT;
ALTER TABLE bonds DROP CONSTRAINT IF EXISTS bonds_stage_check;
ALTER TABLE bonds ADD CONSTRAINT bonds_stage_check CHECK (stage BETWEEN 0 AND 3);

CREATE INDEX IF NOT EXISTS idx_bonds_user1 ON bonds(user1_uid);
CREATE INDEX IF NOT EXISTS idx_bonds_user2 ON bonds(user2_uid);

CREATE TABLE IF NOT EXISTS bond_confirmations (
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  user_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  stage_target SMALLINT NOT NULL CHECK (stage_target BETWEEN 2 AND 3),
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (bond_id, user_uid, stage_target)
);

CREATE TABLE IF NOT EXISTS bond_history (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  entry TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS festival_invitations (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  festival_id INT NOT NULL REFERENCES festivals(id) ON DELETE CASCADE,
  host_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  guest_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  sender_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_bond_created ON messages(bond_id, created_at DESC);

CREATE TABLE IF NOT EXISTS reports_blocks (
  reporter_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  target_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  reason TEXT,
  is_block BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (reporter_uid, target_uid)
);

-- Seed core Nepali cultural festivals
INSERT INTO festivals (name, community, region, event_date, etiquette_notes, description) VALUES
  ('Udhauli', 'Rai / Limbu', 'Hill region', '15 Dec', 'Remove shoes before entering sacred spaces; join Sakela circle respectfully.', 'Kirat festival marking the migration of birds and harvest thanksgiving.'),
  ('Yomari Punhi', 'Newar', 'Valley', '26 Dec', 'Accept yomari with both hands; ask before photographing home shrines.', 'Post-harvest Newar festival celebrating rice harvest with steamed yomari.'),
  ('Tamu Lhosar', 'Gurung', 'Hill region', '30 Dec', 'Greet elders with Tashi Delek / Phyafulla.', 'Gurung New Year celebrated with traditional dress, dances, and feasting.'),
  ('Maghe Sankranti', 'Tharu / Magar', 'Terai & Hills', '15 Jan', 'Share til ko laddu and yam with hosts.', 'Mid-winter festival celebrating the end of the winter solstice.')
ON CONFLICT (name) DO NOTHING;

-- Seed demo partner accounts from the design report & mockup
INSERT INTO users (uid, display_name, email, community, region, age, college, interests) VALUES
  ('demo_sunita', 'Sunita', 'sunita.rai@mitjyu.np', 'Rai', 'Hill region', 21, 'Patan Multiple Campus', ARRAY['Photography', 'Folk Dance']),
  ('demo_prakash', 'Prakash', 'prakash.newar@mitjyu.np', 'Newar', 'Valley', 22, 'PCPS College', ARRAY['Cooking', 'Heritage Walks'])
ON CONFLICT (uid) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  community = EXCLUDED.community,
  region = EXCLUDED.region;
