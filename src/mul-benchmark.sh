#!/bin/bash
outfile="tpsa.out"
bench=`pwd`"/lib/tpsa-ffi/bench_mul"
while read line; do
    params=( $line )
    nv=${params[0]}
    no=${params[1]}
    nl=${params[2]}
    luajit make_mul_input.lua $nv $no $outfile
    echo -ne "$nv\t$no\t$nl\t"
    $bench $outfile $nl 2>/dev/null
done < bench-params/mul-params.txt
