CREATE SCHEMA IF NOT EXISTS "ref";

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS ref.asset
(
    id   INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_asset__name
ON ref.asset(name);


CREATE TABLE IF NOT EXISTS ref.exchange
(
    id   INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_exchange__name
ON ref.exchange(name);


CREATE TABLE IF NOT EXISTS ref.tenor
(
    id   INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,

	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_tenor__name
ON ref.tenor(name);


CREATE TABLE IF NOT EXISTS ref.asset_pair
(
    id         INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	base_id    INTEGER NOT NULL REFERENCES ref.asset(id),
	quote_id   INTEGER NOT NULL REFERENCES ref.asset(id),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_asset_pair__base_id__quote_id
ON ref.asset_pair(base_id, quote_id);


CREATE TABLE IF NOT EXISTS ref.security_fx_detail
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    trading_status   VARCHAR(50) NOT NULL DEFAULT 'TRADING',
    sub_type         VARCHAR(50),
    
    tenor_1_id       INTEGER REFERENCES ref.tenor(id),
    tenor_2_id       INTEGER REFERENCES ref.tenor(id),
    allow_short_sell BOOLEAN DEFAULT false,
    allow_margin     BOOLEAN DEFAULT false,
    margin_asset_id  INTEGER REFERENCES ref.asset(id),

    max_lot_size       REAL,
    min_notional       REAL,
    price_precision    REAL,
    quantity_precision REAL,

	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);


CREATE TABLE IF NOT EXISTS ref.security_fx
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	asset_pair_id    INTEGER NOT NULL REFERENCES ref.asset_pair(id),
	exchange_id      INTEGER NOT NULL REFERENCES ref.exchange(id),
    type             VARCHAR(50) NOT NULL DEFAULT 'SPOT',
	detail_id        INTEGER NOT NULL REFERENCES ref.security_fx_detail(id),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
	changed_at TIMESTAMPTZ   DEFAULT current_timestamp,
	changed_by VARCHAR(50) DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_security_fx__asset_pair_id__exchange_id__type
ON ref.security_fx(asset_pair_id, exchange_id, type);


-- table which aggregates all kinds of security definitions
CREATE TABLE IF NOT EXISTS ref.security
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	security_fx_id   INTEGER REFERENCES ref.security_fx(id)
);

--------------------
-- PREDEFINED VALUES
--------------------

INSERT INTO ref.tenor (name)
VALUES ('SPOT'),
 ('PERPETUAL'), ('CURRENT_MONTH'), ('NEXT_MONTH'), ('CURRENT_QUARTER'), ('NEXT_QUARTER'),
('1W'), ('2W'), ('1M'), ('2M'), ('3M'), ('6M'), ('9M'), ('1Y');

--------
-- VIEWS
--------

CREATE MATERIALIZED VIEW IF NOT EXISTS ref.v_security_fx AS
SELECT
	cp."id" AS "id",
	CONCAT(bc.name, qc.name) AS "name",
	bc.name AS "base_ccy",
	qc.name AS "quote_ccy",
	fx.type,
	e.name AS exchange,
	(bc.type = 'REAL' OR qc.type= 'REAL') AS has_real_ccy,
	base_id, quote_id, asset_pair_id, fx.id AS security_id, exchange_id,
	(bc.enabled AND qc.enabled AND cp.enabled AND fx.enabled AND e.enabled) AS enabled
FROM ref.asset_pair cp
JOIN ref.asset bc ON cp.base_id = bc.id
JOIN ref.asset qc ON cp.quote_id = qc.id
JOIN ref.security_fx fx ON cp.id = fx.asset_pair_id
JOIN ref.exchange e ON fx.exchange_id = e.id;
CREATE UNIQUE INDEX IF NOT EXISTS ux_id
ON ref.v_security_fx(id);


--------------------------
-- TRIGGERS With FUNCTIONS
--------------------------

-- set asset_pair.enabled = false
-- when asset.enabled = false referred by either asset_pair.base_id or asset_pair.quote_id
CREATE OR REPLACE FUNCTION ref.update_asset_pair_enabled_status() -- ON ref.asset
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.enabled = FALSE AND OLD.enabled = TRUE THEN
        UPDATE ref.asset_pair
        SET enabled = FALSE
        WHERE (base_id = NEW.id OR quote_id = NEW.id)
        AND enabled = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER asset_enabled_changed
AFTER UPDATE OF enabled
ON ref.asset
FOR EACH ROW
EXECUTE FUNCTION ref.update_asset_pair_enabled_status();

-- set security_fx.enabled = false
-- when asset_pair.enabled = false referred by security_fx.asset_pair_id
CREATE OR REPLACE FUNCTION ref.update_security_fx_enabled_status() -- ON ref.asset_pair
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.enabled = FALSE AND OLD.enabled = TRUE THEN
        UPDATE ref.security_fx
        SET enabled = FALSE
        WHERE asset_pair_id = NEW.id
        AND enabled = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER asset_pair_enabled_changed
AFTER UPDATE OF enabled
ON ref.asset_pair
FOR EACH ROW
EXECUTE FUNCTION ref.update_security_fx_enabled_status();

-- refresh v_security_fx
-- automatically
CREATE OR REPLACE FUNCTION ref.refresh_v_security_fx_event()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY ref.v_security_fx;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER refresh_v_security_fx_event
AFTER INSERT OR UPDATE OR DELETE
ON ref.security_fx
FOR EACH STATEMENT
EXECUTE FUNCTION ref.refresh_v_security_fx_event();