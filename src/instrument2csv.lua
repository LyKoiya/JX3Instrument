-- 适配LUA版本
local lua51 = _VERSION == "Lua 5.1"
local lua54 = _VERSION == "Lua 5.4"
if lua51 then
    load = loadstring
end
if lua54 then
    loadstring = load
end

--将曲谱转csv文件
function instrument2csv_LUA(OpenFileName,SaveFileName)
	local file = assert(io.open(OpenFileName, "rb")) --打开文件，并读取
	file:seek("set", 16)  -- 跳过文件头CNDK校验码，16字节
	local szTable = loadstring(file:read("*a"))()  -- 读取剩余内容，并加载
	file:close() --关闭文件

    local retStr = "\xEF\xBB\xBF" .. 'label,time,szState1,szKey1,\"return {nVersion='.. szTable['nVersion'] .. ',' .. 'szFileName=\"\"' .. szTable['szFileName'] .. '\"\",\",SetSimMode 2 //szFileName:' .. szTable['szFileName'] .. '\n'  --表头
    --遍历原表，排序
    local keys = {}
    for k in pairs(szTable) do
        if type(k) == "number" then
            table.insert(keys, k)
        end
    end
    table.sort(keys) -- 排序
	--遍历曲谱，写入文件
    for label, id in ipairs(keys) do
		retStr = retStr .. label .. ',' .. id .. ',' .. szTable[id]['szState1'] .. ',' .. szTable[id]['szKey1'] .. ',\"[' ..id .. ']={szState1=\"\"'..szTable[id]['szState1'] .. '\"\",szKey1=\"\"' .. szTable[id]['szKey1'] .. '\"\"},\"\n'
	end
	retStr = retStr .. ',,,,}'
	file = io.open(SaveFileName, 'wb') --打开保存路径
	file:write(retStr) --写入数据
    file:close() --关闭文件

end

-- 入口检查启动参数
if #arg < 1 then
    os.exit(1) -- 启动参数为空，没有曲谱路径，则退出
	elseif #arg == 1 then
		arg[2] = arg[1] .. '.csv' -- 启动参数只有一个，填充第二参数保存路径
end

-- 调用曲谱转换函数
instrument2csv_LUA(arg[1], arg[2])

os.exit(1) -- 结束退出
