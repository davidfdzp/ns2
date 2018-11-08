#!$HOME/ns-allinone-2.35/ns-2.35/ns
# modelDatalink.tcl - based on tg.tcl example and ERG-UoA Aberdeen (UK), May 2008 VoIP and web traffic generation examples
# D. Fernández - November 2018
# Results: PLR and one-way delay statistics (avg delay, TD50, TD95 and TD99.9) in function of arrival rate of messages
# Testing the effect of TCP ACKs prioritization
#

if { $argc !=13 } {
	puts stderr {usage: ns modelDatalink.tcl <RLC kbps> <FLC kbps> <RL UDP rate packets/s> <RL TCP rate packets/s> <FL UDP rate packets/s> <FL TCP rate packets/s> <RL message size> <FL message size> <no_terminals> <NbrRLC> <NbrFLC> <RL one-way delay ms> <FL one-way delay ms> }
	puts stderr {e.g.:} 
	puts stderr {ns modelDatalink.tcl 144 272 25 0 0 0 463 463 1 1 1 850 270}
	puts stderr {ns modelDatalink.tcl 128 512 0 0 0 0 0 0 1 1 1 5 5}
	exit 1
}

set testing            0

set num_pkts 10000

set tx_capacity_per_RLC_kb [lindex $argv 0]
set tx_capacity_per_FLC_kb [lindex $argv 1]
set rl_UDP_packets_rate [lindex $argv 2]
set rl_TCP_packets_rate [lindex $argv 3]
set fl_UDP_packets_rate [lindex $argv 4]
set fl_TCP_packets_rate [lindex $argv 5]
set rl_msg_size [lindex $argv 6]
set fl_msg_size [lindex $argv 7]
set no_terminals [lindex $argv 8]
set NbrRLC [lindex $argv 9]
set NbrFLC [lindex $argv 10]
set delayRLms [lindex $argv 11]
set delayFLms [lindex $argv 12]
set bwRL_kb [expr [lindex $argv 0] * $NbrRLC]
set bwFL_kb [expr [lindex $argv 1] * $NbrFLC]

set tx_capacity_per_RLC [expr $tx_capacity_per_RLC_kb]kb
set tx_capacity_per_FLC [expr $tx_capacity_per_FLC_kb]kb
set tx_latency_per_FLC_ms [expr $delayFLms / 2]
set rx_latency_per_FLC [expr $delayFLms / 2]ms
set tx_latency_per_RLC_ms [expr $delayRLms / 2]
set rx_latency_per_RLC [expr $delayRLms / 2]ms
set tx_latency_per_FLC [expr $tx_latency_per_FLC_ms]ms
set tx_latency_per_RLC [expr $tx_latency_per_RLC_ms]ms

set ping_pkt_size 64

set onboard_net_delay_ms 10.0
set onboard_net_delay [expr $onboard_net_delay_ms]ms
set onboard_net_capacity_Mb	1000
set onboard_net_capacity      [expr $onboard_net_capacity_Mb]Mb

# Rx capacity per FLC = bwRL_kb / NbrFL
# set rx_capacity_per_FLC [expr ceil(1.0 * $bwRL_kb / $NbrFLC)]kb
# set rx_capacity_per_RLC $tx_capacity_per_FLC
# Satellites are not store and forward: almost unlimited capacity hereafter
set rx_capacity_per_FLC_Mb $onboard_net_capacity_Mb
set rx_capacity_per_FLC [expr $rx_capacity_per_FLC_Mb]Mb
set rx_capacity_per_RLC_Mb $onboard_net_capacity_Mb
set rx_capacity_per_RLC [expr $rx_capacity_per_RLC_Mb]Mb

set per 0.0
# set per 0.5
# set per 1e-3
set ber 0.0
set rl_ber $ber
set fl_ber $ber
# Assuming RL L2 frames are ATM cells (53 bytes cells, 48 bytes payload)
# set rl_cell_size 53
# set rl_cell_size 200
# set rl_ber [expr 1-pow((1-$per),[expr 1/($rl_cell_size*8.0)])]
# Assuming FL L2 frames are MPEG packets (188 bytes cells, 184 bytes payload)
# set fl_cell_size 188
# set fl_cell_size 8100
# set fl_ber [expr 1-pow((1-$per),[expr 1/($fl_cell_size*8.0)])]
set mtu 1500
set ack_size 52

set tcp_duration 60

set rl_bdp_factor 3
set fl_bdp_factor 1

# QoS and CoS configuration
set set_prio 1
# Single CoS setup (all Best Effort)
# set ping_prio 0
set ping_prio 0
# set tcp_data_prio 0
set tcp_data_prio 0
set ack_prio 46
set udp_data_prio 0

set af_data_prio 10
set ef_data_prio 46
# set udp_data_prio 46
set num_cos 2
set qos1(deadline) 1.0
set qos2(deadline) 1.0
set qos3(deadline) 1.0
# set qos3(deadline) [expr 1e-3*($tx_latency_per_FLC_ms + $tx_latency_per_RLC_ms)]

set finish_margin 10.0

