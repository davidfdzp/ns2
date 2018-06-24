#!$HOME/ns-allinone-2.35/ns-2.35/ns
# model_datalink.tcl - based on tg.tcl example and ERG-UoA Aberdeen (UK), May 2008 VoIP and web traffic generation examples
# D. Fernández - January 2018
# From SatNEx IV CoO2 Part 1 WI4: Forward Packet Scheduling Techniques for Emerging Satellite Scenarios:
# VoIP QoS required: 400 ms max one-way delay, 50 ms max delay jitter, PLR < 1e-3 (coherent with ITU-T Y.1541 class 1)
# TCP QoS required: 15 s max delay (RTT), max delay jitter 10 s, PLR < 1e-4 (coherent with ITU-T Y.1541 class 4)
# Expected traffic load ratio (from Internet stats.):  QoS1/QoS2 = 1/4
# Traffic profile:
# CoS 1 packets: Each video source of this type is modeled as a Markovian ON/OFF source with mean bit-rate of 0.2 Mbps, mean ON phase duration of 1 s, mean OFF phase duration of 4 s, and bit-rate during ON period equal to 1 Mbps.
# CoS 2 packets: Each video source of this type is modeled as a Markovian ON/OFF source with mean bit-rate of 1 Mbps, mean ON phase duration of 0.4 s, mean OFF phase duration of 2 s, and bit-rate during ON period equal to 6 Mbps.
# Then generate at each user terminal 5 Mbit/s: 5 QoS1 flows and 4 QoS2 flows, so (0.2 Mbit/s * 5) / (1 Mbit/s * 4) = 1/4
# MTU 1500 bytes => 6 UTs will generate 30 Mbit/s, i.e. 2500 packets/s on average, of which 500 packets/s are of QoS1 and 2000 packets/s of QoS2.
# So for the overall 6 UTs, for QoS 1 queue size must be <= 75 packets and for QoS 2 queue size must be <= 2000 packets.
# 6 UTs generate QoS 1 flows at 100 packets/s and QoS 2 flow at 500 packets/s. As deadline for QoS 2 flows is 1 s, put 500 packets queues for QoS 2 flows of the 6 terminals overall and 15 for QoS 1 traffic overall.
# In general, queue-limits are for QoS 1: $no_terminals*$no_streams_term*$voip(deadline)/$voip(interval)
# For QoS 2: $no_terminals*($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu)
# Consider a FLC at 55 Mbit/s, even though these are the DVB-S2 MODCODs and probabilities:
#   QPSK 3/5 at 112.500 Mbit/s with probability 0.20671
#   8PSK 3/5 at 168.750 Mbit/s with probability 0.20607
# 16APSK 5/6 at 312.500 Mbit/s with probability 0.20530
# 32APSK 5/6 at 390.625 Mbit/s with probability 0.20054
# 32APSK 8/9 at 416.650 Mbit/s with probability 0.18138
# which would imply an FLC at an average of 276.093 Mbit/s
# Results: PLR and average delay in function of number of UTs for the different CoS.
# one-way latencies to test: GEO (250 - 267 ms), MEO (65 - 75 ms) and LEO (15 - 21 ms or 120 ms with ISL) 
# two-way latencies on the user plane: GEO (600 ms), MEO (180 ms), LEO (50 ms), as per 3GPP TR 38.913 V14.3.0 (2017-06) section 7.5.
# two-way latencies on the user plane: SES 17 GEO HTS (650 ms), mPower MEO (150 ms), LeoSat (from 20 to 130 ms)

