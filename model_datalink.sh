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

echo "model_datatalink.sh $N_RLC $N_FLC $NUM_NODES $NUM_FID execution report" > model_datalink.txt

echo "\documentclass[a4paper, 11pt, twoside]{article}" > model_datalink.tex
# echo "\usepackage[latin1]{inputenc}" >> model_datalink.tex
echo "\usepackage{hyperref}" >> model_datalink.tex
echo "\usepackage{spreadtab}" >> model_datalink.tex
echo "\usepackage{color}" >> model_datalink.tex
echo "\usepackage{longtable}" >> model_datalink.tex
echo "\hypersetup{colorlinks=true,%" >> model_datalink.tex
echo "			citecolor=black,%" >> model_datalink.tex
echo "			filecolor=black,%" >> model_datalink.tex
echo "			linkcolor=black,%" >> model_datalink.tex
echo "			urlcolor=black}" >> model_datalink.tex
echo "\usepackage[pdftex]{graphicx}" >> model_datalink.tex
# echo "\author{David Fernández Piñas}" >> model_datalink.tex
echo "\author{David F. Pinas}" >> model_datalink.tex
echo "\title{Simulation of traffic over GEO satellite link}" >> model_datalink.tex
echo "\begin{document}" >> model_datalink.tex
echo "\maketitle" >> model_datalink.tex
echo "\section{Introduction}" >> model_datalink.tex
echo "Ns-2 is an event-driven simulator designed specifically for research in computer communication networks. Having been under constant investigation and enhancement for years since its inception in 1989, it now contains modules for numerous network components such as satellite links, transport layer protocols, applications, etc." >> model_datalink.tex
echo "" >> model_datalink.tex
echo "To investigate network performance, it allows using the Tcl scripting language to configure a network and observe results generated. Undoubtedly, it has become one of the most widely used network simulators~\cite{Intro:ns2}." >> model_datalink.tex
echo "In this report, it is evaluated the Quality of Service (QoS) achievable on a GEO bent pipe link by $NUM_FID CoS traffic corresponding to the execution of model\_datalink.tcl script." >> model_datalink.tex
echo "\section{Model configuration}" >> model_datalink.tex
echo "Simulation of $NUM_NODES remote nodes generating and receiving $NUM_FID CoS traffic over a SATCOM link with $N_RLC return link carriers and $N_FLC forward link carriers of a given capacity." >> model_datalink.tex
echo "" >> model_datalink.tex
echo "The simulation output is the trace file model\_datalink.tr." >> model_datalink.tex
echo "Run nam model\_datalink.nam to see the network topology." >> model_datalink.tex
echo "\section{Execution results}" >> model_datalink.tex
echo "Forward link packets counting is summarized in table~\ref{tab:FLpackets}." >> model_datalink.tex
# echo "\begin{table}[!h]" >> model_datalink.tex
echo "\begin{longtable}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> model_datalink.tex
# echo "\centering" >> model_datalink.tex
# echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\textbf{Flow ID} & \textbf{Src} & \textbf{Dest} & \textbf{\#Packets} & \textbf{\#Bytes} & \textbf{\#Drops} & \textbf{PLR} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
# FL packet counting:
# Measure packets sent from hubs per fid
for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk model_datalink.tr >> model_datalink.tex
	done
