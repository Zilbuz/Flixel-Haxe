package org.flixel;

import flash.display.Bitmap;

/**
 * <code>FlxEmitter</code> is a lightweight particle emitter.
 * It can be used for one-time explosions or for
 * continuous fx like rain and fire.  <code>FlxEmitter</code>
 * is not optimized or anything; all it does is launch
 * <code>FlxSprite</code> objects out at set intervals
 * by setting their positions and velocities accordingly.
 * It is easy to use and relatively efficient, since it
 * automatically redelays its sprites and/or kills
 * them once they've been launched.
 */
class FlxEmitter extends FlxGroup {
	/**
	 * The minimum possible velocity of a particle.
	 * The default value is (-100,-100).
	 */
	
	/**
	 * The minimum possible velocity of a particle.
	 * The default value is (-100,-100).
	 */
	public var minParticleSpeed:FlxPoint;
	/**
	 * The maximum possible velocity of a particle.
	 * The default value is (100,100).
	 */
	public var maxParticleSpeed:FlxPoint;
	/**
	 * The X and Y drag component of particles launched from the emitter.
	 */
	public var particleDrag:FlxPoint;
	/**
	 * The minimum possible angular velocity of a particle.  The default value is -360.
	 * NOTE: rotating particles are more expensive to draw than non-rotating ones!
	 */
	public var minRotation:Float;
	/**
	 * The maximum possible angular velocity of a particle.  The default value is 360.
	 * NOTE: rotating particles are more expensive to draw than non-rotating ones!
	 */
	public var maxRotation:Float;
	/**
	 * Sets the <code>acceleration.y</code> member of each particle to this value on launch.
	 */
	public var gravity:Float;
	/**
	 * Determines whether the emitter is currently emitting particles.
	 */
	public var on:Bool;
	/**
	 * This variable has different effects depending on what kind of emission it is.
	 * During an explosion, delay controls the lifespan of the particles.
	 * During normal emission, delay controls the time between particle launches.
	 * NOTE: In older builds, polarity (negative numbers) was used to define emitter behavior.
	 * THIS IS NO LONGER THE CASE!  FlxEmitter.start() controls that now!
	 */
	public var delay:Float;
	/**
	 * The number of particles to launch at a time.
	 */
	public var quantity:Int;
	/**
	 * The style of particle emission (all at once, or one at a time).
	 */
	var _explode:Bool;
	/**
	 * Internal helper for deciding when to launch particles or kill them.
	 */
	var _timer:Float;
	/**
	 * Internal marker for where we are in <code>_sprites</code>.
	 */
	var _particle:Int;
	/**
	 * Internal counter for figuring out how many particles to launch.
	 */
	var _counter:Int;
	
	/**
	 * Creates a new <code>FlxEmitter</code> object at a specific position.
	 * Does not automatically generate or attach particles!
	 * 
	 * @param	X			The X position of the emitter.
	 * @param	Y			The Y position of the emitter.
	 */
	public function new(?X:Float=0, ?Y:Float=0)
	{
		super();
		
		x = X;
		y = Y;
		width = 0;
		height = 0;
		
		minParticleSpeed = new FlxPoint(-100,-100);
		maxParticleSpeed = new FlxPoint(100,100);
		minRotation = -360;
		maxRotation = 360;
		gravity = 400;
		particleDrag = new FlxPoint();
		delay = 0;
		quantity = 0;
		_counter = 0;
		_explode = true;
		exists = false;
		on = false;
	}
	