if { $argc !=6 } {
	puts stderr {usage: ns model_datalink.tcl <RLC kbps> <FLC kbps> <# VoIP streams/term> <no_terminals> <NbrRLC> <NbrFLC> }
	puts stderr {e.g.:} 
	puts stderr {ns model_datalink.tcl 71 22 1 2 4 2}
	puts stderr {ns model_datalink.tcl 55000 55000 5 6 1 1}
	exit 1
}

set testing            0

set tx_capacity_per_RLC [lindex $argv 0]kb
set tx_capacity_per_FLC [lindex $argv 1]kb
# Iris VoIP
# set voip(interval)      0.08
# set voip(burst_time)    0.46
# set voip(idle_time)     0.54
# set voip(plen)            130
# QoS 1 Video over IP at 0.2 Mbit/s average and 1 Mbit/s when on
# set voip(interval)      0.06
set voip(interval)      0.012
set voip(burst_time)    1.0
# set voip(idle_time)     0.0
set voip(idle_time)     4.0
set voip(plen)            1500
set voip(deadline)		150e-3
set no_streams_term [lindex $argv 2] 
set rlvoip(index) 0
set flvoip(index) 0
set rltcpexp(index) 0
set fltcpexp(index) 0
set no_terminals [lindex $argv 3]
set NbrRLC [lindex $argv 4]
if { $NbrRLC > $no_terminals } {
	set no_terminals $NbrRLC
}
set NbrFLC [lindex $argv 5]
set bwRL [expr [lindex $argv 0] * $NbrRLC]
set bwFL [expr [lindex $argv 1] * $NbrFLC]

set tx_latency_per_FLC_ms 135
set tx_latency_per_FLC [expr $tx_latency_per_FLC_ms]ms

# Rx capacity per FLC = bwRL / NbrFL
set rx_capacity_per_FLC [expr ceil(1.0 * $bwRL / $NbrFLC)]kb
set rx_latency_per_FLC 135ms

set tx_latency_per_RLC_ms 135
set tx_latency_per_RLC [expr $tx_latency_per_RLC_ms]ms

set rx_capacity_per_RLC $tx_capacity_per_FLC
set rx_latency_per_RLC 135ms

set onboard_net_delay         10.000ms
set onboard_net_capacity_Mb	  1000
set onboard_net_capacity      [expr $onboard_net_capacity_Mb]Mb

set per 0.0
# set per 0.5
# set per 1e-3
set ber 0.0
set rl_ber $ber
set rl_cell_size 53
# Assuming RL L2 frames are ATM cells (53 bytes cells, 48 bytes payload)
set rl_ber [expr 1-pow((1-$per),[expr 1/($rl_cell_size*8.0)])]
set fl_cell_size 188
# Assuming FL L2 frames are MPEG packets (188 bytes cells, 184 bytes payload)
set fl_ber [expr 1-pow((1-$per),[expr 1/($fl_cell_size*8.0)])]
set mtu 1500

# QoS and CoS configuration
set set_prio 0
set set_fid 1
set ping_prio 0
set data_prio 10
set voice_prio 46
# set num_cos 13
set num_cos 2
set qos2(deadline) 1.0

set num_rl_flows 0
set num_fl_flows 0

set traffic_duration [expr 99.0 + ($no_streams_term*$num_cos-1)*$no_terminals]
set start 1.0
set reset [expr $start + 1.0]
set finish_margin 120.0
set stop  [expr $reset + $traffic_duration]

set rpingstime0 $start
set fpingstime0 [expr $rpingstime0 + 1.0]

puts "Running test with $no_terminals terminals and $no_streams_term VoIP sessions per terminal, at $bwFL kb FL with $NbrFLC FL datalink carriers and at $bwRL kb RL with $NbrRLC RL datalink carriers..."
# puts "PER = $per"
puts "PER = $per (RL BER $rl_ber, FL BER $fl_ber)"
puts "Rx capacity per FLC $rx_capacity_per_FLC"

ns-random 0
set ns [new Simulator]
$ns color 0 Blue
$ns color 1 Red

set f [open model_datalink.tr w]
$ns trace-all $f
set nf [open model_datalink.nam w]
$ns namtrace-all $nf

# VoIP traffic #########################################################

proc new-rl-voip { i k } {
	global ns rlvoip voip h n voice_prio mtu num_rl_flows
	global start reset stop no_terminals NbrFLC
		
	set rlvoip(s$i) [new Application/Traffic/Voice]
	set rlvoip(r$i) [new Application/Traffic/Voice]
	set udp_s [new Agent/UDP]
	set udp_r [new Agent/UDP]

	$rlvoip(s$i) attach-agent $udp_s
	$rlvoip(s$i) set interval_ $voip(interval)
	$rlvoip(s$i) set burst_time_ $voip(burst_time)
	$rlvoip(s$i) set idle_time_ $voip(idle_time)
	$rlvoip(s$i) set packetSize_ $voip(plen)
	$rlvoip(r$i) set A_ 20
	$rlvoip(r$i) attach-agent $udp_r
	
	$udp_s set index $i
	$udp_s set fid_ 0
	$udp_s set prio_ $voice_prio 
	$udp_s set packetSize_ $mtu
	$udp_r set index $i

#	set k [expr [ns-random] % $no_terminals]
#	set h_n [expr [ns-random] % $NbrFLC]
#	set k [expr $i % $no_terminals]
	set h_n [expr $i % $NbrFLC]

	$ns attach-agent $n($k) $udp_s
	$ns attach-agent $h($h_n) $udp_r	
	$ns connect $udp_s $udp_r

	$ns at [expr $start + $num_rl_flows] "$rlvoip(s$i) start"
	$ns at [expr $reset + $num_rl_flows] "$rlvoip(r$i) reset"
	$ns at [expr $stop + $num_rl_flows] "$rlvoip(s$i) stop"
	
	set num_rl_flows [expr $num_rl_flows + 1]
	set rlvoip(index) [expr $rlvoip(index) + 1]
}

proc new-fl-voip { i k } {
	global ns flvoip voip h n voice_prio mtu num_fl_flows
	global start reset stop no_terminals NbrFLC
	
	set flvoip(s$i) [new Application/Traffic/Voice]
	set flvoip(r$i) [new Application/Traffic/Voice]
	set udp_s [new Agent/UDP]
	set udp_r [new Agent/UDP]

	$flvoip(s$i) attach-agent $udp_s
	$flvoip(s$i) set interval_ $voip(interval)
	$flvoip(s$i) set burst_time_ $voip(burst_time)
	$flvoip(s$i) set idle_time_ $voip(idle_time)
	$flvoip(s$i) set packetSize_ $voip(plen)
	$flvoip(r$i) set A_ 20
	$flvoip(r$i) attach-agent $udp_r
	
	$udp_s set index $i
	$udp_s set fid_ 0
	$udp_s set prio_ $voice_prio 
	$udp_s set packetSize_ $mtu
	$udp_r set index $i

#	set k [expr [ns-random] % $no_terminals]
#	set h_n [expr [ns-random] % $NbrFLC]
#	set k [expr $i % $no_terminals]
	set h_n [expr $i % $NbrFLC]

	$ns attach-agent $h($h_n) $udp_s
	$ns attach-agent $n($k) $udp_r		
	$ns connect $udp_s $udp_r

	$ns at [expr $start + $num_fl_flows] "$flvoip(s$i) start"
	$ns at [expr $reset + $num_fl_flows] "$flvoip(r$i) reset"
	$ns at [expr $stop + $num_fl_flows] "$flvoip(s$i) stop"
	
	set num_fl_flows [expr $num_fl_flows + 1]
	set flvoip(index) [expr $flvoip(index) + 1]
}

# ICMP traffic

proc new-pings { i k } {
	global ns ping h n
	global rpingstime0 rpingstime1 fpingstime0 fpingstime1 no_terminals NbrFLC

	set ping(r$i) [new Agent/Ping]
	$ping(r$i) set packetSize_ 64
	$ping(r$i) set fid_ [expr $num_cos+1]
	$ping(r$i) set prio_ $ping_prio
	# set k [expr $i % $no_terminals]
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $ping(r$i)
	$ns at $rpingstime0 "$ping(r$i) send"
#	$ns at $rpingstime1 "$ping(r$i) send"
	
	set ping(f$i) [new Agent/Ping]
	$ping(f$i) set packetSize_ 64
	$ping(f$i) set fid_ [expr $num_cos+1]
	$ping(f$i) set prio_ $ping_prio
	$ns attach-agent $h($h_n) $ping(f$i)
	$ns connect $ping(f$i) $ping(r$i)
	# $ns at $fpingstime0 "$ping(f$i) send"
	# $ns at $fpingstime1 "$ping(f$i) send"
}

# Markovian on/off TCP traffic
proc new-rl-tcp-exp { i k } {
	global ns rltcpexp h n mtu data_prio num_cos mtu
	global start reset stop no_terminals NbrFLC num_rl_flows

	set rs [new Agent/TCP/Linux]
	# set rs [new Agent/TCP/FullTcp/Sack]
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
 	$rs set window_ 100
#   $rs set window_ $buff_size_pkts
	if { $rltcpexp(index) == 0 } {
		puts "TCP slow start threshold: [$rs set window_]"
	}
#   $rs set tcpTick_ 0.01
	if { $rltcpexp(index) == 0 } {
		puts "TCP tick: [$rs set tcpTick_]"
	}
# default value
#   $rs set windowInit_ 2
#   $rs set windowInit_ 3
    $rs set windowInit_ 10
#   $rs set windowInit_ $buff_size_pkts
	if { $rltcpexp(index) == 0 } {
		puts "TCP initial window size: [$rs set windowInit_]"
	}
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
#	$rs set maxcwnd_ 5000
	if { $rltcpexp(index) == 0 } {
		puts "TCP maximum congestion window size: [$rs set maxcwnd_]"
	}
	$rs set tcpip_base_hdr_size_ 40
	$rs set segsize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	$rs set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
#	$rs set fid_ [expr 1 + ($i % ($num_cos-1))]
	$rs set fid_ 1
	$rs set prio_ $data_prio
	# set k [expr $i % $no_terminals]
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $rs
	set rsink [new Agent/TCPSink]
	$ns attach-agent $h($h_n) $rsink
	$ns connect $rs $rsink
	set rltcpexp(s$i) [new Application/Traffic/Exponential]
	$rltcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	# $rltcpexp(s$i) set packetSize_ $mtu
	$rltcpexp(s$i) set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]	
	$rltcpexp(s$i) set rate_ 6Mb
	$rltcpexp(s$i) set burst_time_ 0.4	
	$rltcpexp(s$i) set idle_time_ 2.0
	$ns at [expr $start + $num_rl_flows] "$rltcpexp(s$i) start"
	$ns at [expr $stop + $num_rl_flows] "$rltcpexp(s$i) stop"
	set num_rl_flows [expr $num_rl_flows + 1]
	set rltcpexp(index) [expr $rltcpexp(index) + 1]
}

