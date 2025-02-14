# Run ibench tests
# Input parameters
# $PATCH_ID - commit hash
# $ENGINE - heap or orioledb
# $PGDATADIR - PG data dir
if [ `which pg_ctl` == "/usr/local/pgsql/bin/pg_ctl" ]; then
       echo "USING DEFAULT PG BINARIES. CHECK THAT bin DIRECTORY OF YOUR PATCHSET IS SET ON A FIRST POSITION IN PATH"
       exit 1
fi
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
	exit 1
fi

pg_ctl -D $PGDATADIR -l logfile restart

echo "Running ibench for commit $PATCH_ID with $ENGINE"

export SCALE_MUL=5
RESULTFILE="results/$ENGINE-$PATCH_ID-ibench-scale$SCALE_MUL-du"

echo "# " tr -d '\n' >> $RESULTFILE
date >> $RESULTFILE
echo "# pgdata apparent, pgdata, pg_wal apparent, pg_wal, orioledb_data apparent, orioledb_data, orioledb_undo apparent, orioledb_undo, time, checkpoint time" >> $RESULTFILE

CONNS=20 ./run_ibench.sh

echo "Completed ibench for commit $PATCH_ID with $ENGINE"
pg_ctl -D $PGDATADIR -l logfile stop
