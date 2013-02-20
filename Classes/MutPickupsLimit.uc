//==============================================================================
//	MutPickupsLimit.uc (C) 2011 Eliot Van Uytfanghe All Rights Reserved
//==============================================================================
class MutPickupsLimit extends Mutator
	config(MutPickupsLimit);

struct sPickupRules
{
	var string PickupInventoryType;
	var int MaxPickups;
	var bool bAmmoUpdateCountsAsPickup;
};

var() config array<sPickupRules> PickupRules;

event PostBeginPlay()
{
	local PickupsLimitRules rules;

	super.PostBeginPlay();

	rules = Spawn( class'PickupsLimitRules', self );
	Level.Game.AddGameModifier( rules );
}

static function FillPlayInfo( PlayInfo Info )
{
	Super.FillPlayInfo(Info);
	Info.AddSetting( default.RulesGroup,
		"PickupRules",
		"Pickup Rules", 0, 1, "Text",,,, true );
}

//==============================================================================
// Display Description.
static function string GetDescriptionText( string PropName )
{
	switch( PropName )
	{
		case "PickupRules":
			return "The pickups with these inventory types that must have a pickup limit.";
	}
	return Super.GetDescriptionText(PropName);
}

defaultproperties
{
	PickupRules(0)=(PickupInventoryType="XWeapons.Redeemer",MaxPickups=10,bAmmoUpdateCountsAsPickup=true)

	FriendlyName="Pickups Limit"
	Description="This mutator provides the ability to place a limit on the amount of times a player is allowed to take a pickup. Created by Eliot Van Uytfanghe @ 2011"
	RulesGroup="MutPickupsLimit"
}