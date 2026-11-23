import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import pg from 'pg';

const app = express();
app.use(cors());
app.use(express.json());

const pool = new pg.Pool({
  connectionString:
    process.env.DATABASE_URL ||
    'postgres://postgres@127.0.0.1:5432/newzen_mitjyu',
});

const STAGE_NAMES = ['Pending', 'Chinari', 'Saathi', 'Mit'];

function makeBondId(uid1, uid2) {
  return uid1 < uid2 ? `${uid1}_${uid2}` : `${uid2}_${uid1}`;
}

function orderedPair(uid1, uid2) {
  return uid1 < uid2 ? [uid1, uid2] : [uid2, uid1];
}

// Auto-seed Sunita & Prakash demo bonds for a real user if they have 0 bonds
async function ensureDemoBondsForUser(client, uid) {
  if (uid === 'demo_sunita' || uid === 'demo_prakash') return;
  const { rows } = await client.query(
    `SELECT COUNT(*)::int AS cnt FROM bonds WHERE user1_uid = $1 OR user2_uid = $1`,
    [uid]
  );
  if (rows[0].cnt > 0) return;

  const { rows: festRows } = await client.query(
    `SELECT id FROM festivals WHERE name = 'Udhauli' LIMIT 1`
  );
  const udhauliId = festRows[0]?.id ?? null;

  // 1. Sunita (Stage 2 Saathi · 9 days · 1 festival shared · 32 messages · Udhauli 15 Dec)
  const [s1, s2] = orderedPair(uid, 'demo_sunita');
  const sunitaBondId = makeBondId(uid, 'demo_sunita');
  await client.query(
    `INSERT INTO bonds (
       id, user1_uid, user2_uid, initiator_uid, stage, match_reason,
       festivals_shared, message_count, upcoming_festival_id, upcoming_event_note, created_at
     ) VALUES (
       $1, $2, $3, $4, 2, 'Different community (Rai) · Both into Photography',
       1, 32, $5, 'You will both confirm you met afterwards to reach Mit.',
       NOW() - INTERVAL '9 days'
     ) ON CONFLICT (id) DO NOTHING`,
    [sunitaBondId, s1, s2, uid, udhauliId]
  );
  await client.query(
    `INSERT INTO bond_history (bond_id, entry, created_at) VALUES
       ($1, 'Bonded at Chinari', NOW() - INTERVAL '9 days'),
       ($1, 'Reached Saathi after Udhauli prep', NOW() - INTERVAL '3 days')`,
    [sunitaBondId]
  );
  await client.query(
    `INSERT INTO messages (bond_id, sender_uid, text, created_at) VALUES
       ($1, 'demo_sunita', 'Namaste! Excited to invite you to Udhauli on 15 Dec.', NOW() - INTERVAL '2 hours'),
       ($1, $2, 'Namaste Sunita! Looking forward to joining the preparations.', NOW() - INTERVAL '1 hour')`,
    [sunitaBondId, uid]
  );

  // 2. Prakash (Stage 1 Chinari · 2 days · 0 festivals shared · 6 messages)
  const [p1, p2] = orderedPair(uid, 'demo_prakash');
  const prakashBondId = makeBondId(uid, 'demo_prakash');
  await client.query(
    `INSERT INTO bonds (
       id, user1_uid, user2_uid, initiator_uid, stage, match_reason,
       festivals_shared, message_count, created_at
     ) VALUES (
       $1, $2, $3, 'demo_prakash', 1, 'Different community (Newar) · Valley heritage',
       0, 6, NOW() - INTERVAL '2 days'
     ) ON CONFLICT (id) DO NOTHING`,
    [prakashBondId, p1, p2]
  );
  await client.query(
    `INSERT INTO bond_history (bond_id, entry, created_at) VALUES
       ($1, 'Bonded at Chinari', NOW() - INTERVAL '2 days')`,
    [prakashBondId]
  );
  await client.query(
    `INSERT INTO messages (bond_id, sender_uid, text, created_at) VALUES
       ($1, 'demo_prakash', 'Jojolapa! Have you ever tried making Yomari?', NOW() - INTERVAL '1 day')`,
    [prakashBondId]
  );
}

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true, db: 'postgresql' });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Upsert user profile (called after Firebase Auth sign-in)
// ponytail: trusts uid in path for local dev; verify Firebase ID token via firebase-admin before deploying
app.put('/users/:uid', async (req, res) => {
  const { uid } = req.params;
  const {
    displayName,
    email,
    phoneNumber,
    photoUrl,
    community,
    region,
    age,
    college,
    interests,
    matchMode,
  } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `INSERT INTO users (
         uid, display_name, email, phone_number, photo_url,
         community, region, age, college, interests, match_mode
       )
       VALUES (
         $1, COALESCE(NULLIF($2, ''), 'User'), LOWER(NULLIF($3, '')), $4, $5,
         $6, $7, $8, $9, COALESCE($10, '{}'::text[]), COALESCE($11, 'different')
       )
       ON CONFLICT (uid) DO UPDATE SET
         display_name = COALESCE(NULLIF(EXCLUDED.display_name, ''), users.display_name),
         email = COALESCE(EXCLUDED.email, users.email),
         phone_number = COALESCE(EXCLUDED.phone_number, users.phone_number),
         photo_url = COALESCE(EXCLUDED.photo_url, users.photo_url),
         community = COALESCE(EXCLUDED.community, users.community),
         region = COALESCE(EXCLUDED.region, users.region),
         age = COALESCE(EXCLUDED.age, users.age),
         college = COALESCE(EXCLUDED.college, users.college),
         interests = CASE WHEN $10::text[] IS NOT NULL THEN EXCLUDED.interests ELSE users.interests END,
         match_mode = COALESCE($11, users.match_mode),
         updated_at = NOW()
       RETURNING *`,
      [
        uid,
        displayName,
        email,
        phoneNumber,
        photoUrl,
        community,
        region,
        age,
        college,
        interests ?? null,
        matchMode ?? null,
      ]
    );
    await ensureDemoBondsForUser(client, uid);
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// List active bonds (stage >= 1) for a user
app.get('/users/:uid/bonds', async (req, res) => {
  const { uid } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT
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
            FROM bond_history h WHERE h.bond_id = b.id),
           '[]'::json
         ) AS history,
         COALESCE(
           (SELECT json_agg(c.user_uid)
            FROM bond_confirmations c
            WHERE c.bond_id = b.id AND c.stage_target = b.stage + 1),
           '[]'::json
         ) AS stage_confirmations
       FROM bonds b
       JOIN users u ON u.uid = CASE WHEN b.user1_uid = $1 THEN b.user2_uid ELSE b.user1_uid END
       LEFT JOIN festivals f ON f.id = b.upcoming_festival_id
       WHERE (b.user1_uid = $1 OR b.user2_uid = $1)
         AND b.stage >= 1
       ORDER BY b.stage DESC, b.created_at ASC`,
      [uid]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Search only among bonded users (stage >= 1) for Chat searchbar
app.get('/users/:uid/bonds/search', async (req, res) => {
  const { uid } = req.params;
  const q = String(req.query.q || '').trim();
  if (!q) return res.json([]);
  const pattern = `%${q}%`;
  try {
    const { rows } = await pool.query(
      `SELECT
         u.uid,
         u.display_name AS "displayName",
         u.email,
         u.phone_number AS "phoneNumber",
         u.photo_url AS "photoUrl",
         u.community,
         u.region
       FROM bonds b
       JOIN users u ON u.uid = CASE WHEN b.user1_uid = $1 THEN b.user2_uid ELSE b.user1_uid END
       WHERE (b.user1_uid = $1 OR b.user2_uid = $1)
         AND b.stage >= 1
         AND (
           u.display_name ILIKE $2
           OR COALESCE(u.email, '') ILIKE $2
           OR COALESCE(u.phone_number, '') ILIKE $2
           OR COALESCE(u.community, '') ILIKE $2
         )
       LIMIT 30`,
      [uid, pattern]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Send Namaste (creates stage=0 pending bond, or stage=1 if immediate)
app.post('/bonds', async (req, res) => {
  const { user1Uid, user2Uid, initiatorUid, stage = 0, matchReason, upcomingFestivalId, upcomingEventNote } = req.body;
  if (!user1Uid || !user2Uid || user1Uid === user2Uid) {
    return res.status(400).json({ error: 'Two distinct user UIDs are required' });
  }
  const [u1, u2] = orderedPair(user1Uid, user2Uid);
  const bondId = makeBondId(u1, u2);
  try {
    const { rows } = await pool.query(
      `INSERT INTO bonds (id, user1_uid, user2_uid, initiator_uid, stage, match_reason, upcoming_festival_id, upcoming_event_note)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (id) DO NOTHING
       RETURNING *`,
      [bondId, u1, u2, initiatorUid ?? user1Uid, stage, matchReason ?? null, upcomingFestivalId ?? null, upcomingEventNote ?? null]
    );
    if (rows.length > 0 && stage >= 1) {
      await pool.query(
        `INSERT INTO bond_history (bond_id, entry) VALUES ($1, 'Bonded at Chinari')`,
        [bondId]
      );
    }
    res.status(201).json({ bondId, created: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Accept pending Namaste (stage 0 -> 1 Chinari)
app.post('/bonds/:bondId/accept', async (req, res) => {
  const { bondId } = req.params;
  try {
    const { rows } = await pool.query(
      `UPDATE bonds SET stage = 1 WHERE id = $1 AND stage = 0 RETURNING *`,
      [bondId]
    );
    if (rows.length > 0) {
      await pool.query(
        `INSERT INTO bond_history (bond_id, entry) VALUES ($1, 'Bonded at Chinari')`,
        [bondId]
      );
    }
    res.json({ bondId, accepted: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Two-way confirmation to advance Chinari (1) -> Saathi (2) -> Mit (3)
app.post('/bonds/:bondId/confirm', async (req, res) => {
  const { bondId } = req.params;
  const { userUid } = req.body;
  if (!userUid) return res.status(400).json({ error: 'userUid is required' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `SELECT * FROM bonds WHERE id = $1 FOR UPDATE`,
      [bondId]
    );
    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Bond not found' });
    }
    const bond = rows[0];
    if (bond.user1_uid !== userUid && bond.user2_uid !== userUid) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Not a participant of this bond' });
    }
    if (bond.stage >= 3 || bond.stage < 1) {
      await client.query('ROLLBACK');
      return res.json({ stage: bond.stage, advanced: false });
    }

    const target = bond.stage + 1;
    await client.query(
      `INSERT INTO bond_confirmations (bond_id, user_uid, stage_target)
       VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
      [bondId, userUid, target]
    );

    const { rows: confs } = await client.query(
      `SELECT user_uid FROM bond_confirmations WHERE bond_id = $1 AND stage_target = $2`,
      [bondId, target]
    );

    let advanced = false;
    if (confs.length >= 2) {
      await client.query(
        `UPDATE bonds SET stage = $1, festivals_shared = festivals_shared + 1 WHERE id = $2`,
        [target, bondId]
      );
      await client.query(
        `INSERT INTO bond_history (bond_id, entry) VALUES ($1, $2)`,
        [bondId, `Reached ${STAGE_NAMES[target]}`]
      );
      advanced = true;
    }

    await client.query('COMMIT');
    res.json({ stage: advanced ? target : bond.stage, advanced });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// List active chat conversations for a user (backed by active bonds)
