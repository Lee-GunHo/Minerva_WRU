PRAGMA foreign_keys = ON;

-- contacts / phones ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS contacts (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  display_name  TEXT NOT NULL,
  is_self       INTEGER NOT NULL DEFAULT 0 CHECK (is_self IN (0,1))
);

CREATE TABLE IF NOT EXISTS contact_phones (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  contact_id  INTEGER NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  e164        TEXT NOT NULL,
  label       TEXT,
  UNIQUE (contact_id, e164)
);
CREATE INDEX IF NOT EXISTS idx_contact_phones_contact ON contact_phones(contact_id);
CREATE INDEX IF NOT EXISTS idx_contact_phones_e164    ON contact_phones(e164);

-- numbers (번호 레지스트리) -------------------------------------------------
CREATE TABLE IF NOT EXISTS numbers (
  e164           TEXT PRIMARY KEY,
  contact_id     INTEGER REFERENCES contacts(id) ON DELETE SET NULL,
  is_contact     INTEGER NOT NULL DEFAULT 0 CHECK (is_contact IN (0,1)),
  display_hint   TEXT,
  spam_score     REAL,
  first_seen_at  INTEGER NOT NULL,
  last_seen_at   INTEGER NOT NULL,
  last_source    TEXT CHECK (last_source IN ('call','sms','blocklist','manual')),
  call_in_cnt    INTEGER NOT NULL DEFAULT 0,
  call_out_cnt   INTEGER NOT NULL DEFAULT 0,
  sms_in_cnt     INTEGER NOT NULL DEFAULT 0,
  sms_out_cnt    INTEGER NOT NULL DEFAULT 0,
  last_call_at   INTEGER,
  last_sms_at    INTEGER,
  note           TEXT
);
CREATE INDEX IF NOT EXISTS idx_numbers_last_seen ON numbers(last_seen_at);
CREATE INDEX IF NOT EXISTS idx_numbers_contact   ON numbers(contact_id);

-- conversations / participants ---------------------------------------------
CREATE TABLE IF NOT EXISTS conversations (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  kind  TEXT
);

CREATE TABLE IF NOT EXISTS conversation_participants (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  contact_id      INTEGER REFERENCES contacts(id),
  e164            TEXT,
  is_self         INTEGER NOT NULL DEFAULT 0 CHECK (is_self IN (0,1)),
  CHECK (contact_id IS NOT NULL OR e164 IS NOT NULL),
  UNIQUE (conversation_id, contact_id),
  UNIQUE (conversation_id, e164)
);
CREATE INDEX IF NOT EXISTS idx_participants_conv         ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_participants_conv_is_self ON conversation_participants(conversation_id, is_self);
CREATE INDEX IF NOT EXISTS idx_participants_e164         ON conversation_participants(e164);

-- messages ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS messages (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id       INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_participant_id INTEGER NOT NULL REFERENCES conversation_participants(id) ON DELETE CASCADE,
  body        TEXT,
  msg_type    TEXT NOT NULL CHECK (msg_type IN ('text','mms','system')),
  direction   TEXT NOT NULL CHECK (direction IN ('incoming','outgoing')),
  status      TEXT NOT NULL CHECK (status IN ('sent','delivered','read','failed')),
  sent_at     INTEGER NOT NULL,
  risk_score  REAL
);
CREATE INDEX IF NOT EXISTS idx_messages_conv_time ON messages(conversation_id, sent_at);
CREATE INDEX IF NOT EXISTS idx_messages_sender    ON messages(sender_participant_id);

-- unknown numbers view ------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_unknown_numbers AS
SELECT n.*
FROM numbers n
LEFT JOIN contact_phones cp ON cp.e164 = n.e164
WHERE cp.contact_id IS NULL AND n.is_contact = 0;

-- triggers: 연락처 번호 추가되면 numbers/participants 연결 -------------------
CREATE TRIGGER IF NOT EXISTS trg_numbers_bind_on_phone_ins
AFTER INSERT ON contact_phones
BEGIN
  UPDATE numbers
     SET contact_id = NEW.contact_id, is_contact = 1
   WHERE e164 = NEW.e164;

  UPDATE conversation_participants
     SET contact_id = NEW.contact_id
   WHERE e164 = NEW.e164
     AND contact_id IS NULL;
END;
