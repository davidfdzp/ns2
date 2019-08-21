#
# Copyright (c) 1999 Regents of the University of California.
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
#       This product includes software developed by the MASH Research
#       Group at the University of California Berkeley.
# 4. Neither the name of the University nor of the Research Group may be
#    used to endorse or promote products derived from this software without
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
# Contributed by Tom Henderson, UCB Daedalus Research Group, June 1999
#

if {![info exists ns]} {
	puts "Error:  sat-igso-circular-8-nodes.tcl is a supporting script for the "
	puts "        sat-igso-circular-8.tcl script-- run `sat-igso-circular-8.tcl' instead"
	exit
}
# $n0 set-position $alt $inc $lon $alpha $plane
# lon specifies the East longitude of "ascending node"
# alpha specifies the initial angle with respect to the "ascending node"
# offset to position the orbits above the desired longitude
set offset +70
proc compute_lon { lon offset } {
	set lon [expr $lon + $offset]
	if { $lon > 180 } {
		set lon [expr $lon - 360]
	} elseif { $lon < -180 } {
		set lon [expr $lon + 360]
	}
	return $lon
}
set n0 [$ns node]; $n0 set-position $alt $inc [compute_lon 60 $offset] 240 1
set n1 [$ns node]; $n1 set-position $alt $inc [compute_lon -30 $offset] 300 2 
set n2 [$ns node]; $n2 set-position $alt $inc [compute_lon -120 $offset] 60 1 
set n3 [$ns node]; $n3 set-position $alt $inc [compute_lon 150 $offset] 120 2
set n4 [$ns node]; $n4 set-position $alt $inc [compute_lon -80 $offset] 5 3 
set n5 [$ns node]; $n5 set-position $alt $inc [compute_lon 10 $offset] 275 3
set n6 [$ns node]; $n6 set-position $alt $inc [compute_lon 100 $offset] 185 3
set n7 [$ns node]; $n7 set-position $alt $inc [compute_lon -170 $offset] 95 3

# By setting the next_ variable on polar sats; handoffs can be optimized

$n0 set_next $n3; $n7 set_next $n0; $n4 set_next $n7; $n1 set_next $n4
$n2 set_next $n1; $n5 set_next $n2; $n6 set_next $n5; $n3 set_next $n6
