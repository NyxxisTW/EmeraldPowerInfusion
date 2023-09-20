-- by using this addon you agree to sell your soul to player named Nyxxis at Turtle WoW
-- https://armory.turtle-wow.org/#!/character/Nyxxis
-- https://github.com/NyxxisTW

local Addon = CreateFrame("FRAME")
local DeltaTime = 0
local OldTime = GetTime()
local IconLifeSpan = 0
local PITarget = nil
local PITargetName = nil
local RemainingCDPosted = false

local DEFAULT_SCALE = 1.0
local DEFAULT_ALPHA = 0.8
local DEFAULT_PASSWORD = "PI me now!"
local DEFAULT_RESPONSE = "PI used!"

EmeraldPowerInfusion_Config = {
	Scale = DEFAULT_SCALE,
	Alpha = DEFAULT_ALPHA,
	Password = DEFAULT_PASSWORD,
	Response = DEFAULT_RESPONSE,
}


----- COMMUNICATION -----

local START_COLOR = "\124CFF"
local END_COLOR = "\124r"

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("[EPI]: "..tostring(msg))
end

local function Error(msg)
	local COLOR = "FF0000"
	DEFAULT_CHAT_FRAME:AddMessage("[EPI]: "..START_COLOR..COLOR..tostring(msg)..END_COLOR)
end

local function SendMessage(message, target)
	if (not target) then target = UnitName(PITarget) end
	if (not target) then return end
	local channel = "WHISPER"
	local language = GetDefaultLanguage()
	SendChatMessage(message, channel, language, target)
end

----- UTILITY -----

local function SetScale(frame, scale)
	local prevScale = frame:GetScale()
	local point, _, _, xOfs, yOfs = frame:GetPoint()
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint(point, xOfs / (scale / prevScale), yOfs / (scale / prevScale))
end

local function Round(value, precision)
	return tonumber(string.format("%."..precision.."f", value))
end

local function GetPISpell()
	local spell = 1
	while true do
		local spellName = GetSpellName(spell, BOOKTYPE_SPELL)
		if (not spellName) then return end
		if (spellName == "Power Infusion") then
			break
		end
		spell = spell + 1
	end
	return spell
end

function string.empty(str)
	if (str == nil) then return true end
	if (str == "") then return true end
	local i = 1
	while i <= strlen(str) do
		local char = strsub(str, i, i)
		if (char ~= " ") then
			return false
		end
		i = i + 1
	end
	return true
end

local function NotEnoughMana()
	local mana = UnitMana("player")
	local _,_,_,_,rank = GetTalentInfo(1, 10)
	local required = 275 * (1 - 0.02 * rank)
	return (mana < required)
end

----- COMMANDS -----

local function CommandPI(msg, msglower)
	if (msglower == "pi" or msglower == "power infusion") then
		EmeraldPowerInfusion()
		return true
	end
	return false
end

local function CommandShow(msg, msglower)
	if (msglower == "show") then
		EmeraldPowerInfusion_PIIcon:Show()
		EmeraldPowerInfusion_PIIcon:EnableMouse(true)
		return true
	end
	return false
end

local function CommandHide(msg, msglower)
	if (msglower == "hide") then
		EmeraldPowerInfusion_PIIcon:Hide()
		EmeraldPowerInfusion_PIIcon:EnableMouse(false)
		return true
	end
	return false
end

