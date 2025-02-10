# Run ibench tests
# Input parameters
# $PATCH_ID - commit hash
# $ENGINE - heap or orioledb

export PGDATADIR=/ssd/pgdata
export IBENCH=./mdcallag-tools/bench/ibench/iibench.py

pg_ctl -D $PGDATADIR -l logfile stop

rm -R $PGDATADIR/*
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start

if [ $ENGINE = "orioledb" ]; then
	psql -dpostgres -c "create extension orioledb;"
	cp postgresql.auto.conf.orioledb.ibench $PGDATADIR/postgresql.auto.conf
elif [ $ENGINE = "heap" ]; then
	cp postgresql.auto.conf.heap.disk_bloat $PGDATADIR/postgresql.auto.conf
else
	echo "Unknown engne: $ENGINE"
	exit
fi

pg_ctl -D $PGDATADIR -l logfile restart

echo "Running ibench for commit $PATCH_ID with $ENGINE"

SCALE_MUL=5 CONNS=20 ./run_ibench.sh

echo "Completed ibench for commit $PATCH_ID with $ENGINE"
