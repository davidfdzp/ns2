## sat-aloha-rl-mftdma-fl-model.tcl - Based on sat-aloha.tcl example for the RL and mftdma-dama-model.tcl for the FL

# Script with a geostationary bent-pipe (repeater) satellite and
# 0 terminals using unslotted (pure) Aloha random access in the RL. The
# traffic sources consist of traffic trace agents or exponential
# on-off traffic generators.
# Options:
# 1. basic: MAC operates in stop-and-wait mode (one outstanding packet
#           at a time). Collisions and drops are not traced.
# 2. basic_tracing: Same as "basic", but drops ("d") and collisions ("c")
#                   are instead explicitly traced.
# 3. poisson: Packets arrive according to Poisson process. Each source
#             still operates in stop-and-wait mode and collisions and
#             drops are traced. rtx_limit = 0 (no persistence).
#             This can be used to try to approximate theoretical
#             unslotted Aloha results, if the number of terminals is large
#             compared to the arrival rate (so that no packets are queued)
# 4. [FOR FUTURE WORK]: larger than one packet rxmit buffer...

set traffic_duration 10.0
set start 1.0
set reset [expr $start + 1.0]
set stop  [expr $reset + $traffic_duration]

set rpingstime0 $reset
set fpingstime0 [expr $rpingstime0 + 1.0]
set fpingstime1 [expr $stop + 1.0]
set rpingstime1 [expr $fpingstime1 + 1.0]

set duration [expr $rpingstime1 + 1.0]

if { $argc <1 } {
	puts stderr {usage: ns sat-aloha-rl-mftdma-fl-model.tcl (basic | basic_tracing | poisson) <num_terminals> [NbrRLC] }
	exit 1
}

set test_ [lindex $argv 0]

set no_terminals         [lindex $argv 1]

set NbrFLC 1

if { $argc > 2 } {
	set NbrRLC [lindex $argv 2]
} else {
	set NbrRLC 1
}
puts "Running test $test_ with $no_terminals terminals, $NbrFLC FL carriers and $NbrRLC RL carriers..."

ns-random 0

# Creating scenario  ##########################

global ns
set ns [new Simulator]

;# testing == 1  enables tracing for debugging purposes

Allocator/MFTDMA set testing_ 0
Allocator/MFTDMA set layout_ 0            ;# First-Fit=0, Best-Fit=1
Allocator/MFTDMA set mode_ 1              ;# Slot-based=0, Continuous=1
Allocator/MFTDMA set forget_debit_ 1      ;# Carry-Next-Frame=0, Not-Carry-Next-Frame=1

Allocator/MFTDMA set hwin_ 400

set testing            1
Allocator/MFTDMA set frame_duration_ 0.080
# Global configuration parameters for Aloha (also settable in ns-sat.tcl)
Mac/Sat/UnslottedAloha set mean_backoff_ 1s ; # mean exponential backoff time(s)
Mac/Sat/UnslottedAloha set rtx_limit 3; # max number of retrans. attempted
Mac/Sat/UnslottedAloha set send_timeout_ 270ms; # resend if send times out
# Mac/Sat/UnslottedAloha set send_timeout_ 900ms; # resend if send times out


# The SatLL object passes the packet up after a processing delay (again, by default, the value for delay_ is zero).
Mac/Sat set delay_ 50.000000ms
if { $test_ == "basic"} {
	Mac/Sat set trace_collisions_ false
	Mac/Sat set trace_drops_ false
}


# set ber 0.0
set per 0.0

# Burst drop rate (PER)
set bdrop_rate $per

set mtu 1500

set set_prio 0
set set_fid 1
set data_prio 0
set voice_prio 0

set terrestrial_delay         10.000ms
set terrestrial_capacity      100Mb

set lan_delay         10.000ms
set lan_capacity      100Mb

set num_cos 8

proc new-pings { i } {
	global ns ping hq user
	global rpingstime0 rpingstime1 fpingstime0 fpingstime1 no_terminals

	set ping(r$i) [new Agent/Ping]
	$ping(r$i) set packetSize_ 64
	$ping(r$i) set fid_ 1
	$ping(r$i) set prio_ 0
	set n [expr $i % $no_terminals]
	$ns attach-agent $user($n) $ping(r$i)
	$ns at $rpingstime0 "$ping(r$i) send"
#	$ns at $rpingstime1 "$ping(r$i) send"
	
	set ping(f$i) [new Agent/Ping]
	$ping(f$i) set packetSize_ 64
	$ping(f$i) set fid_ 1
	$ping(f$i) set prio_ 0
	$ns attach-agent $hq $ping(f$i)
	$ns connect $ping(f$i) $ping(r$i)
	# $ns at $fpingstime0 "$ping(f$i) send"
	# $ns at $fpingstime1 "$ping(f$i) send"
}

