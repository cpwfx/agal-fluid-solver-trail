package animators
{
	import away3d.animators.AnimationSetBase;
	import away3d.animators.data.VertexAnimationMode;
	import away3d.animators.IAnimationSet;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;
	
	import flash.display3D.Context3D;
	
	import flash.utils.Dictionary;
	
	use namespace arcane;
	
	/**
	 * The animation data set used by vertex-based animators, containing vertex animation state data.
	 *
	 * @see away3d.animators.VertexAnimator
	 */
	public class CubicBezierAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _numPoses:uint;
		private var _blendMode:String;
		private var _streamIndices:Dictionary = new Dictionary(true);
		private var _useNormals:Dictionary = new Dictionary(true);
		private var _useTangents:Dictionary = new Dictionary(true);
		private var _uploadNormals:Boolean;
		private var _uploadTangents:Boolean;
		
		private var _vertexData : Vector.<Number>;
		private var _steps:int = 10;
		private var _loc1:Vector3D = new Vector3D( -200, -200, 0);
		private var _loc2:Vector3D = new Vector3D( 200, 200, 0);
		private var _loc3:Vector3D = new Vector3D( 200, -400, 0);
		private var _loc4:Vector3D = new Vector3D( 500, 0, 0);
		
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
		 * Creates a new <code>TrailAnimationSet</code> object.
		 *
		 * @param numPoses The number of poses made available at once to the GPU animation code.
		 * @param blendMode Optional value for setting the animation mode of the vertex animator object.
		 *
		 * @see away3d.animators.data.VertexAnimationMode
		 */
		public function CubicBezierAnimationSet(numPoses:uint = 2, blendMode:String = "absolute")
		{
			super();
			_numPoses = numPoses;
			_blendMode = blendMode;
			
			_vertexData = new Vector.<Number>(20);
			updateVertexData();
		
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
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 24, _vertexData, 5);
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
			return  "mov vt0, va0 \n" + 
					
					"div vt6.x, vt0.z, vc24.x \n" + // divide z position by steps to get percentage
					"mov vt0.z, vc24.z \n" + // reset z position to 0;
					
					"mov vt1.xy, vc25.xy \n" + // move point 1 in vt1
					"sub vt1.xy, vt1.xy, vc26.xy \n" + // Place difference between point 1 and point 2 in vt1
					"mul vt1.xy, vt1.xy, vt6.xx \n" + // Multiple difference percentage
					"sub vt1.xy, vt1.xy, vc25.xy \n" + 
					"sub vt1.xy, vt0.xy, vt1.xy \n" + 
					
					"mov vt2.xy, vc26.xy \n" + // move point 2 in vt2
					"sub vt2.xy, vt2.xy, vc27.xy \n" + // Place difference between point 2 and point 3 in vt2
					"mul vt2.xy, vt2.xy, vt6.xx \n" + // Multiple difference percentage
					"sub vt2.xy, vt2.xy, vc26.xy \n" + 
					"sub vt2.xy, vt0.xy, vt2.xy \n" + 
					
					"mov vt3.xy, vc27.xy \n" + // move point 3 in vt3
					"sub vt3.xy, vt3.xy, vc28.xy \n" + // Place difference between point 3 and point 4 in vt3
					"mul vt3.xy, vt3.xy, vt6.xx \n" + // Multiple difference percentage
					"sub vt3.xy, vt3.xy, vc27.xy \n" + 
					"sub vt3.xy, vt0.xy, vt3.xy \n" + 
					
					"sub vt4.xy, vt1.xy, vt2.xy \n" + // Place difference between "resulting point 1" and "resulting point 2" in vt4
					"mul vt4.xy, vt4.xy, vt6.xx \n" + // Multiple difference percentage
					"sub vt4.xy, vt4.xy, vt1.xy \n" + 
					"sub vt4.xy, vt0.xy, vt4.xy \n" + 
					
					"sub vt5.xy, vt2.xy, vt3.xy \n" + // Place difference between "resulting point 2" and "resulting point 3" in vt5
					"mul vt5.xy, vt5.xy, vt6.xx \n" + // Multiple difference percentage
					"sub vt5.xy, vt5.xy, vt2.xy \n" + 
					"sub vt5.xy, vt0.xy, vt5.xy \n" + 
					
					"sub vt7.xy, vt4.xy, vt5.xy \n" + // Place difference between calc 1 point and calc 2 point in vt7
					"mul vt7.xy, vt7.xy, vt6.xx \n" + // Multiple difference percentage
					"add vt0.xy, vt0.xy, vt4.xy \n" + // Add point calc 1 point to base vertex
					"sub vt0.xy, vt0.xy, vt7.xy \n"; // Add percentage differnce to base vertex
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
		
		
		
		public function updateVertexData():void
		{
			_vertexData[0] = steps;
			_vertexData[1] = 0;
			_vertexData[2] = 0;
			_vertexData[3] = 0;
			
			_vertexData[4] = loc1.x;
			_vertexData[5] = loc1.y;
			_vertexData[6] = loc1.z;
			_vertexData[7] = 0;
			
			_vertexData[8] = loc2.x;
			_vertexData[9] = loc2.y;
			_vertexData[10] = loc2.z;
			_vertexData[11] = 0;
			
			_vertexData[12] = loc3.x;
			_vertexData[13] = loc3.y;
			_vertexData[14] = loc3.z;
			_vertexData[15] = 0;
			
			_vertexData[16] = loc4.x;
			_vertexData[17] = loc4.y;
			_vertexData[18] = loc4.z;
			_vertexData[19] = 0;
		}
		
		public function get loc1():Vector3D 
		{
			return _loc1;
		}
		
		public function set loc1(value:Vector3D):void 
		{
			_loc1 = value;
		}
		
		public function get loc2():Vector3D 
		{
			return _loc2;
		}
		
		public function set loc2(value:Vector3D):void 
		{
			_loc2 = value;
		}
		
		public function get loc3():Vector3D 
		{
			return _loc3;
		}
		
		public function set loc3(value:Vector3D):void 
		{
			_loc3 = value;
		}
		
		public function get loc4():Vector3D 
		{
			return _loc4;
		}
		
		public function set loc4(value:Vector3D):void 
		{
			_loc4 = value;
		}
		
		public function get steps():int 
		{
			return _steps;
		}
		
		public function set steps(value:int):void 
		{
			_steps = value;
		}
	}
}
