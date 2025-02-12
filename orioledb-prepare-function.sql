CREATE OR REPLACE FUNCTION pgbench_transaction(_aid int, _bid int, _tid int, _delta int)
RETURNS void AS $$
BEGIN
UPDATE pgbench_accounts SET abalance = abalance + _delta WHERE aid = _aid;
PERFORM abalance FROM pgbench_accounts WHERE aid = _aid;
UPDATE pgbench_tellers SET tbalance = tbalance + _delta WHERE tid = _tid;
UPDATE pgbench_branches SET bbalance = bbalance + _delta WHERE bid = _bid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (_tid, _bid, _aid, _delta, CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

