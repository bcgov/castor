package forest_hierarchy;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Collections;
import java.util.Iterator;

public class Forest_Hierarchy {
	private static final int EMPTY = -1;
	static ArrayList<Edges> edgeList = new ArrayList<Edges>(); //a minnimum spanning tree solved from igraph in R
	static ArrayList<Integer> blockList = new ArrayList<Integer>();
	static int imageSize;
	static histogram hist = new histogram();
	static Integer[] degree;
	static List<Integer> degreeList; // the degree of a vertex of a graph is the number of edges incident to the vertex, with loops counted twice
	
	public Forest_Hierarchy() {	
	}
	
	public static void main(String[] args) {
		// TODO Running from the main need a int[] method for running this?
		if(args.length < 1){
			createData();
			degree = create_degree();
			imageSize = edgeList.size() + 1;
			edgeList.sort((o1, o2) -> Double.compare(o1.getWeight(), o2.getWeight()));
			blockEdges();
		} else{
			
		}	
	}

	private static void blockEdges() {
		
		int[] pixelBlock = new int[(int)(edgeList.size() + 1)];
		Arrays.fill(pixelBlock, EMPTY);
		
		int blockID = 0, blockSize = 0, seed = 0, seedNew =0, d = 1;
		int nTarget =  hist.bins.get(hist.getLastBin()-1).n;
		double maxTargetSize = hist.bins.get(hist.getLastBin()-1).max_block_size;
		boolean findBlocks=	!hist.bins.isEmpty(); //if there is a histogram with bins then findBlocks
		degreeList = Arrays.asList(degree);
		
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
				if(seedNew >= 0){
					if(seedNew == 0) {
						blockList.add(seed + 1);
						System.out.println("block list: " + (seed + 1));
					}else {
						blockList.add(seedNew + 1);
						System.out.println("block list: " + (seedNew + 1));
						seedNew =0;
					}
					blockSize ++;
				}else{
					blockSize = (int) maxTargetSize;
					seedNew = 0;
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
			 
			if(nTarget == 0){
				hist.setLastBin();//Remove the last bin
				maxTargetSize = hist.bins.get(hist.getLastBin()-1).max_block_size;
				nTarget =  hist.bins.get(hist.getLastBin()-1).n;
			}
			
			if(edgeList.size() == 0 || hist.bins.isEmpty()) findBlocks = false; //Exit the while loop
		
		}//End of the while loop

		for (int r = 0; r < pixelBlock.length ; r++){ //assign the remaining blocks their own blockID
			if(pixelBlock[r]==(EMPTY)){
				blockID++;
				pixelBlock[r] = blockID ;
			}
			System.out.println("The clustering of " + (r+1) + ": " + pixelBlock[r]);
		}
		
	}
	
	private static int findPixelToAdd(int seed) {
	int nextPixel = -1;
		for(Edges edge : edgeList){ //find the next pixel from a seed
			if (edge.to == (seed +1)|| edge.from == (seed+1)) {
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
	
	public  void add_mst(ArrayList<LinkedHashMap<String, Object>> dfList) {
		//Instantiate the Stands objects from the R data.frame
		for(int i =0;  i < dfList.size(); i++){
			 Object[] row = dfList.get(i).values().toArray();
			 Edges ed= new Edges((int)row[1], (int)row[2], (double)row[0]);
			 edgeList.add(ed);
		}
	}
	
	public  void add_hist() {
		//TODO add histogram information from R?
		
	}
	
	  /**
     * Creates generic data to test the blocking algorithum
     */
	private static void createData() {
		edgeList.add(new Edges(14,19,0.004068539));
		edgeList.add(new Edges(15,20,0.007603801));
		edgeList.add(new Edges(8,13,0.026225054));
		edgeList.add(new Edges(11,12,0.029417822));
		edgeList.add(new Edges(13,17,0.030595662));
		edgeList.add(new Edges(8,9,0.031683749));
		edgeList.add(new Edges(6,7,0.046285584));
		edgeList.add(new Edges(3,9,0.056260681));
		edgeList.add(new Edges(17,23,0.065944742));
		edgeList.add(new Edges(1,2,0.106615236));
		edgeList.add(new Edges(19,25,0.112814511));
		edgeList.add(new Edges(5,10,0.139895661));
		edgeList.add(new Edges(9,15,0.140727376));
		edgeList.add(new Edges(24,25,0.141665573));
		edgeList.add(new Edges(2,3,0.200729464));
		edgeList.add(new Edges(17,21,0.217086723));
		edgeList.add(new Edges(16,17,0.219919266));
		edgeList.add(new Edges(9,14,0.245010326));
		edgeList.add(new Edges(4,8,0.247409998));
		edgeList.add(new Edges(7,13,0.257652422));
		edgeList.add(new Edges(17,18,0.274287587));
		edgeList.add(new Edges(16,22,0.285556721));
		edgeList.add(new Edges(11,16,0.291724667));
		edgeList.add(new Edges(10,14,0.322317448));
	}
	  /**
     * Creates generic data to test the blocking algorithum
     */
	public static  Integer[]  create_degree() {
		Integer[] degree = new Integer[25];
		degree[0] = 1;degree[1] = 2;degree[2] = 2;degree[3] = 1;degree[4] = 1;
		degree[5] = 1;degree[6] = 2;degree[7] = 3;degree[8] = 4;degree[9] = 2;
		degree[10] = 2;degree[11] = 1;degree[12] = 3;degree[13] = 3;degree[14] = 2;
		degree[15] = 3;degree[16] = 5;degree[17] = 1;degree[18] = 2;degree[19] = 1;
		degree[20] = 1;degree[21] = 1;degree[22] = 1;degree[23] = 1;degree[24] = 2;
		return degree;
	}
    /**
     * Private class for tracking Edges of a Minnimum Spanning Tree.
     */
	private static class Edges implements java.io.Serializable {
		int to, from, block =0;
		double weight;
		private static final long serialVersionUID = 10L;
		
		public Edges(int to, int from, double weight){
			this.to = to;
			this.from = from;
			this.weight = weight;
			this.block =0;
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
        	areaBin ab  = new areaBin();
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
    

}
