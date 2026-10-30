-- Server-only bounded queue. Hearing grants a location, never a player identity.
local Noise={}
local pending={}
function Noise.Emit(position,source)
    if #pending>=12 then table.remove(pending,1) end
    table.insert(pending,{position=position,source=source,time=os.clock()})
end
function Noise.Take()
    local result=pending; pending={}; return result
end
return Noise
