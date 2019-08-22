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
