-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_ROLLCOST = "rollcost";

local fGetCostMessage;
local fCreateCostRoll;
local fGetCostTotal;
local fGetPowerRoll;
local fGetPCPowerAction;

function onInit()
    fGetCostMessage = ActionAttempt.getCostMessage;
    ActionAttempt.getCostMessage = getCostMessageWithMastery;

    fCreateCostRoll = ActionCost.createCostRoll;
    ActionCost.createCostRoll = createCostRollWithMastery
    
    fGetCostTotal = ActionCost.getCostTotal;
    ActionCost.getCostTotal = getCostTotalWithMastery;


    fGetPCPowerAction = PowerManager.getPCPowerAction;
    PowerManager.getPCPowerAction = getPCPowerActionWithMastery;

    fGetPowerRoll = ActionAttempt.getPowerRoll;
    ActionAttempt.getPowerRoll = getAttemptPowerRoll;
end

-------------------------------------
-- HANDLE COST ROLLING / RESOLVING
-------------------------------------

function createCostRollWithMastery(msgOOB)
    rRoll = fCreateCostRoll(msgOOB);
    if msgOOB.sMastery then
        local nMastery = getMasteryLevel(DB.findNode(msgOOB.sSourceNode), msgOOB.sMastery);
        if nMastery >= 4 then
            rRoll.sDesc = rRoll.sDesc .. " [MASTERED]";
        end
    end
    return rRoll;
end

function getCostTotalWithMastery(rSource, rTarget, rRoll)
    local nTotal = fGetCostTotal(rSource, rTarget, rRoll);

    -- Handle mastery
    local mastered = rRoll.sDesc:match("%[MASTERED%]");
    if mastered then
        nTotal = math.max(math.floor(nTotal/2), 1)
    end

    return nTotal;
end

-------------------------------------
-- GET ACTION & ATTEMPT ROLLS
-------------------------------------

function getCostMessageWithMastery(rSource, rTarget, sPowerName, sCost)
    local msg = fGetCostMessage(rSource, rTarget, sPowerName, sCost);
    
    local mastery = string.match(sCost, "%(type: (.+)%)")
    if mastery then
        msg.sMastery = mastery;
    end

    return msg;
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

------------------------------
-- UTILITY
------------------------------

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