set traffic_duration $tcp_duration
if {$rl_UDP_packets_rate > 0 } {
	set rl_udp_traffic_duration [expr $num_pkts / $rl_UDP_packets_rate ]
	set traffic_duration $rl_udp_traffic_duration
}
if {$fl_UDP_packets_rate > 0} {
	set fl_udp_traffic_duration [expr $num_pkts / $fl_UDP_packets_rate ]
	if { $fl_udp_traffic_duration > $traffic_duration } {
		set traffic_duration $fl_udp_traffic_duration
	}
}
if {$rl_TCP_packets_rate > 0 } {
	set rl_tcp_traffic_duration [expr $num_pkts / $rl_TCP_packets_rate ]
	if { $rl_tcp_traffic_duration > $traffic_duration } {
		set traffic_duration $rl_tcp_traffic_duration
	}
}
if {$fl_TCP_packets_rate > 0 } {
	set fl_tcp_traffic_duration [expr $num_pkts / $fl_TCP_packets_rate ]
	if { $fl_tcp_traffic_duration > $traffic_duration } {
		set traffic_duration $fl_tcp_traffic_duration
	}
}

set rltcpexp(index) 0
set fltcpexp(index) 0
set rltcp(index) 0
set fltcp(index) 0
set rlftp(index) 0
set flftp(index) 0
set rsink(index) 0
set fsink(index) 0

set start 1.0
set currTime $start
set pingTime $start
set rpingstime0 $start
set fpingstime0 [expr $rpingstime0 + 1.0]
set reset [expr $fpingstime0 + 1.0]
set stop  [expr $reset + $traffic_duration]

puts "Running test with $no_terminals terminal(s), $tx_capacity_per_RLC per RL carrier and $tx_capacity_per_FLC per FL carrier"
puts "$rl_msg_size bytes messages in the RL, $fl_msg_size bytes messages in the FL"
puts "$NbrRLC RL carriers and $NbrFLC FL carriers"
# puts "PER = $per"
puts "PER = $per (RL BER $rl_ber, FL BER $fl_ber)"
if { $rl_msg_size > 0 } {
	set rl_req_ber [expr 1-pow((1-1e-3),(1/($rl_msg_size*8.0)))]
	puts "Required RL BER: $rl_req_ber"
}
if { $fl_msg_size > 0 } {
	set fl_req_ber [expr 1-pow((1-1e-3),(1/($fl_msg_size*8.0)))]
	puts "Required FL BER: $fl_req_ber"
}
puts "Rx capacity per FLC $rx_capacity_per_FLC"
if { $rl_UDP_packets_rate > 0 } {
	puts "$rl_UDP_packets_rate UDP packets/s in the RL"
	set rl_service_rate [expr 1e3*$tx_capacity_per_RLC_kb/($rl_msg_size*8.0)]
	puts "Service rate per RL carrier (mu) UDP packets/s: $rl_service_rate"
	set rl_rho [expr 1.0*$rl_UDP_packets_rate/($rl_service_rate*$NbrRLC)]
	puts "RL carrier occupation %: [expr 100*$rl_rho]"
	set rl_tq [expr $rl_rho/(2*$rl_service_rate*(1-$rl_rho))]
	puts "RL expected (M/D/1 model) average queueing time (s): $rl_tq"
	set rl_tq95 [expr log(100/(100-95.0))*$rl_tq]
	puts "RL expected (M/D/1 model) percentil 95 of queueing time (s): $rl_tq95"
	set rl_tq999 [expr log(100/(100-99.9))*$rl_tq]
	puts "RL expected (M/D/1 model) percentil 99.9 of queueing time (s): $rl_tq999"
	set rl_td [expr 1e-3*$delayRLms + 1/$rl_service_rate + $rl_tq]
	puts "RL expected (M/D/1 model) average one-way delay (s): $rl_td"
	set rl_td95 [expr 1e-3*$delayRLms + 1/$rl_service_rate + $rl_tq95]
	puts "RL expected (M/D/1 model) percentil 95 one-way delay (s): $rl_td95"
	set rl_td999 [expr 1e-3*$delayRLms + 1/$rl_service_rate + $rl_tq999]
	puts "RL expected (M/D/1 model) percentil 99.9 one-way delay (s): $rl_td999"
	puts "RL UDP traffic duration for $num_pkts packets (s): $rl_udp_traffic_duration"
}
if { $fl_UDP_packets_rate > 0 } {
	puts "$fl_UDP_packets_rate UDP packets/s in the FL"
	set fl_service_rate [expr 1e3*$tx_capacity_per_FLC_kb/($fl_msg_size*8.0)]
	puts "Service rate per FL carrier (mu) UDP packets/s: $fl_service_rate"
	set fl_rho [expr 1.0*$fl_UDP_packets_rate/($fl_service_rate*$NbrFLC)]
	puts "FL carrier occupation %: [expr 100*$fl_rho]"
	set fl_tq [expr $fl_rho/(2*$fl_service_rate*(1-$fl_rho))]
	puts "FL expected (M/D/1 model) average queueing time (s): $fl_tq"
	set fl_tq95 [expr log(100/(100-95.0))*$fl_tq]
	puts "FL expected (M/D/1 model) percentil 95 of queueing time (s): $fl_tq95"
	set fl_tq999 [expr log(100/(100-99.9))*$fl_tq]
	puts "FL expected (M/D/1 model) percentil 99.9 of queueing time (s): $fl_tq999"
	set fl_td [expr 1e-3*$delayFLms + 1/$fl_service_rate + $fl_tq]
	puts "FL expected (M/D/1 model) average one-way delay (s): $fl_td"
	set fl_td95 [expr 1e-3*$delayFLms + 1/$fl_service_rate + $fl_tq95]
	puts "FL expected (M/D/1 model) percentil 95 one-way delay (s): $fl_td95"
	set fl_td999 [expr 1e-3*$delayFLms + 1/$fl_service_rate + $fl_tq999]
	puts "FL expected (M/D/1 model) percentil 99.9 one-way delay (s): $fl_td999"
	puts "FL UDP traffic duration for $num_pkts packets (s): $fl_udp_traffic_duration"
}
if { $rl_TCP_packets_rate > 0 } {
	puts "$rl_TCP_packets_rate TCP packets/s in the RL"
}
if { $fl_TCP_packets_rate > 0 } {
	puts "$fl_TCP_packets_rate TCP packets/s in the FL"
}

