for a in 10 15 22 33 47 68 100 150 220 330 470
do
	echo "read only test conns: $a"
	pgbench postgres -S -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in 10 15 22 33 47 68 100 150 220 330 470
do
	echo "select 9 conns: $a"
	pgbench postgres -f ./orioledb-select-9.sql -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in 10 15 22 33 47 68 100 150 220 330 470
do
	echo "tpcb procedure conns: $a"
	pgbench postgres -f ./orioledb-tpcb-in-procedure.sql -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

echo "----------------------------"
for a in 10 15 22 33 47 68 100 150 220 330 470
do
	echo "TPC-b conns: $a"
	pgbench postgres -s100 -P10 -M prepared -T 30 -j 5 -c $a
done

