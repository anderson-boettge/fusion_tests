
public class MultiAccel{
	int pool;
	float result[], matA[], matB[];
	int rowA, colB, nRows;
	
	MultiAccel(int nCore){
	  this.pool = nCore;
	}
	
	public void setData(float matA[], float matB[], int rowA, int colB){
	  this.matA = matA;
	  this.matB = matB;
	  this.rowA = rowA;
	  this.colB = colB;
	  this.nRows = rowA/pool;
	  setDataCall(matA, matB, rowA, colB, pool);
	}
		
	static{
	  System.loadLibrary("multi");
	}
	// 	
	public native void setDataCall(float[] matA, float[] matB, int rowA, int rowB, int pool);
	public native float[] getResult();
	
	public class Calc{
		int index;
		int initialIdx;
		int size;
		Calc(int index){
		    this.index = index;
		    this.initialIdx = nRows*colB*index;
		    this.size = nRows*colB;
		    createStream(index, matA, initialIdx, size); 
		}
		public void multiply(){
		  /*auto-generated*/
		  int bx=32, by=32, bz=1;
		  int gx=colB/32, gy=(rowA/pool)/32, gz=1;  
		  multiplyCall(matA, matB, nRows, colB, index, gx, gy, gz, bx, by, bz);
		}
		
		/*generated for call multiply method on unit Calc*/
		private native void multiplyCall(float[] matA, float[] matB, int nRows,  int colB, int index, int gx,
		  int gy, int gz, int bx, int by, int bz);		
		/*default methods auto-generated*/
		public native void createStream(int index, float[] mat, int initialIdx, int size);
	}
}
