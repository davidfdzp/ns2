# usage: perl throughput_tx.pl <tracefile> <granularity> <origin> <fid> > file

$infile=$ARGV[0];
$granularity=$ARGV[1];
$from=$ARGV[2];
$fid=$ARGV[3];

# we compute how many bytes were transmitted during time interval specified
# by granularity parameter in seconds (acks are excluded)
$sum=0;
$clock=0;

open (DATA,"<$infile") || die "Can't open $infile $!";

while (<DATA>) {
	@x = split(' ');

	# column 0 is event type, column 1 is time, column 2 is from, column 3 is to , column 4 is type, column 5 is size in bytes, column 6 are flags and column 7 is fid
	if($x[7]==$fid && $x[2]==$from){
		if ($x[1]-$clock <= $granularity){
			# checking if the event corresponds to a departure			
			if ($x[0] eq '-'){
				$sum=$sum+$x[5]*8;				
			}
		}else{
			$throughput=$sum/$granularity;
			print STDOUT "$x[1] $throughput\n";
			$clock=$clock+$granularity;
			$sum=0;
		}
	}
}
$throughput=$sum/$granularity;
print STDOUT "$x[1] $throughput\n";
$clock=$clock+$granularity;
$sum=0;

close DATA;

exit(0);
