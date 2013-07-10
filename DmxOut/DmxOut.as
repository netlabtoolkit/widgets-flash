package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.errors.IOError; 
	import flash.text.TextField;
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
	 * along with NETLab Flash Widgets.  If not, see <http://www.gnu.org/licenses/>.
	 */
	
	public class DmxOut extends WidgetOutput { 

		// vars
		
		// buttons
		public var connectButton:ToggleButton;
		
		// working variables 
		public var theKnob:Knob;
		private var knobRectangle:Rectangle;
		public var knobRange:int = 100;
		private var knobScale:Number;
		
		private var outputLevelMin:Number = 0;
		private var outputLevelMax:Number = 255;
		private var levelRange:Number = outputLevelMax - outputLevelMin;

		private var lastLevel:Number;
		
		// instances of objects on the Flash stage
		//
		// input fields

		// output fields
		public var sInputSource:TextField;
		public var sInputValue:TextField;
		public var sOutputPort:TextField;
		public var sOut:TextField;
		
		// buttons
		public var connect:MovieClip;
		
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
			
			// set up the buttons
			connectButton = new ToggleButton(connect, this, "connect");

			// PARAMETERS
			//
			
			// set up the defaults for this widget's parameters
			paramsList.push(["connectButton", "off", "button"]);

			
			// set the name used in the parameters XML
			paramsXMLname = "DmxOut_" + this.name;
			
			// go
			setupParams();
			
			// set up knob
			knobRectangle = new Rectangle(theLine.x,theLine.y,0,100);
			theKnob = new Knob(knob, knobRectangle, this);
			knobScale = (outputLevelMax - outputLevelMin)/knobRange;
			
			// init vars
			lastLevel = -100;
			
			setUpInputSource();

		}
		
	
		public function knobMove(position:Number): void {
			var newLevel = position*(knobScale);
			//trace("knob: " + position + "," + newRaw);
			sendOutput(newLevel);
		}
		
		public function initControllerConnection() {
			theConnection.sendData("/service/osc/reader-writer/connect " + mediaControlPort + " " + mediaControlIP);
			//theConnection.sendData("/service/osc/reader-writer/nlhubconfig/connect " + mediaControlIP + ":" + mediaControlPort + " " + String(mediaControlPort + 1));
		}
		
		public function sendOutput(outputValue) {
			sendDmx(outputValue);
		}
		
		public function sendDmx(outputValue:Number, customDmxChannel:Number = 0) {
			outputValue = Math.round(outputValue);
			customDmxChannel = Math.round(customDmxChannel);
			if (customDmxChannel > 0 && customDmxChannel <= 512 && dmxChannel != customDmxChannel) dmxChannel = customDmxChannel;
			if (connectButton.text == "on" && connectionComplete) {
				theConnection.sendData("/service/osc/reader-writer/" + mediaControlIP + ":" + mediaControlPort + "/mediacontrol/dmxout/data " + String(dmxChannel)+ " " + outputValue);
				//theConnection.sendData("/service/osc/reader-writer/mediacontrol/dmxout/data " + String(dmxChannel) + " " + outputValue);
			}
			sOut.text = String(outputValue);
		}
		
		override public function finishConnect() {
			super.finishConnect();
			// output initial value
			//sendOutput(Number(sOut.text));
		}

		
					// output initial value
			//sendOutput(Number(sOut.text));

		override public function handleInputFeed( event:NetFeedEvent ):void {
			//trace(this.name + ": " + event.netFeedValue + " " + event.widget.name);
			
			var inputValue = event.netFeedValue;
			sInputValue.text = String(inputValue);
			
			// constrain the value to min and max
			inputValue = Math.min(inputValue,outputLevelMax);
			inputValue = Math.max(inputValue,outputLevelMin);

			
						
			// set the knob position to reflect the input values processed through the envelope
			if (theKnob.dragging == false) {
				var newY = (theLine.y + knobRange) - (inputValue*(knobRange/levelRange));
				knob.y = newY;
			}
			
			
			if (inputValue != lastLevel) {
				sendOutput(inputValue);
				lastLevel = inputValue;
				//trace("newvol " + newVol);
			}
		}
		
		public function connectWidget():void {
			tryConnect();
			connectButton.setState("on");
		}
		
		public function disconnectWidget():void {
			disConnect();
			connectButton.setState("off");
		}

		
		override public function draw():void {
			super.draw();
			sInputSource.text = inputSource;
			sOutputPort.text = "DMX " + dmxChannel;
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions

		private var _dmxChannel:Number = 1;
		[Inspectable (name = "dmxChannel", variable = "dmxChannel", type = "Number", defaultValue = 1)]
		public function get dmxChannel():Number { return _dmxChannel; }
		public function set dmxChannel(value:Number):void {
			_dmxChannel = value;
			draw();
		}		

		private var _mediaControlIP:String = "127.0.0.1";
		[Inspectable (name = "mediaControlIP", variable = "mediaControlIP", type = "String", defaultValue = "127.0.0.1")]
		public function get mediaControlIP():String { return _mediaControlIP; }
		public function set mediaControlIP(value:String):void {
			_mediaControlIP = value;
			//draw();
		}		

		private var _mediaControlPort:Number = 51010;
		[Inspectable (name = "mediaControlPort", variable = "mediaControlPort", type = "Number", defaultValue = 51010)]
		public function get mediaControlPort():Number { return _mediaControlPort; }
		public function set mediaControlPort(value:Number):void {
			_mediaControlPort = value;
			draw();
		}
	}
}
