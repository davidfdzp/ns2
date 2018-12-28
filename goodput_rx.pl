# usage: perl goodput_rx.pl <tracefile> <granularity> <dest> <fid> > file

$infile=$ARGV[0];
$granularity=$ARGV[1];
$to=$ARGV[2];
$fid=$ARGV[3];

# we compute how many bytes were transmitted during time interval specified
# by granularity parameter in seconds
$sum=0;
$clock=0;

open (DATA,"<$infile") || die "Can't open $infile $!";

while (<DATA>) {
	@x = split(' ');

	if($x[7]==$fid && $x[3]==$to){
		# checking if the event corresponds to a reception
		# column 0 is event type
		if ($x[0] eq 'r'){
			if($x[4] eq 'ack'){
				# do nothing
			}else{
				$sum=$sum+$x[5]*8;
			}
		}
		# column 1 is time and column 3 is to
		if ($x[1]-$clock > $granularity){
			$throughput=$sum/$granularity;
			print STDOUT "$x[1] $throughput\n";
			$clock=$clock+$granularity;
			$sum=0;
		}
	}
}
# $throughput=$sum/$granularity;
# print STDOUT "$x[1] $throughput\n";
# $clock=$clock+$granularity;
# $sum=0;

close DATA;

exit(0);
