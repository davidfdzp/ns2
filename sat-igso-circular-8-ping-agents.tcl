
if {![info exists ns]} {
	puts "Error:  sat-galileo-ping-agents.tcl is a supporting script for the "
	puts "        sat-galileo-ping-sats.tcl script-- run `sat-galileo-ping-sats.tcl' instead"
	exit
}

set pingtx0 [new Agent/Ping]
$pingtx0 set packetSize_ $ping_pkt_size
$pingtx0 set fid_ 1
$pingtx0 set prio_ 0
$ns attach-agent $n100 $pingtx0
set pingrx0 [new Agent/Ping]
$pingrx0 set packetSize_ $ping_pkt_size
$pingrx0 set fid_ 1
$pingrx0 set prio_ 0
$ns attach-agent $n0 $pingrx0
$ns connect $pingtx0 $pingrx0

set pingtx1 [new Agent/Ping]
$pingtx1 set packetSize_ $ping_pkt_size
$pingtx1 set fid_ 1
$pingtx1 set prio_ 0
$ns attach-agent $n100 $pingtx1
set pingrx1 [new Agent/Ping]
$pingrx1 set packetSize_ $ping_pkt_size
$pingrx1 set fid_ 1
$pingrx1 set prio_ 0
$ns attach-agent $n1 $pingrx1
$ns connect $pingtx1 $pingrx1

set pingtx2 [new Agent/Ping]
$pingtx2 set packetSize_ $ping_pkt_size
$pingtx2 set fid_ 1
$pingtx2 set prio_ 0
$ns attach-agent $n100 $pingtx2
set pingrx2 [new Agent/Ping]
$pingrx2 set packetSize_ $ping_pkt_size
$pingrx2 set fid_ 1
$pingrx2 set prio_ 0
$ns attach-agent $n2 $pingrx2
$ns connect $pingtx2 $pingrx2

set pingtx3 [new Agent/Ping]
$pingtx3 set packetSize_ $ping_pkt_size
$pingtx3 set fid_ 1
$pingtx3 set prio_ 0
$ns attach-agent $n100 $pingtx3
set pingrx3 [new Agent/Ping]
$pingrx3 set packetSize_ $ping_pkt_size
$pingrx3 set fid_ 1
$pingrx3 set prio_ 0
$ns attach-agent $n3 $pingrx3
$ns connect $pingtx3 $pingrx3

set pingtx4 [new Agent/Ping]
$pingtx4 set packetSize_ $ping_pkt_size
$pingtx4 set fid_ 1
$pingtx4 set prio_ 0
$ns attach-agent $n100 $pingtx4
set pingrx4 [new Agent/Ping]
$pingrx4 set packetSize_ $ping_pkt_size
$pingrx4 set fid_ 1
$pingrx4 set prio_ 0
$ns attach-agent $n4 $pingrx4
$ns connect $pingtx4 $pingrx4

set pingtx5 [new Agent/Ping]
$pingtx5 set packetSize_ $ping_pkt_size
$pingtx5 set fid_ 1
$pingtx5 set prio_ 0
$ns attach-agent $n100 $pingtx5
set pingrx5 [new Agent/Ping]
$pingrx5 set packetSize_ $ping_pkt_size
$pingrx5 set fid_ 1
$pingrx5 set prio_ 0
$ns attach-agent $n5 $pingrx5
$ns connect $pingtx5 $pingrx5

set pingtx6 [new Agent/Ping]
$pingtx6 set packetSize_ $ping_pkt_size
$pingtx6 set fid_ 1
$pingtx6 set prio_ 0
$ns attach-agent $n100 $pingtx6
set pingrx6 [new Agent/Ping]
$pingrx6 set packetSize_ $ping_pkt_size
$pingrx6 set fid_ 1
$pingrx6 set prio_ 0
$ns attach-agent $n6 $pingrx6
$ns connect $pingtx6 $pingrx6

set pingtx7 [new Agent/Ping]
$pingtx7 set packetSize_ $ping_pkt_size
$pingtx7 set fid_ 1
$pingtx7 set prio_ 0
$ns attach-agent $n100 $pingtx7
set pingrx7 [new Agent/Ping]
$pingrx7 set packetSize_ $ping_pkt_size
$pingrx7 set fid_ 1
$pingrx7 set prio_ 0
$ns attach-agent $n7 $pingrx7
$ns connect $pingtx7 $pingrx7
