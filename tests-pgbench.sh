# Run pgbench tests
# Input parameters
# $PATCH_ID - commit hash
# $ENGINE - heap or orioledb
# $PGDATADIR - PG data dir
# $PRECISE - measure more connection points than usual

pg_ctl -D $PGDATADIR -l logfile stop
initdb $PGDATADIR --no-locale
pg_ctl -D $PGDATADIR -l logfile start

cp postgresql.auto.conf.pgbench $PGDATADIR/postgresql.auto.conf
if [ $ENGINE = "orioledb" ]; then
        psql -dpostgres -c "create extension orioledb;"
        cat postgresql.auto.conf.orioledb.pgbench >> $PGDATADIR/postgresql.auto.conf
elif [ $ENGINE = "heap" ]; then
        cat postgresql.auto.conf.heap.pgbench >> $PGDATADIR/postgresql.auto.conf
else
        echo "Unknown engne: $ENGINE"
        exit
fi

pg_ctl -D $PGDATADIR -l logfile restart

pgbench postgres -i -s100
psql -dpostgres -f ./orioledb-prepare-function.sql

if [ $PRECISE -eq 1 ]; then
	conns=(5 6 7 8 9 10 11 12 13 15 16 18 20 22 24 27 30 33 36 39 43 47 51 56 62 68 75 82 91 100 110 120 130 150 160 180 200 220 240 270 300 330 360 390 430 470)
else
	conns=(10 15 22 33 47 68 100 150 220 330 470)
fi

for a in "${conns[@]}"
do
	echo "read only test conns: $a"
	#pgbench postgres -S -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in "${conns[@]}"
do
	echo "select 9 conns: $a"
	#pgbench postgres -f ./orioledb-select-9.sql -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in "${conns[@]}"
do
	echo "tpcb procedure conns: $a"
	#pgbench postgres -f ./orioledb-tpcb-in-procedure.sql -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in "${conns[@]}"
do
	echo "TPC-b conns: $a"
	#pgbench postgres -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

