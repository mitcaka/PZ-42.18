require 'Items/SuburbsDistributions'
require "Items/ProceduralDistributions"
require "FadedFeastcraft/FFC_DistributionSafety"

SandboxVars = SandboxVars or {}
SandboxVars.MR = SandboxVars.MR or {}
SandboxVars.MR.PerishableChance = SandboxVars.MR.PerishableChance or 3
SandboxVars.MR.CannedSpawnChance = SandboxVars.MR.CannedSpawnChance or 3
SandboxVars.MR.NonPerishableChance = SandboxVars.MR.NonPerishableChance or 3
SandboxVars.MR.AlcoholChance = SandboxVars.MR.AlcoholChance or 3
SandboxVars.MR.MagazineChance = SandboxVars.MR.MagazineChance or 3
SandboxVars.MR.ZombieLootSpawn = SandboxVars.MR.ZombieLootSpawn or 3

if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
    FadedFeastcraft.DistributionSafety.installProceduralFallback()
end


local function addSandboxLoot()

--Item drops.
--Set Sandbox Settings values.
local PerishableSpawnChance = SandboxVars.MR.PerishableChance; 
local CannedSpawnChance = SandboxVars.MR.CannedSpawnChance;
local NonPerishableSpawnChance = SandboxVars.MR.NonPerishableChance; 
local AlcoholSpawnChance = SandboxVars.MR.AlcoholChance;
local MagazineSpawnChance = SandboxVars.MR.MagazineChance;
local ZombieSpawnChance = SandboxVars.MR.ZombieLootSpawn;


--Default value is 3.

if (PerishableSpawnChance == 6) then  --20 21军粮
    PerishableSpawnChance = 0;
    end

if (CannedSpawnChance == 6) then   --副食品（罐头，零食）生成
    CannedSpawnChance = 0;
    end

if (NonPerishableSpawnChance == 6) then   --冷冻盒饭/冷冻食品
    NonPerishableSpawnChance = 0;
    end

if (AlcoholSpawnChance == 7) then   --烟酒生成
    AlcoholSpawnChance = 0;
    end

if (MagazineSpawnChance == 6) then   --杂志生成
    MagazineSpawnChance = 0;
    end

if (ZombieSpawnChance == 6) then   --僵尸掉落
    ZombieSpawnChance = 0;
    end



--inventorymale（男性丧尸掉落）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.81cigarette"); --八一香烟
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.0003);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.lucky_strike"); --lucky strike
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.05);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.005);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.Camel_cigarettes"); --Camel
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.05);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.005);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.double_happiness"); --红双喜香烟
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.0003);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.01);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(SuburbsDistributions["all"]["inventorymale"].items, AlcoholSpawnChance * 0.002);

--inventoryfemale（女性丧尸掉落）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.81cigarette"); --八一香烟
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.0003);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.lucky_strike"); --lucky strike
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.05);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.005);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.Camel_cigarettes"); --Camel
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.05);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.005);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.double_happiness"); --红双喜香烟
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.0003);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.01);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.002);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.02);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, AlcoholSpawnChance * 0.002);

--AmbulanceDriverTools（救护车司机工具）
table.insert(ProceduralDistributions["list"]["AmbulanceDriverTools"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["AmbulanceDriverTools"].items, PerishableSpawnChance * 12);

--KitchenDryFood 厨房干货
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.pickledcabbage_beef"); --酸菜牛肉面
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.BoneDragon_BeefCurry"); --骨龙牌牛肉咖喱
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Durable_Cake"); --耐贮蛋糕
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.energy_bar"); --末日工坊牌能量棒
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.AirForce_Chocolate"); --18式空军巧克力
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.AirForce_Chocolate_pack"); --18式空军巧克力（盒装）
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Honeyoat_proteinstick"); --蜂蜜燕麦蛋白棒
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Honeyoat_proteinstick_pack"); --蜂蜜燕麦蛋白棒（盒装）
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Lemonjam_softpie"); --柠檬果酱软派
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Lemonjam_softpie_box"); --柠檬果酱软派（盒装）
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Blueberry_Cake_CaramelPie"); --蓝莓蛋糕焦糖派
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Blueberry_Cake_CaramelPie_box"); --蓝莓蛋糕焦糖派（盒装）
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, "MR.Fivespice_porkballs"); --五香猪肉粒
table.insert(ProceduralDistributions["list"]["KitchenDryFood"].items, CannedSpawnChance * 3);


