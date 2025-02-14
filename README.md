# Oriole-bench: automated benchmarking for Postgres and OrioleDB

Mainly fo internal usage. Use at your own risk.

## Usage

```
git checkout https://github.com/pashkinelfe/oriole-bench.git
cd oriole-bench
$ORIOLE_ID="<list of commits>" $HEAP_ID="<list of commits>" ./tests.sh 
```

```<list of commits>``` is a list of commit hashes, tags or branch names to be compared in tests

It is used at git checkout stage.

Result files would be like: ```./results/<orioledb/heap>-<commit hash/tag>-<test-name>-<optional params>```

Each result file contains timestamp then test results. Repeated test runs appended to the file with respective timestamps.

## Caveats

- Tests are for quite heavy instances like c7g. For running on smaller machines PG config parameters and test scales may need to be modified. 
- Error processing is far from being full. If you get something unexpected - report.
- Ibench test detaches several runners, kill them all if stopping test before it finishes.
