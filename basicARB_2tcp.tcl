# Basic example of A---R---B, i.e. A and B computers are communicated through router R.
# http://intronetworks.cs.luc.edu/current/html/ns2.html#single-sender-throughput-experiments
# Link from A to R is assumed to be LAN, i.e. symmetric 1000 Mbit/s, 10 ms delay
# Link from R to B is assumed to be WAN with a certain bandwidth and delay that can be asymetric.
# First one upload TCP is done, then one TCP download, then simultaneous

if { $argc != 4 } {
	puts stderr {usage: ns basicARB_2tcp.tcl <R-B kbit/s> <B-R kbit/s> <R-B one-way delay ms> <B-R one-way delay ms> }
	puts stderr {e.g.:} 
	puts stderr {ns basicARB_2tcp.tcl 800 800 50 50}
	exit 1
}

set tx_capacity_R_B_kb [lindex $argv 0]
set tx_capacity_B_R_kb [lindex $argv 1]
set delay_R_B_ms [lindex $argv 2]
set delay_B_R_ms [lindex $argv 3]

set tx_capacity_R_B [expr $tx_capacity_R_B_kb]kb
set tx_capacity_B_R [expr $tx_capacity_B_R_kb]kb
set delay_R_B [expr $delay_R_B_ms]ms
set delay_B_R [expr $delay_B_R_ms]ms

set mtu 1500
# set mtu 1000
# set ack_size 52
# set ack_size 40
# set ack_size $mtu
# set ack_size [expr $mtu/3]
set ack_size [expr $mtu/5]

set tcp_initial_window_size 10
set tcp_window_size 65000
# 10 TCP packets are around 10 KB, which is the minimum queue size acceptable too

# set tcp_duration 1000
set tcp_duration 60
set time_margin [expr $tcp_duration*4]

# 125 = 1 kbyte (1000 bytes) / 8 bytes
set max_bytes_rx_per_tcp_R_B [expr $tcp_duration*125*$tx_capacity_R_B_kb]
set max_bytes_rx_per_tcp_B_R [expr $tcp_duration*125*$tx_capacity_B_R_kb]

puts "Simulating A---R---B with bottleneck R-B equal to $tx_capacity_R_B_kb kbit/s with $delay_R_B_ms ms delay and B-R with $tx_capacity_B_R_kb kbit/s and $delay_R_B_ms ms delay."

# Compute queue sizes according to the BDP rule
set queue_size_bytes_R_B [expr $tx_capacity_R_B_kb*($delay_R_B_ms + $delay_B_R_ms)/8]
set queue_size_bytes_B_R [expr $tx_capacity_B_R_kb*($delay_R_B_ms + $delay_B_R_ms)/8]
set queue_size_packets_R_B [expr $queue_size_bytes_R_B/$ack_size]
set queue_size_packets_B_R [expr $queue_size_bytes_B_R/$ack_size]
puts "Computed upload queue size R-->B [expr $queue_size_bytes_R_B/1000] kbytes and $queue_size_packets_R_B packets, assuming $ack_size bytes ACKs."
puts "Computed download queue size R<--B [expr $queue_size_bytes_B_R/1000] kbytes and $queue_size_packets_B_R packets, assuming $ack_size bytes ACKs."

if { $queue_size_packets_R_B < $tcp_initial_window_size } {
	set queue_size_packets_R_B $tcp_initial_window_size
	puts "Minimum queue size R-->B set to TCP initial window size in packets, at least, i.e. $queue_size_packets_R_B"
}

if { $queue_size_packets_B_R < $tcp_initial_window_size } {
	set queue_size_packets_B_R $tcp_initial_window_size
	puts "Minimum queue size R<--B set to TCP initial window size in packets, at least, i.e. $queue_size_packets_B_R"
}

#Create a simulator object
set ns [new Simulator]

#Open the nam file and the trace file
set nf [open basicARB_2tcp.nam w]
$ns namtrace-all $nf
set f [open basicARB_2tcp.tr w]
$ns trace-all $f

