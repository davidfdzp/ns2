# usage: perl tcp_throughput.pl <tracefile> <origin> <fid> > file

$infile=$ARGV[0];
$from=$ARGV[1];
$fid=$ARGV[2];

# we compute how many bytes were transmitted since TCP start detection for fid
# (acks are excluded)
$sum=0;
$clock=0;
$num_tcps=0;

open (DATA,"<$infile") || die "Can't open $infile $!";

while (<DATA>) {
	@x = split(' ');

	# column 0 is event type, column 1 is time, column 2 is from, column 3 is to , column 4 is type, column 5 is size in bytes, column 6 are flags and column 7 is fid
	if($x[0] eq '-' && $x[7]==$fid && $x[2]==$from && $x[4] eq 'tcp'){	 # acks are excluded
		$clock = $x[1];		
		if($x[5]<64){ # whatever TCP options, size of ACKs is lower than 64 bytes
			if($num_tcps>0){
				$duration = $clock - $start;
				if($duration>0){
					$throughput=$sum/($clock - $start);
					print STDOUT "TCP $num_tcps of CoS $fid from node $from, starting at t=$start s and ending at t=$clock s, had a throughput of $throughput bit/s.\n\n";
				}
			}
			$start=$clock;
			$num_tcps = $num_tcps + 1;
			$sum=0;
		}else{		
			$sum=$sum+$x[5]*8;				
		}
	}
}
$duration = $clock - $start;
if($duration>0){
	$throughput=$sum/($clock - $start);
	print STDOUT "TCP $num_tcps of CoS $fid, starting at t=$start s and ending at t=$clock s, had a throughput of $throughput bit/s.\n\n";
}

close DATA;

exit(0);

