##
## Network Topology of N hubs that can be connected each one to one and only one of M possible gateway nodes
## connected in ring intermittently following a connectivity matrix (N <= M)
##
## Simulated topology consists of N hubs connected to N gateway with a 150 kbit/s full duplex link.
##
## The M possible nodes are connected intermitently in ring, following a connectivity matrix, in a half-duplex way.
## The connectivity matrix period is equal to M (number of nodes) timeslots of timeslot duration (40 s).
## Each timeslot there are two uptime periods that pairs of nodes A <-> B can connect each other in each direction.
## The first part of timeslot A -> B, then A <- B. 
## The link rate is 120 kbit/s and there are two 14.5 s connections possible in each direction each 40 s.
##
## There are ping agents at the hubs and at each node to characterize the network latency.
## First each node pings each hub, then each hub pings to each node.
## So, if M nodes have to ping N hubs M*N pings are sent in M*N timeslots. Then N hubs send N*M pings to nodes.
## In total 2*M*N pings are sent to characterize network latency in 2*M*N timeslots.
## The connectivity matrix needs to be repeated 2*N times.
## 
## A VoIP could be established between any hub and any node.
## An FTP transfer can be done between any node and any hub.
##
## References: http://intronetworks.cs.luc.edu/current/html/ns2.html
## https://www.isi.edu/nsnam/ns/tutorial/nsscript3.html

set pingPacketSize 64
set pingPacketSize2 1064
set pingFid 100
set pingPrio 0

set mss 1460

set timeslot 40.0
set upTime 14.5
set linkSetupTime [expr ($timeslot - $upTime*2)/2]

# set ber 1e-6
set ber 0.0
set per 0.0

set bw1 150kb
set bw2 120kb

# The delay in the links depends on the distance between nodes and the speed of light in vaccuum: 299792 km/h
# Worst case distance estimated between a hub and a node: 30000 km => 100 ms
# Worst case distance between hub and node: 28102 km => 94 ms
# Worst case distance measured between nodes 59205 km => 197.5 ms

set opt(nodes)      	4                       ;# number of nodes
set opt(hubs)      	1                       ;# number of hubs

set opt(time_btw_pkts)   $timeslot		  ;# seconds

set latencyHubNode 94ms
set latencyBtwNodes 197.5ms

set startpingtime $linkSetupTime
set startime 1.0

set ns [new Simulator]

# Enable dynamic routing distance vector protocol
$ns rtproto DV

# Hubs
for {set j 0} {$j < $opt(hubs)} {incr j} {
	set hub($j) [$ns node]
	puts "hub($j)"
}
# Nodes
for {set i 0} {$i < $opt(nodes)} {incr i} {
	set n($i) [$ns node]
	puts "node($i)"
}
# So, subtract number of hubs to node number to get node index

set f [open NHubsToMNodesInRing.tr w]
$ns trace-all $f
set nf [open NHubsToMNodesInRing.nam w]
$ns namtrace-all $nf

# Any hub can be potentially connected to any node (only one) at any time (scheduled contact plan)
# And any node can be connected to any hub, but only to one.
for {set j 0} {$j < $opt(hubs)} {incr j} {
	for {set i 0} {$i < $opt(nodes)} {incr i} {
		$ns duplex-link $hub($j) $n($i) $bw1 $latencyHubNode DropTail
		puts "duplex link from hub($j) to node($i)"
		# Add an error model to the link from node to hub
		set emIndex [expr $i + $j*$opt(nodes)]
		set emHubNode($emIndex) [new ErrorModel]
		$emHubNode($emIndex) unit byte
		# Byte error rate = 1 - (1-BER)^8
		$emHubNode($emIndex) set rate_ [expr 1-pow((1-$ber),8)]
		# $emHubNode($emIndex) unit pkt
		# $emHubNode($emIndex) set rate_ $per
		$emHubNode($emIndex) ranvar [new RandomVariable/Uniform]
		$emHubNode($emIndex) drop-target [new Agent/Null]
		$ns link-lossmodel $emHubNode($emIndex) $n($i) $hub($j)
		# Add an error model to the link from hub to node
		set emIndex [expr $i + $j*$opt(nodes)]
		set emNodeHub($emIndex) [new ErrorModel]
		$emNodeHub($emIndex) unit byte
		# Byte error rate = 1 - (1-BER)^8
		$emNodeHub($emIndex) set rate_ [expr 1-pow((1-$ber),8)]
		# $emNodeHub($emIndex) unit pkt
		# $emNodeHub($emIndex) set rate_ $per
		$emNodeHub($emIndex) ranvar [new RandomVariable/Uniform]
		$emNodeHub($emIndex) drop-target [new Agent/Null]
		$ns link-lossmodel $emNodeHub($emIndex) $hub($j) $n($i)
	}
}

