
-- CREATE TABLE `t_character` (
--   `id` int(11) NOT NULL AUTO_INCREMENT,
--   `accName` varchar(60) NOT NULL DEFAULT '' COMMENT '帐号名',
--   `charName` varchar(60) NOT NULL DEFAULT '' COMMENT '角色名',
--   `marshalId` int(11) NOT NULL DEFAULT '0' COMMENT '主将配置表id',
--   `gold` int(11) NOT NULL DEFAULT '0' COMMENT '剩余金币',
--   `goldTotal` int(11) NOT NULL DEFAULT '0' COMMENT '充值金币',
--   `vipLevel` int(11) NOT NULL DEFAULT '0' COMMENT 'vip等级',
--   `lv` int(11) NOT NULL DEFAULT '1' COMMENT '角色等级',
--   `exp` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色经验',
--   `tili` int(11) NOT NULL DEFAULT '0' COMMENT '体力',
--   `b_citywar` longblob NOT NULL COMMENT '光卡信息',
--   `b_card` longblob NOT NULL COMMENT '卡牌信息',
--   `time` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
--   `logoutTime` int(11) NOT NULL DEFAULT '0' COMMENT '上次登出时间',
--   PRIMARY KEY (`id`),
--   KEY `accName` (`accName`),
--   KEY `charName` (`charName`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8$$
local mSys = require "system.sys"
local mTimer = require "system.timer"
local mConfig = require "config"
local mChar = require "logic.character"
module ("logic.login",package.seeall)

loginAccNameMap = {}
loginSockMap = {}

function onQueryLogin( ret,sockId,accName )
  print("onQueryLogin", ret, sockId, accName)
  if type(ret) ~= "table" then
    mSys.log(ERROR, "onQueryLogin ret:" ..tostring(ret))
    return
  end  

  print("#ret", #ret)
  if #ret == 0 then
    if mConfig.AUTO_CREATECHAR == true then
      local randName = "rd-"..tostring(math.random(100000))
      local randMid = math.random(6)
      createChar(sockId, {charName=randName,mid=randMid})
    else
      mSys.callClient(sockId, "onCreateChar")
    end
    return 
  end 

  loginAccNameMap[accName] = nil
  loginSockMap[sockId] = nil

  assert(#ret == 1)
  local char = {data=ret[1]}
  char.sockId = sockId
  mChar.loginData(char)
  -- printTable(char)
  mSys.callClient(sockId, "onLogin", ret[1])


  -- body
end

-- params
--   accName
function login( sockId,params )
  assert(type(params.accName) == type(""))
  if loginSockMap[sockId] ~= nil then
    return
  end 
  if loginAccNameMap[params.accName] ~= nil then
    return
  end 
  loginAccNameMap[params.accName] =  os.time()
  loginSockMap[sockId] = params.accName

  print("params.accName", params.accName)

  local sql = "select * from t_character where accName='"..mSys.escapedStr(params.accName).."'"
  mSys.dbQuery(sql, onQueryLogin,sockId, params.accName)
end



-- params
--   charName
--   mid
function createChar( sockId,params )
  assert(type(params.charName) == type(""))
  assert(type(params.mid) == type(0))
  local sql = "select id from t_character where charName='"..mSys.escapedStr(params.charName).."'"
  mSys.dbQuery(sql, onQueryChar,sockId,params)
end

function onQueryChar( ret,sockId,params )
  if #ret > 0 then
    print("charName not available")
    mSys.callClient(sockId, "onSysInfo", "角色名已存在")
    return
  end  
  local accName = loginSockMap[sockId]
  local sql = "insert into t_character (accName,charName,marshalId,time) "..
              "values ('"..accName.."','"..params.charName.."','"..params.mid.."',"..os.time()..")"
  mSys.dbQuery(sql,onInsertChar)

  sql = "select * from t_character where accName='"..mSys.escapedStr(accName).."'"
  mSys.dbQuery(sql, onQueryLogin,sockId, accName)

end


function onInsertChar( ret )
  print("onInsertChar",ret)
end

function logout( sockId )
  local char = mChar.getCharBySocket(sockId)
  if char == nil then
    return
  end  
  mChar.logoutData(char)
end