puts "Traffic duration(s): $traffic_duration, from t=$reset to t=$stop"
# Satellite is considered a store and forward node (not transparent)
set ping_rtt_ms [expr $ping_pkt_size*8*2.0/(1000.0*$onboard_net_capacity_Mb) + $ping_pkt_size*8*2.0/$tx_capacity_per_RLC_kb + $ping_pkt_size*8*2.0/$tx_capacity_per_FLC_kb + $delayRLms + $delayFLms + $onboard_net_delay_ms*2]
puts "Theoretical store and forward RTT ms: $ping_rtt_ms"
set ping_rtt_ms [expr $ping_pkt_size*2.0*8/(1000.0*$onboard_net_capacity_Mb) + $ping_pkt_size*8/$tx_capacity_per_RLC_kb + $ping_pkt_size*8/$tx_capacity_per_FLC_kb + $delayRLms + $delayFLms + $onboard_net_delay_ms*2]
puts "Theoretical transparent RTT ms: $ping_rtt_ms"

# Uncomment if you are just interested in theoretical values
# exit

ns-random 0
set ns [new Simulator]
$ns color 0 Blue
$ns color 1 Red
# set udp_fid 0
# Single CoS setup (all Best Effort)
set udp_fid 1
set tcp_fid 1
# In order to make plots look good do some pings with the same fid you are plotting just after the flow end
set ping_fid 1

# Full tracing can increase the runtime 10-fold: http://intronetworks.cs.luc.edu/current/html/ns2.html
set f [open modelDatalink.tr w]
$ns trace-all $f
set nf [open modelDatalink.nam w]
$ns namtrace-all $nf

# UDP Poisson traffic #########################################################

proc new-rl-udpExpo { i k t } {
	global ns rludpExpo h n udp_data_prio mtu udp_fid rl_UDP_packets_rate rl_msg_size
	global NbrFLC traffic_duration
		
	set rludpExpo($i) [new Application/Traffic/Exponential]
	set null [new Agent/Null]
	set udp [new Agent/UDP]

	$rludpExpo($i) attach-agent $udp
	$rludpExpo($i) set rate_ 10000Mb
	$rludpExpo($i) set burst_time_ 0
	$rludpExpo($i) set idle_time_ [expr 1.0 / $rl_UDP_packets_rate]
	$rludpExpo($i) set packetSize_ $rl_msg_size
	
	$udp set index $i
	$udp set fid_ $udp_fid
	$udp set prio_ $udp_data_prio 
	$udp set packetSize_ $mtu

	set h_n [expr $i % $NbrFLC]

	$ns attach-agent $n($k) $udp
	$ns attach-agent $h($h_n) $null
	$ns connect $udp $null

	$ns at $t "$rludpExpo($i) start"
	$ns at [expr $t + $traffic_duration] "$rludpExpo($i) stop"
}

proc new-fl-udpExpo { i k t } {
	global ns fludpExpo h n udp_data_prio mtu udp_fid fl_UDP_packets_rate fl_msg_size
	global NbrFLC traffic_duration
	
	set fludpExpo($i) [new Application/Traffic/Exponential]
	set null [new Agent/Null]
	set udp [new Agent/UDP]

	$fludpExpo($i) attach-agent $udp
	$fludpExpo($i) set rate_ 10000Mb
	$fludpExpo($i) set burst_time_ 0
	$fludpExpo($i) set idle_time_ [expr 1.0 / $fl_UDP_packets_rate]
	$fludpExpo($i) set packetSize_ $fl_msg_size
	
	$udp set index $i
	$udp set fid_ $udp_fid
	$udp set prio_ $udp_data_prio 
	$udp set packetSize_ $mtu

	set h_n [expr $i % $NbrFLC]

	$ns attach-agent $h($h_n) $udp
	$ns attach-agent $n($k) $null		
	$ns connect $udp $null

	$ns at $t "$fludpExpo($i) start"
	$ns at [expr $t + $traffic_duration] "$fludpExpo($i) stop"
}

# ICMP traffic

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

