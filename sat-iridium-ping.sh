#!/bin/bash

# Interactive Plot
gnuplot -e "set xlabel \"time(s)\";set ylabel \"RTT(ms)\";plot \"RTTs.txt\" with lines title \"Measured ping RTT on Iridium model during a day\" ; pause -1"

