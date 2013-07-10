package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.DisplayObjectContainer;
	import flash.display.DisplayObject;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.media.Camera;
	import flash.media.Video;
	
	import org.netlabtoolkit.*;
	
	// uses these two libraries by Soulwire and GSkinner http://blog.soulwire.co.uk/code/actionscript-3/webcam-motion-detection-tracking
	import uk.co.soulwire.cv.MotionTracker;
	import com.gskinner.geom.ColorMatrix;
	
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
	
	public class MotionTrack extends WidgetBase { 
	
		// vars
		private var _motionTracker : MotionTracker;

		private var _target : Shape;
		private var _bounds : Shape;
		private var _output : Bitmap;
		private var _source : Bitmap;
		private var _video : BitmapData;
		private var _matrix : ColorMatrix;
		
		private var camW : int = 320;
		private var camH : int = 240;
		private var displayYOffset:int = 37;
		
		// buttons
		public var easingButton:ToggleButton;
		
		// working variables
		
		
		// instances of objects on the Flash stage
		//
		// fields
		public var blur:TextField;
		public var brightness:TextField;
		public var contrast:TextField;
		public var minArea:TextField;
		public var screenWidth:TextField;
		public var xOut:TextField;
		public var yOut:TextField;
		public var labelX:TextField;
		public var labelY:TextField;
		
		// buttons
		public var easing:MovieClip;
		
		// objects


		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the buttons
			easingButton = new ToggleButton(easing, this, "easing");
			
			// set up the defaults for this widget's parameters
			paramsList.push(["blur", "0", "text"]);
			paramsList.push(["brightness", "0", "text"]);
			paramsList.push(["contrast", "0", "text"]);
			paramsList.push(["minArea", "0", "text"]);
			paramsList.push(["screenWidth", "320", "text"]);
			paramsList.push(["easingButton", "on", "button"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "MotionTrack_" + this.name;
			
			// go
			setupParams();
			
			// init display text fields
			//blur.text = "0";
			//brightness.text = "0";
			//contrast.text = "0";
			//minArea.text = "0";
			//screenWidth.text = "320";
			xOut.text = String(xOffset);
			yOut.text = String(yOffset);
			labelX.text = this.name + "X";
			labelY.text = this.name + "Y";
			
			//configureUI();
			initTracking();
			applyFilters();
			
		}
		

		//	----------------------------------------------------------------
		//	PRIVATE METHODS
		//	----------------------------------------------------------------


		private function initTracking() : void
		{

			// Create the camera
			var cam : Camera = Camera.getCamera();
			cam.setMode(camW, camH, stage.frameRate);
			
			// Create a video
			var vid : Video = new Video(camW, camH);
			vid.attachCamera(cam);
			
			// Create the Motion Tracker
			_motionTracker = new MotionTracker(vid);
			
			// We flip the input as we want a mirror image
			_motionTracker.flipInput = true;
			
			/*** Create a few things to help us visualise what the MotionTracker is doing... ***/

			_matrix = new ColorMatrix();
			_matrix.brightness = _motionTracker.brightness;
			_matrix.contrast = _motionTracker.contrast;
			
			// Display the camera input with the same filters (minus the blur) as the MotionTracker is using
			_video = new BitmapData(camW, camH, false, 0);
			_source = new Bitmap(_video);
			_source.scaleX = -1;
			_source.x = camW;
			_source.y = displayYOffset;
			_source.filters = [new ColorMatrixFilter(_matrix.toArray())];
			addChild(_source);
			
			// Show the image the MotionTracker is processing and using to track
			_output = new Bitmap(_motionTracker.trackingImage);
			_output.x = camW + 10;
			_output.y = displayYOffset;
			addChild(_output);
			
			// A shape to represent the tracking point
			_target = new Shape();
			_target.graphics.lineStyle(0, 0xFFFFFF);
			_target.graphics.drawCircle(0, 0, 10);
			addChild(_target);
			
			// A box to represent the activity area
			_bounds = new Shape();
			_bounds.x = _output.x;
			_bounds.y = _output.y;
			addChild(_bounds);
			
			// Get going!
			addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
		}

		private function applyFilters() : void
		{
			//_blurLabel.text = "Blur: " + Math.round(_blurSlider.value);
			//_brightnessLabel.text = "Brightness: " + Math.round(_brightnessSlider.value);
			//_contrastLabel.text = "Contrast: " + Math.round(_contrastSlider.value);
			//_minAreaLabel.text = "Min Area: " + Math.round(_minAreaSlider.value);
			
			_matrix.reset();
			_matrix.adjustContrast(0);
			_matrix.adjustBrightness(0);
			_source.filters = [new ColorMatrixFilter(_matrix)];
		}

		//	----------------------------------------------------------------
		//	EVENT HANDLERS
		//	----------------------------------------------------------------


		private function onEnterFrameHandler(event : Event) : void
		{
			var adjustedX:Number;
			var adjustedY:Number;
			var scaleRatio:Number;
			
			// Tell the MotionTracker to update itself
			_motionTracker.track();
			
			// Move the target with some easing
			//_target.x += ((_motionTracker.x + _bounds.x) - _target.x) / 10;
			//_target.y += ((_motionTracker.y + _bounds.y) - _target.y) / 10;
			
			_video.draw(_motionTracker.input);
			
			scaleRatio = Number(screenWidth.text) / camW;
			
			if (easingButton.text == "on") {
				_target.x += ((_motionTracker.x + _bounds.x) - _target.x) / 10;
				_target.y += ((_motionTracker.y + _bounds.y) - _target.y) / 10;
				adjustedX = (_target.x - _output.x) * scaleRatio;
				adjustedY = (_target.y - displayYOffset) * scaleRatio;
			} else {
				_target.x = _motionTracker.x + _bounds.x;
				_target.y = _motionTracker.y + _bounds.y;
				adjustedX = _motionTracker.x * scaleRatio;
				adjustedY = _motionTracker.y * scaleRatio;
			}
			
			adjustedX += xOffset;
			adjustedY += yOffset;
			
			// dispatch the x,y coords
			stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 adjustedX));
			stage.dispatchEvent(new NetFeedEvent(this.name + "X", 
												 true,
												 false,
												 this,
												 adjustedX));
			stage.dispatchEvent(new NetFeedEvent(this.name + "Y", 
												 true,
												 false,
												 this,
												 adjustedY));
			
			// show x,y
			xOut.text = String(Math.round(adjustedX));
			yOut.text = String(Math.round(adjustedY));
			
			// If there is enough movement (see the MotionTracker's minArea property) then continue
			if ( !_motionTracker.hasMovement ) return;
			
			// Draw the motion bounds so we can see what the MotionTracker is doing
			_bounds.graphics.clear();
			_bounds.graphics.lineStyle(0, 0xFFFFFF);
			_bounds.graphics.drawRect(_motionTracker.motionArea.x, _motionTracker.motionArea.y, _motionTracker.motionArea.width, _motionTracker.motionArea.height);
			
			
		}


		private function paramsChange(event : Event) : void
		{
			switch(event.target)
			{
				case blur : 
				
					_motionTracker.blur = Number(blur.text);
				
					break;
				
				case brightness : 
				
					_motionTracker.brightness = Number(brightness.text);
				
					break;
					
				case contrast : 
				
					_motionTracker.contrast = Number(contrast.text);
				
					break;
					
				case minArea : 
				
					_motionTracker.minArea = Number(minArea.text);
				
					break;
			}
			
			applyFilters();
		}
		
		override public function parametersDone(): void {
			 
			blur.addEventListener(Event.CHANGE, paramsChange);
			brightness.addEventListener(Event.CHANGE, paramsChange);
			contrast.addEventListener(Event.CHANGE, paramsChange);
			minArea.addEventListener(Event.CHANGE, paramsChange);
			
		}
		
		public function handleButton(buttonType:String, buttonState:String) {
			/*
			if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
			*/
		}
		
		override public function draw():void {
			
			//labelX.text = this.name + "X";
			//labelY.text = this.name + "Y";
			super.draw();
			//
			
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _xOffset:Number = 0;
		[Inspectable (name = "xOffset", variable = "xOffset", type = "Number", defaultValue = 0)]
		public function get xOffset():Number { return _xOffset; }
		public function set xOffset(value:Number):void {
			_xOffset = value;
		}
		
		private var _yOffset:Number = 0;
		[Inspectable (name = "yOffset", variable = "yOffset", type = "Number", defaultValue = 0)]
		public function get yOffset():Number { return _yOffset; }
		public function set yOffset(value:Number):void {
			_yOffset = value;
		}

	}
}
