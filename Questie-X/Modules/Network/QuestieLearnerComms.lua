---@class QuestieLearnerComms
local QuestieLearnerComms = QuestieLoader:CreateModule("QuestieLearnerComms")
local _QuestieLearnerComms = QuestieLearnerComms.private

---@type QuestieLearner
local QuestieLearner = QuestieLoader:ImportModule("QuestieLearner")

local LibDeflate = LibStub("LibDeflate")
local AceSerializer = LibStub("AceSerializer-3.0")
local AceComm = LibStub("AceComm-3.0")

local addonPrefix = "QuestieLearner"
-- Emergency incident mitigation: pause all learner outbound broadcasts.
-- Keep receiving, local learning, saved data and existing settings intact.
local EMERGENCY_PAUSE_OUTBOUND = true -- Remain fail-closed until SmartSync v3 is complete
-- Shared BBLC25C membership is cooperative: each addon can join if needed.
-- Never leave, renumber, or alter chat frame subscriptions.
local hiddenChannelName = "BBLC25C"
local lastJoinAttempt = -100
local joinCooldown = 30
local loginReadyAt = nil
local loadingPaused = true
local outboundResumeAt = math.huge
-- Never claim /1 during login. Fail closed until a normal channel occupies /1.
local startupFrame = CreateFrame("Frame")
startupFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
startupFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
startupFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LEAVING_WORLD" then
        loadingPaused = true
        outboundResumeAt = math.huge
    else
        loadingPaused = false
        outboundResumeAt = GetTime() + 10
        loginReadyAt = GetTime() + 35
    end
end)
local function SafeToJoin()
    if not loginReadyAt or GetTime() < loginReadyAt then return false end
    local firstId, firstName = GetChannelName(1)
    return type(firstId) == "number" and firstId > 0
        and type(firstName) == "string" and firstName ~= ""
        and firstName:lower() ~= hiddenChannelName:lower()
end
local sentCount, receivedCount, sendErrors, lastSendError = 0, 0, 0, "none"
local incomingMessageQueue = {}
local incomingMessageQueueHead = 1
local incomingMessageQueueTail = 0
local assembledCount, duplicateChunks, rejectedChunks = 0, 0, 0
local learnedCount = 0
local transferSerial = 0
local partialTransfers = {}
local partialCount = 0
local MAX_CHUNKS, CHUNK_BYTES, MAX_PENDING = 64, 170, 256
local function ClearExpiredTransfers()
    local now = GetTime()
    for key, state in pairs(partialTransfers) do
        if now - state.started > 120 then
            partialTransfers[key] = nil
            partialCount = partialCount - 1
        end
    end
end
local function QueueIncoming(text, sender)
    if incomingMessageQueueTail - incomingMessageQueueHead >= MAX_PENDING then return end
    incomingMessageQueueTail = incomingMessageQueueTail + 1
    incomingMessageQueue[incomingMessageQueueTail] = {text = text, sender = sender}
end
local function AcceptChunk(msg, sender)
    local transfer, part, total, chunk = msg:match("^QX2:([%w]+):(%d+):(%d+):(.+)$")
    part, total = tonumber(part), tonumber(total)
    if not transfer or not part or not total or total < 1 or total > MAX_CHUNKS or part < 1 or part > total or #chunk > 400 then
        rejectedChunks = rejectedChunks + 1
        return
    end
    ClearExpiredTransfers()
    local key = sender .. ":" .. transfer
    local state = partialTransfers[key]
    if not state then
        if partialCount >= 48 then rejectedChunks = rejectedChunks + 1; return end
        state = {total = total, pieces = {}, count = 0, started = GetTime()}
        partialTransfers[key] = state
        partialCount = partialCount + 1
    end
    if state.total ~= total then rejectedChunks = rejectedChunks + 1; return end
    if state.pieces[part] then duplicateChunks = duplicateChunks + 1; return end
    state.pieces[part] = chunk
    state.count = state.count + 1
    if state.count == total then
        partialTransfers[key] = nil
        partialCount = partialCount - 1
        local assembled = table.concat(state.pieces)
        if #assembled <= MAX_CHUNKS * CHUNK_BYTES then
            assembledCount = assembledCount + 1
            QueueIncoming(assembled:gsub("||", "|"), sender)
        else
            rejectedChunks = rejectedChunks + 1
        end
    end
