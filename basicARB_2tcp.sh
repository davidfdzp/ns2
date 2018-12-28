#!/bin/bash

echo "TCP throughput measurements:"
perl tcp_throughput.pl basicARB_2tcp.tr 0 0
perl throughput_tx.pl basicARB_2tcp.tr 1.0 0 0 > basicARB_2tcp_throughput_0_0.txt
perl tcp_throughput.pl basicARB_2tcp.tr 2 1
perl throughput_tx.pl basicARB_2tcp.tr 1.0 2 1 > basicARB_2tcp_throughput_2_1.txt

echo "TCP goodput measurements:"
perl tcp_goodput.pl basicARB_2tcp.tr 2 0
perl goodput_rx.pl basicARB_2tcp.tr 1.0 2 0 > basicARB_2tcp_goodput_2_0.txt
perl tcp_goodput.pl basicARB_2tcp.tr 0 1
perl goodput_rx.pl basicARB_2tcp.tr 1.0 0 1 > basicARB_2tcp_goodput_0_1.txt
# perl tcp_goodput.pl basicARB_2tcp.tr 2 2
# perl tcp_goodput.pl basicARB_2tcp.tr 0 3

# Interactive plot
gnuplot -e "set xlabel \"Time(s)\";set ylabel \"bit/s\";plot \"basicARB_2tcp_throughput_0_0.txt\" with lines title \"Flow 0 throughput from node A\", \"basicARB_2tcp_goodput_2_0.txt\" with lines title \"Flow 0 goodput to node B\", \"basicARB_2tcp_throughput_2_1.txt\" with lines title \"Flow 1 throughput from node B\", \"basicARB_2tcp_goodput_0_1.txt\" with lines title \"Flow 1 goodput to node A\" ; pause -1"

