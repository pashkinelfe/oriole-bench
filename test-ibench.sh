#!/bin/bash
# Run ibench tests
# Input parameters
# $PATCH_ID - commit hash
# $ENGINE - heap or orioledb
# $PGDATADIR - PG data dir
# $FAST_RUN - run fast for testing, not for actual measurements
export IBENCH=./mdcallag-tools/bench/ibench/iibench.py

echo TESTING PATCH $PATCH_ID

# Check correct path to PG build
if [ `which pg_ctl` = "/usr/local/pgsql/bin/pg_ctl" ]; then
       echo "USING DEFAULT PG BINARIES. CHECK THAT bin DIRECTORY OF YOUR PATCHSET IS SET ON A FIRST POSITION IN PATH"
       exit 1
fi


pg_ctl -D $PGDATADIR -l logfile stop
rm -Rf /ssd/pgdata
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start

if [ -z "$MEMORY_BUFFERS" ]; then
    MEMORY_BUFFERS='70GB'
fi

cp postgresql.auto.conf.ibench $PGDATADIR/postgresql.auto.conf
if [ $ENGINE = "orioledb" ]; then
	psql -dpostgres -c "create extension orioledb;"
	cat postgresql.auto.conf.orioledb.ibench >> $PGDATADIR/postgresql.auto.conf
	echo orioledb.main_buffers \= $MEMORY_BUFFERS >> $PGDATADIR/postgresql.auto.conf
elif [ $ENGINE = "heap" ]; then
	cat postgresql.auto.conf.heap.ibench >> $PGDATADIR/postgresql.auto.conf
	echo shared_buffers \= $MEMORY_BUFFERS >> $PGDATADIR/postgresql.auto.conf
else
	echo "Unknown engne: $ENGINE"
	exit 1
fi

pg_ctl -D $PGDATADIR -l logfile restart

echo "Running ibench for commit $PATCH_ID with $ENGINE"

if [ -z "$IBENCH_SCALE_MUL"]; then
    if [ -n "$FAST_RUN" ]; then
    	FAST_RUN_MSG="FAST RUN!"
    	export IBENCH_SCALE_MUL=1
    else
    	export IBENCH_SCALE_MUL=100
    fi
fi

RESULTFILE="results/$ENGINE-$PATCH_ID-ibench-scale$IBENCH_SCALE_MUL"

echo "# $FAST_RUN_MSG" `date` >> $RESULTFILE
echo "# pgdata apparent, pgdata, pg_wal apparent, pg_wal, orioledb_data apparent, orioledb_data, orioledb_undo apparent, orioledb_undo, time, checkpoint time" >> $RESULTFILE

CONNS=20 ./run_ibench.sh

echo "Completed ibench for commit $PATCH_ID with $ENGINE"
pg_ctl -D $PGDATADIR -l logfile stop
