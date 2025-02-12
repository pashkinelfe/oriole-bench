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

if [ -n $PG_ID ]; then
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
git clone https://github.com/pashkinelfe/mdcallag-tools.git mdcallag-tools
export IBENCHDIR=/mdcallag-tools/bench/ibench

sudo apt install golang-go -y
git clone https://github.com/pingcap/go-tpc
cd go-tpc
make build
cd ..

mkdir /ssd

if [ $NVME -eq 1 ]; then
        # hardcoded for c7gd instance
        parted /dev/nvme0n1 mklabel gpt
        parted /dev/nvme0n1 mkpart ext4 0% 100%
        sudo mkfs.ext4 /dev/nvme0n1p1
        mount -t ext4 -o defaults,nocheck  /dev/nvme0n1p1 /ssd
        chmod 0777 /ssd
fi
chmod 0777 /ssd
export PGDATADIR=/ssd/pgdata

# ---- TEST PHASE ----

for var in $ORIOLE_ID
do
	export GITHUB_WORKSPACE="$(pwd)/$var"
	PATH=$GITHUB_WORKSPACE:$PATH
	ENGINE=orioledb PATCH_ID=$var ./test-ibench.sh
	#./test-tpcc.sh
	#./test-tpcb.sh
done

if [ -n $PG_ID ]; then
	for var in $PG_ID
	do
	export GITHUB_WORKSPACE="$(pwd)/$var"
	PATH=$GITHUB_WORKSPACE:$PATH
	ENGINE=heap PATCH_ID=$var ./test-ibench.sh
	#./test-tpcc.sh
	#./test-tpcb.sh
	done
fi
