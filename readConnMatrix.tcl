# Slurp connectivity matrix
catch {set cf [ open "connectivityMatrix4.txt" r]}
set conn_matrix_data [ read -nonewline $cf ]
close $cf

# Process connectivity matrix data
set data [split $conn_matrix_data "\n"]

set n 0
foreach line $data {
	puts "$n $line"	
	set connElem [split $line "\]\["]
	set j 0
	foreach conn $connElem {
		# puts "$j $conn"
		set nodes [split $conn " "]
		set k 0
		foreach nk $nodes {			
			# puts "$j $k $nk"
			if { [expr $j % 2] == 1 } {				
				if { $k != 0 && $k != 3 } {					
					scan $nk %d nodeNum
					incr nodeNum -1
					if { $j ==1 && $k == 1 } {
						set firstNode $nodeNum
						set prevNode $nodeNum
					} else {
						puts "$prevNode -> $nodeNum"
						set prevNode $nodeNum
					}
				}
			}
			set k [ expr $k + 1]
		}
		set j [expr $j + 1]
	}
	puts "$prevNode -> $firstNode"
	set n [expr $n+1]
}

set opt(nodes) $n       ;# number of nodes

puts "$opt(nodes) nodes"