proc new-pings { i k t } {
	global ns ping h n num_cos ping_prio ping_pkt_size ping_fid
	global NbrFLC

	set ping(r$i) [new Agent/Ping]
	$ping(r$i) set packetSize_ $ping_pkt_size
	$ping(r$i) set fid_ $ping_fid
	$ping(r$i) set prio_ $ping_prio
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $ping(r$i)
	$ns at $t "$ping(r$i) send"
	
	set ping(f$i) [new Agent/Ping]
	$ping(f$i) set packetSize_ $ping_pkt_size
	$ping(f$i) set fid_ $ping_fid
	$ping(f$i) set prio_ $ping_prio
	$ns attach-agent $h($h_n) $ping(f$i)
	$ns connect $ping(f$i) $ping(r$i)
}

# Markovian on/off TCP traffic
proc new-rl-tcp-exp { i k t } {
	global ns rltcpexp h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global traffic_duration NbrFLC

	set rs [new Agent/TCP/Linux]
	# set rs [new Agent/TCP/FullTcp/Sack]
	# Print TCP parameters
	#   Window_ sets the ssthreshold. Terrestrial TCP senders use as
#		initial ssthreshold value of 38 pkts as it is common.
#		Since the advwindow is implemented this value is only used to initialize the value of 
#		ssthreshold and must be sufficient high to not disturb the operation of TCP sender
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
	$rs set fid_ $tcp_fid
	$rs set prio_ $tcp_data_prio
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $rs
	set rsink [new Agent/TCPSink]
	$rsink set set_prio_ $set_prio
	$rsink set ack_prio_ $ack_prio
	$ns attach-agent $h($h_n) $rsink
	$ns connect $rs $rsink
	set rltcpexp(s$i) [new Application/Traffic/Exponential]
	$rltcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	# $rltcpexp(s$i) set packetSize_ $mtu
	$rltcpexp(s$i) set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]	
	$rltcpexp(s$i) set rate_ [expr $rl_TCP_packets_rate*8*$rl_msg_size]
	$rltcpexp(s$i) set burst_time_ 0.001
	$rltcpexp(s$i) set idle_time_ [expr 1/$rl_TCP_packets_rate]
	$ns at $t "$rltcpexp(s$i) start"
	$ns at [expr $t + $traffic_duration] "$rltcpexp(s$i) stop"
	set rltcpexp(index) [expr $rltcpexp(index) + 1]
}

proc new-fl-tcp-exp { i k t } {
	global ns fltcpexp h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global traffic_duration NbrFLC
	
	set fs [new Agent/TCP/Linux]
	# set fs [new Agent/TCP/FullTcp/Sack]
	$fs set tcpip_base_hdr_size_ 40	
	$fs set segsize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
#	$fs set fid_ [expr 1 + ($i % ($num_cos-1))]
	$fs set fid_ $tcp_fid
	$fs set prio_ $tcp_data_prio	
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $h($h_n) $fs
	set fsink [new Agent/TCPSink]
	$fsink set set_prio_ $set_prio
	$fsink set ack_prio_ $ack_prio
	$ns attach-agent $n($k) $fsink
	$ns connect $fs $fsink
	set fltcpexp(s$i) [new Application/Traffic/Exponential]
	$fltcpexp(s$i) attach-agent $fs
	# This is the default packetSize value	
	$fltcpexp(s$i) set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]	
	$fltcpexp(s$i) set rate_ [expr $fl_TCP_packets_rate*8*$fl_msg_size]
	$fltcpexp(s$i) set burst_time_ 0.001
	$fltcpexp(s$i) set idle_time_ [expr 1/$fl_TCP_packets_rate]
	$ns at $t "$fltcpexp(s$i) start"
	$ns at [expr $t + $traffic_duration] "$fltcpexp(s$i) stop"
	set fltcpexp(index) [expr $fltcpexp(index) + 1]
}

# Bulk TCP Poisson traffic
proc new-rl-tcp-poisson { i k t } {
	global ns rltcpexp h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global traffic_duration NbrFLC

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
	$rs set fid_ $tcp_fid
	$rs set prio_ $tcp_data_prio
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $rs
	set rsink [new Agent/TCPSink]
	$rsink set set_prio_ $set_prio
	$rsink set ack_prio_ $ack_prio
	$ns attach-agent $h($h_n) $rsink
	$ns connect $rs $rsink
	set rltcpexp(s$i) [new Application/Traffic/Exponential]
	$rltcpexp(s$i) attach-agent $rs
	# This is the default packetSize value
	# $rltcpexp(s$i) set packetSize_ $mtu
	# $rltcpexp(s$i) set packetSize_ [expr $mtu-[$rs set tcpip_base_hdr_size_]]
	# $rltcpexp(s$i) set packetSize_ 156250
	$rltcpexp(s$i) set packetSize_ $rl_packet_size
	# $rltcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$rs set packetSize_]]	
# The Exponential On/Off generator can be configured to behave as a Poisson process by setting the variable burst_time
# to 0 and the variable rate_ to a very large value. The C++ code guarantees that even if the burst time is zero, at least one
# packet is sent. Additionally, the next interarrival time is the sum of the assumed packet transmission time (governed by the
# variable rate_) and the random variate corresponding to idle_time_. Therefore, to make the first term in the sum very
# small, make the burst rate very large so that the transmission time is negligible compared to the typical idle times.
	$rltcpexp(s$i) set rate_ 10000Mb
	$rltcpexp(s$i) set burst_time_ 0
	$rltcpexp(s$i) set idle_time_ [expr 1/$rl_TCP_packets_rate]
	$ns at $t "$rltcpexp(s$i) start"
	$ns at [expr $t + $traffic_duration] "$rltcpexp(s$i) stop"
	set rltcpexp(index) [expr $rltcpexp(index) + 1]
}

