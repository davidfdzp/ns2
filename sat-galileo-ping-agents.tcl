
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

set pingtx8 [new Agent/Ping]
$pingtx8 set packetSize_ $ping_pkt_size
$pingtx8 set fid_ 1
$pingtx8 set prio_ 0
$ns attach-agent $n100 $pingtx8
set pingrx8 [new Agent/Ping]
$pingrx8 set packetSize_ $ping_pkt_size
$pingrx8 set fid_ 1
$pingrx8 set prio_ 0
$ns attach-agent $n8 $pingrx8
$ns connect $pingtx8 $pingrx8

set pingtx9 [new Agent/Ping]
$pingtx9 set packetSize_ $ping_pkt_size
$pingtx9 set fid_ 1
$pingtx9 set prio_ 0
$ns attach-agent $n100 $pingtx9
set pingrx9 [new Agent/Ping]
$pingrx9 set packetSize_ $ping_pkt_size
$pingrx9 set fid_ 1
$pingrx9 set prio_ 0
$ns attach-agent $n9 $pingrx9
$ns connect $pingtx9 $pingrx9

set pingtx15 [new Agent/Ping]
$pingtx15 set packetSize_ $ping_pkt_size
$pingtx15 set fid_ 1
$pingtx15 set prio_ 0
$ns attach-agent $n100 $pingtx15
set pingrx15 [new Agent/Ping]
$pingrx15 set packetSize_ $ping_pkt_size
$pingrx15 set fid_ 1
$pingrx15 set prio_ 0
$ns attach-agent $n15 $pingrx15
$ns connect $pingtx15 $pingrx15

set pingtx16 [new Agent/Ping]
$pingtx16 set packetSize_ $ping_pkt_size
$pingtx16 set fid_ 1
$pingtx16 set prio_ 0
$ns attach-agent $n100 $pingtx16
set pingrx16 [new Agent/Ping]
$pingrx16 set packetSize_ $ping_pkt_size
$pingrx16 set fid_ 1
$pingrx16 set prio_ 0
$ns attach-agent $n16 $pingrx16
$ns connect $pingtx16 $pingrx16

set pingtx17 [new Agent/Ping]
$pingtx17 set packetSize_ $ping_pkt_size
$pingtx17 set fid_ 1
$pingtx17 set prio_ 0
$ns attach-agent $n100 $pingtx17
set pingrx17 [new Agent/Ping]
$pingrx17 set packetSize_ $ping_pkt_size
$pingrx17 set fid_ 1
$pingrx17 set prio_ 0
$ns attach-agent $n17 $pingrx17
$ns connect $pingtx17 $pingrx17

set pingtx18 [new Agent/Ping]
$pingtx18 set packetSize_ $ping_pkt_size
$pingtx18 set fid_ 1
$pingtx18 set prio_ 0
$ns attach-agent $n100 $pingtx18
set pingrx18 [new Agent/Ping]
$pingrx18 set packetSize_ $ping_pkt_size
$pingrx18 set fid_ 1
$pingrx18 set prio_ 0
$ns attach-agent $n18 $pingrx18
$ns connect $pingtx18 $pingrx18

set pingtx19 [new Agent/Ping]
$pingtx19 set packetSize_ $ping_pkt_size
$pingtx19 set fid_ 1
$pingtx19 set prio_ 0
$ns attach-agent $n100 $pingtx19
set pingrx19 [new Agent/Ping]
$pingrx19 set packetSize_ $ping_pkt_size
$pingrx19 set fid_ 1
$pingrx19 set prio_ 0
$ns attach-agent $n1 $pingrx19
$ns connect $pingtx19 $pingrx19

set pingtx20 [new Agent/Ping]
$pingtx20 set packetSize_ $ping_pkt_size
$pingtx20 set fid_ 1
$pingtx20 set prio_ 0
$ns attach-agent $n100 $pingtx20
set pingrx20 [new Agent/Ping]
$pingrx20 set packetSize_ $ping_pkt_size
$pingrx20 set fid_ 1
$pingrx20 set prio_ 0
$ns attach-agent $n20 $pingrx20
$ns connect $pingtx20 $pingrx20

set pingtx21 [new Agent/Ping]
$pingtx21 set packetSize_ $ping_pkt_size
$pingtx21 set fid_ 1
$pingtx21 set prio_ 0
$ns attach-agent $n100 $pingtx21
set pingrx21 [new Agent/Ping]
$pingrx21 set packetSize_ $ping_pkt_size
$pingrx21 set fid_ 1
$pingrx21 set prio_ 0
$ns attach-agent $n21 $pingrx21
$ns connect $pingtx21 $pingrx21

set pingtx22 [new Agent/Ping]
$pingtx22 set packetSize_ $ping_pkt_size
$pingtx22 set fid_ 1
$pingtx22 set prio_ 0
$ns attach-agent $n100 $pingtx22
set pingrx22 [new Agent/Ping]
$pingrx22 set packetSize_ $ping_pkt_size
$pingrx22 set fid_ 1
$pingrx22 set prio_ 0
$ns attach-agent $n22 $pingrx22
$ns connect $pingtx22 $pingrx22

set pingtx23 [new Agent/Ping]
$pingtx23 set packetSize_ $ping_pkt_size
$pingtx23 set fid_ 1
$pingtx23 set prio_ 0
$ns attach-agent $n100 $pingtx23
set pingrx23 [new Agent/Ping]
$pingrx23 set packetSize_ $ping_pkt_size
$pingrx23 set fid_ 1
$pingrx23 set prio_ 0
$ns attach-agent $n23 $pingrx23
$ns connect $pingtx23 $pingrx23

