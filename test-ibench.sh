export PGDATADIR=/ssd/pgdata
export IBENCH=./mdcallag-tools/bench/ibench/iibench.py

rm -R $PGDATADIR/*
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start
psql -dpostgres -c "create extension orioledb;"
cp postgresql.auto.conf.orioledb.ibench $PGDATADIR/postgresql.auto.conf
pg_ctl -D $PGDATADIR -l logfile stop
pg_ctl -D $PGDATADIR -l logfile start
PATCH_ID=sklfhjdsk ENGINE=orioledb SCALE_MUL=5 CONNS=20 ./run_ibench.sh

pg_ctl -D $PGDATADIR -l logfile stop

rm -R $PGDATADIR/*
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start
psql -dpostgres -c "create extension orioledb;"
cp postgresql.auto.conf.heap.disk_bloat $PGDATADIR/postgresql.auto.conf
pg_ctl -D $PGDATADIR -l logfile stop
pg_ctl -D $PGDATADIR -l logfile start
PATCH_ID=sklfhjdsk ENGINE=heap SCALE_MUL=5 CONNS=20 ./run_ibench.sh

