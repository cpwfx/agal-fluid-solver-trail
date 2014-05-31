package animators
{
	import away3d.animators.AnimationSetBase;
	import away3d.animators.data.VertexAnimationMode;
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import flash.display3D.Context3D;
	
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * The animation data set used by vertex-based animators, containing vertex animation state data.
	 *
	 * @see away3d.animators.VertexAnimator
	 */
	public class PointCloudAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _numPoses:uint;
		private var _blendMode:String;
		private var _streamIndices:Dictionary = new Dictionary(true);
		private var _useNormals:Dictionary = new Dictionary(true);
		private var _useTangents:Dictionary = new Dictionary(true);
		private var _uploadNormals:Boolean;
		private var _uploadTangents:Boolean;
		
		public var vertexData:Vector.<Number>;
		private var vertexConstances:Vector.<Number> = new Vector.<Number>(4);
		
		public var positionData1:Vector.<Number>;
		public var positionData2:Vector.<Number>;
		public var positionData3:Vector.<Number>;
		public var positionData4:Vector.<Number>;
		
		public var byteArrayOffset:int = 0;
		public var numRegisters:int;
		
		/**
		 * Returns the number of poses made available at once to the GPU animation code.
		 */
		public function get numPoses():uint
		{
			return _numPoses;
		}
		
		/**
		 * Returns the active blend mode of the vertex animator object.
		 */
		public function get blendMode():String
		{
			return _blendMode;
		}
		
		/**
		 * Returns whether or not normal data is used in last set GPU pass of the vertex shader.
		 */
		public function get useNormals():Boolean
		{
			return _uploadNormals;
		}
		
		/**
		 * Creates a new <code>PointCloudAnimationSet</code> object.
		 *
		 * @param numPoses The number of poses made available at once to the GPU animation code.
		 * @param blendMode Optional value for setting the animation mode of the vertex animator object.
		 *
		 * @see away3d.animators.data.VertexAnimationMode
		 */
		public function PointCloudAnimationSet(numRegisters:int, numPoses:uint = 2, blendMode:String = "absolute")
		{
			super();
			
			this.numRegisters = numRegisters;
			
			_numPoses = numPoses;
			_blendMode = blendMode;
			
			vertexConstances[0] = 0.5;
			vertexConstances[1] = 100;
			vertexConstances[2] = 10;
			vertexConstances[3] = numRegisters;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>, profile:String):String
		{
			if (_blendMode == VertexAnimationMode.ABSOLUTE)
				return getAbsoluteAGALCode(pass, sourceRegisters, targetRegisters);
			else
				return getAdditiveAGALCode(pass, sourceRegisters, targetRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
			_uploadNormals = Boolean(_useNormals[pass]);
			_uploadTangents = Boolean(_useTangents[pass]);
			
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, vertexConstances, 1);
			
			if (positionData1) {
				
				trace("numRegisters = " + numRegisters);
				trace("positionData1.length = " + positionData1.length);
				
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10 + (numRegisters * 0), positionData1, numRegisters);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10 + (numRegisters * 1), positionData2, numRegisters);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10 + (numRegisters * 2), positionData3, numRegisters);
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10 + (numRegisters * 3), positionData4, numRegisters);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
			var index:int = _streamIndices[pass];
			var context:Context3D = stage3DProxy._context3D;
			context.setVertexBufferAt(index, null);
			if (_uploadNormals)
				context.setVertexBufferAt(index + 1, null);
			if (_uploadTangents)
				context.setVertexBufferAt(index + 2, null);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String
		{
			return "";
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String
		{
			return "mov " + UVTarget + "," + UVSource + "\n";
		}
		
		/**
		 * @inheritDoc
		 */
		public function doneAGALCode(pass:MaterialPassBase):void
		{
		
		}
		
		/**
		 * Generates the vertex AGAL code for absolute blending.
		 */
		private function getAbsoluteAGALCode(pass:MaterialPassBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>):String
		{
			Debug.active = true;
			
			var code:String = "// test\n";
			var len:uint = sourceRegisters.length;
			var useNormals:Boolean = Boolean(_useNormals[pass] = len > 1);
			
			
			code += "mov " + targetRegisters[0] + ", " + sourceRegisters[0] + "\n";
			
			if (useNormals) code += "mov " + targetRegisters[1] + ", " + sourceRegisters[1] + "\n";
			
			if (targetRegisters.length > 2) {
				code += "mov " + targetRegisters[2] + ", " + sourceRegisters[2] + "\n";
			}
			
			code += "frc vt6.x, vt0.z \n"; // put trail fraction in vt6.x 
			//code += "mov vt6.x, vt0.w \n"; // put trail fraction in vt6.x 
			//code += "add vt6.x, vt6.x, vc5.x \n"; // put trail fraction in vt6.x 
			//code += "sub vt6.x, vt6.x, vc10.y \n"; // put trail fraction in vt6.x 
			//0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.8, 0.9, 1.0
			
			//code += "mov v2.xyzw, vc[vt6.x].wwww \n"; // move rgb into v1
			
			
			code += "mov vt2.xyzw, vt0.zzzz \n"; // move trail index into vt2.x;
			//code += "add vt2.xyzw, vt2.xyzw, vc5.zzzz \n"; // remove trail fraction from trail index
			code += "sub vt2.xyzw, vt2.xyzw, vt6.xxxx \n"; // remove trail fraction from trail index
			// 10 - 10+numOfTrails
			
			//code += "add vt2.x, vt2.x, vc5.x \n";
			code += "add vt2.y, vt2.y, vc5.w \n";
			
			code += "add vt2.z, vt2.z, vc5.w \n";
			code += "add vt2.z, vt2.z, vc5.w \n";
			
			code += "add vt2.w, vt2.w, vc5.w \n";
			code += "add vt2.w, vt2.w, vc5.w \n";
			code += "add vt2.w, vt2.w, vc5.w \n";
			
			
			code += "mov vt0.z, vc5.z \n"; // reset z position to 0;
			
			//code += "add vt0.xy, vt0.xy, vc[vt2.x].xy \n"; // move z position back to 0
			
			//return code;
			
			//code += "add vt0.xy, vt0.xy, vc[vt2.w].xy \n"; // move point 1 in vt3
			
			code += "add vt0.xy, vt0.xy, vc[vt2.x].xy \n";
			//code += "add vt0.x, vt0.x, vc16.x \n";
			
			code += "mov vt3.xy, vc[vt2.x].xy \n";
			code += "mov vt4.xy, vc[vt2.w].xy \n";
			code += "sub vt5.xy, vt4.xy, vt3.xy \n";
			
			code += "mul vt5.xy, vt5.xy, vt6.xx \n";
			code += "add vt0.xy, vt0.xy, vt5.xy \n";
			
			
			//code += "sub vt4.x, vt3.x, vt3.z \n";
			
			//code += "mov vt3.y, vt3.y \n";
			//code += "mul vt4.x, vt4.x, vt6.x \n";
			//code += "add vt0.x, vt0.x, vt4.x \n";
			
			//code += "mov vt3.xy, vc[vt2.x].xy \n";
			//code += "mov vt3.zw, vc[vt2.x].xy \n";
			//code += "sub vt3.xy, vt3.xy, vt3.zw \n";
			
			//code += "mul vt3.xy, vt3.xy, vt6.xx \n";
			//code += "add vt0.xy, vt0.xy, vt3.xy \n";
			
			/*code += "mov vt3.xy, vc[vt2.y].xy \n"; // move point 1 in vt3
			code += "sub vt3.xy, vt3.xy, vc[vt2.x].xy \n"; // move point 1 in vt3
			code += "mul vt3.xy, vt3.xy, vt6.xx \n"; // move point 1 in vt3
			code += "add vt3.xy, vt3.xy, vc[vt2.x].xy \n"; // move point 1 in vt3
			code += "add vt0.xy, vt0.xy, vt3.xy \n";*/
			
			/*code += "mov vt3.xy, vc[vt2.x].xy \n"; // move point 1 in vt3
			code += "sub vt3.xy, vt3.xy, vc[vt2.x].xy \n"; // Place difference between point 1 and point 2 in vt3 // vc10.zz
			code += "mul vt3.xy, vt3.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt3.xy, vt3.xy, vc[vt2.w].xy \n";
			code += "sub vt0.xy, vt0.xy, vt3.xy \n";
			
			code += "add vt0.xy, vt0.xy, vt3.xy \n";*/
			
			return code;
			
			code += "mov vt1.xy, vc[vt2.x].xy \n"; // move point 1 in vt1
			code += "sub vt1.xy, vt1.xy, vc[vt2.y].xy \n"; // Place difference between point 1 and point 2 in vt1
			code += "mul vt1.xy, vt1.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt1.xy, vt1.xy, vc[vt2.x].xy \n"; 
			code += "sub vt1.xy, vt0.xy, vt1.xy \n"; 
			
			code += "mov vt2.xy, vc[vt2.y].xy \n"; // move point 2 in vt2
			code += "sub vt2.xy, vt2.xy, vc[vt2.z].xy \n"; // Place difference between point 2 and point 3 in vt2
			code += "mul vt2.xy, vt2.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt2.xy, vt2.xy, vc[vt2.y].xy \n"; 
			code += "sub vt2.xy, vt0.xy, vt2.xy \n"; 
			
			code += "mov vt3.xy, vc[vt2.z].xy \n"; // move point 3 in vt3
			code += "sub vt3.xy, vt3.xy, vc[vt2.w].xy \n"; // Place difference between point 3 and point 4 in vt3
			code += "mul vt3.xy, vt3.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt3.xy, vt3.xy, vc[vt2.z].xy \n"; 
			code += "sub vt3.xy, vt0.xy, vt3.xy \n"; 
			
			code += "sub vt4.xy, vt1.xy, vt2.xy \n"; // Place difference between "resulting point 1" and "resulting point 2" in vt4
			code += "mul vt4.xy, vt4.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt4.xy, vt4.xy, vt1.xy \n"; 
			code += "sub vt4.xy, vt0.xy, vt4.xy \n"; 
			
			code += "sub vt5.xy, vt2.xy, vt3.xy \n"; // Place difference between "resulting point 2" and "resulting point 3" in vt5
			code += "mul vt5.xy, vt5.xy, vt6.xx \n"; // Multiple difference percentage
			code += "sub vt5.xy, vt5.xy, vt2.xy \n"; 
			code += "sub vt5.xy, vt0.xy, vt5.xy \n"; 
			
			code += "sub vt7.xy, vt4.xy, vt5.xy \n"; // Place difference between calc 1 point and calc 2 point in vt7
			code += "mul vt7.xy, vt7.xy, vt6.xx \n"; // Multiple difference percentage
			code += "add vt0.xy, vt0.xy, vt4.xy \n"; // Add point calc 1 point to base vertex
			code += "sub vt0.xy, vt0.xy, vt7.xy \n"; // Add percentage differnce to base vertex
			
			return code;
			
			// vc25.x == vc[vt2.x].x;
			// vc26.x == vc[vt2.y].x;
			// vc27.x == vc[vt2.z].x;
			// vc28.x == vc[vt2.w].x;
			
			//_vertexData[4] = loc1.x; // vc25.x
			//_vertexData[5] = loc1.y; // vc25.y
			//_vertexData[6] = loc1.z; // vc25.z
			//_vertexData[7] = 0;
			//
			//_vertexData[8] = loc2.x; // vc26.x
			//_vertexData[9] = loc2.y; // vc26.y
			//_vertexData[10] = loc2.z; // vc26.z
			//_vertexData[11] = 0;
			//
			//_vertexData[12] = loc3.x; // vc27.x
			//_vertexData[13] = loc3.y; // vc27.y
			//_vertexData[14] = loc3.z; // vc27.z
			//_vertexData[15] = 0;
			//
			//_vertexData[16] = loc4.x; // vc28.x
			//_vertexData[17] = loc4.y; // vc28.y
			//_vertexData[18] = loc4.z; // vc28.z
			//_vertexData[19] = 0;
			
			
			return  //"mov vt0, va0 \n" + 
					
					//"div vt6.x, vt0.z, vc24.x \n" + // divide z position by steps to get percentage
					//"mov vt0.z, vc24.z \n" + // reset z position to 0;
					
					
		}
		
		
		
		/**
		 * Generates the vertex AGAL code for additive blending.
		 */
		private function getAdditiveAGALCode(pass:MaterialPassBase, sourceRegisters:Vector.<String>, targetRegisters:Vector.<String>):String
		{
			var code:String = "";
			var len:uint = sourceRegisters.length;
			var regs:Array = ["x", "y", "z", "w"];
			var temp1:String = findTempReg(targetRegisters);
			var k:uint;
			var useTangents:Boolean = Boolean(_useTangents[pass] = len > 2);
			var useNormals:Boolean = Boolean(_useNormals[pass] = len > 1);
			var streamIndex:uint = _streamIndices[pass] = pass.numUsedStreams;
			
			if (len > 2)
				len = 2;
			
			code += "mov  " + targetRegisters[0] + ", " + sourceRegisters[0] + "\n";
			if (useNormals)
				code += "mov " + targetRegisters[1] + ", " + sourceRegisters[1] + "\n";
			
			for (var i:uint = 0; i < len; ++i) {
				for (var j:uint = 0; j < _numPoses; ++j) {
					code += "mul " + temp1 + ", va" + (streamIndex + k) + ", vc" + pass.numUsedVertexConstants + "." + regs[j] + "\n" +
						"add " + targetRegisters[i] + ", " + targetRegisters[i] + ", " + temp1 + "\n";
					k++;
				}
			}
			
			if (useTangents) {
				code += "dp3 " + temp1 + ".x, " + sourceRegisters[uint(2)] + ", " + targetRegisters[uint(1)] + "\n" +
					"mul " + temp1 + ", " + targetRegisters[uint(1)] + ", " + temp1 + ".x			 \n" +
					"sub " + targetRegisters[uint(2)] + ", " + sourceRegisters[uint(2)] + ", " + temp1 + "\n";
			}
			
			return code;
		}
	}
}
