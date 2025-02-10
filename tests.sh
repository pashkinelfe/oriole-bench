# Do all benchmarks for specified version of PG and Orioledb
# 
# Input: list of Orioledb commit hashes

for var in "$@"
do
	git clone https://github.com/orioledb/orioledb
        cd orioledb
	git checkout $var
done
	ENGINE=heap PATCH_ID=heap ./test-ibench.sh



for var in "$@"
do
	ENGINE=orioledb PATCH_ID=$var ./test-ibench.sh
done
	ENGINE=heap PATCH_ID=heap ./test-ibench.sh

#./test-tpcc.sh
#./test-tpcb.sh