proc new-fl-tcp-exp { i k } {
	global ns fltcpexp h n mtu data_prio num_cos
	global start reset stop no_terminals NbrFLC num_fl_flows
	
	set fs [new Agent/TCP/Linux]
	# set fs [new Agent/TCP/FullTcp/Sack]
	$fs set tcpip_base_hdr_size_ 40	
	$fs set segsize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
#	$fs set fid_ [expr 1 + ($i % ($num_cos-1))]
	$fs set fid_ 1
	$fs set prio_ $data_prio	
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $h($h_n) $fs
	set fsink [new Agent/TCPSink]
	# set k [expr $i % $no_terminals]	
	$ns attach-agent $n($k) $fsink
	$ns connect $fs $fsink
	set fltcpexp(s$i) [new Application/Traffic/Exponential]
	$fltcpexp(s$i) attach-agent $fs
	# This is the default packetSize value	
	$fltcpexp(s$i) set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]	
	$fltcpexp(s$i) set rate_ 6Mb
	$fltcpexp(s$i) set burst_time_ 0.4	
	$fltcpexp(s$i) set idle_time_ 2.0
	$ns at [expr $start + $num_fl_flows] "$fltcpexp(s$i) start"
	$ns at [expr $stop + $num_fl_flows] "$fltcpexp(s$i) stop"
	set num_fl_flows [expr $num_fl_flows + 1]
	set fltcpexp(index) [expr $fltcpexp(index) + 1]
}

