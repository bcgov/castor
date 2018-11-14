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
	int[] blockPixels ;
	histogram hist;
	Integer[] degree;
	private static final int EMPTY = -1;
	
	public Forest_Hierarchy() {

	}
	
	public static void main(String[] arg) {
		  if (arg.length != 3) {
	            System.err.println("Usage: java forest_hierarchy <Edges> <degree> <histogram>");
	            //System.out.println("Creating a test run...");
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }else{
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }
	}

	public void blockEdges() {
		int[] pixelBlock = new int[(int)(this.edgeList.size() + 1)];
		Arrays.fill(pixelBlock, EMPTY);		
		int blockID = 0, blockSize = 0, seed = 0, seedNew = -1, d = 0;
		int nTarget =  this.hist.bins.get(this.hist.getLastBin()-1).n;
		double maxTargetSize = this.hist.bins.get(this.hist.getLastBin()-1).max_block_size;
		boolean findBlocks=	!this.hist.bins.isEmpty(); //if there is a histogram with bins then findBlocks
		this.degreeList = Arrays.asList(this.degree);	
		this.edgeList.sort((o1, o2) -> Double.compare(o1.getWeight(), o2.getWeight()));		
		//as long as the distribution of block sizes has not been met or there are edges to include, cluster pixels into blocks
		while(findBlocks){
			//System.out.println("edgeList: " + this.edgeList.size());
			//System.out.println("nTarget: " + nTarget);	
			//System.out.println("maxTargetSize" + this.hist.bins.get(this.hist.getLastBin()-1).max_block_size);	
			if(blockSize == 0){
				seed = this.degreeList.indexOf(Collections.max(this.degreeList)); // get the largest degree 
				//degreeList.set(seed, (degreeList.get(seed).intValue() - 1)); //assign a zero degree to the pixel
				//System.out.println("pixel with the greatest degree:" + (seed + 1));
			}else{
				if(this.degreeList.get(seed) > 0) { //if there are still edges from the seed to spawn
					//System.out.println("the pixel in the last blocklist: " + blockList.get(blockList.size()-d-1).intValue());
					seedNew = findPixelToAdd(seed); //get the lowest weighted edge. Note the first edge to be added will have the lowest weight because it is sorted 
				} else{
					//Need a loop here to find branches off the main
					d++; //counts the number of edges being connected. 
					int counter = 0;
					for(int b = d; b < blockList.size() ; b++){
						//System.out.println("blockList.size: " + this.blockList.size() + " d: " + d + " b: " + b);
						seed = this.blockList.get(b).intValue() -1;
						if(this.degreeList.get(seed) > 0) {
							seedNew = findPixelToAdd(seed);
							if(seedNew > 0) break;
						} else  counter++;
					}
					d = d + counter;
				}
			}
			if(blockSize < maxTargetSize && nTarget > 0){
				//System.out.println("degree:" + degreeList.get(seed).intValue() );
				if(seedNew >= -1){
					if(seedNew == -1) {
						this.blockList.add(seed + 1);
						//System.out.println("block list: " + (seed + 1));
					}else {
						this.blockList.add(seedNew + 1);
						//System.out.println("block list: " + (seedNew + 1));
						seedNew = -1;
					}
					blockSize ++;
				}else{
					blockSize = (int) maxTargetSize;
					seedNew = -1;
				}
			}	
			
			if((blockSize >= maxTargetSize && nTarget > 0 )|| this.edgeList.size() == 0 ){ //Found all the pixels needed to make the target block
				blockID ++; //assign a blockID to the temp list of vertices
				//System.out.println("block ID" + blockID);
				Iterator<Integer> itr = this.blockList.iterator(); 
		        while (itr.hasNext()) { 
		            int x = (Integer)itr.next(); 
		            pixelBlock[x-1] = blockID;
		            removeEdges(x); //remove all remaining edges in the edgeList. So that each block has a unique set of pixels
		            //System.out.println("pixel: " + x + " is assigned block: " + pixelBlock[x-1]);
		                itr.remove(); 
		        } 
		        this.blockList.clear();
		        this.hist.setBinTargetNumber();//reduce the n in the bin by one
				nTarget =  this.hist.bins.get(this.hist.getLastBin()-1).n;
				blockSize = 0; //reset the new blockSize to zero
				d = 0;
				//System.out.println("left: " + nTarget);
			}	
			
			if(nTarget == 0 ){
				this.hist.setLastBin();//Remove the last bin
				if(!(this.hist.bins.isEmpty())){
					maxTargetSize = this.hist.bins.get(this.hist.getLastBin()-1).max_block_size;
					nTarget =  this.hist.bins.get(this.hist.getLastBin()-1).n;
				}
			}
			
			if(this.edgeList.size() == 0 || this.hist.bins.isEmpty()) findBlocks = false; //Exit the while loop
		}//End of the while loop
		for (int r = 0; r < pixelBlock.length ; r++){ //assign the remaining blocks their own blockID
			if(pixelBlock[r]==(EMPTY)){
				blockID++;
				pixelBlock[r] = blockID ;
			}
			//System.out.println("The clustering of " + (r+1) + ": " + pixelBlock[r]);
		}
		setBlockPixels(pixelBlock);
		//little garbage collection?
		d=0;
		pixelBlock = null;
		this.blockList.clear();
		this.edgeList.clear();
		//degreeList.clear();
	}
	


	private  int findPixelToAdd(int seed) {
	int nextPixel = -1;
		for(Edges edge : this.edgeList){ //find the next pixel from a seed
			if (edge.to == (seed +1) || edge.from == (seed+1)) {
				if(edge.to == (seed+1)) nextPixel = edge.from; //get the 'from' pixel because the seed is the 'to'
				if(edge.from == (seed+1)) nextPixel = edge.to; //get the 'to' pixel because the seed is the 'from'
				this.edgeList.remove(edge);
				break; //a match has been found so break out of the loop of the edges
			}
		}
		if(nextPixel > 0){ //remove degrees from each of the pixels
			//System.out.println("seed:" + seed + " nextpixel: " + nextPixel);
			this.degreeList.set(seed, (this.degreeList.get(seed).intValue() - 1)); //assign a zero degree to the pixel
			this.degreeList.set((nextPixel -1), (this.degreeList.get((nextPixel-1)).intValue() - 1)); //assign a zero degree to the pixel
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
	
	public void setRParms(int[] to, int[] from, double[] weight, int[] dg, ArrayList<LinkedHashMap<String, Object>> histTable ) {
		//Instantiate the Edge objects from the R data.table
		for(int i =0;  i < to.length; i++){
			 this.edgeList.add( new Edges((int)to[i], (int)from[i], (double)weight[i]));
		}
		System.out.println(to.length + " edges have been added");
		

		this.degree = Arrays.stream(dg).boxed().toArray( Integer[]::new );
		System.out.println(degree.length + " pixel degrees have been added");
		
		this.hist = new histogram(histTable);
		System.out.println(this.hist.bins.size() + " target bins have been added");
		
		dg = null;
		histTable.clear();
		to = null;
		from =null;
		weight = null;
	}


	  /**
     * Creates generic data to test the blocking algorithum
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
			ArrayList<LinkedHashMap<String, Object>> histTable = new ArrayList<LinkedHashMap<String, Object>>();
			this.hist = new histogram(histTable);
			blockEdges();
	}
	

	  /**
     * Creates generic data to test the blocking algorithum
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
     * Private class for tracking Edges of a Minnimum Spanning Tree.
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
     * Private class for tracking bins wihtin a histgoram of block size
     */
    private class histogram {
		private int lastBin;
		
        class areaBin {
            double max_block_size;
            int n;
        }

        private final ArrayList<areaBin> bins = new ArrayList<areaBin>();
        
        public histogram(ArrayList<LinkedHashMap<String, Object>> histTable) {
        	// TODO  need a way to make this discrete --issues with rounding up and down?
            if(histTable.isEmpty()){
                areaBin bin0  = new areaBin();
                bin0.max_block_size = 10; //changed this from 5, needed a large block that is more than the degrees
                bin0.n = 2;
                this.bins.add(bin0);
                
                areaBin bin  = new areaBin();
                bin.max_block_size = 20; //changed this from 5, needed a large block that is more than the degrees
                bin.n = 1;
                this.bins.add(bin);
            }else{
        		for(int i =0;  i < histTable.size(); i++){
	       			 Object[] row = histTable.get(i).values().toArray();
	       			 areaBin bin  = new areaBin();
	                 bin.max_block_size = (double)row[0]; //changed this from 5, needed a large block that is more than the degrees
	                 bin.n = (int)row[1];
	                 
	                 //System.out.println("size: " + bin.max_block_size + " n: " + bin.n);
	                 this.bins.add(bin);
        		}
       		}
         }
        
        public void setBinTargetNumber() {
        	this.bins.get(this.lastBin-1).n --;
		}

		public void setLastBin(){
			if(this.bins.get(this.lastBin-1).n == 0){
				this.bins.remove(this.lastBin-1);
			    this.lastBin = this.bins.size();
			}   
        }
        
        public int getLastBin(){
        	this.lastBin = this.bins.size() ;
        	return this.lastBin;
        }
    }
    
	public double getEdgeListWeight(int i){
		return this.edgeList.get(i).weight;
		
	}
	
	private void setBlockPixels(int[] pixelBlock) {
		this.blockPixels = null;
		this.blockPixels = pixelBlock;
	}
	
	public int[] getBlocks(){
		return this.blockPixels;
	}
}