--FridgeGeneric（冰箱通用）
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Braised_cannedbeef"); --红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Braised_cannedpock"); --红烧肉罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.box_Braised_cannedbeef"); --一盒红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_peaches"); --黄桃罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.douchi_mudcarp"); --甘竹牌豆豉鲮鱼罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Energy_drinks"); --末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_sesame_ricedumpling"); --芝麻汤圆罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_porkbelly_chickensoup"); --胡椒猪肚鸡汤罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_spareribsoup"); --玉米排骨汤罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_Cream_BaconSoup"); --奶油培根汤罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_tomato_stew"); --番茄炖杂菜罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Canned_seaweed_peanuts"); --海苔椒盐花生罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.LaoGanMa_chicken_dicedchili_canned"); --老干妈鸡丁辣椒罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Smoked_canned_oysters"); --烟熏牡蛎罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Sichuan_beefhotpot_canned"); --川味牛肉火锅罐头
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Honeyoat_proteinstick"); --蜂蜜燕麦蛋白棒
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Honeyoat_proteinstick_pack"); --蜂蜜燕麦蛋白棒（盒装）
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Lemonjam_softpie"); --柠檬果酱软派
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Lemonjam_softpie_box"); --柠檬果酱软派（盒装）
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Blueberry_Cake_CaramelPie"); --蓝莓蛋糕焦糖派
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Blueberry_Cake_CaramelPie_box"); --蓝莓蛋糕焦糖派（盒装）
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.Fivespice_porkballs"); --五香猪肉粒
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "MR.colaBottle"); --毛毛裤牌提神可乐
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, AlcoholSpawnChance * 1.2);

--FridgeRich--（冰箱丰富）
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Braised_cannedbeef"); --红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Braised_cannedpock"); --红烧肉罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.box_Braised_cannedbeef"); --一盒红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_peaches"); --黄桃罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.douchi_mudcarp"); --甘竹牌豆豉鲮鱼罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Energy_drinks"); --末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_sesame_ricedumpling"); --芝麻汤圆罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_porkbelly_chickensoup"); --胡椒猪肚鸡汤罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_spareribsoup"); --玉米排骨汤罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_Cream_BaconSoup"); --奶油培根汤罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_tomato_stew"); --番茄炖杂菜罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Canned_seaweed_peanuts"); --海苔椒盐花生罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.LaoGanMa_chicken_dicedchili_canned"); --老干妈鸡丁辣椒罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Smoked_canned_oysters"); --烟熏牡蛎罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Sichuan_beefhotpot_canned"); --川味牛肉火锅罐头
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Honeyoat_proteinstick"); --蜂蜜燕麦蛋白棒
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Honeyoat_proteinstick_pack"); --蜂蜜燕麦蛋白棒（盒装）
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Lemonjam_softpie"); --柠檬果酱软派
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Lemonjam_softpie_box"); --柠檬果酱软派（盒装）
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Blueberry_Cake_CaramelPie"); --蓝莓蛋糕焦糖派
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Blueberry_Cake_CaramelPie_box"); --蓝莓蛋糕焦糖派（盒装）
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.Fivespice_porkballs"); --五香猪肉粒
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "MR.colaBottle"); --毛毛裤牌提神可乐
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, AlcoholSpawnChance * 1.2);

