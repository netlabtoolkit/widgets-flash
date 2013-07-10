package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.DisplayObjectContainer;
	import flash.display.DisplayObject;
	import flash.geom.Matrix3D;
	import flash.geom.Transform;
	import org.netlabtoolkit.*;
	
	/**
	 * Part of the NETLab Flash Widgets, which is part of the NETLab Toolkit project - http://netlabtoolkit.org
	 *
	 * Copyright (c) 2006-2013 Philip van Allen <dev@philvanallen.com>
	 * 
	 * @author Philip van Allen
	 *
	 * NETLab Flash Widgets is free software: you can redistribute it and/or modify
	 * it under the terms of the GNU General Public License as published by
	 * the Free Software Foundation, either version 3 of the License, or
	 * (at your option) any later version.
	 *
	 * NETLab Flash Widgets is distributed in the hope that it will be useful,
	 * but WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 * GNU General Public License for more details.
	 *
	 * You should have received a copy of the GNU General Public License
	 * along with NETLab Glash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class ZSortClips extends WidgetBase { 
	
		// vars

		
		// buttons
		
		
		// working variables
		private var theClip:DisplayObjectContainer;
		
		// instances of objects on the Flash stage
		//
		// fields
		public var sClipName:TextField;
		
		// buttons

		
		// objects


		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			var tempClip;

			tempClip = parseNameSpace(clipContainer, parent);
			
			if (tempClip == this.stage) tempClip = null;
			//trace(tempClip);

			if (tempClip != null) {
				theClip = DisplayObjectContainer(tempClip);
				// set up our event listener to sort on every frame
				this.addEventListener(Event.ENTER_FRAME, sortIt);
			} else {
				// bad clip name
				trace("--->SortClipsByZ: BAD NAME FOR CLIP CONTAINER: Check the spelling and clip instance name");
			}
			
		}
		
		private function sortIt(e:Event) : void {
			//trace("here");
			//SimpleZSorter.sortClips(parent, sortRecursively);
			simpleZSort3DChildren(theClip, sortRecursively);
		}
		
		public static function simpleZSort3DChildren( doc:DisplayObjectContainer, recurse:Boolean = true ) : void {
			
			// thanks to Drew Cummins for this zsort code
			// http://blog.generalrelativity.org/?p=28
		 
			//transforms from local to world oordinate frame
			var transform:Matrix3D
			
			// the z axis needs to be set for this to work
			doc.z = doc.z;
			transform = doc.transform.getRelativeMatrix3D( doc.stage );
			//var transformedMatrix:Matrix3D = doc.transform.getRelativeMatrix3D( mainParent );
		 	//trace(transform);
			var numChildren:int = doc.numChildren;
		 
			//v = ( n * 3 )- (x,y,z) set for each child
			var vLength:int = numChildren * 3;
		 
			var vLocal:Vector.<Number> = new Vector.<Number>( vLength, true );
			var vWorld:Vector.<Number> = new Vector.<Number>( vLength, true );
		 
			//insertion point for child’s coordinates into state vector
			var vIndex:int = 0;
		 
			for( var i:int = 0; i <numChildren; i++ )
			{
		 
				var child:DisplayObject = doc.getChildAt( i );
				if( recurse && child is DisplayObjectContainer ) simpleZSort3DChildren( DisplayObjectContainer( child ), true );
		 
				vLocal[ vIndex ] = child.x;
				vLocal[ vIndex + 1 ] = child.y;
				vLocal[ vIndex + 2 ] = child.z;
		 
				vIndex += 3;
		 
			}
		 
			//populates vWorld with children coordinates in world space
			transform.transformVectors( vLocal, vWorld );
		 
		 
		 
			//bubble sorts children along world z-axis
			for( i = numChildren - 1; i > 0; i-- )
			{
		 
				var hasSwapped:Boolean = false;
		 
				vIndex = 2;
		 
				for( var j:int = 0; j < i; j++ )
				{
		 
					//z value at that index for each child
					var z1:Number = vWorld[ vIndex ];
		 
					vIndex += 3;
		 
					var z2:Number = vWorld[ vIndex ];
		 
					if( z2> z1 )
					{
		 
						//swap
						doc.swapChildrenAt( j, j + 1 );
		 
						//swap z values (don’t need to change x and y because they’re not used anymore)
						vWorld[ vIndex - 3 ] = z2;
						vWorld[ vIndex ] = z1;
		 
						//mark as swapped
						hasSwapped = true;
		 
					}
		 
				}
		 
				//if there was no swap, we don’t need to iterate again
				if( !hasSwapped ) return;
		 
			}
		}
		
		private static function traverseParents(container : DisplayObject) : DisplayObject {
			//Take the current parent.
			var parent : DisplayObject = container.parent;
			var lastParent : DisplayObject = parent;
			//Iterate until the parent value is null (we've reached the end of this displayobject chain).
			while((parent = parent.parent) != null){
				lastParent = parent;
			}
			//Return the "top most" parent.
			//trace(lastParent);
			return lastParent;
		}
		
		override public function draw():void {
			super.draw();
			sClipName.text = clipContainer;
			
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _clipContainer:String = "clip1";
		[Inspectable (name = "clipContainer", variable = "clipContainer", type = "String", defaultValue="clip1")]
		public function get clipContainer():String { return _clipContainer; }
		public function set clipContainer(value:String):void {
			_clipContainer = value;
			draw();
		}		
		
		private var _sortRecursively:Boolean = true;
		[Inspectable (name = "sortRecursively", variable = "sortRecursively", type = "Boolean", defaultValue=true)]
		public function get sortRecursively():Boolean { return _sortRecursively; }
		public function set sortRecursively(value:Boolean):void {
			_sortRecursively = value;
			//draw();
		}
	}
}
