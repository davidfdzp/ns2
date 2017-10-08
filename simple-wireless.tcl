# Copyright (c) 1997 Regents of the University of California.
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
#
# simple-wireless.tcl
# A simple example for wireless simulation

# ======================================================================
# Define options
# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(x)              300   			   ;# X dimension of the topography
set val(y)              300   			   ;# Y dimension of the topography
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             3                          ;# number of wireless nodes
# set val(rp)             DSDV                     ;# routing protocol
set val(rp)             DSR                        ;# routing protocol

# ======================================================================
# Main Program
# ======================================================================

# https://www.isi.edu/nsnam/ns/tutorial/

# 
# http://intronetworks.cs.luc.edu/current/html/ns2.html#wireless-simulation
# Propagation delay is simply the distance divided by the speed of light.
# For the Mac/802_11 model the bandwidth is determined by the attribute dataRate_ (which can be set). 
# To find the current value, one can print [Mac/802_11 set dataRate_]; in ns-2 version 2.35 it is 1mb.
# The maximum range of a node is determined by its power level, which can be set with node-config below 
# (using the txPower attribute). In the ns-2 source code, in file wireless-phy.cc, the variable Pt_ 
# – for transmitter power – is declared; the default value of 0.28183815 W translates to a physical range 
# of 250 meters using the appropriate radio-attenuation model.

Mac/802_11 set dataRate_ 11Mb

#
# Initialize Global Variables
#

set startpingtime 0.5
set startime 1.0
set stoptime 101.0
set stoppingtime 110.0
set endtime 120.0

set ns_		[new Simulator]
set tracefd     [open simple-wireless.tr w]
$ns_ trace-all $tracefd

set namtrace [open simple-wireless.nam w]           ;# for nam tracing
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]

$topo load_flatgrid val(x) val(y)

#
# Create God
#
set god_ [create-god $val(nn)]

# The shortest path between node 1 and 2 is 2 hops
$god_ set-dist 1 2 2

# Create channel #1 and #2
set chan_1_ [new $val(chan)]
set chan_2_ [new $val(chan)]

#
#  Create the specified number of mobilenodes [$val(nn)] and "attach" them
#  to the channel. 
#  Here three nodes are created : node(0), node(1) and node (2)
#  node (0) is allowing node(1) to communicate with node(2) and viceversa.

# configure node

        $ns_ node-config -adhocRouting $val(rp) \
			 -llType $val(ll) \
			 -macType $val(mac) \
			 -ifqType $val(ifq) \
			 -ifqLen $val(ifqlen) \
			 -antType $val(ant) \
			 -propType $val(prop) \
			 -phyType $val(netif) \
			 -topoInstance $topo \
			 -agentTrace ON \
			 -routerTrace ON \
			 -macTrace ON \
			 -movementTrace OFF \
			 -channel $chan_1_
	
set node_(0) [$ns_ node]
set node_(1) [$ns_ node]
# node_(2) can also be created with the same configuration, or with a different
# channel specified.
# Uncomment below two lines will create node_(1) with a different channel.
#  $ns_ node-config \
#		 -channel $chan_2_ 
set node_(2) [$ns_ node]
		 
for {set i 0} {$i < $val(nn) } {incr i} {
	$node_($i) random-motion 0		;# disable random motion
}

#
# Provide initial (X,Y, for now Z=0) co-ordinates for (mobile) wireless nodes (even though this will not move)
# Worst case is in diagonal

$node_(0) set X_ [expr $val(x)/2]
$node_(0) set Y_ [expr $val(y)/2]
$node_(0) set Z_ 0.0

$node_(1) set X_ 5.0
$node_(1) set Y_ 5.0
$node_(1) set Z_ 0.0

$node_(1) set X_ [expr $val(x)-5.0]
$node_(1) set Y_ [expr $val(y)-5.0]
$node_(1) set Z_ 0.0

$ns_ initial_node_pos $node_(0) 20
$ns_ initial_node_pos $node_(1) 20
$ns_ initial_node_pos $node_(2) 20

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
$ns_ attach-agent $node_(1) $bp1
$ns_ at $startpingtime "$bp1 send"
$ns_ at $stoptime "$bp1 set packetSize_ 1064"
$ns_ at [expr ($startime+$stoptime)/2.0] "$bp1 send"
$ns_ at $stoppingtime "$bp1 send"

# Building 2 Ping Agent
set bp2 [new Agent/Ping]
$bp2 set packetSize_ 64
$bp2 set fid_ 100
$bp2 set prio_ 0
$ns_ attach-agent $node_(2) $bp2
$ns_ connect $bp1 $bp2
$ns_ at $stoptime "$bp2 set packetSize_ 1064"

#
# Setup traffic flow between nodes
# TCP connections between node_(1) and node_(2)

set tcp [new Agent/TCP]
$tcp set class_ 2
$tcp set packetSize_ 2264
$tcp attach $tracefd
$tcp tracevar ack_
$tcp tracevar maxseq_
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(1) $tcp
$ns_ attach-agent $node_(2) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at $startime "$ftp start"
$ns_ at $stoptime "$ftp stop"

## set up a VoIP

set s1 [new Agent/UDP]
$s1 set fid_ 0
$ns_ attach-agent $node_(1) $s1

set null1 [new Agent/UDP]
$ns_ attach-agent $node_(2) $null1

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
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $endtime "$node_($i) reset";
}
$ns_ at $endtime "stop"
$ns_ at [expr $endtime+0.01] "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd namtrace tcp startime stoptime voip_r
    $ns_ flush-trace
    close $tracefd
    close $namtrace
    $voip_r update_score
    puts "[$voip_r set delay_] [$voip_r set rscore_] [$voip_r set mos_]"
    set lastAck [$tcp set ack_]
    set lastSEQ [$tcp set maxseq_]
	set reTxNum [$tcp set nrexmitpack_]    
	puts "Wireless Tx Power (W): [Phy/WirelessPhy set Pt_]"
	puts "802.11 data Rate (bits/s): [Mac/802_11 set dataRate_]"
	puts "Final ack: $lastAck, final seq num: $lastSEQ, Number of reTx packets: $reTxNum"
    puts "Estimated goodput: [expr $lastAck*8*2.264/($stoptime-$startime)] kbits/s [expr $lastAck*2264] bytes in [expr $stoptime-$startime] s"
    puts "Estimated throughput: [expr $lastSEQ*2.304*8/($stoptime-$startime)] kbits/s [expr $lastSEQ*2304] bytes in [expr $stoptime-$startime] s"
	
    puts "run nam  simple-wireless.nam..."
    # exec nam  simple-wireless.nam &
}

puts "Starting Simulation..."
$ns_ run

