package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.errors.IOError; 
	import flash.text.TextField;
	import flash.media.Sound;
    import flash.media.SoundChannel;
	import flash.media.SoundTransform;
    import flash.net.URLRequest;
	import flash.utils.getDefinitionByName;
	import flash.utils.Timer;
	import flash.geom.Rectangle;

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
	
	public class SoundControl extends Widget { 
	
		public static const SOUND_NAME_DEFAULT = "defaultSound";

		// vars
		
		// buttons
		public var outputStateButton:ToggleButton;
		
		// working variables 
		public var theKnob:Knob;
		private var knobRectangle:Rectangle;
		//private var envelope:EnvelopeObj;
		public var knobRange:int = 100;
		private var knobScale:Number;
		private var normalizeSound:Number = 1/512;
		private var soundVolMin:Number = 0;
		private var soundVolMax:Number = 1023;
		private var soundRange:Number = soundVolMax;
		private var soundRangeScale:Number = soundRange / 1023;
		private var sound:Sound;
		private var channel:SoundChannel;
		private var transformSound:SoundTransform;
		private var pauseTime:int;
		private var lastVol:Number;
		private var lastPan:Number;
		private var lastThresholdInput:Number;
		private var soundPlaying:Boolean = false;
		private var loopAmount:int;
		private var soundInit:Boolean = false;
		private var soundStartTimer:Timer;
		private var restart:Boolean;
		private var restartPending:Boolean;
		private var triggerStartStop:String;
		private var firstListItem:Boolean = true;
		
		
		// instances of objects on the Flash stage
		//
		// input fields
		public var sVol:TextField;
		public var sPan:TextField;
		//public var sMaxVol:TextField;
		
		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sSoundName:TextField;
		
		// buttons
		public var outputState:MovieClip;
		
		// objects
		public var knob:MovieClip;
		public var theLine:MovieClip;
		
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
			//paramsList.push(["sMinVol", "0.0", "text"]);
			//paramsList.push(["sMaxVol", "1.0", "text"]);
			
			// set the name used in the parameters XML
			//paramsXMLname = "SoundControl_" + this.name;
			
			// go
			//setupParams();
			
			// set up the buttons
			outputStateButton = new ToggleButton(outputState, this, "outputState");
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			knobScale = (soundVolMax - soundVolMin)/knobRange;
			
			// kick off a timer so sound is set up and started after everything else settles
			soundInit = false;
			soundStartTimer = new Timer(500,1);
			soundStartTimer.addEventListener(TimerEvent.TIMER, initSound);
			soundStartTimer.start();
			
			// init vars
			lastVol = -100;
			lastPan = -100;
			lastThresholdInput = -100;
			
			// set up the listener for the input source, and draw a line to it
			setUpInputSource();
			if (inputSourceVolume != "none") setUpInputSourceOther(inputSourceVolume,handleInputFeedVolume);
			if (inputSourcePan != "none") setUpInputSourceOther(inputSourcePan,handleInputFeedPan);
		}
		
		private function initSound(event:TimerEvent) {
			setUpSound();
		}
		
		private function setUpSound() {
			// trace("in setupsound");
			// check to see if they forgot to set up the name of the sound - if so, use the default from the library
			if (listItemName != "none" && listItemName != "") soundName = parseNameSpace(listItemName, parent).nextItem(); // get the sound name from the ListItems widget
	
			if (soundName == SOUND_NAME_DEFAULT) soundSource = "library";
			
			if (soundSource == "library") {
				//trace("loading sound from LIBRARY: " + soundName);
				try {
					var SoundClassReference:Class = getDefinitionByName(soundName) as Class;
					sound = new SoundClassReference();
					sound.addEventListener(IOErrorEvent.IO_ERROR, useDefaultSound); 
				} catch (err:Error) {
					useDefaultSound();
				}
			} else if (soundSource == "file") {
				//trace("loading sound from FILE: " + soundName);
				try {
					sound = new Sound(new URLRequest(soundName));
					sound.addEventListener(IOErrorEvent.IO_ERROR, useDefaultSound); 
				} catch (err:Error) {
					useDefaultSound();
				}
			}
			
			completeSoundSetup();
		}
		
		private function completeSoundSetup(): void {
			
			transformSound = new SoundTransform();
			//transformSound.volume = Number(sMinVol.text);
			//transformSound.volume = volume * normalizeSound; // 512 = 1.0
			setVolume(volume);
			//transformSound.pan = (pan * normalizeSound) - 1; // 512 = 0.0
			setPan(pan);
			
			sVol.text = String(volume);

			restart = false;
			restartPending = false;
				
			lastVol = transformSound.volume;
			pauseTime = 0;
			soundPlaying = false;
			if (loopSound) loopAmount = int.MAX_VALUE;
			else loopAmount = 1;
			
			positionKnob(volume);
			
			soundInit = true;
			startSound(0,loopAmount);
			if (soundBehavior != "continuous") {
				// stop the sound right away and wait until input is above threshold to start playing)
				channel.stop();
			} else soundPlaying = true;
			
			
		}
		
		private function useDefaultSound(errorEvent:IOErrorEvent = null): void {
			trace("--->CAN'T FIND SOUND : " + soundName + ", USING DEFAULT SOUND");
			soundName = SOUND_NAME_DEFAULT;
			soundSource = "library";
			var SoundClassReference:Class = getDefinitionByName(soundName) as Class;
			sound = new SoundClassReference();
			
			completeSoundSetup();
		}
		
		public function startSound(soundPosition:int, loops:int) {
			if (soundInit) {
				channel = sound.play(soundPosition, loops);
				channel.soundTransform = transformSound;
				channel.addEventListener(Event.SOUND_COMPLETE, soundDone);
			}
		}
		
		public function setVolume(newVolume:Number) {
			if (newVolume != lastVol) {
				if (newVolume >= 0) transformSound.volume = newVolume * normalizeSound; // 512 = 1.0
				else transformSound.volume = 0;
				if (soundInit) channel.soundTransform = transformSound;
				sVol.text = String(Math.round(newVolume));
				positionKnob(newVolume);
				lastVol = newVolume;
			}
		}
		
		public function setPan(newPan:Number) {
			if (newPan != lastPan) {
				if (newPan >= 0 && newPan <= 1023) transformSound.pan = (newPan * normalizeSound) - 1; // 512 = 0.0
				else transformSound.pan = 0; // center
				if (soundInit) channel.soundTransform = transformSound;
				sPan.text = String(Math.round(newPan));
				//positionKnob(newVolume);
				lastPan = newPan;
			}
		}
		
		private function soundDone (event:Event):void {
			trace("sound done ");
			/*
			if (autoRestart) {
				Sound(this).start();
				//trace("auto restart");
			} else restart = true;
			*/
			if (loopSound) startSound(0,loopAmount);
			else {
				soundPlaying = false;
				restart = true;
				pauseTime = 0;
				outputStateButton.setState("off");
				if (listItemName != "none") setUpSound(); 
			}
		}

		public function knobMove(position:Number): void {
			var newVolume = position*(knobScale);
			//trace("knob: " + position + "," + newRaw);
			setVolume(newVolume);
		}

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			sInputValue.text = String(inputValue);
			
			if (soundBehavior != "continuous") {
				triggerSoundProcess(inputValue);
			}

		}
		
		public function handleInputFeedVolume( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			
			setVolume(inputValue);
		}
		
		public function handleInputFeedPan( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			
			setPan(inputValue);
		}
		
		private function positionKnob(inputValue:Number):void {
			if (theKnob.dragging == false) {
				var newY = (theLine.y + knobRange) - (inputValue*(knobRange/soundRange));
				//trace(newY);
				knob.y = newY;
			}
		}
		
		public function triggerSoundProcess(thresholdInput:Number): void {
			
			
			// determine if the new threshold state is start or stop
			if (thresholdInput < threshold ) triggerStartStop = "stop";
			else { 
				// only start back up if we've been below threshold - prevents restart while still above threshold
				if (lastThresholdInput < threshold) { // if we've been below the threshold, trigger a start
					triggerStartStop = "start";
				} else if (!soundPlaying) { // if not, put us in the stop state only if the sound has finished playing
					triggerStartStop = "stop";
				}
			}
			lastThresholdInput = thresholdInput;
			
			if (restart && soundBehavior == "pause" && soundPlaying == true) {
				pauseTime = 0;
				restart = false;
				if (loopSound) {
					startSound(0,1);
					soundPlaying = true;
				} else {
					restartPending = true;
				}
			}
				
			if (triggerStartStop == "stop" && soundPlaying == true && soundBehavior != "restartPlayToEnd") { // stop the sound
				if (soundBehavior == "pause") {
					pauseTime = channel.position;
					channel.stop();
					if (listItemName != "none") setUpSound();
					//trace("pauseTime: " + pauseTime);
				} else if (soundBehavior != "restartPlayToEndInterrupt") {
					pauseTime = 0;
					channel.stop();
					if (listItemName != "none") setUpSound();
				} else pauseTime = 0;
				
				soundPlaying = false;
				 
			} else if (triggerStartStop == "start" && soundPlaying == false) { // start the sound if it is not already playing
				if (soundBehavior == "pause") {
					if (restartPending) {
						startSound(0,1);
						restartPending = false;
					} else {
						startSound(pauseTime,1); // or should the number of loops be 0?
					}
				} else {
					if (soundBehavior == "restartPlayToEndInterrupt") { // we're above the threshold, so stop the old playtoend and start new one
						channel.stop();
						if (listItemName != "none") setUpSound();
					}
					startSound(0,loopAmount);
				}
					
				soundPlaying = true;
			}
			
			if (soundPlaying) outputStateButton.setState("on");
			else outputStateButton.setState("off");
		}
		
		public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "outputState" && soundInit) {
				if (buttonState == "on") triggerSoundProcess(1023)
				else if (buttonState =="off") triggerSoundProcess(0);
			}
		}

		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			sSoundName.text = soundName;
			
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _loopSound:Boolean = true;
		[Inspectable (name = "loopSound", variable = "loopSound", type = "Boolean", defaultValue=true)]
		public function get loopSound():Boolean { return _loopSound; }
		public function set loopSound(value:Boolean):void {
			_loopSound = value;
			//draw();
		}		
		
		private var _soundName:String = SOUND_NAME_DEFAULT;
		[Inspectable (name = "soundName", variable = "soundName", type = "String", defaultValue="defaultSound")]
		public function get soundName():String { return _soundName; }
		public function set soundName(value:String):void {
			_soundName = value;
			draw();
		}		
		
		private var _soundSource:String = "file";
		[Inspectable (name = "soundSource", variable = "soundSource", type = "String", enumeration="file,library", defaultValue="file")]
		public function get soundSource():String { return _soundSource; }
		public function set soundSource(value:String):void {
			_soundSource = value;
			//draw();
		}		
		
		private var _soundBehavior:String = "restart";
		[Inspectable (name = "soundBehavior", variable = "soundBehavior", type = "String", enumeration="continuous,pause,restart,restartPlayToEnd,restartPlayToEndInterrupt", defaultValue="restart")]
		public function get soundBehavior():String { return _soundBehavior; }
		public function set soundBehavior(value:String):void {
			_soundBehavior = value;
			//draw();
		}		

		private var _pan:Number = 512;
		[Inspectable (name = "pan", variable = "pan", type = Number, defaultValue=512)]
		public function get pan():Number { return _pan; }
		public function set pan(value:Number):void {
			_pan = value;
			//draw();
		}
		
		private var _volume:Number = 512;
		[Inspectable (name = "volume", variable = "volume", type = Number, defaultValue=512)]
		public function get volume():Number { return _volume; }
		public function set volume(value:Number):void {
			_volume = value;
			//draw();
		}
		
		private var _listItemName:String = "none";
		[Inspectable (name = "listItemName", variable = "listItemName", type = "String", defaultValue="none")]
		public function get listItemName():String { return _listItemName; }
		public function set listItemName(value:String):void {
			_listItemName = value;
			draw();
		}
		
		private var _inputSourceVolume:String = "none";
		[Inspectable (name = "inputSourceVolume", variable = "inputSourceVolume", type = "String", defaultValue="none")]
		public function get inputSourceVolume():String { return _inputSourceVolume; }
		public function set inputSourceVolume(value:String):void {
			_inputSourceVolume = value;
			draw();
		}
		
		private var _inputSourcePan:String = "none";
		[Inspectable (name = "inputSourcePan", variable = "inputSourcePan", type = "String", defaultValue="none")]
		public function get inputSourcePan():String { return _inputSourcePan; }
		public function set inputSourcePan(value:String):void {
			_inputSourcePan = value;
			draw();
		}
		
		private var _threshold:Number = 500;
		[Inspectable (name = "threshold", variable = "threshold", type = "Number", defaultValue = 500)]
		public function get threshold():Number { return _threshold; }
		public function set threshold(value:Number):void {
			_threshold = value;
		}
	}
}
