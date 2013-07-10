package org.netlabtoolkit {
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.*;
	import flash.events.DataEvent;
	import flash.net.XMLSocket;
	
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

	public class SocketConnection extends Sprite {
  
  
		private var connectionId:String;
		private var hubIP:String = "localhost";
		private var hubPort:int = 51000;
		private var dataConsumer:MovieClip;
		private var connectDelayTimer:Timer;
		private var randomDelay:int;
		
		private var xmlSocket:XMLSocket;
	  
		public function SocketConnection(connectionId, hubIP, hubPort, dataConsumer) {
			
			this.connectionId = connectionId;
			this.hubIP = hubIP;
			this.hubPort = hubPort;
			this.dataConsumer = dataConsumer;
			
			randomDelay = Math.round((Math.random() * 1000) + 1000);
			connectDelayTimer = new Timer(randomDelay, 1);
			connectDelayTimer.addEventListener(TimerEvent.TIMER, finishConnect);
			
			
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
			trace("Widget '" + connectionId + "' connecting...");
			//connectDelayTimer.start();
			dataConsumer.initControllerConnection();
			
		}
		
		public function finishConnect(event:TimerEvent) {
			//trace("finishConnect");
			dataConsumer.initControllerConnection();
		}
	
		private function processData( event:DataEvent ):void {
	 
			dataConsumer.processData(event.data);
		  
		}
		
		private function onClose( event:Event ) {
			trace(connectionId + " connection closed");
		}
								 
		private function onError( event:Event ) : void {
			trace(connectionId + " Error Connecting ---> IS THE NETLAB HUB RUNNING?");
		}
		
		public function openConnection() : void {
			// connect to the server, complete connection with onConnect function
			if ( !xmlSocket.connected ) xmlSocket.connect( hubIP, hubPort );
		}
		
		public function sendData(theData:String) : void {
			xmlSocket.send(theData + "\n");
		}
		
		public function closeConnection( ) : void {
			if ( xmlSocket.connected ) xmlSocket.close();
		}
	}
}







