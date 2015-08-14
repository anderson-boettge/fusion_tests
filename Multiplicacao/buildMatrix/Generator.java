import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Random;


public class Generator {
	
	Generator(String size, String type){
		int n = Integer.parseInt(size);
		int t = Integer.parseInt(type);
		if(t==0){
		  writeFile(n,"A",0);
		  writeFile(n,"B",0);
		}else if(t==1){
		  writeFile(n,"A",1);
		  writeFile(n,"B",2);
		}
	}
	
	public static void main(String args[]){
		Generator g = new Generator(args[0],args[1]);
	}
	
	void writeFile(int size, String name, int t){
		Random rand = new Random();
		float matriz[][] = new float[size][size];
		if(t==0){
		try {
			BufferedWriter out = new BufferedWriter(new FileWriter("../matriz"+name+size+".txt"));
			out.write(""+size+" "+size+"\n");			
			for(int i=0;i<size;i++){
				for(int j=0;j<size;j++){
					matriz[i][j]=rand.nextFloat();
					out.write(matriz[i][j]+" ");
				}
				out.write("\n");
			}	
			out.close();
		} catch (IOException e) {
		}
		}else{
		  try {
		    BufferedWriter out = new BufferedWriter(new FileWriter("../"+name+size+"_"+t+".txt"));
			out.write(""+size+" "+size+"\n");			
			for(int i=0;i<size;i++){
				for(int j=0;j<size;j++){
					matriz[i][j]=t;
					out.write(matriz[i][j]+" ");
				}
				out.write("\n");
			}	
			out.close();
		   } catch (IOException e) {
		  }
		}
	}
}
