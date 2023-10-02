EnemyInfo={}

--敌人AI，不同状态调用不同逻辑
EnemyInfo.EnemyState={
    await=1,
    death=2,
    attack=3,
    walk=4,
    skill=5,
}

--初始化   
--参数enemy：任一 EnemyData 子表
function EnemyInfo:New(enemy)
    local o={}
    self.__index=self
    setmetatable(o,self)

    --gameobject & component
    o.name = enemy.name
    o.model = ModelManager:CreateModel(enemy.name,false)
    o.collider = o.model:GetComponent("CapsuleCollider2D")  --这里锁死了范围CapsuleCollider2D
    o.hpbar = HpBar:New(o.model)
    o.scale=o.model.transform.localScale
    o.renderer = o.model:GetComponent("MeshRenderer")
    o.skin  = o.model:GetComponent("SkeletonAnimation")

    --data
    o.hp=enemy.hp
    o.maxHp=enemy.hp
    o.atk=enemy.atk or 0
    o.atkRange=enemy.atkRange or 0
    o.def=enemy.def or 0
    o.money=enemy.money or 0
    o.moveSpeed=enemy.speed or 0
    o.lootEnemy=enemy.lootEnemy or nil
    o.AnimeName=enemy.AnimeName
    o.AnimeAudio=enemy.AnimeAudio
    o.atkParticle=enemy.atkParticle or nil

    --StateSupport
    o.awaitTimer=1
    o.awaitIndex=0
    o.direction=unity.Vector3.zero
    o.deathTimer=math.random(1,3)
    o.deathIndex=0
    o.isDied=false
    EnemyList:AddCharacter(o)

    ----生命周期
    Utils:registerObject(o.model)
    o:Await()

    CS.SpineAnimationState.Instance:AnimeComplete(o.skin,function (TrackEntry) 
        o:AttackEnd(TrackEntry)
    end)
    EventDispatcher:addListener(Events:GetEvent(Events.Update),function ()
        if o.isDied==false then
            o:StateOnUpdate()
        end
    end)
    
    return o
end

----行为
function EnemyInfo:StateOnUpdate()
    self:HpCheck()
    self.renderer.sortingOrder = math.floor(-self.model.transform.position.y)

    if     self.currentState == EnemyInfo.EnemyState.await then
        --print("Await OnUpdate")
        self.awaitIndex = self.awaitIndex+unity.Time.deltaTime
        if self.awaitIndex >= self.awaitTimer or self.hpbar.isHpChange==true then
            self:Walk()
        end


    elseif self.currentState == EnemyInfo.EnemyState.walk then
        --print("Walk OnUpdate")
        self.model.transform:Translate(self.direction * self.moveSpeed * unity.Time.deltaTime)

        self.direction = self:SetTargetPos(Player.model.transform.position)
        local direction=unity.Vector2(self.direction.x,self.direction.y)
        local hitCount = self.collider:Raycast(direction,{unity.RaycastHit2D},self.atkRange)--检测攻击距离内物体，若无，持续移动状态
        if hitCount>0 then  --若有物体，判断与玩家距离，进入攻击距离则进入攻击
            if unity.Vector3.Distance(Player.collider.bounds.center,self.collider.bounds.center)<(self.atkRange+Player.collider.size.x/2) then
                self:Attack()
            else            --判断是否敌人（鉴于Physics2D.Raycast无法忽视自身碰撞盒，故判定检测数阈值为>1）
                local origin=unity.Vector2(self.collider.bounds.center.x,self.collider.bounds.center.y)
                local hit2Ds=unity.Physics2D.RaycastAll(origin,direction,3)
                local e=0
                for i = 0, hit2Ds.Length-1 do
                    if Utils:isContains(hit2Ds[i].collider.name,"Enemy") then 
                        e=e+1
                        if e>1 then
                            self:Await()
                        end
                    end
                end 
            end 
        end
    elseif self.currentState == EnemyInfo.EnemyState.death then
        self.deathIndex = self.deathIndex+unity.Time.deltaTime
        if self.deathIndex >= self.deathTimer then 
            if self.lootEnemy then
                local lootEnemy = EnemyInfo:New(self.lootEnemy) --若有掉落物，生成。（比如一个大史莱姆被打死了，可以生成一个小史莱姆？）
                lootEnemy.model.transform.position=self.model.transform.position
            end

            unity.GameObject.Destroy(self.model)
            self.isDied=true
        end
    end
end

function EnemyInfo:Await()
    if self.currentState==EnemyInfo.EnemyState.death then return end
    self.skin.AnimationState:SetAnimation(1, self.AnimeName.await , true)
    self.awaitIndex=0
    self.currentState=EnemyInfo.EnemyState.await
end

function EnemyInfo:Walk()
    if self.currentState==EnemyInfo.EnemyState.death then return end
    self.skin.AnimationState:SetAnimation(1, self.AnimeName.walk , true)
    self.currentState=EnemyInfo.EnemyState.walk
end

function EnemyInfo:Attack()
    if self.currentState==EnemyInfo.EnemyState.death then return end
    self.skin.AnimationState:SetAnimation(1, self.AnimeName.attack , false)
    self.currentState=EnemyInfo.EnemyState.attack
    AudioManager:Play(self.AnimeAudio.attack)
end

--当攻击结束，检测玩家是否在范围内，在则命中
function EnemyInfo:AttackEnd(TrackEntry)
    if TrackEntry.Animation.Name~=self.AnimeName.attack then return end

    if self.atkParticle then
        AtkParticleInfo:New(self.atkParticle,self)
    elseif unity.Vector3.Distance(Player.collider.bounds.center,self.collider.bounds.center)<self.atkRange+Player.collider.size.x/2 then
        Player:hurt(self.atk)
    end

    self:Walk()
end

function EnemyInfo:Dead()
    if self.currentState==EnemyInfo.EnemyState.death then return end
    self.skin.AnimationState:SetAnimation(1, self.AnimeName.death , false)
    self.currentState=EnemyInfo.EnemyState.death
    AudioManager:Play(self.AnimeAudio.death)
    EnemyList:RemoveCharacter(self)
end

--isRealHurt 是否为真实伤害（是则算法无视防御力）
function EnemyInfo:hurt(demage, isRealHurt)
    if self.currentState==EnemyInfo.EnemyState.death then return end
    if isRealHurt then
        self.hp = self.hp - demage
    else
        self.hp = self.hp - demage * (100-self.def)/100
    end

    self.hpbar.isHpChange=true
    if self.hp<=0 then
        self:Dead()
    end
end

--设置寻路目标
function EnemyInfo:SetTargetPos(target)

    local direction = unity.Vector3.Normalize(target-self.model.transform.position)

    if direction.x>0 then
        self.model.transform.localScale=unity.Vector3(-self.scale.x,self.scale.y,self.scale.z)
        self.hpbar.model.transform.localScale = unity.Vector3(-self.hpbar.scale.x,self.hpbar.scale.y,self.hpbar.scale.z)
    else
        self.model.transform.localScale=self.scale
        self.hpbar.model.transform.localScale = self.hpbar.scale
    end
    
    return direction
end

--检测生命值是否变化
function EnemyInfo:HpCheck()
    if self.hpbar.isHpChange then
        self.hpbar:OnHpChange(self.hp,self.maxHp)
    end
end

return EnemyInfo