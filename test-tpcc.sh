# Input variables
# $LINEAR_SCALE - linear scale, beautiful for publishing but slower
# $INIT_POINT - init cluster before each point (better test repeatability but much slower)
if [ $LINEAR_SCALE -eq 1 ]; then
        conns = ( 330 320 310 300 290 280 270 260 250 240 230 220 210 200 190 180 170 160 150 140 130 120 110 100 90 80 70 60 50 40 30 20 10 1 )
else
        conns = ( 330 220 150 100 68 47 33 22 15 10 7 5 3 2 1 )
fi

for w in 470 220 100 47 22 10 5
do
        echo "tpc-c NEW SERIES -----------------" >> go-tpc/results.orioledb
        echo "tpc-c NEW SERIES -----------------" >> wait_events.orioledb

        if [ $INIT_POINT -ne 1]; then
                init-cluster
        fi

        for a in "${conns[@]}"
        do
                if [  $INIT_POINT -eq 1]; then
                        init_cluster
                fi

                echo "tpc-c warehouses: $w conns: $a" >> results.orioledb
                echo "tpc-c warehouses: $w conns: $a" >> wait_events.orioledb

                psql -dpostgres -c "checkpoint;"

#                df /dev/root >> results.orioledb
#                iostat -xt nvme0n1 90 2  >> results.orioledb &
		cd go-tpc
                ./bin/go-tpc tpcc --warehouses $w run -d postgres -U ubuntu -p '5432' -D postgres -H 127.0.0.1 -P 5432 --conn-params sslmode=disable -T $a --time 100s | grep tpmTotal >> results.orioledb

                ## log wait events each second
##                for t in {1..90}
##                do
##                        sleep 1
##                        echo time: $t s >> wait_events.orioledb
##                        psql -dpostgres -c "SELECT jsonb_object_agg(k, v)::text waits, pg_current_wal_lsn() lsn
##                                    FROM(SELECT coalesce(wait_event, 'CPU') k, count(*) v FROM pg_stat_activity GROUP BY wait_event);" >> wait_events.orioledb
##                        df /dev/root >> wait_events.orioledb
		cd ..
	done
done

init_cluster(){
	sudo killall -9 postgres
	pg_ctl -D pgdata -l logfile stop
        sleep 10
        initdb pgdata --no-locale
        pg_ctl -D pgdata -l logfile start
        psql -dpostgres -c "create extension orioledb;" # create extension pg_stat_statements;"
        cp postgresql.auto.conf.orioledb pgdata/postgresql.auto.conf
        pg_ctl -D pgdata -l logfile restart
        psql -dpostgres -c "show shared_buffers; show orioledb.main_buffers; show default_table_access_method;"
        cd go-tpc
        # -T 100 makes prepare stage faster, it's not linked to connections at measure stage
        ./bin/go-tpc tpcc --warehouses $w  prepare -T 100 -d postgres -U ubuntu -p '5432' -D postgres -H 127.0.0.1 -P 5432 --conn-params sslmode=disable --no-check
	cd ..
}