set pingtx24 [new Agent/Ping]
$pingtx24 set packetSize_ $ping_pkt_size
$pingtx24 set fid_ 1
$pingtx24 set prio_ 0
$ns attach-agent $n100 $pingtx24
set pingrx24 [new Agent/Ping]
$pingrx24 set packetSize_ $ping_pkt_size
$pingrx24 set fid_ 1
$pingrx24 set prio_ 0
$ns attach-agent $n24 $pingrx24
$ns connect $pingtx24 $pingrx24

set pingtx30 [new Agent/Ping]
$pingtx30 set packetSize_ $ping_pkt_size
$pingtx30 set fid_ 1
$pingtx30 set prio_ 0
$ns attach-agent $n100 $pingtx30
set pingrx30 [new Agent/Ping]
$pingrx30 set packetSize_ $ping_pkt_size
$pingrx30 set fid_ 1
$pingrx30 set prio_ 0
$ns attach-agent $n30 $pingrx30
$ns connect $pingtx30 $pingrx30

set pingtx31 [new Agent/Ping]
$pingtx31 set packetSize_ $ping_pkt_size
$pingtx31 set fid_ 1
$pingtx31 set prio_ 0
$ns attach-agent $n100 $pingtx31
set pingrx31 [new Agent/Ping]
$pingrx31 set packetSize_ $ping_pkt_size
$pingrx31 set fid_ 1
$pingrx31 set prio_ 0
$ns attach-agent $n31 $pingrx31
$ns connect $pingtx31 $pingrx31

set pingtx32 [new Agent/Ping]
$pingtx32 set packetSize_ $ping_pkt_size
$pingtx32 set fid_ 1
$pingtx32 set prio_ 0
$ns attach-agent $n100 $pingtx32
set pingrx32 [new Agent/Ping]
$pingrx32 set packetSize_ $ping_pkt_size
$pingrx32 set fid_ 1
$pingrx32 set prio_ 0
$ns attach-agent $n32 $pingrx32
$ns connect $pingtx32 $pingrx32

set pingtx33 [new Agent/Ping]
$pingtx33 set packetSize_ $ping_pkt_size
$pingtx33 set fid_ 1
$pingtx33 set prio_ 0
$ns attach-agent $n100 $pingtx33
set pingrx33 [new Agent/Ping]
$pingrx33 set packetSize_ $ping_pkt_size
$pingrx33 set fid_ 1
$pingrx33 set prio_ 0
$ns attach-agent $n33 $pingrx33
$ns connect $pingtx33 $pingrx33

set pingtx34 [new Agent/Ping]
$pingtx34 set packetSize_ $ping_pkt_size
$pingtx34 set fid_ 1
$pingtx34 set prio_ 0
$ns attach-agent $n100 $pingtx34
set pingrx34 [new Agent/Ping]
$pingrx34 set packetSize_ $ping_pkt_size
$pingrx34 set fid_ 1
$pingrx34 set prio_ 0
$ns attach-agent $n34 $pingrx34
$ns connect $pingtx34 $pingrx34

set pingtx35 [new Agent/Ping]
$pingtx35 set packetSize_ $ping_pkt_size
$pingtx35 set fid_ 1
$pingtx35 set prio_ 0
$ns attach-agent $n100 $pingtx35
set pingrx35 [new Agent/Ping]
$pingrx35 set packetSize_ $ping_pkt_size
$pingrx35 set fid_ 1
$pingrx35 set prio_ 0
$ns attach-agent $n35 $pingrx35
$ns connect $pingtx35 $pingrx35

set pingtx36 [new Agent/Ping]
$pingtx36 set packetSize_ $ping_pkt_size
$pingtx36 set fid_ 1
$pingtx36 set prio_ 0
$ns attach-agent $n100 $pingtx36
set pingrx36 [new Agent/Ping]
$pingrx36 set packetSize_ $ping_pkt_size
$pingrx36 set fid_ 1
$pingrx36 set prio_ 0
$ns attach-agent $n36 $pingrx36
$ns connect $pingtx36 $pingrx36

set pingtx37 [new Agent/Ping]
$pingtx37 set packetSize_ $ping_pkt_size
$pingtx37 set fid_ 1
$pingtx37 set prio_ 0
$ns attach-agent $n100 $pingtx37
set pingrx37 [new Agent/Ping]
$pingrx37 set packetSize_ $ping_pkt_size
$pingrx37 set fid_ 1
$pingrx37 set prio_ 0
$ns attach-agent $n37 $pingrx37
$ns connect $pingtx37 $pingrx37

set pingtx38 [new Agent/Ping]
$pingtx38 set packetSize_ $ping_pkt_size
$pingtx38 set fid_ 1
$pingtx38 set prio_ 0
$ns attach-agent $n100 $pingtx38
set pingrx38 [new Agent/Ping]
$pingrx38 set packetSize_ $ping_pkt_size
$pingrx38 set fid_ 1
$pingrx38 set prio_ 0
$ns attach-agent $n38 $pingrx38
$ns connect $pingtx38 $pingrx38

set pingtx39 [new Agent/Ping]
$pingtx39 set packetSize_ $ping_pkt_size
$pingtx39 set fid_ 1
$pingtx39 set prio_ 0
$ns attach-agent $n100 $pingtx39
set pingrx39 [new Agent/Ping]
$pingrx39 set packetSize_ $ping_pkt_size
$pingrx39 set fid_ 1
$pingrx39 set prio_ 0
$ns attach-agent $n39 $pingrx39
$ns connect $pingtx39 $pingrx39

