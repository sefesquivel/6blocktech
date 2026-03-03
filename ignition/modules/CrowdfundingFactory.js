const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules');
 
module.exports = buildModule("CrowdfundingFactoryModule", (m) => {
  // Deploy CrowdfundingFactory — it will deploy Crowdfunding
  // instances internally when createCampaign() is called.
  const factory = m.contract("CrowdfundingFactory");
 
  return { factory };
});
