# Copyright (c) 1999 Regents of the University of Southern California.
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
#      This product includes software developed by the Computer Systems
#      Engineering Group at Lawrence Berkeley Laboratory.
# 4. Neither the name of the University nor of the Laboratory may be used
#    to endorse or promote products derived from this software without
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
# wireless1.tcl
# A simple example for wireless simulation

# ======================================================================
# Define options
# ======================================================================

set val(chan)       Channel/WirelessChannel
set val(prop)       Propagation/TwoRayGround
set val(netif)      Phy/WirelessPhy
set val(mac)        Mac/802_11
set val(ifq)        Queue/DropTail/PriQueue
set val(ll)         LL
set val(ant)        Antenna/OmniAntenna
set val(x)              300   ;# X dimension of the topography
set val(y)              300   ;# Y dimension of the topography
set val(ifqlen)         50            ;# max packet in ifq
set val(seed)           0.0
# set val(adhocRouting)   DSR
set val(adhocRouting)   DSDV
set val(nn)             4             ;# how many wireless interfaces are there

# =====================================================================
# Main Program
# ======================================================================

Mac/802_11 set dataRate_ 11Mb

#
# Initialize Global Variables
#

set num_wired_nodes      1
set num_bs_nodes         2

set startpingtime 0.5
set startime 1.0
set stoptime 101.0
set stoppingtime 110.0
set endtime 120

# create simulator instance

set ns_		[new Simulator]

# https://www.isi.edu/nsnam/ns/tutorial/nsscript6.html

$ns_ node-config -addressType hierarchical    
AddrParams set domain_num_ 3           ;# number of domains
lappend cluster_num 1 1 1           ;# number of clusters in each
                                       ;#domain
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 1 2 2            ;# number of nodes in each cluster
AddrParams set nodes_num_ $eilastlevel ;# for each domain

# create trace object for ns and nam

set tracefd	[open wired-cum-2wireless-out.tr w]
set namtrace    [open wired-cum-2wireless-out.nam w]
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# setup topography object

set topo	[new Topography]

# define topology
$topo load_flatgrid $val(x) $val(y)

#
# create General Operations Director (GOD)
# It needs to know the number of wireless interfaces that are on the simulation
#
set god_ [create-god $val(nn)]

# The shortest path between node 1 and 2 is 4 hops
# $god_ set-dist 1 2 4

# Create channel #1 and #2
set chan_1_ [new $val(chan)]
set chan_2_ [new $val(chan)]

# create wired node
set W(0) [$ns_ node 0.0.0] ;# hierarchical addresses to be used

#
# define how node should be created
#

# configure for base-station node
$ns_ node-config -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
		 -topoInstance $topo \
                 -wiredRouting ON \
	         -agentTrace ON \
                 -routerTrace OFF \
                 -macTrace OFF \
		 -channel $chan_1_

#create base-station node
set BS(0) [ $ns_ node 1.0.0]
$BS(0) random-motion 0               ;# disable random motion
#provide some co-ordinates (fixed) to base station node
$BS(0) set X_ [expr ($val(x)/2)-5]
$BS(0) set Y_ [expr ($val(y)/2)-5]
$BS(0) set Z_ 0.0									 

# Uncomment below two lines will create BS(1) with a different channel.
#  $ns_ node-config \
#		 -channel $chan_2_ 

set BS(1) [ $ns_ node 2.0.0]
$BS(1) random-motion 0               ;# disable random motion
#provide some co-ordinates (fixed) to base station node
$BS(1) set X_ [expr ($val(x)/2)+5]
$BS(1) set Y_ [expr ($val(y)/2)+5]
$BS(1) set Z_ 0.0

#global node setting

$ns_ node-config -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
		 -topoInstance $topo \
		 -agentTrace ON \
                 -routerTrace OFF \
                 -macTrace OFF \
		 -channel $chan_1_

# create wireless node in the same domain as BS(1)
# Note there has been a change of the earlier AddrParams 
# function 'set-hieraddr' to 'addr2id'.

#configure for mobilenodes
$ns_ node-config -wiredRouting OFF

# now create building 1 node
set node_(0) [ $ns_ node 1.0.1 ]
    $node_(0) base-station [AddrParams addr2id \
            [$BS(0) node-addr]]   ;# provide each mobilenode with
                                  ;# hier address of its base-station								  
$node_(0) random-motion 0		;# disable random motion
$node_(0) set X_ 5.0
$node_(0) set Y_ 5.0
$node_(0) set Z_ 0.0

# Uncomment below two lines will create node_(1) with a different channel.
#  $ns_ node-config \
#		 -channel $chan_2_ 

set node_(1) [ $ns_ node 2.0.1 ]
	$node_(1) base-station [AddrParams addr2id \
			[$BS(1) node-addr]]   ;# provide each mobilenode with
								  ;# hier address of its base-station
