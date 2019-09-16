##
## Network Topology of N hubs that can be connected each one to one and only one of M possible gateway nodes
## connected permanently in ring with a changing topology following a connectivity matrix (N <= M). Then, K workstations can connect to
## the gateways via the most convenient hub.
##
## Simulated topology consists of N hubs connecting K workstations (usually K=1) to N gateways through 150 kbit/s full duplex links. The workstations connect to the N hubs through a high speed LAN.
##
## The M possible nodes are connected intermitently in ring, following a connectivity matrix, in a full-duplex way.
## The connectivity matrix period is equal to M (number of nodes) timeslots of timeslot duration (40 s).
## Each timeslot each pairs of nodes A <-> B can connect each other in each direction.
## In reality, the link layer rate is 120 kbit/s and there are two 16.5 s connections possible in each direction each 40 s.
## From the network layer, this is equivalent to being able to transfer 120e3*16.5 bits on each direction full-duplex each 40 s.
## So, it is like the links have a rate of ~48 kbit/s and are up 40 s on each direction.
##
## There are ping agents at the workstations and at each node to characterize the network latency.
## First each node pings each workstation, then each workstation pings to each node.
## So, if M nodes have to ping K workstations M*K pings are sent in M*K timeslots. Then K workstations send K*M pings to nodes.
## In total 2*M*K pings are sent to characterize network latency in 2*M*K timeslots.
## The connectivity matrix needs to be repeated 2*K times if ideal visibility conditions.
## With real-visibility conditions, the simulation period should be 14 hours and 7 minutes if real visibility of GWs to nodes is not considered, only the visibility among nodes, or 10 days if the visibility between GWs and 
## Hubs is accounted and dynamic.
## 
## TODO:
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
set epsilon 0.001

# set ber 1e-6
set ber 0.0
set per 0.0

set bw1 150kb
set bw2 48kb

set lan_delay 1ms
set lan_capacity 1Gb

# set file_name "satsVisibility.mat"
# set file_name "visibility.mat"
set file_name ""
set mychar #

if { [file exists $file_name] == 1} {
	catch {set vf [ open $file_name r]}
	set visibility_matrix_data [ read -nonewline $vf ]
	close $vf

	set visibility_data [split $visibility_matrix_data "\n"]

	set n 1
	set satIndex 0
	set timeslot 1
	foreach line $visibility_data {
		# This indicates a new element
		# name: <cell-element>
		# type: matrix
		# rows: 21601
		# columns: 30
		if {[string match $mychar* $line]} {
			# Check if it is a new <cell-element>
			set substring "cell-element"
			if {[string first $substring $line] != -1} {
				set satIndex [expr $satIndex+1]
				set timeslot 1
			}
		} else {
			# if not a blank line
			if { $line ne ""} {
				puts "$n $satIndex $timeslot $line"		
				if { $timeslot > 21601 } {
					puts "Error: too many timeslots!"
					exit
				}
				lappend satsVisibility($satIndex) $line
				set n [expr $n+1]
				set timeslot [expr $timeslot+1]			
			}
		}
	}
	
	# set satsrc 1
	# set timeslot 1
	# set satdst 2
	# puts [lindex [lindex $satsVisibility($satsrc) $timeslot] $satdst]
	
	set idealVisibility 0
} else {
	set idealVisibility 1
}

# Slurp connectivity matrix
# catch {set cf [open "connectivityMatrix2.txt" r]}
# Ideal visibility:
# One hub: 3 pings sent and 3 pings received with RTT=[196.8, 613.2] ms.
# Two hubs: 3 pings sent and 3 pings received with RTT=[196.8, 196.8] ms.

# catch {set cf [ open "connectivityMatrix4.txt" r]}
# Ideal visibility:
# One hub: 7 pings sent and 7 pings received with RTT=[196.8, 1030.5] ms.
# 24 pings sent and 24 pings received with RTT=[196.8, 1029.5] ms.
# Two hubs: 7 pings sent and 7 pings received with RTT=[196.8, 614.3] ms.
# 24 pings sent and 24 pings received with RTT=[196.8, 613.2] ms.
# Three hubs: 7 pings sent and 7 pings received with RTT=[196.8, 614.5] ms.
# 24 pings sent and 24 pings received with RTT=[196.8, 613.2] ms.
# Four hubs: 7 pings sent and 7 pings received with RTT=[196.8, 197.3] ms.
# 24 pings sent and 24 pings received with RTT=[196.8, 196.8] ms.

