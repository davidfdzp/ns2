#!/bin/bash

# Interactive Plot
gnuplot -e "set xlabel \"time(s)\";set ylabel \"RTT(ms)\";plot \"NHubsToMNodesInPermanentRingWithRealVisibilityMeasuredRTTs.txt\" with lines title \"Measured ping RTTs on the model\" ; pause -1"
