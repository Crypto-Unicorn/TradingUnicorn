-- algo schema


-- trading schema
DROP TABLE IF EXISTS trading.order;
DROP TABLE IF EXISTS trading.order_book;
DROP TABLE IF EXISTS trading.order_book_detail;
DROP TABLE IF EXISTS trading.trade;
DROP TABLE IF EXISTS trading.fee_detail;
DROP TABLE IF EXISTS trading.position;
DROP TABLE IF EXISTS trading.loan_transaction;

-- md schema
DROP TABLE IF EXISTS md.funding_rate_fx;
DROP TABLE IF EXISTS md.candlestick_fx_1m;
DROP TABLE IF EXISTS md.candlestick_fx_1h;
DROP TABLE IF EXISTS md.candlestick_fx_1d;
DROP TABLE IF EXISTS md.order_book_fx;

-- admin schema
DROP VIEW IF EXISTS adm.v_table;
DROP TABLE IF EXISTS adm.preference;
DROP TABLE IF EXISTS adm.secret;
DROP TABLE IF EXISTS adm.account_logon_trace;
DROP TABLE IF EXISTS adm.account;

-- ref schema
DROP TRIGGER IF EXISTS insert_security_after_insert_security_fx on ref.security_fx;
DROP TRIGGER IF EXISTS insert_security_after_insert_security_others on ref.security_equity;
DROP TRIGGER IF EXISTS insert_security_after_insert_security_others on ref.currency;
DROP TRIGGER IF EXISTS currency_enabled_changed_for_security_fx ON ref.security_fx;

DROP FUNCTION IF EXISTS ref.insert_security_after_insert_security_fx;
DROP FUNCTION IF EXISTS ref.insert_security_after_insert_security_others;
DROP FUNCTION IF EXISTS ref.update_security_fx_enabled_status;

DROP TABLE IF EXISTS ref.security;
DROP TABLE IF EXISTS ref.security_equity;
DROP TABLE IF EXISTS ref.security_fx;
DROP TABLE IF EXISTS ref.security_fx_detail;
DROP TABLE IF EXISTS ref.currency;
DROP TABLE IF EXISTS ref.tenor;
DROP TABLE IF EXISTS ref.exchange;

DROP SEQUENCE IF EXISTS ref.security_id_seq;