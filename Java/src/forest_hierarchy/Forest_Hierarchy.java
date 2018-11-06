package forest_hierarchy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Collections;
import java.util.Iterator;

public class Forest_Hierarchy {

	static ArrayList<Edges> edgeList = new ArrayList<Edges>(); //a minnimum spanning tree solved from igraph in R
	static ArrayList<Integer> blockList = new ArrayList<Integer>();
	static List<Integer> degreeList; // the degree of a vertex of a graph is the number of edges incident to the vertex, with loops counted twice
	static int[] blockPixels ;
	static histogram hist;
	static Integer[] degree;
	private static final int EMPTY = -1;
	
	
	public Forest_Hierarchy() {		
	}
	
	public static void main(String[] arg) {
		// TODO Running from the main need a int[] method for running this?
		  if (arg.length != 3) {
	            System.err.println("Usage: java forest_hierarchy <Edges> <degree> <histogram>");
	            System.out.println("Creating a test run...");
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }else{
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }
	}

	public static void blockEdges() {
		int[] pixelBlock = new int[(int)(edgeList.size() + 1)];
		Arrays.fill(pixelBlock, EMPTY);
		
		int blockID = 0, blockSize = 0, seed = 0, seedNew = -1, d = 1;
		int nTarget =  hist.bins.get(hist.getLastBin()-1).n;
		double maxTargetSize = hist.bins.get(hist.getLastBin()-1).max_block_size;
		boolean findBlocks=	!hist.bins.isEmpty(); //if there is a histogram with bins then findBlocks
		degreeList = Arrays.asList(degree);
		
		edgeList.sort((o1, o2) -> Double.compare(o1.getWeight(), o2.getWeight()));
		
		//as long as the distribution of block sizes has not been met or there are edges to include, cluster pixels into blocks
		while(findBlocks){
			System.out.println("maxTargetSize: " + maxTargetSize);
			System.out.println("nTarget: " + nTarget);;
			
			if(blockSize == 0){
				seed = degreeList.indexOf(Collections.max(degreeList)); // get the largest degree 
				//degreeList.set(seed, (degreeList.get(seed).intValue() - 1)); //assign a zero degree to the pixel
				System.out.println("pixel with the greatest degree:" + (seed + 1));
			}else{
				if(degreeList.get(seed) > 0) { //if there are still edges from the seed to spawn
					System.out.println("the pixel in the last blocklist: " + blockList.get(blockList.size()-d).intValue());
					seedNew = findPixelToAdd(seed); //get the lowest weighted edge
					d++; //counts the number of edges being connected. Note the first edge to be added will have the lowest weight because it is sorted
				} else{
					//Need a loop here to find branches off the main
					for(int b = 0; b < blockList.size()-1; b++){
						seed = (blockList.get((blockList.size() - (d- 1- b))).intValue() -1);
						seedNew = findPixelToAdd(seed);
						if(!(seedNew < 0)){
							break;
						}
					}
				}
			}

			if(blockSize < maxTargetSize && nTarget > 0){
				System.out.println("degree:" + degreeList.get(seed).intValue() );
				if(seedNew >= -1){
					if(seedNew == -1) {
						blockList.add(seed + 1);
						System.out.println("block list: " + (seed + 1));
					}else {
						blockList.add(seedNew + 1);
						System.out.println("block list: " + (seedNew + 1));
						seedNew = -1;
					}
					blockSize ++;
				}else{
					blockSize = (int) maxTargetSize;
					seedNew = -1;
				}
			}
			
			if((blockSize == maxTargetSize && nTarget > 0 )|| edgeList.size() == 0 ){ //Found all the pixels needed to make the target block
				blockID ++; //assign a blockID to the temp list of vertices
				//System.out.println("block ID" + blockID);
				Iterator<Integer> itr = blockList.iterator(); 
		        while (itr.hasNext()) { 
		            int x = (Integer)itr.next(); 
		            pixelBlock[x-1] = blockID;
		            removeEdges(x); //remove all remaining edges in the edgeList. So that each block has a unique set of pixels
		            System.out.println("pixel: " + x + " is assigned block: " + pixelBlock[x-1]);
		                itr.remove(); 
		        } 
		       
				hist.setBinTargetNumber();//reduce the n in the bin by one
				nTarget =  hist.bins.get(hist.getLastBin()-1).n;
				blockSize = 0; //reset the new blockSize to zero
				d = 1;
			}
			 
			if(nTarget == 0 ){
				hist.setLastBin();//Remove the last bin
				if(!(hist.bins.isEmpty())){
					maxTargetSize = hist.bins.get(hist.getLastBin()-1).max_block_size;
					nTarget =  hist.bins.get(hist.getLastBin()-1).n;
				}
			}
			
			if(edgeList.size() == 0 || hist.bins.isEmpty()) findBlocks = false; //Exit the while loop
		
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
		pixelBlock = null;
		blockList.clear();
		edgeList.clear();
		
	}
	


	private static int findPixelToAdd(int seed) {
	int nextPixel = -1;
		for(Edges edge : edgeList){ //find the next pixel from a seed
			if (edge.to == (seed +1) || edge.from == (seed+1)) {
				if(edge.to == (seed+1)) nextPixel = edge.from; //get the 'from' pixel because the seed is the 'to'
				if(edge.from == (seed+1)) nextPixel = edge.to; //get the 'to' pixel because the seed is the 'from'
				edgeList.remove(edge);
				break; //a match has been found so break out of the loop of the edges
			}
		}
		if(nextPixel > 0){ //remove degrees from each of the pixels
			degreeList.set(seed, (degreeList.get(seed).intValue() - 1)); //assign a zero degree to the pixel
			degreeList.set((nextPixel -1), (degreeList.get((nextPixel-1)).intValue() - 1)); //assign a zero degree to the pixel
		}
	return (nextPixel - 1);
	}

	private static void removeEdges(int x) {
		if(degreeList.get(x-1) > 0){
			List<Edges> deleteEdges = new ArrayList<Edges>();
			for(Edges edge : edgeList){ //find the next pixel from a seed
				if (edge.to == x) {
					deleteEdges.add(edge);
					degreeList.set(x-1, (degreeList.get(x-1).intValue() - 1));
					degreeList.set((edge.from -1), (degreeList.get(edge.from-1).intValue() - 1));
				}
				if (edge.from == x) {
					deleteEdges.add(edge);
					degreeList.set(x-1, (degreeList.get(x-1).intValue() - 1));
					degreeList.set((edge.to -1), (degreeList.get((edge.to -1)).intValue() - 1));
				}
			}
			edgeList.removeAll(deleteEdges);
		}
	}
	
	public void setRParms(ArrayList<LinkedHashMap<String, Object>> dfList, int[] dg) {
		//Instantiate the Edge objects from the R data.table
		for(int i =0;  i < dfList.size(); i++){
			 Object[] row = dfList.get(i).values().toArray();
			 edgeList.add( new Edges((int)row[0], (int)row[1], (double)row[2]));
		}
		System.out.println(dfList.size() + " edges have been added");
		

		degree=Arrays.stream(dg).boxed().toArray( Integer[]::new );
		System.out.println(degree.length + " pixel degrees have been added");
		
		hist = new histogram();
		
	}
	
	
	public  void setHist() {
		//TODO add histogram information from R?
		
	}

	  /**
     * Creates generic data to test the blocking algorithum
     */
	public void createData() {
			System.out.println("making up the data");
			edgeList.add(new Edges(1,7,0.086715709));
			edgeList.add(new Edges(2,8,0.180796037));
			edgeList.add(new Edges(3,4,0.308244033));
			edgeList.add(new Edges(3,7,0.012837183));
			edgeList.add(new Edges(5,9,0.1766306));
			edgeList.add(new Edges(6,7,0.295186504));
			edgeList.add(new Edges(7,11,0.122610174));
			edgeList.add(new Edges(8,9,0.063785272));
			edgeList.add(new Edges(8,13,0.10074124));
			edgeList.add(new Edges(9,10,0.183048232));
			edgeList.add(new Edges(9,14,0.278541127));
			edgeList.add(new Edges(11,12,0.043365683));
			edgeList.add(new Edges(11,16,0.091373383));
			edgeList.add(new Edges(12,17,0.147566343));
			edgeList.add(new Edges(13,18,0.091251474));
			edgeList.add(new Edges(14,15,0.050895983));
			edgeList.add(new Edges(17,21,0.129981886));
			edgeList.add(new Edges(18,19,0.004794077));
			edgeList.add(new Edges(18,22,0.022060849));
			edgeList.add(new Edges(19,20,0.085095334));
			edgeList.add(new Edges(20,24,0.408227721));
			edgeList.add(new Edges(21,22,0.147379324));
			edgeList.add(new Edges(23,24,0.230504445));
			edgeList.add(new Edges(24,25,0.182275042));

			degree = create_degree();
			hist = new histogram();
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
	private static class Edges implements java.io.Serializable {
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
    private static class histogram {
		private static int lastBin;
		
        class areaBin {
            double max_block_size;
            double freq;
            int n = 0;
        }

        private final ArrayList<areaBin> bins = new ArrayList<areaBin>();
        
        public histogram() {
        	// TODO  need a way to make this discrete --issues with rounding up and down?
/**/        areaBin ab  = new areaBin();
            ab.max_block_size = 2;
            ab.freq = 0.4;
            ab.n = 3;
            bins.add(ab);
            
            areaBin ab1  = new areaBin();
            ab1.max_block_size = 3;
            ab1.freq = 0.28;
            ab1.n = 2;
            bins.add(ab1); 
            
            areaBin ab11  = new areaBin();
            ab11.max_block_size = 4;
            ab11.freq = 0.2;
            ab11.n = 2;
            bins.add(ab11); 
            
            areaBin ab111  = new areaBin();
            ab111.max_block_size = 5; //changed this from 5, needed a large block that is more than the degrees
            ab111.freq = 0.11;
            ab111.n = 1;
            bins.add(ab111);
         }
        
        public void setBinTargetNumber() {
        	bins.get(lastBin-1).n --;
		}

		public void setLastBin(){
			if(bins.get(lastBin-1).n == 0){
				bins.remove(lastBin-1);
			    lastBin = bins.size();
			}   
        }
        
        public int getLastBin(){
        	lastBin = bins.size() ;
        	return lastBin;
        }
    }
    
	public double getEdgeListWeight(int i){
		return Forest_Hierarchy.edgeList.get(i).weight;
		
	}
	
	private static void setBlockPixels(int[] pixelBlock) {
		blockPixels = null;
		blockPixels = pixelBlock;
	}
	
	public int[] getBlocks(){
		return blockPixels;
	}
}