#Define a 'finish' procedure
proc finish {} {
        global ns nf f tcp0 tcp1 tcp2 tcp3 end0 end1 end2 end3 tcp_duration max_bytes_rx_per_tcp_R_B max_bytes_rx_per_tcp_B_R
        $ns flush-trace	
        close $nf		
        close $f
	set lastACK [$tcp0 set ack_]
        set lastSEQ [$tcp0 set maxseq_]
	set ACKed [$end0 set bytes_]
	set reTx [$tcp0 set nrexmitpack_]
        puts stdout "final ack: $lastACK, final seq num: $lastSEQ, $ACKed bytes transferred, ReTx Pkts: $reTx"
	puts "TCP upload link utilization during $tcp_duration s (%): [expr 100.0*$ACKed/$max_bytes_rx_per_tcp_R_B]"
	set lastACK [$tcp2 set ack_]
        set lastSEQ [$tcp2 set maxseq_]
	set ACKed [$end2 set bytes_]
	set reTx [$tcp2 set nrexmitpack_]
        puts stdout "final ack: $lastACK, final seq num: $lastSEQ, $ACKed bytes transferred, ReTx Pkts: $reTx"
	puts "TCP upload link utilization during $tcp_duration s (%): [expr 100.0*$ACKed/$max_bytes_rx_per_tcp_R_B]"
	# exec perl tcp_goodput.pl basicARB.tr 2 0
	set lastACK [$tcp1 set ack_]
        set lastSEQ [$tcp1 set maxseq_]
	set ACKed [$end1 set bytes_]
	set reTx [$tcp1 set nrexmitpack_]
        puts stdout "final ack: $lastACK, final seq num: $lastSEQ, $ACKed bytes transferred, ReTx Pkts: $reTx"
	puts "TCP download link utilization during $tcp_duration s (%): [expr 100.0*$ACKed/$max_bytes_rx_per_tcp_B_R]"
	set lastACK [$tcp3 set ack_]
        set lastSEQ [$tcp3 set maxseq_]
	set ACKed [$end3 set bytes_]
	set reTx [$tcp3 set nrexmitpack_]
        puts stdout "final ack: $lastACK, final seq num: $lastSEQ, $ACKed bytes transferred, ReTx Pkts: $reTx"
	puts "TCP download link utilization during $tcp_duration s (%): [expr 100.0*$ACKed/$max_bytes_rx_per_tcp_B_R]"
	# exec perl tcp_goodput.pl basicARB.tr 0 1
#	exec ./basicARB.sh
#	puts "Launching NAM..."
#	exec nam basicARB.nam &
	puts "Finished"
        exit 0
}

#Create the network nodes
set A [$ns node]
set R [$ns node]
set B [$ns node]

#Create a duplex link between the nodes A and R
# $ns duplex-link $A $R 1000Mb 10ms DropTail
$ns duplex-link $A $R 10Mb 50ms DropTail
#Create simplex links between R and B
$ns simplex-link $R $B $tx_capacity_R_B $delay_R_B DropTail
$ns simplex-link $B $R $tx_capacity_B_R $delay_B_R DropTail

# The queue sizes at $R are the computed BDP, with at minimum of three packets
$ns queue-limit $R $B $queue_size_packets_R_B
$ns queue-limit $B $R $queue_size_packets_B_R

# some hints for nam
# color packets of flow 0 red
$ns color 0 Red			
$ns duplex-link-op $A $R orient right
$ns duplex-link-op $R $B orient right
$ns duplex-link-op $R $B queuePos 0.5

# Create a TCP sending agent and attach it to A
# set tcp0 [new Agent/TCP/Reno]
set tcp0 [new Agent/TCP/Linux]
# make our one-and-only flow be flow 0
$tcp0 set class_ 0
$tcp0 set windowInit_ $tcp_initial_window_size
$tcp0 set window_ $tcp_window_size
$tcp0 set tcpip_base_hdr_size_ 40
$tcp0 set segsize_ [expr $mtu-[$tcp0 set tcpip_base_hdr_size_]]
$tcp0 set packetSize_ [expr $mtu-[$tcp0 set tcpip_base_hdr_size_]]
$ns attach-agent $A $tcp0

# Let's trace some variables
# $tcp0 attach $f
# $tcp0 tracevar cwnd_
# $tcp0 tracevar ssthresh_
# $tcp0 tracevar ack_
# $tcp0 tracevar maxseq_

#Create a TCP receive agent (a traffic sink) and attach it to B
set end0 [new Agent/TCPSink]
$ns attach-agent $B $end0

#Connect the traffic source with the traffic sink
$ns connect $tcp0 $end0  

#Schedule the connection data flow; start sending data at T=0, stop at T=tcp_duration
set myftp0 [new Application/FTP]
$myftp0 attach-agent $tcp0
$ns at 0.0 "$myftp0 start"
$ns at $tcp_duration "$myftp0 stop"

