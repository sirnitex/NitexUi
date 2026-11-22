-- NitexUI: Quality of Life
--
-- Small conveniences, each with its own switch:
--   * Hide the talking head frame (the voice line still plays)
--   * Hide red error messages (UIErrorsFrame)
--   * Hide zone text
--   * Sell junk at vendors       (Blizzard's own C_MerchantFrame.SellAllJunkItems)
--   * Repair at vendors          (Blizzard's RepairAllItems, guild bank first if chosen)
--   Retail only:
--   * Quick sign-up in the group finder (hold Shift for the normal dialog)
--   * Accept group invites (friends / Battle.net friends / guild, or anyone)
--
-- Only events that an option needs are registered (MERCHANT_SHOW, PARTY_INVITE_REQUEST).
-- No OnUpdate. Hooks (talking head, group finder) are installed the first time the option
-- is used; they cannot be removed, so after turning off they return immediately.
--
-- When the module is OFF: nothing is registered, hooked or created.

local _, ns = ...
local M = ns:NewModule("QualityOfLife")
ns.QualityOfLife = M
local L = ns.L

ns.defaults.qol = {
    hideTalkingHead = false,
    hideErrors = false,
    hideZoneText = false,
    sellJunk = false,
    autoRepair = false,
    repairGuildFirst = true,
    quickSignup = false,
    autoAcceptInvite = false,
    inviteFriendsOnly = true,
}

local db -- ns.db.qol, set in Apply

---------------------------------------------------------------------------
-- Hidden parent (same technique as Interface > General)
---------------------------------------------------------------------------
local hiddenParent
local originalParent = {}

local function HideFrame(frame)
    if not frame or originalParent[frame] then return end
    if not hiddenParent then
        hiddenParent = CreateFrame("Frame")
        hiddenParent:Hide()
    end
    originalParent[frame] = frame:GetParent()
    frame:SetParent(hiddenParent)
end

local function RestoreFrame(frame)
    local parent = frame and originalParent[frame]
    if not parent then return end
    frame:SetParent(parent)
    originalParent[frame] = nil
end

---------------------------------------------------------------------------
-- Talking head: made fully transparent and click-through instead of hidden, so its
-- animations keep running, it closes on its own and the voice line is not stopped.
---------------------------------------------------------------------------
local thActive, thHooked = false, false

local function TalkingHeadMouse(on)
    local f = TalkingHeadFrame
    f:EnableMouse(on)
    local main = f.MainFrame
    if main then
        main:EnableMouse(on)
        if main.CloseButton then main.CloseButton:EnableMouse(on) end
    end
end

local function OnTalkingHeadPlay(self)
    if thActive then self:SetAlpha(0) end
end

local function ApplyTalkingHead(on)
    local f = TalkingHeadFrame
    if not f then return end
    if on == thActive then return end
    thActive = on
    if on and not thHooked and f.PlayCurrent then
        thHooked = true
        hooksecurefunc(f, "PlayCurrent", OnTalkingHeadPlay)
    end
    f:SetAlpha(on and 0 or 1)
    TalkingHeadMouse(not on)
end

---------------------------------------------------------------------------
-- Error messages: UIErrorsFrame stops listening to UI_ERROR_MESSAGE only.
-- Yellow info messages (quest progress etc.) still show.
---------------------------------------------------------------------------
local errorsHidden = false

local function ApplyErrors(on)
    if not UIErrorsFrame or on == errorsHidden then return end
    errorsHidden = on
    if on then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    else
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
    end
end

---------------------------------------------------------------------------
-- Zone text
---------------------------------------------------------------------------
local function ApplyZoneText(on)
    if on then
        HideFrame(ZoneTextFrame)
        HideFrame(SubZoneTextFrame)
    else
        RestoreFrame(ZoneTextFrame)
        RestoreFrame(SubZoneTextFrame)
    end
end

---------------------------------------------------------------------------
-- Merchant: junk + repair
---------------------------------------------------------------------------
local function RepairPersonal()
    local cost = GetRepairAllCost()
    if cost and cost > 0 and GetMoney() >= cost then
        RepairAllItems(false)
        ns:Print(L["QOL_REPAIRED"]:format(GetMoneyString(cost)))
    end
end

-- Runs once, a moment after a guild repair was tried: if anything is still broken
-- (guild had no funds / no withdraw left), pay it personally.
local guildCost = 0
local function RepairFallback()
    if not (MerchantFrame and MerchantFrame:IsShown()) then return end
    local left = GetRepairAllCost()
    if left and left > 0 then
        RepairPersonal()
    else
        ns:Print(L["QOL_REPAIRED_GUILD"]:format(GetMoneyString(guildCost)))
    end
end

local function DoRepair()
    if not CanMerchantRepair() then return end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then return end
    if db.repairGuildFirst and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
        guildCost = cost
        RepairAllItems(true)
        C_Timer.After(1, RepairFallback)
    else
        RepairPersonal()
    end
end

local function DoSellJunk()
    local MF = C_MerchantFrame
    if not (MF and MF.SellAllJunkItems and MF.GetNumJunkItems) then return end
    local n = MF.GetNumJunkItems()
    if n and n > 0 then
        MF.SellAllJunkItems()
        ns:Print(L["QOL_SOLD_JUNK"]:format(n))
    end
end

function M:OnMerchantShow()
    if db.autoRepair then DoRepair() end
    if db.sellJunk then DoSellJunk() end
end

---------------------------------------------------------------------------
-- Group finder quick sign-up (retail). Blizzard's own sign-up dialog is opened as
-- usual and its Sign Up button is pressed for you, with the roles already ticked in it.
-- Hold Shift to get the normal dialog (to write a note or change roles).
---------------------------------------------------------------------------
local signupActive, signupHooked = false, false

local function OnApplicationDialogShow(dialog)
    if not signupActive or IsShiftKeyDown() then return end
    dialog = dialog or LFGListApplicationDialog
    local btn = dialog and dialog.SignUpButton
    if btn and btn:IsEnabled() then btn:Click() end
end

local function HookSignup()
    if signupHooked then return true end
    if LFGListApplicationDialog_Show then
        hooksecurefunc("LFGListApplicationDialog_Show", OnApplicationDialogShow)
    elseif LFGListApplicationDialog then
        LFGListApplicationDialog:HookScript("OnShow", OnApplicationDialogShow)
    else
        return false
    end
    signupHooked = true
    return true
end

function M:OnAddonLoaded(_, name)
    if name ~= "Blizzard_GroupFinder" then return end
    ns:UnregisterEvent("ADDON_LOADED", self)
    if signupActive then HookSignup() end
end

local function ApplySignup(on)
    signupActive = on
    if on and not HookSignup() then
        -- Group finder not loaded yet: hook it when it loads.
        ns:RegisterEvent("ADDON_LOADED", M, M.OnAddonLoaded)
    elseif not on then
        ns:UnregisterEvent("ADDON_LOADED", M)
    end
end

---------------------------------------------------------------------------
-- Accept group invites (retail)
---------------------------------------------------------------------------
local function IsTrusted(guid)
    if not guid or (issecretvalue and issecretvalue(guid)) then return false end
    if C_FriendList and C_FriendList.IsFriend and C_FriendList.IsFriend(guid) then return true end
    if C_BattleNet and C_BattleNet.GetGameAccountInfoByGUID and C_BattleNet.GetGameAccountInfoByGUID(guid) then return true end
    if IsGuildMember and IsGuildMember(guid) then return true end
    return false
end

function M:OnPartyInvite(_, _, _, _, _, _, _, inviterGUID)
    if db.inviteFriendsOnly and not IsTrusted(inviterGUID) then return end
    AcceptGroup()
    if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------
--- Bring every feature in line with the current settings. Off = everything restored.
function M:Apply()
    db = ns.db.qol
    local on = self.enabled

    ApplyTalkingHead(on and db.hideTalkingHead or false)
    ApplyErrors(on and db.hideErrors or false)

    -- Zone text frames are not protected: no need to wait for combat to end.
    ApplyZoneText(on and db.hideZoneText or false)

    if on and (db.sellJunk or db.autoRepair) then
        ns:RegisterEvent("MERCHANT_SHOW", self, self.OnMerchantShow)
    else
        ns:UnregisterEvent("MERCHANT_SHOW", self)
    end

    local retail = ns.isRetail
    ApplySignup(retail and on and db.quickSignup or false)

    if retail and on and db.autoAcceptInvite then
        ns:RegisterEvent("PARTY_INVITE_REQUEST", self, self.OnPartyInvite)
    else
        ns:UnregisterEvent("PARTY_INVITE_REQUEST", self)
    end
end

function M:OnEnable()
    self:Apply()
end

function M:OnDisable()
    -- self.enabled is already false here, so Apply restores everything.
    self:Apply()
end
