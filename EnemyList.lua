EnemyList={}

--登记的Chacater(table)必须有model
function EnemyList:AddCharacter(character)
    if character.model==nil then print(character.__tostring.." havn't model") return end
    table.insert(EnemyList,character)
end

function EnemyList:RemoveCharacter(character)
    for k, v in pairs(self) do
        if v==character then
            table.remove(self,k)
        end
    end
end

function EnemyList:GetTableByGameObject(go)
    for i=1,#self do
        if self[i].model==go then
            return self[i]
        end
    end
end

function EnemyList:PrintAllCharacters()
    for i=1,#self do
        print(self[i].model)
    end
end

return EnemyList