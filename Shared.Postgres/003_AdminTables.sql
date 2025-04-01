CREATE SCHEMA IF NOT EXISTS "adm";

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS adm.account
(
    id          INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name        VARCHAR(50) NOT NULL,
    type        VARCHAR(50) NOT NULL, -- INTERNAL, EXTERNAL
    exchange_id INTEGER REFERENCES ref.exchange(id), -- NULL for INTERNAL
    external_id VARCHAR(500),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_account__name_type
ON adm.account(name, type);


CREATE TABLE IF NOT EXISTS adm.secret
(
    id         INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    key_group  VARCHAR(255),
    key        VARCHAR(255) NOT NULL,
    account_id INTEGER NOT NULL REFERENCES adm.account(id),
    secret     VARCHAR(1000),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_secret__key_group__key
ON adm.secret(key_group, key);


CREATE TABLE IF NOT EXISTS adm.account_logon_trace
(
    id         INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_id INTEGER NOT NULL REFERENCES adm.account(id),
    logon_at   TIMESTAMPTZ DEFAULT current_timestamp,
    logon_ip   VARCHAR(50),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);


CREATE TABLE IF NOT EXISTS adm.preference
(
    id         INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    key        VARCHAR(255) NOT NULL,
    value      VARCHAR(2000),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);


--------
-- VIEWS
--------

CREATE OR REPLACE VIEW adm.v_table AS
SELECT
	CONCAT(table_schema, '.', table_name) AS "table",
    table_type AS type,
    table_catalog AS catalog
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
    AND table_schema NOT LIKE ('%timescaledb%')
ORDER BY "table";