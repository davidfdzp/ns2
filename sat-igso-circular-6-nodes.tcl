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
	puts "Error:  sat-igso-circular-6-nodes.tcl is a supporting script for the "
	puts "        sat-igso-circular-6-ping.tcl script-- run `sat-igso-circular-6-ping.tcl' instead"
	exit
}
set n0 [$ns node]; $n0 set-position $alt $inc 60 240 1
set n1 [$ns node]; $n1 set-position $alt $inc -30 300 2 
set n2 [$ns node]; $n2 set-position $alt $inc -120 60 1 
set n3 [$ns node]; $n3 set-position $alt $inc 150 120 2
set n4 [$ns node]; $n4 set-position $alt $inc -80 5 3 
set n5 [$ns node]; $n5 set-position $alt $inc 10 275 3

# By setting the next_ variable on polar sats; handoffs can be optimized
# Ring 1 6 3 2 5 4
$n0 set_next $n3; $n5 set_next $n0; $n2 set_next $n5; $n1 set_next $n2
$n4 set_next $n1; $n3 set_next $n4
# Other rings: 1 5 2 3 6 4
# 1 4 6 5 2 3
