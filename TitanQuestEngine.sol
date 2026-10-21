// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TitanQuestEngine {
    struct Quest {
        string questTitle;
        uint256 rewardPerClaim;
        uint256 totalRewardPool;
        uint256 requiredLevel;
        uint256 expiresAt;
        uint256 maxCompletions;
        uint256 completedCount;
        bool isActive;
    }

    struct PlayerProfile {
        uint256 level;
        uint256 experiencePoints;
        uint256 totalQuestsFinished;
        string heroClass;
    }

    address payable public immutable gameDirector;
    string public gameRealmName;
    uint256 public questCount;
    uint256 public xpPerQuestCompletion;

    mapping(uint256 => Quest) public quests;
    mapping(address => PlayerProfile) public players;
    mapping(uint256 => mapping(address => bool)) public hasCompletedQuest;

    event QuestCreated(uint256 indexed questId, string title, uint256 rewardPool);
    event QuestPoolFunded(uint256 indexed questId, uint256 addedAmount);
    event QuestCompleted(uint256 indexed questId, address indexed player, uint256 rewardWon);
    event PlayerProfileInitialized(address indexed player, string heroClass);
    event PlayerLeveledUp(address indexed player, uint256 newLevel);
    event QuestStateUpdated(uint256 indexed questId, bool isActive);
    event GameRealmConfigured(string realmName, uint256 newXpRate);
    event ExpiredQuestFundsReclaimed(uint256 indexed questId, uint256 reclaimedAmount);

    modifier onlyDirector() {
        require(msg.sender == gameDirector, "TitanQuest: Caller is not the Game Director");
        _;
    }

    constructor() {
        gameDirector = payable(msg.sender);
        gameRealmName = "Titan Base Chronicles";
        xpPerQuestCompletion = 250;
    }

    // 1. Инициализация игрового профиля
    function initializePlayer(string calldata heroClass) external {
        require(bytes(heroClass).length > 0, "TitanQuest: Empty hero class");
        PlayerProfile storage p = players[msg.sender];
        require(p.level == 0, "TitanQuest: Profile already exists");

        players[msg.sender] = PlayerProfile({
            level: 1,
            experiencePoints: 0,
            totalQuestsFinished: 0,
            heroClass: heroClass
        });

        emit PlayerProfileInitialized(msg.sender, heroClass);
    }

    // 2. Создание нового квеста с выделением начального фонда наград
    function createQuest(
        string calldata title,
        uint256 rewardPerClaim,
        uint256 requiredLevel,
        uint256 durationSeconds,
        uint256 maxCompletions
    ) external payable onlyDirector returns (uint256) {
        require(msg.value > 0, "TitanQuest: Initial reward pool required");
        require(rewardPerClaim > 0 && rewardPerClaim <= msg.value, "TitanQuest: Invalid reward per claim");
        require(maxCompletions > 0, "TitanQuest: Max completions must be > 0");

        questCount++;
        quests[questCount] = Quest({
            questTitle: title,
            rewardPerClaim: rewardPerClaim,
            totalRewardPool: msg.value,
            requiredLevel: requiredLevel,
            expiresAt: block.timestamp + durationSeconds,
            maxCompletions: maxCompletions,
            completedCount: 0,
            isActive: true
        });

        emit QuestCreated(questCount, title, msg.value);
        return questCount;
    }

    // 3. Дополнительное пополнение призового фонда существующего квеста
    function fundQuestPool(uint256 questId) external payable onlyDirector {
        require(questId > 0 && questId <= questCount, "TitanQuest: Invalid quest ID");
        require(msg.value > 0, "TitanQuest: Zero deposit");

        quests[questId].totalRewardPool += msg.value;
        emit QuestPoolFunded(questId, msg.value);
    }

    // 4. Прохождение квеста и получение награды
    function completeQuest(uint256 questId) external {
        Quest storage q = quests[questId];
        PlayerProfile storage p = players[msg.sender];

        require(questId > 0 && questId <= questCount, "TitanQuest: Quest does not exist");
        require(q.isActive, "TitanQuest: Quest inactive");
        require(block.timestamp < q.expiresAt, "TitanQuest: Quest expired");
        require(p.level >= q.requiredLevel, "TitanQuest: Level too low");
        require(!hasCompletedQuest[questId][msg.sender], "TitanQuest: Already completed");
        require(q.completedCount < q.maxCompletions, "TitanQuest: Max completions reached");
        require(q.totalRewardPool >= q.rewardPerClaim, "TitanQuest: Insufficient quest pool");

        hasCompletedQuest[questId][msg.sender] = true;
        q.completedCount++;
        q.totalRewardPool -= q.rewardPerClaim;

        p.experiencePoints += xpPerQuestCompletion;
        p.totalQuestsFinished++;

        (bool sent, ) = payable(msg.sender).call{value: q.rewardPerClaim}("");
        require(sent, "TitanQuest: Payout failed");

        emit QuestCompleted(questId, msg.sender, q.rewardPerClaim);
    }

    // 5. Повышение уровня игрока при накоплении опыта
    function levelUpPlayer() external {
        PlayerProfile storage p = players[msg.sender];
        require(p.level > 0, "TitanQuest: Profile not initialized");
        require(p.experiencePoints >= p.level * 200, "TitanQuest: Not enough XP to level up");

        p.experiencePoints -= p.level * 200;
        p.level++;

        emit PlayerLeveledUp(msg.sender, p.level);
    }

    // 6. Переключение статуса активности квеста
    function toggleQuestActive(uint256 questId) external onlyDirector {
        require(questId > 0 && questId <= questCount, "TitanQuest: Invalid quest ID");
        quests[questId].isActive = !quests[questId].isActive;
        emit QuestStateUpdated(questId, quests[questId].isActive);
    }

    // 7. Обновление настроек игрового мира
    function updateRealmSettings(string calldata realmName, uint256 newXpRate) external onlyDirector {
        gameRealmName = realmName;
        xpPerQuestCompletion = newXpRate;
        emit GameRealmConfigured(realmName, newXpRate);
    }

    // 8. Возврат остатка призового фонда завершённого или отменённого квеста
    function reclaimQuestPoolFunds(uint256 questId) external onlyDirector {
        Quest storage q = quests[questId];
        require(questId > 0 && questId <= questCount, "TitanQuest: Invalid quest ID");
        uint256 leftover = q.totalRewardPool;
        require(leftover > 0, "TitanQuest: Zero pool balance");

        q.totalRewardPool = 0;
        (bool sent, ) = gameDirector.call{value: leftover}("");
        require(sent, "TitanQuest: Reclaim failed");

        emit ExpiredQuestFundsReclaimed(questId, leftover);
    }

    // Чтение информации о квесте
    function getQuestDetails(uint256 questId) external view returns (
        string memory title,
        uint256 rewardPerClaim,
        uint256 totalRewardPool,
        uint256 requiredLevel,
        uint256 expiresAt,
        uint256 completedCount,
        bool active
    ) {
        Quest memory q = quests[questId];
        return (q.questTitle, q.rewardPerClaim, q.totalRewardPool, q.requiredLevel, q.expiresAt, q.completedCount, q.isActive);
    }
}