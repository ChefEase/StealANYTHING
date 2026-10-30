--!strict

export type ItemId = "toaster" | "duck" | "traffic_cone" | "disco_bin"
    | "gold_toilet" | "jelly_lamp" | "snack_machine" | "moon_rock"
    | "mini_ufo" | "dinosaur_skull" | "storm_jar" | "giant_diamond"
export type CarryBehavior = "Heavy" | "Noisy" | "Bouncy"
export type Rarity = "Common" | "Uncommon" | "Rare" | "Legendary"
export type FootprintClass = "Small" | "Medium" | "Heavy"
export type SlotId = "protected" | "exposed_01" | "exposed_02" | "exposed_03"
    | "exposed_04" | "exposed_05" | "exposed_06" | "exposed_07"
    | "exposed_08" | "exposed_09"

export type ItemDefinition = {
    id: ItemId,
    name: string,
    tier: Rarity,
    carry: CarryBehavior,
    sizeClass: FootprintClass,
    baseIncomePerMinute: number,
    shopPrice: number?,
    depotWeight: number,
    modelKey: string,
    iconKey: string,
}

export type ContractDefinition = {
    id: string,
    name: string,
    requirementPaths: {[string]: number},
    cashReward: number,
    eligibility: "Always" | "UnownedObtainableItem",
}

export type UpgradeDefinition = {
    id: string,
    tier: number,
    name: string,
    cost: number,
    requirementPaths: {[string]: number},
    unlockedSlots: {SlotId},
    cosmeticId: string,
}

export type Exhibit = {
    state: "Available" | "Missing",
    registeredAtUnix: number,
    acquisition: "Tutorial" | "Depot" | "Shop",
    missingOperationId: string?,
    previousSlotId: SlotId?,
    recoveryJobsDone: number,
}

export type Contract = {
    instanceId: string,
    definitionId: string,
    progress: {[string]: number},
    assignedAtUnix: number,
    completed: boolean,
    claimed: boolean,
}

export type Operation = {
    kind: "DepotDelivery" | "TutorialProgress" | "ShopPurchase" | "UpgradePurchase"
        | "RaidLoss" | "RecoveryParcel" | "RecoveryRestore"
        | "ContractClaim" | "ExhibitArrangement",
    result: "Committed" | "Rejected",
    committedAtUnix: number,
    requestScope: string,
    resultCode: string,
}

export type Settings = {
    masterVolume: number,
    musicVolume: number,
    effectsVolume: number,
    reduceMotion: boolean,
    lowEffects: boolean,
    travelTipsEnabled: boolean,
    collectionTutorialDone: boolean,
}

export type Lifetime = {
    npcDeliveries: number,
    pvpDeliveries: number,
    recoveryParcels: number,
    distinctRegistered: number,
    totalCashEarned: number,
}

export type RaidCycle = {
    phase: "Protected" | "Open" | "RetryShield",
    remainingSeconds: number,
}

export type MuseumRecord = {
    version: number,
    tier: number,
    styleId: string,
    groundsPresetId: string,
    securityLevel: number,
}

export type PlayerProfile = {
    schemaVersion: number,
    revision: number,
    createdAtUnix: number,
    lastSavedAtUnix: number,
    cash: number,
    incomeRemainder: number,
    exhibits: {[ItemId]: Exhibit},
    displaySlots: {[SlotId]: ItemId},
    collectionIndex: {[ItemId]: boolean},
    publicDisplayApproved: {[ItemId]: boolean},
    publicDisplayMode: "Auto" | "Manual",
    museum: MuseumRecord,
    accreditation: number,
    lifetime: Lifetime,
    tutorialStep: number,
    beginnerActiveSeconds: number,
    contracts: {Contract},
    pinnedContractId: string?,
    activeRecoveryType: ItemId?,
    settings: Settings,
    cosmetics: {[string]: boolean},
    recentOperations: {[string]: Operation},
    operationOrder: {string},
    raidCycle: RaidCycle,
}

return table.freeze({})
