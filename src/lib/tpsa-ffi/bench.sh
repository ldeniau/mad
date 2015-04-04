#!/bin/bash
echo -n "Runs an executable with all (nv,no,nl) from a file. Extra params are passed to the script.
Usage:./$0 script_name params_file
e.g.  ./$0 bench_mul ../../bench-params/mul_params.txt
"
script=$1
file=$2
shift 2
echo -e "nv\tno\tnc\tnl\ttime (s)"
while read line; do
    a=($line)
    nv=${a[0]}
    no=${a[1]}
    nl=${a[2]}
    $script $nv $no $nl "$@"
done < $file
