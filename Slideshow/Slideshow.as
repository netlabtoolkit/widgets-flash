package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.display.*;
 	import flash.net.URLRequest;
	import flash.utils.Timer;
	import fl.transitions.*;
	import fl.transitions.easing.*;
	import flash.display.Sprite;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.media.Video;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
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
	
	public class Slideshow extends Widget { 
	
		// parameters in alphabetized order		
			
		// vars
		private var lastToggleValue:Number = 0;
		private var currentValue:Number = 0;

		// buttons
		
		
		// working variables
		private var listItemsObject:Object;
		private var imageLoaderA:Loader;
		private var imageLoaderB:Loader;
		private var bkLoader:Loader;
		private var nextSlide:String;

		public var bkMask:MovieClip = new MovieClip();
		public var slideA:MovieClip = new MovieClip();
		public var slideB:MovieClip = new MovieClip();
		public var slideVideo:MovieClip = new MovieClip();
		
		//private var rectangle:Shape = new Shape();
		
		private var theVideo:Video = new Video();
		public var videoClient:Object = new Object();
		private var videoDuration:Number = 0;
		private var nc:NetConnection;
		private var ns:NetStream;
		private var videoTween:Tween;
		
		private var slideATransition:TransitionManager = new TransitionManager(slideA);
		private var slideBTransition:TransitionManager = new TransitionManager(slideB);
		//private var videoTransition:TransitionManager = new TransitionManager(theVideo);
		private var currentLoader:Loader = imageLoaderA;
		private var currentSlide:MovieClip = slideA;
		private var startTimer:Timer;
		private var slideTimer:Timer;
		private var slideTimerVideo:Timer;
		private var nextSlideSpeed:int = 0;
		
		private var slideshowInit:Boolean = false;
		private var slideshowPaused:Boolean = false;
		
		// instances of objects on the Flash stage
		//
		// fields
		public var sInputSource:TextField;
		public var sInput:TextField;
		public var sOut:TextField;
		
		// buttons

		
		// objects

		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// set up the defaults for this widget's parameters
			/*
			paramsList.push(["sToggleThreshold", "500", "text"]);
			paramsList.push(["sToggleInc", "1", "text"]);
			paramsList.push(["sToggleMin", "0", "text"]);
			paramsList.push(["sToggleMax", "1", "text"]);
			
			// set the name used in the parameters XML
			paramsXMLname = "SoundControl_" + this.name;
			
			// go
			setupParams();
			*/
			
			if (listItemName != "none" && listItemName != "") listItemsObject = parseNameSpace(listItemName, parent);
			else listItemsObject = null;
			
			// init display text fields
			sInput.text = "0";
			sOut.text = String(currentValue);
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
			
			// set up input source to control speed
			if (inputSourceSlideTime != "none") setUpInputSourceOther(inputSourceSlideTime,handleInputFeedSlideTime);
			
			// set up the buffers for the slides
			slideA.x = slideB.x = bkMask.x = slideVideo.x = this.x;
			slideA.y = slideB.y = bkMask.y = slideVideo.y = this.y;
			
			//slideA.rotationY = slideB.rotationY = rectangle.rotationY = slideVideo.rotationY = horizontalSkew;
			/*
			rectangle.graphics.beginFill(0xFFFFFF); // choosing the colour for the fill, here it is red
			rectangle.graphics.drawRect(0, 0, slideWidth,slideHeight); // (x spacing, y spacing, width, height)
			rectangle.graphics.endFill(); // not always needed but I like to put it in to end the fill
			*/

			slideVideo.addChild(theVideo);
			parent.addChildAt(bkMask,0 + (slideDisplayOrder * 4));
			//parent.addChildAt(rectangle, 0 + (slideDisplayOrder * 4));
			parent.addChildAt(slideB,1 + (slideDisplayOrder * 4));
			parent.addChildAt(slideA,2 + (slideDisplayOrder * 4));
			parent.addChildAt(slideVideo,3 + (slideDisplayOrder * 4));
			
			slideA.rotationY = slideB.rotationY = bkMask.rotationY = slideVideo.rotationY = horizontalSkew;
			// set up video
			// Create a NetConnection object
			nc = new NetConnection();
			// Create a local streaming connection
			nc.connect(null);
			// Create a NetStream object and define an onStatus() function
			ns = new NetStream(nc);

			// Attach the NetStream video feed to the Video object
			theVideo.attachNetStream(ns);

			// set up for metadata callback
			videoClient.onMetaData = videoMetaData;
			videoClient.onCuePoint = videoCuePoint;
			ns.client = videoClient;
			
			theVideo.width = slideWidth;
			theVideo.height = slideHeight;
			
			// set up status handling
			ns.addEventListener(NetStatusEvent.NET_STATUS, netstatus);

			bkLoader = new Loader();
			bkLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, bkImageLoaded);
			bkLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			bkLoader.load(new URLRequest(backgroundMask));
			
			imageLoaderA = new Loader();
			imageLoaderA.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			imageLoaderA.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			imageLoaderB = new Loader();
			imageLoaderB.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			imageLoaderB.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			bkMask.addChild(bkLoader);
			slideA.addChild(imageLoaderA);
			slideB.addChild(imageLoaderB);
			
			// set up event listeners
			slideATransition.addEventListener("allTransitionsInDone", transitionComplete);
			slideBTransition.addEventListener("allTransitionsInDone", transitionComplete);

			// set up slide timer
			slideTimer = new Timer((slideTime * 1000),1);
			slideTimer.addEventListener(TimerEvent.TIMER, slideComplete);
			
			// set up slide timer to resume after video plays
			slideTimerVideo = new Timer((slideTime * 1000) + (startDelay * 1000),1);
			slideTimerVideo.addEventListener(TimerEvent.TIMER, slideComplete);
			
			// init slideshow
			startTimer = new Timer((startDelay * 1000) + 300,1);
			startTimer.addEventListener(TimerEvent.TIMER, initSlideShow);
			startTimer.start();
	
		}
		
		public function initSlideShow(event:TimerEvent):void {
			//var nextSlide:String;
			
			if (listItemsObject != null) {
				nextSlide = listItemsObject.nextItem(); // get the image name from the ListItems widget
				loadImage(nextSlide);
			}
		}
		
		public function slideComplete(event:TimerEvent):void {
			doTransition();
		}
			
		private function doTransition() {
			if (currentSlide == slideA) {
				//trace("transitioning to A");
				slideATransition.startTransition({type:Fade, direction:Transition.IN, duration:slideTransitionTime, easing:None.easeIn});
				slideBTransition.startTransition({type:Fade, direction:Transition.OUT, duration:slideTransitionTime, easing:None.easeOut});
				currentSlide = slideB;
				//currentLoader = imageLoaderB;
			} else {
				//trace("transitioning to B");
				slideBTransition.startTransition({type:Fade, direction:Transition.IN, duration:slideTransitionTime, easing:None.easeIn});
				slideATransition.startTransition({type:Fade, direction:Transition.OUT, duration:slideTransitionTime, easing:None.easeOut});
				currentSlide = slideA;
				//currentLoader = imageLoaderA;
			}
		}
 
		private function loadImage(url:String):void {
			// Set properties on my Loader object
			//currentLoader = new Loader();
			//currentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			//currentSlide.alpha = 0;
			if (currentSlide == slideA) imageLoaderA.load(new URLRequest(url));
			else imageLoaderB.load(new URLRequest(url));
		}

 
		private function imageLoaded(e:Event):void {
			// Load Image
			if (currentSlide == slideA) {
				imageLoaderA.width = slideWidth;
				imageLoaderA.height = slideHeight;
			} else {
				imageLoaderB.width = slideWidth;
				imageLoaderB.height = slideHeight;
			}
			//parent.swapChildren(slideA, slideB);
			slideA.x = slideB.x = this.x;
			slideA.y = slideB.y = this.y;
			parent.swapChildren(slideA, slideB);
			
			if (slideshowInit == false) {
				doTransition();
				slideshowInit = true;
			}
		}
		
		private function bkImageLoaded(e:Event):void {
			bkMask.width = slideWidth;
			bkMask.height = slideHeight;
			
			bkMask.x = this.x;
			bkMask.y = this.y;
		}
		
		function errorHandler(event:ErrorEvent):void {
			trace("load image error: " + nextSlide);
			if (listItemsObject != null) {
				nextSlide = listItemsObject.nextItem(); // get the image name from the ListItems widget
				loadImage(nextSlide);
			}
		}
		
		private function transitionComplete(e:Event):void {
			//var nextSlide:String;
			
			if (nextSlideSpeed != 0) {
				slideTimer = new Timer(nextSlideSpeed,1);
				slideTimer.addEventListener(TimerEvent.TIMER, slideComplete);
				nextSlideSpeed = 0;
			}
			
			if(!slideshowPaused) {
				slideTimer.start();
			}
			if (listItemsObject != null) {
				nextSlide = listItemsObject.nextItem(); // get the image name from the ListItems widget
				loadImage(nextSlide);
			}
		}
		
		private function videoMetaData(oMetaData:Object):void {
			videoDuration = Number(oMetaData.duration);
			//trace("meta: " + videoDuration);
		}
		
		private function videoCuePoint(oCuePoint:Object):void {
			//trace("cuepoint: " + oCuePoint.name + " " + oCuePoint.time);
		}
		
		public function netstatus(stats:NetStatusEvent):void {
			var statusCode:String = stats.info.code
			//trace(statusCode);
				
				
			if (statusCode == "NetStream.Play.StreamNotFound") {
				//trace("Can't find video file: " + videoFileName);
			}

			if (statusCode == "NetStream.Play.Stop") {
				//videoTransition.startTransition({type:Fade, direction:Transition.OUT, duration:slideTransitionTime, easing:None.easeIn});
				videoTween = new Tween(slideVideo, "alpha", None.easeOut, 1, 0, 1, true);
				stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 0));
				// start slideshow up
				slideTimerVideo.start();
				slideshowPaused = false;
			}
			
			
			
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue:Number = event.netFeedValue;
			sOut.text = sInput.text = String(inputValue);
			
			if (inputValue >= threshold && lastToggleValue < threshold) {
				
				
				// stop slideshow
				slideTimer.stop();
				slideshowPaused = true;
				//theVideo.alpha = 1;
				videoTween = new Tween(slideVideo, "alpha", None.easeIn, 0, 1, 1, true);
				//theVideo.width = slideWidth;
				//theVideo.height - slideHeight;
				//videoTransition.startTransition({type:Fade, direction:Transition.IN, duration:slideTransitionTime, easing:None.easeIn});
				ns.play(videoFileName);
				
				stage.dispatchEvent(new NetFeedEvent(this.name, 
												 true,
												 false,
												 this,
												 1023));
				
			} /* else if (inputValue < threshold && lastToggleValue >= threshold) {
				theVideo.alpha = 0;
			} */
			
			lastToggleValue = inputValue;
			
		}
		
		public function handleInputFeedSlideTime( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			if (inputValue > 0) nextSlideSpeed = Math.round(inputValue);
		}
		
		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			
		}
		
		//----------------------------------------------------------
		// parameter getter setter functions
		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
		}
		
		private var _slideWidth:Number = 320;
		[Inspectable (name = "slideWidth", variable = "slideWidth", type = "Number", defaultValue = 320)]
		public function get slideWidth():Number { return _slideWidth; }
		public function set slideWidth(value:Number):void {
			_slideWidth = value;
		}
		
		private var _slideHeight:Number = 240;
		[Inspectable (name = "slideHeight", variable = "slideHeight", type = "Number", defaultValue = 240)]
		public function get slideHeight():Number { return _slideHeight; }
		public function set slideHeight(value:Number):void {
			_slideHeight = value;
		}
		
		private var _slideTime:Number = 2.0;
		[Inspectable (name = "slideTime", variable = "slideTime", type = "Number", defaultValue = 2.0)]
		public function get slideTime():Number { return _slideTime; }
		public function set slideTime(value:Number):void {
			_slideTime = value;
		}
		
		private var _slideTransitionTime:Number = 1.0;
		[Inspectable (name = "slideTransitionTime", variable = "slideTransitionTime", type = "Number", defaultValue = 1.0)]
		public function get slideTransitionTime():Number { return _slideTransitionTime; }
		public function set slideTransitionTime(value:Number):void {
			_slideTransitionTime = value;
		}
		
		private var _startDelay:Number = 0.0;
		[Inspectable (name = "startDelay", variable = "startDelay", type = "Number", defaultValue = 0.0)]
		public function get startDelay():Number { return _startDelay; }
		public function set startDelay(value:Number):void {
			_startDelay = value;
		}
		
		private var _slideDisplayOrder:Number = 0;
		[Inspectable (name = "slideDisplayOrder", variable = "slideDisplayOrder", type = "Number", defaultValue = 0)]
		public function get slideDisplayOrder():Number { return _slideDisplayOrder; }
		public function set slideDisplayOrder(value:Number):void {
			_slideDisplayOrder = value;
		}
		
		
		private var _listItemName:String = "none";
		[Inspectable (name = "listItemName", variable = "listItemName", type = "String", defaultValue="none")]
		public function get listItemName():String { return _listItemName; }
		public function set listItemName(value:String):void {
			_listItemName = value;
			draw();
		}
		
		private var _videoFileName:String = "none.flv";
		[Inspectable (name = "videoFileName", variable = "videoFileName", type = "String", defaultValue="none.flv")]
		public function get videoFileName():String { return _videoFileName; }
		public function set videoFileName(value:String):void {
			_videoFileName = value;
			draw();
		}		
		
		private var _horizontalSkew:Number = 0.0;
		[Inspectable (name = "horizontalSkew", variable = "horizontalSkew", type = "Number", defaultValue = 0.0)]
		public function get horizontalSkew():Number { return _horizontalSkew; }
		public function set horizontalSkew(value:Number):void {
			_horizontalSkew = value;
		}	
		
		private var _backgroundMask:String = "none.png";
		[Inspectable (name = "backgroundMask", variable = "backgroundMask", type = "String", defaultValue="none.png")]
		public function get backgroundMask():String { return _backgroundMask; }
		public function set backgroundMask(value:String):void {
			_backgroundMask = value;
			draw();
		}		
		
		private var _inputSourceSlideTime:String = "none";
		[Inspectable (name = "inputSourceSlideTime", variable = "inputSourceSlideTime", type = "String", defaultValue="none")]
		public function get inputSourceSlideTime():String { return _inputSourceSlideTime; }
		public function set inputSourceSlideTime(value:String):void {
			_inputSourceSlideTime = value;
			draw();
		}
		
	}
}
