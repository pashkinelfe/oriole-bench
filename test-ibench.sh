# Run ibench tests
# Input parameters
# $PATCH_ID - commit hash
# $ENGINE - heap or orioledb
# $PGDATADIR - PG data dir

export IBENCH=./mdcallag-tools/bench/ibench/iibench.py

pg_ctl -D $PGDATADIR -l logfile stop
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start

cp postgresql.auto.conf.ibench $PGDATADIR/postgresql.auto.conf
if [ $ENGINE = "orioledb" ]; then
	psql -dpostgres -c "create extension orioledb;"
	cat postgresql.auto.conf.orioledb.ibench >> $PGDATADIR/postgresql.auto.conf
elif [ $ENGINE = "heap" ]; then
	cat postgresql.auto.conf.heap.ibench >> $PGDATADIR/postgresql.auto.conf
else
	echo "Unknown engne: $ENGINE"
	exit
fi

pg_ctl -D $PGDATADIR -l logfile restart

echo "Running ibench for commit $PATCH_ID with $ENGINE"

SCALE_MUL=5 CONNS=20 ./run_ibench.sh

echo "Completed ibench for commit $PATCH_ID with $ENGINE"
