#
# Copyright (c) 1999 Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#       This product includes software developed by the MASH Research
#       Group at the University of California Berkeley.
# 4. Neither the name of the University nor of the Research Group may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Contributed by Tom Henderson, UCB Daedalus Research Group, June 1999

# Example of a MEO constellation with orbital configuration 
# similar to that of Galileo.  The script sets up one uplink ground station and
# one user and sends a packet from the ground station to the user
# every second for a whole day-- the script illustrates how the latency
# due to propagation delay changes depending on the satellite network configuration. 
#
# This script relies on sourcing two additional files:
# - sat-galileo-nodes.tcl
# - sat-galileo-links.tcl
# To enable crossseam ISLs, uncomment 
# the last few lines of "sat-galileo-links.tcl"
#
# Ground stations locations:
# Kiruna - lat 67.85 deg, lon 20.96 deg, alt 0.3911 km
# Kourou - lat 5.08 deg, lon -52.63, alt 0.02557 km
# Noumea - lat -22.27 deg, lon 166.41 deg, alt 0.08734 km
# Papetee - lat -17.58 deg, lon -149.62 deg, alt 0.09804 km
# Reunion - lat -21.22 deg, lon 55.57 deg, alt 1.5584 km
# Redu - lat 50 deg, lon 5.15 deg, alt 0.1782 km
#
# Galileo parameters [primary reference: https://www.gsc-europa.eu/system-status/orbital-and-technical-parameters ]
# Altitude = 23228.8 km (29599.8 - 6371)
# Orbital period = 14 hours and 7 min (50820 s)
# interplane separation = 360/16 deg (minimum, from nominal to spare), 360/8 between nominal
# inclination = 56.0
# eccentricity =  0.0 (not modelled)
# minimum elevation angle at edge of coverage = 5 deg
# ISL cross-link pattern:  2 ISL

global ns
set ns [new Simulator]

# Global configuration parameters 
HandoffManager/Term set elevation_mask_ 5
HandoffManager/Term set term_handoff_int_ 10
HandoffManager/Sat set sat_handoff_int_ 10
HandoffManager/Sat set latitude_threshold_ 60 
HandoffManager/Sat set longitude_threshold_ 10 
HandoffManager set handoff_randomization_ true
SatRouteObject set metric_delay_ true
# Set this to false if opt(wiredRouting) == ON below
SatRouteObject set data_driven_computation_ true
# "ns-random 0" sets seed heuristically; other integers are deterministic
ns-random 1
Agent set ttl_ 32; # Should be > than max diameter in network

# One plane of Galileo-like satellites

global opt
set opt(chan)           Channel/Sat
set opt(bw_down)        100kb; # Downlink bandwidth (satellite to ground)
set opt(bw_up)          100kb; # Uplink bandwidth
set opt(bw_isl)         120kb
set opt(phy)            Phy/Sat
set opt(mac)            Mac/Sat
set opt(ifq)            Queue/DropTail
set opt(qlim)           50
set opt(ll)             LL/Sat
set opt(wiredRouting) 	OFF

set opt(alt)            23228.8; # Satellite altitude (Galileo)
set opt(inc)            56.0; # Orbit inclination w.r.t. equator

# XXX This tracing enabling must precede link and node creation
set outfile [open sat-galileo-ping.tr w]
$ns trace-all $outfile

# Create the satellite nodes
# Nodes 0-99 are satellite nodes; 100 and higher are earth terminals

$ns node-config -satNodeType polar \
		-llType $opt(ll) \
		-ifqType $opt(ifq) \
		-ifqLen $opt(qlim) \
		-macType $opt(mac) \
		-phyType $opt(phy) \
		-channelType $opt(chan) \
		-downlinkBW $opt(bw_down) \
		-wiredRouting $opt(wiredRouting) 

set alt $opt(alt)
set inc $opt(inc)

source sat-galileo-nodes.tcl

# configure the ISLs
source sat-galileo-links.tcl

# Set up terrestrial nodes
$ns node-config -satNodeType terminal
set n100 [$ns node]
# $n100 set-position 37.9 -122.3; # Berkeley
$n100 set-position 50 5.15; # Redu, alt 0.1782 km
# $n100 set-position 0 0
set n101 [$ns node]
# $n101 set-position 42.3 -71.1; # Boston 
$n101 set-position 52.24 4.45; # Noordwijk
# $n101 set-position 0 10

# Add GSL links
# It doesn't matter what the sat node is (handoff algorithm will reset it)
$n100 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n0 set downlink_] [$n0 set uplink_]
$n101 add-gsl polar $opt(ll) $opt(ifq) $opt(qlim) $opt(mac) $opt(bw_up) \
  $opt(phy) [$n0 set downlink_] [$n0 set uplink_]

# Trace all queues
$ns trace-all-satlinks $outfile

# Attach agents
set udp0 [new Agent/UDP]
$ns attach-agent $n100 $udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 attach-agent $udp0
$cbr0 set interval_ 60.01

set null0 [new Agent/Null]
$ns attach-agent $n101 $null0

$ns connect $udp0 $null0
# $ns at 1.0 "$cbr0 start"


## ICMP traffic ##

set filename "GalileoRTTs.txt"
set fileId [open $filename "w"]

set max_rtt 0
set min_rtt 10000
set avg 0
set quk 0
set num_pings_rx 0
set num_pings_tx 0

# CBR packet size
set ping_pkt_size 210

puts "PING size $ping_pkt_size bytes"

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns fileId avg quk num_pings_rx max_rtt min_rtt
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
	puts $fileId "[$ns now] $rtt"
	if { $rtt < $min_rtt } {
		set min_rtt $rtt
	}
	if { $rtt > $max_rtt } {
		set max_rtt $rtt
	}
	set num_pings_rx [expr $num_pings_rx + 1]
	set quk [expr $quk + (($num_pings_rx - 1.0)/$num_pings_rx)*pow($rtt - $avg, 2)]
	set avg [expr $avg + ($rtt - $avg)*1.0/$num_pings_rx]
}

set pingtx [new Agent/Ping]
$pingtx set packetSize_ $ping_pkt_size
$pingtx set fid_ 1
$pingtx set prio_ 0
$ns attach-agent $n100 $pingtx
set pingrx [new Agent/Ping]
$pingrx set packetSize_ $ping_pkt_size
$pingrx set fid_ 1
$pingrx set prio_ 0
$ns attach-agent $n101 $pingrx
$ns connect $pingtx $pingrx

# We're using a centralized routing genie-- create and start it here
set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes

# set duration 86400 ; # one earth rotation
# set duration 50820 ; # one orbit rotation
set duration 12705 ; # a quarter of an orbit

$ns at 0.0 "$n0 dump_sats"

for { set i 0} { $i < $duration } {incr i} {
	$ns at $i "$pingtx send"
	set num_pings_tx [expr $num_pings_tx + 1]
}

$ns at $duration "finish"

proc finish {} {
	global ns outfile fileId num_pings_tx num_pings_rx min_rtt max_rtt avg quk duration
	$ns flush-trace
	close $outfile
	close $fileId
	puts "$num_pings_tx packets transmitted, $num_pings_rx received, [expr 100*($num_pings_tx-$num_pings_rx)/$num_pings_tx]% packet loss, time $duration s"
	puts "rtt min/avg/max/stdev = $min_rtt/$avg/$max_rtt/[expr sqrt(1.0*$quk/($num_pings_rx-1))] ms"
	exec ./sat-galileo-ping.sh
	exit 0
}

$ns run
