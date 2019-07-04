package forest_hierarchy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Collections;
import java.util.Iterator;

public class Forest_Hierarchy {

	ArrayList<Edges> edgeList = new ArrayList<Edges>(); //a minnimum spanning tree solved from igraph in R
	ArrayList<Integer> blockList = new ArrayList<Integer>();
	List<Integer> degreeList; // the degree of a vertex of a graph is the number of edges incident to the vertex, with loops counted twice
	Integer[] blockPixels ;
	histogram hist;
	Integer[] degree;
	Integer[] idegree;
	int blockID = 0;
	double cwt = 1.0, allowableDiff = 2;
	
	private static final int EMPTY = -1;
	
	public Forest_Hierarchy() {

	}
	
	public static void main(String[] arg) {
		  if (arg.length != 3) {
	            System.err.println("Usage: java forest_hierarchy <Edges> <degree> <histogram> <variation>");
	            //System.out.println("Creating a test run...");
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }else{
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }
	}

	public void blockEdges() {
		int blockSize = 0, seed = 0, seedNew = -1, d = 0;
		this.hist.setBin();
		int nTarget =  this.hist.bins.get(this.hist.getBin()-1).n;
		double maxTargetSize = this.hist.bins.get(this.hist.getBin()-1).max_block_size;
		boolean findBlocks=	!this.hist.bins.isEmpty(); //if there is a histogram with bins then findBlocks
		this.degreeList = Arrays.asList(this.degree);
		
		this.blockPixels = new Integer[this.degree.length]; 
		Arrays.fill(this.blockPixels, EMPTY);	//fill the pixelBlock array with -1
		this.edgeList.sort((o1, o2) -> Double.compare(o1.getWeight(), o2.getWeight()));	//sort the edgeList	
		
		System.out.println("Blocking...");
		while(findBlocks){//as long as the distribution of block sizes has not been met or there are edges to include, cluster pixels into blocks
			if(blockSize == 0){ //the first pixel in the block
				seed = this.degreeList.indexOf(Collections.max(this.degreeList));//get the largest degree?
				//seed = this.edgeList.get(0).to - 1;
				//System.out.println("seed: " + seed);
			}else{
				if(this.degreeList.get(seed) > 0) { //if there are still edges from the seed to spawn
					seedNew = findPixelToAdd(seed, blockSize); //get the lowest weighted edge. Note the first edge to be added will have the lowest weight because it is sorted 
				}else{
					//TODO: use a heuristic to compare which branches to choose. Compare an average weight?
					d++; //counts where the branch will occur. 
					int counter = 0;
					for(int b = d; b < blockList.size() ; b++){//loop here to find branches off the main
						seed = this.blockList.get(b).intValue() - 1;
						if(this.degreeList.get(seed) > 0) {
							seedNew = findPixelToAdd(seed, blockSize);
							if(seedNew > 0) break;
						} else  counter++;
					}
					d = d + counter;
				}
			}
			
			if(blockSize < maxTargetSize){//Haven't found all the pixels to meet the target block size
				if(seedNew >= -1){
					if(seedNew == -1) {
						//System.out.println("adding to blocklist1: " + (seed + 1));
						this.blockList.add(seed + 1);
					}else {
						//System.out.println("adding to blocklist2: " + (seedNew + 1));
						this.blockList.add(seedNew + 1);
						seedNew = -1;
					}
					blockSize ++;
					//System.out.println("blockSize: " + blockSize);
				}else{//can't find any more pixels to add
					//System.out.println("can't find any more pixels");
					//TODO: check to see what the bin this will fit in. This way there remains larger target blocks
					setPixelBlocks();
					this.hist.setBinTargetNumber(blockSize);
					if(!this.hist.bins.isEmpty()){
						nTarget = this.hist.bins.get(this.hist.getBin()-1).n;
						maxTargetSize = this.hist.bins.get(this.hist.getBin()-1).max_block_size;
					}
					blockSize = 0; //reset the new blockSize to zero
					d = 0;
					seedNew = -1;
				}
			}else{ //Found all the pixels needed to meet the target block size
				setPixelBlocks();
		        this.hist.setBinTargetNumber(blockSize);//reduce the n in the bin by one
		        if(!this.hist.bins.isEmpty()){
					nTarget =  this.hist.bins.get(this.hist.getBin()-1).n;
					maxTargetSize = this.hist.bins.get(this.hist.getBin()-1).max_block_size;
		        }
				blockSize = 0; //reset the new blockSize to zero
				d = 0;
				seedNew = -1;
			}
					
			if(this.edgeList.isEmpty() || this.hist.bins.isEmpty()){
				// This will only enter when the remaining blockList can reach the target size but there are no more edges left
				this.blockID ++; //assign a blockID to the temp list of vertices
				Iterator<Integer> itr = this.blockList.iterator(); 
		        while (itr.hasNext()) { 
		            int x = (Integer)itr.next(); 
		            this.blockPixels[x-1] = this.blockID;
		        } 
				findBlocks = false; //Exit the while loop
			}
		}//End of the while loop
		
		for (int r = 0; r < blockPixels.length ; r++){ //assign the remaining blocks their own blockID
			//System.out.println("idegree[" + r + "]:" + this.idegree[r]);
			if(this.blockPixels[r]==EMPTY && this.idegree[r] >= 0){
				this.blockID++;
				this.blockPixels[r] = this.blockID ;
			}
		}

		d=0; //clean up
		this.blockList.clear();//clean up
		this.edgeList.clear();//clean up
	}


