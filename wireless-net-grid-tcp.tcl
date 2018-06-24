# wireless-net-grid-tcp.tcl: wireless simulation with the following arrangement:
#
#	n0		n1		n2		n3			
#		n4		n5		n6		
#	n7		n8		n9		n10	
#		n11		n12		n13
#	n14		n15		n16		n17	
#		n18		n19		n20
#	n21		n22		n23		n24
#		n25		n26		n27
#	n28		n29		n30		n31
#		n32		n33		n34
#	n35		n36		n37		n38
#  
# hexagonal teselation of a 1000 x 1000 m square area with 39 hexagons (nodes)
# If the node zero is at (0,0), then node 1 is at (3R, 0).
# Node seven is at 0, 2Rsqrt(3), and node 4 is at (2R, R sqrt(3))
# Each node covers a radius of around 100 m.
# default wireless range is 250 m, based on constants in ns-2.35/tcl/lib/ns-default.tcl
# as 140 m < 250 m ok
#
# Each node generates a packet per second of 1024 bytes packets towards the others, using TCP.
#
# Simulation time 1700 s (originally 20 minutes)
# 
# http://intronetworks.cs.luc.edu/current/html/ns2.html#wireless-simulation
# Propagation delay is simply the distance divided by the speed of light.
# For the Mac/802_11 model the bandwidth is determined by the attribute dataRate_ (which can be set). 
# To find the current value, one can print [Mac/802_11 set dataRate_]; in ns-2 version 2.35 it is 1mb.
# The maximum range of a node is determined by its power level, which can be set with node-config below 
# (using the txPower attribute). In the ns-2 source code, in file wireless-phy.cc, the variable Pt_ 
# – for transmitter power – is declared; the default value of 0.28183815 W translates to a physical range 
# of 250 meters using the appropriate radio-attenuation model.

# Mac/802_11 set dataRate_ 11Mb
# Mac/802_11 set dataRate_ 54Mb
# Mac/802_11 set Pt_ 0.005
# Antenna/OmniAntenna set Z_ 25
# Phy/WirelessPhy set freq_ 2400e+6

# ======================================================================
# Define options
# ======================================================================
set opt(chan)           Channel/WirelessChannel  ;# channel type
set opt(prop)           Propagation/TwoRayGround ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy          ;# network interface type
set opt(mac)            Mac/802_11               ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue  ;# interface queue type
set opt(ll)             LL                       ;# link layer type
set opt(ant)            Antenna/OmniAntenna      ;# antenna model
set opt(ifqlen)         50                       ;# max packet in ifq
set opt(x)		1000
set opt(y)		1000
set opt(nodes)      	39                       ;# number of nodes
set opt(vsize)		[expr floor(sqrt($opt(nodes)))]
set opt(hsize)		[expr ceil(sqrt($opt(nodes)))]
# set opt(radius)		[expr sqrt($opt(x)*$opt(y))/sqrt($opt(nodes)*3*sqrt(3))]
set opt(radius)		[expr $opt(x)/10]
set opt(horspacing)	[expr 3*$opt(radius)]
set opt(verspacing)	[expr sqrt(3)*$opt(radius)]

set opt(adhocRouting)   AODV                     ;# routing protocol
#set opt(adhocRouting)   DSDV                      ;# routing protocol
#set opt(adhocRouting)   DSR                       ;# routing protocol

# set opt(finish)         1700                      ;# time to stop simulation (seconds)
set opt(finish)         13500                      ;# time to stop simulation (seconds)
set opt(datasize)	1024
set opt(mtu)		1500
set opt(time_btw_pkts)  1

# ============================================================================

# create the simulator object
set ns [new Simulator]

# set up tracing
set name [lindex [split [info script] "."] 0]
# $ns use-newtrace
set tracefd  [open $name.tr w]
set namtrace [open $name.nam w]
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $opt(x) $opt(y)

# create  and define the topography object and layout
set topo [new Topography]
$topo load_flatgrid $opt(x) $opt(y)

