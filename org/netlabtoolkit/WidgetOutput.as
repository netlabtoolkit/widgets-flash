package org.netlabtoolkit { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	import flash.utils.*;
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
	
	public class WidgetOutput extends Widget	{ 

		// vars
		//public var hubIP:Number = 51000;
		public var theConnection:SocketConnection;
		public var fileConnection:SocketConnectionParams;
		
		// working variables 
		
		public var connectionComplete:Boolean = false;
		
		// delay connection
		private var connectDelayTimer:Timer;
		private var randomDelay:int;
	
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);	
		}
				
		public function handleButton(buttonType:String, buttonState:String) {
			if (buttonType == "connect") {
				if (buttonState == "on") tryConnect();
				else if (buttonState =="off") disConnect();
			}
		}
		
		public function tryConnect():void {
				
			//trace("name: " + paramsXMLname);
			// set up connection to controller
			if (mobileSetupComplete || deviceType != "mobile") {
				if (theConnection == null) theConnection = new SocketConnection(this.name, remotehubIP, hubPort, this);
				theConnection.openConnection();
			} else {
				thisWidget.connectButton.setState("off");
				trace("can't connect until MobileControl is set");
			}
		}
		
		public function disConnect(): void {
			if (theConnection != null) theConnection.closeConnection();
		}
		
		public function processData( data:String): void {
			
			//trace("the data: " + data);
			
			var theValue = data.split(" ")[1];
			if (theValue.indexOf("OK") >=0) {
				if (data.indexOf("/service/arduino") >=0 || data.indexOf("/service/xbee") >=0 || data.indexOf("/service/tools/serial") >=0) getHubDevice(data);
				else hubDeviceName = "";
				finishConnect();
			} else if (theValue.indexOf("FAIL") >=0) {
				disConnect();
				failConnect(data);
			} else trace("Unexpected data from output controller: " + data);
		}
		
		override public function finishConnect() {
			connectionComplete = true;
			//trace("..." + this.name + " connected");
			//trace("..." + this.name + " connected to Hub device #" + hubDeviceNumber);
			super.finishConnect();
		}
		
				
		//----------------------------------------------------------
		// parameter getter setter functions
			
		// parameters
		
	}
}
