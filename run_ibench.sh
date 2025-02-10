# Ibench run script. Adapted from ibench repo

# Necessary input options:
# $SCALE_MUL Scale multiplier (in percents of full test)
# $ENGINE: heap, orioledb
# $CONNS Number of connections
# $PGDATADIR PG datadir
# $IBENCH: iibench.py location with path
# $PATCH_ID commit hash for reporting to results

#
# The benchmark is a sequence of steps:
# l.i0 -> initial load
# l.x -> create secondary indexes
# l.i1 -> random inserts as fast as possible with 50 writes per commit
# l.i2 -> random inserts as fast as possible with 5 writes per commit
# qr100.L1 -> range queries as fast as possible, in the background do 100 inserts/s and 100 deletes/s
# qp100.L2 -> point queries as fast as possible, in the background do 100 inserts/s and 100 deletes/s
# qr500.L3 -> range queries as fast as possible, in the background do 500 inserts/s and 500 deletes/s
# qp500.L4 -> point queries as fast as possible, in the background do 500 inserts/s and 500 deletes/s
# qr1000.L5 -> range queries as fast as possible, in the background do 1000 inserts/s and 1000 deletes/s
# qp1000.L6 -> point queries as fast as possible, in the background do 1000 inserts/s and 1000 deletes/s

# Each table is a queue -> inserts are done to one end, deletes to the other and iibench.py has code
# so they run at the same rate. This triggers a perf problem with Postgres, see my many posts
# on the CPU overhead from get_actual_variable_range.
# https://www.google.com/search?q=site%3Asmalldatum.blogspot.com+get_actual_variable_range

#
# Initial load -> l.i0
#

# Initial load without secondary indexes. This also creates the tables.
# In this case it inserts 10M rows per table

for N in $( seq 1 $CONNS ); do
	python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --max_rows=$((100000*$SCALE_MUL)) --table_name=pi${N} --setup --num_secondary_indexes=0 --data_length_min=10 --data_length_max=20 --rows_per_commit=100 --inserts_per_second=0 --query_threads=0 --seed=1733776768 --dbopt=none --my_id=$N --use_prepared_query --engine_options="using $ENGINE" &
  pids[${N}]=$!
done

# Wait for initial load processes to finish
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh l.i0 $SECONDS
SECONDS=0

#
# Create indexes -> l.x
#

# create 3 secondary indexes per table
for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --secondary_at_end --max_rows=5 --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=100 --inserts_per_second=0 --query_threads=0 --seed=1733776886 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done

# Wait for create index processes to finish
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh l.ix $SECONDS
SECONDS=0

#
# Random inserts, random deletes with 50 writes rows per commit -> l.i1
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --max_rows=$((160000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=0 --query_threads=0 --seed=1733776944 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done

for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh l.i1 $SECONDS
SECONDS=0

#
# Random inserts, random deletes with 5 writes per commit -> l.i2
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --max_rows=$((40000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=5 --inserts_per_second=0 --query_threads=0 --seed=1733777712 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh l.i2 $SECONDS
SECONDS=0

#
# Reduce MVCC GC debt
# 
# For Postgres this does vacuum (verbose, analyze, index_cleanup=ON) for each table and waits for that to finish
# It does that for heap tables and OrioleDB because I have yet to update my scripts.
# 
# Then this does checkpoint and waits for that to finish.
#
# Finally, if the above finished in less than X seconds than it waits until X seconds have passed. The value of X is a function
# of the number of rows and X=260 with 10M rows per table and 20 tables.
#
#TODO add code to do the above.

#
# Random range queries with 100 background inserts and deletes per second -> qr100.L1
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --max_rows=$((1800*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=100 --query_threads=1 --seed=1733778656 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr100.L1 $SECONDS
SECONDS=0

#
# Random point queries with 100 background inserts and deletes per second -> qp100.L2
#

for n in $( seq 1 $CONNS ); do
	python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --query_pk_only --max_rows=$((1800*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=100 --query_threads=1 --seed=1733780481 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr100.L2 $SECONDS
SECONDS=0

#
# Random range queries with 500 background inserts and deletes per second -> qr500.L3
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --max_rows=$((9000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=500 --query_threads=1 --seed=1733782306 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr500.L3 $SECONDS
SECONDS=0

#
# Random point queries with 500 background inserts and deletes per second -> qp500.L4
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --query_pk_only --max_rows=$((9000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=500 --query_threads=1 --seed=1733784214 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr500.L4 $SECONDS
SECONDS=0

#
# Random range queries with 1000 background inserts and deletes per second -> qr1000.L5
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --max_rows=$((18000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=1000 --query_threads=1 --seed=1733786203 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr1000.L5 $SECONDS
SECONDS=0

#
# Random point queries with 1000 background inserts and deletes per second -> qp1000.L6
#

for n in $( seq 1 $CONNS ); do
  python3 $IBENCH --dbms=postgres --db_name=postgres --secs_per_report=1 --db_host=127.0.0.1 --db_user=ubuntu  --engine=pg --unique_checks=1 --bulk_load=0 --delete_per_insert --query_pk_only --max_rows=$((18000*$SCALE_MUL)) --table_name=pi${N} --num_secondary_indexes=3 --data_length_min=10 --data_length_max=20 --rows_per_commit=50 --inserts_per_second=1000 --query_threads=1 --seed=1733789005 --dbopt=none --my_id=$N --use_prepared_query --engine_options=$ENGINE &
  pids[${N}]=$!
done
for N in $( seq 1 $CONNS ); do
  wait ${pids[${N}]}
done

./report-ibench.sh qr1000.L6 $SECONDS
SECONDS=0
