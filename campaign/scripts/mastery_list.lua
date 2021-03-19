function onInit()
    local node = getDatabaseNode();
    local charNode = node.getChild("..");
    DB.addHandler(DB.getPath(charNode, "powers"), "onChildAdded", onPowerAdded);
    DB.addHandler(DB.getPath(charNode, "inventorylist"), "onChildAdded", onItemAdded);
end

function onClose()
    local node = getDatabaseNode();
    local charNode = node.getChild("..");
    DB.removeHandler(DB.getPath(charNode, "powers"), "onChildAdded", onPowerAdded);
    DB.removeHandler(DB.getPath(charNode, "inventorylist"), "onChildAdded", onItemAdded);
end

function onPowerAdded(nodeParent, nodeAdded)
    -- some kind of hidden field that's populated when an item is added
end

function onItemAdded(nodeParent, nodeAdded)
    -- Check the link field type
end

function onListChanged()
    update();
end

function update()
    local sEdit = getName() .. "_iedit";
    if window[sEdit] then
        local bEdit = (window[sEdit].getValue() == 1);
        for _,wCategory in ipairs(getWindows()) do
            wCategory.idelete.setVisibility(bEdit);
        end
    end
end

function addEntry(bFocus)
    local w = createWindow();
    if bFocus then
        w.masterytype.setFocus();
    end
    return w;
end