$node_(1) random-motion 0		;# disable random motion
$node_(1) set X_ [expr $val(x)-5.0]
$node_(1) set Y_ [expr $val(y)-5.0]
$node_(1) set Z_ 0.0  

# create links between wired and BaseStation nodes
$ns_ duplex-link $W(0) $BS(0) 100Mb 1ms DropTail
$ns_ duplex-link $W(0) $BS(1) 100Mb 1ms DropTail
$ns_ duplex-link-op $W(0) $BS(0) orient left-down
$ns_ duplex-link-op $W(0) $BS(1) orient right-up

# Define node initial position in nam

# 20 defines the node size in nam, must adjust it according to your scenario
# The function must be called after mobility model is defined

$ns_ initial_node_pos $node_(0) 20
$ns_ initial_node_pos $node_(1) 20
# $ns_ initial_node_pos $BS(0) 20
# $ns_ initial_node_pos $BS(1) 20

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns_
	$self instvar node_
	puts "t=[$ns_ now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

# Building 1 Ping Agent
set bp1 [new Agent/Ping]
$bp1 set packetSize_ 64
$bp1 set packetSize_ 64
$bp1 set fid_ 100
$bp1 set prio_ 0
$ns_ attach-agent $node_(0) $bp1
$ns_ at $startpingtime "$bp1 send"
$ns_ at $stoptime "$bp1 set packetSize_ 1064"
$ns_ at [expr ($startime+$stoptime)/2.0] "$bp1 send"
$ns_ at $stoppingtime "$bp1 send"

# Building 2 Ping Agent
set bp2 [new Agent/Ping]
$bp2 set packetSize_ 64
$bp2 set fid_ 100
$bp2 set prio_ 0
$ns_ attach-agent $node_(1) $bp2
$ns_ connect $bp1 $bp2
$ns_ at $stoptime "$bp2 set packetSize_ 1064"

# setup TCP connections between wireless nodes at buildings

set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
$tcp1 set packetSize_ 2264
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp1
$ns_ attach-agent $node_(1) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns_ at $startime "$ftp1 start"
$ns_ at $stoptime "$ftp1 stop"

## set up a VoIP

set s1 [new Agent/UDP]
$s1 set fid_ 0
$ns_ attach-agent $node_(0) $s1

set null1 [new Agent/UDP]
$ns_ attach-agent $node_(1) $null1

$ns_ connect $s1 $null1

set voip_s [new Application/Traffic/Voice]
set voip_r [new Application/Traffic/Voice]

$voip_s attach-agent $s1
$voip_s set interval_ 0.02
$voip_s set burst_time_ 6.0
$voip_s set idle_time_ 6.0
$voip_s set packetSize_ 80
# $voip_r set A_ 0
$voip_r attach-agent $null1

$ns_ at $startime "$voip_s start"
$ns_ at $stoptime "$voip_s stop"

#
# Tell nodes when the simulation ends
#
$ns_ at $endtime.0 "$node_(0) reset";
$ns_ at $endtime.0 "$node_(1) reset";
$ns_ at $endtime.0 "$BS(0) reset";
$ns_ at $endtime.0 "$BS(1) reset";

$ns_ at  $endtime.0002 "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $endtime.0001 "stop"
proc stop {} {
    global ns_ tracefd namtrace tcp1 startime stoptime voip_r
    close $tracefd
    close $namtrace
    $voip_r update_score
    puts "[$voip_r set delay_] [$voip_r set rscore_] [$voip_r set mos_]"
    set lastAck [$tcp1 set ack_]
    set lastSEQ [$tcp1 set maxseq_]
    set reTxNum [$tcp1 set nrexmitpack_]
    puts "Wireless Tx Power (W): [Phy/WirelessPhy set Pt_]"
    puts "802.11 data Rate (bits/s): [Mac/802_11 set dataRate_]"
    puts "Final ack: $lastAck, final seq num: $lastSEQ, Number of reTx packets: $reTxNum"
    puts "Estimated goodput: [expr $lastAck*8*2.264/($stoptime-$startime)] kbits/s [expr $lastAck*2264] bytes in [expr $stoptime-$startime] s"
    puts "Estimated throughput: [expr $lastSEQ*2.304*8/($stoptime-$startime)] kbits/s [expr $lastSEQ*2304] bytes in [expr $stoptime-$startime] s"
    puts "run nam  wired-cum-2wireless-out.nam..."
    # exec nam  wired-cum-2wireless.nam &
}

puts $tracefd "M 0.0 nn $val(nn) x $val(x) y $val(y) rp $val(adhocRouting)"
puts $tracefd "M 0.0 seed $val(seed)"
puts $tracefd "M 0.0 prop $val(prop) ant $val(ant)"

puts "Starting Simulation..."
$ns_ run

