# Input agruments:
# $1		 name of test
# $ENGINE	 oriole or postgres
# $PATCH_ID	 commit hash
# PGDATADIR	 PG data dir
# $2 		 time elapsed (for reporting)

# Output: test-name, pgdata apparent size, pgdata size, pg_wal apparent size, pg_wal size, orioledb_data apparent size, orioledb_data size, orioledb_undo apparent size, orioledb_undo size, test time (sec, including checkpoint), checkpoint only time (sec)
# 
RESULTFILE="results/$ENGINE-$PATCH_ID-ibench-scale$SCALE_MUL-du"
psql -dpostgres -c "checkpoint;"

echo $1 | tr '\n' ',' >> $RESULTFILE

for dir in $PGDATADIR $PGDATADIR/pg_wal $PGDATADIR/orioledb_data $PGDATADIR/orioledb_undo
do
	du -s $dir --apparent-size | cut -f1 | tr '\n' ',' >> $RESULTFILE
	du -s $dir | cut -f1 | tr '\n' ',' >> $RESULTFILE
done
	echo $2 | tr '\n' ',' >> $RESULTFILE
	echo $SECONDS | tr -d '\n'  >> $RESULTFILE
echo "" >> $RESULTFILE
