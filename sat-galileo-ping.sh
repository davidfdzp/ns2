#!/bin/bash

# Interactive Plot
gnuplot -e "set xlabel \"time(s)\";set ylabel \"RTT(ms)\";plot \"GalileoRTTs.txt\" with lines title \"Measured ping RTT on Galileo model during a quarter of an orbit period\" ; pause -1"

