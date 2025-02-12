./scripts/pg-stop
sleep 2
./scripts/pg-initdb-nolocale
sleep 2
psql -dpostgres -c "create extension if not exists orioledb;"
./scripts/pg-stop
echo -e "max_worker_processes = 50 # should fit orioledb.s3_num_workers as long as other workers\n\
log_min_messages = debug1 # will log all S3 requests\n\
shared_preload_libraries = 'orioledb'\n\
orioledb.main_buffers = 20GB\n\
orioledb.undo_buffers = 1GB\n\
default_table_access_method = orioledb\n\
max_parallel_maintenance_workers = 35\n\
max_wal_senders=0\n\
wal_level=minimal\n\
synchronous_commit = off\n\
fsync = off\n\
max_connections=700\n\
max_wal_size = 5GB\n\
shared_buffers = 5GB\n\
max_parallel_workers = 50\n\
max_locks_per_transaction = 3000\n\
work_mem = 10MB\n" > ./pgdata/postgresql.auto.conf
./scripts/pg-start


pgbench postgres -i -s100
psql -dpostgres -f ./orioledb-prepare-function.sql

#psql -dpostgres -c "create table data (id serial, project_id int, ts timestamp, filler text) partition by LIST (project_id);"

#for i in {1..10000}
#do	
#	psql -dpostgres -c "create table data_$i partition of data for values in ($i) USING orioledb;"
#done
#synchronous_commit = off\n\
#fsync = off\n\

