﻿package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import fl.controls.ComboBox; 
	import fl.data.DataProvider;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.filters.BlurFilter;
	import flash.events.GestureEvent;
	import flash.events.TouchEvent;
	import flash.events.TransformGestureEvent;
	import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;


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
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class ClipControl extends Widget { 
			
		// vars
		private var clipProperties:Array;
		private var theProperty:String;
		
		// buttons
		
		
		// working variables
		private var theClip:Object;
		private var touchConstrainClip:Object;
		public var propertySelector:ComboBoxSelector;
		private var blur:BlurFilter;
		private var dropShadow:DropShadowFilter;
		private var gestureInit:Boolean = true;
		
		// instances of objects on the Flash stage
		//
		// fields
		public var gInputSource:TextField;
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
				{label:"scale", data:"scale"}, 
				{label:"rotation", data:"rotation"}, 
				{label:"rotationX", data:"rotationX"},
				{label:"rotationY", data:"rotationY"},
				{label:"rotationZ", data:"rotationZ"},
				{label:"alpha", data:"alpha"},
				{label:"blur", data:"blur"},
				{label:"shadow", data:"shadow"},
				{label:"frameNo", data:"frameNo"},
				{label:"gesture", data:"gesture"},
				{label:"touch", data:"touch"}
			);
			
			// set up the selector
			propertySelector = new ComboBoxSelector(selectProperty, clipProperties, this, "property");
			

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["propertySelector", "x", "selector"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "ClipControl_" + this.name;
			
			// go
			setupParams();
			
			// set up filters
			blur = new BlurFilter(0,0,BitmapFilterQuality.MEDIUM)
			dropShadow = new DropShadowFilter();
			dropShadow.distance = 20;
			dropShadow.blurX = dropShadow.blurY = 8;
			
			// get object to be controlled
			theClip = parseNameSpace(clip, parent);
			if (theClip == null) {
				// bad clip name
				trace('--->BAD NAME FOR CLIP (' + clip + '): Check the spelling and clip instance name');
			}
			
			// get clip used to constrain touch dragging
			if (touchConstrain != "none" && theClip != null) {
				touchConstrainClip = parseNameSpace(touchConstrain, parent);
				if (touchConstrainClip == null) {
					// bad clip name
					trace('--->BAD NAME FOR TOUCH CONSTRAIN CLIP (' + clip + '): Check the spelling and clip instance name');
				}
			}
			
			setUpInputSource();
		}
		
		/*
		private function changeSelection(event:Event): void {
			trace("changeSelection");
			propertySelector.text = String(ComboBox(event.target).selectedItem.data);
			//dispatchEvent(new Event(Event.CHANGE));
		}
		*/
		
		private function enableGestureEvents():void {
			// set up for gestures
			Multitouch.inputMode = MultitouchInputMode.GESTURE;
			theClip.addEventListener(TransformGestureEvent.GESTURE_ZOOM, gestureZoomHandler);
			theClip.addEventListener(TransformGestureEvent.GESTURE_ROTATE, gestureRotateHandler);
			theClip.addEventListener(TransformGestureEvent.GESTURE_PAN, gesturePanHandler);
			//theClip.addEventListener(GestureEvent.GESTURE_TWO_FINGER_TAP, twoFingerTapHandler);
		}
		
		private function disableGestureEvents():void {
			// turn off gestures
			theClip.removeEventListener(TransformGestureEvent.GESTURE_ZOOM, gestureZoomHandler);
			theClip.removeEventListener(TransformGestureEvent.GESTURE_ROTATE, gestureRotateHandler);
			theClip.removeEventListener(TransformGestureEvent.GESTURE_PAN, gesturePanHandler);
			//theClip.removeEventListener(GestureEvent.GESTURE_TWO_FINGER_TAP, twoFingerTapHandler);
		}
		
		function enableTouchEvents():void {
			if (deviceType == "mobile") {
				Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
				theClip.addEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler);
				theClip.addEventListener(TouchEvent.TOUCH_END, touchEndHandler);
			} else {
				theClip.addEventListener(MouseEvent.MOUSE_DOWN, dragBegin);
				stage.addEventListener(MouseEvent.MOUSE_UP, dragEnd);
				//theClip.addEventListener(MouseEvent.MOUSE_OUT, dragEnd);
			}
		}
		function disableTouchEvents():void {
			if (deviceType == "mobile") {
				theClip.removeEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler);
				theClip.removeEventListener(TouchEvent.TOUCH_END, touchEndHandler);
			} else {
				theClip.removeEventListener(MouseEvent.MOUSE_DOWN, dragBegin);
				stage.removeEventListener(MouseEvent.MOUSE_UP, dragEnd);
				//theClip.removeEventListener(MouseEvent.MOUSE_OUT, dragEnd);
			}
		}
		
		// This method will control what happens when we Zoom
		private function gestureZoomHandler(e:TransformGestureEvent):void {
			theClip.scaleX *= e.scaleX;
			theClip.scaleY *= e.scaleY;
		}
		
		//This method will control what happens when we Rotate.
		private function gestureRotateHandler(e:TransformGestureEvent):void {
			theClip.rotation += e.rotation;
		}
		
		// This method will controll what happens when we Pan
		// Notice that we can not use Pan at the same time as Zoom and Rotate.
		private function gesturePanHandler(e:TransformGestureEvent):void {
			//trace("panning");
			theClip.x += e.offsetX;
			theClip.y += e.offsetY;
		}
		
		// The following two methods will let us drag the image
		// when using TouchPoint
		private function touchBeginHandler(e:TouchEvent):void {
			if (touchConstrain == "none" || touchConstrainClip == null) {
				theClip.startTouchDrag(e.touchPointID, false);
			} else if (touchConstrainClip != null) {
				theClip.startTouchDrag(e.touchPointID, false, touchConstrainClip.getRect(parent));
			}
		}
		
		private function touchEndHandler(e:TouchEvent):void {
			theClip.stopTouchDrag(e.touchPointID);
		}
		
		private function dragBegin(e:MouseEvent):void {
			//trace("dragging");
			if (touchConstrain == "none" || touchConstrainClip == null) {
				theClip.startDrag();
			} else if (touchConstrainClip != null) {
				theClip.startDrag(false,touchConstrainClip.getRect(parent));
			}
		}
		
		private function dragEnd(e:MouseEvent):void {
			theClip.stopDrag();
		}
		
		public function handleComboBox(selectionType:String, selector:ComboBox) { 
			//trace("got property change");
			theProperty = selector.selectedItem.data;
			if (theClip != null) {
				if (theProperty == "gesture") {
					enableGestureEvents();	
				} else {
					disableGestureEvents();
				}
				if (theProperty == "touch") {
					enableTouchEvents();	
				} else {
					disableTouchEvents();
				}
			}
		}
		
		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = Number(event.netFeedValue);
			gInputValue.text = String(inputValue.toFixed(1));
			
			if (theClip != null) {
				
				switch (theProperty) {
					
					
					case "scale" :
						theClip.scaleX = theClip.scaleY = inputValue/100;
						break;
					
					case "alpha" :
						theClip.alpha = inputValue/100;
						break;
						
					case "blur" :
						blur.blurX = blur.blurY = inputValue/10.0;
						theClip.filters = [blur];
						break;
						
					case "shadow" :
						dropShadow.angle = inputValue;
						theClip.filters = [dropShadow];
						break;
						
					case "frameNo" :
						try {
							var frameNo = Math.round(inputValue);
							theClip.gotoAndStop(frameNo);
						} catch (error:Error) {
							trace("The clip: " + theClip.name + " doesn't have a frame at: " + frameNo);
						}
						
						break;
						
					case "gesture" :
					case "touch" :
						break;
												
					default : // width, height, x, y, z, rotation, etc
						theClip[theProperty] = inputValue;
				}
			}
		}
		
		override public function draw():void {
			super.draw();
			gInputSource.text = inputSource;
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
		
		private var _touchConstrain:String = "clip1";
		[Inspectable (name = "touchConstrain", variable = "touchConstrain", type = "String", defaultValue="none")]
		public function get touchConstrain():String { return _touchConstrain; }
		public function set touchConstrain(value:String):void {
			_touchConstrain = value;
			//draw();
		}
	}
}
