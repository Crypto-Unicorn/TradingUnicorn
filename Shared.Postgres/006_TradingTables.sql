CREATE SCHEMA IF NOT EXISTS "trading";

---------
-- TABLES
---------

CREATE TABLE IF NOT EXISTS trading.order
(
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_id      INTEGER NOT NULL REFERENCES adm.account(id),
    security_id     INTEGER NOT NULL REFERENCES ref.security(id),
    order_type      VARCHAR(50) NOT NULL, -- MARKET, LIMIT, STOP_LOSS, TAKE_PROFIT, STOP_LOSS_LIMIT, TAKE_PROFIT_LIMIT, LIMIT_MAKER
    time_in_force   VARCHAR(50) NOT NULL, -- GTC, IOC, FOK
    
    side            CHAR(1) NOT NULL, -- B, S
    price           REAL, -- NULL for MARKET order or OCO parent order
    quantity        REAL NOT NULL,
    quote_quantity  REAL, -- optional quantity in quote asset
    actual_price    REAL,
    filled_quantity REAL,
    status          VARCHAR(50) NOT NULL, -- NEW, PARTIALLY_FILLED, FILLED, CANCELED, PENDING_CANCEL, REJECTED, EXPIRED

    external_id     VARCHAR(100),
    detail_id       INTEGER NOT NULL REFERENCES trading.order_detail(id),

    internal_created_at      TIMESTAMPTZ NOT NULL, -- the time when the order is created in the system
    external_created_at      TIMESTAMPTZ NOT NULL, -- the time when the order is acknowledged by the exchange
    changed_at      TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_order__security_id
ON trading.order(security_id);
CREATE INDEX IF NOT EXISTS ix_order__security_id__changed_at
ON trading.order(security_id, changed_at DESC);
CREATE INDEX IF NOT EXISTS ix_order__account_id
ON trading.order(account_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_order__account_id__external_id
ON trading.order(account_id, external_id DESC);
CREATE UNIQUE INDEX IF NOT EXISTS ux_order__account_id__security_id
ON trading.order(account_id, security_id);
CREATE UNIQUE INDEX IF NOT EXISTS ix_order__account_id__external_id__changed_at
ON trading.order(account_id, external_id DESC, changed_at DESC);


CREATE TABLE IF NOT EXISTS trading.order_detail
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    stop_price       REAL,
    trailing_delta   REAL,
    iceberg_quantity REAL,
    strategy_id      INTEGER REFERENCES algo.strategy(id),
    sor_enabled      BOOLEAN NOT NULL DEFAULT false,
    cancel_type      VARCHAR(50), -- ONLY_NEW, ONLY_PARTIALLY_FILLED, ALL, CANCEL_REPLACE
    auto_margin_effect VARCHAR(50), -- NO_SIDE_EFFECT, MARGIN_BUY, AUTO_REPAY, AUTO_BORROW_REPAY
    self_trade_prevention VARCHAR(50), -- EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH
    parent_order_id   INTEGER REFERENCES trading.order(id) -- NULL for parent order
    parent_order_type VARCHAR(50) -- NULL for child order; OCO, OTO, OTOCO
);


CREATE TABLE IF NOT EXISTS trading.trade
(
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_id        INTEGER NOT NULL REFERENCES trading.order(id),
    price           REAL NOT NULL,
    quantity        REAL NOT NULL,

    external_id     VARCHAR(100),
    fee_detail_id   INTEGER REFERENCES trading.fee_detail(id),
    at              TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_trade__order_id
ON trading.trade(order_id DESC);


CREATE TABLE IF NOT EXISTS trading.fee_detail
(
    id               INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    fee_quantity     REAL,
    fee_asset_id     INTEGER REFERENCES ref.asset(id),
    maker_commission REAL,
    taker_commission REAL,
    maker_tax        REAL,
    taker_tax        REAL,
    discount_enabled_for_account  BOOLEAN,
    discount_enabled_for_security BOOLEAN,
    discount_asset_id INTEGER REFERENCES ref.asset(id),
    discount_rate     REAL,
);


CREATE TABLE IF NOT EXISTS trading.position
(
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_id      INTEGER NOT NULL REFERENCES adm.account(id),
    asset_id        INTEGER NOT NULL REFERENCES ref.asset(id),
    quantity        REAL NOT NULL,
    locked_quantity REAL NOT NULL,

    changed_at      TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_position__account_id__asset_id
ON trading.position(account_id, asset_id);


CREATE TABLE IF NOT EXISTS trading.loan_transaction
(
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    account_id      INTEGER NOT NULL REFERENCES adm.account(id),
    asset_id        INTEGER NOT NULL REFERENCES ref.asset(id),
    quantity        REAL NOT NULL,
    interest        REAL NOT NULL,
    principal       REAL NOT NULL,
    status          VARCHAR(50) NOT NULL,
    at              TIMESTAMPTZ   DEFAULT current_timestamp
);
CREATE UNIQUE INDEX IF NOT EXISTS ix_loan_transaction__account_id__asset_id
ON trading.position(account_id, asset_id);