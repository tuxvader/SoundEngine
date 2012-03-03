package net.icecubegames.sound 
{
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	
	public class SoundEngine
	{
		
		private var _sounds:Array;
		private var soundChannels:Array;
		private var soundMute:Boolean = false;
		private var tempSoundTransform:SoundTransform = new SoundTransform();
		private var muteSoundTransform:SoundTransform = new SoundTransform();
		private var tempSound:Sound;
		
		private var _queuedSound:Vector.<GameSound>;
		
		private static var instance:SoundEngine;
		
		/**
		 * Obtains the only instance of SoundEngine
		 * @return SoundEngine
		 */
		public static function get Instance():SoundEngine
		{
			if (instance == null) { instance = new SoundEngine(new SingletonKey()); }
			return instance;
		}
		
		public function SoundEngine(pKey:SingletonKey) 
		{
			_sounds = new Array();
			_queuedSound = new Vector.<GameSound>();
			soundChannels = new Array();
		}
		
		/**
		 * Add a new sound to the sound list
		 * @param	sound Object with the sound and the sound info
		 */
		public function addSound(sound:GameSound):void
		{
			_sounds[sound.Name] = sound
		}
		
		/**
		 * return the state of the sound
		 * @param soundName Name of the sound of with we want to know it's state
		 * @return int representing the state of the sound, the enum is defined in the class GameSound
		 */
		public function soundCurrentState(soundName:String):int
		{
			var aGameSound:GameSound = _sounds[soundName];
			
			if (aGameSound)
			{
				return aGameSound.currentState;
			}
			return GameSound.STOPPED;
		}
		
		/**
		 * Return the previous state of the sound
		 * @param soundName Name of the sound of with we want to know it's state
		 * @return int representing the state of the sound, the enum is defined in the class GameSound
		 */
		public function soundPreviousState(soundName:String):int
		{
			var aGameSound:GameSound = _sounds[soundName];
			
			if (aGameSound)
			{
				return aGameSound.previousState;
			}
			return GameSound.STOPPED;
		}
		
		/**
		 * Add an event listener to the complete event of the sound
		 * @param soundName Name of the sound that we want to add the listener
		 * @param callback function that will be called when the event is fired, the function must take a param of type Event
		 */
		public function addSoundCompleteListener(soundName:String, callback:Function):void
		{
			var aGameSound:GameSound = _sounds[soundName];
			
			if (aGameSound)
			{
				aGameSound.addEventListener(Event.SOUND_COMPLETE, callback, false, 0, true);
			}
		}
		
		/**
		 * Play the selected sound, this must be added to the engine before
		 * @param	soundName The name of the sound
		 * @param	playInParallel if true, the engine can play the same sound at the same time
		 * @param   queued add the selected sound to a queue to play them in order one after the other
		 * @param   fadeIn If true the sound will tween its volume from 0 to the sound configured in the GameSound
		 */
		public function playSound(soundName:String, playInParallel:Boolean = false, queued:Boolean = false, fadeIn:Boolean = false ):void
		{
			try
			{
				var aGameSound:GameSound = (_sounds[soundName] as GameSound);
				if (aGameSound != null)
				{
					if (playInParallel)
					{
						var auxGameSound:GameSound = new GameSound(aGameSound.Name, aGameSound.CurrentSound, aGameSound.Volume, aGameSound.Loops, aGameSound.Enabled);
						aGameSound.playInParallel(auxGameSound,fadeIn);
					}
					else if (queued)
					{
						aGameSound.addEventListener(Event.SOUND_COMPLETE, onQueuedSoundComplete);
						if (_queuedSound.length == 0)
						{
							_queuedSound.push(aGameSound);
							aGameSound.Play(fadeIn);
						}
						else
						{
							_queuedSound.push(aGameSound);
						}
						
					}
					else
					{
						aGameSound.Play(fadeIn);
					}
				}
			}
			catch (ex:Error)
			{
				trace(ex.message);
			}
		}
		
		/**
		 * Change the volume of the selected Sound
		 * @param volume The volume we want to set to the sound. Must be between 0 and 1
		 * @param soundName The name of the sound
		 * @param fade If true the volume will tween from the current volume to the new volume 
		 */
		public function changeVolume(volume:Number, soundName:String, fade:Boolean = false):void
		{
			(_sounds[soundName] as GameSound).changeVolume(volume,fade);
		}
		
		/**
		 * Pause the selected sound
		 * @param soundName The name of the sound we want to pause
		 * @param fadeOut If true the sound will tween from current sound to 0
		 */
		public function pauseSound(soundName:String,fadeOut:Boolean=false):void
		{
			var aGameSound:GameSound = (_sounds[soundName] as GameSound);
			if (aGameSound != null)
			{
				aGameSound.Pause(fadeOut);
			}
			
		}
		
		/**
		 * Stop the sound
		 * @param	soundName soundName The name of the sound that we want to stop
		 */
		public function stopSound(soundName:String,fadeOut:Boolean=false, fadeOutSeconds:Number=10):void
		{
			var aGameSound:GameSound = (_sounds[soundName] as GameSound);
			if (aGameSound != null)
			{
				aGameSound.Stop(fadeOut,fadeOutSeconds);
			}
		}
		
		/**
		 * Stop all sounds
		 */
		public function stopAllSounds(fadeOut:Boolean = false, fadeOutSeconds:int = 10 ):void
		{
			for each(var s:GameSound in _sounds)
			{
				s.Stop(fadeOut,fadeOutSeconds);
			}
		}
		
		/**
		 * Mute sound
		 * @param soundName The name of the sound we want to mute
		 */
		public function muteSound(soundName:String):void
		{
			(_sounds[soundName] as GameSound).mute();
		}
		
		/**
		 * UnMute sound
		 * @param soundName The name of the sound we want to unmute
		 */
		public function unMuteSound(soundName:String):void
		{
			(_sounds[soundName] as GameSound).unMute();
		}
		
		/**
		 * Mute/UnMute all sounds
		 * @param on If true UnMute all sounds, else mute all sounds
		 */
		public function mute(on:Boolean):void 
		{
			for (var name:String in _sounds) 
			{
				if (on)
				{
					(_sounds[name] as GameSound).mute();
				}
				else
				{
					(_sounds[name] as GameSound).unMute();
				}
			}
		}
		
		private function onQueuedSoundComplete(e:Event):void 
		{
			var aGameSound:GameSound = e.target as GameSound;
			if (aGameSound) { aGameSound.removeEventListener(Event.SOUND_COMPLETE, onQueuedSoundComplete); }
			
			var auxGameS:GameSound;
			
			do 
			{
				auxGameS = 	_queuedSound.shift()
			}while (auxGameS == aGameSound);
			
			aGameSound = auxGameS;
			if (aGameSound)
			{
				aGameSound.addEventListener(Event.SOUND_COMPLETE, onQueuedSoundComplete, false, 0, true);
				aGameSound.Play(false);
			}
		}
	}

}

class SingletonKey
{
	
}