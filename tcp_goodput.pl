# usage: perl tcp_goodput.pl <tracefile> <dest> <fid> > file

$infile=$ARGV[0];
$to=$ARGV[1];
$fid=$ARGV[2];

# we compute how many bytes were received ok
$sum=0;
$clock=0;
$last_clock=0;
$last_from=-1;
$num_tcps=0;

open (DATA,"<$infile") || die "Can't open $infile $!";

while (<DATA>) {
	@x = split(' ');
	# column 0 is event type, column 1 is time, column 2 is from, column 3 is to , column 4 is type, column 5 is size in bytes, column 6 are flags and column 7 is fid
	if($x[0] eq 'r' && $x[3]==$to && $x[4] eq 'tcp' && $x[7]==$fid){
		$clock = $x[1];
		$from = $x[2];
		if ($x[5]<64){
			if($num_tcps>0){
				$duration = $last_clock - $start;
				if($duration>0){
					$goodput=$sum/($last_clock - $start);
					print STDOUT "TCP $num_tcps of CoS $fid from node $last_from to node $to, starting at t=$start s and ending at t=$last_clock s, had a goodput of $goodput bit/s.\n\n";
				}
			}
			$start=$clock;		
			$num_tcps = $num_tcps + 1;
			$sum=0;
		}else{
			$sum=$sum+$x[5]*8;
		}
		$last_clock=$clock;
		$last_from=$from;
	}
}
$duration = $last_clock - $start;
if($duration>0){
	$goodput=$sum/($last_clock - $start);
	print STDOUT "TCP $num_tcps of CoS $fid from node $last_from to node $to, starting at t=$start s and ending at t=$last_clock s, had a goodput of $goodput bit/s.\n\n";
}

close DATA;

exit(0);
