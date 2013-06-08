local os,pairs,unpack,table,print,type,pairs,pcall,C_log,debug
	= os,pairs,unpack,table,print,type,pairs,pcall,C_log,debug


module ("system.timer")

timerCol = {}

--- 新增timerout timer
-- @param func 回调函数
-- @param delay 延迟
function setTimeOut(func,delay,...)
	local arg = {...}
	local now = os.time()*1000
	local expire = now + delay
	local timer = newTimer(func,expire,delay,false,arg)
	addTimer(timer)
	return timer
end

--- 新增interval timer
-- @param func 回调函数
-- @param delay 间隔
function setInterval(func,delay,...)
	local arg = {...}
	local now = os.time()*1000
	local expire = now + delay
	local timer = newTimer(func,expire,delay,true,arg)
	addTimer(timer)
	return timer
end

--- 清除 timer
-- @param timer timer
function clearTimer(timer)
	if timer ~= nil then
		timerCol[timer] = nil
	end
end

function newTimer(func,expire,delay,rep,param)
	local timer = {}
	timer["func"]  = func
	timer["expire"] = expire
	timer["rep"] = rep
	timer["param"] = param
	timer["delay"] = delay
	return timer
end

function addTimer(timer)
	timerCol[timer] = true
end

function clearExpire()
	for i,_ in pairs(timerCol) do
		if timerCol[i] == false then
			timerCol[i] = nil
		end
	end
end

function runTimer()
	local funcRes = true
	local errorInfo = nil
	local now = os.time() * 1000
	for timer,_ in pairs(timerCol) do
		if timer.expire <= now then	
			if timer.param then
				funcRes,errorInfo = pcall(timer.func,unpack(timer.param))
			else
				funcRes,errorInfo = pcall(timer.func)
			end
			if funcRes == false then
				C_log(2,errorInfo)
				C_log(2,debug.traceback())
			end
			if timer.rep == false then
				timerCol[timer] = nil
			else
				timer.expire = now + timer.delay
			end
		end
	end
	--clearExpire()
end