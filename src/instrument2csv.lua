-- 将曲谱转csv文件
function instrument2csv_LUA(OpenFileName, SaveFileName)
    local file
    file = assert(io.open(OpenFileName, "rb")) -- 打开文件，并读取
    if not file then
        print("错误：无法打开文件", OpenFileName)
        return
    end

    if file:read(4) ~= "CNDK" then -- 检查文件类型标识
        file:close()
        print("错误：不是有效的JX3Instrument文件")
        return
    end
    file:seek("set", 16) -- 跳过文件头CNDK校验码，16字节
    local str = file:read("*a")
    file:close() -- 关闭文件
    local fn, err = loadstring(str) -- 读取剩余内容，并加载
    local tData = {}
    if fn then
        tData = fn() -- 执行加载的函数，获取曲谱数据表
    else
        print("错误：无法加载曲谱数据", err)
        return
    end

    local aAllData = {}
    table.insert(
        aAllData,
        'label,time,szState1,szKey1,\"return {nVersion='
            .. tData.nVersion .. ','
            .. 'szFileName=\"\"' .. tData.szFileName
            .. '\"\",\",SetSimMode 2 //szFileName:' .. tData.szFileName
            .. '\n'
    ) -- 表头
    -- 遍历原表，排序
    local keys = {}
    for k in pairs(tData) do
        if type(k) == "number" then
            table.insert(keys, k)
        end
    end
    table.sort(keys) -- 排序
    -- 遍历曲谱，写入文件
    for label, id in ipairs(keys) do
        table.insert(aAllData, label .. ',')
        table.insert(aAllData, id .. ',')
        table.insert(aAllData, tData[id].szState1 .. ',')
        table.insert(aAllData, tData[id].szKey1 .. ',')
        table.insert(aAllData, tData[id].szKey1 .. ',')
        table.insert(
            aAllData,
            '\"[' .. id
                .. ']={szState1=\"\"' .. tData[id].szState1
                .. '\"\",szKey1=\"\"' .. tData[id].szKey1
                .. '\"\"},\"\n'
        )
    end
    table.insert(aAllData, ',,,,}')
    local retStr = table.concat(aAllData) -- 合并为字符串
    file = io.open(SaveFileName, 'wb') -- 打开保存路径
    if file then
        file:write('\239\187\191', retStr) -- 写入数据
        file:close() -- 关闭文件
    end
 
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
