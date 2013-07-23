--encoding=utf-8
-----------------------------------------------------------------------------
--| 字符串相关的一些处理
-----------------------------------------------------------------------------

-- 分割字符串
function splitString(str,delimiter)
   local args = {};
   local pattern = '(.-)' .. delimiter;
   local last_end = 1;
   local s,e,cap = string.find(str,pattern, 1);
   while s do
      if s ~= 1 or cap ~= '' then
		table.insert(args,cap);
      end
      last_end = e + 1;
      s,e,cap = string.find(str,pattern,last_end);
   end
   if last_end <= #str then
      cap = string.sub(str,last_end);
      table.insert(args,cap);
   end
   return args;
end

--去除字符串头部和尾部的空格 \t等
function trim(str)
	local tmp = string.gsub(str,"^%s+","")
	tmp = string.gsub(tmp,"%s+$","")
	return tmp
end
function splitWithTrim(str,delim)
	local args = {}
	local pattern = '(.-)' .. delim
	local last_end = 1
	local s,e,cap = string.find(str,pattern , 1)
	while s do
		local tmp = trim(cap)
		if tmp ~= '' then
			table.insert(args,tmp)
		end
		last_end = e+1
		s,e,cap = string.find(str,pattern,last_end)
	end
	if last_end <= #str then
		cap = trim(string.sub(str,last_end))
		if cap ~= "" then
			table.insert(args,cap)
		end
	end
	return args
end
--*****************************************
-- 切割字符串，返回数组 @author lihebin
--*****************************************
function cutString(str, c)
	local arr = {}
	local k = 1
	local i = 1
	local j = 1
	while j <= string.len(str) do
		if string.sub(str, j, j) == c then
			if i <= j-1 then
				arr[k] = string.sub(str, i, j-1)
				k = k+1
			end
			i = j+1
		elseif j == string.len(str) then
			arr[k] = string.sub(str, i, j)
			break
		end
		j = j+1
	end
	return arr
end

