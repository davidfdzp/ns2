#!/bin/bash

if [ "$1" != "" ]; then
	N_RLC=$1
else
	N_RLC=1
fi

if [ "$2" != "" ]; then
	N_FLC=$2
else
	N_FLC=1
fi

if [ "$3" != "" ]; then
	NUM_NODES=$3
else
	NUM_NODES=$N_RLC
fi

if [ "$4" != "" ]; then
	NUM_FID=$4
else
	NUM_FID=2
fi

FIRST_NODE=$((1 + N_RLC + N_FLC))
LAST_NODE=$((FIRST_NODE + NUM_NODES - 1))

# Clean up
rm plot*.png
rm *.in

echo "modelDatalink.sh $N_RLC $N_FLC $NUM_NODES $NUM_FID execution report" > modelDatalink.txt

echo "\documentclass[a4paper, 11pt, twoside]{article}" > modelDatalink.tex
# echo "\usepackage[latin1]{inputenc}" >> modelDatalink.tex
echo "\usepackage{hyperref}" >> modelDatalink.tex
echo "\usepackage{spreadtab}" >> modelDatalink.tex
echo "\usepackage{color}" >> modelDatalink.tex
echo "\usepackage{longtable}" >> modelDatalink.tex
echo "\hypersetup{colorlinks=true,%" >> modelDatalink.tex
echo "			citecolor=black,%" >> modelDatalink.tex
echo "			filecolor=black,%" >> modelDatalink.tex
echo "			linkcolor=black,%" >> modelDatalink.tex
echo "			urlcolor=black}" >> modelDatalink.tex
echo "\usepackage[pdftex]{graphicx}" >> modelDatalink.tex
# echo "\author{David Fernández Piñas}" >> modelDatalink.tex
echo "\author{David F. Pinas}" >> modelDatalink.tex
echo "\title{Simulation of traffic over data link}" >> modelDatalink.tex
echo "\begin{document}" >> modelDatalink.tex
echo "\maketitle" >> modelDatalink.tex
echo "\section{Introduction}" >> modelDatalink.tex
echo "Ns-2 is an event-driven simulator designed specifically for research in computer communication networks. Having been under constant investigation and enhancement for years since its inception in 1989, it now contains modules for numerous network components such as satellite links, transport layer protocols, applications, etc." >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "To investigate network performance, it allows using the Tcl scripting language to configure a network and observe results generated. Undoubtedly, it has become one of the most widely used network simulators~\cite{Intro:ns2}." >> modelDatalink.tex
echo "In this report, it is evaluated the Quality of Service (QoS) achievable on a data link by $NUM_FID CoS traffic corresponding to the execution of modelDatalink.tcl script." >> modelDatalink.tex
echo "\section{Model configuration}" >> modelDatalink.tex
echo "Simulation of $NUM_NODES remote nodes generating and receiving $NUM_FID CoS traffic over a data link with $N_RLC return link carriers and $N_FLC forward link carriers of a given capacity." >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "The simulation output is the trace file modelDatalink.tr." >> modelDatalink.tex
echo "Run nam modelDatalink.nam to see the network topology." >> modelDatalink.tex
echo "\section{Execution results}" >> modelDatalink.tex
echo "Forward link packets counting is summarized in table~\ref{tab:FLpackets}." >> modelDatalink.tex
# echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\begin{longtable}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> modelDatalink.tex
# echo "\centering" >> modelDatalink.tex
# echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "\textbf{Flow ID} & \textbf{Src} & \textbf{Dest} & \textbf{\#Packets} & \textbf{\#Bytes} & \textbf{\#Drops} & \textbf{PLR} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
# FL packet counting:
# Measure packets sent from hubs per fid
for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk modelDatalink.tr >> modelDatalink.tex
	done