--FridgeSoda（冰箱苏打水）
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Energy_drinks"); --末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.box_Energy_drinks"); --一箱末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.coconut_milk"); --椰树牌椰汁
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.emergency_drinking_water"); --应急饮用水H2O
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.emergency_drinking_water1"); --一箱应急饮用水H2O
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.colaBottle"); --毛毛裤牌提神可乐
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.laoda_IcedTea"); --劳大冰红茶(原味)
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.laoda_greentea"); --劳大冰红茶(薄荷味)
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Qingdao_CraftBeer"); --青岛精酿
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Chocolate_Banana_ShitaoBeer"); --巧克力香蕉世涛啤酒
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Beifeng_Coconut_ShitaoBeer"); --北峰椰子奶油世涛啤酒
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Jasmine_LongjingBeer"); --茉莉龙井啤酒
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "MR.Lafite_Rothschild_1982"); --拉菲酒庄1982年干红
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, AlcoholSpawnChance * 0.8);

--GigamartCannedFood（罐头食物）
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Braised_cannedbeef"); --红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Braised_cannedpock"); --红烧肉罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.box_Braised_cannedbeef"); --一盒红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_peaches"); --黄桃罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.douchi_mudcarp"); --甘竹牌豆豉鲮鱼罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_LifeBread"); --生命面包罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_LifeBread_box"); --生命面包罐头（箱装）
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_sesame_ricedumpling"); --芝麻汤圆罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_porkbelly_chickensoup"); --胡椒猪肚鸡汤罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_spareribsoup"); --玉米排骨汤罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_Cream_BaconSoup"); --奶油培根汤罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_tomato_stew"); --番茄炖杂菜罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Canned_seaweed_peanuts"); --海苔椒盐花生罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.LaoGanMa_chicken_dicedchili_canned"); --老干妈鸡丁辣椒罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Smoked_canned_oysters"); --烟熏牡蛎罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 4.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "MR.Sichuan_beefhotpot_canned"); --川味牛肉火锅罐头
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 0.38);

--GroceryStorageCrate1（杂货店价格1）
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Braised_cannedbeef"); --红烧牛肉罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Braised_cannedpock"); --红烧肉罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_peaches"); --黄桃罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.douchi_mudcarp"); --甘竹牌豆豉鲮鱼罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_LifeBread"); --生命面包罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 0.9);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_LifeBread_box"); --生命面包罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Lemonjam_softpie"); --柠檬果酱软派
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Lemonjam_softpie_box"); --柠檬果酱软派（盒装）
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Blueberry_Cake_CaramelPie"); --蓝莓蛋糕焦糖派
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Blueberry_Cake_CaramelPie_box"); --蓝莓蛋糕焦糖派（盒装）
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_sesame_ricedumpling"); --芝麻汤圆罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_porkbelly_chickensoup"); --胡椒猪肚鸡汤罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_spareribsoup"); --玉米排骨汤罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_Cream_BaconSoup"); --奶油培根汤罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_tomato_stew"); --番茄炖杂菜罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Canned_seaweed_peanuts"); --海苔椒盐花生罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.LaoGanMa_chicken_dicedchili_canned"); --老干妈鸡丁辣椒罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Smoked_canned_oysters"); --烟熏牡蛎罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "MR.Sichuan_beefhotpot_canned"); --川味牛肉火锅罐头
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, CannedSpawnChance * 0.5);

--GasStorageCombo（储物架）
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "MR.energy_bar"); --能量棒
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, CannedSpawnChance * 8);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "MR.Durable_Cake"); --耐贮蛋糕
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "MR.AirForce_Chocolate"); --18式空军巧克力
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "MR.AirForce_Chocolate_pack"); --18式空军巧克力（盒装）
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, CannedSpawnChance * 1.2);

--GigamartDryGoods（干货）
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "MR.Compressed_biscuit"); --末日工坊牌压缩饼干
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "MR.AirForce_Chocolate_pack"); --18式空军巧克力（盒装）
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, CannedSpawnChance * 0.22);