# Create a TCP sending agent and attach it to B
# set tcp1 [new Agent/TCP/Reno]
set tcp1 [new Agent/TCP/Linux]
# make our one-and-only flow be flow 1
$tcp1 set class_ 1
$tcp1 set windowInit_ $tcp_initial_window_size
$tcp1 set window_ $tcp_window_size
$tcp1 set tcpip_base_hdr_size_ 40
$tcp1 set segsize_ [expr $mtu-[$tcp1 set tcpip_base_hdr_size_]]
$tcp1 set packetSize_ [expr $mtu-[$tcp1 set tcpip_base_hdr_size_]]
$ns attach-agent $B $tcp1

# Let's trace some variables
# $tcp1 attach $f
# $tcp1 tracevar cwnd_
# $tcp1 tracevar ssthresh_
# $tcp1 tracevar ack_
# $tcp1 tracevar maxseq_

#Create a TCP receive agent (a traffic sink) and attach it to A
set end1 [new Agent/TCPSink]
$ns attach-agent $A $end1

#Connect the traffic source with the traffic sink
$ns connect $tcp1 $end1  

#Schedule the connection data flow; start at tcp_duration plus 15 s margin, stop tcp_duration seconds afterwards
set myftp1 [new Application/FTP]
$myftp1 attach-agent $tcp1
$ns at [expr $tcp_duration + $time_margin] "$myftp1 start"
$ns at [expr $tcp_duration*2 + $time_margin] "$myftp1 stop"

# Create a TCP sending agent and attach it to A
# set tcp2 [new Agent/TCP/Reno]
set tcp2 [new Agent/TCP/Linux]
# make our one-and-only flow be flow 2
# $tcp2 set class_ 2
$tcp2 set class_ 0
$tcp2 set windowInit_ $tcp_initial_window_size
$tcp2 set window_ $tcp_window_size
$tcp2 set tcpip_base_hdr_size_ 40
$tcp2 set segsize_ [expr $mtu-[$tcp2 set tcpip_base_hdr_size_]]
$tcp2 set packetSize_ [expr $mtu-[$tcp2 set tcpip_base_hdr_size_]]
$ns attach-agent $A $tcp2

# Let's trace some variables
# $tcp2 attach $f
# $tcp2 tracevar cwnd_
# $tcp2 tracevar ssthresh_
# $tcp2 tracevar ack_
# $tcp2 tracevar maxseq_

#Create a TCP receive agent (a traffic sink) and attach it to B
set end2 [new Agent/TCPSink]
$ns attach-agent $B $end2

#Connect the traffic source with the traffic sink
$ns connect $tcp2 $end2

#Schedule the connection data flow; start sending data at start and finish at stop
set myftp2 [new Application/FTP]
$myftp2 attach-agent $tcp2
$ns at [expr 2*($tcp_duration + $time_margin)] "$myftp2 start"
$ns at [expr 3*$tcp_duration + 2*$time_margin] "$myftp2 stop"

# Create a TCP sending agent and attach it to B
# set tcp3 [new Agent/TCP/Reno]
set tcp3 [new Agent/TCP/Linux]
# make our one-and-only flow be flow 3
# $tcp3 set class_ 3
$tcp3 set class_ 1
$tcp3 set windowInit_ $tcp_initial_window_size
$tcp3 set window_ $tcp_window_size
$tcp3 set tcpip_base_hdr_size_ 40
$tcp3 set segsize_ [expr $mtu-[$tcp3 set tcpip_base_hdr_size_]]
$tcp3 set packetSize_ [expr $mtu-[$tcp3 set tcpip_base_hdr_size_]]
$ns attach-agent $B $tcp3

# Let's trace some variables
# $tcp3 attach $f
# $tcp3 tracevar cwnd_
# $tcp3 tracevar ssthresh_
# $tcp3 tracevar ack_
# $tcp3 tracevar maxseq_

#Create a TCP receive agent (a traffic sink) and attach it to A
set end3 [new Agent/TCPSink]
$ns attach-agent $A $end3

#Connect the traffic source with the traffic sink
$ns connect $tcp3 $end3  

#Schedule the connection data flow; start at tcp_duration plus margin, stop tcp_duration seconds afterwards
set myftp3 [new Application/FTP]
$myftp3 attach-agent $tcp3
$ns at [expr 2*($tcp_duration + $time_margin)] "$myftp3 start"
$ns at [expr 3*$tcp_duration + 2*$time_margin] "$myftp3 stop"

$ns at [expr 3*($tcp_duration+$time_margin)] "finish"

#Run the simulation
$ns run