local function CommandScale(msg, msglower)
	if (strsub(msglower, 1, 5) == "scale") then
		local value = string.sub(msg, 7)
		local scale = tonumber(value)
		if (not scale) then
			Error("Invalid value ("..value..").")
			return true
		end 
		SetScale(EmeraldPowerInfusion_PIIcon, scale)
		EmeraldPowerInfusion_Config.Scale = scale
		Print("Icon's scale set to \""..START_COLOR.."00AA00"..scale..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandAlpha(msg, msglower)
	if (strsub(msglower, 1, 5) == "alpha") then
		local value = string.sub(msg, 7)
		local alpha = tonumber(value)
		if (not alpha) then
			Error("Invalid value ("..value..").")
			return true
		end
		EmeraldPowerInfusion_PIIcon:SetAlpha(alpha)
		EmeraldPowerInfusion_Config.Alpha = alpha
		Print("Icon's alpha channel set to \""..START_COLOR.."00AA00"..alpha..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandPW(msg, msglower)
	local password = nil
	if (strsub(msglower, 1, 14) == "trigger message") then
		password = strsub(msg, 16)
	elseif (strsub(msglower, 1, 10) == "trigger msg") then
		password = strsub(msg, 12)
	elseif (strsub(msglower, 1, 8) == "password") then
		password = strsub(msg, 10)
	elseif (strsub(msglower, 1, 2) == "pw" or strsub(msglower, 1, 2) == "tm") then
		password = strsub(msg, 4)
	end
	if (not password) then return false end
	if (string.empty(password)) then
		Error("Invalid value ("..password..").")
		return true
	end
	EmeraldPowerInfusion_Config.Password = password
	Print("Trigger message set to \""..START_COLOR.."00AA00"..password..END_COLOR.."\"")
	return true
end

local function CommandRes(msg, msglower)
	local response = nil
	if (strsub(msglower, 1, 8) == "response") then
		response = strsub(msg, 10)
	elseif (strsub(msglower, 1, 3) == "res") then
		response = strsub(msg, 5)
	end
	if (not response) then return false end
	if (string.empty(response)) then
		Error("Invalid value ("..response..").")
		return true
	end
	EmeraldPowerInfusion_Config.Response = response
	Print("Message sent while casting PI set to \""..START_COLOR.."00AA00"..response..END_COLOR.."\"")
	return true
end

local function CommandPrintPW(msg, msglower)
	if (msglower == "printpw" or
		msglower == "print pw" or
		msglower == "printpassword" or
		msglower == "print password" or
		msglower == "printtm" or
		msglower == "print tm" or
		msglower == "printtriggermsg" or
		msglower == "print trigger msg" or
		msglower == "print triggermsg" or
		msglower == "printtriggermessage" or
		msglower == "print trigger message" or
		msglower == "print triggermessage") then
		Print("Current trigger message: \""..START_COLOR.."00AA00"..EmeraldPowerInfusion_Config.Password..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandPrintRes(msg, msglower)
	if (msglower == "printres" or
		msglower == "print res" or
		msglower == "printresponse" or
		msglower == "print response") then
		Print("Current message sent while casting PI: \""..START_COLOR.."00AA00"..EmeraldPowerInfusion_Config.Response..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandHelp(msg, msglower, force)
	if (msglower == "help" or force) then
		local COLOR = "FFFF99"
		Print("Commands:")
		Print(START_COLOR..COLOR.."/run EmeraldPowerInfusion()"..END_COLOR.." or "
			..START_COLOR..COLOR.."/epi pi"..END_COLOR.." - macro to cast Power Infusion.")
		Print(START_COLOR..COLOR.."/epi show"..END_COLOR.." - sets status of PI icon to visible and allows mouse dragging.")
		Print(START_COLOR..COLOR.."/epi hide"..END_COLOR.." - hides PI icon.")
		Print(START_COLOR..COLOR.."/epi scale \"number\""..END_COLOR.." - set PI icon's scale to given number.")
		Print(START_COLOR..COLOR.."/epi alpha \"number\""..END_COLOR.." - sets PI icon's alpha channel to given number.")
		Print(START_COLOR..COLOR.."/epi pw \"text\""..END_COLOR.." - sets text of trigger message.")
		Print(START_COLOR..COLOR.."/epi res \"text\""..END_COLOR.." - sets text of message sent while casting PI.")
		Print(START_COLOR..COLOR.."/epi print pw"..END_COLOR.." - prints in chat current trigger message.")
		Print(START_COLOR..COLOR.."/epi print res"..END_COLOR.." - prints in chat message sent while casting PI.")
		return true
	end
	return false
end

SLASH_EMERALDPOWERINFUSION1 = "/epi"
SlashCmdList["EMERALDPOWERINFUSION"] = function(msg)
	local msglower = strlower(msg)
	if (CommandPI(msg, msglower)) then return end
	if (CommandShow(msg, msglower)) then return end
	if (CommandHide(msg, msglower)) then return end
	if (CommandScale(msg, msglower)) then return end
	if (CommandAlpha(msg, msglower)) then return end
	if (CommandPW(msg, msglower)) then return end
	if (CommandRes(msg, msglower)) then return end
	if (CommandPrintPW(msg, msglower)) then return end
	if (CommandPrintRes(msg, msglower)) then return end
	if (CommandHelp(msg, msglower, true)) then return end
end

----- EVENT HANDLING -----

local function OnEvent()
	if (event == "VARIABLES_LOADED") then
		if (not EmeraldPowerInfusion_Config.Scale) then
			EmeraldPowerInfusion_Config.Scale = DEFAULT_SCALE
		end
		if (not EmeraldPowerInfusion_Config.Alpha) then
			EmeraldPowerInfusion_Config.Alpha = DEFAULT_ALPHA
		end
		if (not EmeraldPowerInfusion_Config.Password) then
			EmeraldPowerInfusion_Config.Password = DEFAULT_PASSWORD
		end
		if (not EmeraldPowerInfusion_Config.Response) then
			EmeraldPowerInfusion_Config.Response = DEFAULT_RESPONSE
		end
		SetScale(EmeraldPowerInfusion_PIIcon, EmeraldPowerInfusion_Config.Scale)
		EmeraldPowerInfusion_PIIcon:SetAlpha(EmeraldPowerInfusion_Config.Alpha)
	elseif (event == "CHAT_MSG_WHISPER") then
		if (arg1 == EmeraldPowerInfusion_Config.Password) then
			local _,_,_,_,rank = GetTalentInfo(1, 15)
			if (rank <= 0) then
				SendMessage("I don't have this talent.", arg2)
				return
			end
			local CD, CDvalue = GetSpellCooldown(GetPISpell(), BOOKTYPE_SPELL)
			if (CD and CD ~= 0) then
				local remainingCD = CDvalue - (GetTime() - CD)
				SendMessage("PI ready in "..Round(remainingCD, 0).." sec.", arg2)
			elseif (GetNumRaidMembers() > 0) then
				local unit
				for i = 1, GetNumRaidMembers() do
					unit = "raid"..i
					if (arg2 == UnitName(unit)) then
						PITarget = unit
						PITargetName = arg2
						EmeraldPowerInfusion_PIIcon:Show()
						EmeraldPowerInfusion_PIIcon:EnableMouse(false)
						IconLifeSpan = 15
						break
					end
				end
			elseif (GetNumPartyMembers() > 0) then
				for i = 1, GetNumPartyMembers() do
					unit = "party"..i
					if (arg2 == UnitName(unit)) then
						PITarget = unit
						PITargetName = arg2
						EmeraldPowerInfusion_PIIcon:Show()
						EmeraldPowerInfusion_PIIcon:EnableMouse(false)
						IconLifeSpan = 15
						break
					end
				end
			end
		end
	end
end

----- UPDATE HANDLING -----

local function OnUpdate()
	local newTime = GetTime()
	DeltaTime = newTime - OldTime
	OldTime = newTime
	if (IconLifeSpan > 0) then
		IconLifeSpan = IconLifeSpan - DeltaTime
		if (IconLifeSpan <= 0) then
			EmeraldPowerInfusion_PIIcon:Hide()
			PITarget = nil
		end
	end
	local _,_,_,_,rank = GetTalentInfo(1, 15)
	if (rank >= 1) then
		local start, duration = GetSpellCooldown(GetPISpell(), BOOKTYPE_SPELL)
		local remaining = (start + duration) - GetTime()
		if (start ~= 0 and PITarget and EmeraldPowerInfusion_PIIcon:IsShown()) then
			SendMessage(EmeraldPowerInfusion_Config.Response)
			EmeraldPowerInfusion_PIIcon:Hide()
			PITarget = nil
		elseif (PITargetName and (RemainingCDPosted == false) and (remaining <= 30) and (remaining > 25)) then
			SendMessage("PI ready in 30 sec.")
			RemainingCDPosted = true
		elseif ((start == 0) and (PITargetName) and (not PITarget)) then
			SendMessage("PI ready!")
			PITargetName = nil
			RemainingCDPosted = false
		end
	end
end


local function OnLoad()
	if (UnitClass("player") ~= "Priest") then return end
	Addon:RegisterEvent("VARIABLES_LOADED")
	Addon:RegisterEvent("CHAT_MSG_WHISPER")
	Addon:SetScript("OnEvent", OnEvent)
	Addon:SetScript("OnUpdate", OnUpdate)
end
OnLoad()

----- IN GAME MACRO -----

function EmeraldPowerInfusion()
	if (not PITarget) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."No target."..END_COLOR)
		return
	end
	local spell = GetPISpell()
	if (not spell) then
		local COLOR = "FF0000"
		Print(START_COLOR..COLOR.."Spell not found."..END_COLOR)
		return
	end
	if (GetSpellCooldown(spell, BOOKTYPE_SPELL) ~= 0) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."Cooldown."..END_COLOR)
		return
	end

	if (NotEnoughMana()) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."Not enough mana."..END_COLOR)
		return
	end


	local targetingFriend = UnitIsFriend("player", "target")
	if (targetingFriend) then
		ClearTarget()
	end

	local autoSelfCast = GetCVar("autoSelfCast")
	SetCVar("autoSelfCast", 0)
	CastSpell(spell, BOOKTYPE_SPELL)
	if (not SpellCanTargetUnit(PITarget)) then
		SpellStopTargeting()
		SetCVar("autoSelfCast", autoSelfCast)
		return
	end
	SpellTargetUnit(PITarget)
	SpellStopTargeting()
	if (targetingFriend) then TargetLastTarget() end
	SetCVar("autoSelfCast", autoSelfCast)
end