--GigamartCrisps（食品杂货店薯片）
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.energy_bar"); --能量棒
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.Compressed_biscuit"); --末日工坊牌压缩饼干
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, CannedSpawnChance * 1.0);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.PeaBeef_Rice"); --豌豆牛肉
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.Chicken_curry_Rice"); --咖喱鸡丁
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.Spicy_lambmeat_Rice"); --香辣羊肉饭
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.xuecai_Rice"); --雪菜肉丝饭
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.pickledcabbage_beef"); --酸菜牛肉面
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.BoneDragon_BeefCurry"); --骨龙牌牛肉咖喱
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 1.3);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.WaterBoiled_Beef"); --水煮牛肉特需会餐
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, "MR.Spicy_grilledfish"); --香辣烤鱼特需会餐
table.insert(ProceduralDistributions["list"]["GigamartCrisps"].items, PerishableSpawnChance * 0.3);

--StoreShelfSnacks 商店货架零食小吃
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.energy_bar"); --能量棒
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, CannedSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.Compressed_biscuit"); --末日工坊牌压缩饼干
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, CannedSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.PeaBeef_Rice"); --豌豆牛肉
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.Chicken_curry_Rice"); --咖喱鸡丁
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.Spicy_lambmeat_Rice"); --香辣羊肉饭
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.xuecai_Rice"); --雪菜肉丝饭
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.3);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.pickledcabbage_beef"); --酸菜牛肉面
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.BoneDragon_BeefCurry"); --骨龙牌牛肉咖喱
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.WaterBoiled_Beef"); --水煮牛肉特需会餐
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 0.25);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "MR.Spicy_grilledfish"); --香辣烤鱼特需会餐
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, PerishableSpawnChance * 0.25);

--StoreShelfDrinks（商店货架饮料）
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "MR.coconut_milk"); --椰树牌椰汁
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, AlcoholSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "MR.Energy_drinks"); --末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, AlcoholSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "MR.box_Energy_drinks"); --一箱末日工坊能量饮料
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, AlcoholSpawnChance * 0.03);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "MR.emergency_drinking_water"); --应急饮用水H2O
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, AlcoholSpawnChance * 5);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "MR.emergency_drinking_water1"); --一箱应急饮用水H2O
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, AlcoholSpawnChance * 0.5);


--BarShelfLiquor(酒吧货架酒)
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Antwhip_liquor"); --蚁鞭劲酒
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Qingdao_CraftBeer"); --青岛精酿
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Chocolate_Banana_ShitaoBeer"); --巧克力香蕉世涛啤酒
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Beifeng_Coconut_ShitaoBeer"); --北峰椰子奶油世涛啤酒
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Jasmine_LongjingBeer"); --茉莉龙井啤酒
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "MR.Lafite_Rothschild_1982"); --拉菲酒庄1982年干红
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 2);

--BarCounterLiquor（酒吧柜台酒）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Antwhip_liquor"); --蚁鞭劲酒
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Qingdao_CraftBeer"); --青岛精酿
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Chocolate_Banana_ShitaoBeer"); --巧克力香蕉世涛啤酒
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Beifeng_Coconut_ShitaoBeer"); --北峰椰子奶油世涛啤酒
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Jasmine_LongjingBeer"); --茉莉龙井啤酒
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Lafite_Rothschild_1982"); --拉菲酒庄1982年干红
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 2);

--BarCounterLiquor（酒吧柜台酒）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.81cigarette"); --中华香烟
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 2.2);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.02);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 8);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 8);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.8);


--BarCounterMisc（酒吧柜台杂项）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.88);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 9);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 9);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.88);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Qingdao_CraftBeer"); --青岛精酿
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Chocolate_Banana_ShitaoBeer"); --巧克力香蕉世涛啤酒
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Beifeng_Coconut_ShitaoBeer"); --北峰椰子奶油世涛啤酒
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Jasmine_LongjingBeer"); --茉莉龙井啤酒
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "MR.Lafite_Rothschild_1982"); --拉菲酒庄1982年干红
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, AlcoholSpawnChance * 0.5);

