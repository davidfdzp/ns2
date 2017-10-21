#!/home/raffaello/ns-allinone-2.35/ns-2.35/ns
# ERG-UoA Aberdeen (UK), May 2008
# D. Fernández - September 2017

# CONFIGURATION VARIABLES ###########################################

;# testing == 1  enables tracing for debugging purposes

if { $argc != 8 } {
	puts "usage: ns mftdma-dama-model-rl-fl.tcl <CRA kbps> <RBDC=0/1> <VBDC=0/1> <AVBDC=0/1> <# streams/term> <smoothing par. alpha (0,1) for RBDC (the higher the smoother)> <num_terminals> <NbrRLC>"
	exit 0
}

ns-random 0

Allocator/MFTDMA set testing_ 0
Allocator/MFTDMA set layout_ 0            ;# First-Fit=0, Best-Fit=1
Allocator/MFTDMA set mode_ 1              ;# Slot-based=0, Continuous=1
Allocator/MFTDMA set forget_debit_ 1      ;# Carry-Next-Frame=0, Not-Carry-Next-Frame=1

Allocator/MFTDMA set hwin_ 400
Requester/Combiner set req_period_ 0.080
# RBDC request = alpha_ * RATE + (1-alpha_)*PREV_REQUEST
Requester/Combiner set alpha_ [lindex $argv 5]
Requester/Combiner set win_ [expr int(0.6/[Requester/Combiner set req_period_]+1)]

set testing            1
Allocator/MFTDMA set frame_duration_ 0.080

set terrestrial_delay          10ms
set terrestrial_capacity      100Mb

set lan_delay          10ms
set lan_capacity      100Mb

set bdrop_rate 0.0
set per 1e-3

# QoS and CoS configuration
set set_prio 0
set set_fid 1
set data_prio 0
set voice_prio 0

set mtu 1500

set voip(interval)      0.08
set voip(burst_time)    0.46
set voip(idle_time)     0.54
set voip(plen)            96
set voip(no_voip)       [lindex $argv 4] 
set voip(index)            0

set no_terminals         [lindex $argv 6]

set num_cos 8

set NbrFLC 1
set NbrRLC [lindex $argv 7]

set traffic_duration 10.0
set start 1.0
set reset [expr $start + 1.0]
set stop  [expr $reset + $traffic_duration]

set rpingstime0 $reset
set fpingstime0 [expr $rpingstime0 + 1.0]
set fpingstime1 [expr $stop + 1.0]
set rpingstime1 [expr $fpingstime1 + 1.0]

set duration [expr $rpingstime1 + 1.0]

##########################################################

proc new-rl-voip { i } {
	global ns voip hq user voice_prio
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
	$voip(r$i) set A_ 20
	$voip(r$i) attach-agent $udp_r
	
	$udp_s set index $i
	$udp_s set fid_ 0
	$udp_s set prio_ $voice_prio 
	$udp_r set index $i

	set n [expr [ns-random] % $no_terminals]

	$ns attach-agent $user($n) $udp_s
	$ns attach-agent $hq $udp_r	
	$ns connect $udp_s $udp_r

	$ns at $start "$voip(s$i) start"
	$ns at $reset "$voip(r$i) reset"
	$ns at $stop "$voip(s$i) stop"
}

proc new-fl-voip { i } {
	global ns voip hq user voice_prio
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
	$voip(r$i) set A_ 20
	$voip(r$i) attach-agent $udp_r
	
	$udp_s set index $i
	$udp_s set fid_ 0
	$udp_s set prio_ $voice_prio 
	$udp_r set index $i

	set n [expr [ns-random] % $no_terminals]

	$ns attach-agent $hq $udp_s
	$ns attach-agent $user($n) $udp_r		
	$ns connect $udp_s $udp_r

	$ns at $start "$voip(s$i) start"
	$ns at $reset "$voip(r$i) reset"
	$ns at $stop "$voip(s$i) stop"
}

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
	# Print TCP parameters
	#   Window_ sets the ssthreshold. Terrestrial TCP senders use as
#		initial ssthreshold value of 38 pkts as it is common.
#		Since the advwindow is implemented this value is only used to initialize the value of 
#		ssthreshold and must be sufficient high to not distub the operation of TCP sender
#		Note that cwnd_ is bounded by min (window_, advwindow_, maxcwnd_)
#		For Satelite TCP sender a high value is set to analize in TCP SACk baseline the Slow Start
#		behaviour over LFN satelite networks preventing the smooth transition between Slow Start 
#		and Congestion Avoidance phases.
# 	$rs set window_ 20
#   $rs set window_ $buff_size_pkts
	puts "TCP slow start threshold: [$rs set window_]"
#   $rs set tcpTick_ 0.01
	puts "TCP tick: [$rs set tcpTick_]"
