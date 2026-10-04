-- 适配LUA版本
local lua51 = _VERSION == "Lua 5.1"
local lua54 = _VERSION == "Lua 5.4"
if lua51 then
    load = loadstring
end
if lua54 then
    loadstring = load
end

-- 音符编号映射键盘布局
local mapKey = {
	[0] = "",
	[1] = "",
	[2] = "",
	[3] = "",
	[4] = "",
	[5] = "",
	[6] = "",
	[7] = "",
	[8] = "",
	[9] = "",
	[10] = "",
	[11] = "",
	[12] = "",
	[13] = "",
	[14] = "",
	[15] = "",
	[16] = "",
	[17] = "",
	[18] = "",
	[19] = "",
	[20] = "",
	[21] = "",
	[22] = "",
	[23] = "",
	[24] = "",
	[25] = "",
	[26] = "",
	[27] = "",
	[28] = "",
	[29] = "",
	[30] = "",
	[31] = "",
	[32] = "",
	[33] = "",
	[34] = "",
	[35] = "",
	[36] = "B", -- (C2)
	[37] = "",
	[38] = "N", -- (D2)
	[39] = "",
	[40] = "M", -- (E2)
	[41] = "",
	[42] = "",
	[43] = "",
	[44] = "",
	[45] = "",
	[46] = "",
	[47] = "",
	[48] = "A", -- (C3)
	[49] = "",
	[50] = "S", -- (D3)
	[51] = "",
	[52] = "D", -- (E3)
	[53] = "F", -- (F3)
	[54] = "",
	[55] = "G", -- (G3)
	[56] = "",
	[57] = "H", -- (A3)
	[58] = "",
	[59] = "J", -- (B3)
	[60] = "Q", -- (C4)
	[61] = "",
	[62] = "W", -- (D4)
	[63] = "",
	[64] = "E", -- (E4)
	[65] = "R", -- (F4)
	[66] = "",
	[67] = "T", -- (G4)
	[68] = "",
	[69] = "Y", -- (A4)
	[70] = "",
	[71] = "U", -- (B4)
	[72] = "1", -- (C5)
	[73] = "",
	[74] = "2", -- (D5)
	[75] = "",
	[76] = "3", -- (E5)
	[77] = "4", -- (F5)
	[78] = "",
	[79] = "5", -- (G5)
	[80] = "",
	[81] = "",
	[82] = "",
	[83] = "",
	[84] = "",
	[85] = "",
	[86] = "",
	[87] = "",
	[88] = "",
	[89] = "",
	[90] = "",
	[91] = "",
	[92] = "",
	[93] = "",
	[94] = "",
	[95] = "",
	[96] = "",
	[97] = "",
	[98] = "",
	[99] = "",
	[100] = "",
	[101] = "",
	[102] = "",
	[103] = "",
	[104] = "",
	[105] = "",
	[106] = "",
	[107] = "",
	[108] = "",
	[109] = "",
	[110] = "",
	[111] = "",
	[112] = "",
	[113] = "",
	[114] = "",
	[115] = "",
	[116] = "",
	[117] = "",
	[118] = "",
	[119] = "",
	[120] = "",
	[121] = "",
	[122] = "",
	[123] = "",
	[124] = "",
	[125] = "",
	[126] = "",
	[127] = ""
}

-- 返回音符映射按键
function getKey(szNote)
    -- 返回映射函数
    return mapKey[szNote] or "?"  -- 未映射的音符返回"?"
end

-- MIDI常量定义
local MIDI_EVENT = {
    NOTE_OFF = 0x8,
    NOTE_ON = 0x9,
    META = 0xFF,
    SET_TEMPO = 0x51,
    END_OF_TRACK = 0x2F
}

-- 读取可变长度值 (VLQ)
function read_vlq(data, index)
    local value = 0
    while true do
        local byte = data:byte(index)
        index = index + 1
        value = (value * 128) + (byte % 128)
        if byte < 128 then
            break
        end
    end
    return value, index
end

