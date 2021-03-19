function onInit()
    local node = getDatabaseNode();
    DB.addHandler(DB.getPath(node, "mastery1"), "onUpdate", onMasteryChanged);
    DB.addHandler(DB.getPath(node, "mastery2"), "onUpdate", onMasteryChanged);
    DB.addHandler(DB.getPath(node, "mastery3"), "onUpdate", onMasteryChanged);
    DB.addHandler(DB.getPath(node, "mastery4"), "onUpdate", onMasteryChanged);
end

function onClose()
    local node = getDatabaseNode();
    DB.removeHandler(DB.getPath(node, "mastery1"), "onUpdate", onMasteryChanged);
    DB.removeHandler(DB.getPath(node, "mastery2"), "onUpdate", onMasteryChanged);
    DB.removeHandler(DB.getPath(node, "mastery3"), "onUpdate", onMasteryChanged);
    DB.removeHandler(DB.getPath(node, "mastery4"), "onUpdate", onMasteryChanged);
end

function onMasteryChanged(node)
    -- Get node name
    local masteryitem = node.getChild("..");
    local sNodeName = node.getName();
    local nChecked = node.getValue();
    local nNum = tonumber(sNodeName:match("mastery(%d)"));
    for _,v in pairs(masteryitem.getChildren()) do
        local n = tonumber(v.getName():match("mastery(%d)"));
        if n and ((nChecked == 0 and n > nNum) or (nChecked == 1 and n < nNum)) then
            v.setValue(nChecked);
        end
    end
end