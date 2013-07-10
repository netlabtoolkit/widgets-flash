package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.errors.IOError; 
	import flash.text.TextField;
	import flash.utils.getTimer;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.media.Video;
	import flash.utils.Timer;

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
	
	public class VideoControl extends Widget { 

		// vars
		
		// buttons
		
		
		// working variables 
		private var videoDuration:Number = 0;
		public var videoClient:Object = new Object();
		private var currentlyPlaying:String = "stopped";
		private var lastTime:Number = getTimer();
		private var lastSeek:Number = -1;
		private var videoTime:Number = 0;
		private var inputValue:Number = 0;
		private var minSeek:Number = 0.01;
		private var my_nc:NetConnection;
		private var my_ns:NetStream;
		private var videoStartTimer:Timer;
		private var seekTimer:Timer = new Timer(60, 0);
		//sensorValue = 0;
		
		
		// instances of objects on the Flash stage
		//
		// input fields
		
		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sVideoBehavior:TextField;
		public var sVideoState:TextField;
		public var sVideoName:TextField;
		
		// buttons

		
		// objects
		public var videoObject:Video;
		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters

			// set the name used in the parameters XML

			// go

			// init vars
			
			
			// find the video object the user set up
			videoObject = Video(parseNameSpace(videoObjectName, parent));
			if (videoObject == null) {
				// bad video object name
				trace('--->BAD NAME FOR VIDEO OBJECT (' + videoObjectName + '): Check the spelling and video instance name');
			} else { 
				// set up the video
				
				// Create a NetConnection object
				my_nc = new NetConnection();
				// Create a local streaming connection
				my_nc.connect(null);
				// Create a NetStream object and define an onStatus() function
				my_ns = new NetStream(my_nc);
	
				my_ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler); 

				// Attach the NetStream video feed to the Video object
				videoObject.attachNetStream(my_ns);
				// Set the buffer time
				//my_ns.bufferTime(10);
	
				// set up for metadata callback
				videoClient.onMetaData = videoMetaData;
				//videoClient.onCuePoint = videoCuePoint;
				my_ns.client = videoClient;
				
				// set up status handling
				my_ns.addEventListener(NetStatusEvent.NET_STATUS, netstatus);
	 

				
				if (videoBehavior == "pause" || videoBehavior.indexOf("restart") == 0) {
					videoStartTimer = new Timer(500,1);
					videoStartTimer.addEventListener(TimerEvent.TIMER, initVideoFileName);
					videoStartTimer.start();
				} else { // Begin playing the FLV file if in time or speed modes
					my_ns.play(videoFileName);
					my_ns.pause();
					my_ns.seek(0);
					currentlyPlaying = "playing";
					sVideoState.text = currentlyPlaying;
				}
				
				// set up the enterframehandler if the property is speed
				if (videoBehavior == "speed" || videoBehavior == "time") {
					//this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
					seekTimer.addEventListener(TimerEvent.TIMER, seekTimeUpdate);
					seekTimer.start();
				}
			}
		
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
		}
		
		private function initVideoFileName(event:TimerEvent) {
			nextVideoFileName(); // sets new filename from a ListItems widget if listItemName is set
			// make sure the video shows
			my_ns.play(videoFileName);
			my_ns.pause();
			my_ns.seek(0);
		}
		
		//private function enterFrameHandler(e:Event) {
		private function seekTimeUpdate(event:TimerEvent) {
			// only used if videoBehavior is speed or time
			if (videoDuration != 0) {
				
				
				if (videoBehavior == "speed") {
					var timePassed = getTimer() - lastTime; // get how much time passed in milliseconds
					var speed = ((inputValue / 100.00) * timePassed) / 1000.00; // 100 is normal speed
					//trace(speed);
					//trace("speed: " + videoTime + " " + my_ns.videoDuration);
					//trace(videoTime);
					if (Math.abs((videoTime + speed) - lastSeek) > minSeek) {
						lastTime = getTimer();
						videoTime += speed;
						if (videoTime > videoDuration) {
							if (!loopVideo) videoTime = videoDuration;
							else videoTime = 0;
						}
						if (videoTime < 0) {
							if (!loopVideo) videoTime = 0;
							else videoTime = videoDuration;
						}
						
						my_ns.seek(videoTime);
						lastSeek = videoTime;
						
						if (inputValue != 0 && currentlyPlaying != "playing") {
							currentlyPlaying = "playing";
							sVideoState.text = currentlyPlaying;
						} else if (inputValue == 0 && currentlyPlaying != "paused"){
							currentlyPlaying = "paused";
							sVideoState.text = currentlyPlaying;
						}
					}
					
					

				} else if (videoBehavior == "time") {
					var theTime;
					if (videoDuration != 0) {
						theTime = inputValue * 0.0333333333 // 30 fps 0.033366700033 is a 29.97 frame
						
						if (Math.abs(theTime - lastSeek) > minSeek) {
						
							if (loopVideo) {
								theTime = Math.abs(theTime % videoDuration);
							}
							my_ns.seek(theTime);
							lastSeek = theTime;
						}
					}
				}
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
				trace("Can't find video file: " + videoFileName);
			}

			if (statusCode == "NetStream.Play.Stop") {
				// to handle case where looping is on
				if (loopVideo && (videoBehavior == "pause" || videoBehavior.indexOf("restart") == 0)) {
					//trace("restarting");
					my_ns.play(videoFileName);
				} else {
					sVideoState.text = currentlyPlaying = "stopped";
				}
			}
			
			
			
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			inputValue = event.netFeedValue;
			if (isNaN(inputValue)) inputValue = 0; 
			sInputValue.text = String(Math.round(inputValue));
			
			var theTime;
			var lastValue = inputValue;

			switch (videoBehavior) {
				case "time" :
					// handle time in seekTimeUpdate
					break;
				case "speed" :
					// handle speed in seekTimeUpdate so speed continues regardless of if there are changes in sensorValue
					break;
					
				case "pause" :
				case "restart" :
					// play the movie if input value greater than the threshold (default = 500)
					if (inputValue >= threshold && currentlyPlaying == "stopped") {
						//trace("start play");
						my_ns.play(videoFileName);
						currentlyPlaying = "playing";
					} else if (inputValue >= threshold && currentlyPlaying == "paused") {
						//trace("restart play");
						if (videoBehavior == "restart") {
							my_ns.play(videoFileName);
						} else if (videoBehavior == "pause") {
							my_ns.resume();
						}
						currentlyPlaying = "playing";
					} else if (inputValue < threshold && currentlyPlaying == "playing") {
						//trace("start pause");
						my_ns.pause();
						currentlyPlaying = "paused";
						nextVideoFileName();
					}
					sVideoState.text = currentlyPlaying;
					break;
					
				case "restartPlayToEnd" :
				case "restartPlayToEndInterrupt" :
				// play the movie if input value greater than the threshold (default = 500)
					if (inputValue >= threshold && (currentlyPlaying == "stopped" || currentlyPlaying == "paused" || currentlyPlaying == "waitThreshold")) {
						my_ns.play(videoFileName);
						currentlyPlaying = "playing";
					}
					if (inputValue < threshold && currentlyPlaying == "playing") {
						if (videoBehavior == "restartPlayToEnd") currentlyPlaying = "waitToEnd";
						else if (videoBehavior == "restartPlayToEndInterrupt") currentlyPlaying = "waitThreshold";
						nextVideoFileName();
					}
					sVideoState.text = currentlyPlaying;
					break;
					
			}
		
		}
		
		public function nextVideoFileName():void {
			if (listItemName != "none" && videoBehavior.indexOf("restart") == 0) {
				videoFileName = parseNameSpace(listItemName, parent).nextItem();
			}
		}
		
		public function setVideoFilename(filename:String):void {
			videoFileName = filename;
			currentlyPlaying = "stopped";
			sVideoState.text = currentlyPlaying;
			if (videoBehavior == "time" || videoBehavior == "speed") playVideo(inputValue); // if time or speed get started again so new video shows
		}
		
		public function playVideo(newInputValue:Number = -100000) {
			if (currentlyPlaying == "paused") {
				if (videoBehavior.indexOf("restart") == 0) {
					my_ns.play(videoFileName);
				} else if (videoBehavior == "pause") {
					my_ns.resume();
				}
			} else if (currentlyPlaying == "stopped") {
				my_ns.play(videoFileName);
				if (videoBehavior == "time" || videoBehavior == "speed") my_ns.pause();
				if (videoBehavior == "time") my_ns.seek(0);
			}
			
			if (videoBehavior == "speed") {
				trace(newInputValue);
				if (newInputValue != -100000) inputValue = newInputValue;
				else inputValue = 100;
				sInputValue.text = String(inputValue);
			}
			if (videoBehavior == "time" && newInputValue != -100000) {
				inputValue = newInputValue;
				//setTimeProperty(inputValue);
				sInputValue.text = String(inputValue);
			}
				
			currentlyPlaying = "playing";
			sVideoState.text = currentlyPlaying;
		}
		
		public function pauseVideo() {
			if (videoBehavior == "pause" || videoBehavior.indexOf("restart") == 0 || videoBehavior == "speed") {
				my_ns.pause();
				inputValue = 0;
				sInputValue.text = String(inputValue);
				currentlyPlaying = "paused";
				sVideoState.text = currentlyPlaying;
			}
		}
		
		private function asyncErrorHandler(event:AsyncErrorEvent):void { 
			// ignore error 
		} 
				
		
		
		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			sVideoName.text = videoFileName;
			sVideoBehavior.text = videoBehavior;
			
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _loopVideo:Boolean = true;
		[Inspectable (name = "loopVideo", variable = "loopVideo", type = "Boolean", defaultValue=true)]
		public function get loopVideo():Boolean { return _loopVideo; }
		public function set loopVideo(value:Boolean):void {
			_loopVideo = value;
			//draw();
		}		
		
		private var _videoObjectName:String = "video1";
		[Inspectable (name = "videoObjectName", variable = "videoObjectName", type = "String", defaultValue="video1")]
		public function get videoObjectName():String { return _videoObjectName; }
		public function set videoObjectName(value:String):void {
			_videoObjectName = value;
			//draw();
		}		
		
		private var _videoFileName:String = "none.flv";
		[Inspectable (name = "videoFileName", variable = "videoFileName", type = "String", defaultValue="none.flv")]
		public function get videoFileName():String { return _videoFileName; }
		public function set videoFileName(value:String):void {
			_videoFileName = value;
			draw();
		}		
		
		private var _listItemName:String = "none";
		[Inspectable (name = "listItemName", variable = "listItemName", type = "String", defaultValue="none")]
		public function get listItemName():String { return _listItemName; }
		public function set listItemName(value:String):void {
			_listItemName = value;
			draw();
		}		
				
		private var _videoBehavior:String = "pause";
		[Inspectable (name = "videoBehavior", variable = "videoBehavior", type = "String", enumeration="time,speed,pause,restart,restartPlayToEnd,restartPlayToEndInterrupt", defaultValue="pause")]
		public function get videoBehavior():String { return _videoBehavior; }
		public function set videoBehavior(value:String):void {
			_videoBehavior = value;
			draw();
		}
		
		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
			//draw();
		}
	}
}