# default value
#   $rs set windowInit_ 2
#   $rs set windowInit_ 3
#   $rs set windowInit_ 10
#   $rs set windowInit_ $buff_size_pkts
    puts "TCP initial window size: [$rs set windowInit_]"
#	puts "TCP initial window size: [$rs set wnd_init_]"
# 		The advwindow_ initial value is set the initial ssthreshold value in TCP senders. This 
#		value is used by TCP sender until the receiver updates its value to the advertize receiver 
#		window 
#   $rs set advwindow_ 		[$rs set window_]
	# puts "TCP advertised window size: [$rs set advwindow_]"
	# The advertised window is simulated by simply telling the sender a bound on the window size (wnd_).
	# In real TCP, a user process performing a read (via PRU_RCVD) calls tcp_output each time to (possibly) send a window
    # update.  Here we don't have a user process, so we simulate a user process always ready to consume all the receive buffer *
 # Notes: wnd_, wnd_init_, cwnd_, ssthresh_ are in segment units, sequence and ack numbers are in byte units
 	# puts "TCP advertised window size: [$rs set wnd_]"
#		maxcwnd_ is the upper bound of TCP sender cwnd_	. The cwnd_ is bounded by 
#		min (advwindow_, maxcwnd_)	
# 	$rs set maxcwnd_ 5000
	puts "TCP maximum congestion window size: [$rs set maxcwnd_]"
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

# Creating scenario  ##########################

set ns [new Simulator]

if { $testing == 1 } {
	# Tracing enabling must 
	# precede link and node creation 
	set outfile [open mftdma-dama-model-rl-fl.tr w]
	$ns trace-all $outfile
}

puts "Initial PER=$bdrop_rate"
puts "At t=$reset PER=$per"

# Head-Quarter node
set hq    [$ns node]

for {set i 0} { $i < $no_terminals } {incr i} {
	set user($i) [$ns node]
}

# Configure bent-pipe satellites
$ns node-config -wiredRouting ON \
                -satNodeType geo-repeater \
                -phyType Phy/Repeater \
                -channelType Channel/Sat


set sat_rl [$ns node]
# GEO satellite at 13 degrees longitude East (Hotbird 6)
# $sat_rl set-position 13
# GEO satellite at 24.9 degrees longitude East (Alphasat)
$sat_rl set-position 24.9
# GEO satellite at 25.1 degrees longitude East (I4)
# $sat_rl set-position 25.1

set sat_fl [$ns node]
$sat_fl set-position 25.1

# Set the default packing threshold in s
LL/Mpeg set pack_thresh 0.1

$ns node-config -satNodeType terminal \
                -llType LL/Mpeg \
		-ifqLen [expr 250 + 4*$no_terminals] \
		-macType Mac/TdmaDama \
		-requesterType Requester/Combiner \
		-phyType Phy/Sat


set hub_fl   [$ns node]
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

$ns node-config -satNodeType terminal \
                -llType LL/Atm \
		-ifqLen [expr 250 + 3*$no_terminals] \
		-macType Mac/TdmaDama \
		-requesterType Requester/Combiner \
		-phyType Phy/Sat

set hub_rl   [$ns node]
$hub_rl set-position 53.3 6.2; # BURUM
$ns simplex-link $hub_rl $hq $terrestrial_capacity $terrestrial_delay DropTail
$ns queue-limit $hub_rl $hq [expr 50 + 3*$no_terminals]
$ns setup-geolink $hub_rl $sat_rl
set hub_rl_mac [$hub_rl set mac_(0)]
# Add a packet error model to the receiving terminal
set em_hub [new ErrorModel]
# $em_hub unit byte
# Byte error rate = 1 - (1-BER)^8
# $em_hub set rate_ [expr 1-pow((1-$ber),8)]
$em_hub unit pkt
$em_hub set rate_ $bdrop_rate
$em_hub ranvar [new RandomVariable/Uniform]
$hub_rl interface-errormodel $em_hub
$ns at $reset "$em_hub set rate_ $per"

for {set i 0} { $i < $no_terminals } {incr i} {
	set rcst_rl($i) [$ns node]
#	$rcst_rl($i) set-position 43.71 10.38
# Place terminals at different locations in a diagonal line starting from -15, 15 and down to 0, 0 (the Null Island) 
	set latitude [expr -15 + $i * 15/$no_terminals]
	set longitude [expr 15 - $i * 15/$no_terminals]
	puts "Terminal $i at $latitude, $longitude"
	$rcst_rl($i) set-position  $latitude $longitude	
	$ns simplex-link $user($i) $rcst_rl($i) $lan_capacity $lan_delay DropTail
	$ns queue-limit $user($i) $rcst_rl($i) 50	
	$ns at 0.0 "$rcst_rl($i) start-req"
	$ns setup-geolink $rcst_rl($i) $sat_rl
	set ter_rl_mac($i) [$rcst_rl($i) set mac_(0)]
	[$rcst_rl(0) set phy_tx_(0)] set bdrop_rate_ $bdrop_rate
}

