CREATE SCHEMA IF NOT EXISTS "algo";

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS algo.strategy
(
    id          INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name        VARCHAR(50) NOT NULL,
    description VARCHAR(2000),
    
    enabled     BOOLEAN NOT NULL DEFAULT true,
    version     INT NOT NULL DEFAULT 0,
    changed_at  TIMESTAMPTZ   DEFAULT current_timestamp,
    changed_by  VARCHAR(50) DEFAULT 'SYSTEM'
);
