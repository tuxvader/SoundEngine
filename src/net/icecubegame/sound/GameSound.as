package net.icecubegames.sound 
{
	import com.greensock.TweenLite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	[Event(name="soundComplete", type="flash.events.Event")]
	public class GameSound extends EventDispatcher
	{
		/*ENUM STATES*/
		public static const STOPPED:int = 0;
		public static const PLAYING:int = 1;
		public static const PAUSED:int = 2;
		
		private var sound:Sound
		private var name:String
		private var volume:Number;
		private var loops:int;
		private var enabled:Boolean;
		private var offset:Number;
		private var pan:Number;
		private var pausedOffset:Number;
		private var soundChannel:SoundChannel;
		private var muteSoundTransform:SoundTransform;
		private var _parallelSounds:Vector.<GameSound>;
		private var _state:int = 0;
		private var _prevState:int = 0;
		private var _mutePrevState:int;
		
		/**
		 * Class contructor, the developer must never call this functions directly. It well be called from the SoundEngine class
		 * @param name The name of the sound
		 * @param sound The flash.media.Sound that will play
		 * @param volume Initial volume, Must be between 0 and 1
		 * @param loops The times the sound will play, if < 0 it will play int.MAX_VALUE times
		 * @param pan The pan of the sound, if it will play more from the left channel or the right channel
		 * @param offset The position on the sound from with it will star playing
		 */
		public function GameSound(name:String, sound:Sound, volume:Number, loops:int, enabled:Boolean, pan:Number = 0, offset:Number = 0 ) 
		{
			this.name = name;
			this.sound = sound;
			this.volume = volume;
			this.loops = (loops < 0) ? int.MAX_VALUE : loops;
			this.enabled = enabled;
			this.offset = offset;
			this.pan = pan;
			_parallelSounds = new Vector.<GameSound>();
			muteSoundTransform = new SoundTransform();
			
			
			previousState = STOPPED;
			currentState = STOPPED;
		}
		
		public function playInParallel(sound:GameSound,fadeIn:Boolean=false):void
		{
			_parallelSounds.push(sound);
			sound.Play(fadeIn);
		}
		
		public function Play(fadeIn:Boolean):void
		{
			if (enabled)
			{
				if (currentState == STOPPED)
				{

					soundChannel = CurrentSound.play(Offset, Loops);
					var transform:SoundTransform = soundChannel.soundTransform;
					if (fadeIn)
					{
						doFadeIn(soundChannel, volume,transform,pan);
					}
					else
					{
						transform.volume = volume;
						transform.pan = pan;
						soundChannel.soundTransform = transform;
					}
					
					checkForLoop(Loops);
					previousState = STOPPED;
					currentState = PLAYING;
				}
				else if(currentState == PAUSED)
				{
					Resume();
				}
			}
		}
		
		public function mute(fadeOut:Boolean=false):void
		{
			_mutePrevState = currentState;
			Pause(fadeOut);
			enabled = false;
		}
		
		public function unMute(fadeIn:Boolean=false):void
		{
			enabled = true;
			if (_mutePrevState == PLAYING)
			{
				Play(fadeIn);
			}
		}
		
		public function changeVolume(volume:Number, fade:Boolean = false, fadeOutSeconds:int = 10):void
		{
			var auxVolume:Number;
			if (this.volume < volume)
			{
				auxVolume = volume - this.volume;
				this.volume += auxVolume;
			}
			else
			{
				auxVolume = this.volume - volume;
				this.volume -= auxVolume;
			}
			if (this.volume > 1) { this.volume = 1; }
			if (this.volume < 0) { this.volume = 0; }
			if (soundChannel != null)
			{
				if (!fade)
				{
					var transform:SoundTransform = soundChannel.soundTransform;
					transform.volume = this.volume; 
					soundChannel.soundTransform = transform;
				}
				else
				{
					TweenLite.to(soundChannel, fadeOutSeconds, { volume:this.volume } );
				}
			}
		}
		
		public function Pause(fadeOut:Boolean):void
		{
			if (currentState == PLAYING)
			{
				if (soundChannel != null)
				{
					pausedOffset = soundChannel.position;
					Stop(fadeOut);
					previousState = PLAYING;
					currentState = PAUSED;
				}
			}
		}
		
		public function Resume():void
		{
			if (currentState == PAUSED)
			{
				if (sound != null)
				{
					soundChannel = CurrentSound.play(pausedOffset, Loops);
					var transform:SoundTransform = soundChannel.soundTransform;
					transform.volume = volume;
					soundChannel.soundTransform = transform;
					
					checkForLoop(Loops);
					previousState = PAUSED;
					currentState = PLAYING;
				}
			}
		}
		
		public function Stop(fadeOut:Boolean,fadeOutSeconds:int = 10):void
		{
			stopParallelSounds(fadeOut);
			
			if (soundChannel != null)
			{
				if (fadeOut)
				{
					doFadeOut(soundChannel,fadeOutSeconds);
				}
				else
				{
					reallyStopSound();
				}
				
				previousState = PLAYING;
				currentState = STOPPED;
			}
		}
		
		public function get Name():String { return name; }
		public function get CurrentSound():Sound { return sound; }
		public function get Volume():Number { return volume; }
		public function get Loops():int { return loops; }
		public function get Enabled():Boolean { return enabled; }
		public function get Offset():Number { return offset; }
		public function set Offset(value:Number):void { offset = value; }	
		public function get Playing():Boolean { return (currentState == PLAYING); }
		
		public function get currentState():int 
		{
			return _state;
		}
		
		public function set currentState(value:int):void 
		{
			_state = value;
		}
		
		public function get previousState():int 
		{
			return _prevState;
		}
		
		public function set previousState(value:int):void
		{
			_prevState = value;
		}
		
		private function doFadeIn(soundChannel:SoundChannel, volume:Number,transform:SoundTransform, pan:Number):void 
		{
			transform.volume = 0;
			transform.pan = pan;
			soundChannel.soundTransform = transform;
			TweenLite.to(soundChannel, 2, { volume:volume } );
		}
		
		private function doFadeOut(soundChannel:SoundChannel,fadeOutSeconds:int=10):void 
		{
			TweenLite.to(soundChannel, fadeOutSeconds, { volume:0, onComplete:reallyStopSound } );
		}
		
		private function reallyStopSound():void 
		{
			if (soundChannel)
			{
				soundChannel.stop();
				removeListeners();
				soundChannel = null;
			}
		}
		
		private function stopParallelSounds(fadeOut:Boolean=false):void
		{
			if (_parallelSounds.length > 0)
			{
				var tempS:GameSound = _parallelSounds.pop();
				tempS.Stop(fadeOut);
				stopParallelSounds(fadeOut);
			}
		}
		
		private function removeListeners():void
		{
			if ((soundChannel != null) && (soundChannel.hasEventListener(Event.SOUND_COMPLETE)))
			{
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundTrackComplete);
			}
		}
		
		private function checkForLoop(loops:int):void
		{
			
			if (soundChannel != null)
			{
				soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundTrackComplete);
			}
		}
		
		private function onSoundTrackComplete(e:Event):void
		{
			dispatchEvent(new Event(Event.SOUND_COMPLETE));
			if (currentState == PLAYING)
			{
				Stop(false);
				if (loops < 0)
				{
					Play(false);
				}
			}
		}
	}

}