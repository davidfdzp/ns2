# wireless-net-grid-voip.tcl: wireless simulation with the following arrangement:
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
# as 100 m < 250 m ok
#
# A UDP packet of 1024 bytes is generated in each node each second to some other node starting from node 0 to node 1 and so on...
#
# Time between packets in the network follows an Exponential distribution.
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
set opt(start)		0
set opt(finish)         1700                      ;# time to stop simulation (seconds)
set opt(datasize)	1024
set opt(mtu)		1500
set opt(time_btw_pkts)  1
set opt(interval)	1
set opt(burst_time)	0.001

# ============================================================================

# create the simulator object
set ns [new Simulator]

# set up tracing
set name [lindex [split [info script] "."] 0]
# New trace format explained at section 16.1.7 of ns-manual
$ns use-newtrace
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
		set last_arrival($num_nodes) 0
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

# Build UDP Exponential agents. Each node will try to send $databytes to  another node once at an instant randomly as per the previously defined random variable.
set num_agents 0
for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j 0} {$j < $opt(nodes)} {incr j} {
		if { $i != $j } {
			# Building node i to node j Agent
			set index [expr $i * $opt(nodes) + $j]
	# Application/Traffic/Voice generates traffic according to an Exponential On/Off distribution.
	# Packets are sent at a fixed rate during on periods, and no packets are sent during off periods.
	# Both on and off periods are taken from an exponential distribution. Packets are constant size.
			set voip_s($index) [new Application/Traffic/Voice]
			set voip_r($index) [new Application/Traffic/Voice]
			set udp_s($index) [new Agent/UDP]
			set udp_r($index) [new Agent/UDP]
	# The Voice generator can be configured to behave as a Poisson process by setting the variable burst_time
	# to a very low value, e.g. a millisecond (not zero, so at least a packet is generated) and the variable interval_ 
	# equal to burst time, so no more than one packet is generated during the on interval. 		
	# The next arrival time is determined by the random variate corresponding to idle_time_.
			$voip_s($index) attach-agent $udp_s($index)
			$voip_s($index) set interval_ $opt(interval)
			$voip_s($index) set burst_time_ $opt(burst_time)
			$voip_s($index) set idle_time_ $time_btw_pkts_net
			$voip_s($index) set packetSize_ $opt(datasize)
			$voip_r($index) attach-agent $udp_r($index)

			$udp_s($index) set index $index
			$udp_s($index) set packetSize_ $opt(mtu)
			$udp_s($index) set fid_ 0
			$udp_s($index) set prio_ 0
			$udp_r($index) set index $index

			$ns attach-agent $node($i) $udp_s($index)
			$ns attach-agent $node($j) $udp_r($index)
			$ns connect $udp_s($index) $udp_r($index)

			$ns at $opt(start) "$voip_s($index) start"
			$ns at $opt(start) "$voip_r($index) reset"
			$ns at [expr 9.0*$opt(finish)/10] "$voip_s($index) stop"
			set num_agents [expr $num_agents + 1]
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
    global ns tracefd namtrace name opt time_btw_pkts_net voip_s voip_r num_agents
    $ns flush-trace
    close $tracefd
    close $namtrace
    puts "Node coverage radius: $opt(radius) m"
    puts "Covered area size: $opt(hsize) x $opt(vsize) nodes"
    puts "Wireless Tx Power (W): [Phy/WirelessPhy set Pt_]"
    puts "802.11 data Rate (bits/s): [Mac/802_11 set dataRate_]"
    puts "Time between packets at each UDP agent: $time_btw_pkts_net s"
    set voip_max_delay 0
    set voip_min_delay 100000
    set num_agents_traffic 0
    for {set i 0} {$i < $opt(nodes)} {incr i} {
	for {set j 0} {$j < $opt(nodes)} {incr j} {
		if { $i != $j } {
			set index [expr $i * $opt(nodes) + $j]
			$voip_r($index) update_score
			set voip_delay [$voip_r($index) set max_delay_]
			if { $voip_delay > 0 } {
				puts "$voip_delay [$voip_r($index) set rscore_] [$voip_r($index) set mos_]"			
				if { $voip_delay > 0 && $voip_delay < $voip_min_delay } {
					set voip_min_delay $voip_delay
				}
				if { $voip_delay > 0 && $voip_delay > $voip_max_delay } {
					set voip_max_delay $voip_delay
				}
				set num_agents_traffic [expr $num_agents_traffic + 1]
			}
		}
	}
    }
    if { $voip_max_delay > 0 } {
	puts "Max packet delay from a terminal $voip_max_delay ms (Min $voip_min_delay ms) of $num_agents agents ($num_agents_traffic with traffic)"
    }
    puts "run nam $name.nam..."
    exit 0
}

puts "Starting simulation..."
$ns run

