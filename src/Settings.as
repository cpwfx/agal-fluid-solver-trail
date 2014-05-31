package  
{
	/**
	 * ...
	 * @author P.J.Shand
	 */
	public class Settings 
	{
		public static var useWorkers:Boolean = true;
		private static var _particleSize:Number = 4;
		
		static public function get width():Number 
		{
			CONFIG::mobile  {
				return 1920;
			}
			return 1080;
		}
		
		static public function get height():Number 
		{
			CONFIG::mobile  {
				return 1080;
			}
			return 500;
		}
		
		static public function get batches():int 
		{
			CONFIG::mobile  {
				return 25;
			}
			return 100;
		}
		
		static public function get particleSize():Number 
		{
			CONFIG::mobile  {
				return 20;
			}
			return 10;
		}
		
		static public function get FLUID_WIDTH():uint 
		{
			CONFIG::mobile  {
				return 30;
			}
			return 60;
		}
		
		static public function get Scale():Number
		{
			CONFIG::mobile  {
				return 1.1;
			}
			return 2.31;
		}
		
		static public function get viscosity():Number 
		{
			CONFIG::mobile  {
				return .001;
			}
			return .001;
		}
		
		static public function get deltaT():Number 
		{
			CONFIG::mobile  {
				return .2;
			}
			return .3;
		}
		
		static public function get fadeSpeed():Number 
		{
			CONFIG::mobile  {
				return 0.0001;
			}
			return 0.001;
		}
		
		static public function get wrap_y():Boolean 
		{
			return true;
		}
		
		static public function get wrap_x():Boolean 
		{
			return true;
		}
	}
}