done
# Measure packets sent from satellite to access nodes
for (( i=$((1 + N_FLC)); i<$FIRST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=0 -v dest=$i -f measure-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v orig=0 -v dest=$i -f measure-loss.awk model_datalink.tr >> model_datalink.tex
	done
done
# Measure packets received at remotes
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk model_datalink.tr >> model_datalink.tex
	done
done
# echo "\end{tabular}" >> model_datalink.tex
# echo "\end{table}" >> model_datalink.tex
echo "\caption{FL packet counting}" >> model_datalink.tex
echo "\label{tab:FLpackets}" >> model_datalink.tex
echo "\end{longtable}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "Return link packets counting is summarized in table~\ref{tab:RLpackets}." >> model_datalink.tex
# echo "\begin{table}[!h]" >> model_datalink.tex
echo "\begin{longtable}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> model_datalink.tex
# echo "\centering" >> model_datalink.tex
# echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1cm}|p{1.75cm}|p{1.75cm}|p{1.5cm}|p{1cm}|}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\textbf{Flow ID} & \textbf{Src} & \textbf{Dest} & \textbf{\#Packets} & \textbf{\#Bytes} & \textbf{\#Drops} & \textbf{PLR} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
# RL packet counting:
# Measure packets sent by remotes
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v orig=$i -f measure-tx-loss.awk model_datalink.tr >> model_datalink.tex
	done
done
# Measure packets received at hubs
for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v dest=$i -f measure-rx-loss.awk model_datalink.tr >> model_datalink.tex
	done	
done
# Measure packets sent from access nodes to satellite
for (( i=$((1 + N_FLC)); i<$FIRST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
#		gawk -v fid=$j -v orig=$i -v dest=0 -f measure-loss.awk model_datalink.tr >> model_datalink.txt
		gawk -v fid=$j -v orig=$i -v dest=0 -f measure-loss.awk model_datalink.tr >> model_datalink.tex
	done
done
# echo "\end{tabular}" >> model_datalink.tex
# echo "\end{table}" >> model_datalink.tex
echo "\caption{RL packet counting}" >> model_datalink.tex
echo "\label{tab:RLpackets}" >> model_datalink.tex
echo "\end{longtable}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "Forward link packets average delay is summarized in table~\ref{tab:FLdelay}." >> model_datalink.tex
echo "\begin{table}[!h]" >> model_datalink.tex
echo "\caption{FL packets delay}" >> model_datalink.tex
echo "\label{tab:FLdelay}" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\STautoround{6}" >> model_datalink.tex
echo "\begin{spreadtab}{{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|}}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "@ \textbf{Flow ID} & @ \textbf{Dest} & @ \textbf{Average delay (s)} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
# Measure end-to-end delay of packets directed to nodes per QoS
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		gawk -v dest=$i -v fid=$j -f measure-any-fid-delay-ip.awk model_datalink.tr > model_datalink_delay_$i\_$j.txt
		# Now get the average of the previously measured delays		
		gawk -v dest=$i -v fid=$j -f average_delay.awk model_datalink_delay_$i\_$j.txt >> model_datalink.tex
	done
done
echo "a2 & @ All & (c`seq -s +c 2 2 $((2 * NUM_NODES))`)/$NUM_NODES \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "a3 & @ All & (c`seq -s +c 3 2 $((1 + 2 * NUM_NODES))`)/$NUM_NODES \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\end{spreadtab}" >> model_datalink.tex
echo "\end{table}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "Return link packets average delay is summarized in table~\ref{tab:RLdelay}." >> model_datalink.tex
echo "\begin{table}[!h]" >> model_datalink.tex
echo "\caption{RL packets delay}" >> model_datalink.tex
echo "\label{tab:RLdelay}" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{Average delay (s)} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
# Measure end-to-end delay of packets directed to hubs per QoS
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		gawk -v dest=$i -v fid=$j -f measure-any-fid-delay-ip.awk model_datalink.tr > model_datalink_delay_$i\_$j.txt
		# Now get the average of the previously measured delays		
		gawk -v dest=$i -v fid=$j -f average_delay.awk model_datalink_delay_$i\_$j.txt >> model_datalink.tex
	done
done
echo "\end{tabular}" >> model_datalink.tex
echo "\end{table}" >> model_datalink.tex
echo "" >> model_datalink.tex
# Now get the percentile 95 and 99.9 of previously measured delays
echo "Forward link packets delay percentiles are summarized in table~\ref{tab:FLdelay2}." >> model_datalink.tex
echo "\begin{table}[!h]" >> model_datalink.tex
echo "\caption{FL packets delay percentiles 95 and 99.9}" >> model_datalink.tex
echo "\label{tab:FLdelay2}" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|p{2.25cm}|}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{TD95 (s)} & \textbf{TD99.9 (s)} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		perl percentile_tex_table_row.pl model_datalink_delay_$i\_$j.txt 1 $j $i 95 99.9 >> model_datalink.tex		
	done
done
echo "\end{tabular}" >> model_datalink.tex
echo "\end{table}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "Return link packets delay percentiles are summarized in table~\ref{tab:RLdelay2}." >> model_datalink.tex
echo "\begin{table}[!h]" >> model_datalink.tex
echo "\caption{RL packets delay percentiles 95 and 99.9}" >> model_datalink.tex
echo "\label{tab:RLdelay2}" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\begin{tabular}{|p{1.75cm}|p{0.75cm}|p{1.75cm}|p{2.25cm}|}" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
echo "\textbf{Flow ID} & \textbf{Dest} & \textbf{TD95 (s)} & \textbf{TD99.9 (s)} \\\\" >> model_datalink.tex
echo "\hline" >> model_datalink.tex
# Measure end-to-end delay of packets directed to hubs per QoS
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do		
		perl percentile_tex_table_row.pl model_datalink_delay_$i\_$j.txt 1 $j $i 95 99.9 >> model_datalink.tex		
	done
done
echo "\end{tabular}" >> model_datalink.tex
echo "\end{table}" >> model_datalink.tex
echo "" >> model_datalink.tex

# Get the percentile 95 and 99 of web durations
# perl percentile.pl web_durations.txt 1 95 >> model_datalink.txt
# perl percentile.pl web_durations.txt 1 99.9 >> model_datalink.txt

for (( i=1; i<=$N_FLC; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j throughput from hub i file with specified granularity in seconds
		perl throughput_tx.pl model_datalink.tr 1 $i $j > model_datalink_throughput_$i\_$j.txt
	done
done
for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j goodput to node i file with specified granularity in seconds
		perl goodput_rx.pl model_datalink.tr 1 $i $j > model_datalink_goodput_$i\_$j.txt
	done
done

for (( i=$FIRST_NODE; i<=$LAST_NODE; i++ ))
do	
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j throughput from node i file with specified granularity in seconds
		perl throughput_tx.pl model_datalink.tr 1 $i $j > model_datalink_throughput_$i\_$j.txt
	done
done
for (( i=1; i<=$N_FLC; i++ ))
do
	for (( j=0; j<$NUM_FID; j++ ))
	do
		# Create fid j goodput to hub i file with specified granularity in seconds
		perl goodput_rx.pl model_datalink.tr 1 $i $j > model_datalink_goodput_$i\_$j.txt
	done
done


# Plot to PNG file throughput from first hub and goodput to first node data per QoS
for (( j=0; j<$NUM_FID; j++ ))
do
	echo > gnuplotFL$j\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotFL$j\.in
	echo "set ylabel \"bits/s\"" >> gnuplotFL$j\.in
	echo "set term png" >> gnuplotFL$j\.in
	echo "set output \"plotFL$j\.png\"" >> gnuplotFL$j\.in
	echo "plot \"model_datalink_throughput_1_$j\.txt\" with lines title \"QoS $j throughput from hub 1\", \"model_datalink_goodput_$FIRST_NODE\_$j\.txt\" with lines title \"QoS $j goodput to node $FIRST_NODE\"" >> gnuplotFL$j\.in
	gnuplot gnuplotFL$j\.in
done
# Interactive Plot of two first QoS
gnuplot -e "plot \"model_datalink_throughput_1_0.txt\" with lines title \"QoS 0 throughput from hub 1\", \"model_datalink_goodput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 goodput to node $FIRST_NODE\", \"model_datalink_throughput_1_1.txt\" with lines title \"QoS 1 throughput from hub 1\", \"model_datalink_goodput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 goodput to node $FIRST_NODE\" ; pause -1"

for (( j=0; j<$NUM_FID; j++ ))
do
	echo "The figure~\ref{fig:thpFirstFL$j} shows for QoS $j the forward datalink throughput from first hub and the goodput at the first remote node." >> model_datalink.tex
	echo "\begin{figure}[!h]" >> model_datalink.tex
	echo "\centering" >> model_datalink.tex
	echo "\includegraphics[width=\textwidth]{plotFL$j.png}" >> model_datalink.tex
	echo "\caption{Throughput from first hub and goodput at first node for QoS $j.}" >> model_datalink.tex
	echo "\label{fig:thpFirstFL$j}" >> model_datalink.tex
	echo "\end{figure}" >> model_datalink.tex
	echo "" >> model_datalink.tex
done

# Plot to PNG file FL delay data
echo > gnuplotFL$NUM_FID\.in
echo "set xlabel \"Time (s)\"" >> gnuplotFL$NUM_FID\.in
echo "set ylabel \"Time (s)\"" >> gnuplotFL$NUM_FID\.in
echo "set yrange [0:]" >> gnuplotFL$NUM_FID\.in
echo "set term png" >> gnuplotFL$NUM_FID\.in
echo "set output \"plotFL$NUM_FID\.png\"" >> gnuplotFL$NUM_FID\.in
echo "plot \"model_datalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"model_datalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\"" >> gnuplotFL$NUM_FID\.in
gnuplot gnuplotFL$NUM_FID\.in
echo > gnuplotFLZoom$NUM_FID\.in
echo "set xlabel \"Time (s)\"" >> gnuplotFLZoom$NUM_FID\.in
echo "set ylabel \"Time (s)\"" >> gnuplotFLZoom$NUM_FID\.in
echo "set term png" >> gnuplotFLZoom$NUM_FID\.in
echo "set output \"plotFLZoom$NUM_FID\.png\"" >> gnuplotFLZoom$NUM_FID\.in
echo "plot \"model_datalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"model_datalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\"" >> gnuplotFLZoom$NUM_FID\.in
gnuplot gnuplotFLZoom$NUM_FID\.in
# Interactive Plot
gnuplot -e "plot \"model_datalink_delay_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 delay to first node\", \"model_datalink_delay_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 delay to first node\" ; pause -1"

echo "The figures~\ref{fig:delayFirstFL} and~\ref{fig:delayFirstFLZoom} show the forward link delay per QoS of packets to the first remote node." >> model_datalink.tex
echo "\begin{figure}[!h]" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\includegraphics[width=\textwidth]{plotFL$NUM_FID.png}" >> model_datalink.tex
echo "\caption{Forward link delay to first node per QoS.}" >> model_datalink.tex
echo "\label{fig:delayFirstFL}" >> model_datalink.tex
echo "\end{figure}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "\begin{figure}[!h]" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\includegraphics[width=\textwidth]{plotFLZoom$NUM_FID.png}" >> model_datalink.tex
echo "\caption{Forward link delay to first node per QoS zoomed.}" >> model_datalink.tex
echo "\label{fig:delayFirstFLZoom}" >> model_datalink.tex
echo "\end{figure}" >> model_datalink.tex
echo "" >> model_datalink.tex

# Plot to PNG file throughput from first node and goodput to first hub data per QoS
for (( j=0; j<$NUM_FID; j++ ))
do
	echo > gnuplotRL$j\.in
	echo "set xlabel \"Time (s)\"" >> gnuplotRL$j\.in
	echo "set ylabel \"bits/s\"" >> gnuplotRL$j\.in
	echo "set term png" >> gnuplotRL$j\.in
	echo "set output \"plotRL$j\.png\"" >> gnuplotRL$j\.in
	echo "plot \"model_datalink_throughput_$FIRST_NODE\_$j\.txt\" with lines title \"QoS $j throughput from first node\", \"model_datalink_goodput_1_$j\.txt\" with lines title \"QoS $j goodput to hub 1\"" >> gnuplotRL$j\.in
	gnuplot gnuplotRL$j\.in
done
# Interactive Plot of two first QoS in the RL
gnuplot -e "plot \"model_datalink_throughput_$FIRST_NODE\_0.txt\" with lines title \"QoS 0 throughput from first node\", \"model_datalink_goodput_1_0.txt\" with lines title \"QoS 0 goodput to hub 1\", \"model_datalink_throughput_$FIRST_NODE\_1.txt\" with lines title \"QoS 1 throughput from first node\", \"model_datalink_goodput_1_1.txt\" with lines title \"QoS 1 goodput to hub 1\" ; pause -1"

for (( j=0; j<$NUM_FID; j++ ))
do
	echo "The figure~\ref{fig:thpFirstRL$j} shows for QoS $j the return datalink throughput from first node and the goodput at hub 1." >> model_datalink.tex
	echo "\begin{figure}[!h]" >> model_datalink.tex
	echo "\centering" >> model_datalink.tex
	echo "\includegraphics[width=\textwidth]{plotRL$j.png}" >> model_datalink.tex
	echo "\caption{Throughput from first node and goodput at hub 1 for QoS $j.}" >> model_datalink.tex
	echo "\label{fig:thpFirstRL$j}" >> model_datalink.tex
	echo "\end{figure}" >> model_datalink.tex
	echo "" >> model_datalink.tex
done

# Plot to PNG file RL delay data
echo > gnuplotRL$NUM_FID\.in
echo "set xlabel \"Time (s)\"" >> gnuplotRL$NUM_FID\.in
echo "set ylabel \"Time (s)\"" >> gnuplotRL$NUM_FID\.in
echo "set yrange [0:]" >> gnuplotRL$NUM_FID\.in
echo "set term png" >> gnuplotRL$NUM_FID\.in
echo "set output \"plotRL$NUM_FID\.png\"" >> gnuplotRL$NUM_FID\.in
echo "plot \"model_datalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\", \"model_datalink_delay_1_1.txt\" with lines title \"QoS 1 delay to hub 1\"" >> gnuplotRL$NUM_FID\.in
gnuplot gnuplotRL$NUM_FID\.in
echo > gnuplotRLZoom$NUM_FID\.in
echo "set xlabel \"Time (s)\"" >> gnuplotRLZoom$NUM_FID\.in
echo "set ylabel \"Time (s)\"" >> gnuplotRLZoom$NUM_FID\.in
echo "set term png" >> gnuplotRLZoom$NUM_FID\.in
echo "set output \"plotRLZoom$NUM_FID\.png\"" >> gnuplotRLZoom$NUM_FID\.in
echo "plot \"model_datalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\", \"model_datalink_delay_1_1.txt\" with lines title \"QoS 1 delay to hub 1\"" >> gnuplotRLZoom$NUM_FID\.in
gnuplot gnuplotRLZoom$NUM_FID\.in
# Interactive Plot
gnuplot -e "plot \"model_datalink_delay_1_0.txt\" with lines title \"QoS 0 delay to hub 1\", \"model_datalink_delay_1_1.txt\" with lines title \"QoS 1 delay to hub 1\" ; pause -1"

echo "The figures~\ref{fig:delayFirstRL} and~\ref{fig:delayFirstRLZoom} show the return link delay per QoS of packets to hub 1." >> model_datalink.tex
echo "\begin{figure}[!h]" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\includegraphics[width=\textwidth]{plotRL$NUM_FID.png}" >> model_datalink.tex
echo "\caption{Return link delay to hub 1 per QoS.}" >> model_datalink.tex
echo "\label{fig:delayFirstRL}" >> model_datalink.tex
echo "\end{figure}" >> model_datalink.tex
echo "" >> model_datalink.tex
echo "\begin{figure}[!h]" >> model_datalink.tex
echo "\centering" >> model_datalink.tex
echo "\includegraphics[width=\textwidth]{plotRLZoom$NUM_FID.png}" >> model_datalink.tex
echo "\caption{Return link delay to hub 1 per QoS zoomed.}" >> model_datalink.tex
echo "\label{fig:delayFirstRLZoom}" >> model_datalink.tex
echo "\end{figure}" >> model_datalink.tex
echo "" >> model_datalink.tex

echo "\begin{thebibliography}{1}" >> model_datalink.tex
echo "\bibitem{Intro:ns2} T. Issariyakul, E. Hossain, \emph{Introduction to Network Simulator NS2}.\hskip 1em plus 0.5em minus 0.4em\relax Springer, 2008." >> model_datalink.tex
echo "\end{thebibliography}" >> model_datalink.tex
echo "\end{document}" >> model_datalink.tex

pdflatex model_datalink.tex

# Do it twice to fix references
pdflatex model_datalink.tex