	private void setPixelBlocks() {
		this.blockID ++;
		Iterator<Integer> itr = this.blockList.iterator();   
        while (itr.hasNext()) { 
            int x = (Integer)itr.next();
            this.blockPixels[x-1] = this.blockID;
            removeEdges(x); //remove all remaining edges in the edgeList. So that each block has a unique set of pixels
            itr.remove(); 
        } 
        
        this.blockList.clear();
		
	}

	private  int findPixelToAdd(int seed, int blocksize) {
	//double wt = 0.0;
	int nextPixel = -1;
		for(Edges edge : this.edgeList){ //find the next pixel from a seed
			if (edge.to == (seed + 1) || edge.from == (seed + 1)) {
				if(edge.to == (seed + 1)) nextPixel = edge.from; //get the 'from' pixel because the seed is the 'to'
				if(edge.from == (seed + 1)) nextPixel = edge.to; //get the 'to' pixel because the seed is the 'from'
				
				//if(blocksize > 1 && edge.weight  < this.allowableDiff){
					this.edgeList.remove(edge);
					break; //a match ha
				//}
				//if(blocksize <= 1){
				//	this.edgeList.remove(edge);
				//	break; //a match has been found so break out of the loop of the edges
				//}
				
			}
		}
		if(nextPixel > 0){ //remove degrees from each of the pixels
			this.degreeList.set(seed, (this.degreeList.get(seed).intValue() - 1)); //subtract a degree from the pixel
			this.degreeList.set((nextPixel -1), (this.degreeList.get((nextPixel-1)).intValue() - 1)); 
		}
	return (nextPixel - 1);
	}

	private void removeEdges(int x) {
		if(this.degreeList.get(x-1) > 0){
			List<Edges> deleteEdges = new ArrayList<Edges>();
			for(Edges edge : this.edgeList){ //find the next pixel from a seed
				if (edge.to == x) {
					deleteEdges.add(edge);
					this.degreeList.set(x-1, (this.degreeList.get(x-1).intValue() - 1));
					this.degreeList.set((edge.from -1), (this.degreeList.get(edge.from-1).intValue() - 1));
				}
				if (edge.from == x) {
					deleteEdges.add(edge);
					this.degreeList.set(x-1, (this.degreeList.get(x-1).intValue() - 1));
					this.degreeList.set((edge.to -1), (this.degreeList.get((edge.to -1)).intValue() - 1));
				}
			}
			this.edgeList.removeAll(deleteEdges);
			deleteEdges = null;
		}
	}
	
	public void setRParms(int[] to, int[] from, double[] weight, int[] dg, ArrayList<LinkedHashMap<String, Object>> histTable, double allowdiff ) {
		//Instantiate the Edge objects from the R data.table
		
		//System.out.println("Linking to java...");
		for(int i =0;  i < to.length; i++){
			 this.edgeList.add( new Edges((int)to[i], (int)from[i], (double)weight[i]));
		}
		//System.out.println(to.length + " edges ");

		this.degree = Arrays.stream(dg).boxed().toArray( Integer[]::new );
		this.idegree = Arrays.stream(dg).boxed().toArray( Integer[]::new );
		//System.out.println(degree.length + " degree ");
		
		this.hist = new histogram(histTable);
		//System.out.println(this.hist.bins.size() + " target bins have been added");
		
		dg = null;
		//histTable.clear();
		to = null;
		from =null;
		weight = null;
		
		this.allowableDiff = allowdiff;
	}


	  /**
     * Creates generic data to test the blocking algorithm
     */
	public void createData() {
			//System.out.println("making up the data");
		this.edgeList.add(new Edges(1,7,0.086715709));
		this.edgeList.add(new Edges(2,8,0.180796037));
		this.edgeList.add(new Edges(3,4,0.308244033));
		this.edgeList.add(new Edges(3,7,0.012837183));
		this.edgeList.add(new Edges(5,9,0.1766306));
		this.edgeList.add(new Edges(6,7,0.295186504));
		this.edgeList.add(new Edges(7,11,0.122610174));
		this.edgeList.add(new Edges(8,9,0.063785272));
		this.edgeList.add(new Edges(8,13,0.10074124));
		this.edgeList.add(new Edges(9,10,0.183048232));
		this.edgeList.add(new Edges(9,14,0.278541127));
		this.edgeList.add(new Edges(11,12,0.043365683));
		this.edgeList.add(new Edges(11,16,0.091373383));
		this.edgeList.add(new Edges(12,17,0.147566343));
		this.edgeList.add(new Edges(13,18,0.091251474));
		this.edgeList.add(new Edges(14,15,0.050895983));
		this.edgeList.add(new Edges(17,21,0.129981886));
		this.edgeList.add(new Edges(18,19,0.004794077));
		this.edgeList.add(new Edges(18,22,0.022060849));
		this.edgeList.add(new Edges(19,20,0.085095334));
		this.edgeList.add(new Edges(20,24,0.408227721));
		this.edgeList.add(new Edges(21,22,0.147379324));
		this.edgeList.add(new Edges(23,24,0.230504445));
		this.edgeList.add(new Edges(24,25,0.182275042));

		this.degree = create_degree();
		this.idegree = create_degree();
		ArrayList<LinkedHashMap<String, Object>> histTable = new ArrayList<LinkedHashMap<String, Object>>();
		this.hist = new histogram(histTable);
		blockEdges();
	}
	

