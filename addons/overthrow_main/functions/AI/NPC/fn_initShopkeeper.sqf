private ["_unit"];

_unit = _this select 0;
_category = _this select 1;

(group _unit) setVariable ["VCM_Disable",true];

private _firstname = OT_firstNames_local call BIS_fnc_selectRandom;
private _lastname = OT_lastNames_local call BIS_fnc_selectRandom;
private _fullname = [format["%1 %2",_firstname,_lastname],_firstname,_lastname];
[_unit,_fullname] remoteExecCall ["setName",0,_unit];
_unit allowDamage false;

[_unit, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _unit];
[_unit, "NoVoice"] remoteExecCall ["setSpeaker", 0, _unit];

removeAllWeapons _unit;
removeAllAssignedItems _unit;
removeuniform _unit;
removeGoggles _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeVest _unit;

// Dress the traders up according to their profession

if(_category isEqualTo "General") then
  {
    _unit forceAddUniform "CUP_U_I_GUE_Anorak_01";
    _unit addVest "B_Messenger_Coyote_F";
  };

if(_category isEqualTo "Surplus") then
  {
    _unit forceAddUniform "U_O_R_Gorka_01_camo_F";
    _unit addVest "CUP_V_B_BAF_MTP_Osprey_Mk4_Webbing";
    _unit addBackpack "B_Bergen_mcamo_F";
    _unit addHeadgear "H_Bandanna_khk";
  };

// _unit forceAddUniform (OT_clothes_shops call BIS_fnc_selectRandom);

if(_category isEqualTo "Pharmacy") then
  {
    _units forceAddUniform "U_C_Paramedic_01_F";
    _unit addVest "V_Plain_crystal_F";
  };

if(_category isEqualTo "Electronics") then
    {
      _units forceAddUniform "CUP_U_C_Worker_02";
    };

if(_category isEqualTo "Clothing") then
    {
      _units forceAddUniform "U_C_Man_casual_1_F";
      _unit addBackpack "B_Messenger_IDAP_F";
    };



[_unit,"self"] call OT_fnc_setOwner;

_unit disableAI "MOVE";