--StoreCounterTobacco （商店柜台烟草）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 2.2);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.02);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 5);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.06);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, AlcoholSpawnChance * 0.42);

--BedroomSidetableClassy-- (卧室边桌优雅)
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableClassy"].items, AlcoholSpawnChance * 0.05);

--BedroomSidetableChild--(卧室边桌儿童)
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableChild"].items, AlcoholSpawnChance * 0.05);

--BedroomSidetable--(卧室边桌)
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetable"].items, AlcoholSpawnChance * 0.05);

--BedroomSidetableRedneck--(卧室边桌红领)
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.006);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["BedroomSidetableRedneck"].items, AlcoholSpawnChance * 0.05);


--ArmyStorageMedical （军火库医疗）
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, PerishableSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["StoreCounterTobacco"].items, PerishableSpawnChance * 0.25);

--DrugLabSupplies（药物实验室用品）
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["DrugLabSupplies"].items, PerishableSpawnChance * 0.33);

--HospitalRoomShelves（医院病房货架）
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["HospitalRoomShelves"].items, PerishableSpawnChance * 0.33);

--MedicalClinicDrugs（医疗临床药物）
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["MedicalClinicDrugs"].items, PerishableSpawnChance * 0.33);

--MedicalStorageDrugs（医疗储存药品）
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["MedicalStorageDrugs"].items, PerishableSpawnChance * 0.33);

--SafehouseMedical（安全屋医疗）
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["SafehouseMedical"].items, PerishableSpawnChance * 0.33);

--StoreShelfMedical（商店货架医疗）
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, "MR.Anti_hypoxia_capsules"); --抗缺氧食物
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, CannedSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, "MR.Glucose_oralsolution"); --牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, CannedSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, "MR.Glucose_oralsolution_pack"); --一盒牛磺酸葡萄糖口服液
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, CannedSpawnChance * 0.15);
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, "MR.Portable_first_aidkit"); --便携急救包
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, PerishableSpawnChance * 1.1);
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, "MR.Military_first_aidkit"); --军用急救包
table.insert(ProceduralDistributions["list"]["StoreShelfMedical"].items, PerishableSpawnChance * 0.33);

--ArmyStorageGuns（军火库枪支）
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 0.18);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 2.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["ArmyStorageGuns"].items, PerishableSpawnChance * 1.2);

--GunStoreGuns（枪支商店枪支）
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["GunStoreGuns"].items, PerishableSpawnChance * 1.2);

--PoliceStorageGuns（警用存储枪）
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["PoliceStorageGuns"].items, PerishableSpawnChance * 1.2);

--DrugLabGuns（药物实验室枪）
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 0.12);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["DrugLabGuns"].items, PerishableSpawnChance * 1.2);

--FirearmWeapons（枪支武器）
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["FirearmWeapons"].items, PerishableSpawnChance * 1.2);

--GunStoreMagsAmmo（枪械店弹药）
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["GunStoreMagsAmmo"].items, PerishableSpawnChance * 1.2);

--PoliceDesk（警察办公桌）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 0.1);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 2.2);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.02);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.06);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻
table.insert(ProceduralDistributions["list"]["PoliceDesk"].items, MagazineSpawnChance * 2.5);


