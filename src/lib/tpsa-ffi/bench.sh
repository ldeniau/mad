#!/bin/bash
echo -n "Usage:
  gcc -DTPSA_MAIN -std=c99 -Wall -W -pedantic -O3 -fopenmp -static-libgcc  *.c -o tpsa
  ./bench ../../bench-pamrams/compose-params.txt
"
echo -e "nv\tno\tnc\tnl\ttime (s)"
while read line; do
    a=($line)
    nv=${a[0]}
    no=${a[1]}
    nl=${a[2]}
    ./$1 $nv $no $nl 8 2> /dev/null
done < $2
