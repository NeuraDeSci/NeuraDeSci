// Scripts for deploying the NeuraDeSci contracts

const hre = require("hardhat");

async function main() {
  console.log("Starting deployment of NeuraDeSci contracts...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy NDSToken
  const NDSToken = await hre.ethers.getContractFactory("NDSToken");
  const ndsToken = await NDSToken.deploy();
  await ndsToken.deployed();
  console.log("NDSToken deployed to:", ndsToken.address);

  // Deploy ResearchDataRegistry
  const ResearchDataRegistry = await hre.ethers.getContractFactory("ResearchDataRegistry");
  const dataRegistry = await ResearchDataRegistry.deploy();
  await dataRegistry.deployed();
  console.log("ResearchDataRegistry deployed to:", dataRegistry.address);

  // Deploy NeuroScienceDAO
  const NeuroScienceDAO = await hre.ethers.getContractFactory("NeuroScienceDAO");
  const neuroScienceDAO = await NeuroScienceDAO.deploy(ndsToken.address);
  await neuroScienceDAO.deployed();
  console.log("NeuroScienceDAO deployed to:", neuroScienceDAO.address);

  // Deploy ResearchCollaboration
  const ResearchCollaboration = await hre.ethers.getContractFactory("ResearchCollaboration");
  const researchCollaboration = await ResearchCollaboration.deploy(dataRegistry.address);
  await researchCollaboration.deployed();
  console.log("ResearchCollaboration deployed to:", researchCollaboration.address);

  // Grant DAO role to the DAO contract in the token contract
  const daoRole = await ndsToken.DAO_ROLE();
  await ndsToken.grantRole(daoRole, neuroScienceDAO.address);
  console.log("Granted DAO role to NeuroScienceDAO in NDSToken");

  // Grant minter role to the deployer
  const minterRole = await ndsToken.MINTER_ROLE();
  console.log("Minter role already granted to deployer:", deployer.address);

  // Grant curator role to the deployer in data registry
  const curatorRole = await dataRegistry.CURATOR_ROLE();
  await dataRegistry.grantRole(curatorRole, deployer.address);
  console.log("Granted curator role to deployer in ResearchDataRegistry");

  // Grant scientific committee role to the deployer in research collaboration
  const scientificCommitteeRole = await researchCollaboration.SCIENTIFIC_COMMITTEE_ROLE();
  console.log("Scientific committee role already granted to deployer:", deployer.address);

  console.log("NeuraDeSci contracts deployment completed!");

  // Write deployment addresses to a file for frontend configuration
  const fs = require("fs");
  const deploymentInfo = {
    NDSToken: ndsToken.address,
    ResearchDataRegistry: dataRegistry.address,
    NeuroScienceDAO: neuroScienceDAO.address,
    ResearchCollaboration: researchCollaboration.address,
    networkName: hre.network.name,
    deployTime: new Date().toISOString()
  };

  fs.writeFileSync(
    "deployment-info.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("Deployment information saved to deployment-info.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 