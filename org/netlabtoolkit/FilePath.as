package org.netlabtoolkit {
	
	import flash.system.Capabilities;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	
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
	
	public class FilePath extends Sprite {
  
		public var currentDir:String;
		public var currentFilename:String;
		public var currentOS:String;
		public var filePrefix:String;
		private var myPattern:RegExp
	  
		public function FilePath(clip:MovieClip) {
			
			//currentOS = flash.system.Capabilities.os.substr(0, 3).toUpperCase();
			
			currentOS = flash.system.Capabilities.os
			currentOS = currentOS.substr(0, currentOS.indexOf(" ")).toUpperCase();

		
			var thisPath = unescape(clip.loaderInfo.url);
			//trace(thisPath);

			// get rid of the "file:///" or "app:/"
			if (thisPath.indexOf("file:///") == 0) {
				thisPath = thisPath.substr(8,thisPath.length);
				filePrefix = "file:///";
			} else if (thisPath.indexOf("app:/") == 0) {
				thisPath = thisPath.substr(5,thisPath.length);
				filePrefix = "app:/";
			} else {
				filePrefix = "noFilePrefix";
			}
			
			// check to see if the separators are "/" or "\"
			if (thisPath.indexOf("/") == -1) { // must be using "\" so switch it to "/"
				myPattern = /\\/g;  
				thisPath = thisPath.replace(myPattern, "/"); 
			}
			
			// get the filename
			currentFilename = thisPath.substr(thisPath.lastIndexOf("/") + 1,thisPath.length);
			currentFilename = currentFilename.substr(0,currentFilename.lastIndexOf("."));
			
			// get the directory
			currentDir = thisPath.substr(0,(thisPath.lastIndexOf("/") + 1));
			//currentDir = currentDir.substr(8,currentDir.length);

			if (currentOS == "IPHONE" || currentOS == "IOS" || filePrefix == "app:/") {
				currentDir = "./";
			} else if (currentOS == "MAC") {
							// flash provides different paths depending on if run within the flash app, or as a separate .swf in FlashPlayer
				var topDir = currentDir.substr(0,(currentDir.indexOf("/")));
				if (topDir == "Users" || topDir == "Volumes" || topDir == "Applications" || topDir == "") {
					if (currentDir.substr(0,1) != "/") currentDir = "/" + currentDir;
				} else currentDir = "/Volumes/" + currentDir;
			} else if (currentOS == "WIN" || currentOS == "WINDOWS"){
				// flash on windows reports the Drive name followed by a | character instead of a colon
				currentDir = currentDir.substr(0,1) + ":" + currentDir.substr(2,currentDir.length - 2);
			} else {
				currentDir = "./";
			}
			
			//var display = "thisDir: " + currentDir + " " + currentOS + " topdir: " + topDir + " file: " + currentFilename;
			//trace(display);
		}
	}
}







