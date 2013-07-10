package org.netlabtoolkit {
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.events.DataEvent;
	import flash.net.XMLSocket;
	import org.netlabtoolkit.Globals;
	
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

	public class SocketConnectionParams extends Sprite {
  
  		public static const PARAMSCOMPLETE:String = "onParamsComplete";
  
		private var dataConsumer:MovieClip;
		private var connectionId:String;
		private var currentDir:String;
		private var currentFilename:String;
		private var hubIP:String = "localhost";
		private var hubPort:int = 51000;
		private var hubAlive:Boolean = false;

		private var xmlSocket:XMLSocket;
	  
		public function SocketConnectionParams(dataConsumer, currentDir, currentFilename, hubIP = "localhost") {
			
			this.dataConsumer = dataConsumer;
			this.connectionId = dataConsumer.name;
			this.currentDir = currentDir;
			this.currentFilename = currentFilename;
			this.hubIP = hubIP;
			
			xmlSocket = new XMLSocket();
		  
			// Connect listener to send a message to the server
			// after we make a successful connection
			xmlSocket.addEventListener( Event.CONNECT, onConnect );
		  
			// Connect listener to send a message to the server
			// after the connection is closed
			xmlSocket.addEventListener( Event.CLOSE, onClose );
		  
			// Listen for when data is received from the socket server
			xmlSocket.addEventListener( DataEvent.DATA, processData );
		  
			// Handle errors
			xmlSocket.addEventListener( IOErrorEvent.IO_ERROR, onError );
			
			
	
		}
		
		private function onConnect( event:Event ):void {
			//trace("sending file init");
			xmlSocket.send('/service/tools/file-io/base {' + currentDir + '}' + "\n");
			xmlSocket.send('/service/tools/file-io/filename {' + currentFilename + '.xml}' + "\n");
			xmlSocket.send("/service/tools/file-io/get" + "\n");
			if (dataConsumer.deviceType == "mobile") {
				if (dataConsumer.controlClip != null) dataConsumer.controlClip.mainButton.buttonText.text = "Connected";
				dataConsumer.mobileSetupComplete = true;
			}
		}
	
		private function processData( event:DataEvent ):void {
			// The Hub returns the command plus the file data. e.g. /service/tools/file-io/get {<NETCONNECT><ClipControl___id0_ propertySelector="x"/><AnalogInput___id1_ connectButton="on" smoothButton="off" easeButton="off" invertButton="off" sMin="0" sMax="1023" sFloor="0" sCeiling="1023"/></NETCONNECT>}
			var fileData:String = event.data.substr(event.data.indexOf(' ') + 1);
			//trace("filedata: " + fileData);
	 		var displayFilename = hubIP + ":" + currentFilename;
			if(fileData.indexOf('<HostError code="50') >= 0) { // file error
				if(fileData.indexOf('<HostError code="505') >= 0) { // file not found
					trace("--->no parameters file <" + displayFilename + ".xml>... setting defaults");
				} else {
					trace("--->parameters file error: " + displayFilename + ".xml, " + fileData  + " ... setting defaults");
				}
				
				Globals.vars.xmlParams = XML(<NETCONNECT></NETCONNECT>);

			} else {
				fileData = trimCurlyBraces(fileData);
				if (fileData.indexOf('<NETCONNECT>') == 0) {
					Globals.vars.xmlParams = XML(fileData);
					trace("--->initializing parameters from file <" + displayFilename + ".xml>");
					//trace(event.data);
				} else {
					trace("--->BAD parameters file <" + displayFilename + ".xml>... setting defaults");
					trace(fileData);
					Globals.vars.xmlParams = XML(<NETCONNECT></NETCONNECT>);
				}
			}
			
			hubAlive = true;
			dataConsumer.stage.dispatchEvent(new Event(SocketConnectionParams.PARAMSCOMPLETE));
			//dataConsumer.notifyParamSetup()
	 
		}
		
		private function onClose( event:Event ) {
			trace(connectionId + " connection closed");
		}
								 
		private function onError( event:Event ) : void {
			trace(connectionId + " Error Connecting ---> IS THE NETLAB HUB RUNNING?");
			
			if (dataConsumer.deviceType == "mobile") {
				trace("--->can't find Hub, check IP address in mobileControl");
				Globals.vars.fileConnection = undefined;
				dataConsumer.mobileSetupComplete = false;
				dataConsumer.controlClip.mainButton.buttonText.text = "Bad IP, Try Again";
			} else {
				trace("--->no HUB... setting default parameters");
				Globals.vars.xmlParams = XML(<NETCONNECT></NETCONNECT>);
				dataConsumer.stage.dispatchEvent(new Event(SocketConnectionParams.PARAMSCOMPLETE));
			}
		}
		
		public function openConnection() : void {
			// connect to the server, complete connection with onConnect function
			//trace("opening connection for params file: " + hubIP);
			xmlSocket.connect( hubIP, hubPort );
		}
		
		public function closeConnection( ) : void {
			if( xmlSocket.connected ) xmlSocket.close();
		}
		
		public function sendData(theData:String) : void {
			if (hubAlive) xmlSocket.send('/service/tools/file-io/put {' + theData + '}' + "\n");
		}
		
		public function trimCurlyBraces(inputStr:String) {
			var temp:String = inputStr;
			
			// check to see if the is a return character at the end of the string
			if (temp.indexOf("\n") == temp.length - 1) {
				temp = temp.substring(0,temp.length - 1);
			}
			
			var start:int = 0;
			var end:int = temp.length;
			
			// now trim off the curly braces if they are there
			if (temp.indexOf("{") == 0) start = 1;
			if (temp.indexOf("}") == end - 1) end -= 1;
			temp = temp.substring(start,end);
			return temp;
		}
	}
}