# Each GW can be connected to each other using simplex links. 
# The number of links that can be established between n nodes is N=n(n-1)/2
# The links between GWs are half-duplex and are active only 14.5 s in each direction each 40 s.
for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j [expr $i+1]} {$j < $opt(nodes)} {incr j} {
		$ns simplex-link $n($i) $n($j) $bw2 $latencyBtwNodes DropTail
		puts "simplex link from node($i) to node($j)"
		$ns simplex-link $n($j) $n($i) $bw2 $latencyBtwNodes DropTail
		puts "simplex link from node($j) to node($i)"
		# Add an error model to the link from node i to node j
		set emIndex [expr $j + $i*$opt(nodes)]
		set emAB($emIndex) [new ErrorModel]
		$emAB($emIndex) unit byte
		# Byte error rate = 1 - (1-BER)^8
		$emAB($emIndex) set rate_ [expr 1-pow((1-$ber),8)]
		# $emAB($emIndex) unit pkt
		# $emAB($emIndex) set rate_ $per
		$emAB($emIndex) ranvar [new RandomVariable/Uniform]
		$emAB($emIndex) drop-target [new Agent/Null]
		$ns link-lossmodel $emAB($emIndex) $n($i) $n($j)
		# Add an error model to the link from node j to node i
		set emIndex [expr $j + $i*$opt(nodes)]
		set emBA($emIndex) [new ErrorModel]
		$emBA($emIndex) unit byte
		# Byte error rate = 1 - (1-BER)^8
		$emBA($emIndex) set rate_ [expr 1-pow((1-$ber),8)]
		# $emBA($emIndex) unit pkt
		# $emBA($emIndex) set rate_ $per
		$emBA($emIndex) ranvar [new RandomVariable/Uniform]
		$emBA($emIndex) drop-target [new Agent/Null]
		$ns link-lossmodel $emBA($emIndex) $n($j) $n($i)
		# Setup initial connectivity between gateways (all down)
		$ns rtmodel-at [expr $startime] down $n($i) $n($j)
		$ns rtmodel-at [expr $startime] down $n($j) $n($i)
	}
}
# $ns duplex-link-op $n0 $n1 orient down
# $ns duplex-link-op $n0 $n2 orient left

# $ns duplex-link-op $n0 $n1 queuePos 0.5

#$ns trace-queue $n0 $n1 $f

# Setup contact schedule of hub to GWs. 
# Let's assume always hub j connected to node j.
for {set j 0} {$j < $opt(hubs)} {incr j} {
	for {set i 0} {$i < $opt(nodes)} {incr i} {
		if { $i != $j } {
			$ns rtmodel-at [expr $startime] down $n($i) $hub($j)
		}
	}
}

set currentTime $startpingtime

