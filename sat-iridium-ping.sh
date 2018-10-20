#!/bin/bash

# Interactive Plot
gnuplot -e "plot \"RTTs.txt\" with lines title \"Measured ping RTT on Iridium model during a day\" ; pause -1"

