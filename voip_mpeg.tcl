#!/home/raffaello/ns-allinone-2.35/ns-2.35/ns
# ERG-UoA Aberdeen (UK), May 2008 - September 2017

# CONFIGURATION VARIABLES ###########################################

;# testing == 1  enables tracing for debugging purposes

if { $argc != 7 } {
	puts "usage: ns voip_mpeg.tcl <CRA kbps> <RBDC=0/1> <VBDC=0/1> <# streams/term> <smoothing par. alpha (0,1) for RBDC (the higher the smoother)> <num_terminals> <NbrRLC>"
	exit 0
}

ns-random 0

Allocator/MFTDMA set testing_ 0

Allocator/MFTDMA set layout_ 0            ;# First-Fit=0, Best-Fit=1
Allocator/MFTDMA set mode_ 1              ;# Slot-based=0, Continuous=1
Allocator/MFTDMA set forget_debit_ 1      ;# Carry-Next-Frame=0, Not-Carry-Next-Frame=1

Allocator/MFTDMA set hwin_ 400
Requester/Combiner set req_period_ 0.080
Requester/Combiner set alpha_ [lindex $argv 4]
Requester/Combiner set win_ [expr int(0.6/[Requester/Combiner set req_period_]+1)]

set testing            1
Allocator/MFTDMA set frame_duration_ 0.080

set terrestrial_delay          10ms
set terrestrial_capacity      100Mb

set lan_delay          10ms
set lan_capacity      100Mb

set bdrop_rate 0.0

set per 1e-3

# VoIP Flows (IPsec/CRTP/G729)
# max tolerable delay (ms)

set voip(interval)      0.04
set voip(burst_time)    0.46
set voip(idle_time)     0.54
set voip(plen)            76
set voip(no_voip)       [lindex $argv 3] 
set voip(index)            0

set no_terminals	[lindex $argv 5]
set NbrRLC		[lindex $argv 6]

set start 1.0
set reset 200.0
set stop  300.0

set duration [expr $stop+200]

##########################################################

proc new-voip { i } {
	global ns voip rcst hq user 
	global start reset stop no_terminals

	set voip(s$i) [new Application/Traffic/Voice]
	set voip(r$i) [new Application/Traffic/Voice]
	set udp_s [new Agent/UDP]
	set udp_r [new Agent/UDP]

	$voip(s$i) attach-agent $udp_s
	$voip(s$i) set interval_ $voip(interval)
	$voip(s$i) set burst_time_ $voip(burst_time)
	$voip(s$i) set idle_time_ $voip(idle_time)
	$voip(s$i) set packetSize_ $voip(plen)
	$voip(r$i) attach-agent $udp_r
	
	$udp_s set index $i
	$udp_s set fid_ 0
	$udp_s set prio_ 0 
	$udp_r set index $i

	set n [expr [ns-random] % $no_terminals]

	$ns attach-agent $user($n) $udp_s
	$ns attach-agent $hq $udp_r	
	$ns connect $udp_s $udp_r

	$ns at $start "$voip(s$i) start"
	$ns at $reset "$voip(r$i) reset"
	$ns at $stop "$voip(s$i) stop"
}

proc new-ping { i } {
	global ns ping rcst hq user
	global start reset stop no_terminals

	set ping(r$i) [new Agent/Ping]
	$ping(r$i) set packetSize_ 64
	$ping(r$i) set fid_ 1
	$ping(r$i) set prio_ 0
	set n [expr $i % $no_terminals]
	$ns attach-agent $user($n) $ping(r$i)
	$ns at $start "$ping(r$i) send"
	$ns at $reset "$ping(r$i) send"
	# $ns at $stop "$ping(r$i) send"

	set ping(f$i) [new Agent/Ping]
	$ping(f$i) set packetSize_ 64
	$ping(f$i) set fid_ 1
	$ping(f$i) set prio_ 0
	$ns attach-agent $hq $ping(f$i)
	$ns connect $ping(f$i) $ping(r$i)
}

proc new-tcp-poisson { i } {
	global ns tcpexp rcst hq user
	global start reset stop no_terminals

	set rs [new Agent/TCP/FullTcp]
	$rs set tcpip_base_hdr_size_ 40
	$rs set packetSize_ 1460
	$rs set fid_ 2
	$rs set prio_ 100
	set n [expr $i % $no_terminals]
	$ns attach-agent $user($n) $rs
	set rsink [new Agent/TCPSink]
	$ns attach-agent $hq $rsink
	$ns connect $rs $rsink
	set tcpexp(s$i) [new Application/Traffic/Exponential]
	$tcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	$tcpexp(s$i) set packetSize_ 210
# The Exponential On/Off generator can be configured to behave as a Poisson process by setting the variable burst_time
# to 0 and the variable rate_ to a very large value. The C++ code guarantees that even if the burst time is zero, at least one
# packet is sent. Additionally, the next interarrival time is the sum of the assumed packet transmission time (governed by the
# variable rate_) and the random variate corresponding to idle_time_. Therefore, to make the first term in the sum very
# small, make the burst rate very large so that the transmission time is negligible compared to the typical idle times.
	$tcpexp(s$i) set rate_ 10000Mb
	$tcpexp(s$i) set burst_time_ 0
	$tcpexp(s$i) set idle_time_ 5
	$ns at $start "$tcpexp(s$i) start"
	$ns at $stop "$tcpexp(s$i) stop"
}

# Creating scenario  ##########################

set ns [new Simulator]