	  /**
     * Creates generic data to test the blocking algorithm
     */
	public static  Integer[]  create_degree() {
		//System.out.println("adding degree array");
		Integer[] degree = new Integer[25];
		degree[0] = 1;degree[1] = 1;degree[2] = 2;degree[3] = 1;degree[4] = 1;
		degree[5] = 1;degree[6] = 4;degree[7] = 3;degree[8] = 4;degree[9] = 1;
		degree[10] = 3;degree[11] = 2;degree[12] = 2;degree[13] = 2;degree[14] = 1;
		degree[15] = 1;degree[16] = 2;degree[17] = 3;degree[18] = 2;degree[19] = 2;
		degree[20] = 2;degree[21] = 2;degree[22] = 1;degree[23] = 3;degree[24] = 1;

		return degree;
	}
	

	
    /**
     * Private class for tracking Edges of a Minimum Spanning Tree.
     */
	private  class Edges implements java.io.Serializable {
		int to, from;
		double weight;
		private static final long serialVersionUID = 10L;
		
		public Edges(int to, int from, double weight){
			this.to = to;
			this.from = from;
			this.weight = weight;
		}

		public double getWeight() {
			return this.weight;
		}
	}
	
    /**
     * Private class for tracking bins within a histogram of block size
     */
    private class histogram {
		private int nextBin;
		
        class areaBin {
            double max_block_size;
            int n;
        }

        private final ArrayList<areaBin> bins = new ArrayList<areaBin>();
        
        public histogram(ArrayList<LinkedHashMap<String, Object>> histTable) {
        	// TODO  need a way to make this discrete --issues with rounding up and down?
            if(histTable.isEmpty()){
                areaBin bin0  = new areaBin();
                bin0.max_block_size = 4; //changed this from 5, needed a large block that is more than the degrees
                bin0.n = 3;
                this.bins.add(bin0);
                
                areaBin bin  = new areaBin();
                bin.max_block_size = 2; //changed this from 5, needed a large block that is more than the degrees
                bin.n = 3;
                this.bins.add(bin);
            }else{
        		for(int i =0;  i < histTable.size(); i++){
	       			 Object[] row = histTable.get(i).values().toArray();
	       			 areaBin bin  = new areaBin();
	                 bin.max_block_size = (double)row[0]; //changed this from 5, needed a large block that is more than the degrees
	                 bin.n = (int)row[1];
	                 this.bins.add(bin);
        		}
       		}
         }
        
        public void setBinTargetNumber(int blockSize) {	
        	for(int j = this.bins.size()-1; j >= 0 ; j--){
        		if(j == 0){
        			this.bins.get(j).n --;
            		if(this.bins.get(j).n == 0){
            			this.bins.remove(j);
            		}
            		break;
            		
        		}else{
            		if(blockSize > this.bins.get(j-1).max_block_size && blockSize <= this.bins.get(j).max_block_size){
            			this.bins.get(j).n --;
            			if(this.bins.get(j).n == 0){
            				this.bins.remove(j);
            			}
            			break;
            		}
        		}

        	}
        	setBin();
		}

		public void setBin(){
			//TODO: pull a random integer from a uniform distribution?
			//System.out.println("the bin size:" + this.bins.size());
			//System.out.println("the random is:" + (1 + (int)(Math.random() * (this.bins.size()) )));
			//this.nextBin = (int)(Math.random() * (this.bins.size() + 1));  
			//this.nextBin = (1 + (int)(Math.random() * (this.bins.size()) ));
			this.nextBin = this.bins.size();
        }
        
        public int getBin(){
        	return this.nextBin;
        }
    }
    
	public double getEdgeListWeight(int i){
		return this.edgeList.get(i).weight;
		
	}
	
	
	public Integer[] getBlocks(){
		return this.blockPixels;
	}
	
	public void clearInfo(){
		this.edgeList.clear();
		this.blockList.clear(); 
		//this.degreeList.clear();
		this.degreeList = new ArrayList<Integer>();
		this.blockPixels = null;
		this.hist = null;
		this.degree = null;
		this.idegree = null;
	}
}
