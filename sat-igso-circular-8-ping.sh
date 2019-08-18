#!/bin/bash

# Interactive Plot
gnuplot -e "set xlabel \"time(s)\";set ylabel \"RTT(ms)\";plot \"IGSO8circularRTTs.txt\" with lines title \"Measured ping RTT on 8 circular IGSO model during a day\" ; pause -1"
