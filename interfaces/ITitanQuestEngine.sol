// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface ITitanQuestEngine {
    function acceptCampaign(uint256 questId) external;
    function claimQuestReward(uint256 questId, bytes calldata proof) external returns (uint256);
}
