package org.netlabtoolkit {

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
	
	public class EnvelopeObj {
  
		
		public var minLevel:Number;
		public var maxLevel:Number;
		public var fadeInStart:Number;
		public var fadeInEnd:Number;
		public var fadeOutStart:Number;
		public var fadeOutEnd:Number;
		private static const DEFAULT_VALUE:int = int.MIN_VALUE;
		
		public function EnvelopeObj(minLevelIn:Number = 0.0, maxLevelIn:Number = 1.0, fadeInStartIn:Number = 1, fadeInEndIn:Number = 400, fadeOutStartIn:Number = 800, fadeOutEndIn:Number = 1023 ) {
			
			minLevel = minLevelIn;
			maxLevel = maxLevelIn;
			fadeInStart = fadeInStartIn;
			fadeInEnd = fadeInEndIn;
			fadeOutStart = fadeOutStartIn;
			fadeOutEnd = fadeOutEndIn;
			
		}
		
		public function envelopeLevel(inputLevel:Number, minLevelIn:Number = DEFAULT_VALUE, maxLevelIn:Number = DEFAULT_VALUE, fadeInStartIn:Number = DEFAULT_VALUE, fadeInEndIn:Number = DEFAULT_VALUE, fadeOutStartIn:Number = DEFAULT_VALUE, fadeOutEndIn:Number = DEFAULT_VALUE ): Number {
			
			if (minLevelIn != DEFAULT_VALUE) minLevel = minLevelIn;
			if (maxLevelIn != DEFAULT_VALUE) maxLevel = maxLevelIn;
			if (fadeInStartIn != DEFAULT_VALUE) fadeInStart = fadeInStartIn;
			if (fadeInEndIn != DEFAULT_VALUE) fadeInEnd = fadeInEndIn;
			if (fadeOutStartIn != DEFAULT_VALUE) fadeOutStart = fadeOutStartIn;
			if (fadeOutEndIn != DEFAULT_VALUE) fadeOutEnd = fadeOutEndIn;
		
			var levelRange:Number = maxLevel - minLevel;
			var newLevel:Number = minLevel;
			var fadeInScale:Number = levelRange/(fadeInEnd - fadeInStart);
			var fadeOutScale:Number = levelRange/(fadeOutEnd - fadeOutStart);
			
			//var triggerStartStop;
	  
			if (inputLevel < fadeInStart) { 
				// below range of envelope
				newLevel = minLevel;
				//triggerStartStop = "stop";
			}
			else if (inputLevel >= fadeInStart && inputLevel <= fadeInEnd) { 
				// in the fade-in ramp
				newLevel = ((inputLevel - fadeInStart) * fadeInScale) + minLevel;
				//triggerStartStop = "start";
			}
			else if (inputLevel > fadeInEnd && inputLevel < fadeOutStart) { 
				// in the full volume area
				newLevel = maxLevel;
				//triggerStartStop = "start";
			}
			else if (inputLevel >= fadeOutStart && inputLevel <= fadeOutEnd) { 
				// in the fade-out ramp
				newLevel = maxLevel - ((inputLevel - fadeOutStart) * fadeOutScale);
				//triggerStartStop = "start";
			}
			else { 
				// above the range of the envelope
				newLevel = minLevel;
				//triggerStartStop = "stop";
			}
			
			return newLevel;
		}
	}
}