done
# Measure packets sent from central node (node zero) to access nodes
for (( i=$((1 + N_FLC)); i<$FIRST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=0 -v dest=$i -f measure-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v orig=0 -v dest=$i -f measure-loss.awk modelDatalink.tr >> modelDatalink.tex
	done
done
# Measure packets received at remotes
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk modelDatalink.tr >> modelDatalink.tex
	done
done
# echo "\end{tabular}" >> modelDatalink.tex
# echo "\end{table}" >> modelDatalink.tex
echo "\caption{FL packet counting}" >> modelDatalink.tex
echo "\label{tab:FLpackets}" >> modelDatalink.tex
echo "\end{longtable}" >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "Return link packets counting is summarized in table~\ref{tab:RLpackets}." >> modelDatalink.tex
# echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\begin{longtable}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> modelDatalink.tex
# echo "\centering" >> modelDatalink.tex
# echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "\textbf{Flow ID} & \textbf{Src} & \textbf{Dest} & \textbf{\#Packets} & \textbf{\#Bytes} & \textbf{\#Drops} & \textbf{PLR} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
# RL packet counting:
# Measure packets sent by remotes
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk modelDatalink.tr >> modelDatalink.tex
	done
done
# Measure packets received at hubs
for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk modelDatalink.tr >> modelDatalink.tex
	done	
done
# Measure packets sent from access nodes to satellite
for (( i=$((1 + N_FLC)); i<$FIRST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=$i -v dest=0 -f measure-loss.awk modelDatalink.tr >> modelDatalink.txt
		gawk -v fid=$j -v orig=$i -v dest=0 -f measure-loss.awk modelDatalink.tr >> modelDatalink.tex
	done
done
# echo "\end{tabular}" >> modelDatalink.tex
# echo "\end{table}" >> modelDatalink.tex
echo "\caption{RL packet counting}" >> modelDatalink.tex
echo "\label{tab:RLpackets}" >> modelDatalink.tex
echo "\end{longtable}" >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "Forward link packets average delay is summarized in table~\ref{tab:FLdelay}." >> modelDatalink.tex
echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\caption{FL packets delay}" >> modelDatalink.tex
echo "\label{tab:FLdelay}" >> modelDatalink.tex
echo "\centering" >> modelDatalink.tex
echo "\STautoround{6}" >> modelDatalink.tex
echo "\begin{spreadtab}{{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|}}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "@ \textbf{Flow ID} & @ \textbf{Dest} & @ \textbf{Average delay (s)} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
# Measure end-to-end delay of packets directed to nodes per QoS
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		gawk -v dest=$i -v fid=$j -f measure-any-fid-delay-ip.awk modelDatalink.tr > modelDatalink_delay_$i\_$j.txt
		# Now get the average of the previously measured delays		
		gawk -v dest=$i -v fid=$j -f average_delay.awk modelDatalink_delay_$i\_$j.txt >> modelDatalink.tex
	done
done
for (( j=0; j<$NUM_FID; j++ ))
do
	echo "a$((2 + j)) & @ All & (c`seq -s +c $((2 + j)) $NUM_FID $((j + NUM_FID * NUM_NODES))`)/$NUM_NODES \\\\" >> modelDatalink.tex
	echo "\hline" >> modelDatalink.tex
done
# What the previous loop does for NUM_FID equal to 2
# echo "a2 & @ All & (c`seq -s +c 2 2 $((2 * NUM_NODES))`)/$NUM_NODES \\\\" >> modelDatalink.tex
# echo "\hline" >> modelDatalink.tex
# echo "a3 & @ All & (c`seq -s +c 3 2 $((1 + 2 * NUM_NODES))`)/$NUM_NODES \\\\" >> modelDatalink.tex
# echo "\hline" >> modelDatalink.tex
echo "\end{spreadtab}" >> modelDatalink.tex
echo "\end{table}" >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "Return link packets average delay is summarized in table~\ref{tab:RLdelay}." >> modelDatalink.tex
echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\caption{RL packets delay}" >> modelDatalink.tex
echo "\label{tab:RLdelay}" >> modelDatalink.tex
echo "\centering" >> modelDatalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{Average delay (s)} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
# Measure end-to-end delay of packets directed to hubs per QoS
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		gawk -v dest=$i -v fid=$j -f measure-any-fid-delay-ip.awk modelDatalink.tr > modelDatalink_delay_$i\_$j.txt
		# Now get the average of the previously measured delays		
		gawk -v dest=$i -v fid=$j -f average_delay.awk modelDatalink_delay_$i\_$j.txt >> modelDatalink.tex
	done
done
echo "\end{tabular}" >> modelDatalink.tex
echo "\end{table}" >> modelDatalink.tex
echo "" >> modelDatalink.tex
# Now get the percentile 95 and 99.9 of previously measured delays
echo "Forward link packets delay percentiles are summarized in table~\ref{tab:FLdelay2}." >> modelDatalink.tex
echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\caption{FL packets delay percentiles 95 and 99.9}" >> modelDatalink.tex
echo "\label{tab:FLdelay2}" >> modelDatalink.tex
echo "\centering" >> modelDatalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|p{2.25cm}|}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{TD95 (s)} & \textbf{TD99.9 (s)} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		perl percentile_tex_table_row.pl modelDatalink_delay_$i\_$j.txt 1 $j $i 95 99.9 >> modelDatalink.tex		
	done
done
echo "\end{tabular}" >> modelDatalink.tex
echo "\end{table}" >> modelDatalink.tex
echo "" >> modelDatalink.tex
echo "Return link packets delay percentiles are summarized in table~\ref{tab:RLdelay2}." >> modelDatalink.tex
echo "\begin{table}[!h]" >> modelDatalink.tex
echo "\caption{RL packets delay percentiles 95 and 99.9}" >> modelDatalink.tex
echo "\label{tab:RLdelay2}" >> modelDatalink.tex
echo "\centering" >> modelDatalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|p{2.25cm}|}" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{TD95 (s)} & \textbf{TD99.9 (s)} \\\\" >> modelDatalink.tex
echo "\hline" >> modelDatalink.tex
# Measure end-to-end delay of packets directed to hubs per QoS
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do		
		perl percentile_tex_table_row.pl modelDatalink_delay_$i\_$j.txt 1 $j $i 95 99.9 >> modelDatalink.tex		
	done
done
echo "\end{tabular}" >> modelDatalink.tex
echo "\end{table}" >> modelDatalink.tex
echo "" >> modelDatalink.tex

# Get the percentile 95 and 99 of web durations
# perl percentile.pl web_durations.txt 1 95 >> modelDatalink.txt
# perl percentile.pl web_durations.txt 1 99.9 >> modelDatalink.txt

echo "Forward or download link TCP throughput and goodput." >> modelDatalink.tex
echo "" >> modelDatalink.tex
for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j throughput from hub i file with specified granularity in seconds
		perl throughput_tx.pl modelDatalink.tr 1.0 $i $j > modelDatalink_throughput_$i\_$j.txt
		perl tcp_throughput.pl modelDatalink.tr $i $j >> modelDatalink.tex
	done
done
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j goodput to node i file with specified granularity in seconds
		perl goodput_rx.pl modelDatalink.tr 1.0 $i $j > modelDatalink_goodput_$i\_$j.txt
		perl tcp_goodput.pl modelDatalink.tr $i $j >> modelDatalink.tex
	done
done
echo "Return or upload link TCP throughput and goodput." >> modelDatalink.tex
echo "" >> modelDatalink.tex
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j throughput from node i file with specified granularity in seconds
		perl throughput_tx.pl modelDatalink.tr 1.0 $i $j > modelDatalink_throughput_$i\_$j.txt
		perl tcp_throughput.pl modelDatalink.tr $i $j >> modelDatalink.tex
	done
done
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j goodput to hub i file with specified granularity in seconds
		perl goodput_rx.pl modelDatalink.tr 1.0 $i $j > modelDatalink_goodput_$i\_$j.txt
		perl tcp_goodput.pl modelDatalink.tr $i $j >> modelDatalink.tex
	done
done


# Plot to PNG files non-empty throughput files from first hub and goodput to first node data per QoS
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES=`cat modelDatalink_throughput_1\_$j\.txt | wc -l`
	if [ $NUM_LINES -gt 1 ]
	then
		echo > gnuplotFL$j\.in
		echo "set xlabel \"Time (s)\"" >> gnuplotFL$j\.in
		echo "set ylabel \"bit/s\"" >> gnuplotFL$j\.in
		echo "set term png" >> gnuplotFL$j\.in
		echo "set output \"plotFL$j\.png\"" >> gnuplotFL$j\.in
		echo "plot \"modelDatalink_throughput_1_$j\.txt\" with lines title \"QoS $j throughput from hub 1\", \"modelDatalink_goodput_$FIRST_NODE\_$j\.txt\" with lines title \"QoS $j goodput to node $FIRST_NODE\"" >> gnuplotFL$j\.in
		gnuplot gnuplotFL$j\.in
	fi
done
# Interactive Plot of two first QoS
# gnuplot -e "set xlabel \"Time(s)\";set ylabel \"bit/s\";plot \"modelDatalink_throughput_1_0.txt\" with lines title \"QoS 0 throughput from hub 1\", \"modelDatalink_goodput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 goodput to node $FIRST_NODE\", \"modelDatalink_throughput_1_1.txt\" with lines title \"QoS 1 throughput from hub 1\", \"modelDatalink_goodput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 goodput to node $FIRST_NODE\" ; pause -1"

for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES=`cat modelDatalink_throughput_1\_$j\.txt | wc -l`
	if [ $NUM_LINES -gt 1 ]
	then
		echo "The figure~\ref{fig:thpFirstFL$j} shows for QoS $j the forward datalink throughput from first hub and the goodput at the first remote node." >> modelDatalink.tex
		echo "\begin{figure}[!h]" >> modelDatalink.tex
		echo "\centering" >> modelDatalink.tex
		echo "\includegraphics[width=\textwidth]{plotFL$j.png}" >> modelDatalink.tex
		echo "\caption{Throughput from first hub and goodput at first node for QoS $j.}" >> modelDatalink.tex
		echo "\label{fig:thpFirstFL$j}" >> modelDatalink.tex
		echo "\end{figure}" >> modelDatalink.tex
		echo "" >> modelDatalink.tex
	fi
done

# Plot to PNG file non-empty FL delay data
NUM_LINES_TOTAL=0
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES[j]=`cat modelDatalink_delay_$FIRST_NODE\_$j.txt | wc -l`
	if [ ${NUM_LINES[$j]} -gt 0 ]
	then
		NUM_LINES_TOTAL=$((NUM_LINES_TOTAL + 1))
	fi
done
if [ $NUM_LINES_TOTAL -gt 0 ]
then
	echo > gnuplotFL$NUM_FID\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotFL$NUM_FID\.in
	echo "set ylabel \"Time (s)\"" >> gnuplotFL$NUM_FID\.in
	echo "set yrange [0:]" >> gnuplotFL$NUM_FID\.in
	echo "set term png" >> gnuplotFL$NUM_FID\.in
	echo "set output \"plotFL$NUM_FID\.png\"" >> gnuplotFL$NUM_FID\.in
	echo "plot \"modelDatalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\" \\" >> gnuplotFL$NUM_FID\.in
	for (( j=1; j<$NUM_FID; j++ ))
	do
		if [ ${NUM_LINES[$j]} -gt 0 ]
		then
			echo ", \"modelDatalink_delay_$FIRST_NODE\_$j.txt\" with lines title \"QoS $j delay to first node\" \\" >> gnuplotFL$NUM_FID\.in
		fi
	done
# For 2 CoS
#	echo "plot \"modelDatalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"modelDatalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\"" >> gnuplotFL$NUM_FID\.in
	gnuplot gnuplotFL$NUM_FID\.in
	echo > gnuplotFLZoom$NUM_FID\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotFLZoom$NUM_FID\.in
	echo "set ylabel \"Time (s)\"" >> gnuplotFLZoom$NUM_FID\.in
	echo "set term png" >> gnuplotFLZoom$NUM_FID\.in
	echo "set output \"plotFLZoom$NUM_FID\.png\"" >> gnuplotFLZoom$NUM_FID\.in
	echo "plot \"modelDatalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\" \\" >> gnuplotFLZoom$NUM_FID\.in
	for (( j=1; j<$NUM_FID; j++ ))
	do
		if [ ${NUM_LINES[$j]} -gt 0 ]
		then
			echo ", \"modelDatalink_delay_$FIRST_NODE\_$j.txt\" with lines title \"QoS $j delay to first node\" \\" >> gnuplotFLZoom$NUM_FID\.in
		fi
	done
	gnuplot gnuplotFLZoom$NUM_FID\.in

	# Interactive Plot of two first CoS
	gnuplot -e "set xlabel \"Time(s)\";set ylabel \"Time(s)\";plot \"modelDatalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"modelDatalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\" ; pause -1"
fi

NUM_LINES_TOTAL=0
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES[j]=`cat modelDatalink_delay_$FIRST_NODE\_$j.txt | wc -l`
	if [ ${NUM_LINES[$j]} -gt 0 ]
	then
		NUM_LINES_TOTAL=$((NUM_LINES_TOTAL + 1))
	fi
done
if [ $NUM_LINES_TOTAL -gt 0 ]
then
	echo "The figures~\ref{fig:delayFirstFL} and~\ref{fig:delayFirstFLZoom} show the forward link delay per QoS of packets to the first remote node." >> modelDatalink.tex
	echo "\begin{figure}[!h]" >> modelDatalink.tex
	echo "\centering" >> modelDatalink.tex
	echo "\includegraphics[width=\textwidth]{plotFL$NUM_FID.png}" >> modelDatalink.tex
	echo "\caption{Forward link delay to first node per QoS.}" >> modelDatalink.tex
	echo "\label{fig:delayFirstFL}" >> modelDatalink.tex
	echo "\end{figure}" >> modelDatalink.tex
	echo "" >> modelDatalink.tex
	echo "\begin{figure}[!h]" >> modelDatalink.tex
	echo "\centering" >> modelDatalink.tex
	echo "\includegraphics[width=\textwidth]{plotFLZoom$NUM_FID.png}" >> modelDatalink.tex
	echo "\caption{Forward link delay to first node per QoS zoomed.}" >> modelDatalink.tex
	echo "\label{fig:delayFirstFLZoom}" >> modelDatalink.tex
	echo "\end{figure}" >> modelDatalink.tex
	echo "" >> modelDatalink.tex
fi

# Plot to PNG file non-emtpy throughput from first node and goodput to first hub data per QoS
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES=`cat modelDatalink_goodput_1\_$j\.txt | wc -l`
	if [ $NUM_LINES -gt 1 ]
	then
		echo > gnuplotRL$j\.in
		echo "set xlabel \"Time (s)\"" >> gnuplotRL$j\.in
		echo "set ylabel \"bit/s\"" >> gnuplotRL$j\.in
		echo "set term png" >> gnuplotRL$j\.in
		echo "set output \"plotRL$j\.png\"" >> gnuplotRL$j\.in
		echo "plot \"modelDatalink_throughput_$FIRST_NODE\_$j\.txt\" with lines title \"QoS $j throughput from first node\", \"modelDatalink_goodput_1_$j\.txt\" with lines title \"QoS $j goodput to hub 1\"" >> gnuplotRL$j\.in
		gnuplot gnuplotRL$j\.in
	fi
done
# Interactive Plot of two first QoS in the RL
# gnuplot -e "set xlabel \"Time(s)\";set ylabel \"bit/s\";plot \"modelDatalink_throughput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 throughput from first node\", \"modelDatalink_goodput_1_0.txt\" with lines title \"QoS 0 goodput to hub 1\", \"modelDatalink_throughput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 throughput from first node\", \"modelDatalink_goodput_1_1.txt\" with lines title \"QoS 1 goodput to hub 1\" ; pause -1"

gnuplot -e "set xlabel \"Time(s)\";set ylabel \"bit/s\";plot \"modelDatalink_throughput_1_0.txt\" with lines title \"QoS 0 throughput from hub 1\", \"modelDatalink_goodput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 goodput to node $FIRST_NODE\", \"modelDatalink_throughput_1_1.txt\" with lines title \"QoS 1 throughput from hub 1\", \"modelDatalink_goodput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 goodput to node $FIRST_NODE\", \"modelDatalink_throughput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 throughput from first node\", \"modelDatalink_goodput_1_0.txt\" with lines title \"QoS 0 goodput to hub 1\", \"modelDatalink_throughput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 throughput from first node\", \"modelDatalink_goodput_1_1.txt\" with lines title \"QoS 1 goodput to hub 1\" ; pause -1"

for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES=`cat modelDatalink_goodput_1\_$j\.txt | wc -l`
	if [ $NUM_LINES -gt 1 ]
	then
		echo "The figure~\ref{fig:thpFirstRL$j} shows for QoS $j the return datalink throughput from first node and the goodput at hub 1." >> modelDatalink.tex
		echo "\begin{figure}[!h]" >> modelDatalink.tex
		echo "\centering" >> modelDatalink.tex
		echo "\includegraphics[width=\textwidth]{plotRL$j.png}" >> modelDatalink.tex
		echo "\caption{Throughput from first node and goodput at hub 1 for QoS $j.}" >> modelDatalink.tex
		echo "\label{fig:thpFirstRL$j}" >> modelDatalink.tex
		echo "\end{figure}" >> modelDatalink.tex
		echo "" >> modelDatalink.tex
	fi
done

# Plot to PNG file RL delay data
NUM_LINES_TOTAL=0
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES[j]=`cat modelDatalink_delay_1\_$j.txt | wc -l`
	if [ ${NUM_LINES[$j]} -gt 0 ]
	then
		NUM_LINES_TOTAL=$((NUM_LINES_TOTAL + 1))
	fi
done
if [ $NUM_LINES_TOTAL -gt 0 ]
then
	echo > gnuplotRL$NUM_FID\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotRL$NUM_FID\.in
	echo "set ylabel \"Time (s)\"" >> gnuplotRL$NUM_FID\.in
	echo "set yrange [0:]" >> gnuplotRL$NUM_FID\.in
	echo "set term png" >> gnuplotRL$NUM_FID\.in
	echo "set output \"plotRL$NUM_FID\.png\"" >> gnuplotRL$NUM_FID\.in
	echo "plot \"modelDatalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\" \\" >> gnuplotRL$NUM_FID\.in
	for (( j=1; j<$NUM_FID; j++ ))
	do
		echo ", \"modelDatalink_delay_1_$j.txt\" with lines title \"QoS $j delay to hub 1\" \\" >> gnuplotRL$NUM_FID\.in
	done
	gnuplot gnuplotRL$NUM_FID\.in
	echo > gnuplotRLZoom$NUM_FID\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotRLZoom$NUM_FID\.in
	echo "set ylabel \"Time (s)\"" >> gnuplotRLZoom$NUM_FID\.in
	echo "set term png" >> gnuplotRLZoom$NUM_FID\.in
	echo "set output \"plotRLZoom$NUM_FID\.png\"" >> gnuplotRLZoom$NUM_FID\.in
	echo "plot \"modelDatalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\" \\" >> gnuplotRLZoom$NUM_FID\.in
	for (( j=1; j<$NUM_FID; j++ ))
	do
		echo ", \"modelDatalink_delay_1_$j.txt\" with lines title \"QoS $j delay to hub 1\" \\" >> gnuplotRLZoom$NUM_FID\.in
	done
	gnuplot gnuplotRLZoom$NUM_FID\.in
	# Interactive Plot of two first CoS
	gnuplot -e "set xlabel \"Time(s)\";set ylabel \"Time(s)\";plot \"modelDatalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\", \"modelDatalink_delay_1_1.txt\" with lines title \"QoS 1 delay to hub 1\" ; pause -1"
fi

# gnuplot -e "set xlabel \"Time(s)\";set ylabel \"Time(s)\";plot \"modelDatalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"modelDatalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\", \"modelDatalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\", \"modelDatalink_delay_1_1.txt\" with lines title \"QoS 1 delay to hub 1\" ; pause -1"

NUM_LINES_TOTAL=0
for (( j=0; j<$NUM_FID; j++ ))
do
	NUM_LINES[j]=`cat modelDatalink_delay_1\_$j.txt | wc -l`
	if [ ${NUM_LINES[$j]} -gt 0 ]
	then
		NUM_LINES_TOTAL=$((NUM_LINES_TOTAL + 1))
	fi
done
if [ $NUM_LINES_TOTAL -gt 0 ]
then
	echo "The figures~\ref{fig:delayFirstRL} and~\ref{fig:delayFirstRLZoom} show the return link delay per QoS of packets to hub 1." >> modelDatalink.tex
	echo "\begin{figure}[!h]" >> modelDatalink.tex
	echo "\centering" >> modelDatalink.tex
	echo "\includegraphics[width=\textwidth]{plotRL$NUM_FID.png}" >> modelDatalink.tex
	echo "\caption{Return link delay to hub 1 per QoS.}" >> modelDatalink.tex
	echo "\label{fig:delayFirstRL}" >> modelDatalink.tex
	echo "\end{figure}" >> modelDatalink.tex
	echo "" >> modelDatalink.tex
	echo "\begin{figure}[!h]" >> modelDatalink.tex
	echo "\centering" >> modelDatalink.tex
	echo "\includegraphics[width=\textwidth]{plotRLZoom$NUM_FID.png}" >> modelDatalink.tex
	echo "\caption{Return link delay to hub 1 per QoS zoomed.}" >> modelDatalink.tex
	echo "\label{fig:delayFirstRLZoom}" >> modelDatalink.tex
	echo "\end{figure}" >> modelDatalink.tex
	echo "" >> modelDatalink.tex
fi

echo "\begin{thebibliography}{1}" >> modelDatalink.tex
echo "\bibitem{Intro:ns2} T. Issariyakul, E. Hossain, \emph{Introduction to Network Simulator NS2}.\hskip 1em plus 0.5em minus 0.4em\relax Springer, 2008." >> modelDatalink.tex
echo "\end{thebibliography}" >> modelDatalink.tex
echo "\end{document}" >> modelDatalink.tex

pdflatex modelDatalink.tex

# Do it twice to fix references
pdflatex modelDatalink.tex

