# usage: perl percentile_tex_table_row.pl <inputfile> <column> <fid> <dest> <percentile in %> <percentile in %> > file
# use column 5 for queue size
# use column 0 if the file has just one column

use Statistics::Descriptive;

$infile=$ARGV[0];
$column=$ARGV[1];
$fid=$ARGV[2];
$dest=$ARGV[3];
$p1=$ARGV[4];
$p2=$ARGV[5];

$stat=Statistics::Descriptive::Full->new();

open (DATA,"<$infile") || die "Can't open $infile $!";
while(<DATA>) {
	@x = split(' ');
	$stat->add_data($x[$column]);	
}
close DATA;
$samples = $stat->count();
if($samples > 1){
	$m=$stat->percentile($p1);
	$n=$stat->percentile($p2);
#	print STDOUT "$infile column $column percentile $p1% of $samples samples is $m\n";
#	print STDOUT "$infile column $column percentile $p2% of $samples samples is $n\n";
	print STDOUT "$fid & $dest & $m & $n \\\\\n\\hline\n";
# }else{
#	print STDOUT "$infile column $column percentiles $p1% and $p2% are $x[$column]\n";
#	print STDOUT "$fid & $dest & $x[$column] & $x[$column] \\\\\n\\hline\n";
}
exit(0);