proc new-rl-tcp-poisson { i } {
	global ns tcpexp hq user mtu data_prio num_cos
	global start reset stop no_terminals

	set rs [new Agent/TCP/FullTcp/Sack]
	$rs set tcpip_base_hdr_size_ 40
	$rs set segsize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	$rs set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	$rs set fid_ [expr 1 + ($i % $num_cos)]
	$rs set prio_ $data_prio
	set n [expr $i % $no_terminals]
	$ns attach-agent $user($n) $rs
	set rsink [new Agent/TCPSink]
	$ns attach-agent $hq $rsink
	$ns connect $rs $rsink
	set tcpexp(s$i) [new Application/Traffic/Exponential]
	$tcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	$tcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$rs set packetSize_]]
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

proc new-fl-tcp-poisson { i } {
	global ns tcpexp hq user mtu data_prio num_cos
	global start reset stop no_terminals

	set fs [new Agent/TCP/FullTcp/Sack]
	$fs set tcpip_base_hdr_size_ 40
	$fs set segsize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set fid_ [expr 1 + ($i % $num_cos)]
	$fs set prio_ $data_prio	
	$ns attach-agent $hq $fs
	set fsink [new Agent/TCPSink]
	set n [expr $i % $no_terminals]
	$ns attach-agent $user($n) $fsink
	$ns connect $fs $fsink
	set tcpexp(s$i) [new Application/Traffic/Exponential]
	$tcpexp(s$i) attach-agent $fs
	# This is the default packetSize value
	$tcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$fs set packetSize_]]
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

# We'll set these global options for the satellite terminals
global optAir
set optAir(chan)           Channel/Sat
set optAir(bw_up)	[expr $NbrRLC*84800]
set optAir(bw_down)	[expr $NbrRLC*84800]
set optAir(phy)            Phy/Sat
set optAir(mac)            Mac/Sat/UnslottedAloha
# set optAir(ifq)            Queue/DropTail
set optAir(ifq)            Queue/DropTail/PrioFid
# set optAir(qlim)		5
set optAir(qlim)		50
set optAir(ll)             LL/Sat
set optAir(wiredRouting)   ON

if { $testing == 1 } {
	# Tracing enabling must precede link and node creation
#	set winfile [open WinFile w]
	set outfile [open sat-aloha-rl-mftdma-fl-model.tr w]
	$ns trace-all $outfile
}

puts "Initial PER=$bdrop_rate"
puts "At t=$reset PER=$per"

# Set up satellite and terrestrial nodes

# Normal nodes

# Head-Quarter node
set hq    [$ns node]

for {set i 0} { $i < $no_terminals } {incr i} {
	set user($i) [$ns node]
}

# Configure FL bent-pipe satellite
$ns node-config -wiredRouting ON \
				-satNodeType geo-repeater \
				-phyType Phy/Repeater \
				-channelType Channel/Sat\

# GEO satellite at 24.9 degrees longitude East (Alphasat)
set sat_fl [$ns node]
$sat_fl set-position 24.9

# GEO satellite at 25.1 degrees longitude East (I4)
# $sat_fl set-position 25.1

# Other possibilities: -llType LL/Atm -llType LL/Mpeg
# -llType LL/Rle requires Mac/Rle

# Set the default packing threshold in s
LL/Mpeg set pack_thresh 0.1

$ns node-config -satNodeType terminal \
				-llType LL/Mpeg \
				-ifqLen [expr 250 + 4*$no_terminals] \
				-macType Mac/TdmaDama \
				-requesterType Requester/Combiner \
				-phyType Phy/Sat

set hub_fl [$ns node]
$hub_fl set-position 53.3 6.2; # BURUM
$ns simplex-link $hq $hub_fl $terrestrial_capacity $terrestrial_delay DropTail
$ns queue-limit $hq $hub_fl [expr 50 + 3*$no_terminals]
$ns setup-geolink $hub_fl $sat_fl
set hub_fl_mac [$hub_fl set mac_(0)]

for {set i 0} { $i < $no_terminals } {incr i} {
	set rcst_fl($i) [$ns node]
#	$rcst_fl($i) set-position 43.71 10.38
	# Place terminals at different locations in a diagonal line starting from -15, 15 and down to 0, 0 (the Null Island) 
	$rcst_fl($i) set-position [expr -15 + $i * 15/$no_terminals] [expr 15 - $i * 15/$no_terminals]
	$ns simplex-link $rcst_fl($i) $user($i) $lan_capacity $lan_delay DropTail
	$ns queue-limit $rcst_fl($i) $user($i) 50
	$ns setup-geolink $rcst_fl($i) $sat_fl
	set ter_fl_mac($i) [$rcst_fl($i) set mac_(0)]
	[$rcst_fl(0) set phy_tx_(0)] set bdrop_rate_ $bdrop_rate
	# Add a packet error model to the FL receiving terminal
	set em_fl_t($i) [new ErrorModel]
	# $em_fl_t($i) unit byte
	# Byte error rate = 1 - (1-BER)^8
	# $em_fl_t($i) set rate_ [expr 1-pow((1-$ber),8)]
	$em_fl_t($i) unit pkt
	$em_fl_t($i) set rate_ $bdrop_rate
	$em_fl_t($i) ranvar [new RandomVariable/Uniform]
	$rcst_fl($i) interface-errormodel $em_fl_t($i)
	$ns at $reset "$em_fl_t($i) set rate_ $per"
}

