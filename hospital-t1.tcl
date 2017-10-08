##
## Network Topology of Hospital Case Study Current Solution Model
##
## Simulated topology consists of a Main Hospital Router connected to 
## two satellite building routers by T1 links (1.544 Mbit/s full-duplex)
## Note that in an European Hospital that would be E1 links at 2.048 Mbit/s.
##
## There are ping agents at each building router.
## A VoIP call can be established between one building and another
## An FTP transfer can be done between one building and another
##
## Reference: http://intronetworks.cs.luc.edu/current/html/ns2.html

set ber 1e-6
# set ber 0.0
set per 0.0

puts "BER=$ber"

set bw 1.544Mb
# set bw 2.048Mb

set startpingtime 0.0
set startime 1.0
set stoptime 101.0
set stoppingtime 110.0
set endtime 120.0

set ns [new Simulator]

# Main Hospital
set n0 [$ns node]
# Building 1
set n1 [$ns node]
# Building 2
set n2 [$ns node]

set f [open hospital-t1.tr w]
$ns trace-all $f

# set windowVsTime [open WindowVsTime w]

set nf [open hospital-t1.nam w]
$ns namtrace-all $nf

$ns duplex-link $n0 $n1 $bw 1ms DropTail
# $ns queue-limit $n0 $n1 50
$ns duplex-link $n0 $n2 $bw 1ms DropTail
# $ns queue-limit $n0 $n2 50

# Queue monitoring
# set qmon [$ns monitor-queue $n0 $n2 [open qm.out w] 0.1];
# [$ns link $n0 $n2] queue-sample-timeout; # [$ns link $n0 $n2] start-tracing

# $ns duplex-link-op $n0 $n1 orient right
# $ns duplex-link-op $n0 $n2 orient left

# $ns duplex-link-op $n0 $n1 queuePos 0.5

#$ns trace-queue $n0 $n1 $f

# Add an error model to the receiving building 1
set em1_ [new ErrorModel]
$em1_ unit byte
# Byte error rate = 1 - (1-BER)^8
$em1_ set rate_ [expr 1-pow((1-$ber),8)]
# $em1_ unit pkt
# $em1_ set rate_ $per
$em1_ ranvar [new RandomVariable/Uniform]
$em1_ drop-target [new Agent/Null]
$ns link-lossmodel $em1_ $n0 $n2

#Define a 'recv' function for the class 'Agent/Ping'
Agent/Ping instproc recv {from rtt} {
	global ns
	$self instvar node_
	puts "t=[$ns now]: node [$node_ id] received ping answer from \
	$from with round-trip-time $rtt ms."
}

# Building 1 Ping Agent
set bp1 [new Agent/Ping]
$bp1 set packetSize_ 64
$bp1 set packetSize_ 64
$bp1 set fid_ 100
$bp1 set prio_ 0
$ns attach-agent $n1 $bp1
$ns at $startpingtime "$bp1 send"
$ns at $stoptime "$bp1 set packetSize_ 1064"
$ns at [expr ($startime+$stoptime)/2.0] "$bp1 send"
$ns at $stoppingtime "$bp1 send"

# Building 2 Ping Agent
set bp2 [new Agent/Ping]
$bp2 set packetSize_ 64
$bp2 set fid_ 100
$bp2 set prio_ 0
$ns attach-agent $n2 $bp2
$ns connect $bp1 $bp2
$ns at $stoptime "$bp2 set packetSize_ 1064"

# Attach agents for FTP over TCP/Tahoe
set tcp1 [new Agent/TCP]
# default value
# $tcp1 set window_ 20
# $tcp1 set window_ 100
$tcp1 set packetSize_ 1460
# Trace ack_ and maxseq_ to get the amount of data transferred
$tcp1 attach $f
# $tcp1 tracevar cwnd_
$tcp1 tracevar ack_
$tcp1 tracevar maxseq_
$ns attach-agent $n1 $tcp1
set sink1 [new Agent/TCPSink]
$ns attach-agent $n2 $sink1
$ns connect $tcp1 $sink1
set ftp1 [$tcp1 attach-app FTP]
# $ns at 7.0 "$ftp1 produce 100"
# $ftp produce <n> Causes the FTP object to produce n packets instantaneously

## set up a VoIP

set s1 [new Agent/UDP]
$s1 set fid_ 0
$ns attach-agent $n1 $s1

set null1 [new Agent/UDP]
$ns attach-agent $n2 $null1

$ns connect $s1 $null1

set voip_s [new Application/Traffic/Voice]
set voip_r [new Application/Traffic/Voice]

$voip_s attach-agent $s1
$voip_s set interval_ 0.02
$voip_s set burst_time_ 6.0
$voip_s set idle_time_ 6.0
$voip_s set packetSize_ 80
# $voip_r set A_ 0
$voip_r attach-agent $null1

#Printing the window size
proc plotWindow {tcpSource file} {
global ns
set time 0.1
set now [$ns now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns at [expr $now+$time] "plotWindow $tcpSource $file" }

# $ns at [expr $startime-0.1] "plotWindow $tcp1 $windowVsTime"

$ns at $startime "$ftp1 start"
$ns at $stoptime "$ftp1 stop"

$ns at $startime "$voip_s start"
$ns at $stoptime "$voip_s stop"

$ns at $endtime "close $f"
$ns at $endtime "finish"

proc finish {} {
	global ns voip_r tcp1 startime stoptime

	$voip_r update_score
	puts "[$voip_r set delay_] [$voip_r set rscore_] [$voip_r set mos_]"

	set lastAck [$tcp1 set ack_]
	set lastSEQ [$tcp1 set maxseq_]
	set reTxNum [$tcp1 set nrexmitpack_]
	puts "Final ack: $lastAck, final seq num: $lastSEQ, Number of reTx packets: $reTxNum"
    puts "Estimated goodput: [expr $lastAck*8*1.460/($stoptime-$startime)] kbits/s [expr $lastAck*1460] bytes in [expr $stoptime-$startime] s"
    puts "Estimated throughput: [expr $lastSEQ*1.5*8/($stoptime-$startime)] kbits/s [expr $lastSEQ*1500] bytes in [expr $stoptime-$startime] s"

# http://intronetworks.cs.luc.edu/current/html/ns2.html#link-utilization-measurement
# Use gnuplot and throughput.pl to show it graphically

	puts "run nam hospital-t1.nam..."
	#exec nam hospital-t1.nam &

	$ns halt

}

$ns run

exit 0
