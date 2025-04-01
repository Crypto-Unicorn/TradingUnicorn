CREATE SCHEMA IF NOT EXISTS "md";

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS md.candlestick_fx_1m
(
    security_fx_id INTEGER NOT NULL REFERENCES ref.security_fx(id),
    open           REAL NOT NULL,
    high           REAL NOT NULL,
    low            REAL NOT NULL,
    close          REAL NOT NULL,
    volume         REAL NOT NULL,
    type           CHAR(1),
    at             TIMESTAMPTZ NOT NULL,

    trade_count    INTEGER, -- count of trades within the candlestick
    taker_base_volume  REAL, -- sum of base asset bid volume of trades on taker side within the candlestick
    taker_quote_volume REAL -- sum of quote asset bid volume of trades on taker side within the candlestick
);
CREATE INDEX IF NOT EXISTS ix_candlestick_fx_1m__security_fx_id
ON md.candlestick_fx_1m(security_fx_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_candlestick_fx_1m__security_fx_id__at
ON md.candlestick_fx_1m(security_fx_id, at DESC);


CREATE TABLE IF NOT EXISTS md.candlestick_fx_1h
(
    security_fx_id INTEGER NOT NULL REFERENCES ref.security_fx(id),
    open           REAL NOT NULL,
    high           REAL NOT NULL,
    low            REAL NOT NULL,
    close          REAL NOT NULL,
    volume         REAL NOT NULL,
    type           CHAR(1),
    at             TIMESTAMPTZ NOT NULL,

    trade_count    INTEGER,
    taker_base_volume  REAL,
    taker_quote_volume REAL
);
CREATE INDEX IF NOT EXISTS ix_candlestick_fx_1h__security_fx_id
ON md.candlestick_fx_1h(security_fx_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_candlestick_fx_1h__security_fx_id__at
ON md.candlestick_fx_1h(security_fx_id, at DESC);


CREATE TABLE IF NOT EXISTS md.candlestick_fx_1d
(
    security_fx_id INTEGER NOT NULL REFERENCES ref.security_fx(id),
    open           REAL NOT NULL,
    high           REAL NOT NULL,
    low            REAL NOT NULL,
    close          REAL NOT NULL,
    volume         REAL NOT NULL,
    type           CHAR(1),
    at             TIMESTAMPTZ NOT NULL,

    trade_count    INTEGER,
    taker_base_volume  REAL,
    taker_quote_volume REAL
);
CREATE INDEX IF NOT EXISTS ix_candlestick_fx_1d__security_fx_id
ON md.candlestick_fx_1d(security_fx_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_candlestick_fx_1d__security_fx_id__at
ON md.candlestick_fx_1d(security_fx_id, at DESC);


CREATE TABLE IF NOT EXISTS md.order_book_fx
(
    security_fx_id INTEGER NOT NULL REFERENCES ref.security_fx(id),
    price          REAL NOT NULL,
    size           REAL NOT NULL,
    depth          INTEGER NOT NULL,
    side           CHAR(1) NOT NULL,
    type           CHAR(1),
    at             TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_order_book_fx__security_fx_id
ON md.order_book_fx(security_fx_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_order_book_fx__security_fx_id__depth__side__at
ON md.order_book_fx(security_fx_id, depth, side, at DESC);


CREATE TABLE IF NOT EXISTS md.funding_rate_fx
(
    security_fx_id INTEGER NOT NULL REFERENCES ref.security_fx(id),
    funding_rate   REAL NOT NULL,
    at             TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_funding_rate_fx__security_fx_id
ON md.funding_rate_fx(security_fx_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_funding_rate_fx__security_fx__at
ON md.funding_rate_fx(security_fx_id, at DESC);

---------------------
-- TIMESCALEDB TABLES
---------------------

SELECT create_hypertable('md.candlestick_fx_1m', 'at', if_not_exists => TRUE);
SELECT create_hypertable('md.candlestick_fx_1h', 'at', if_not_exists => TRUE);
SELECT create_hypertable('md.candlestick_fx_1d', 'at', if_not_exists => TRUE);
SELECT create_hypertable('md.order_book_fx', 'at', if_not_exists => TRUE);