$ns node-config -satNodeType geo-repeater \
		-llType $optAir(ll) \
		-ifqType $optAir(ifq) \
		-ifqLen $optAir(qlim) \
		-macType $optAir(mac) \
		-phyType $optAir(phy) \
		-channelType $optAir(chan) \
		-downlinkBW $optAir(bw_down)  \
		-wiredRouting $optAir(wiredRouting)

set sat_rl [$ns node]

# GEO satellite at 24.9 degrees longitude East (Alphasat)
$sat_rl set-position 24.9

# GEO satellite at 25.1 degrees longitude East (I4)
# $sat_rl set-position 25.1

# Configure the node generator for ground satellite terminal
$ns node-config -satNodeType terminal \
				-llType $optAir(ll) \
				-ifqType $optAir(ifq) \
				-ifqLen $optAir(qlim) \
				-macType $optAir(mac) \
				-phyType $optAir(phy) \
				-channelType $optAir(chan) \
				-downlinkBW $optAir(bw_down) \
				-wiredRouting $optAir(wiredRouting)

# Place Hub
set hub_rl [$ns node]
$hub_rl set-position 53.3 6.2; # BURUM
$ns simplex-link $hub_rl $hq $terrestrial_capacity $terrestrial_delay DropTail
$ns queue-limit $hub_rl $hq [expr 50 + 3*$no_terminals]
# Add GSLs to geo satellite from/to the hub
$hub_rl add-gsl geo $optAir(ll) $optAir(ifq) $optAir(qlim) $optAir(mac) $optAir(bw_up) \
$optAir(phy) [$sat_rl set downlink_] [$sat_rl set uplink_]

# Add an error model to the receiving terminal node in the hub
set em_ [new ErrorModel]
# $em_ unit byte
# Byte error rate = 1 - (1-BER)^8
# $em_ set rate_ [expr 1-pow((1-$ber),8)]
$em_ unit pkt
$em_ set rate_ $per
$em_ ranvar [new RandomVariable/Uniform]
$hub_rl interface-errormodel $em_

for {set i 0} { $i < $no_terminals } {incr i} {
	set rcst_rl($i) [$ns node]
	$ns simplex-link $user($i) $rcst_rl($i) $lan_capacity $lan_delay DropTail
	$ns queue-limit $user($i) $rcst_rl($i) 50	
	# $rcst_rl($i) set-position 43.71 10.38
	# Place terminals at different locations in a diagonal line starting from -15, 15 and down to 0, 0 (the Null Island) 
	$rcst_rl($i) set-position [expr -15 + $i * 15/$no_terminals] [expr 15 - $i * 15/$no_terminals]
	$rcst_rl($i) add-gsl geo $optAir(ll) $optAir(ifq) $optAir(qlim) $optAir(mac) $optAir(bw_up) \
$optAir(phy) [$sat_rl set downlink_] [$sat_rl set uplink_]	
}

if { $testing == 1 } {
	set fl_ev_file [open fl_event_rl_aloha.tr w]
	$hub_fl trace-event $fl_ev_file
	$ns trace-all-satlinks $outfile
}

# Network Control Center
set rrm_fl [$hub_fl install-allocator Allocator/MFTDMA]

################### RRM CONF ######################

## Allocator/MFTDMA set frame_duration_ e.g. 0.080 (see above)

#### Forward Link

# MPEG
# 1 carriers with 9 timeslots per carrier and 188 bytes per timeslot => 1*9*188*8/0.080 = 169.200 kbit/s => 1 cell assigned per frame are 18.800 kbit/s
set DL_frame [$rrm_fl new-frame $NbrFLC 9 188]
$rrm_fl add-rule $hub_fl_mac $DL_frame
$rrm_fl cra $hub_fl_mac [expr $NbrFLC*170]
$ns at $reset "$hub_fl_mac reset"

if { $testing == 1 } {
	$ns at $start {
		set ps_anim_fl [open "fl_superframe_rl_aloha.ps" w]
		$rrm_fl trace-sf $ps_anim_fl
	}
}
#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

# We use centralized routing
set satrouteobject_ [new SatRouteObject]
$satrouteobject_ compute_routes

proc finish-sim {} {
	global testing ns rrm_fl test_ hub_fl_mac reset
	
	$ns flush-trace
	
	set used_fl [$hub_fl_mac set used_slots_]
	set total_fl [$hub_fl_mac set total_slots_]
	if {$total_fl > 0} {
		set eff_fl [expr double($used_fl)/$total_fl]
	} else {
		set eff_fl 0
	}
	puts "Hub used $used_fl of $total_fl bytes assigned (occupation $eff_fl)"

	$ns halt

}

for {set i 0} {$i<$no_terminals} {incr i} {
	$ns at $start "new-pings $i"
	if {$test_ == "basic" || $test_ == "basic_tracing" || $test_ == "poisson"} {
		$ns at $start "new-rl-tcp-poisson $i"
		$ns at $start "new-fl-tcp-poisson $i"
	}
}

$ns at $duration "finish-sim"

$ns run