# Bulk TCP Poisson traffic
proc new-rl-tcp-poisson { i k } {
	global ns rltcpexp h n mtu data_prio num_cos mtu
	global start reset stop no_terminals NbrFLC num_rl_flows

	set rs [new Agent/TCP/Linux]
	# set rs [new Agent/TCP/FullTcp/Sack]
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
 	$rs set window_ 100
#   $rs set window_ $buff_size_pkts
	if { $rltcpexp(index) == 0 } {
		puts "TCP slow start threshold: [$rs set window_]"
	}
#   $rs set tcpTick_ 0.01
	if { $rltcpexp(index) == 0 } {
		puts "TCP tick: [$rs set tcpTick_]"
	}
# default value
#   $rs set windowInit_ 2
#   $rs set windowInit_ 3
    $rs set windowInit_ 10
#   $rs set windowInit_ $buff_size_pkts
	if { $rltcpexp(index) == 0 } {
		puts "TCP initial window size: [$rs set windowInit_]"
	}
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
#	$rs set maxcwnd_ 5000
	if { $rltcpexp(index) == 0 } {
		puts "TCP maximum congestion window size: [$rs set maxcwnd_]"
	}
	$rs set tcpip_base_hdr_size_ 40
	$rs set segsize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	$rs set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
#	$rs set fid_ [expr 1 + ($i % ($num_cos-1))]
	$rs set fid_ 1
	$rs set prio_ $data_prio
	# set k [expr $i % $no_terminals]
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $rs
	set rsink [new Agent/TCPSink]
	$ns attach-agent $h($h_n) $rsink
	$ns connect $rs $rsink
	set rltcpexp(s$i) [new Application/Traffic/Exponential]
	$rltcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	# $rltcpexp(s$i) set packetSize_ $mtu
	$rltcpexp(s$i) set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	# $rltcpexp(s$i) set packetSize_ 156250
	# $rltcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$rs set packetSize_]]	
# The Exponential On/Off generator can be configured to behave as a Poisson process by setting the variable burst_time
# to 0 and the variable rate_ to a very large value. The C++ code guarantees that even if the burst time is zero, at least one
# packet is sent. Additionally, the next interarrival time is the sum of the assumed packet transmission time (governed by the
# variable rate_) and the random variate corresponding to idle_time_. Therefore, to make the first term in the sum very
# small, make the burst rate very large so that the transmission time is negligible compared to the typical idle times.
	$rltcpexp(s$i) set rate_ 10000Mb
	$rltcpexp(s$i) set burst_time_ 0
	# $rltcpexp(s$i) set idle_time_ [expr 5/4]
	$rltcpexp(s$i) set idle_time_ 12ms
	$ns at [expr $start + $num_rl_flows] "$rltcpexp(s$i) start"
	$ns at [expr $stop + $num_rl_flows] "$rltcpexp(s$i) stop"
	set num_rl_flows [expr $num_rl_flows + 1]
	set rltcpexp(index) [expr $rltcpexp(index) + 1]
}

proc new-fl-tcp-poisson { i k } {
	global ns fltcpexp h n mtu data_prio num_cos
	global start reset stop no_terminals NbrFLC num_fl_flows
	
	set fs [new Agent/TCP/Linux]
	# set fs [new Agent/TCP/FullTcp/Sack]
	$fs set tcpip_base_hdr_size_ 40	
	$fs set segsize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
#	$fs set fid_ [expr 1 + ($i % ($num_cos-1))]
	$fs set fid_ 1
	$fs set prio_ $data_prio	
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $h($h_n) $fs
	set fsink [new Agent/TCPSink]
	# set k [expr $i % $no_terminals]	
	$ns attach-agent $n($k) $fsink
	$ns connect $fs $fsink
	set fltcpexp(s$i) [new Application/Traffic/Exponential]
	$fltcpexp(s$i) attach-agent $fs
	# This is the default packetSize value
	# $fltcpexp(s$i) set packetSize_ 156250
	$fltcpexp(s$i) set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	# $fltcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$fs set packetSize_]]
# The Exponential On/Off generator can be configured to behave as a Poisson process by setting the variable burst_time
# to 0 and the variable rate_ to a very large value. The C++ code guarantees that even if the burst time is zero, at least one
# packet is sent. Additionally, the next interarrival time is the sum of the assumed packet transmission time (governed by the
# variable rate_) and the random variate corresponding to idle_time_. Therefore, to make the first term in the sum very
# small, make the burst rate very large so that the transmission time is negligible compared to the typical idle times.
	$fltcpexp(s$i) set rate_ 10000Mb
	$fltcpexp(s$i) set burst_time_ 0
	# $fltcpexp(s$i) set idle_time_ [expr 5/4]
	$fltcpexp(s$i) set idle_time_ 12ms
	$ns at [expr $start + $num_fl_flows] "$fltcpexp(s$i) start"
	$ns at [expr $stop + $num_fl_flows] "$fltcpexp(s$i) stop"
	set num_fl_flows [expr $num_fl_flows + 1]
	set fltcpexp(index) [expr $fltcpexp(index) + 1]
}

######### Web Traffic ######################################

# https://www.keycdn.com/support/the-growth-of-web-page-size/

