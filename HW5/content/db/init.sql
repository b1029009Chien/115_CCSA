-- Initialize names table for HW5 app
CREATE TABLE IF NOT EXISTS names (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
