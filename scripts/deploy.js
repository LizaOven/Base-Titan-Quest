const hre = require("hardhat");
async function main() {
  const QuestCore = await hre.ethers.getContractFactory("TitanQuestEngine");
  const engine = await QuestCore.deploy();
  await engine.deployed();
  console.log("-> Quest Engine successfully initialized at:", engine.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
