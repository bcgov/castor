package forest_hierarchy;

public class main {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		  if (args.length != 3) {
	            System.err.println("Usage: java forest_hierarchy <Edges> <degree> <histogram>");
	            System.out.println("Creating a test run...");
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        	
	        	for(int i = 0; i < f.getBlocks().length; i++){
	        		System.out.println(f.getBlocks()[i]);
	        	}
	        	
	        	
	        }else{
	        	Forest_Hierarchy f = new Forest_Hierarchy();
	        	f.createData();
	        }
	}

}