--PoliceFileBox（警察档案箱）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.armyprovisionsA"); --20式A类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.armyprovisionsB"); --20式B类战斗口粮
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Military_grain"); --一箱军粮
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 0.12);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Energy_adhesive"); --军用能量胶
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Military_energy_pack"); --军用执勤能量包
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Military_reconnaissance_pack"); --军用侦察物品包
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Old_squadleader_pack"); --老班长特供包
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Setmenu1"); --21式单兵口粮1号餐
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Setmenu2"); --21式单兵口粮2号餐
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Setmenu3"); --21式单兵口粮3号餐
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Setmenu4"); --21式单兵口粮4号餐
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Setmenu5"); --21式单兵口粮5号餐
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.81cigarette"); --八一香烟
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 2.2);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.81cigarette_Pack"); --八一香烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.81cigarette_Carton"); --八一香烟（条装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.02);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.lucky_strike"); --lucky strike
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 6);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.lucky_strike_Pack"); --lucky strike（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Camel_cigarettes"); --Camel
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Camel_cigarettes_Pack"); --Camel（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.double_happiness"); --红双喜香烟
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.double_happiness_Pack"); --红双喜香烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.double_happiness_Carton"); --红双喜香烟（罐装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.06);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Gaoxiba_cigarettes"); --高希欛雪茄
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.Gaoxiba_cigarettes_Pack"); --高希欛雪茄（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.42);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.yulan_cigarettes"); --玉兰花烟
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 3.5);
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, "MR.yulan_cigarettes_Pack"); --玉兰花烟（盒装）
table.insert(ProceduralDistributions["list"]["PoliceFileBox"].items, AlcoholSpawnChance * 0.42);



--UniversityLibraryMagazines--（大学图书馆杂志）
table.insert(ProceduralDistributions["list"]["UniversityLibraryMagazines"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["UniversityLibraryMagazines"].items, MagazineSpawnChance * 4);
--ToolStoreBooks--（工具库书籍）
table.insert(ProceduralDistributions["list"]["ToolStoreBooks"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["ToolStoreBooks"].items, MagazineSpawnChance * 2);
--SafehouseBookShelf--(安全屋书本货架)
table.insert(ProceduralDistributions["list"]["SafehouseBookShelf"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["SafehouseBookShelf"].items, MagazineSpawnChance * 2);
--MagazineRackMixed--(杂志架混合)
table.insert(ProceduralDistributions["list"]["MagazineRackMixed"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["MagazineRackMixed"].items, MagazineSpawnChance * 4);
--BookstoreCrafts--(书店配方)
table.insert(ProceduralDistributions["list"]["BookstoreCrafts"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["BookstoreCrafts"].items, MagazineSpawnChance * 2);
--BookstoreMisc--（书店杂项）
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, MagazineSpawnChance * 4);
--GunStoreLiterature--（枪械库文献）
table.insert(ProceduralDistributions["list"]["GunStoreLiterature"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["GunStoreLiterature"].items, MagazineSpawnChance * 4);
--GunStoreMagazineRack--（枪械店杂志架）
table.insert(ProceduralDistributions["list"]["GunStoreMagazineRack"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["GunStoreMagazineRack"].items, MagazineSpawnChance * 4);
--PoliceCaptainDesk--（警察投诉台）
table.insert(ProceduralDistributions["list"]["PoliceCaptainDesk"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["PoliceCaptainDesk"].items, MagazineSpawnChance * 4);
--PoliceLockers--（警察储物柜）
table.insert(ProceduralDistributions["list"]["PoliceCaptainDesk"].items, "MR.KYEmergency_NewsWeekly"); --驻美应急兵团新闻月刊
table.insert(ProceduralDistributions["list"]["PoliceCaptainDesk"].items, MagazineSpawnChance * 4);


--FishChipsKitchenFreezer-- （炸鱼薯条厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["FishChipsKitchenFreezer"].items, NonPerishableSpawnChance * 2);

--ChineseKitchenFreezer--（中式厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["ChineseKitchenFreezer"].items, NonPerishableSpawnChance * 2);

--RestaurantKitchenFreezer--（饭店厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["RestaurantKitchenFreezer"].items, NonPerishableSpawnChance * 2);

--SushiKitchenFreezer--（寿司厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["SushiKitchenFreezer"].items, NonPerishableSpawnChance * 2);

--ItalianKitchenFreezer--（意大利厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["ItalianKitchenFreezer"].items, NonPerishableSpawnChance * 2);

--BakeryKitchenFreezer-- （面包房厨房冷冻柜）
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, "MR.Lianrong_mooncake"); --四黄莲蓉月饼
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, CannedSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, "MR.Yunnan_HamPie"); --昆明蛋黄火腿月饼
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, CannedSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, "MR.Coconut_CreamCake"); --椰子黄奶油蛋糕
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, "MR.Blueberry_MonkeyCake"); --香芋糯米糍
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, "MR.DingShengGao"); --定胜糕
table.insert(ProceduralDistributions["list"]["BakeryKitchenFreezer"].items, CannedSpawnChance * 3);

