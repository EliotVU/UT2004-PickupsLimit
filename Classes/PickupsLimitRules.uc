//==============================================================================
//	MutPickupsLimit.uc (C) 2011 Eliot Van Uytfanghe All Rights Reserved
//==============================================================================
class PickupsLimitRules extends GameRules;

struct sPickupUses
{
	var string ClassReference;
	var int Uses;
};

struct sPickupUser
{
	var PlayerController User;
	var string ID;

	var array<sPickupUses> Uses;
};

var array<sPickupUser> PickupUsers;

final function int GetPickupUser( PlayerController user )
{
	local int i;

	for( i = 0; i < PickupUsers.Length; ++ i )
	{
		if( (PickupUsers[i].User == none || PickupUsers[i].User == user) && PickupUsers[i].ID == user.GetPlayerIDHash() )
		{
			PickupUsers[i].User = user;
			//Level.Game.Broadcast( self, "Found pickup rules for:" @ PickupUsers[i].ID );
			return i;
		}
	}

	PickupUsers.Insert( 0, 1 );
	PickupUsers[0].User = user;
	PickupUsers[0].ID = user.GetPlayerIDHash();
	//Level.Game.Broadcast( self, "Generating pickup rules for:" @ PickupUsers[0].ID );
	return 0;
}

final function int GetPickupLimitIndex( Pickup item )
{
	local int i;

	//Level.Game.Broadcast( self, "Pickup type:" @ string(item.InventoryType) );
	for( i = 0; i < MutPickupsLimit(Owner).PickupRules.Length; ++ i )
	{
		if( MutPickupsLimit(Owner).PickupRules[i].PickupInventoryType ~= string(item.InventoryType) )
		{
			return i;
		}
	}
	return -1;
}

final function bool AddPickupUse( int userIndex, Pickup item )
{
	local int itemIndex, i, pickupIndex;

	pickupIndex = GetPickupLimitIndex( item );
	if( pickupIndex == -1 )
	{
		// Allow infinite uses.
		//Level.Game.Broadcast( self, "Pickup's InventoryType has no rules!" );
		return true;
	}

	itemIndex = -1;
	for( i = 0; i < PickupUsers[userIndex].Uses.Length; ++ i )
	{
		if( PickupUsers[userIndex].Uses[i].ClassReference ~= string(item.InventoryType) )
		{
			itemIndex = i;
			//Level.Game.Broadcast( self, "Found pickups uses data!" );
			break;
		}
	}

	if( itemIndex == -1 )
	{
		PickupUsers[userIndex].Uses.Insert( 0, 1 );
		PickupUsers[userIndex].Uses[0].ClassReference = string(item.InventoryType);
		itemIndex = 0;

		//Level.Game.Broadcast( self, "Creating pickups uses data!" );
	}

	// Reached maximum uses
	if( PickupUsers[userIndex].Uses[itemIndex].Uses >= MutPickupsLimit(Owner).PickupRules[pickupIndex].MaxPickups )
	{
		return false;
	}

	//Level.Game.Broadcast( self, "Pickups uses:" @ PickupUsers[userIndex].Uses[itemIndex].Uses + 1 );
	return ++ PickupUsers[userIndex].Uses[itemIndex].Uses <= MutPickupsLimit(Owner).PickupRules[pickupIndex].MaxPickups;
}

function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	local int userIndex, pIndex;

	// We shall only check for first-time pickups per pawn instance and only for pickups that haven't been dropped by that pawn instance.
	if( Other.FindInventoryType( item.InventoryType ) != none /*|| (item.Inventory != none && item.Inventory.Owner == Other)*/ )
	{
		pIndex = GetPickupLimitIndex( item );
		if( pIndex == -1 || !MutPickupsLimit(Owner).PickupRules[pIndex].bAmmoUpdateCountsAsPickup )
		{
			return super.OverridePickupQuery(Other,item,bAllowPickup);
		}
	}

	userIndex = GetPickupUser( PlayerController(Other.Controller) );
	//Level.Game.Broadcast( self, "Pickup user:" @ userIndex );
	if( !AddPickupUse( userIndex, item ) )
	{
	   // Level.Game.Broadcast( self, "Pickup query denied!" );
		bAllowPickup = 0;
		return true;
	}
	return super.OverridePickupQuery(Other,item,bAllowPickup);
}