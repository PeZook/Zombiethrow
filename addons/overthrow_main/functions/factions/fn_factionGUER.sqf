
private _blueprints = server getVariable ["GEURblueprints",[]];
if(count _blueprints == 0) then {
	_blueprints = OT_item_DefaultBlueprints;
	server setVariable ["GEURblueprints",_blueprints,true];
};
//Keeps track of all entities that should trigger the spawner
private _lastmin = date select 4;
private _lasthr = date select 3;
private _currentProduction = "";
private _stabcounter = 0;
private _trackcounter = 0;

while {true} do {
	sleep 1;

	_trackcounter = _trackcounter + 1;
	if(_trackcounter > 5) then {
		_trackcounter = 0;
		_track = [];
		{
			if(_x getVariable ["OT_spawntrack",false]) then {
				_track pushback _x;
			};
			sleep 0.01;
		}foreach(allunits);
		{
			if(_x getVariable ["OT_spawntrack",false]) then {
				_track pushback _x;
			};
			sleep 0.01;
		}foreach(vehicles);
		spawner setVariable ["track",_track,false];
	};

	private _dead = count alldeadmen;
	if(_dead > 150) then {
		format["There are %1 dead bodies, loot them or clean via options",_dead] remoteExec ["OT_fnc_notifyMinor",0,false];
	};

	{
		if (typename _x == "GROUP") then {
			{
				deleteVehicle _x;
			}foreach(units _x);
			deleteGroup _x;
		};
		if (typename _x == "OBJECT") then {
			deleteVehicle _x;
		};
	}foreach(spawner getVariable ["_noid_",[]]);

	if ((date select 3) != _lasthr) then {
		//Do production/wages
		_lasthr = date select 3;
		private _wages = 0;
		{
			if(_x != "Factory") then {
				private _perhr = [OT_nation,"WAGE",0] call OT_fnc_getPrice;
				_num = server getVariable [format["%1employ",_x],0];
				_enum = _num;
				if(_enum > 20) then {
					_enum = 20;
				};
				_funds = [] call OT_fnc_resistanceFunds;
				_towage = (_num * _perhr);
				if(_funds >= _towage) then {
					[-_towage] call OT_fnc_resistanceFunds;
					_wages = _wages + (_num * _perhr);
					_data = _x call OT_fnc_getBusinessData;

					_pos = _data select 0;
					_outnum = 2 * _num;
					_innum = 2 * _num;
					_intotal = _innum;
					if(_num > 0) then {
						if(count _data == 2 and _x != "Factory") then {
							//Just passive income
							_income = _enum * 200;
							[_income] call OT_fnc_resistanceFunds;
						};
						if(count _data == 3) then {
							//Turns something into money
							_input = _data select 2;
							_income = 0;
							_sellprice = round(([OT_nation,_input,0] call OT_fnc_getSellPrice) * 1.2);
							_container = _pos nearestObject OT_item_CargoContainer;
							if(_container isEqualTo objNull) then {
								_p = _pos findEmptyPosition [0,100,OT_item_CargoContainer];
								_container = OT_item_CargoContainer createVehicle _p;
								[_container,(server getVariable ["generals",[]]) select 0] call OT_fnc_setOwner;
								clearWeaponCargoGlobal _container;
								clearMagazineCargoGlobal _container;
								clearBackpackCargoGlobal _container;
								clearItemCargoGlobal _container;
							};
							{
								_stock = _x call OT_fnc_unitStock;
								_c = _x;
								{
									_x params ["_cls","_amt"];
									if(_cls == _input) exitWith {
										if(_amt >= _innum) then {
											[_c, _cls, _innum] call CBA_fnc_removeItemCargo;
											_income = _income + (_sellprice * _innum);
										}else{
											[_c, _cls, _amt] call CBA_fnc_removeItemCargo;
											_innum = _innum - _amt;
											_income = _income + (_sellprice * _amt);
										};
									};
								}foreach(_stock);
							}foreach(_pos nearObjects [OT_item_CargoContainer, 50]);
							[_income] call OT_fnc_resistanceFunds;
						};
						if(count _data == 4) then {
							//Turns something into something (or creates something from nothing)
							_input = _data select 2;
							_output = _data select 3;
							_container = _pos nearestObject OT_item_CargoContainer;
							if(_container isEqualTo objNull) then {
								_p = _pos findEmptyPosition [0,100,OT_item_CargoContainer];
								_container = OT_item_CargoContainer createVehicle _p;
								[_container,(server getVariable ["generals",[]]) select 0] call OT_fnc_setOwner;
								clearWeaponCargoGlobal _container;
								clearMagazineCargoGlobal _container;
								clearBackpackCargoGlobal _container;
								clearItemCargoGlobal _container;
							};
							if(_input != "") then {
								_inputnum = 0;
								{
									_c = _x;
									{
										_x params ["_cls","_amt"];
										if(_cls == _input) exitWith {
											if(_amt >= _innum) then {
												[_c, _cls, _innum] call CBA_fnc_removeItemCargo;
												_inputnum = _inputnum + _innum;
											}else{
												[_c, _cls, _amt] call CBA_fnc_removeItemCargo;
												_innum = _innum - _amt;
												_inputnum = _inputnum + _amt;
											};
										};
									}foreach(_c call OT_fnc_unitStock);
								}foreach(_pos nearObjects [OT_item_CargoContainer, 50]);
								_outnum = round (_outnum * (_inputnum / _intotal));
							};
							if(_output != "" and _outnum > 0) then {
								if(_output in ["OT_Sugarcane","ACE_Banana"]) then {
									_foundFertilizer = false;
									{
										_c = _x;
										{
											_x params ["_cls","_amt"];
											if(_cls == "OT_Fertilizer") exitWith {
												[_c, _cls, 1] call CBA_fnc_removeItemCargo;
												_foundFertilizer = true;
											};
										}foreach(_c call OT_fnc_unitStock);
										if(_foundFertilizer) exitWith {};
									}foreach(_pos nearObjects [OT_item_CargoContainer, 50]);
									if(_foundFertilizer) then {
										_output = round(_output * 1.5);
									};
								};
								_container addItemCargoGlobal [_output,_outnum];
							};
						};
					};
				}else{
					format["Resistance was unable to pay wages at %1",_x] remoteExec ["OT_fnc_notifyMinor",0,false];
				};
			};
		}foreach(server getVariable ["GEURowned",[]]);
	};

	if ((date select 4) != _lastmin) then {
		_lastmin = date select 4;

		if(!(call OT_fnc_generalIsOnline) and _dead > 300) then {
			format["There are %1 dead bodies, initiating auto-cleanup",_dead] remoteExec ["OT_fnc_notifyMinor",0,false];
			call OT_fnc_cleanDead;
		};

		_stabcounter = _stabcounter + 1;
		private _abandoned = server getVariable ["NATOabandoned",[]];

		if(_stabcounter >= 10) then {
			_stabcounter = 0;
			{
				_town = _x;
				_townpos = server getvariable _x;
				if !(_town in _abandoned) then {
					if(_townpos call OT_fnc_inSpawnDistance) then {
						_numcops = {side _x == west} count (_townpos nearObjects ["CAManBase",600]);
						if(_numcops == 0) then {
							[_town,-1] call OT_fnc_stability;
						};
					};
				}else{
					_stabchange = 0;
					_numcops = {side _x == west} count (_townpos nearObjects ["CAManBase",600]);
					if(_numcops > 0) then {
						_stabchange = _stabchange - _numcops;
					};
					_police = server getVariable [format["police%1",_town],0];
					if (_police > 0) then {
						_stabchange = _stabchange + floor(_police / 2);
					};
					if(_stabchange != 0) then {
						[_town,_stabchange] call OT_fnc_stability;
					};
				};
			}foreach(OT_allTowns);
		};

		//chemical production
		if("Chemical Plant" in _abandoned) then {
			private _chems = server getVariable ["reschems",0];
			server setVariable ["reschems",_chems + 1,true];
		};

		//do factory
		if("Factory" in (server getVariable ["GEURowned",[]])) then {
			private _currentCls = server getVariable ["GEURproducing",""];
			if(_currentCls != "") then {
				_cost = cost getVariable[_currentCls,[]];
				if(count _cost > 0) then {
					_cost params ["_base","_wood","_steel","_plastic"];
					if(isNil "_plastic") then {
						_plastic = 0;
					};
					_b = _base;
					if(_base > 240) then {
						_b = 30;
					};
					if(_base > 10000) then {
						_b = 60;
					};
					if(_base > 20000) then {
						_b = 120;
					};
					if(_base > 50000) then {
						_b = 240;
					};
					_timetoproduce = _b + (round (_wood+1)) + (round (_steel * 2)) + (round (_plastic * 5));
					if(_timetoproduce > 360) then {_timetoproduce = 360};
					if(_timetoproduce < 5) then {_timetoproduce = 5};
					_timespent = server getVariable ["GEURproducetime",0];

					_numtoproduce = 1;
					if(_wood < 1 and _wood > 0) then {
						_numtoproduce = round (1 / _wood);
					};
					if(_steel < 1 and _steel > 0) then {
						_numtoproduce = round (1 / _steel);
					};
					if(_plastic < 1 and _plastic > 0) then {
						_numtoproduce = round (1 / _plastic);
					};
					_costtoproduce = round((_base * _numtoproduce) * 0.8);

					if(_timespent == 0) then {
						//take items
						private _veh = OT_factoryPos nearestObject OT_item_CargoContainer;
						if(_veh isEqualTo objNull) then {
							_p = OT_factoryPos findEmptyPosition [0,100,OT_item_CargoContainer];
							if(count _p > 0) then {
								_veh = OT_item_CargoContainer createVehicle _p;
								[_veh,(server getVariable ["generals",[]]) select 0] call OT_fnc_setOwner;
								clearWeaponCargoGlobal _veh;
								clearMagazineCargoGlobal _veh;
								clearBackpackCargoGlobal _veh;
								clearItemCargoGlobal _veh;
							}else{
								format["Factory has no room to place container, please clear marker area"] remoteExec["OT_fnc_notifyMinor",0,false];
							};
						};
						_dowood = ["OT_wood",_wood,OT_factoryPos] call OT_fnc_hasFromCargoContainers;
						_dosteel = ["OT_steel",_steel,OT_factoryPos] call OT_fnc_hasFromCargoContainers;
						_doplastic = ["OT_plastic",_plastic,OT_factoryPos] call OT_fnc_hasFromCargoContainers;
						_domoney = ([] call OT_fnc_resistanceFunds >= _costtoproduce);
						if(_dowood and _dosteel and _doplastic and _domoney) then {
							["OT_wood",_wood,OT_factoryPos] call OT_fnc_takeFromCargoContainers;
							["OT_steel",_steel,OT_factoryPos] call OT_fnc_takeFromCargoContainers;
							["OT_plastic",_plastic,OT_factoryPos] call OT_fnc_takeFromCargoContainers;
							[-_costtoproduce] call OT_fnc_resistanceFunds;
							_timespent = _timespent + 1;
						};
					}else{
						_timespent = _timespent + 1;
					};
					if(_timespent >= _timetoproduce) then {
						_timespent = 0;

						if(!(_currentCls isKindOf "Bag_Base") and _currentCls isKindOf "AllVehicles") then {
							_p = OT_factoryVehicleSpawn findEmptyPosition [0,100,_currentCls];
							if(count _p > 0) then {
								_veh = _currentCls createVehicle _p;
								[_veh,(server getVariable ["generals",[]]) select 0] call OT_fnc_setOwner;
								clearWeaponCargoGlobal _veh;
								clearMagazineCargoGlobal _veh;
								clearBackpackCargoGlobal _veh;
								clearItemCargoGlobal _veh;
								_veh setDir OT_factoryVehicleDir;
								format["Factory has produced %1 x %2",_numtoproduce,_currentCls call OT_fnc_vehicleGetName] remoteExec["OT_fnc_notifyMinor",0,false];
							}else{
								format["Factory has no room to produce %1, please clear the road",_currentCls call OT_fnc_vehicleGetName] remoteExec["OT_fnc_notifyMinor",0,false];
								_timespent = _timetoproduce;
							};
						}else{
							private _veh = OT_factoryPos nearestObject OT_item_CargoContainer;
							if(_veh isEqualTo objNull) then {
								_p = OT_factoryPos findEmptyPosition [0,100,OT_item_CargoContainer];
								_veh = OT_item_CargoContainer createVehicle _p;
								[_veh,(server getVariable ["generals",[]]) select 0] call OT_fnc_setOwner;
								clearWeaponCargoGlobal _veh;
								clearMagazineCargoGlobal _veh;
								clearBackpackCargoGlobal _veh;
								clearItemCargoGlobal _veh;
							};
							call {
								if(_currentCls isKindOf "Bag_Base") exitWith {
									_currentCls = _currentCls call BIS_fnc_basicBackpack;
									_veh addBackpackCargoGlobal [_currentCls,_numtoproduce];
								};
								if(_currentCls isKindOf ["Rifle",configFile >> "CfgWeapons"]) exitWith {
									_veh addWeaponCargoGlobal [_currentCls,_numtoproduce];
								};
								if(_currentCls isKindOf ["Launcher",configFile >> "CfgWeapons"]) exitWith {
									_veh addWeaponCargoGlobal [_currentCls,_numtoproduce];
								};
								if(_currentCls isKindOf ["Pistol",configFile >> "CfgWeapons"]) exitWith {
									_veh addWeaponCargoGlobal [_currentCls,_numtoproduce];
								};
								if(_currentCls isKindOf ["CA_Magazine",configFile >> "CfgMagazines"]) exitWith {
									_veh addMagazineCargoGlobal [_currentCls,_numtoproduce];
								};
								_veh addItemCargoGlobal [_currentCls,_numtoproduce];
							};
						}
					};
					server setVariable ["GEURproducetime",_timespent,true];
				};
			};
		};

		//Do ranking
		{
			_x params ["_owner","_name","_unit","_rank"];
			if(typename _unit == "OBJECT") then {
				_xp = _unit getVariable ["OT_xp",0];
				_player = spawner getvariable [_owner,objNULL];
				if(_rank == "PRIVATE" and _xp > (OT_rankXP select 0)) then {
					_x set [3,"CORPORAL"];
					_unit setRank "CORPORAL";
					format["%1 has been promoted to Corporal",_name select 0] remoteExec ["OT_fnc_notifyMinor",_player,false];
					_unit setSkill 0.2 + (random 0.3);
				};
				if(_rank == "CORPORAL" and _xp > (OT_rankXP select 1)) then {
					_x set [3,"SERGEANT"];
					_unit setRank "SERGEANT";
					format["%1 has been promoted to Sergeant",_name select 0] remoteExec ["OT_fnc_notifyMinor",_player,false];
					_unit setSkill 0.3 + (random 0.3);
				};
				if(_rank == "SERGEANT" and _xp > (OT_rankXP select 2)) then {
					_x set [3,"LIEUTENANT"];
					_unit setRank "LIEUTENANT";
					format["%1 has been promoted to Lieutenant",_name select 0] remoteExec ["OT_fnc_notifyMinor",_player,false];
					_unit setSkill 0.5 + (random 0.3);
				};
				if(_rank == "LIEUTENANT" and _xp > (OT_rankXP select 3)) then {
					_x set [3,"CAPTAIN"];
					_unit setRank "CAPTAIN";
					format["%1 has been promoted to Captain",_name select 0] remoteExec ["OT_fnc_notifyMinor",_player,false];
					_unit setSkill 0.6 + (random 0.3);
				};
				if(_rank == "CAPTAIN" and _xp > (OT_rankXP select 4)) then {
					_x set [3,"MAJOR"];
					_unit setRank "MAJOR";
					format["%1 has been promoted to Major",_name select 0] remoteExec ["OT_fnc_notifyMinor",_player,false];
					_unit setSkill 0.8 + (random 0.2);
				};
			};
		}foreach(server getVariable ["recruits",[]]);
	}

};
