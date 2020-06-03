private ["_id","_pos","_building","_tracked","_vehs","_group","_all","_shopkeeper","_groups"];

private _hour = date select 3;
params ["_town","_spawnid"];

private _activeshops = server getVariable [format["activeshopsin%1",_town],[]];

if(count _activeshops > 0) exitWith {
	private _groups = [];

 //Make an array of all trading post locations
	_tradeposts = [allmapmarkers, {(getmarkertype _x) == "Empty"}] call BIS_fnc_conditionalselect;

	{
		_x params ["_pos","_category"];
		private _pos = _x select 0;
		//Find the trading post marker nearest to the current town
		_tradepost = [_tradeposts,_pos] call BIS_fnc_nearestPosition;
		_building = nearestBuilding _pos;

		private _group = createGroup civilian;
		_group setBehaviour "CARELESS";
		_groups pushback _group;

		//Distribute shopkeepers to correct positions in the trade post
		private _start = getmarkerpos _tradepost;

		if (_category == "General") then
			{
				_tp = [(getMarkerPos _tradepost), 180, call (compile (preprocessFileLineNumbers "overthrow_main\functions\virtualization\spawners\trade_post.sqf"))] call BIS_fnc_ObjectsMapper;
				_start = [(getmarkerpos _tradepost), 7.88553, 166] call BIS_fnc_relPos;
			};

		if (_category == "Surplus") then
				{
					_start = [(getmarkerpos _tradepost), 1.92187, 302] call BIS_fnc_relPos;
				};

		if (_category == "Electronics") then
						{
							_start = [(getmarkerpos _tradepost), 2.11956, 57] call BIS_fnc_relPos;
						};

		if (_category == "Pharmacy") then
						{
							_start = [(getmarkerpos _tradepost), 4.46949, 204] call BIS_fnc_relPos;
						};
		if (_category == "Clothing") then
						{
							_start = [(getmarkerpos _tradepost), 3.4005, 135] call BIS_fnc_relPos;
						};

		_shopkeeper = _group createUnit [OT_civType_shopkeeper, _start, [],0, "NONE"];

//		private _tracked = _building call OT_fnc_spawnTemplate;
		private _vehs = _tracked select 0;
		{
			_groups pushback _x;
		}foreach(_vehs);

		_shopkeeper allowDamage false;
		_shopkeeper setdir 180;
		_shopkeeper setformdir 180;
		_shopkeeper disableAI "MOVE";
		_shopkeeper disableAI "AUTOCOMBAT";
		_shopkeeper setVariable ["NOAI",true,false];

		_shopkeeper setVariable ["shopcheck",true,true];
		_shopkeeper setVariable ["shop",format["%1",_pos],true];
		_shopkeeper setVariable ["OT_shopCategory",_category,true];
		_building setVariable ["OT_shopCategory",_category,true];
		[_shopkeeper,_category] call OT_fnc_initShopkeeper;

		//Put a light on
		_light = "#lightpoint" createVehicle [_pos select 0,_pos select 1,(_pos select 2)+2.2];
		_light setLightBrightness 0.13;
		_light setLightAmbient[.9, .9, .6];
		_light setLightColor[.5, .5, .4];
		_groups pushback _light;
		sleep 0.5;
	}foreach(_activeshops);

	//Spawn in the trading post



	spawner setvariable [_spawnid,(spawner getvariable [_spawnid,[]]) + _groups,false];
};