app.get('/users/:uid/chats', async (req, res) => {
  const { uid } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT
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
       FROM bonds b
       JOIN users u ON u.uid = CASE WHEN b.user1_uid = $1 THEN b.user2_uid ELSE b.user1_uid END
       LEFT JOIN LATERAL (
         SELECT text, sender_uid, created_at
         FROM messages
         WHERE bond_id = b.id
         ORDER BY created_at DESC
         LIMIT 1
       ) m ON TRUE
       WHERE (b.user1_uid = $1 OR b.user2_uid = $1)
         AND b.stage >= 1
       ORDER BY COALESCE(m.created_at, b.created_at) DESC`,
      [uid]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Messages for a bond
app.get('/bonds/:bondId/messages', async (req, res) => {
  const { bondId } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT
         m.id,
         m.bond_id AS "bondId",
         m.sender_uid AS "senderId",
         u.display_name AS "senderName",
         m.text,
         m.created_at AS "timestamp"
       FROM messages m
       JOIN users u ON u.uid = m.sender_uid
       WHERE m.bond_id = $1
       ORDER BY m.created_at DESC
       LIMIT 100`,
      [bondId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/bonds/:bondId/messages', async (req, res) => {
  const { bondId } = req.params;
  const { senderUid, text } = req.body;
  if (!senderUid || !text?.trim()) {
    return res.status(400).json({ error: 'senderUid and non-empty text required' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      `INSERT INTO messages (bond_id, sender_uid, text) VALUES ($1, $2, $3) RETURNING *`,
      [bondId, senderUid, text.trim()]
    );
    await client.query(
      `UPDATE bonds SET message_count = message_count + 1 WHERE id = $1`,
      [bondId]
    );
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

app.get('/festivals', async (_req, res) => {
  try {
    const { rows } = await pool.query(`SELECT * FROM festivals ORDER BY id ASC`);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const port = Number(process.env.PORT || 3000);
app.listen(port, '0.0.0.0', () => {
  console.log(`NewZen Mitjyu API listening on http://localhost:${port}`);
});