-- midi转csv
function midi2table(FileName)
    local file = io.open(FileName, "rb")
    if not file then return nil, "无法打开文件" end

    local data = file:read("*a")
    file:close()

    local index = 1
    local events = {}
    local track_count = 0
    local tempo = 500000  -- 默认速度: 500000微秒/四分音符 (120 BPM)
    local tempo_events = {}

    -- 解析文件头
    local header = data:sub(index, index + 3)
    index = index + 4
    if header ~= "MThd" then
        return nil, "无效MIDI文件头"
    end

    index = index + 4  -- 跳过头长度(6)
    local format = data:byte(index) * 256 + data:byte(index + 1)
    index = index + 2

    track_count = data:byte(index) * 256 + data:byte(index + 1)
    index = index + 2

    local ticks_per_quarter = data:byte(index) * 256 + data:byte(index + 1)
    index = index + 2

    -- 解析所有轨道
    for track = 1, track_count do
        local track_header = data:sub(index, index + 3)
        index = index + 4
        if track_header ~= "MTrk" then
            return nil, "无效轨道头"
        end

        local track_length = data:byte(index) * 16777216 +
                             data:byte(index + 1) * 65536 +
                             data:byte(index + 2) * 256 +
                             data:byte(index + 3)
        index = index + 4

        local track_end = index + track_length
        local time = 0
        local last_status = 0

        -- 解析轨道内事件
        while index < track_end do
            local delta, new_index = read_vlq(data, index)
            index = new_index
            time = time + delta

            local status = data:byte(index)
            index = index + 1

            -- 处理运行状态
            if status < 0x80 then
                status = last_status
                index = index - 1  -- 回退位置
            else
                last_status = status
            end

            -- 替代位运算获取事件类型和通道
            local event_type = math.floor(status / 16)
            local channel = status % 16

            -- 音符事件处理
            if event_type == MIDI_EVENT.NOTE_ON or event_type == MIDI_EVENT.NOTE_OFF then
                local note = data:byte(index)
                index = index + 1
                local velocity = data:byte(index)
                index = index + 1

                -- NOTE_ON且力度为0视为松开事件
                local event_name = (event_type == MIDI_EVENT.NOTE_ON and velocity > 0)
                                  and "DOWN" or "UP"

                table.insert(events, {
                    time = time,
                    event = event_name,
                    note = note,
                    track = track
                })

            -- 元事件处理
            elseif status == MIDI_EVENT.META then
                local meta_type = data:byte(index)
                index = index + 1
                local length, new_index = read_vlq(data, index)
                index = new_index

                if meta_type == MIDI_EVENT.SET_TEMPO then
                    -- 解析速度事件
                    tempo = data:byte(index) * 65536 +
                            data:byte(index + 1) * 256 +
                            data:byte(index + 2)
                    index = index + 3

                    -- 记录速度变化事件
                    table.insert(tempo_events, {
                        time = time,
                        tempo = tempo
                    })

                elseif meta_type == MIDI_EVENT.END_OF_TRACK then
                    index = index + length  -- 跳过结束事件
                    break
                else
                    index = index + length  -- 跳过其他元事件
                end
            else
                -- 跳过其他事件
                if event_type == 0xF then  -- 系统独占
                    local length, new_index = read_vlq(data, index)
                    index = new_index + length
                else
                    -- 标准MIDI事件长度
                    local event_lengths = {2, 2, 2, 1, 1, 1}  -- 0xA-0xE
                    index = index + (event_lengths[event_type - 0xA] or 0)
                end
            end
        end
    end

    -- 按时间排序所有音符事件
    table.sort(events, function(a, b)
        return a.time < b.time
    end)

    -- 按时间排序速度变化事件
    table.sort(tempo_events, function(a, b)
        return a.time < b.time
    end)

    -- 转换时间到毫秒
    local function ticks_to_ms(ticks, current_tempo)
        -- 计算毫秒时间 = (ticks / ticks_per_quarter) * (tempo / 1000)
        return (ticks / ticks_per_quarter) * (current_tempo / 1000)
    end

    local current_tempo = 500000  -- 默认速度
    local last_tempo_event_time = 0
    local last_tempo_event_index = 1

    -- 转换每个事件的时间到毫秒
    for i, event in ipairs(events) do
        -- 检查是否有速度变化事件在当前事件之前
        while last_tempo_event_index <= #tempo_events and
              tempo_events[last_tempo_event_index].time <= event.time do
            local tempo_event = tempo_events[last_tempo_event_index]
            current_tempo = tempo_event.tempo
            last_tempo_event_time = tempo_event.time
            last_tempo_event_index = last_tempo_event_index + 1
        end

        -- 计算时间差（从上一个速度变化事件到当前事件）
        local delta_ticks = event.time - last_tempo_event_time

        -- 计算毫秒时间
        local time_in_ms = ticks_to_ms(last_tempo_event_time, current_tempo) +
                          ticks_to_ms(delta_ticks, current_tempo)

        event.time_ms = time_in_ms
    end

    return events, ticks_per_quarter, tempo_events
end


function midi2csv_LUA (OpenFileName,SaveFileName)

	local events, ticks_per_quarter = midi2table(OpenFileName)
	if not events then
		print("解析错误:", ticks_per_quarter)
		os.exit(1)
	end

	-- 生成CSV文件
	local csv = io.open(SaveFileName, "w")
	csv:write("label,time,szState1,szKey1," .. '\"return {nVersion=1,szFileName=\"\"' .. 'text' .. '\"\",\",' ..'SetSimMode 2\n')
	local nTime = 0
	local nKey = ""
	for i, event in ipairs(events) do
		if nTime == event.time then
			event.time = event.time + 1
		elseif nTime > event.time then
			event.time = nTime + 1
		end
		nTime = event.time
		--event.note = event.note % 12 + 1
		nKey = getKey(event.note)
		if nKey == "" then
			nKey = event.note
		end
		csv:write(string.format("%d,%d,%s,%s\n", i, event.time, event.event, nKey))
	end

	csv:close()
	print(string.format("解析成功! 共处理%d个音符事件", #events))
	print(string.format("时间单位: %d ticks/quarter note", ticks_per_quarter))
	print("输出文件:", SaveFileName)
end


-- 入口检查启动参数
if #arg < 1 then
    os.exit(1) -- 启动参数为空，没有曲谱路径，则退出
elseif #arg == 1 then
	arg[2] = arg[1] .. '.csv' -- 启动参数只有一个，填充第二参数保存路径
end

-- 调用曲谱转换函数
midi2csv_LUA(arg[1], arg[2])

os.exit(1) -- 结束退出
