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
	puts "Error:  sat-galileo-nodes.tcl is a supporting script for the "
	puts "        sat-galileo.tcl script-- run `sat-galileo.tcl' instead"
	exit
}

set plane 1
set n0 [$ns node]; $n0 set-position $alt $inc 0 1.464 $plane
set n1 [$ns node]; $n1 set-position $alt $inc 0 46.464 $plane 
set n2 [$ns node]; $n2 set-position $alt $inc 0 68.964 $plane 
set n3 [$ns node]; $n3 set-position $alt $inc 0 91.464 $plane 
set n4 [$ns node]; $n4 set-position $alt $inc 0 136.464 $plane 
set n5 [$ns node]; $n5 set-position $alt $inc 0 181.464 $plane
set n6 [$ns node]; $n6 set-position $alt $inc 0 226.464 $plane 
set n7 [$ns node]; $n7 set-position $alt $inc 0 248.964 $plane 
set n8 [$ns node]; $n8 set-position $alt $inc 0 271.464 $plane 
set n9 [$ns node]; $n9 set-position $alt $inc 0 316.464 $plane 

incr plane  
set n15 [$ns node]; $n15 set-position $alt $inc 120 16.464 $plane 
set n16 [$ns node]; $n16 set-position $alt $inc 120 61.464 $plane 
set n17 [$ns node]; $n17 set-position $alt $inc 120 106.464 $plane 
set n18 [$ns node]; $n18 set-position $alt $inc 120 128.964 $plane 
set n19 [$ns node]; $n19 set-position $alt $inc 120 151.464 $plane 
set n20 [$ns node]; $n20 set-position $alt $inc 120 196.464 $plane 
set n21 [$ns node]; $n21 set-position $alt $inc 120 241.464 $plane 
set n22 [$ns node]; $n22 set-position $alt $inc 120 286.464 $plane 
set n23 [$ns node]; $n23 set-position $alt $inc 120 308.964 $plane 
set n24 [$ns node]; $n24 set-position $alt $inc 120 331.464 $plane 

incr plane 
set n30 [$ns node]; $n30 set-position $alt $inc -120 346.464 $plane 
set n31 [$ns node]; $n31 set-position $alt $inc -120 8.964 $plane 
set n32 [$ns node]; $n32 set-position $alt $inc -120 31.464 $plane 
set n33 [$ns node]; $n33 set-position $alt $inc -120 76.464 $plane 
set n34 [$ns node]; $n34 set-position $alt $inc -120 121.464 $plane 
set n35 [$ns node]; $n35 set-position $alt $inc -120 166.464 $plane 
set n36 [$ns node]; $n36 set-position $alt $inc -120 188.964 $plane 
set n37 [$ns node]; $n37 set-position $alt $inc -120 211.464 $plane 
set n38 [$ns node]; $n38 set-position $alt $inc -120 256.464 $plane 
set n39 [$ns node]; $n39 set-position $alt $inc -120 301.464 $plane 

# By setting the next_ variable on polar sats; handoffs can be optimized

$n0 set_next $n9; $n1 set_next $n0; $n2 set_next $n1; $n3 set_next $n2
$n4 set_next $n3; $n5 set_next $n4; $n6 set_next $n5; $n7 set_next $n6
$n8 set_next $n7; $n9 set_next $n8;

$n15 set_next $n24; $n16 set_next $n15; $n17 set_next $n16; $n18 set_next $n17
$n19 set_next $n18; $n20 set_next $n19; $n21 set_next $n20; $n22 set_next $n21
$n23 set_next $n22; $n24 set_next $n23;

$n30 set_next $n39; $n31 set_next $n30; $n32 set_next $n31; $n33 set_next $n32
$n34 set_next $n33; $n35 set_next $n34; $n36 set_next $n35; $n37 set_next $n36
$n38 set_next $n37; $n39 set_next $n38;