# Connectivity matrix for M=4 nodes.
# TODO: configure opt nodes and these connections from connectivity matrix txt file.
if { $opt(nodes) == 4 } {
	# Assuming permanent connectivity among GWs

	for {set i 0} { $i < [expr 2*$opt(hubs)] } {incr i} {
		# Timeslot 1
		# Connections up: [ 01 -> 04 -> 02 -> 03 -> 01 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(0)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(0)
		# Connections up: [ 01 <- 04 <- 02 <- 03 <- 01 ] 
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(0)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(2)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(0)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(2)

		# Timeslot 2
		# Connections up: [ 01 -> 03 -> 02 -> 04 -> 01 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(0)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(0)
		# Connections up: [ 01 <- 03 <- 02 <- 04 <- 01 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(3)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(3)

		# Timeslot 3
		# Connections up: [ 02 -> 01 -> 03 -> 04 -> 02 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(0)
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(1)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(0)
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(1)
		# Connections up: [ 02 <- 01 <- 03 <- 04 <- 02 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(3)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(3)

		# Timeslot 4
		# Connections up: [ 02 -> 04 -> 03 -> 01 -> 02 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(1)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(0)
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(1)
		# Connections up: [ 02 <- 04 <- 03 <- 01 <- 02 ]
		set currentTime [expr $currentTime + $linkSetupTime]
		$ns rtmodel-at [expr $currentTime] up $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] up $n(2) $n(3)
		$ns rtmodel-at [expr $currentTime] up $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] up $n(1) $n(0)
		# Connections down:
		set currentTime [expr $currentTime + $upTime]
		$ns rtmodel-at [expr $currentTime] down $n(3) $n(1)
		$ns rtmodel-at [expr $currentTime] down $n(2) $n(3)
		$ns rtmodel-at [expr $currentTime] down $n(0) $n(2)
		$ns rtmodel-at [expr $currentTime] down $n(1) $n(0)
	}

} else {
	puts "Error: Invalid number of nodes $opt(nodes). No connectivity matrix specified for this case."
	exit
}

set stoptime $currentTime
set stoppingtime $currentTime
set endtime [ expr $currentTime + $linkSetupTime ]

puts "Simulating $endtime s"

set num_pings_tx 0
set num_pings_rx 0
set maxrtt 0
set minrtt 1e9

set last_arrival(all) 0

# $defaultRNG seed 0
# set arrival_ [new RandomVariable/Exponential]
# $arrival_ set avg_ $opt(time_btw_pkts)

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns num_pings_rx num_pings_tx maxrtt minrtt currsrcnode currdstnode last_arrival bp opt timeslot stoppingtime
	$self instvar node_
	set pingrxtime [$ns now]
	set currsrcnode [$node_ id]
	set currdstnode $from
	if { $currsrcnode > $currdstnode } {
		# This is a ping performed from a node to a hub
		set nodeSrcIndex [ expr $currsrcnode - $opt(hubs)]
		set nodeDstIndex -1
		set bpIndexNode [expr $currdstnode + $nodeSrcIndex*2*$opt(hubs) ]
		set bpIndexHub [expr $currdstnode + $nodeSrcIndex*2*$opt(hubs) + 1 ]
		puts "t=$pingrxtime: ping agent $bpIndexNode at ns-2 node $currsrcnode (node $nodeSrcIndex) received ping answer from \
		ping agent $bpIndexHub at hub $currdstnode, with round-trip-time $rtt ms."
		set nodeSrcIndex [expr $nodeSrcIndex + 1]
		set currsrcnode [expr $nodeSrcIndex + $opt(hubs)]
		if { $nodeSrcIndex == $opt(nodes) } {
			set nodeSrcIndex 0
			set currsrcnode [expr $nodeSrcIndex + $opt(hubs)]
			set currdstnode [expr $currdstnode + 1]
			if { $currdstnode == $opt(hubs) } {
				# All nodes have ping all hubs, so now hubs ping nodes
				set currsrcnode 0
				set currdstnode $opt(hubs)
			}
		}
	} else {
		# This is a ping performed from a hub to a node
		set nodeSrcIndex -1
		set nodeDstIndex [ expr $currdstnode - $opt(hubs)]
		set bpIndexNode [expr $currsrcnode + $nodeDstIndex*2*$opt(hubs) ]
		set bpIndexHub [expr $currsrcnode + $nodeDstIndex*2*$opt(hubs) + 1 ]
		puts "t=$pingrxtime: ping agent $bpIndexHub at hub $currsrcnode received ping answer from \
		ping agent $bpIndexNode at ns-2 node $currdstnode (node $nodeDstIndex), with round-trip-time $rtt ms."
		set nodeDstIndex [expr $nodeDstIndex + 1]
		set currdstnode [expr $nodeDstIndex + $opt(hubs)]
		if { $nodeDstIndex == $opt(nodes) } {
			set nodeDstIndex 0
			set currdstnode [expr $nodeDstIndex + $opt(hubs)]
			set currsrcnode [expr $currsrcnode + 1]
			if { $currsrcnode == $opt(hubs) } {
				# All hubs have ping all nodes, so now nodes ping hubs
				set currdstnode 0
				set currsrcnode $opt(hubs)
			}
		}
	}
	set num_pings_rx [expr $num_pings_rx + 1]
	if { $rtt > $maxrtt } {
		set maxrtt $rtt
	}
	if { $rtt < $minrtt } {
		set minrtt $rtt
	}
	# Program the next sending of a ping (see, e.g. wireless-net-grid2.tcl)
	set last_arrival(all) $pingrxtime
	# Compute the next timeslot to send a ping
	set numTimeSlots [expr floor($pingrxtime / $timeslot) ]
	set numTimeSlots [expr $numTimeSlots + 1]
