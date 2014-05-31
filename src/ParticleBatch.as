package  
{
	import animators.PointCloudAnimationSet;
	import animators.PointCloudAnimator;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.CompactSubGeometry;
	import away3d.entities.Mesh;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.textures.ATFTexture;
	import away3d.textures.BitmapTexture;
	import away3d.tools.commands.Merge;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import methods.PixelMethod;
	
	/**
	 * ...
	 * @author P.J.Shand
	 */
	public class ParticleBatch extends ObjectContainer3D 
	{
		private var pointGeo:PlaneGeometry;
		private var merge:Merge;
		
		private var pointCloudAnimationSet:PointCloudAnimationSet;
		
		[Embed(source="bokeh1.png", mimeType="image/png")]
		private const bokeh1Class:Class;
		private var _bokeh1:BitmapData;
		
		private static var sharedBaseMesh:Mesh;
		private static var sharedContainer:Mesh;
		private var container:Mesh;
		private var frameData:FrameData;
		
		private var sprites:Vector.<Sprite> = new Vector.<Sprite>();
		
		public function get bokeh1():BitmapData{
			if (!_bokeh1) _bokeh1 = (new bokeh1Class()).bitmapData;
			return _bokeh1;
		}
		
		public function ParticleBatch(particlesPerBatch:int, stage:Stage) 
		{
			
			for (var j:int = 0; j < 100; j++) 
			{
				var s:Sprite = new Sprite();
				s.graphics.beginFill(0xFFDDDD);
				s.graphics.drawCircle(0, 0, 4);
				stage.addChild(s);
				sprites.push(s);
			}
			super();
			
			trace("particlesPerBatch = " + particlesPerBatch);
			
			frameData = new FrameData(particlesPerBatch);
			
			var texture:BitmapTexture = new BitmapTexture(bokeh1);
			var pointMaterial:TextureMaterial = new TextureMaterial(texture);
			pointMaterial.alphaBlending = true;
			pointMaterial.blendMode = BlendMode.ADD;
			//pointMaterial.alpha = 0.03;
			pointMaterial.colorTransform = new ColorTransform(1, 0.5, Math.random() * 0.5, Settings.particleAlpha, 0, 0, 0, 0);
			
			if (!sharedContainer){
				pointGeo = new PlaneGeometry(Settings.particleSize, Settings.particleSize, 1, 1, false);
				
				var mergeContainer:ObjectContainer3D = new ObjectContainer3D();
				for (var i:int = 0; i < particlesPerBatch-2; ++i)
				{
					if (!sharedBaseMesh) {
						sharedBaseMesh = duplicate(new Mesh(pointGeo, null), 400);
					}
					
					//var mesh:Mesh = new Mesh(pointGeo.clone(), null);
					var mesh:Mesh = new Mesh(sharedBaseMesh.geometry.clone(), null);
					mesh.scale(1 + (Math.random() * 2));
					mesh.z = 10 + i;
					
					mergeContainer.addChild(mesh);
					
				}
				
				sharedContainer = new Mesh(null, pointMaterial);
				
				merge = new Merge();
				merge.applyToContainer(sharedContainer, mergeContainer);
				
				sharedContainer.bounds.fromSphere(new Vector3D(), 100000);
			}
			
			container = new Mesh(sharedContainer.geometry.clone(), pointMaterial);
			addChild(container);
			
			pointCloudAnimationSet = new PointCloudAnimationSet(particlesPerBatch);
			container.animator = new PointCloudAnimator(pointCloudAnimationSet);
			
			//pointMaterial.addMethod(new PixelMethod());
		}
		
		private function duplicate(baseMesh:Mesh, num:Number):Mesh 
		{
			var container:Mesh = new Mesh(null, null);
			for (var i:int = 0; i < num; i++) 
			{
				var mesh:Mesh = new Mesh(baseMesh.geometry.clone(), null);
				mesh.z = i / num;
				/*var vertexData:Vector.<Number> = CompactSubGeometry(mesh.geometry.subGeometries[0]).vertexData;
				for (var j:int = 0; j < vertexData.length/13; j+=13) 
				{
					trace(vertexData[j + 3]);
					vertexData[j + 3] = i / num;
				}
				CompactSubGeometry(mesh.geometry.subGeometries[0]).updateData(vertexData);*/
				container.addChild(mesh);
			}
			
			var returnMesh:Mesh = new Mesh(null, null);
			merge = new Merge();
			merge.applyToContainer(returnMesh, container);
			return returnMesh;
		}
		
		public var positionData1:Vector.<Number>;
		public var positionData2:Vector.<Number>;
		public var positionData3:Vector.<Number>;
		public var positionData4:Vector.<Number>;
		
		public function set vec(value:Vector.<Number>):void 
		{
			
			trace("value.length = " + value.length);
			
			frameData.data = value;
			
			positionData1 = frameData.lastData(0);
			positionData2 = frameData.lastData(3);
			positionData3 = frameData.lastData(6);
			positionData4 = frameData.lastData(9);
			
			pointCloudAnimationSet.positionData1 = positionData1;
			pointCloudAnimationSet.positionData2 = positionData2;
			pointCloudAnimationSet.positionData3 = positionData3;
			pointCloudAnimationSet.positionData4 = positionData4;
			
			/*for (var i:int = 0; i < sprites.length; i++) 
			{
				var f:Number = i / sprites.length;
				sprites[i].x = positionData1[0];
				sprites[i].y = -positionData1[1];
				
				sprites[i].x += (positionData4[0] - positionData1[0]) * f;
				sprites[i].y -= (positionData4[1] - positionData1[1]) * f;
			}*/
			//trace("1 = " + pointCloudAnimationSet.positionData1[4]);
			//trace("2 = " + pointCloudAnimationSet.positionData2[4]);
			//trace("3 = " + pointCloudAnimationSet.positionData3);
			//trace("4 = " + pointCloudAnimationSet.positionData4);
			
		}
	}
}