end
local function PublicSharingEnabled()
    local settings = Questie and Questie.dbLearner and Questie.dbLearner.global and Questie.dbLearner.global.settings
    return not settings or settings.learnerPublicChannelEnabled ~= false
end
local function EnsureLearnerChannel()
    if not PublicSharingEnabled() or type(GetChannelName) ~= "function" then return 0 end
    local id = GetChannelName(hiddenChannelName)
    if type(id) == "number" and id > 0 then return id end
    local now = GetTime()
    if SafeToJoin() and type(JoinChannelByName) == "function" and now - lastJoinAttempt >= joinCooldown then
        lastJoinAttempt = now
        JoinChannelByName(hiddenChannelName)
    end
    return 0
end
local function IsSharedChannel(channelId, channelName)
    local id = EnsureLearnerChannel()
    if id <= 0 then return false end
    if tonumber(channelId) == id then return true end
    if type(channelName) == "string" then
        local normalized = channelName:gsub("^%s*%d+%.%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
        return normalized:lower() == hiddenChannelName:lower()
    end
    return false
end

local ProtocolVersion = 2 -- Increment protocol version for enhanced/sanitized data

local time = time
local GetTime = GetTime
local math_min = math.min
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_getn = table.getn

-- Dev Logging Flags — defined first so all functions below can call DebugLog
local LOG_CRITICAL = true
local LOG_DEVELOP = false

local function DebugLog(tier, msg)
    if tier == "CRITICAL" and LOG_CRITICAL then
        -- print("[QuestieLearnerComms] " .. msg)
    elseif tier == "DEVELOP" and LOG_DEVELOP then
        -- print("[QuestieLearnerComms] " .. msg)
    end
end

local function SanitizeData(data, depth)
    depth = depth or 0
    if depth > 10 then return nil end -- Prevent infinite recursion
    if type(data) ~= "table" then return {} end
    local sanitized = {}
    for k, v in pairs(data) do
        if type(k) ~= "string" and type(k) ~= "number" then
            -- Skip non-string/number keys
        elseif type(v) == "function" or type(v) == "userdata" or type(v) == "thread" then
            -- Skip these types
        elseif type(v) == "table" then
            sanitized[k] = SanitizeData(v, depth + 1)
        else
            sanitized[k] = v
        end
    end
    return sanitized
end

-- Throttling (Token Bucket)
local bucketCapacity = 9
local bucketWindow = 60
local tokenRefillRate = bucketCapacity / bucketWindow
local currentTokens = bucketCapacity
local lastTokenUpdate = GetTime()
local minChatInterval = 3.5
local lastChatMessageTime = 0
local rateLimitQueue = {}
local rateLimitQueueHead = 1
local rateLimitQueueTail = 0

-- Deduplication & Quarantine
local messageCache = {}
local messageCacheCount = 0  -- O(1) counter; avoids pairs() scan on every message
-- Cached hidden channel ID (avoids GetChannelName every ProcessQueues tick)
local _hiddenChannelId = 0

-- Sender Trust System
local senderTrust = {}
local bannedSenders = {}
local mutedUntil = {}
local XXH = LibStub("XXH_Lua_Lib", true)

local function RecordStrike(sender, reason)
    if not senderTrust[sender] then senderTrust[sender] = { strikes = 0, lastMsg = 0, count = 0 } end
    senderTrust[sender].strikes = senderTrust[sender].strikes + 1
    DebugLog("DEVELOP", sender .. " gained a strike (" .. reason .. "). Total: " .. senderTrust[sender].strikes)

    if senderTrust[sender].strikes >= 7 then
        bannedSenders[sender] = true
        DebugLog("CRITICAL", "Sender " .. sender .. " permanently banned (7 strikes).")
    elseif senderTrust[sender].strikes >= 3 then
        mutedUntil[sender] = GetTime() + 300 -- 5-minute mute
        DebugLog("CRITICAL", "Sender " .. sender .. " muted for 5 minutes (3 strikes).")
    end
end

local function IsSenderTrusted(sender)
    if bannedSenders[sender] then return false end
    if mutedUntil[sender] then
        if GetTime() < mutedUntil[sender] then return false end
        mutedUntil[sender] = nil -- mute expired
    end
    if not senderTrust[sender] then senderTrust[sender] = { strikes = 0, lastMsg = 0, count = 0 } end

    local now = GetTime()
    if now - senderTrust[sender].lastMsg < 1.0 then
        senderTrust[sender].count = senderTrust[sender].count + 1
        if senderTrust[sender].count > 10 then
            RecordStrike(sender, "Spamming")
            senderTrust[sender].count = 0
            return false
        end
    else
        senderTrust[sender].count = 1
    end
    senderTrust[sender].lastMsg = now

    return true
end

local function IsDuplicateMessage(serializedData)
    local hash
    if XXH then
        hash = XXH.xxh32(serializedData, 0)
    else
        hash = 0
        for i = 1, string.len(serializedData) do
            hash = math.mod(hash + string.byte(serializedData, i), 4294967296)
        end
    end

    if messageCache[hash] then return true end

    -- O(1) size tracking via explicit counter
    messageCacheCount = messageCacheCount + 1
    if messageCacheCount > 500 then
        messageCache = {}
        messageCacheCount = 0
    end

    messageCache[hash] = true
    return false
end

local function GetLearnerSettings()
    if Questie and Questie.dbLearner and Questie.dbLearner.global and Questie.dbLearner.global.settings then
        return Questie.dbLearner.global.settings
    end
    return {}
end

local function GetCommsTuning()
    local intensity = GetLearnerSettings().learnerCommsIntensity or "normal"
    if intensity == "off" then
        return false, 0, 999999, 0, 0
    elseif intensity == "low" then
        return true, 4, 6.0, 2, 1
    elseif intensity == "fast" then
        return true, 15, 1.5, 10, 4
    end

    return true, 9, 3.5, 6, 2
end

function QuestieLearnerComms:Initialize()
    DebugLog("DEVELOP", "Initializing QuestieLearnerComms")
    AceComm:RegisterComm(addonPrefix, function(prefix, message, distribution, sender)
        QuestieLearnerComms:OnCommReceived(prefix, message, distribution, sender)
    end)
    _hiddenChannelId = EnsureLearnerChannel()
    QuestieCompat.C_Timer.NewTicker(0.5, function() _QuestieLearnerComms:ProcessQueues() end)
    QuestieCompat.C_Timer.NewTicker(60, function() _QuestieLearnerComms:ProcessReinforcement() end)
end

function _QuestieLearnerComms:ProcessReinforcement()
    if EMERGENCY_PAUSE_OUTBOUND then return end
    
    local categories = {"npcs", "quests", "items", "objects"}
    local category = categories[math.random(table.getn(categories))]
    
    if QuestieLearner.data[category] then
        -- We loop randomly until we find an unconfirmed entry. Just take the first few options to save CPU.
        local keys = {}
        for k, v in pairs(QuestieLearner.data[category]) do
            if type(v) == "table" and (v.mc or 0) < 7 then
                table.insert(keys, k)
                if table.getn(keys) >= 10 then break end -- Sample size 10
            end
        end

        if table.getn(keys) > 0 then
            local randomId = keys[math.random(table.getn(keys))]
            local data = QuestieLearner.data[category][randomId]
            local typ = string.upper(category)
            typ = string.sub(typ, 1, string.len(typ) - 1) -- Remove trailing 's' (NPC, QUEST, ITEM, OBJECT)
            
            DebugLog("DEVELOP", "[Reinforcement] Broadcasting " .. typ .. " " .. randomId)
            QuestieLearnerComms:BroadcastLearnedData("REINFORCE", typ, randomId, data)
        end
    end
end

function QuestieLearnerComms:BroadcastLearnedData(op, entityType, entityId, data)
    if EMERGENCY_PAUSE_OUTBOUND or loadingPaused or GetTime() < outboundResumeAt then return end
    if not GetCommsTuning() or not PublicSharingEnabled() then return end
    -- Allow local learned data to queue while the shared channel reconnects.
    EnsureLearnerChannel()
    if not data or type(data) ~= "table" then return end
    
    -- 1. Create Payload (sanitize data to remove functions before serialization)
    local sanitizedData = SanitizeData(data)
    if not sanitizedData or next(sanitizedData) == nil then return end
    
    local payload = {
        _ver = ProtocolVersion,
        op = op, -- "NEW", "UPDATE", "CONFIRM"
        typ = entityType,
        id = entityId,
        d = sanitizedData,
        ts = time()
    }

    -- 2. Serialize and Compress
    local serialized
    local success, err = pcall(AceSerializer.Serialize, AceSerializer, payload)
    if not success then
        DebugLog("CRITICAL", "AceSerializer error: " .. tostring(err))
        return
    end
    serialized = err
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 1})
    local encoded = LibDeflate:EncodeForPrint(compressed)

    -- 3. Broadcast (Token Bucket logic handled in QueueMessage)
    _QuestieLearnerComms:QueueMessage(encoded)