	/**
	 * This function generates a new array of sprites to attach to the emitter.
	 * 
	 * @param	Graphics		If you opted to not pre-configure an array of FlxSprite objects, you can simply pass in a particle image or sprite sheet.
	 * @param	Quantity		The number of particles to generate when using the "create from image" option.
	 * @param	BakedRotations	How many frames of baked rotation to use (boosts performance).  Set to zero to not use baked rotations.
	 * @param	Multiple		Whether the image in the Graphics param is a single particle or a bunch of particles (if it's a bunch, they need to be square!).
	 * @param	Collide			Whether the particles should be flagged as not 'dead' (non-colliding particles are higher performance).  0 means no collisions, 0-1 controls scale of particle's bounding box.
	 * 
	 * @return	This FlxEmitter instance (nice for chaining stuff together, if you're into that).
	 */
	public function createSprites(Graphics:Class<Bitmap>, ?Quantity:Int=50, ?BakedRotations:Int=16, ?Multiple:Bool=true, ?Collide:Float=0):FlxEmitter
	{
		members = new Array();
		var r:Int;
		var s:FlxSprite;
		var tf:Int = 1;
		var sw:Float;
		var sh:Float;
		if(Multiple)
		{
			s = new FlxSprite(0,0,Graphics);
			tf = Math.floor(s.width/s.height);
		}
		for(i in 0...Quantity)
		{
			s = new FlxSprite();
			if(Multiple)
			{
				r = Math.floor(FlxU.random()*tf);
				if(BakedRotations > 0)
					s.loadRotatedGraphic(Graphics,BakedRotations,r);
				else
				{
					s.loadGraphic(Graphics,true);
					s.frame = r;
				}
			}
			else
			{
				if(BakedRotations > 0)
					s.loadRotatedGraphic(Graphics,BakedRotations);
				else
					s.loadGraphic(Graphics);
			}
			if(Collide > 0)
			{
				sw = s.width;
				sh = s.height;
				s.width *= Collide;
				s.height *= Collide;
				s.offset.x = (sw-s.width)/2;
				s.offset.y = (sh-s.height)/2;
				s.solid = true;
			}
			else
				s.solid = false;
			s.exists = false;
			s.scrollFactor = scrollFactor;
			add(s);
		}
		return this;
	}
	
	/**
	 * A more compact way of setting the width and height of the emitter.
	 * 
	 * @param	Width	The desired width of the emitter (particles are spawned randomly within these dimensions).
	 * @param	Height	The desired height of the emitter.
	 */
	public function setSize(Width:Int,Height:Int):Void
	{
		width = Width;
		height = Height;
	}
	
	/**
	 * A more compact way of setting the X velocity range of the emitter.
	 * 
	 * @param	Min		The minimum value for this range.
	 * @param	Max		The maximum value for this range.
	 */
	public function setXSpeed(?Min:Float=0,?Max:Float=0):Void
	{
		minParticleSpeed.x = Min;
		maxParticleSpeed.x = Max;
	}
	
	/**
	 * A more compact way of setting the Y velocity range of the emitter.
	 * 
	 * @param	Min		The minimum value for this range.
	 * @param	Max		The maximum value for this range.
	 */
	public function setYSpeed(?Min:Float=0,?Max:Float=0):Void
	{
		minParticleSpeed.y = Min;
		maxParticleSpeed.y = Max;
	}
	
	/**
	 * A more compact way of setting the angular velocity constraints of the emitter.
	 * 
	 * @param	Min		The minimum value for this range.
	 * @param	Max		The maximum value for this range.
	 */
	public function setRotation(?Min:Float=0,?Max:Float=0):Void
	{
		minRotation = Min;
		maxRotation = Max;
	}
	
	/**
	 * Internal function that actually performs the emitter update (called by update()).
	 */
	function updateEmitter():Void
	{
		if(_explode)
		{
			var i:Int;
			var l:Int;
			_timer += FlxG.elapsed;
			if((delay > 0) && (_timer > delay))
			{
				kill();
				return;
			}
			if(on)
			{
				on = false;
				l = members.length;
				if(quantity > 0)
					l = quantity;
				l += _particle;
				i = _particle;
				for (j in i ... l)
				//for(i = _particle; i < l; i++)
					emitParticle();
			}
			return;
		}
		if(!on)
			return;
		_timer += FlxG.elapsed;
		while((_timer > delay) && ((quantity <= 0) || (_counter < quantity)))
		{
			_timer -= delay;
			emitParticle();
		}
	}
	
