CREATE SCHEMA IF NOT EXISTS "ref";

------------
-- SEQUENCES
------------

-- sequence for all security ids
CREATE SEQUENCE IF NOT EXISTS ref.security_id_seq;

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS ref.exchange
(
    id   INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_exchange__name
ON ref.exchange(name);


CREATE TABLE IF NOT EXISTS ref.tenor
(
    id   INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(50) NOT NULL,

    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_tenor__name
ON ref.tenor(name);


CREATE TABLE IF NOT EXISTS ref.currency
(
    id   INTEGER PRIMARY KEY DEFAULT nextval('ref.security_id_seq'),
    name VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_currency__name
ON ref.currency(name);

CREATE TABLE IF NOT EXISTS ref.security_fx_detail
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    trading_status   VARCHAR(50) NOT NULL DEFAULT 'TRADING',
    sub_type         VARCHAR(50),
    
    tenor_1_id          INTEGER REFERENCES ref.tenor(id),
    tenor_2_id          INTEGER REFERENCES ref.tenor(id),
    allow_short_sell    BOOLEAN DEFAULT false,
    allow_margin        BOOLEAN DEFAULT false,
    margin_currency_id  INTEGER REFERENCES ref.currency(id),

    max_lot_size       REAL,
    min_notional       REAL,
    price_precision    REAL,
    quantity_precision REAL,

    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);


CREATE TABLE IF NOT EXISTS ref.security_fx
(
    id                INTEGER PRIMARY KEY DEFAULT nextval('ref.security_id_seq'),
    base_currency_id  INTEGER NOT NULL REFERENCES ref.currency(id),
    quote_currency_id INTEGER NOT NULL REFERENCES ref.currency(id),
    exchange_id       INTEGER NOT NULL REFERENCES ref.exchange(id),
    type              VARCHAR(50) NOT NULL DEFAULT 'SPOT',
    detail_id         INTEGER NOT NULL REFERENCES ref.security_fx_detail(id),

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_security_fx__base_ccy_id__quote_ccy_id__exchange_id__type
ON ref.security_fx(base_currency_id, quote_currency_id, exchange_id, type);


CREATE TABLE IF NOT EXISTS ref.security_equity
(
    id         INTEGER PRIMARY KEY DEFAULT nextval('ref.security_id_seq'),
    name       VARCHAR(100) NOT NULL,
    type       VARCHAR(50) NOT NULL DEFAULT 'STOCK',

    enabled    BOOLEAN NOT NULL DEFAULT true,
    version    INT NOT NULL DEFAULT 0,
    changed_at TIMESTAMPTZ  DEFAULT current_timestamp,
    changed_by VARCHAR(50)  DEFAULT 'SYSTEM'
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_security_equity__name__type
ON ref.security_equity(name, type);

-- table which aggregates all kinds of security definitions

CREATE TABLE IF NOT EXISTS ref.security 
(
    id            INTEGER PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    security_type VARCHAR(50) NOT NULL,
    type          VARCHAR(50) NOT NULL DEFAULT 'STOCK'
);

--------
-- VIEWS
--------

--------------------------
-- TRIGGERS With FUNCTIONS
--------------------------

-- set security_fx.enabled = false
-- when security_fx.enabled = false referred by security_fx.base_currency_id or security_fx.quote_currency_id
CREATE OR REPLACE FUNCTION ref.update_security_fx_enabled_status() -- ON ref.security_fx
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.enabled = FALSE AND OLD.enabled = TRUE THEN
        UPDATE ref.security_fx
        SET enabled = FALSE
        WHERE (base_currency_id = NEW.base_id OR quote_currency_id = NEW.quote_id)
        AND enabled = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER currency_enabled_changed_for_security_fx
AFTER UPDATE OF enabled
ON ref.security_fx
FOR EACH ROW
EXECUTE FUNCTION ref.update_security_fx_enabled_status();

-- when a new security_fx is inserted, insert a new row into the security table
CREATE OR REPLACE FUNCTION ref.insert_security_after_insert_security_fx() -- ON ref.security_fx
RETURNS TRIGGER AS $$
DECLARE
    base_currency VARCHAR(50);
    quote_currency VARCHAR(50);
BEGIN
    SELECT name INTO base_currency FROM ref.currency WHERE id = NEW.base_currency_id;
    SELECT name INTO quote_currency FROM ref.currency WHERE id = NEW.quote_currency_id;

    INSERT INTO ref.security (id, name, security_type, type)
    VALUES (NEW.id, base_currency || '/' || quote_currency, 'FX', NEW.type);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER insert_security_after_insert_security_fx
AFTER INSERT
ON ref.security_fx
FOR EACH ROW
EXECUTE FUNCTION ref.insert_security_after_insert_security_fx();


-- when a new security_fx is inserted, insert a new row into the security table
CREATE OR REPLACE FUNCTION ref.insert_security_after_insert_security_others() -- ON ref.security_equity
RETURNS TRIGGER AS $$
DECLARE
    sec_type VARCHAR(50);
    table_full_name VARCHAR(100);
BEGIN
    SELECT TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME INTO table_full_name;
    CASE table_full_name
        WHEN 'ref.security_equity' THEN
            SELECT 'EQUITY' INTO sec_type;
        WHEN 'ref.currency' THEN
            SELECT 'CURRENCY' INTO sec_type;
        ELSE
            RAISE EXCEPTION 'Unknown table name: %', TG_TABLE_NAME;
    END CASE;
    INSERT INTO ref.security (id, name, security_type, type)
    VALUES (NEW.id, New.name, sec_type, NEW.type);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER insert_security_after_insert_security_others
AFTER INSERT
ON ref.security_equity
FOR EACH ROW
EXECUTE FUNCTION ref.insert_security_after_insert_security_others();
CREATE OR REPLACE TRIGGER insert_security_after_insert_security_others
AFTER INSERT
ON ref.currency
FOR EACH ROW
EXECUTE FUNCTION ref.insert_security_after_insert_security_others();



--------------------
-- PREDEFINED VALUES
--------------------

DELETE FROM ref.tenor;
INSERT INTO ref.tenor (name)
VALUES ('SPOT'),
 ('PERPETUAL'), ('CURRENT_MONTH'), ('NEXT_MONTH'), ('CURRENT_QUARTER'), ('NEXT_QUARTER'),
('1W'), ('2W'), ('1M'), ('2M'), ('3M'), ('6M'), ('9M'), ('1Y');

DELETE FROM ref.currency;
INSERT INTO ref.currency (name, type)
VALUES ('USD', 'REAL'),
('EUR', 'REAL'), ('GBP', 'REAL'), ('JPY', 'REAL'), ('HKD', 'REAL'), ('CNH', 'REAL'),
('SGD', 'REAL'), ('AUD', 'REAL'), ('CAD', 'REAL'), ('NZD', 'REAL'), ('CHF', 'REAL'),
('DKK', 'REAL'), ('PLN', 'REAL'), ('CZK', 'REAL'), ('HUF', 'REAL'), ('MXN', 'REAL'),
('NOK', 'REAL'), ('RUB', 'REAL'), ('SEK', 'REAL'), ('TRY', 'REAL'), ('ZAR', 'REAL'),
('IDR', 'REAL'), ('ILS', 'REAL'), ('MYR', 'REAL'), ('NGN', 'REAL'), ('RON', 'REAL'),
('THB', 'REAL'), ('VND', 'REAL'),
('BTC', 'CRYPTO'), ('ETH', 'CRYPTO'), ('SOL', 'CRYPTO'), ('XRP', 'CRYPTO'),
('DOGE', 'CRYPTO'), ('BNB', 'CRYPTO'), ('ADA', 'CRYPTO'), ('SUI', 'CRYPTO'),
('PEPE', 'CRYPTO'), ('TRX', 'CRYPTO'), ('LTC', 'CRYPTO'),
('USDT', 'CRYPTO_FIAT'), ('USDC', 'CRYPTO_FIAT'), ('FDUSD', 'CRYPTO_FIAT');