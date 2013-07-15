module("logic.constants.ActionType");

ACTION_TYPE = {}
ACTION_TYPE["PHY_ATTACK"] = 1     --物理攻击
ACTION_TYPE["GROUP_PHY_ATTACK"] = 2  --物理群攻
ACTION_TYPE["MAGIC_ATTACK"] = 3       --法术攻击
ACTION_TYPE["GROUP_MAGIC_ATTACK"] = 4  --法术群攻
ACTION_TYPE["HP_CHANGE"] = 5           --血量增减
ACTION_TYPE["ATK_CHANGE"] = 6          --攻击力增减
ACTION_TYPE["ATK_CHANGE_ONCE"] = 7     --攻击力临时增减
ACTION_TYPE["DEAD"] = 9                --死亡
ACTION_TYPE["ADD_DEBUFF"] = 11         --加buff
ACTION_TYPE["REMOVE_DEBUFF"] =12       
ACTION_TYPE["ADD_STATUS"] = 13         --状态