--BakeryBread--（面包）
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "MR.Lianrong_mooncake"); --四黄莲蓉月饼
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, CannedSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "MR.Yunnan_HamPie"); --昆明蛋黄火腿月饼
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, CannedSpawnChance * 4);
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "MR.Coconut_CreamCake"); --椰子黄奶油蛋糕
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "MR.Blueberry_MonkeyCake"); --香芋糯米糍
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "MR.DingShengGao"); --定胜糕
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, CannedSpawnChance * 3);

--BakeryMisc--（烘焙杂品）
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Lianrong_mooncake"); --四黄莲蓉月饼
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Yunnan_HamPie"); --昆明蛋黄火腿月饼
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Coconut_CreamCake"); --椰子黄奶油蛋糕
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Blueberry_MonkeyCake"); --香芋糯米糍
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.DingShengGao"); --定胜糕
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);

--BakeryPie--（面包片）
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Coconut_CreamCake"); --椰子黄奶油蛋糕
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.Blueberry_MonkeyCake"); --香芋糯米糍
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "MR.DingShengGao"); --定胜糕
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, CannedSpawnChance * 3);

--CafeteriaSandwiches--(自助餐厅三明治)
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, "MR.Coconut_CreamCake"); --椰子黄奶油蛋糕
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, "MR.Blueberry_MonkeyCake"); --香芋糯米糍
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, CannedSpawnChance * 3);
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, "MR.DingShengGao"); --定胜糕
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, CannedSpawnChance * 3);

--FreezerIceCream--(冷冻冰淇淋)
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["FreezerIceCream"].items, NonPerishableSpawnChance * 2);

--FreezerGeneric--(冷冻通用)
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.TaiwanSausage_MeatSauceRice"); --高雄香肠卤排骨便当
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.General_Tsos_ChickenRice"); --台式三杯鸡拼虾卷盖饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.BeefCurry_OmeletteRice"); --厚芝汉堡肉蛋包饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.MapoTofu_FriedChickenRice"); --麻婆豆腐酥炸鸡块饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.CrabFish_Fillet_CurryRice"); --蟹粉蛋葱烤大排饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.Cantonese_BBQPorkRice"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.Guangzhou_BeefChowMein"); --黯然销魂叉烧蛋饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.HoneyTeriyaki_ChickenChowFan"); --照烧鸡肉蜜汁炒饭
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.Boxed_ShrimpDumplings"); --盒装广州酒家虾饺皇
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.Boxed_XiaoLongBao"); --盒装灌汤鸡汁小笼包
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 2);
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "MR.Boxed_CrabWonton"); --盒装蟹籽鲜肉烧麦
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, NonPerishableSpawnChance * 2);


ItemPickerJava.doParse = true
end

--All credits for SAPPH
local function parseTables()
    if ItemPickerJava.doParse then
        ItemPickerJava.Parse()
        ItemPickerJava.doParse = nil
    end
end

local function addSandboxLootSafe()
    if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
        FadedFeastcraft.DistributionSafety.run("MREfood.addSandboxLoot", addSandboxLoot)
        return
    end
    addSandboxLoot()
end

local function parseTablesSafe()
    if FadedFeastcraft and FadedFeastcraft.DistributionSafety then
        FadedFeastcraft.DistributionSafety.run("MREfood.parseTables", parseTables)
        return
    end
    parseTables()
end

Events.OnInitGlobalModData.Add(addSandboxLootSafe)
Events.OnLoadedMapZones.Add(parseTablesSafe)