# catch {set cf [ open "connectivityMatrix6.txt" r]}
# Ideal visibility:
# One hub: 12 pings sent and 12 pings received with RTT=[196.8, 1029.5] ms.
# 36 pings sent and 36 pings received with RTT=[196.8, 1029.5] ms.
# Two hubs: 12 pings sent and 12 pings received with RTT=[196.8, 1029.5] ms.
# 36 pings sent and 36 pings received with RTT=[196.8, 1029.5] ms.
# Three, Four and Five hubs: 12 pings sent and 12 pings received with RTT=[196.8, 613.2] ms.
# 36 pings sent and 36 pings received with RTT=[196.8, 613.2] ms.

# catch {set cf [ open "connectivityMatrix8.txt" r]}
# Ideal visibility:
# One, Two and Three hubs: 16 pings sent and 16 pings received with RTT=[196.8, 1029.5] ms.
# 48 pings sent and 48 pings received with RTT=[196.8, 1029.5] ms.
# Four, Five, Six and Seven hubs: 16 pings sent and 16 pings received with RTT=[196.8, 613.2] ms
# Four hubs: 48 pings sent and 48 pings received with RTT=[196.8, 614.5] ms.
# Five, Six and Seven hubs: 48 pings sent and 48 pings received with RTT=[196.8, 613.2] ms.

catch {set cf [ open "connectivityMatrix24.txt" r]}
# Ideal visibility:
# One, Two, Three, Four, Five, Six, Seven and Eight hubs: 48 pings sent and 48 pings received with RTT=[196.8, 1029.5] ms.
# 144 pings sent and 144 pings received with RTT=[196.8, 1029.5] ms.
# Sixteen: 48 pings sent and 48 pings received with RTT=[196.8, 613.2] ms

# catch {set cf [ open "connectivityMatrix30.txt" r]}
# Ideal visibility:
# One hub: 61 pings sent and 61 pings received with RTT=[194.8, 1809.0] ms

# catch {set cf [ open "connectivityMatrix36.txt" r]}
# Ideal visibility:
# One hub: 73 pings sent and 73 pings received with RTT=[194.8, 1809.0] ms

# catch {set cf [ open "connectivityMatrix40.txt" r]}
# Ideal visibility:
# One hub: 81 pings sent and 81 pings received with RTT=[194.8, 1809.0] ms

# catch {set cf [ open "connectivityMatrix42.txt" r]}
# Ideal visibility:
# One hub: 85 pings sent and 85 pings received with RTT=[194.8, 1809.0] ms

# catch {set cf [ open "connectivityMatrix48.txt" r]}
# Ideal visibility:
# One hub: 97 pings sent and 97 pings received with RTT=[194.8, 1809.0] ms

# catch {set cf [ open "connectivityMatrix54.txt" r]}
# Ideal visibility:
# One hub: 109 pings sent and 109 pings received with RTT=[194.8, 1811.4] ms

set conn_matrix_data [ read -nonewline $cf ]
close $cf

# Process connectivity matrix data
set data [split $conn_matrix_data "\n"]

set opt(ws) 1

set opt(nodes) 0
foreach line $data {
	puts "$opt(nodes) $line"	
	set opt(nodes) [expr $opt(nodes)+1]	; # number of nodes is equal to number of timeslots of the connectivity matrix
}
set opt(hubs)      	1                     ;# number of hubs

if { $opt(hubs) > $opt(nodes) } {
	puts "Limiting number of hubs $opt(hubs) to number of nodes $opt(nodes)"
	set opt(hubs) $opt(nodes)
}

set opt(time_btw_pkts)   $timeslot		  ;# seconds

# The delay in the links depends on the distance between nodes and the speed of light in vaccuum: 299792 km/h
# Worst case distance estimated between a hub and a node: 30000 km => 100 ms
# Worst case distance between hub and node: 28102 km => 94 ms
# Worst case distance measured between nodes 59205 km => 197.5 ms
set latencyHubNode 94ms
set latencyBtwNodes 197.5ms

set startpingtime [ expr $timeslot/2 - 2*$epsilon ]
set startime $epsilon

set ns [new Simulator]

# Enable dynamic routing distance vector protocol
$ns rtproto DV

# Workstations
for {set k 0} {$k < $opt(ws)} {incr k} {
	set ws($k) [$ns node]
	puts "ws($k)"
}
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
# So, subtract number of hubs to node number to get node index, plus one extra for the workstation

set f [open NHubsToMNodesInPermanentRing.tr w]
$ns trace-all $f

if { $opt(nodes) < 24 } {
	set nf [open NHubsToMNodesInPermanentRing.nam w]
	$ns namtrace-all $nf
}

