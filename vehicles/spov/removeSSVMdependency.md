# Removal of SSVM dependency

a somewhat long task that will grant more freedom and make future creations a lot more stable

## functions to replace

init and update hold a whole lot of stuff so I'm not going to bother with them yet

vsoEat
	vsoEatForce

vsoUneat

vsoNotnil

vsoVictimAnimUpdate
	_ListAddStatus
	_animArrayGetRange
	_animArrayGetListClamp
	_ListRemoveStatus

vsoVictimAnimSetStatus
	_ListAddStatus
	_ListRemoveStatus

vsoVictimAnimReplay
	vsoVictimAnimPlay
		vsoVictimAnim
			vsoAnim
				vsoTTCheck
				vsoTT

vsoSetTarget

vsoGetTargetId

vsoClearTarget

vsoApplyStatus
	vsoApplyStatusList

vsoTimeDelta

vsoNext

vsoAnimReplay
	vsoAnim
		vsoTTCheck
		vsoTT

vsoAnimIs

vsoAnimEnded
	vsoTTCheck

vsoTransAnimUpdate
	_animArrayGetRange
	vsoTransMoveTo
	vsoAnimCurr

_ListAddStatus

vsoStorageSaveAndLoad
	vsoStorageSave
		vsoStorageSaveData
	vsoStorageLoad
		vsoStorageLoadData

vsoPill

vsoPillValue

vsoAnimSpeed

vsoUseSolid

vsoUseLounge

vsoEffectWarpIn
	vsoEffectProjectile
		vsoEffectProjectile

vsoEffectWarpOut
	vsoEffectProjectile
		vsoEffectProjectile

vsoStorageLoad
	vsoStorageLoadData

_add_vso_rpc

vsoTimerEvery
	vsoTimerSet
		vsoTT
	vsoTTCheck

vsoFacePoint
	vsoFaceDirection
		vsoMotionParam
			mMotionParametersSet

vsoDebugRect

_vsoOnDeath