# set num_conn 7
set num_conn 1
set req_size 320
# set objnum 43
set objnum 0
set obj_size [new RandomVariable/Pareto]
set obj_maxsize 15000
set last_web_done -1
set num_webs 0
$obj_size set shape_ 1.2
$obj_size set avg_ 7187
set request_time [new RandomVariable/Uniform]
$request_time set min_ 0
$request_time set max_ $traffic_duration
set min_web_duration 10000
set max_web_duration 0
set web_duration_filename "web_durations.txt"

Application/TcpApp instproc http-send-req-index {} {
	global ns req_size objnum obj_num duration testing
	global page_req_time page_time num_conn  page_req_time

	$self instvar apps tcp id

	set page_req_time($id) [$ns now]

	if { $testing == "1" } {
		puts "[$ns now] $objnum $id + INDEX"
	}
	$ns at [$ns now] "$self send $req_size \"$apps http-req-recv-index\""
}

Application/TcpApp instproc http-req-recv-index { } {
	global ns obj_size obj_maxsize
	$self instvar appc	
	set size [expr int([$obj_size value])]
	if {$size > $obj_maxsize} {
		set size $obj_maxsize
	}
	$ns at [$ns now] "$self send $size \"$appc http-recv-index\""
}

Application/TcpApp instproc http-send-req {objid} {
	global ns req_size objnum obj_num web_duration testing min_web_duration
	global page_req_time page_time num_conn last_web_done max_web_duration num_webs

	$self instvar apps tcp id

	if { $objid != "NULL" && $testing == "1" } {
		puts "[$ns now] $objid $id - $obj_num($id)"
	}  

	incr obj_num($id) -1
	if { $obj_num($id) >= 0} {
		if { $testing == "1" } {
	        	puts "[$ns now] $obj_num($id) $id +"
		}
		$ns at [$ns now] "$self send $req_size \"$apps http-req-recv $obj_num($id)\""
		return
	} 
	
	[$self set tcp] close

	if { $obj_num($id) == [expr -$num_conn-1]} {
		set last_web_done $num_webs
		set web_duration($num_webs) [expr [$ns now] - $page_req_time($id)]		
		if { $web_duration($num_webs) < $min_web_duration } {
			set min_web_duration $web_duration($num_webs)
		}
		if { $web_duration($num_webs) > $max_web_duration } {
			set max_web_duration $web_duration($num_webs)
		}
		if { $testing == "1" } {
			puts "end $id $web_duration($num_webs) [$ns now] $page_req_time($id)"
		}
		set num_webs [expr $num_webs + 1]
	}
}

Application/TcpApp instproc http-recv-index {} {

	global ns objnum  testing
	$self instvar id
	if { $testing  == "1" } {
		puts "[$ns now] $objnum $id - INDEX"
	}
	$ns at [$ns now] "$self new-http-session"
	$ns at [$ns now] "$self http-send-req NULL"
}

Application/TcpApp instproc http-req-recv {obj_id} {
	global ns obj_size  obj_num obj_maxsize 
	$self instvar appc id	
	set size [expr int([$obj_size value])]
	if { $size > $obj_maxsize } {
		set size $obj_maxsize
	}
	$ns at [$ns now] "$self send $size \"$appc http-send-req $obj_id\""
}

Application/TcpApp instproc new-http-session { } {
	global ns objnum tcp num_conn obj_num mtu data_prio
	global page_req_time
	$self instvar id n1 n2
	
	set now [$ns now]
	
	for {set i 0} {$i< $num_conn} {incr i} {

		set tcpc [new Agent/TCP/FullTcp/Sack]
		$tcpc set tcpip_base_hdr_size_ 40
		$tcpc set segsize_ [expr $mtu-[$tcpc set tcpip_base_hdr_size_]]
#		$tcpc set fid_ $id
		$tcpc set fid_ 1
		$tcpc set prio_ $data_prio
		set tcps [new Agent/TCP/FullTcp/Sack]
		$tcps set tcpip_base_hdr_size_ 40
		$tcps set segsize_ [expr $mtu-[$tcps set tcpip_base_hdr_size_]]
#		$tcps set fid_ $id
		$tcps set fid_ 1
		$tcps set prio_ $data_prio
		set appc [new Application/TcpApp $tcpc]
		set apps [new Application/TcpApp $tcps]
		$ns attach-agent $n1 $tcpc
		$ns attach-agent $n2 $tcps
		$ns connect $tcpc $tcps
		$tcps listen
		$appc connect $apps

		$appc set apps $apps
		$apps set appc $appc
		$appc set tcp $tcpc
		
		$appc set id $id
		$apps set id $id

		$ns at $now "$appc http-send-req NULL"
	
	}

	set obj_num($id) $objnum
}

proc new-http-session { id n1 n2 } {

	global ns mtu data_prio
	set now [$ns now]
	
	set tcpc [new Agent/TCP/FullTcp/Sack]
	$tcpc set tcpip_base_hdr_size_ 40
	$tcpc set segsize_ [expr $mtu-[$tcpc set tcpip_base_hdr_size_]]
	$tcpc set fid_ $id
	$tcpc set prio_ $data_prio
	set tcps [new Agent/TCP/FullTcp/Sack]
	$tcps set tcpip_base_hdr_size_ 40
	$tcps set segsize_ [expr $mtu-[$tcps set tcpip_base_hdr_size_]]
#	$tcps set fid_ $id
	$tcps set fid_ 1
	$tcps set prio_ $data_prio
	set appc [new Application/TcpApp $tcpc]
	set apps [new Application/TcpApp $tcps]

	$ns attach-agent $n1 $tcpc
	$ns attach-agent $n2 $tcps
	$ns connect $tcpc $tcps
	$tcps listen
	$appc connect $apps

	$appc set apps $apps
	$apps set appc $appc
	$appc set tcp $tcpc
		
	$appc set id $id
	$appc set n1 $n1
	$appc set n2 $n2
	$apps set id $id

	$ns at $now "$appc http-send-req-index"	
}