# Any hub can be potentially connected to any node (only one) at any time (scheduled contact plan)
# And any node can be connected to any hub, but only to one.
for {set j 0} {$j < $opt(hubs)} {incr j} {
	# Connect the workstations to the hub using LAN
	for {set k 0} {$k < $opt(ws)} {incr k} {
		$ns duplex-link $ws($k) $hub($j) $lan_capacity $lan_delay DropTail
	}
	# Connect the hubs to the nodes
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
# The links between GWs are half-duplex and are active in each direction each 40 s.
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

# TODO: Determine connectivity schedule according to real visibility of hubs to nodes in function of time.

for {set j 0} {$j < $opt(hubs)} {incr j} {
	for {set i 0} {$i < $opt(nodes)} {incr i} {
		if { $i != $j } {
			$ns rtmodel-at [expr $startime] down $n($i) $hub($j)
		} else {
			puts "Hub $j connected to node $j"
		}
	}
}

set currentTime $startime

# Connectivity matrix for nodes
# Configure nodes connections according to connectivity matrix txt file and visibility conditions (ideal or not)
# Assuming permanent connectivity among GWs
# for {set i 0} { $i < [expr 2*$opt(ws)] } {incr i} {
for {set i 0} { $i < [expr 6*$opt(ws)] } {incr i} {
	foreach line $data {
		# puts "$line"
		set connElem [split $line "\]\["]		
		set j 0
		foreach conn $connElem {
			set nodes [split $conn " "]
			set k 0
			foreach nk $nodes {
				if { [expr $j % 2] == 1 } {				
					if { $k != 0 && $k != 3 } {
						scan $nk %d nodeNum
						incr nodeNum -1
						if { $j ==1 && $k == 1 } {
							set firstNode $nodeNum
							set prevNode $nodeNum
						} else {
							set satsrc [expr $prevNode + 1]
							set satdst [expr $nodeNum + 1]
							if { $idealVisibility == 1 || ([lindex [lindex $satsVisibility($satsrc) $i] $satdst] == 1 && [lindex [lindex $satsVisibility($satdst) $i] $satsrc] == 1) } {
								$ns rtmodel-at [expr $currentTime] up $n($prevNode) $n($nodeNum)
								$ns rtmodel-at [expr $currentTime] up $n($nodeNum) $n($prevNode)
								puts "t=$currentTime: $prevNode <-> $nodeNum up"
								$ns rtmodel-at [expr $currentTime + $timeslot] down $n($nodeNum) $n($prevNode)
								$ns rtmodel-at [expr $currentTime + $timeslot] down $n($prevNode) $n($nodeNum)
							} else {
								puts "t=$currentTime: $prevNode <-> $nodeNum down"
							}
							set prevNode $nodeNum
						}
					}
				}
				set k [ expr $k + 1]
			}
			set j [expr $j + 1]	
		}
		if { $opt(nodes) > 2 } {
			set satsrc [expr $prevNode + 1]
			set satdst [expr $firstNode + 1]
			if { $idealVisibility == 1 || ([lindex [lindex $satsVisibility($satsrc) $i] $satdst] == 1 && [lindex [lindex $satsVisibility($satdst) $i] $satsrc] == 1) } {
				$ns rtmodel-at [expr $currentTime] up $n($prevNode) $n($firstNode)
				$ns rtmodel-at [expr $currentTime] up $n($firstNode) $n($prevNode)
				puts "t=$currentTime: $prevNode <-> $firstNode up"
				$ns rtmodel-at [expr $currentTime + $timeslot] down $n($firstNode) $n($prevNode)
				$ns rtmodel-at [expr $currentTime + $timeslot] down $n($prevNode) $n($firstNode)
			} else {
				puts "t=$currentTime: $prevNode <-> $firstNode down"
			}
		}
		# puts "$prevNode -> $nodeNum"
		set currentTime [expr $currentTime + $timeslot]
	}
}

set stoptime $currentTime
set stoppingtime $currentTime
set endtime [ expr $currentTime + 2*$epsilon ]

puts "Simulating $endtime s"

set filename "NHubsToMNodesInPermanentRingWithRealVisibilityMeasuredRTTs.txt"
set fileId [open $filename "w"]

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
	global ns num_pings_rx num_pings_tx maxrtt minrtt currsrcnode currdstnode last_arrival bp opt timeslot stoppingtime epsilon fileId
	$self instvar node_
	set pingrxtime [$ns now]
	set currsrcnode [$node_ id]
	set currdstnode $from
	if { $currsrcnode > $currdstnode } {
		# This is a ping received from a node, so performed from workstation to node
		set nodeSrcIndex [ expr $currsrcnode - $opt(hubs) - $opt(ws)]
		set nodeDstIndex -1
		set bpIndexNode [expr $currdstnode + $nodeSrcIndex*2*$opt(ws) ]
		set bpIndexWs [expr $currdstnode + $nodeSrcIndex*2*$opt(ws) + 1 ]
		puts "t=$pingrxtime: ping agent $bpIndexNode at ns-2 node $currsrcnode (node $nodeSrcIndex) received ping answer from \
		ping agent $bpIndexWs at workstation $currdstnode, with round-trip-time $rtt ms."
		puts $fileId "[$ns now] $rtt"
		set nodeSrcIndex [expr $nodeSrcIndex + 1]
		set currsrcnode [expr $nodeSrcIndex + $opt(hubs) + $opt(ws)]
		if { $nodeSrcIndex == $opt(nodes) } {
			set nodeSrcIndex 0
			set currsrcnode [expr $nodeSrcIndex + $opt(hubs) + $opt(ws)]
			set currdstnode [expr $currdstnode + 1]
			if { $currdstnode == $opt(ws) } {
				# All nodes have ping all worstations, so now workstations ping nodes
				set currsrcnode 0
				set currdstnode [expr $opt(hubs) + $opt(ws)]
			}
		}
	} else {
		# This is a ping received from a workstation, so performed from a node to a workstation
		set nodeSrcIndex -1
		set nodeDstIndex [ expr $currdstnode - $opt(hubs) - $opt(ws)]
		set bpIndexNode [expr $currsrcnode + $nodeDstIndex*2*$opt(ws) ]
		set bpIndexWs [expr $currsrcnode + $nodeDstIndex*2*$opt(ws) + 1 ]
		puts "t=$pingrxtime: ping agent $bpIndexWs at workstation $currsrcnode received ping answer from \
		ping agent $bpIndexNode at ns-2 node $currdstnode (node $nodeDstIndex), with round-trip-time $rtt ms."
		set nodeDstIndex [expr $nodeDstIndex + 1]
		set currdstnode [expr $nodeDstIndex + $opt(hubs) + $opt(ws)]
		if { $nodeDstIndex == $opt(nodes) } {
			set nodeDstIndex 0
			set currdstnode [expr $nodeDstIndex + $opt(hubs) + $opt(ws)]
			set currsrcnode [expr $currsrcnode + 1]
			if { $currsrcnode == $opt(ws) } {
				# All workstations have ping all nodes, so now nodes ping workstations
				set currdstnode 0
				set currsrcnode [expr $opt(hubs) + $opt(ws)]
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
	set startpingtime [expr $numTimeSlots * $timeslot + $timeslot/2 - 2*$epsilon]
	if { $startpingtime < $stoppingtime } {
		if { $currsrcnode > $currdstnode } {
			# This is a ping performed from a node to a workstation
			set nodeSrcIndex [ expr $currsrcnode - $opt(hubs) - $opt(ws)]
			set bpIndexNode [expr $currdstnode + $nodeSrcIndex*2*$opt(ws) ]
			set bpIndexWs [expr $currdstnode + $nodeSrcIndex*2*$opt(ws) + 1 ]
			set bpindex $bpIndexNode
			puts "t=$startpingtime s: ping agent $bpIndexNode at ns-2 node $currsrcnode (node $nodeSrcIndex) will send ping request to \
			ping agent $bpIndexWs at workstation $currdstnode."
		} else {
			# This is a ping performed from a workstation to a node
			set nodeDstIndex [ expr $currdstnode - $opt(hubs) - $opt(ws)]
			set bpIndexNode [expr $currsrcnode + $nodeDstIndex*2*$opt(ws) ]
			set bpIndexWs [expr $currsrcnode + $nodeDstIndex*2*$opt(ws) + 1 ]
			set bpindex $bpIndexWs
			puts "t=$startpingtime s: ping agent $bpIndexWs at workstation $currsrcnode will send ping request to \
			ping agent $bpIndexNode at ns-2 node $currdstnode (node $nodeDstIndex)."
		}
		$ns at $startpingtime "$bp($bpindex) send"
		set num_pings_tx [expr $num_pings_tx + 1]
		# puts "t = $startpingtime s: ping agent $bpindex at ns-2 node $currsrcnode will send [$bp($bpindex) set packetSize_] bytes ping request to ns-2 node $currdstnode."
	}
}

# Build ping agents. Each node will try to ping a workstation and each workstation will try to ping each node.
for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j 0} {$j < $opt(ws)} {incr j} {
		# Building node i to workstation j ping Agents
		set bpIndexNode [expr $j + $i*2*$opt(ws) ]
		puts "Setting up ping agent $bpIndexNode at node $i to ping workstation $j."
		# node i ping Agent to workstation j
		set bp($bpIndexNode) [new Agent/Ping]
		$bp($bpIndexNode) set packetSize_ $pingPacketSize
		$bp($bpIndexNode) set fid_ $pingFid
		$bp($bpIndexNode) set prio_ $pingPrio
		$ns attach-agent $n($i) $bp($bpIndexNode)
		# First, the node 0 will try to ping workstation 0, then node 1 ... until node M
		# Then, the node 0 will try to ping workstation 1, then node 1 ...
		# Then, the workstation 0 will try to ping node 0...
		if { $i==0 && $j==0 } {
			$ns at $startpingtime "$bp($bpIndexNode) send"
			set num_pings_tx [expr $num_pings_tx + 1]
			puts "t = $startpingtime s: node $i will send [$bp($bpIndexNode) set packetSize_] bytes ping request to workstation $j."
		}
		# $ns at $stoptime "$bp($bpIndexNode) set packetSize_ $pingPacketSize2"
		# $ns at [expr ($startime+$stoptime)/2.0] "$bp($bpIndexNode) send"
		# $ns at $stoppingtime "$bp($bpIndexNode) send"

		# Workstation j Ping Agent to node i
		set bpIndexWs [expr $j + $i*2*$opt(ws) + 1 ]
		puts "Setting up ping agent $bpIndexWs at workstation $j to ping node $i."
		set bp($bpIndexWs) [new Agent/Ping]
		$bp($bpIndexWs) set packetSize_ $pingPacketSize
		$bp($bpIndexWs) set fid_ $pingFid
		$bp($bpIndexWs) set prio_ $pingPrio
		$ns attach-agent $ws($j) $bp($bpIndexWs)
		$ns connect $bp($bpIndexNode) $bp($bpIndexWs)
		puts "Ping agent $bpIndexNode is connected to ping agent $bpIndexWs"
		# $ns at $stoptime "$bp($bpIndexWs) set packetSize_ $pingPacketSize2"
	}
}

# Attach agents for FTP transfer from node 0 to hub 0
set tcp0_0_ [$ns create-connection TCP $n(0) TCPSink $ws(0) 0]
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
$ns attach-agent $ws(0) $null1

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
$ns at $endtime "close $fileId"
$ns at $endtime "finish"

proc finish {} {
	global ns opt voip_r tcp0_0_ startime stoptime num_pings_rx num_pings_tx minrtt maxrtt
	
	# $voip_r update_score
	# puts "[$voip_r set delay_] [$voip_r set rscore_] [$voip_r set mos_]"

	# set lastAck [$tcp0_0_ set ack_]
	# set lastSEQ [$tcp0_0_ set maxseq_]
	# set reTxNum [$tcp0_0_ set nrexmitpack_]
	# puts "Final ack: $lastAck, final seq num: $lastSEQ, Number of reTx packets: $reTxNum"
	# puts "Estimated goodput: [expr $lastAck*8*1.460/($stoptime-$startime)] kbits/s [expr $lastAck*1460] bytes in [expr $stoptime-$startime] s"
	# puts "Estimated throughput: [expr $lastSEQ*1.500*8/($stoptime-$startime)] kbits/s [expr $lastSEQ*1500] bytes in [expr $stoptime-$startime] s"

	# puts "$num_pings_tx pings sent at interval t=\[$minstartpingtime, $maxstartpingtime\] s."
    # puts "$num_pings_rx pings received at interval t=\[$minpingtimerx, $maxpingtimerx\] s with RTT=\[$minrtt, $maxrtt] ms."
	puts "$num_pings_tx pings sent and $num_pings_rx pings received with RTT=\[$minrtt, $maxrtt] ms."
    puts "Ping loss rate: [expr 1 - (1.0 * $num_pings_rx) / $num_pings_tx ]"

	exec ./NHubsToMNodesInPermanentRingWithRealVisibilityMeasuredRTTs.sh

	if { $opt(nodes) < 24 } {
		puts "run nam NHubsToMNodesInPermanentRing.nam..."
		exec nam NHubsToMNodesInPermanentRing.nam &
	}

	$ns halt

}

$ns run

exit 0
