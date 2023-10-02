EnemyData={}
--敌人库，该表内的一个表，为一类敌人

EnemyData.Zombie_LongFair={
    name="Enemy_Zombie_LongFair",
    hp=100,
    atk=5,
    atkRange=1,
    money=10,
    speed=6,
    AnimeName={
        await="await_cf",
        death="death_cf",
        attack="gnawing_cf",
        walk="walking_cf",
        },
    AnimeAudio={
        attack="Zombie",
        death="Kill",
    },

}

EnemyData.Zombie_Elite={
    name="Enemy_Zombie_Elite",
    hp=500,
    atk=10,
    atkRange=1.5,
    money=10,
    speed=6,
    AnimeName={
        await="await_jy",
        death="death_jy",
        attack="gnawing_jy",
        walk="walking_jy",
        },
    AnimeAudio={
        attack="Zombie",
        death="Kill",
    },

}


return EnemyData