if { $testing == 1 } {
	# Tracing enabling must 
	# precede link and node creation 
	set outfile [open voip_mpeg.tr w]
	$ns trace-all $outfile
}

puts "Initial PER=$bdrop_rate"
puts "At t=$reset PER=$per"

# Head-Quarter node
set hq    [$ns node]
 
# Configure bent-pipe satellite
$ns node-config -wiredRouting ON \
                -satNodeType geo-repeater \
                -phyType Phy/Repeater \
                -channelType Channel/Sat



set sat [$ns node]
# GEO satellite at 13 degrees longitude East (Hotbird 6)
# $sat set-position 13
# GEO satellite at 25.1 degrees longitude East (I4)
$sat set-position 25.1

# Set the default packing threshold in s
LL/Mpeg set pack_thresh 0.1

$ns node-config -satNodeType terminal \
                -llType LL/Mpeg \
		-ifqLen 250 \
		-macType Mac/TdmaDama \
		-requesterType Requester/Combiner \
		-phyType Phy/Sat


set hub   [$ns node]
$hub set-position 53.3 6.2; # BURUM
$ns setup-geolink $hub $sat
set hub_mac [$hub set mac_(0)]
# Add a packet error model to the receiving terminal
set em_hub [new ErrorModel]
# $em_hub unit byte
# Byte error rate = 1 - (1-BER)^8
# $em_hub set rate_ [expr 1-pow((1-$ber),8)]
$em_hub unit pkt
$em_hub set rate_ $bdrop_rate
$em_hub ranvar [new RandomVariable/Uniform]
$hub interface-errormodel $em_hub
$ns at $reset "$em_hub set rate_ $per"

for {set i 0} { $i < $no_terminals } {incr i} {
	set user($i) [$ns node]
	set rcst($i) [$ns node]
	$rcst($i) set-position 43.71 10.38
	$ns duplex-link $user($i) $rcst($i) $lan_capacity $lan_delay DropTail
	$ns at 0.0 "$rcst($i) start-req"
	$ns setup-geolink $rcst($i) $sat
	set ter_mac($i) [$rcst($i) set mac_(0)]
	[$rcst(0) set phy_tx_(0)] set bdrop_rate_ $bdrop_rate
	# Add a packet error model to the receiving terminal
	set emt($i) [new ErrorModel]
	# $emt($i) unit byte
	# Byte error rate = 1 - (1-BER)^8
	# $emt($i) set rate_ [expr 1-pow((1-$ber),8)]
	$emt($i) unit pkt
	$emt($i) set rate_ $bdrop_rate
	$emt($i) ranvar [new RandomVariable/Uniform]
	$rcst($i) interface-errormodel $emt($i)
	$ns at $reset "$emt($i) set rate_ $per"
}


if { $testing == 1 } {
        set ev_file [open voip_mpeg_event.tr w]
        $hub trace-event $ev_file
        for {set i 0} { $i < $no_terminals } {incr i} {
                $rcst($i) trace-event $ev_file
        }
        $ns trace-all-satlinks $outfile

}


# Network Control Center
set rrm [$hub install-allocator Allocator/MFTDMA]

################### RRM CONF ######################

#### Forward Link
# 1 carriers with 9 timeslots per carrier and 188 bytes per timeslot => 1*9*188*8/0.080 = 169.200 kbit/s => 1 cell assigned per frame are 18.800 kbit/s

set DL_frame [$rrm new-frame 1 9 188]
$rrm add-rule $hub_mac $DL_frame
$rrm cra $hub_mac 170
$ns at $reset "$hub_mac reset"

#### Return Link 

set f0 [$rrm new-frame $NbrRLC 7 188]

for {set i 0} {$i<$no_terminals} {incr i} {
	$rrm add-rule $ter_mac($i) $f0
	$rrm cra $ter_mac($i) [lindex $argv 0]
	[$rcst($i) set requester_] set rbdc_ [lindex $argv 1]
	[$rcst($i) set requester_] set vbdc_ [lindex $argv 2]
	$ns at $reset "$ter_mac($i) reset"
}

if { $testing == 1 } {
	$ns at $start {
		set ps_anim [open "voip_mpeg_superframe.ps" w]
		$rrm trace-sf $ps_anim
	}
}

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

###################################################

# We use centralized routing
set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes

$ns duplex-link $hq $hub $terrestrial_capacity $terrestrial_delay DropTail


proc finish-sim {} {
	global testing ns rrm ter_mac voip reset

	$ns flush-trace

	set used [$ter_mac(0) set used_slots_]
	set total [$ter_mac(0) set total_slots_]

	if {$total > 0 } {
		set eff [expr double($used)/$total]
	} else {
		set eff 0.0
	}
	puts "Terminal 0 used $used bytes of total $total (efficiency $eff) after t=$reset s."
#	$voip(r0) update_score
#	puts "[$voip(r0) set max_delay_] [$voip(r0) set rscore_] [$voip(r0) set mos_]"

	$ns halt
}

for {set i 0} {$i<$no_terminals} {incr i} {
#	for {set j 0} { $j < $voip(no_voip)} {incr j} {
	#	$ns at $start "new-voip [expr $i*$voip(no_voip)+$j]"
	#	$ns at $start "new-ping [expr $i*$voip(no_voip)+$j]"
	$ns at $start "new-ping $i"
	#	$ns at $start "new-tcp-poisson [expr $i*$voip(no_voip)+$j]"
	#}
}

$ns at $duration "finish-sim"

$ns run 

