# Input variables
# $LINEAR_SCALE - linear scale, beautiful for publishing but slower
# $INIT_POINT - init cluster before each point (better test repeatability but much slower)
# $WAREHOUSES - (optional) custom array of warehouses values to run
# $EXTENDED_LOGGING - print iostat, wait events and du to separate output file each second
RESULTFILE="results/$ENGINE-$PATCH_ID-tpcc"

if [ -n "$LINEAR_SCALE" ]; then
        conns=(330 320 310 300 290 280 270 260 250 240 230 220 210 200 190 180 170 160 150 140 130 120 110 100 90 80 70 60 50 40 30 20 10 1)
else
        conns=(330 220 150 100 68 47 33 22 15 10 7 5 3 2 1)
fi

if [ -n "$WAREHOUSES" ]; then
	wh=$WAREHOUSES
else
	wh=(470 220 100 47 22 10 5)
fi

for w in ${wh[@]}
do
        echo "# NEW SERIES warehouses = " $w >> $RESULTFILE

	if [ -n "$EXTENDED_LOGGING" ]; then
		echo "# NEW SERIES warehouses = " $w >> $RESULTFILE.extended
		echo "# NEW SERIES warehouses = " $w >> $RESULTFILE.waits
	fi

        if [ -z "$INIT_POINT" ]; then
                init-cluster
        fi

        for a in "${conns[@]}"
        do
                if [ -n "$INIT_POINT" ]; then
                        init_cluster
                fi

                echo "$w,$a," | tr -d '\n' >> $RESULTFILE

                psql -dpostgres -c "checkpoint;"

		if [ -n "$EXTENDED_LOGGING" ]; then
			MEASURE_TIME=100s # do not change
			echo "tpc-c warehouses: $w conns: $a" >> $RESULTFILE.extended
			echo "tpc-c warehouses: $w conns: $a" >> $RESULTFILE.waits
	        	du -s $PGDATADIR | cut -f1 >> $RESULTFILE.extended
			iostat -xt nvme0n1 90 2  >> $RESULTFILE.extended &

	                ./go-tpc/bin/go-tpc tpcc --warehouses $w run -d postgres -U ubuntu -p '5432' -D postgres -H 127.0.0.1 -P 5432 --conn-params sslmode=disable -T $a --time $MEASURE_TIME | grep tpmTotal >> $RESULTFILE &

                	## log wait events each second
			for t in {1..90}
			do
				sleep 1
				echo time: $t s >> $RESULTFILE.waits
				echo time: $t s >> $RESULTFILE.extended
				psql -dpostgres -c "SELECT jsonb_object_agg(k, v)::text waits, pg_current_wal_lsn() lsn FROM(SELECT coalesce(wait_event, 'CPU') k, count(*) v FROM pg_stat_activity GROUP BY wait_event);" >> $RESULTFILE.waits
				du -s $PGDATADIR | cut -f1 >> $RESULTFILE.extended
			done
			sleep 20 ## grace interval to write results
		else	
			# No extended logging
			MEASURE_TIME=5s
	                ./go-tpc/bin/go-tpc tpcc --warehouses $w run -d postgres -U ubuntu -p '5432' -D postgres -H 127.0.0.1 -P 5432 --conn-params sslmode=disable -T $a --time $MEASURE_TIME | grep tpmTotal >> $RESULTFILE
		fi
	done
done

init_cluster(){
	sudo killall -9 postgres
	pg_ctl -D $PGDATADIR -l logfile stop
        sleep 10
        initdb $PGDATADIR --no-locale
        pg_ctl -D $PGDATADIR -l logfile start

        cp postgresql.auto.conf.tpcc $PGDATADIR/postgresql.auto.conf
	if [ $ENGINE = "orioledb" ]; then
        	psql -dpostgres -c "create extension orioledb;"
        	cat postgresql.auto.conf.orioledb.tpcc >> $PGDATADIR/postgresql.auto.conf
	elif [ $ENGINE = "heap" ]; then
        	cat postgresql.auto.conf.heap.tpcc >> $PGDATADIR/postgresql.auto.conf
	else
        	echo "Unknown engne: $ENGINE"
        exit 1	

        pg_ctl -D $PGDATADIR -l logfile restart
        psql -dpostgres -c "show shared_buffers; show orioledb.main_buffers; show default_table_access_method;"
        # -T 100 makes prepare stage faster, it's not linked to connections at measure stage
        ./go-tpc/bin/go-tpc tpcc --warehouses $w  prepare -T 100 -d postgres -U ubuntu -p '5432' -D postgres -H 127.0.0.1 -P 5432 --conn-params sslmode=disable --no-check
}