proc new-fl-tcp-poisson { i k t } {
	global ns fltcpexp h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global traffic_duration no_terminals NbrFLC
	
	set fs [new Agent/TCP/Linux]
	# set fs [new Agent/TCP/FullTcp/Sack]
	$fs set tcpip_base_hdr_size_ 40	
	$fs set segsize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	$fs set fid_ $tcp_fid
	$fs set prio_ $tcp_data_prio	
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $h($h_n) $fs
	set fsink [new Agent/TCPSink]
	$fsink set set_prio_ $set_prio
	$fsink set ack_prio_ $ack_prio
	$ns attach-agent $n($k) $fsink
	$ns connect $fs $fsink
	set fltcpexp(s$i) [new Application/Traffic/Exponential]
	$fltcpexp(s$i) attach-agent $fs
	# This is the default packetSize value
	# $fltcpexp(s$i) set packetSize_ 156250
	$fltcpexp(s$i) set packetSize_ $fl_packet_size
	# $fltcpexp(s$i) set packetSize_ [expr $mtu-[$fs set tcpip_base_hdr_size_]]
	# $fltcpexp(s$i) set packetSize_ [expr 1 + [ns-random] % [$fs set packetSize_]]
# The Exponential On/Off generator can be configured to behave as a Poisson process by setting the variable burst_time
# to 0 and the variable rate_ to a very large value. The C++ code guarantees that even if the burst time is zero, at least one
# packet is sent. Additionally, the next interarrival time is the sum of the assumed packet transmission time (governed by the
# variable rate_) and the random variate corresponding to idle_time_. Therefore, to make the first term in the sum very
# small, make the burst rate very large so that the transmission time is negligible compared to the typical idle times.
	$fltcpexp(s$i) set rate_ 10000Mb
	$fltcpexp(s$i) set burst_time_ 0
	$fltcpexp(s$i) set idle_time_ [expr 1/$fl_TCP_packets_rate]
	$ns at $t "$fltcpexp(s$i) start"
	$ns at [expr $t + $traffic_duration] "$fltcpexp(s$i) stop"
	set fltcpexp(index) [expr $fltcpexp(index) + 1]
}

## Bulk TCP traffic ##
proc new-rl-tcp { i k t } {
	global ns rltcp rlftp rsink f h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global NbrFLC tcp_duration

	set rltcp($rltcp(index)) [new Agent/TCP/Linux]
	# set rltcp($rltcp(index)) [new Agent/TCP/FullTcp/Sack]
	$rltcp($rltcp(index)) set class_ 0
	# Print TCP parameters
	#   Window_ sets the ssthreshold. Terrestrial TCP senders use as
#		initial ssthreshold value of 38 pkts as it is common.
#		Since the advwindow is implemented this value is only used to initialize the value of 
#		ssthreshold and must be sufficient high to not distub the operation of TCP sender
#		Note that cwnd_ is bounded by min (window_, advwindow_, maxcwnd_)
#		For Satelite TCP sender a high value is set to analize in TCP SACk baseline the Slow Start
#		behaviour over LFN satelite networks preventing the smooth transition between Slow Start 
#		and Congestion Avoidance phases.
# 	$rltcp($rltcp(index)) set window_ 20
 	$rltcp($rltcp(index)) set window_ 100
#   $rltcp($rltcp(index)) set window_ $buff_size_pkts
	if { $rltcp(index) == 0 } {
		puts "TCP slow start threshold: [$rltcp($rltcp(index)) set window_]"
	}
#   $rltcp($rltcp(index)) set tcpTick_ 0.01
	if { $rltcp(index) == 0 } {
		puts "TCP tick: [$rltcp($rltcp(index)) set tcpTick_]"
	}
# default value
#   $rltcp($rltcp(index)) set windowInit_ 2
#   $rltcp($rltcp(index)) set windowInit_ 3
    $rltcp($rltcp(index)) set windowInit_ 10
#   $rltcp($rltcp(index)) set windowInit_ $buff_size_pkts
	if { $rltcp(index) == 0 } {
		puts "TCP initial window size: [$rltcp($rltcp(index)) set windowInit_]"
	}
#	puts "TCP initial window size: [$rltcp($rltcp(index)) set wnd_init_]"
# 		The advwindow_ initial value is set the initial ssthreshold value in TCP senders. This 
#		value is used by TCP sender until the receiver updates its value to the advertize receiver 
#		window 
#   $rltcp($rltcp(index)) set advwindow_ 		[$rltcp($rltcp(index)) set window_]
	# puts "TCP advertised window size: [$rltcp($rltcp(index)) set advwindow_]"
	# The advertised window is simulated by simply telling the sender a bound on the window size (wnd_).
	# In real TCP, a user process performing a read (via PRU_RCVD) calls tcp_output each time to (possibly) send a window
    # update.  Here we don't have a user process, so we simulate a user process always ready to consume all the receive buffer *
 # Notes: wnd_, wnd_init_, cwnd_, ssthresh_ are in segment units, sequence and ack numbers are in byte units
 	# puts "TCP advertised window size: [$rltcp($rltcp(index)) set wnd_]"
#		maxcwnd_ is the upper bound of TCP sender cwnd_	. The cwnd_ is bounded by 
#		min (advwindow_, maxcwnd_)	
#	$rltcp($rltcp(index)) set maxcwnd_ 5000
	if { $rltcp(index) == 0 } {
		puts "TCP maximum congestion window size: [$rltcp($rltcp(index)) set maxcwnd_]"
	}
	$rltcp($rltcp(index)) set tcpip_base_hdr_size_ 40
	$rltcp($rltcp(index)) set segsize_ [expr $mtu-[$rltcp($rltcp(index)) set tcpip_base_hdr_size_]]
	$rltcp($rltcp(index)) set packetSize_ [expr $mtu-[$rltcp($rltcp(index)) set tcpip_base_hdr_size_]]
	$rltcp($rltcp(index)) set fid_ $tcp_fid
	$rltcp($rltcp(index)) set prio_ $tcp_data_prio
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $n($k) $rltcp($rltcp(index))

	# Let's trace some TCP variables
	$rltcp($rltcp(index)) attach $f
	$rltcp($rltcp(index)) tracevar cwnd_
	$rltcp($rltcp(index)) tracevar ssthresh_
	$rltcp($rltcp(index)) tracevar ack_
	$rltcp($rltcp(index)) tracevar maxseq_

	set rsink($rltcp(index)) [new Agent/TCPSink]
	$rsink($rltcp(index)) set set_prio_ $set_prio
	$rsink($rltcp(index)) set ack_prio_ $ack_prio
	$ns attach-agent $h($h_n) $rsink($rltcp(index))
	$ns connect $rltcp($rltcp(index)) $rsink($rltcp(index))
	set rlftp($rltcp(index)) [new Application/FTP]
	$rlftp($rltcp(index)) attach-agent $rltcp($rltcp(index))
	$ns at $t "$rlftp($rltcp(index)) start"
	$ns at [expr $t + $tcp_duration] "$rlftp($rltcp(index)) stop"
	set rltcp(index) [expr $rltcp(index) + 1]
}

