﻿package { 

	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	import flash.net.URLLoader;
    import flash.net.URLRequest;
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
	
	public class ListItems extends WidgetBase { 
		
		// vars

		
		// buttons
		
		
		// working variables
		public var listOriginal:Array;
		public var listOrdered:Array;
		public var listIndex:Number;
		private var myTextLoader:URLLoader = new URLLoader();
		private var lastItem:String = "";
		private var lastIndex:int;
		//private var displayLast:String = "";
		//private var displayNext:String = "";
		
		// instances of objects on the Flash stage
		//
		// fields
		public var sListOrder:TextField;
		public var sLast:TextField;
		public var sNext:TextField;
		public var itemLastIndex:TextField;
		public var itemNextIndex:TextField;
		// buttons

		
		// objects


		
		// inherit constructor, so we don't need to create one
		//public function AnalogInput(w:Number = NaN, h:Number = NaN) {
			//super(w,h);
		//} 
		
		
		// functions
		
		override public function setupAfterLoad( event:Event ): void {
			super.setupAfterLoad(event);
			
			// get list from the file and build the ordered list
			readFile(listFileName)
			
		}
		
		public function readFile (fileName:String): void {
			myTextLoader.addEventListener(Event.COMPLETE, onFileLoaded);
			myTextLoader.load(new URLRequest(fileName));
		}
		
		private function onFileLoaded(e:Event):void {
			listOriginal = (e.target.data).split(delimiter);
			trace("ListItems (" + this.name + ") loaded " + listOriginal.length + " items from " + listFileName);
			
			// trim all the items
			for (var i:int=0;i<listOriginal.length;i++) {
				listOriginal[i] = trim(listOriginal[i],false);
			}
			buildOrderedList();
			calcNextItem();
		}
		
		// user functions
		//
		
		public function nextItem(): String {
			var returnItem:String = lastItem;
			calcNextItem();
			return returnItem;
		}
		
		// return item at requested index from ordered list
		public function item(item:int): String {
			if (item >= 0 && item < listOriginal.length) {
				return listOriginal[item];
			} else return "";
		}
		
		public function itemOrdered(item:int): String {
			if (item >= 0 && item < listOrdered.length) {
				return listOrdered[item];
			} else return "";
		}
		
		public function itemCount():Number {
			return listOrdered.length;
		}
		
		public function itemIndex(item:String = null):Number {
			if (item != null) { // get index of named item
				return listOriginal.indexOf(item);
			} else { // give the index of the last item provided
				return listOriginal.indexOf(sLast.text);
			}
		}
		
		public function itemIndexOrdered(item:String = null):Number {
			if (item != null) { // get index of named item
				return listOrdered.indexOf(item);
			} else { // give the index of the last item provided
				return listOrdered.indexOf(sLast.text);
			}
		}
				
		// end user functions
		
		public function calcNextItem(): String {
			var returnItem:String = null;
				
			switch (listOrder) {
				// ordered,ordered_reverse,random,random_norepeat,random_full_list
				case "ordered":
				case "ordered_reverse":
				case "random_full_list":
					returnItem = listOrdered[listIndex];
					listIndex++;
					if (listIndex >= listOrdered.length) {
						listIndex = 0;
						if (listOrder == "random_full_list") { // re-randomize the array, making sure the first item in the new array is not the last in the previous one
							listOrdered = randomizeArray(listOriginal, listOrdered[listOrdered.length - 1]);
						}
					}
					break;
				
				case "random":
					listIndex = Math.floor(Math.random()*listOrdered.length);
					returnItem = listOrdered[listIndex];
					break;
				case "random_norepeat":
					returnItem = lastItem;
					while(returnItem == lastItem) {
						listIndex = Math.floor(Math.random()*listOrdered.length);
						returnItem = listOrdered[listIndex];
					};
					break;
			}
			
			sLast.text = lastItem;
			sNext.text = returnItem;
			
			itemLastIndex.text = String(itemIndex(lastItem));
			itemNextIndex.text = String(itemIndex(returnItem));

			lastItem = returnItem;
			
			return returnItem;
		}
		
		public function buildOrderedList (): void {
			//trace(listOrder);
			//listOrdered = listOriginal;
			// switch based on order type
			switch (listOrder) {
				// ordered,ordered_reverse,random,random_norepeat,random_full_list
				case "ordered":
				case "random":
				case "random_norepeat":
					listOrdered = listOriginal;
					break;
					
				case "ordered_reverse":
					listOrdered = listOriginal.concat();
					listOrdered.reverse();
					break;
				
				case "random_full_list":
					listOrdered = randomizeArray(listOriginal);
					break;
			}
			
			listIndex = 0;
			//trace(listOrdered);
		}
		
		private function randomizeArray($array:Array, notFirst = null):Array {
			var returnArray:Array = new Array();
			var orgArray:Array = $array.slice();
			var orgLength:uint = orgArray.length;
			var r:uint;
			var checkNotFirst:String = notFirst;
			
			while (orgArray.length > 0) {
				if (orgArray.length == orgLength && notFirst != null) {
					while (checkNotFirst == notFirst) {
						r = Math.floor(Math.random()*orgArray.length);
						checkNotFirst = orgArray[r];
						//trace("notfirst");
					}
				} else r = Math.floor(Math.random()*orgArray.length);
				returnArray.push(orgArray.splice(r, 1)[0]);
			}
			return returnArray;
		}
		
		
		
		private function fixSpecialChars(theString:String) {
			var myPattern:RegExp = /\\n/g;
			var fixedValue:String;
			fixedValue = theString.replace(myPattern, "\n"); 
			//trace("delim" + fixedValue);
			
			myPattern = /\\r/g;
			fixedValue = fixedValue.replace(myPattern, "\r");

			return fixedValue;
		}
		
		override public function draw():void {
			super.draw();
			sListOrder.text = listOrder;
			
		}
		//----------------------------------------------------------
		// parameter getter setter functions
		
		private var _listFileName:String = "list.txt";
		[Inspectable (name = "listFileName", variable = "listFileName", type = "String", defaultValue="list.txt")]
		public function get listFileName():String { return _listFileName; }
		public function set listFileName(value:String):void {
			_listFileName = value;
			draw();
		}		
		
		private var _listOrder:String = "ordered";
		[Inspectable (name = "listOrder", variable = "listOrder", type = "String", enumeration="ordered,ordered_reverse,random_full_list,random_norepeat,random", defaultValue="ordered")]
		public function get listOrder():String { return _listOrder; }
		public function set listOrder(value:String):void {
			_listOrder = value;
			draw();
		}		
		
		private var _delimiter:String = ",";
		[Inspectable (name = "delimiter", variable = "delimiter", type = "String", defaultValue=",")]
		public function get delimiter():String { return fixSpecialChars(_delimiter); }
		public function set delimiter(value:String):void {
			_delimiter = value;
			draw();
		}
	}
}
