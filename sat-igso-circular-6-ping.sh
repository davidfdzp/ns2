#!/bin/bash

# Interactive Plot
gnuplot -e "set xlabel \"time(s)\";set ylabel \"RTT(ms)\";plot \"IGSO6circularRTTs.txt\" with lines title \"Measured ping RTT on 6 circular IGSO model during a day\" ; pause -1"
