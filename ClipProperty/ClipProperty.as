package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import fl.controls.ComboBox; 
	import fl.data.DataProvider;

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
	
	public class ClipProperty extends WidgetBase { 
			
		// vars
		private var clipProperties:Array;
		private var theProperty:String;
		
		// buttons
		
		
		// working variables
		private var theClip:Object;
		public var propertySelector:ComboBoxSelector;
		
		// instances of objects on the Flash stage
		//
		// fields
		public var gInputValue:TextField;
		public var gClipName:TextField;
		
		// buttons

		
		// objects
		public var selectProperty:ComboBox;

		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
						
			clipProperties = new Array( 
				
				{label:"x", data:"x"}, 
				{label:"y", data:"y"}, 
				{label:"z", data:"z"}, 
				{label:"width", data:"width"}, 
				{label:"height", data:"height"}, 
				{label:"scaleX", data:"scaleX"}, 
				{label:"scaleY", data:"scaleY"}, 
				{label:"rotation", data:"rotation"}, 
				{label:"rotationX", data:"rotationX"},
				{label:"rotationY", data:"rotationY"},
				{label:"rotationZ", data:"rotationZ"},
				{label:"alpha", data:"alpha"},
				{label:"frameNo", data:"currentFrame"}
				//{label:"swipe", data:"swipe"}
			);
			
			// set up the selector
			propertySelector = new ComboBoxSelector(selectProperty, clipProperties, this, "property");
			

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["propertySelector", "x", "selector"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "ClipProperty_" + this.name;
			
			// go
			setupParams();
			
			// get object to be listened to
			theClip = parseNameSpace(clip, parent);
			if (theClip == null) {
				// bad clip name
				trace('--->BAD NAME FOR CLIP (' + clip + '): Check the spelling and clip instance name');
			}
			
			addEventListener(Event.ENTER_FRAME,checkProperty);

		}
		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			//trace("got property change");
			theProperty = selector.selectedItem.data;
		}
		
		public function checkProperty( event:Event ):void {
			
			var inputValue;
			
			if (theClip != null && theProperty != null) {
				
				switch (theProperty) {
					
					case "scaleX" :
						inputValue = theClip.scaleX * 100;
						break;
						
					case "scaleY" :
						inputValue = theClip.scaleY * 100;
						break;
					
					case "alpha" :
						inputValue = theClip.alpha * 100;
						break;
												
					default : // width, height, x, y, z, rotation, etc
						inputValue = theClip[theProperty];
				}
				gInputValue.text = String(inputValue.toFixed(1));
				//sOut.text = String(outputValue);
				stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 inputValue));
			}
		}
		
		override public function draw():void {
			super.draw();
			gClipName.text = clip;
			
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _clip:String = "clip1";
		[Inspectable (name = "clip", variable = "clip", type = "String", defaultValue="clip1")]
		public function get clip():String { return _clip; }
		public function set clip(value:String):void {
			_clip = value;
			draw();
		}
	}
}
