class CActiveWitcherZoomMode
{
	public var
		yDefault,
		yMax,
		zDefault
		: float;
		
	function Init(yD, yM, zD : float)
	{
		yDefault = yD;
		yMax = yM;
		zDefault = zD;
	}
}

class CActiveWitcherZoom extends CPlayerInput
{
	private var
		offset_current,
		offset_target
		: Vector;
	
	private var
		analogTolerance
		: float;

	private var
		mode_foot,
		mode_horse,
		mode_boat,
		mode_current
		: CActiveWitcherZoomMode;

	private var
		useModifier,
		yModifierPressed,
		zModifierPressed
		: bool;
	
	//
	
	default analogTolerance = 2.5f;
		
	default useModifier = false;
	default yModifierPressed = false;
	default zModifierPressed = false;

	//
	
	public function Init()
	{
		mode_foot = new CActiveWitcherZoomMode in this;
		mode_horse = new CActiveWitcherZoomMode in this;
		mode_boat = new CActiveWitcherZoomMode in this;
		
		// CHANGE THESE VALUES TO YOUR DESIRED INITIAL ZOOM VALUE FOR EACH MODE OF TRAVEL:
		// values are for: initial zoom, max zoom, initial camera height
		mode_foot.Init(-3.f, 4.1f, .22f);
		mode_horse.Init(-2.8f, 4.5f, .25f);
		mode_boat.Init(-4.0f, 4.5f, .05f);
		//
	
		theInput.RegisterListener( this, 'OnZoom', 'AWZ_zoom' );
		theInput.RegisterListener( this, 'OnZoomIn', 'AWZ_zoomIn' );
		theInput.RegisterListener( this, 'OnZoomOut', 'AWZ_zoomOut' );
		theInput.RegisterListener( this, 'OnZoomMax', 'AWZ_zoomMax' );
		theInput.RegisterListener( this, 'OnZoomReset', 'AWZ_zoomReset' );
		theInput.RegisterListener( this, 'OnZoomToggle', 'AWZ_zoomToggle' );
		theInput.RegisterListener( this, 'OnYModifier', 'AWZ_yModifier' );
		theInput.RegisterListener( this, 'OnZModifier', 'AWZ_zModifier' );

		SetFootMode();
	}

	//
	
	private function Delta(val : float) : float
	{
		return ClampF(AbsF( MinF(0, val) ) / 4, .3f, 4.f);
	}
	
	private function AlterTarget(direction : int)
	{
		var delta : float;
		
		if (yModifierPressed && zModifierPressed)
		{
			offset_target.X += (Delta(offset_current.X) * direction);
		}
		else if (zModifierPressed)
		{
			offset_target.Z += (Delta(offset_current.Z) * direction);
		}
		else if (!useModifier || yModifierPressed)
		{
			offset_target.Y = MinF(mode_current.yMax, offset_target.Y + (Delta(offset_current.Y) * direction));
		}
	}

	private function SetMode(mode : CActiveWitcherZoomMode)
	{
		var changed : bool;
		
		var prc : ICustomCameraPivotRotationController;
		
		changed = mode != mode_current;
		mode_current = mode;
		
		if (changed)
		{
			offset_target.X = .0f;
			offset_target.Y = mode_current.yDefault;
			offset_target.Z = mode_current.zDefault;
		}
		
		prc = theGame.GetGameCamera().GetActivePivotRotationController();
		prc.maxPitch = 90.0;
		prc.minPitch = -90.0;
	}
	
	private function UpdateCurrent(current, target : float) : float
	{
		var transitionDelta : float;

		transitionDelta = MinF(.2f * Delta(current), 1.5f);

		if (current < target)
		{
			current = MinF(target, current + transitionDelta);
		}
		else if (current > target)
		{
			current = MaxF(target, current - transitionDelta);
		}
		
		return current;
	}
	
	///
	
	public function Apply( out v : Vector)
	{
		
		if (offset_current.X != offset_target.X)
		{
			offset_current.X = UpdateCurrent(offset_current.X, offset_target.X);
		}

		if (offset_current.Y != offset_target.Y)
		{
			offset_current.Y = UpdateCurrent(offset_current.Y, offset_target.Y);
		}

		if (offset_current.Z != offset_target.Z)
		{
			offset_current.Z = UpdateCurrent(offset_current.Z, offset_target.Z);
		}

		v.X = offset_current.X;
		v.Y = offset_current.Y;
		v.Z = offset_current.Z;
	}
	
	//
	
	public function SetFootMode()
	{
		SetMode(mode_foot);
	}
	
	public function SetHorseMode()
	{
		SetMode(mode_horse);
	}

	public function SetBoatMode()
	{
		SetMode(mode_boat);
	}

	//
	
	public function ZoomIn()
	{
		AlterTarget(1);
	}
	
	public function ZoomOut()
	{
		AlterTarget(-1);
	}
	
	public function isZoomed() : bool
	{
		return offset_target.Y != 0;
	}
	
	//
	
	event OnZoom( action : SInputAction )
	{
		if( action.value < -analogTolerance )
		{
			ZoomOut();
		}
		else if( action.value > analogTolerance )
		{
			ZoomIn();
		}
	}
	
	event OnZoomIn( action : SInputAction )
	{
		if( IsPressed( action ) )
		{
			ZoomIn();
		}
	}
	
	event OnZoomOut( action : SInputAction )
	{
		if( IsPressed( action ) )
		{
			ZoomOut();
		}
	}
	
	event OnZoomMax( action : SInputAction )
	{
		if( IsPressed( action ) )
		{
			offset_target.X = .0f;
			offset_target.Y = mode_current.yMax;
			offset_target.Z = mode_current.zDefault;
		}
	}

	event OnZoomReset( action : SInputAction )
	{
		if( IsPressed( action ) )
		{
			offset_target.X = .0f;
			offset_target.Y = mode_current.yDefault;
			offset_target.Z = mode_current.zDefault;
		}
	}
	
	event OnZoomToggle( action : SInputAction )
	{
		if( IsPressed( action ) )
		{
			offset_target.X = .0f;
			offset_target.Z = mode_current.zDefault;
			if ( offset_target.Y == mode_current.yMax ) 
			{
				offset_target.Y = mode_current.yDefault;
			}
			else
			{
				offset_target.Y = mode_current.yMax;
			}
		}
	}
	
	event OnYModifier( action : SInputAction )
	{
		yModifierPressed = IsPressed( action );
	}

	event OnZModifier( action : SInputAction )
	{
		zModifierPressed = IsPressed( action );
	}
}