# Creating scenario  ##########################

# Satellite node
set n0 [$ns node]
$n0 label "Satellite"

# Hub nodes (one per NbrFLC)
for {set i 0} { $i < $NbrFLC } {incr i} {
	set h($i) [$ns node]
	$h($i) label "Hub $i"
}

# Access nodes (one per NbrRLC)
for {set i 0} { $i < $NbrRLC } {incr i} {
	set an($i) [$ns node]
	$an($i) label "AN $i"
}

# Remote nodes
for {set i 0} { $i < $no_terminals } {incr i} {
	set n($i) [$ns node]
	$n($i) label "UT $i"
}

for {set i 0} { $i < $NbrFLC } {incr i} {	
	$ns simplex-link $n0 $h($i) $rx_capacity_per_FLC $rx_latency_per_FLC DropTail		
	# $ns queue-limit $n0 $h($i) [expr 50 +3*$no_terminals]
	# $ns queue-limit $n0 $h($i) [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrFLC)]
	$ns queue-limit $n0 $h($i) [expr ceil($bwRL*1e3*($voip(deadline)+$qos2(deadline))/(8*$mtu*$NbrFLC))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $n0 $h($i) queuePos 0.5
#	$ns trace-queue $n0 $h($i)
#	$ns namtrace-queue $n0 $h($i)

	# Add an error model to the receiving hub
	set em1_($i) [new ErrorModel]
	$em1_($i) unit byte
	# Byte error rate = 1 - (1-BER)^8
	$em1_($i) set rate_ [expr 1-pow((1-$rl_ber),8)]
	#$em1_($i) unit pkt
	#$em1_($i) set rate_ $per	
	$em1_($i) ranvar [new RandomVariable/Uniform]
	$em1_($i) drop-target [new Agent/Null]	
#	$ns link-lossmodel $em1_($i) $n0 $h($i)
	$ns lossmodel $em1_($i) $n0 $h($i)
}

for {set i 0} { $i < $NbrFLC } {incr i} {	
	## All routers are core since the prio_ field is already set by Agent and we do not wish to change it
	$ns simplex-link $h($i) $n0 $tx_capacity_per_FLC $tx_latency_per_FLC dsRED/core
	# $ns simplex-link $h($i) $n0 $tx_capacity_per_FLC $tx_latency_per_FLC DropTail	
	# $ns queue-limit $h($i) $n0 [expr 50 +3*$no_terminals]
	# $ns queue-limit $h($i) $n0 [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrFLC)]
	$ns queue-limit $h($i) $n0 [expr ceil($bwFL*1e3*($voip(deadline)+$qos2(deadline))/(8*$mtu*$NbrFLC))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $h($i) $n0 queuePos 0.5
#	$ns trace-queue $h($i) $n0
#	$ns namtrace-queue $h($i) $n0
}

for {set i 0} { $i < $NbrRLC } {incr i} {
	$ns simplex-link $n0 $an($i) $rx_capacity_per_RLC $rx_latency_per_RLC DropTail
	# $ns queue-limit $n0 $an($i) 50
	# $ns queue-limit $n0 $an($i) [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrRLC)]
	$ns queue-limit $n0 $an($i) [expr ceil($bwFL*1e3*($voip(deadline)+$qos2(deadline))/(8*$mtu*$NbrFLC))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $n0 $an($i) queuePos 0.5
#	$ns trace-queue $n0 $an($i)
#	$ns namtrace-queue $n0 $an($i)
	# $ns simplex-link $an($i) $n0 $tx_capacity_per_RLC $tx_latency_per_RLC DropTail
	$ns simplex-link $an($i) $n0 $tx_capacity_per_RLC $tx_latency_per_RLC dsRED/core
	# $ns queue-limit $an($i) $n0 50
	# $ns queue-limit $an($i) $n0 [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrRLC)]
	$ns queue-limit $an($i) $n0 [expr ceil($bwRL*1e3*($voip(deadline)+$qos2(deadline))/(8*$mtu*$NbrRLC))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $an($i) $n0 queuePos 0.5
#	$ns trace-queue $an($i) $n0 
#	$ns namtrace-queue $an($i) $n0

	# Add an error model to the receiving access node
	set em_($i) [new ErrorModel]
	$em_($i) unit byte
	# Byte error rate = 1 - (1-BER)^8
	$em_($i) set rate_ [expr 1-pow((1-$fl_ber),8)]
	# $em_($i) unit pkt
	# $em_($i) set rate_ $per	
	$em_($i) ranvar [new RandomVariable/Uniform]	
	$em_($i) drop-target [new Agent/Null]	
#	$ns link-lossmodel $em_($i) $n0 $an($i)
	$ns lossmodel $em_($i) $n0 $an($i)
}

for {set i 0} { $i < $no_terminals } {incr i} {
	set k [expr $i % $NbrRLC]
	$ns duplex-link $n($i) $an($k) $onboard_net_capacity $onboard_net_delay DropTail
	# $ns queue-limit $n($i) $an($k) 1700000
	# $ns queue-limit $n($i) $an($k) [expr ceil($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))]
	$ns queue-limit $n($i) $an($k) [expr ceil($onboard_net_capacity_Mb*1e6*($voip(deadline)+$qos2(deadline))/(8*$mtu))]
	# $ns queue-limit $an($k) $n($i) 1700000
	# $ns queue-limit $an($k) $n($i) [expr ceil($no_streams_term*$voip(deadline)/$voip(interval)+($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))]
	$ns queue-limit $an($k) $n($i) [expr ceil($onboard_net_capacity_Mb*1e6*($voip(deadline)+$qos2(deadline))/(8*$mtu))]
}

## DiffServ configuration

## Get DiffServ queues handles
for {set i 0} { $i < $NbrFLC } {incr i} {
	set qh($i) [[$ns link $h($i) $n0] queue]
	## Set mean packet size for RED average queue length calculation to something greater than zero to avoid segfault
	$qh($i) meanPktSize $mtu
	## Set the number of physical queues
	$qh($i) set NumQueues_ 3
	## Set the number of virtual queues per physical queue (DiffServ precedence levels)
	$qh($i) setNumPrec 1
	## Set the MRED mode of queue 0 to DROP
	$qh($i) setMREDMode DROP 0
	## Set the MRED mode of queue 1 to DROP
	$qh($i) setMREDMode DROP 1
	## Set the MRED mode of queue 2 to DROP
	$qh($i) setMREDMode DROP 2
	## DROP queues only require minth specification (queue size in packets 50 is the default value). First argument is physical queue index, second, virtual queue index.
	# https://www.isi.edu/nsnam/ns/doc/node98.html
	# set minth0 [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval))/$NbrFLC)]
	set minth0 [expr ceil($bwFL*1e3*$voip(deadline)/(8*$mtu*$NbrFLC))]
	$qh($i) configQ 0 0 $minth0 [expr $minth0 + 10] 0.10
	# set minth1 [expr ceil($no_terminals*(($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrFLC)]
	set minth1 [expr ceil($bwFL*1e3*$qos2(deadline)/(8*$mtu*$NbrFLC))]	
	$qh($i) configQ 1 0 $minth1 [expr $minth1 + 10] 0.10
	set minth2 [expr ceil(2.0*$bwFL*$tx_latency_per_FLC_ms/(8*$mtu*$NbrFLC))]
	$qh($i) configQ 2 0 $minth2 [expr $minth2 + 10] 0.10
	## Map code point 46 (EF) to physical queue 0 virtual queue 0
	$qh($i) addPHBEntry 46 0 0
	## Map code point 10 (AF) to physical queue 1 virtual queue 0
	$qh($i) addPHBEntry 10 1 0
	## Map code point 0 (best effort) to physical queue 2 virtual queue 0
	$qh($i) addPHBEntry 0 2 0	
	## Set scheduling mode to strict priority
	$qh($i) setSchedularMode PRI
	## For Priority scheduling, priority is arranged in sequential order with queue 0 having the highest priority. Also, one can set a limit on the maximum bandwidth a particular queue can get using the addQueueRate command, e.g. to a fifth of a carrier rate, which is the maximum expected rate of QoS 1 traffic generated in this model.
	## $qh($i) addQueueRate 0 expr [$tx_capacity_per_FLC/5]
}
puts "Queue Sizes per CoS in the FL:"
puts "CoS 0 queue size in packets: $minth0"
puts "CoS 1 queue size in packets: $minth1"
puts "CoS 2 queue size in packets: $minth2"
for {set i 0} { $i < $NbrRLC } {incr i} {
	set qa($i) [[$ns link $an($i) $n0] queue]
	$qa($i) meanPktSize $mtu
	$qa($i) set NumQueues_ 3
	$qa($i) setNumPrec 1
	$qa($i) setMREDMode DROP 0
	$qa($i) setMREDMode DROP 1
	$qa($i) setMREDMode DROP 2
	# set minth0 [expr ceil($no_terminals*($no_streams_term*$voip(deadline)/$voip(interval))/$NbrRLC)]
	set minth0 [expr ceil($bwRL*1e3*$voip(deadline)/(8*$mtu*$NbrRLC))]
	# set minth1 [expr ceil($no_terminals*(($no_streams_term-1)*$qos2(deadline)*1e6/(8*$mtu))/$NbrRLC)]
	set minth1 [expr ceil($bwRL*1e3*$qos2(deadline)/(8*$mtu*$NbrRLC))]
	set minth2 [expr ceil(2.0*$bwRL*$tx_latency_per_RLC_ms/(8*$mtu*$NbrRLC))]
	$qa($i) configQ 0 0 $minth0 [expr $minth0 + 10] 0.10
	$qa($i) configQ 1 0 $minth1 [expr $minth1 + 10] 0.10
	$qa($i) configQ 2 0 $minth2 [expr $minth2 + 10] 0.10
	$qa($i) addPHBEntry 46 0 0
	$qa($i) addPHBEntry 10 1 0
	$qa($i) addPHBEntry 0 2 0
	$qa($i) setSchedularMode PRI
	## $qa($i) addQueueRate 0 expr [$tx_capacity_per_RLC/5]
}
puts "Queue Sizes per CoS in the RL:"
puts "CoS 0 queue size in packets: $minth0"
puts "CoS 1 queue size in packets: $minth1"
puts "CoS 2 queue size in packets: $minth2"
## Print PHB table one line at a time
$qh(0) printPHBTable
# $qa(0) printPHBTable

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

proc finish-sim {} {
	global ns f nf voip rlvoip flvoip no_terminals no_streams_term NbrRLC NbrFLC num_cos
	global last_web_done web_duration min_web_duration max_web_duration num_webs web_duration_filename
	
	$ns flush-trace
	close $nf
	close $f
	
	set r_voip_max_delay 0
	set f_voip_max_delay 0
	set r_voip_min_delay 100000
	set f_voip_min_delay 100000
	set m 0
	for {set i 0} {$i<$no_terminals} {incr i} {		
		for {set j 0} { $j < $no_streams_term} {incr j} {
			if {$m < $rlvoip(index) } {
				set k [expr $i*$no_streams_term+$j]
				$rlvoip(r$k) update_score
				set r_voip_delay [$rlvoip(r$k) set max_delay_]
				puts "$r_voip_delay [$rlvoip(r$k) set rscore_] [$rlvoip(r$k) set mos_]"
				if { $r_voip_delay < $r_voip_min_delay } {
					set r_voip_min_delay $r_voip_delay
				}
				if { $r_voip_delay > $r_voip_max_delay } {
					set r_voip_max_delay $r_voip_delay
				}
				set m [expr $m +1]
			}
		}
	}
	set m 0
	for {set i 0} {$i<$no_terminals} {incr i} {	
		for {set j 0} { $j < $no_streams_term} {incr j} {
			if {$m < $flvoip(index) } {
				set k [expr $i*$no_streams_term+$j]			
				$flvoip(r$k) update_score			
				set f_voip_delay [$flvoip(r$k) set max_delay_]
				puts "$f_voip_delay [$flvoip(r$k) set rscore_] [$flvoip(r$k) set mos_]"			
				if { $f_voip_delay < $f_voip_min_delay } {
					set f_voip_min_delay $f_voip_delay
				}
				if { $f_voip_delay > $f_voip_max_delay } {
					set f_voip_max_delay $f_voip_delay
				}
				set m [expr $m +1]
			}
		}
	}
	if { $rlvoip(index) > 0 } {
		puts "Max VoIP delay from a terminal $r_voip_max_delay ms (Min $r_voip_min_delay ms) of $rlvoip(index) VoIP agents"
	}
	if { $flvoip(index) > 0 } {
		puts "Max VoIP delay to a terminal $f_voip_max_delay ms (Min $f_voip_min_delay ms) of $flvoip(index) VoIP agents"
	}
	# Open the filename for writing
	set fileId [open $web_duration_filename "w"]
	if { $last_web_done != "-1" } {		
		for {set i 0} { $i < $num_webs } { incr i } {
			# Send the data to the file. Omitting '-nonewline' will result in an extra newline at the end of the file
			# puts -nonewline $fileId $web_duration($i)
			puts $fileId $web_duration($i)
		}		
		puts "Processed $num_webs webpages with duration interval: Min.: $min_web_duration s. Max.: $max_web_duration s."		
	}	
	# Close the file, ensuring the data is written out before you continue with processing.
	close $fileId
	puts "Processing results. Wait and/or press any key to continue..."
	exec ./model_datalink.sh $NbrRLC $NbrFLC $no_terminals $num_cos
	puts "Launching NAM..."
	exec nam model_datalink.nam &
	puts "Finished"
	$ns halt
}

for {set i 0} {$i<$no_terminals} {incr i} {
	# $ns at $start "new-pings $i $i"
	# $ns at $start "new-rl-tcp-poisson $i $i"
	for {set j 0} { $j < [expr $no_streams_term-1]} {incr j} {
		# $ns at $start "new-rl-voip [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-fl-voip [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-pings [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-rl-tcp-poisson [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-fl-tcp-poisson [expr $i*$no_streams_term+$j] $i"
		$ns at $start "new-fl-tcp-exp [expr $i*$no_streams_term+$j] $i"
		# set k [expr [ns-random] % $no_terminals]
		# set h_n [expr [ns-random] % $NbrFLC]
		# set t_download [expr $reset + [$request_time value]]
		# $ns at $t_download "new-http-session [expr $i*$no_streams_term+$j] $n($k) $h($h_n)"
		# set t_upload [expr $reset + [$request_time value]]
		# $ns at $t_upload "new-http-session [expr $i*$no_streams_term+$j] $h($h_n) $n($k)"
	}
	for {set j 0} { $j < $no_streams_term} {incr j} {
		$ns at $start "new-fl-voip [expr $i*$no_streams_term+$j] $i"
	}
}

# $ns at $start "new-fl-voip 0 0"

# $ns at $start "new-fl-tcp-poisson 0 0"

# Web download
# $ns at $start "new-http-session 0 $n(0) $h(0)"
# Web upload
# $ns at $start "new-http-session 0 $h(0) $n(0)"

set fpingstime1 [expr $stop + 1.0 + $num_fl_flows + $num_rl_flows]
set rpingstime1 [expr $fpingstime1 + 1.0]

set duration [expr $rpingstime1 + $finish_margin]

$ns at $duration "finish-sim"

$ns run