#	set startpingtime [expr $last_arrival(all) + $opt(time_btw_pkts)]
	set startpingtime [expr $numTimeSlots * $timeslot]
	if { $startpingtime < $stoppingtime } {
		if { $currsrcnode > $currdstnode } {
			# This is a ping performed from a node to a hub
			set nodeSrcIndex [ expr $currsrcnode - $opt(hubs)]
			set bpIndexNode [expr $currdstnode + $nodeSrcIndex*2*$opt(hubs) ]
			set bpIndexHub [expr $currdstnode + $nodeSrcIndex*2*$opt(hubs) + 1 ]
			set bpindex $bpIndexNode
			puts "t=$startpingtime s: ping agent $bpIndexNode at ns-2 node $currsrcnode (node $nodeSrcIndex) will send ping request to \
			ping agent $bpIndexHub at hub $currdstnode."
		} else {
			# This is a ping performed from a hub to a node
			set nodeDstIndex [ expr $currdstnode - $opt(hubs)]
			set bpIndexNode [expr $currsrcnode + $nodeDstIndex*2*$opt(hubs) ]
			set bpIndexHub [expr $currsrcnode + $nodeDstIndex*2*$opt(hubs) + 1 ]
			set bpindex $bpIndexHub
			puts "t=$startpingtime s: ping agent $bpIndexHub at hub $currsrcnode will send ping request to \
			ping agent $bpIndexNode at ns-2 node $currdstnode (node $nodeDstIndex)."
		}
		$ns at $startpingtime "$bp($bpindex) send"
		set num_pings_tx [expr $num_pings_tx + 1]
		# puts "t = $startpingtime s: ping agent $bpindex at ns-2 node $currsrcnode will send [$bp($bpindex) set packetSize_] bytes ping request to ns-2 node $currdstnode."
	}
}

# Build ping agents. Each node will try to ping a hub and each hub will try to ping each node.
for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j 0} {$j < $opt(hubs)} {incr j} {
		# Building node i to hub j ping Agents
		set bpIndexNode [expr $j + $i*2*$opt(hubs) ]
		puts "Setting up ping agent $bpIndexNode at node $i to ping hub $j."
		# node i ping Agent to hub j
		set bp($bpIndexNode) [new Agent/Ping]
		$bp($bpIndexNode) set packetSize_ $pingPacketSize
		$bp($bpIndexNode) set fid_ $pingFid
		$bp($bpIndexNode) set prio_ $pingPrio
		$ns attach-agent $n($i) $bp($bpIndexNode)
		# First, the node 0 will try to ping hub 0, then node 1 ... until node M
		# Then, the node 0 will try to ping hub 1, then node 1 ...
		# Then, the hub 0 will try to ping node 0...
		if { $i==0 && $j==0 } {
			$ns at $startpingtime "$bp($bpIndexNode) send"
			set num_pings_tx [expr $num_pings_tx + 1]
			puts "t = $startpingtime s: node $i will send [$bp($bpIndexNode) set packetSize_] bytes ping request to hub $j."
		}
		# $ns at $stoptime "$bp($bpIndexNode) set packetSize_ $pingPacketSize2"
		# $ns at [expr ($startime+$stoptime)/2.0] "$bp($bpIndexNode) send"
		# $ns at $stoppingtime "$bp($bpIndexNode) send"

		# Hub j Ping Agent to node i
		set bpIndexHub [expr $j + $i*2*$opt(hubs) + 1 ]
		puts "Setting up ping agent $bpIndexHub at hub $j to ping node $i."
		set bp($bpIndexHub) [new Agent/Ping]
		$bp($bpIndexHub) set packetSize_ $pingPacketSize
		$bp($bpIndexHub) set fid_ $pingFid
		$bp($bpIndexHub) set prio_ $pingPrio
		$ns attach-agent $hub($j) $bp($bpIndexHub)
		$ns connect $bp($bpIndexNode) $bp($bpIndexHub)
		puts "Ping agent $bpIndexNode is connected to ping agent $bpIndexHub"
		# $ns at $stoptime "$bp($bpIndexHub) set packetSize_ $pingPacketSize2"
	}
}

