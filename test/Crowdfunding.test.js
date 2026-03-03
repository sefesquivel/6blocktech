const { expect } = require("chai");
const { ethers } = require("hardhat");
 
describe("CrowdfundingFactory", function () {
  let factory, owner, addr1, addr2;
 
  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory(
      "CrowdfundingFactory"
    );
    factory = await Factory.deploy();
  });
 
  it("should deploy with correct owner", async function () {
    expect(await factory.owner()).to.equal(owner.address);
  });
 
  it("should start unpaused", async function () {
    expect(await factory.paused()).to.equal(false);
  });
 
  it("should create a campaign", async function () {
    const goal = ethers.parseEther("1");
    await factory.connect(addr1).createCampaign(
      "Test Campaign",
      "A test",
      goal,
      7
    );
    const campaigns = await factory.getAllCampaigns();
    expect(campaigns.length).to.equal(1);
    expect(campaigns[0].name).to.equal("Test Campaign");
    expect(campaigns[0].owner).to.equal(addr1.address);
  });
 
  it("should reject campaign creation when paused", async function () {
    await factory.togglePause();
    await expect(
      factory.createCampaign(
        "Paused Campaign", "desc", ethers.parseEther("1"), 7
      )
    ).to.be.revertedWith("Factory is paused");
  });
 
  it("should track user campaigns separately", async function () {
    const goal = ethers.parseEther("0.5");
    await factory.connect(addr1).createCampaign("Camp A","d",goal,7);
    await factory.connect(addr2).createCampaign("Camp B","d",goal,7);
 
    const addr1Camps = await factory.getUserCampaigns(addr1.address);
    const addr2Camps = await factory.getUserCampaigns(addr2.address);
 
    expect(addr1Camps.length).to.equal(1);
    expect(addr2Camps.length).to.equal(1);
    expect(addr1Camps[0].name).to.equal("Camp A");
    expect(addr2Camps[0].name).to.equal("Camp B");
  });
});
 
describe("Crowdfunding (via factory)", function () {
  let factory, campaign, owner, backer;
 
  beforeEach(async function () {
    [owner, backer] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory(
      "CrowdfundingFactory"
    );
    factory = await Factory.deploy();
 
    const goal = ethers.parseEther("0.01");
    await factory.createCampaign(
      "My Campaign", "Desc", goal, 7
    );
    const camps = await factory.getAllCampaigns();
    campaign = await ethers.getContractAt(
      "Crowdfunding",
      camps[0].campaignAddress
    );
  });
 
  it("should allow owner to add tiers", async function () {
    await campaign.addTier("Bronze", ethers.parseEther("0.001"));
    const tiers = await campaign.getTiers();
    expect(tiers.length).to.equal(1);
    expect(tiers[0].name).to.equal("Bronze");
  });
 
  it("should allow funding a tier", async function () {
    const amount = ethers.parseEther("0.001");
    await campaign.addTier("Bronze", amount);
    await campaign.connect(backer).fund(0, { value: amount });
    expect(await campaign.getContractBalance()).to.equal(amount);
  });
 
  it("should reject incorrect fund amount", async function () {
    const amount = ethers.parseEther("0.001");
    await campaign.addTier("Bronze", amount);
    await expect(
      campaign.connect(backer).fund(0, {
        value: ethers.parseEther("0.002")
      })
    ).to.be.revertedWith("Incorrect amount.");
  });
 
  it("should toggle pause correctly", async function () {
    expect(await campaign.paused()).to.equal(false);
    await campaign.togglePause();
    expect(await campaign.paused()).to.equal(true);
    await campaign.togglePause();
    expect(await campaign.paused()).to.equal(false);
  });
});
