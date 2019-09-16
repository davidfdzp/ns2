# Slurp visibility matrix file

# name: satsVisibility
# type: cell
# rows: 1
# columns: 30

# name: <cell-element>
# type: matrix
# rows: 21601
# columns: 30

set file_name "satsVisibility.mat"
set mychar #

if { [file exists $file_name] == 1} {
	catch {set vf [ open $file_name r]}
	set visibility_matrix_data [ read -nonewline $vf ]
	close $vf

	set visibility_data [split $visibility_matrix_data "\n"]

	set n 1
	set satIndex 0
	set timeslot 1
	foreach line $visibility_data {
		# This indicates a new element
		# name: <cell-element>
		# type: matrix
		# rows: 21601
		# columns: 30
		if {[string match $mychar* $line]} {
			# Check if it is a new <cell-element>
			set substring "cell-element"
			if {[string first $substring $line] != -1} {
				set satIndex [expr $satIndex+1]
				set timeslot 1
			}
		} else {
			# if not a blank line
			if { $line ne ""} {
				puts "$n $satIndex $timeslot $line"		
				if { $timeslot > 21601 } {
					puts "Error: too many timeslots!"
					exit
				}
				lappend satsVisibility($satIndex) $line
				set n [expr $n+1]
				set timeslot [expr $timeslot+1]			
			}
		}
	}
	
	set satsrc 1
	set timeslot 1
	set satdst 2
	puts [lindex [lindex $satsVisibility($satsrc) $timeslot] $satdst]
}