# Attach agents for FTP transfer from node 0 to hub 0
set tcp0_0_ [$ns create-connection TCP $n(0) TCPSink $hub(0) 0]
$tcp0_0_ set packetSize_ $mss
# Trace ack_ and maxseq_ to get the amount of data transferred
$tcp0_0_ attach $f
$tcp0_0_ tracevar ack_
$tcp0_0_ tracevar maxseq_
set ftp0_0_ [$tcp0_0_ attach-app FTP]
# $ns at 7.0 "$ftp0_0_ produce 100"
# $ftp produce <n> Causes the FTP object to produce n packets instantaneously

## set up a VoIP
set s1 [new Agent/UDP]
$s1 set fid_ 0
$ns attach-agent $n(0) $s1

set null1 [new Agent/UDP]
$ns attach-agent $hub(0) $null1

$ns connect $s1 $null1

set voip_s [new Application/Traffic/Voice]
set voip_r [new Application/Traffic/Voice]

$voip_s attach-agent $s1
$voip_s set interval_ 0.02
$voip_s set burst_time_ 6.0
$voip_s set idle_time_ 6.0
$voip_s set packetSize_ 80
$voip_r attach-agent $null1

# $ns at $startime "$ftp0_0_ start"
# $ns at $stoptime "$ftp0_0_ stop"

# $ns at $startime "$voip_s start"
# $ns at $stoptime "$voip_s stop"

$ns at $endtime "close $f"
$ns at $endtime "finish"

proc finish {} {
	global ns voip_r tcp0_0_ startime stoptime num_pings_rx num_pings_tx minrtt maxrtt

	$voip_r update_score
	puts "[$voip_r set delay_] [$voip_r set rscore_] [$voip_r set mos_]"

	set lastAck [$tcp0_0_ set ack_]
	set lastSEQ [$tcp0_0_ set maxseq_]
	set reTxNum [$tcp0_0_ set nrexmitpack_]
	puts "Final ack: $lastAck, final seq num: $lastSEQ, Number of reTx packets: $reTxNum"
	puts "Estimated goodput: [expr $lastAck*8*1.460/($stoptime-$startime)] kbits/s [expr $lastAck*1460] bytes in [expr $stoptime-$startime] s"
	puts "Estimated throughput: [expr $lastSEQ*1.500*8/($stoptime-$startime)] kbits/s [expr $lastSEQ*1500] bytes in [expr $stoptime-$startime] s"

	# puts "$num_pings_tx pings sent at interval t=\[$minstartpingtime, $maxstartpingtime\] s."
    	# puts "$num_pings_rx pings received at interval t=\[$minpingtimerx, $maxpingtimerx\] s with RTT=\[$minrtt, $maxrtt] ms."
	puts "$num_pings_tx pings sent and $num_pings_rx pings received with RTT=\[$minrtt, $maxrtt] ms."
    	puts "Ping loss rate: [expr 1 - (1.0 * $num_pings_rx) / $num_pings_tx ]"

	puts "run nam NHubsToMNodesInRing.nam..."
	exec nam NHubsToMNodesInRing.nam &

	$ns halt

}

$ns run

exit 0

