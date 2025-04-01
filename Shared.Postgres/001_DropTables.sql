-- md schema
DROP TABLE IF EXISTS md.funding_rate_fx;
DROP TABLE IF EXISTS md.candlestick_fx_1m;
DROP TABLE IF EXISTS md.candlestick_fx_1h;
DROP TABLE IF EXISTS md.candlestick_fx_1d;
DROP TABLE IF EXISTS md.order_book_fx;

-- admin schema
DROP VIEW IF EXISTS admin.v_table;
DROP TABLE IF EXISTS adm.preference;
DROP TABLE IF EXISTS adm.secret;
DROP TABLE IF EXISTS adm.account_logon_trace;
DROP TABLE IF EXISTS adm.account;

-- ref schema
DROP TRIGGER IF EXISTS asset_enabled_changed ON ref.asset;
DROP TRIGGER IF EXISTS asset_pair_enabled_changed ON ref.asset_pair;
DROP TRIGGER IF EXISTS refresh_v_security_fx_event ON ref.security_fx;
DROP FUNCTION IF EXISTS ref.update_asset_pair_enabled_status;
DROP FUNCTION IF EXISTS ref.update_security_fx_enabled_status;
DROP FUNCTION IF EXISTS ref.refresh_v_security_fx_event;

DROP MATERIALIZED VIEW IF EXISTS ref.v_asset_pair;
DROP MATERIALIZED VIEW IF EXISTS ref.v_security_fx;
DROP TABLE IF EXISTS ref.security;
DROP TABLE IF EXISTS ref.security_fx_detail;
DROP TABLE IF EXISTS ref.security_fx;
DROP TABLE IF EXISTS ref.asset_pair;
DROP TABLE IF EXISTS ref.tenor;
DROP TABLE IF EXISTS ref.exchange;
DROP TABLE IF EXISTS ref.asset;