proc new-fl-tcp { i k t } {
	global ns fltcp flftp fsink f h n mtu tcp_data_prio tcp_fid set_prio ack_prio
	global no_terminals NbrFLC tcp_duration
	
	set fltcp($fltcp(index)) [new Agent/TCP/Linux]
	# set fltcp($fltcp(index)) [new Agent/TCP/FullTcp/Sack]
	$fltcp($fltcp(index)) set class_ 0
	$fltcp($fltcp(index)) set tcpip_base_hdr_size_ 40	
	$fltcp($fltcp(index)) set segsize_ [expr $mtu-[$fltcp($fltcp(index)) set tcpip_base_hdr_size_]]
	$fltcp($fltcp(index)) set packetSize_ [expr $mtu-[$fltcp($fltcp(index)) set tcpip_base_hdr_size_]]
	$fltcp($fltcp(index)) set fid_ $tcp_fid
	$fltcp($fltcp(index)) set prio_ $tcp_data_prio	
	set h_n [expr $i % $NbrFLC]
	$ns attach-agent $h($h_n) $fltcp($fltcp(index))

	# Let's trace some TCP variables
	$fltcp($fltcp(index)) attach $f
	$fltcp($fltcp(index)) tracevar cwnd_
	$fltcp($fltcp(index)) tracevar ssthresh_
	$fltcp($fltcp(index)) tracevar ack_
	$fltcp($fltcp(index)) tracevar maxseq_

	set fsink($fltcp(index)) [new Agent/TCPSink]
	$fsink($fltcp(index)) set set_prio_ $set_prio
	$fsink($fltcp(index)) set ack_prio_ $ack_prio
	$ns attach-agent $n($k) $fsink($fltcp(index))
	$ns connect $fltcp($fltcp(index)) $fsink($fltcp(index))
	set flftp($fltcp(index)) [new Application/FTP]
	$flftp($fltcp(index)) attach-agent $fltcp($fltcp(index))
	$ns at $t "$flftp($fltcp(index)) start"
	$ns at [expr $t + $tcp_duration] "$flftp($fltcp(index)) stop"
	set fltcp(index) [expr $fltcp(index) + 1]
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
	global ns objnum tcp num_conn obj_num mtu data_prio tcp_fid
	global page_req_time
	$self instvar id n1 n2
	
	set now [$ns now]
	
	for {set i 0} {$i< $num_conn} {incr i} {

		set tcpc [new Agent/TCP/FullTcp/Sack]
		$tcpc set tcpip_base_hdr_size_ 40
		$tcpc set segsize_ [expr $mtu-[$tcpc set tcpip_base_hdr_size_]]
#		$tcpc set fid_ $id
		$tcpc set fid_ $tcp_fid
		$tcpc set prio_ $data_prio
		set tcps [new Agent/TCP/FullTcp/Sack]
		$tcps set tcpip_base_hdr_size_ 40
		$tcps set segsize_ [expr $mtu-[$tcps set tcpip_base_hdr_size_]]
#		$tcps set fid_ $id
		$tcps set fid_ $tcp_fid
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

	global ns mtu data_prio tcp_fid
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
	$tcps set fid_ $tcp_fid
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
	$ns queue-limit $n0 $h($i) [expr ceil($rx_capacity_per_FLC_Mb*1e6*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
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
	$ns queue-limit $h($i) $n0 [expr ceil($tx_capacity_per_FLC_kb*1e3*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $h($i) $n0 queuePos 0.5
#	$ns trace-queue $h($i) $n0
#	$ns namtrace-queue $h($i) $n0
}

for {set i 0} { $i < $NbrRLC } {incr i} {
	$ns simplex-link $n0 $an($i) $rx_capacity_per_RLC $rx_latency_per_RLC DropTail
	# $ns queue-limit $n0 $an($i) 50
	$ns queue-limit $n0 $an($i) [expr ceil($rx_capacity_per_RLC_Mb*1e6*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
	# Monitor the queue for link (for NAM)
	$ns simplex-link-op $n0 $an($i) queuePos 0.5
#	$ns trace-queue $n0 $an($i)
#	$ns namtrace-queue $n0 $an($i)
	# $ns simplex-link $an($i) $n0 $tx_capacity_per_RLC $tx_latency_per_RLC DropTail
	$ns simplex-link $an($i) $n0 $tx_capacity_per_RLC $tx_latency_per_RLC dsRED/core
	# $ns queue-limit $an($i) $n0 50
	$ns queue-limit $an($i) $n0 [expr ceil($tx_capacity_per_RLC_kb*1e3*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
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
	$ns queue-limit $n($i) $an($k) [expr ceil($onboard_net_capacity_Mb*1e6*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
	# $ns queue-limit $an($k) $n($i) 1700000
	$ns queue-limit $an($k) $n($i) [expr ceil($onboard_net_capacity_Mb*1e6*($qos1(deadline)+$qos2(deadline)+$qos3(deadline))/(8*$ack_size))]
}

## DiffServ configuration

## Get DiffServ queues handles
for {set i 0} { $i < $NbrFLC } {incr i} {
	set qh($i) [[$ns link $h($i) $n0] queue]
	## Set mean packet size for RED average queue length calculation to something greater than zero to avoid segfault
	$qh($i) meanPktSize $ack_size
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
	set minth0 [expr ceil($bwFL_kb*1e3*$qos1(deadline)/(8*$ack_size*$NbrFLC))]
	$qh($i) configQ 0 0 $minth0 [expr $minth0 + 10] 0.10
	set minth1 [expr ceil($bwFL_kb*1e3*$qos2(deadline)/(8*$ack_size*$NbrFLC))]
	$qh($i) configQ 1 0 $minth1 [expr $minth1 + 10] 0.10
#	set minth2 [expr ceil($fl_bdp_factor*$tx_capacity_per_FLC_kb*($delayFLms + $delayRLms)/(8.0*$ack_size))]
	set minth2 [expr ceil($bwFL_kb*1e3*$qos3(deadline)/(8*$ack_size*$NbrFLC))]
	$qh($i) configQ 2 0 $minth2 [expr $minth2 + 10] 0.10
	## Map code point 46 (EF) to physical queue 0 virtual queue 0
	$qh($i) addPHBEntry $ef_data_prio 0 0
	## Map code point 10 (AF) to physical queue 1 virtual queue 0
	$qh($i) addPHBEntry $af_data_prio 1 0
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
	$qa($i) meanPktSize $ack_size
	$qa($i) set NumQueues_ 3
	$qa($i) setNumPrec 1
	$qa($i) setMREDMode DROP 0
	$qa($i) setMREDMode DROP 1
	$qa($i) setMREDMode DROP 2
	set minth0 [expr ceil($bwRL_kb*1e3*$qos1(deadline)/(8*$ack_size*$NbrRLC))]
	set minth1 [expr ceil($bwRL_kb*1e3*$qos2(deadline)/(8*$ack_size*$NbrRLC))]
#	set minth2 [expr ceil($rl_bdp_factor*$tx_capacity_per_RLC_kb*($delayFLms + $delayRLms)/(8.0*$ack_size))]
	set minth2 [expr ceil($bwRL_kb*1e3*$qos3(deadline)/(8*$ack_size*$NbrRLC))]
	$qa($i) configQ 0 0 $minth0 [expr $minth0 + 10] 0.10
	$qa($i) configQ 1 0 $minth1 [expr $minth1 + 10] 0.10
	$qa($i) configQ 2 0 $minth2 [expr $minth2 + 10] 0.10
	$qa($i) addPHBEntry $ef_data_prio 0 0
	$qa($i) addPHBEntry $af_data_prio 1 0
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

proc finish-sim {} {
	global ns f nf rludpExpo fludpExpo no_terminals NbrRLC NbrFLC num_cos rltcp fltcp rsink fsink tcp_duration
	global last_web_done web_duration min_web_duration max_web_duration num_webs web_duration_filename
	
	$ns flush-trace
	close $nf
	close $f

	for {set i 0} {$i<$rltcp(index)} {incr i} {
		set lastACKrltcp($i) [$rltcp($i) set ack_]
		set lastSEQrltcp($i) [$rltcp($i) set maxseq_]
		set ACKedRL($i) [$rsink($i) set bytes_]
		set reTxRL($i) [$rltcp($i) set nrexmitpack_]
		puts "RL TCP $i Rx $ACKedRL($i) bytes, final ack: $lastACKrltcp($i), final seq num: $lastSEQrltcp($i), ReTx Pkts: $reTxRL($i)"
		puts "RL TCP $i estimated goodput: [expr $ACKedRL($i)*8/(1000*$tcp_duration)] kbit/s"
	}

	for {set i 0} {$i<$fltcp(index)} {incr i} {
		set lastACKfltcp($i) [$fltcp($i) set ack_]
		set lastSEQfltcp($i) [$fltcp($i) set maxseq_]
		set ACKedFL($i) [$fsink($i) set bytes_]
		set reTxFL($i) [$fltcp($i) set nrexmitpack_]
		puts "FL TCP $i Rx $ACKedFL($i) bytes, final ack: $lastACKfltcp($i), final seq num: $lastSEQfltcp($i), ReTx Pkts: $reTxFL($i)"
		puts "FL TCP $i estimated goodput: [expr $ACKedFL($i)*8/(1000*$tcp_duration)] kbit/s"
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
	exec ./modelDatalink.sh $NbrRLC $NbrFLC $no_terminals $num_cos
	puts "Launching NAM..."
	exec nam modelDatalink.nam &
	puts "Finished"
	$ns halt
}

for {set i 0} {$i<$no_terminals} {incr i} {
	# $ns at $start "new-pings $i $i"
	# $ns at $start "new-rl-udpExpo $i $i"
	# $ns at $start "new-rl-tcpExpo $i $i"
	# for {set j 0} { $j < [expr $no_streams_term-1]} {incr j} {
		# $ns at $start "new-rl-voip [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-fl-voip [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-pings [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-rl-tcp-poisson [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-fl-tcp-poisson [expr $i*$no_streams_term+$j] $i"
		# $ns at $start "new-fl-tcp-exp [expr $i*$no_streams_term+$j] $i"
		# set k [expr [ns-random] % $no_terminals]
		# set h_n [expr [ns-random] % $NbrFLC]
		# set t_download [expr $reset + [$request_time value]]
		# $ns at $t_download "new-http-session [expr $i*$no_streams_term+$j] $n($k) $h($h_n)"
		# set t_upload [expr $reset + [$request_time value]]
		# $ns at $t_upload "new-http-session [expr $i*$no_streams_term+$j] $h($h_n) $n($k)"
	# }
	# for {set j 0} { $j < $no_streams_term} {incr j} {
	#	$ns at $start "new-fl-voip [expr $i*$no_streams_term+$j] $i"
	#}
}

set pingTime $currTime
$ns at $start "new-pings 0 0 $pingTime"
set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]

# TCP tests
$ns at $start "new-fl-tcp 0 0 $currTime"
set currTime [expr $currTime + 5.0 + $tcp_duration]
set pingTime $currTime
$ns at $start "new-pings 0 0 $pingTime"
set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]

$ns at $start "new-rl-tcp 0 0 $currTime"
$ns at $start "new-fl-tcp 0 0 $currTime"
set currTime [expr $currTime + 5.0 + $tcp_duration]
set pingTime $currTime
$ns at $start "new-pings 0 0 $pingTime"
set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]

$ns at $start "new-rl-tcp 0 0 $currTime"
set currTime [expr $currTime + 5.0 + $tcp_duration]
set pingTime $currTime
$ns at $start "new-pings 0 0 $pingTime"
set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]
# End of TCP tests

# UDP Expo Agents
if {$rl_UDP_packets_rate > 0 } {
	$ns at $start "new-rl-udpExpo 0 0 $currTime"
	set currTime [expr $currTime + 5.0 + $rl_udp_traffic_duration]
	set pingTime $currTime
	$ns at $start "new-pings 0 0 $pingTime"
	set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]
}

if {$fl_UDP_packets_rate > 0 } {
	$ns at $start "new-fl-udpExpo 0 0 $currTime"
	set currTime [expr $currTime + 5.0 + $fl_udp_traffic_duration]
	set pingTime $currTime
	$ns at $start "new-pings 0 0 $pingTime"
	set currTime [expr $pingTime + $ping_rtt_ms/1000.0 + 1.0]
}

# $ns at $start "new-fl-voip 0 0"

# $ns at $start "new-fl-tcp-poisson 0 0"

# Web download
# $ns at $start "new-http-session 0 $n(0) $h(0)"
# Web upload
# $ns at $start "new-http-session 0 $h(0) $n(0)"

# set fpingstime1 [expr $stop + 1.0 + $num_fl_flows + $num_rl_flows]
set fpingstime1 [expr $currTime + $finish_margin + 1.0]
set rpingstime1 [expr $fpingstime1 + 1.0]
# set pingTime $rpingstime1
# $ns at $start "new-pings 0 0 $pingTime"

set duration [expr $rpingstime1 + $finish_margin]

$ns at $duration "finish-sim"

$ns run