# create an instance of General Operations Director, which keeps track of nodes and 
# node-to-node reachability. The parameter is the total number of nodes in the simulation.
create-god [expr $opt(nodes)]

# New API to config node: 
# 1. Create channel (or multiple-channels);
# 2. Specify channel in node-config (instead of channelType);
# 3. Create nodes for simulations.

set chan1 [new $opt(chan)]

$ns node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channel $chan1 \
                 -topoInstance $topo \
                 -wiredRouting OFF \
                 -agentTrace ON \
                 -routerTrace ON \
		 -movementTrace OFF \
                 -macTrace ON

set num_pkts_tx 0
set num_pkts_rx 0
set maxstartpkttime 0
set maxpkttimerx 0
set maxfirstpkttime 0
set minstartpkttime $opt(finish)
set minpkttimerx $opt(finish)
set maxdelay 0
set mindelay $opt(finish)

# install a procedure to print out the received data at trace file
Application/TcpApp instproc recv {data} {
	global ns num_pkts_rx num_pkts_tx minpkttimerx maxpkttimerx maxdelay mindelay opt
	set pktrxtime [$ns now]
	set delay [expr $pktrxtime - $data]
	$ns trace-annotate "$self received data pkt \"$data\""
	set num_pkts_rx [expr $num_pkts_rx + 1]
	if { $pktrxtime > $maxpkttimerx } {
		set maxpkttimerx $pktrxtime
	}
	if { $pktrxtime < $minpkttimerx } {
		set minpkttimerx $pktrxtime
	}
	if { $delay > $maxdelay } {
		set maxdelay $delay
	}
	if { $delay < $mindelay } {
		set mindelay $delay
	}
	# Do not program the sending of any packet. All programmed during TCP app construction.
}

# Make nodes
set num_nodes 0

set last_arrival(all) 0
for {set i 0} {$i < $opt(hsize)} {incr i} {
	if { [expr $i % 2] == 0 } {
		set j0 0
	} else {
		set j0 1
	}
	for {set j $j0} {$j < $opt(vsize)} {incr j} {
    		set node($num_nodes) [$ns node]
		$node($num_nodes) set X_ [expr $opt(horspacing) + ((-1)^($j0))*$opt(horspacing)/2 + $j*$opt(horspacing) ]
    		$node($num_nodes) set Y_ [expr $opt(verspacing) + $i * $opt(verspacing)]
		$node($num_nodes) set Z_ 25
		set num_nodes [expr $num_nodes + 1]
		if {$num_nodes > $opt(nodes)} {
			break
		}
	}
	if {$num_nodes > $opt(nodes)} {
		break
	}
}
set opt(nodes) $num_nodes
set time_btw_pkts_net [expr $opt(time_btw_pkts)*($opt(nodes)*$opt(nodes)-$opt(nodes))]

$defaultRNG seed 0
set arrival_ [new RandomVariable/Exponential]
$arrival_ set avg_ $time_btw_pkts_net

