# Do all benchmarks for specified version of PG and Orioledb
# 
# Input:
# $ORIOLE_ID compulsory list of Orioledb commit hashes
# $PG_ID optional list of PG commit hashes (for PG-only tests)

# ---- BUILD PHASE ----

#       git clone https://github.com/orioledb/orioledb
#       git clone https://github.com/orioledb/postgres postgresql
        cp -r ../../orioledb orioledb   # fixit
        cp -r ../postgres postgresql    # fixit

for var in $ORIOLE_ID
do
        cd orioledb
        git checkout $var
#       PATHSET="cat .pgtags | grep 17 | cut -d' ' -f2-"
#       echo $PATCHSET
        cd ..

        chmod +x ./orioledb/ci/prerequisites.sh
        export COMPILER=clang
        export LLVM_VER=17
        export CHECK_TYPE=normal
        export GITHUB_ENV=tmp
        export GITHUB_JOB=run-benchmark
        export GITHUB_WORKSPACE="$(pwd)/$var"
        ./orioledb/ci/prerequisites.sh
        ./orioledb/ci/build.sh
done

if [ -n "$PG_ID" ]; then
	for var in $PG_ID
	do
		export GITHUB_WORKSPACE="$(pwd)/$var"
		cd postgresql
		./configure --enable-debug --disable-cassert --enable-tap-tests --with-icu --prefix=$GITHUB_WORKSPACE
		make -sj 64
		make -sj 64 install
		make -C contrib -sj 64
		make -C contrib -sj 64 install
		cd ..
	done
fi

# ---- PREPARE TESTS PHASE
pip3 install psycopg2 six testgres
git clone https://github.com/pashkinelfe/mdcallag-tools.git mdcallag-tools
export IBENCHDIR=/mdcallag-tools/bench/ibench

sudo apt install golang-go -y
git clone https://github.com/pingcap/go-tpc
cd go-tpc
make build
cd ..

sudo mkdir /ssd
if [ -n "$NVME" ]; then
	echo "NVME"
#       hardcoded for c7gd instance
	sudo parted /dev/nvme0n1 mklabel gpt
	sudo parted /dev/nvme0n1 mkpart ext4 0% 100%
	sudo mkfs.ext4 /dev/nvme0n1p1
	sudo mount -t ext4 -o defaults,nocheck  /dev/nvme0n1p1 /ssd
	sudo chmod 0777 /ssd
fi

sudo chmod 0777 /ssd
export PGDATADIR=/ssd/pgdata

# ---- TEST PHASE ----
OLDPATH=$PATH

for var in $ORIOLE_ID
do
	export GITHUB_WORKSPACE="$(pwd)/$var"
	export PATH=$GITHUB_WORKSPACE/pgsql/bin:$PATH

	echo $PATH
	#./test-tpcc.sh
#	ENGINE=orioledb PATCH_ID=$var ./tests-pgbench.sh
	ENGINE=orioledb PATCH_ID=$var ./test-ibench.sh
done

if [ -n "$PG_ID" ]; then
	for var in $PG_ID
	do
	export GITHUB_WORKSPACE="$(pwd)/$var"
	export PATH=$GITHUB_WORKSPACE/pgsql/bin:$PATH
	#./test-tpcc.sh
#	ENGINE=heap PATCH_ID=$var ./tests-pgbench.sh
	ENGINE=heap PATCH_ID=$var ./test-ibench.sh
	done
fi

export PATH=$OLDPATH
