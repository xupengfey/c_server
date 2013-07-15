module("logic.constants.BattleType")

TEAM_STATUS = {
				["READY"] = 0,
			    ["WIN"] = 1,
			    ["LOSE"]  = 2,
}

FIELD_STATUS = {
				["INIT"] = 0,
			    ["BATTLEING"] = 1,
			    ["END"]  = 2,
}

BATTLE_TYPE = {
	["arena"] = 1,  --挑战
	["point"] = 2,  --关卡
	["boss"]  = 3,	--boss战	
	["multi_point"] = 4, --多人关卡	
}

BATTLE_STATE = {
					["NORMAL"] = 1,  --普通
					["SEAL"] = 2, --晕眩		
					["SKIP_PHY"] = 3,--跳过物理攻击
					["PHY_SEAL"] = 4, --物理晕眩	
					["MAGIC_SEAL"] = 5, --法术晕眩	
					["NON_CURE"] = 6, --不能治疗
					--["BLOOD_SUCK"] = 7, --嗜血
					--["BLOOD_ABSORB"] = 8, --吸血
					--["RABIT"] = 9, --狂热
}