# Build TCP agents. Each node will try to send 1024 bytes to another node once after $time_btw_pkts_net s on average
for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j [expr $i+1]} {$j < $opt(nodes)} {incr j} {
		if { $i != $j } {
			# Building node i to node j TCP Agent
			set bpindex [expr $i * $opt(nodes) + $j]
			set bp($bpindex) [new Agent/TCP/FullTcp/Sack]
			$bp($bpindex) set fid_ 1
			$bp($bpindex) set prio_ 0
			$bp($bpindex) set tcpip_base_hdr_size_ 40
			$bp($bpindex) set segsize_ [expr $opt(mtu)-[$bp($bpindex) set tcpip_base_hdr_size_]]
			$ns attach-agent $node($i) $bp($bpindex)
			# Building node j to node i TCP Agent
			set bpindex_ [expr $j * $opt(nodes) + $i]
			set bp($bpindex_) [new Agent/TCP/FullTcp/Sack]
			$bp($bpindex_) set fid_ 1
			$bp($bpindex_) set prio_ 0
			$bp($bpindex_) set tcpip_base_hdr_size_ 40
			$ns attach-agent $node($j) $bp($bpindex_)
			$ns connect $bp($bpindex) $bp($bpindex_)
			$bp($bpindex) listen
			$bp($bpindex_) listen
			# Build node i to j TCP Application
			set app($bpindex) [new Application/TcpApp $bp($bpindex)]
			set app($bpindex_) [new Application/TcpApp $bp($bpindex_)]
			$app($bpindex) connect $app($bpindex_)
	#		Program packets sending while simulation goes on, but at least program one.
			set finish_packets 0
			set num_pkts($bpindex) 0
			set last_arrival($bpindex) 0
			while { $finish_packets != 1 } {
				set startpkttime [expr $last_arrival($bpindex) + [$arrival_ value]]
				if {$startpkttime > [expr 9.0*$opt(finish)/10]} {
					set finish_packets 1
					if { $num_pkts($bpindex) == 0 } {
						puts "Warning: Node $i to node $j packet time $startpkttime exceeds 90 percent of simulation time $opt(finish) s."
						if {$startpkttime > $maxfirstpkttime} {
							set maxfirstpkttime $startpkttime
						}
						# set startpkttime [expr 9.0*$opt(finish)/10]
					} 
					break
				}
				set last_arrival($bpindex) $startpkttime
				$ns at $startpkttime "$app($bpindex) send $opt(datasize) {$app($bpindex_) recv {$startpkttime}}"
				puts "t = $startpkttime s: node $i will send $opt(datasize) bytes to node $j."
				if { $startpkttime > $maxstartpkttime } {
					set maxstartpkttime $startpkttime
				}
				if {$startpkttime < $minstartpkttime} {
					set minstartpkttime $startpkttime
				}
				set num_pkts_tx [expr $num_pkts_tx + 1]
				set num_pkts($bpindex) [expr $num_pkts($bpindex) + 1]
			}
		}
	}
}

# tell nam the initial node position (taken from node attributes) 
# and size (supplied as a parameter)
for {set i 0} {$i < $opt(nodes)} {incr i} {
    $ns initial_node_pos $node($i) 10
}

$ns at $opt(finish) "finish"

proc finish {} {
    global ns tracefd namtrace name opt num_pkts num_pkts_tx num_pkts_rx minstartpkttime maxstartpkttime minpkttimerx maxpkttimerx maxdelay mindelay maxfirstpkttime app bp
    $ns flush-trace
    close $tracefd
    close $namtrace
    puts "Node coverage radius: $opt(radius) m"
    puts "Covered area size: $opt(hsize) x $opt(vsize) nodes"
    puts "Wireless Tx Power (W): [Phy/WirelessPhy set Pt_]"
    puts "802.11 data Rate (bits/s): [Mac/802_11 set dataRate_]"
    for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j [expr $i+1]} {$j < $opt(nodes)} {incr j} {
		if { $i != $j } {
			set bpindex [expr $i * $opt(nodes) + $j]
			puts "Node $i tx $num_pkts($bpindex) packets to node $j."
			set bpindex_ [expr $j * $opt(nodes) + $i]
			$app($bpindex_) score "Rx from $i at $j"
			set reTxNum [$bp($bpindex) set nrexmitpack_]
			puts "Number of TCP packets reTx from $i to $j: $reTxNum"
		}
	}
    }
    puts "$num_pkts_tx $opt(datasize) bytes packets tx at interval t=\[$minstartpkttime, $maxstartpkttime\] s."
    puts "$num_pkts_rx $opt(datasize) bytes packets rx at interval t=\[$minpkttimerx, $maxpkttimerx\] s with one-way delay=\[$mindelay, $maxdelay] s."
    puts "Packet loss rate: [expr 1 - (1.0 * $num_pkts_rx) / $num_pkts_tx ]"
    if {$maxfirstpkttime > 0} {
	    puts "Consider increasing simulation duration to [expr 1.1*$maxfirstpkttime] s."
    }
    puts "run nam $name.nam..."
    exit 0
}

puts "Starting simulation..."
$ns run

