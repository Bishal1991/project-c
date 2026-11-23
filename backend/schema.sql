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
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
  stage SMALLINT NOT NULL DEFAULT 1 CHECK (stage BETWEEN 1 AND 3),
  festivals_shared INT NOT NULL DEFAULT 0,
  message_count INT NOT NULL DEFAULT 0,
  upcoming_festival_id INT REFERENCES festivals(id) ON DELETE SET NULL,
  upcoming_event_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (user1_uid <> user2_uid)
);

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

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  bond_id TEXT NOT NULL REFERENCES bonds(id) ON DELETE CASCADE,
  sender_uid TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_bond_created ON messages(bond_id, created_at DESC);

-- Seed core Nepali cultural festivals
INSERT INTO festivals (name, community, region, event_date, etiquette_notes, description) VALUES
  ('Udhauli', 'Rai / Limbu', 'Hill region', '15 Dec', 'Remove shoes before entering sacred spaces; join Sakela circle respectfully.', 'Kirat festival marking the migration of birds and harvest thanksgiving.'),
  ('Yomari Punhi', 'Newar', 'Valley', '26 Dec', 'Accept yomari with both hands; ask before photographing home shrines.', 'Post-harvest Newar festival celebrating rice harvest with steamed yomari.'),
  ('Tamu Lhosar', 'Gurung', 'Hill region', '30 Dec', 'Greet elders with Tashi Delek / Phyafulla.', 'Gurung New Year celebrated with traditional dress, dances, and feasting.'),
  ('Maghe Sankranti', 'Tharu / Magar', 'Terai & Hills', '15 Jan', 'Share til ko laddu and yam with hosts.', 'Mid-winter festival celebrating the end of the winter solstice.')
ON CONFLICT (name) DO NOTHING;