end

function _QuestieLearnerComms:QueueMessage(encodedMessage)
    if EMERGENCY_PAUSE_OUTBOUND then return end
    if not GetCommsTuning() or not PublicSharingEnabled() then return end
    -- Prevent unbounded growth while offline or during long channel outages.
    if rateLimitQueueTail - rateLimitQueueHead >= MAX_PENDING then
        sendErrors = sendErrors + 1
        lastSendError = "outgoing queue full"
        return
    end
    local escaped = encodedMessage:gsub("|", "||")
    local total = math.ceil(#escaped / CHUNK_BYTES)
    if total > MAX_CHUNKS then
        sendErrors = sendErrors + 1
        lastSendError = "discovery too large for bounded transfer"
        return
    end
    transferSerial = transferSerial + 1
    local transfer = string.format("%x%x", math.floor(GetTime() * 1000) % 0xFFFFFF, transferSerial % 0xFFFFFF)
    for i = 1, total do
        rateLimitQueueTail = rateLimitQueueTail + 1
        rateLimitQueue[rateLimitQueueTail] = "QX2:" .. transfer .. ":" .. i .. ":" .. total .. ":" .. escaped:sub((i-1)*CHUNK_BYTES+1, i*CHUNK_BYTES)
    end
end

function _QuestieLearnerComms:ProcessQueues()
    if EMERGENCY_PAUSE_OUTBOUND then
        rateLimitQueue = {}
        rateLimitQueueHead, rateLimitQueueTail = 1, 0
    end
    local commsEnabled, tunedBucketCapacity, tunedMinChatInterval, normalIncomingCount, combatIncomingCount = GetCommsTuning()
    bucketCapacity = tunedBucketCapacity or 9
    tokenRefillRate = bucketCapacity / bucketWindow
    minChatInterval = tunedMinChatInterval or 3.5
    currentTokens = math_min(bucketCapacity, currentTokens)
    if not commsEnabled or not PublicSharingEnabled() then
        rateLimitQueue = {}
        rateLimitQueueHead, rateLimitQueueTail = 1, 0
        return
    end

    -- 1. Refill Tokens
    local now = GetTime()
    local elapsed = now - lastTokenUpdate
    currentTokens = math_min(bucketCapacity, currentTokens + (elapsed * tokenRefillRate))
    lastTokenUpdate = now

    -- 2. Drain Outgoing Queue
    if not EMERGENCY_PAUSE_OUTBOUND and not loadingPaused and now >= outboundResumeAt and rateLimitQueueHead <= rateLimitQueueTail and currentTokens >= 1 and (now - lastChatMessageTime) >= minChatInterval then
        -- LootCollector may join after login; hold queued data until it is available.
        _hiddenChannelId = EnsureLearnerChannel()
        if _hiddenChannelId > 0 then
        local msg = rateLimitQueue[rateLimitQueueHead]
        rateLimitQueue[rateLimitQueueHead] = nil
        rateLimitQueueHead = rateLimitQueueHead + 1
        if rateLimitQueueHead > rateLimitQueueTail then
            rateLimitQueueHead = 1
            rateLimitQueueTail = 0
        end
        currentTokens = currentTokens - 1
        lastChatMessageTime = now
        
        -- QX2 chunks have already escaped pipe characters and fit chat limits.
        local wire = msg
        if #wire <= 240 then
            local ok, err = pcall(SendChatMessage, wire, "CHANNEL", nil, _hiddenChannelId)
            if ok then sentCount = sentCount + 1 else
                sendErrors = sendErrors + 1
                lastSendError = tostring(err):sub(1, 100)
            end
        else
            sendErrors = sendErrors + 1
            lastSendError = "internal chunk exceeds chat limit"
        end
        DebugLog("DEVELOP", "Broadcasted message. Tokens left: " .. math_floor(currentTokens))
        end
    end

    -- 3. Process Incoming Queue (Combat Aware)
    local processCount = (InCombatLockdown() and combatIncomingCount or normalIncomingCount) or 1
    if loadingPaused then processCount = 0 end
    processCount = math_min(processCount, 2)
    local incomingStartedAt = debugprofilestop and debugprofilestop() or nil
    for i = 1, processCount do
        if incomingStartedAt and debugprofilestop() - incomingStartedAt >= 1 then break end
        if incomingMessageQueueHead > incomingMessageQueueTail then break end
        local rawMsg = incomingMessageQueue[incomingMessageQueueHead]
        incomingMessageQueue[incomingMessageQueueHead] = nil
        incomingMessageQueueHead = incomingMessageQueueHead + 1
        if incomingMessageQueueHead > incomingMessageQueueTail then
            incomingMessageQueueHead = 1
            incomingMessageQueueTail = 0
        end
        _QuestieLearnerComms:ProcessRawMessage(rawMsg.text, rawMsg.sender)
    end
end

-- Hook for Chat Message Event (Hidden Channel)
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:SetScript("OnEvent", function(self, event, msg, sender, _, _, _, _, _, channelId, channelName)
    local commsEnabled = GetCommsTuning()
    if not GetCommsTuning() or not PublicSharingEnabled() then return end
    if IsSharedChannel(channelId, channelName) and sender ~= UnitName("player")
        and type(msg) == "string" then
        if msg:sub(1, 4) == "QX3:" then
            receivedCount = receivedCount + 1
            AcceptChunk(msg, sender)
        -- Legacy QX1/QX2 messages are intentionally ignored.
        end
    end
end)

function QuestieLearnerComms:OnCommReceived(prefix, message, distribution, sender)
    if not GetCommsTuning() or not PublicSharingEnabled() then return end
    -- Legacy AceComm payloads are not SmartSync v3; reject before decoding.
end

function _QuestieLearnerComms:ProcessRawMessage(encodedMsg, sender)

    -- 1. Decode & Decompress
    local compressed = LibDeflate:DecodeForPrint(encodedMsg)
    if not compressed then
        RecordStrike(sender, "Invalid Base64 Encoding")
        return 
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then 
        RecordStrike(sender, "Decompression Failed")
        return 
    end

    -- Deduplication Check
    if IsDuplicateMessage(serialized) then return end

    -- 2. Deserialize
    local success, payload = AceSerializer:Deserialize(serialized)
    if not success or type(payload) ~= "table" then
        RecordStrike(sender, "Deserialization Failed")
        return
    end

    -- 3. Version Check
    if payload._ver ~= ProtocolVersion then return end

    -- 4. Pass to Learner Processing Logic
    local op = payload.op
    local typ = payload.typ
    local id = payload.id
    local d = payload.d

    if not typ or not id or not d then return end

    DebugLog("DEVELOP", "Received " .. tostring(op) .. " " .. tostring(typ) .. " " .. tostring(id) .. " from " .. tostring(sender))

    local ok, result = pcall(QuestieLearner.HandleNetworkData, QuestieLearner, typ, id, d, op)
    if ok and result == true then learnedCount = learnedCount + 1 end
end

-- Minimal diagnostics; no new chat channel or visible frame required.
SLASH_QUESTIELEARNERSHARE1 = "/questieshare"
SlashCmdList.QUESTIELEARNERSHARE = function(command)
    command = (command or ""):lower():match("^%s*(.-)%s*$")
    local settings = Questie and Questie.dbLearner and Questie.dbLearner.global and Questie.dbLearner.global.settings
    if command == "on" and settings then settings.learnerPublicChannelEnabled = true
    elseif command == "off" and settings then settings.learnerPublicChannelEnabled = false end
    local id = type(GetChannelName) == "function" and GetChannelName(hiddenChannelName) or 0
    local enabled = PublicSharingEnabled()
    local pending = math.max(0, rateLimitQueueTail - rateLimitQueueHead + 1)
    print("Questie-X Learner: sharing=" .. tostring(enabled) .. " channel=" .. tostring(id)
        .. " sent=" .. sentCount .. " received=" .. receivedCount .. " queued=" .. pending
        .. " errors=" .. sendErrors .. " lastError=" .. lastSendError)
    print("Questie-X transfer: assembled=" .. assembledCount .. " learnedConfirmed=" .. learnedCount
        .. " duplicateChunks=" .. duplicateChunks .. " rejectedChunks=" .. rejectedChunks
        .. " partial=" .. partialCount)
end