if { $testing == 1 } {
        set rl_ev_file [open mftdma-dama-model-rl-event.tr w]
        $hub_rl trace-event $rl_ev_file
        for {set i 0} { $i < $no_terminals } {incr i} {
                $rcst_rl($i) trace-event $rl_ev_file
        }
	$ns trace-all-satlinks $outfile
}


# Network Control Centers
set rrm_rl [$hub_rl install-allocator Allocator/MFTDMA]
set rrm_fl [$hub_fl install-allocator Allocator/MFTDMA]

################### RRM CONF ######################

#### Forward Link

# MPEG
# 1 carriers with 9 timeslots per carrier and 188 bytes per timeslot => 1*9*188*8/0.080 = 169.200 kbit/s => 1 cell assigned per frame are 18.800 kbit/s
set DL_frame [$rrm_fl new-frame $NbrFLC 9 188]
$rrm_fl add-rule $hub_fl_mac $DL_frame
$rrm_fl cra $hub_fl_mac [expr $NbrFLC*170]
$ns at $reset "$hub_fl_mac reset"

#### Return Link 

# ATM
# 1 carriers with 16 timeslots per carrier and 53 bytes per timeslot => 1*16*53*8/0.080 = 84.800 kbit/s => 1 cell assigned per frame are 5.300 kbit/s
set f0 [$rrm_rl new-frame $NbrRLC 16 53]

for {set i 0} {$i<$no_terminals} {incr i} {
	$rrm_rl add-rule $ter_rl_mac($i) $f0
	$rrm_rl cra $ter_rl_mac($i) [lindex $argv 0]
	[$rcst_rl($i) set requester_] set rbdc_ [lindex $argv 1]
	[$rcst_rl($i) set requester_] set vbdc_ [lindex $argv 2]
	[$rcst_rl($i) set requester_] set avbdc_ [lindex $argv 3]
	$ns at $reset "$ter_rl_mac($i) reset"
}

if { $testing == 1 } {
	$ns at $start {
		set ps_anim_rl [open "mftdma-dama-model-rl_superframe.ps" w]
		$rrm_rl trace-sf $ps_anim_rl
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


proc finish-sim {} {
	global testing ns rrm_rl rrm_fl ter_rl_mac hub_fl_mac voip reset

	$ns flush-trace

	set used_rl [$ter_rl_mac(0) set used_slots_]
	set total_rl [$ter_rl_mac(0) set total_slots_]

	if {$total_rl > 0 } {
		set eff_rl [expr double($used_rl)/$total_rl]
	} else {
		set eff_rl 0.0
	}
	
	set used_fl [$hub_fl_mac set used_slots_]
	set total_fl [$hub_fl_mac set total_slots_]

	if {$total_fl > 0 } {
		set eff_fl [expr double($used_fl)/$total_fl]
	} else {
		set eff_rl 0.0
	}
	
	puts "RL terminal 0 used $used_rl bytes of total $total_rl (efficiency $eff_rl) after t=$reset s."
	puts "FL used $used_fl bytes of total $total_fl (occupation $eff_fl) after t=$reset s."
#	puts "Allocator assigned [$rrm_rl set total_assigned_slots_] slots of [$rrm_rl set total_available_slots_]"
#	puts "Allocator maximum slots assigned on a frame: [$rrm_rl set max_assigned_slots_] of [$rrm_rl set slot_c#ount_]"
#	$voip(r0) update_score
#	puts "[$voip(r0) set max_delay_] [$voip(r0) set rscore_] [$voip(r0) set mos_]"

	$ns halt
}

for {set i 0} {$i<$no_terminals} {incr i} {
	#for {set j 0} { $j < $voip(no_voip)} {incr j} {
		# $ns at $start "new-rl-voip [expr $i*$voip(no_voip)+$j]"
		# $ns at $start "new-fl-voip [expr $i*$voip(no_voip)+$j]"
		# $ns at $start "new-pings [expr $i*$voip(no_voip)+$j]"
		$ns at $start "new-pings $i"
#		$ns at $start "new-rl-tcp-poisson $i"
		# $ns at $start "new-rl-tcp-poisson [expr $i*$voip(no_voip)+$j]"
		# $ns at $start "new-fl-tcp-poisson [expr $i*$voip(no_voip)+$j]"
	#}
}

$ns at $start "new-rl-tcp-poisson 0"

$ns at $duration "finish-sim"

$ns run 

