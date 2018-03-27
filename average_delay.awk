BEGIN { 
	FS = " "
} 
{ 
	n1++ 
} 
{ 
	s=s+$2
} 
END { 
	if(n1){
#		printf("Mean delay of QoS %d packets to node %d: %.6f s\n", fid, dest, s/n1);
		printf("%d & %d & %.6f \\\\\n\\hline\n", fid, dest, s/n1);
	}else{
		printf("%d & %d & 0.0 \\\\\n\\hline\n", fid, dest);
	}
}
