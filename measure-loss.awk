# This program is used to calculate the packet loss rate for a given flow id between two nodes
# usage: gawk -v fid=<flow_id> -v orig=<from> -v dest=<to> -f measure-loss.awk out.tr

BEGIN{
# Initialization. Set two variables. fsDrops: packets drop. numFS: packets sent
	fsDrops=0;
	numFs=0;	
	numFsBytes=0;
	numFsNet=0;
	numFsNetBytes=0;
	startFs=-1;
	endFs=-1;
	startFsNet=-1;
	endFsNet=-1;
}
{
	action=$1;
	time=$2;
	from=$3;
	to=$4;
	type=$5;
	pktsize=$6;
	flow_id=$8;
	src=$9;
	dst=$10;
	seq_no=$11;
	packet_id=$12;
	
	if(flow_id==fid && from==orig && to==dest && action=="+"){
		numFs++;
		numFsBytes+=pktsize;
		if(startFs==-1) startFs = time;
		endFs = time;
		if(type!="ack"){
			numFsNet++;
			numFsNetBytes+=pktsize;
			if(startFsNet==-1) startFsNet = time;
			endFsNet = time;
		}
	}
		
	if(flow_id==fid && from==orig && to==dest && (action=="d" || action=="e")){
		if(startFs==-1) startFs = time;
		fsDrops++;
		endFs = time;
		if(type!="ack"){
			if(startFsNet==-1) startFsNet = time;
			endFsNet = time;
		}
	}
}
END{
	if(numFs){
#		printf("Flow ID %d from %d to %d.\nNumber of packets sent: %d (%d bytes), lost: %d (PLR %.3f), duration %.6f s, %.f packets/s, %.f bits/s.\nUser data packets sent: %d (%d bytes), duration %.6f s, %.f packets/s, %.f bits/s.\n", fid, orig, dest, numFs, numFsBytes, fsDrops, (1.0*fsDrops)/numFs, endFs-startFs, endFs==startFs? 0 : numFs/(endFs-startFs), endFs==startFs? 0 : (numFsBytes*8)/(endFs-startFs), numFsNet, numFsNetBytes, endFsNet-startFsNet, endFsNet==startFsNet? 0 : numFsNet/(endFsNet-startFsNet), endFsNet==startFsNet? 0 : (numFsNetBytes*8)/(endFsNet-startFsNet));
		plr = (1.0*fsDrops)/numFs;
		if(plr < 0.001){
			printf("%d & %d & %d & %d & %d & %d & %.3f \\\\\n\\hline\n", fid, orig, dest, numFs, numFsBytes, fsDrops, plr);
		}else{
			printf("%d & %d & %d & %d & %d & %d & \\textcolor{red}{%.3f} \\\\\n\\hline\n", fid, orig, dest, numFs, numFsBytes, fsDrops, plr);
		}
	}
}
