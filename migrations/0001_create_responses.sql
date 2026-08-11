CREATE TABLE IF NOT EXISTS responses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,

  age_group TEXT,
  gender TEXT,
  grade TEXT,

  q1 TEXT,
  q2 TEXT,
  q3 TEXT,
  q4 TEXT,
  q5 TEXT,

  user_agent TEXT,
  ip_hash TEXT
);