	/**
	 * Internal function that actually goes through and updates all the group members.
	 * Overridden here to remove the position update code normally used by a FlxGroup.
	 */
	override function updateMembers():Void
	{
		var o:FlxObject;
		var l:Int = members.length;
		for(i in 0...l)
		{
			o = cast( members[i], FlxObject);
			if((o != null) && o.exists && o.active)
				o.update();
		}
	}
	
	/**
	 * Called automatically by the game loop, decides when to launch particles and when to "die".
	 */
	public override function update():Void
	{
		super.update();
		updateEmitter();
	}
	
	/**
	 * Call this function to start emitting particles.
	 * 
	 * @param	Explode		Whether the particles should all burst out at once.
	 * @param	Delay		You can set the delay (or lifespan) here if you want.
	 * @param	Quantity	How many particles to launch.  Default value is 0, or "all the particles".
	 */
	public function start(?Explode:Bool=true,?Delay:Float=0,?Quantity:Int=0):Void
	{
		if(members.length <= 0)
		{
			FlxG.log("WARNING: there are no sprites loaded in your emitter.\nAdd some to FlxEmitter.members or use FlxEmitter.createSprites().");
			return;
		}
		_explode = Explode;
		if(!_explode)
			_counter = 0;
		if(!exists)
			_particle = 0;
		exists = true;
		visible = true;
		active = true;
		dead = false;
		on = true;
		_timer = 0;
		if(quantity == 0)
			quantity = Quantity;
		if(Delay != 0)
			delay = Delay;
		if(delay < 0)
			delay = -delay;
		if(delay == 0)
		{
			if(Explode)
				delay = 3;	//default value for particle explosions
			else
				delay = 0.1;//default value for particle streams
		}
	}
	
	/**
	 * This function can be used both internally and externally to emit the next particle.
	 */
	public function emitParticle():Void
	{
		_counter++;
		var s:FlxSprite = cast( members[_particle], FlxSprite);
		s.visible = true;
		s.exists = true;
		s.active = true;
		s.x = x - (Math.floor(s.width)>>1) + FlxU.random()*width;
		s.y = y - (Math.floor(s.height)>>1) + FlxU.random()*height;
		s.velocity.x = minParticleSpeed.x;
		if(minParticleSpeed.x != maxParticleSpeed.x) s.velocity.x += FlxU.random()*(maxParticleSpeed.x-minParticleSpeed.x);
		s.velocity.y = minParticleSpeed.y;
		if(minParticleSpeed.y != maxParticleSpeed.y) s.velocity.y += FlxU.random()*(maxParticleSpeed.y-minParticleSpeed.y);
		s.acceleration.y = gravity;
		s.angularVelocity = minRotation;
		if(minRotation != maxRotation) s.angularVelocity += FlxU.random()*(maxRotation-minRotation);
		if(s.angularVelocity != 0) s.angle = FlxU.random()*360-180;
		s.drag.x = particleDrag.x;
		s.drag.y = particleDrag.y;
		s.visible = true;
		_particle++;
		if(_particle >= members.length)
			_particle = 0;
		s.onEmit();
	}
	
	/**
	 * Call this function to stop the emitter without killing it.
	 * 
	 * @param	Delay	How long to wait before killing all the particles.  Set to 'zero' to never kill them.
	 */
	public function stop(?Delay:Float=3):Void
	{
		_explode = true;
		delay = Delay;
		if(delay < 0)
			delay = -Delay;
		on = false;
	}
	
	/**
	 * Change the emitter's position to the origin of a <code>FlxObject</code>.
	 * 
	 * @param	Object		The <code>FlxObject</code> that needs to spew particles.
	 */
	public function at(Object:FlxObject):Void
	{
		x = Object.x + Object.origin.x;
		y = Object.y + Object.origin.y;
	}
	
	/**
	 * Call this function to turn off all the particles and the emitter.
	 */
	public override function kill():Void
	{
		super.kill();
		on = false;
	}
}
