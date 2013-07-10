package org.netlabtoolkit {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix3D;	
	
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
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	/**
	 * @author Ralph Hauwert / UnitZeroOne
	 * http://www.leebrimelow.com/flash-player-10-z-sorting-class/
	 */
	 

	public class SimpleZSorter
	{
		
		/**
		 * SimpleZSorter.sortClips(container, recursive);
		 * 
		 * @param container the display object containing the children to be sorted according to their Z Depth.
		 * @param recursive if set to true, the sortClips will recurse to all nested display objects, and sort their children if necessary.
		 */
		public static function sortClips(container : DisplayObjectContainer, recursive : Boolean = false) : void
		{
			//Check if something was passed.
			if(container != null){
				//Check if this displayobjectcontainer has more then 1 child.
				var nc:int = container.numChildren;
				if(nc > 1){
					
					var index:int = 0;
					var vo : SimpleZSortVO;
					var displayObject:DisplayObject;
					var transformedMatrix : Matrix3D;
					var mainParent : DisplayObject = traverseParents(container);
					
					//This array we will use to store & sort the objects and the relative screenZ's.
					var sortArray : Array = new Array();
					
					//cycle through all the displayobjects.
					for(var c:int = 0; c < container.numChildren; c++){
						displayObject = container.getChildAt(c);
						//If we are recursing all children, we also sort the children within these children.
						if(recursive && (displayObject is DisplayObjectContainer)){
							sortClips(displayObject as DisplayObjectContainer, true);
						}
						//This transformed matrix contains the actual transformed Z position.
						transformedMatrix = displayObject.transform.getRelativeMatrix3D(mainParent);
						
						//Push this object in the sortarray. [Maybe replace the new for a pool]
						sortArray.push(new SimpleZSortVO(displayObject, transformedMatrix.position.z));
					}
					
					//Sort the array (Array.sort is still king of speed).
					sortArray.sortOn("screenZ", Array.NUMERIC | Array.DESCENDING);
					for each(vo in sortArray){
						//Change the indices of all objects according to their Z Sorted value.
						container.setChildIndex(vo.object, index++);
					}
					
					//Let's make sure all ref's are released.
					sortArray = null;
				}
			}else{
				throw new Error("No displayobject was passed as an argument");
			}
		}
		
		/**
		 * This traverses the displayobject to the parent.
		 */
		private static function traverseParents(container : DisplayObject) : DisplayObject
		{
			//Take the current parent.
			var parent : DisplayObject = container.parent;
			var lastParent : DisplayObject = parent;
			//Iterate until the parent value is null (we've reached the end of this displayobject chain).
			while((parent = parent.parent) != null){
				lastParent = parent;
			}
			//Return the "top most" parent.
			return lastParent;
		}
	}
}
