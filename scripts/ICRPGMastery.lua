-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_ROLLCOST = "rollcost";

local fGetPowerRoll;
local fGetPCPowerAction;
function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ROLLCOST, handleRollCostWithMastery);
    ActionsManager.registerResultHandler("cost", onCostRoll);

    fGetPCPowerAction = PowerManager.getPCPowerAction;
    PowerManager.getPCPowerAction = getPCPowerActionWithMastery;

    fGetPowerRoll = ActionAttempt.getPowerRoll;
    ActionAttempt.getPowerRoll = getAttemptPowerRoll;
    ActionAttempt.deductCost = deductCostWithMastery;
end

function getPCPowerActionWithMastery(nodeAction)
    local rAction, rActor = fGetPCPowerAction(nodeAction);
    if rAction.type == "attempt" then
        local nodePower = nodeAction.getChild("...");
        local nodeActor = nodeAction.getChild(".....");
        local sType = DB.getValue(nodePower, "type", "");
    
        if HasMasteryType(nodeActor, sType) then
            rAction.sMasteryType = sType;
        end 
    end
    return rAction, rActor;
end

function getAttemptPowerRoll(rActor, rAction)
    local rRoll = fGetPowerRoll(rActor, rAction);
    -- Replace '[COST: #]' with updated version that includes mastery type
    if rAction.sCostTrigger ~= "" then
        if rAction.sMasteryType then
            local fullmatch = rRoll.sDesc:match("(%[COST: .+%])")
            if fullmatch then
                local copy = fullmatch:match("%[COST: .+ %((.+)%)%]");
                if copy then
                    local newCost = rAction.sMasteryType .. ", " .. copy;
                    fullmatch = fullmatch:gsub("%(.+%)", "(" .. newCost .. ")");
                    rRoll.sDesc = rRoll.sDesc:gsub("%[COST: .+%]", fullmatch); 
                end
            end
        end
    end
    return rRoll;
end

function deductCostWithMastery(rSource, sCost, bSuccess)
	if not sCost then return; end
    -- try with mastery type
    sCostTrigger = string.match(sCost, "%(.+, (.+)%)");
    if not sCostTrigger then
        -- try to match without mastery type
	local sCostTrigger = string.match(sCost, "%((.+)%)");
    end
	if (sCostTrigger == "S/F") or (sCostTrigger == "S" and bSuccess == true) or (sCostTrigger == "F" and bSuccess == false) then
		local sCostDice = string.match(sCost, "(.+) %(.+%)");
		local costOOB = {};
		costOOB.type = OOB_MSGTYPE_ROLLCOST;
		costOOB.nSecret = 0;
		costOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
		costOOB.sCost = sCostDice;

        -- Handle mastery type
        local mastery = string.match(sCost, ".+ %((.+), .+%)")
        if mastery then
            costOOB.sMastery = mastery;
        end

		Comm.deliverOOBMessage(costOOB, "");
	end
end

function handleRollCostWithMastery(msgOOB)
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local sCost = msgOOB.sCost;
	local rCostRoll = {};
	rCostRoll.sType = "cost";
	rCostRoll.sDesc = ""; 
    if msgOOB.sMastery then
        local nMastery = getMasteryLevel(DB.findNode(msgOOB.sSourceNode), msgOOB.sMastery);
        if nMastery >= 4 then
            rCostRoll.sDesc = "[MASTERED]";
        end
    end
	rCostRoll.aDice, rCostRoll.nMod = StringManager.convertStringToDice(sCost);
	ActionCost.performAction(rActor, rCostRoll);
end

function onCostRoll(rSource, rTarget, rRoll)
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
    rMessage.icon = "action_effort";
    local nTotal = ActionsManager.total(rRoll);
    rMessage.text = "[COST: " .. nTotal .. "] " .. rRoll.sDesc;
    
    local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end

    -- Handle mastery
    local mastered = rMessage.text:match("%[MASTERED%]");
    if mastered then
        nTotal = math.max(math.floor(nTotal/2), 1)
    end

	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

    ActionEffort.notifyApplyDamage(rSource, rSource, bShowMsg, rMessage.text, nTotal);
end

function getMasteryNode(nodeActor, sType) 
    if not nodeActor or not sType then return nil; end
    local nMastery = 0;

    local masteries = nodeActor.getChild("masteries");
    if not masteries then return nil; end

    for _,v in pairs(masteries.getChildren()) do
        local type = v.getChild("masterytype");
        if type.getValue() == sType then 
            return v;
        end
    end
    return nil;
end

function HasMasteryType(nodeActor, sType)
    if not nodeActor or not sType then return nil; end

    local mastery = getMasteryNode(nodeActor, sType);
    return mastery ~= nil;
end

function getMasteryLevel(nodeActor, sType)
    if not nodeActor or not sType then return nil; end

    local mastery = getMasteryNode(nodeActor, sType);
    if not mastery then return 0 end

    if mastery.getChild("mastery4").getValue() == 1 then
        return 4;
    end
    if mastery.getChild("mastery3").getValue() == 1 then
        return 3;
    end
    if mastery.getChild("mastery2").getValue() == 1 then
        return 2;
    end
    if mastery.getChild("mastery1").getValue() == 1 then
        return 1;
    end
    return 0;
end

