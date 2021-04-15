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

    ActionAttempt.setCustomDeductCost(handleCostMastery)
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
            local costPrefix = rRoll.sDesc:match("(%[COST:.-)%]")
            if costPrefix then
                local newCopy = costPrefix .. "(type: " .. rAction.sMasteryType .. ")]";
                rRoll.sDesc = rRoll.sDesc:gsub("%[COST: .-%]", newCopy); 
            end
        end
    end
    return rRoll;
end

function handleCostMastery(rSource, rTarget, costOOB, sCost, bSuccess)
	if not rSource or not sCost then return; end
    
    -- Handle mastery type
    local mastery = string.match(sCost, "%(type: (.+)%)")
    if mastery then
        costOOB.sMastery = mastery;
    end
end

function handleRollCostWithMastery(msgOOB)
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local sCost = msgOOB.sCost;
	local rCostRoll = {};
	rCostRoll.sType = "cost";
	rCostRoll.sDesc = msgOOB.sPowerName .. " [COST: " .. sCost .. "]";
    if msgOOB.sHealthResource then
		rCostRoll.sDesc = rCostRoll.sDesc .. " [" .. msgOOB.sHealthrResource .. "]";
	end
    if msgOOB.sMastery then
        local nMastery = getMasteryLevel(DB.findNode(msgOOB.sSourceNode), msgOOB.sMastery);
        if nMastery >= 4 then
            rCostRoll.sDesc = "[MASTERED]";
        end
    end
	rCostRoll.aDice, rCostRoll.nMod = StringManager.convertStringToDice(sCost);
	ActionCost.performAction(rActor, rTarget, rCostRoll);
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

