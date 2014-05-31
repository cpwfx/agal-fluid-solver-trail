package  
{
	/**
	 * ...
	 * @author P.J.Shand
	 */
	public class FrameData 
	{
		private var bufferLength:int = 20;
		private var buffer:Vector.<Frame> = new Vector.<Frame>();
		private var currentIndex:int = 0;
		private var particlesPerBatch:int;
		private var frameIndex:int;
		
		public function FrameData(particlesPerBatch:int) 
		{
			this.particlesPerBatch = particlesPerBatch;
			/*for (var i:int = 0; i < bufferLength; i++) 
			{
				buffer.push(new Frame(particlesPerBatch));
			}*/
		}
		
		public function lastData(value:Number):Vector.<Number>
		{
			var index:int = frameIndex - value;
			if (index < 0) index += bufferLength;
			//trace("index = " + index);
			return buffer[index].data;
		}
		
		public function set data(vec:Vector.<Number>):void 
		{
			if (buffer.length == 0) {
				for (var i:int = 0; i < bufferLength; i++) 
				{
					var frame:Frame = new Frame(particlesPerBatch);
					frame.data = new Vector.<Number>();
					for (var j:int = 0; j < vec.length; j++) 
					{
						frame.data.push(vec[j]);
					}
					buffer.push(frame);
				}
			}
			else {
				frameIndex = currentIndex % bufferLength;
				for (var k:int = 0; k < vec.length; k++) 
				{
					buffer[frameIndex].data[k] = vec[k];
				}
			}
			currentIndex++;
		}
		
		public function get data():Vector.<Number> 
		{
			return buffer[(currentIndex-1) % bufferLength].data;
		}
	}
}

class Frame
{
	public var data:Vector.<Number>;
	
	public function Frame(particlesPerBatch:int):void
	{
		data = new Vector.<Number>(particlesPerBatch*4);
	}
}