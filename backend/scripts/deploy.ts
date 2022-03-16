import { ethers } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { WAKULIMA_NFT_ADDRESS } from "../constants";

const main = async () => {
  try {
    const MarketplaceContract = await (
      await ethers.getContractFactory("WakulimaMarketPlace")
    ).deploy();
    await MarketplaceContract.deployed();

    const DAOContract = await (
      await ethers.getContractFactory("WakulimaDao")
    ).deploy(MarketplaceContract.address, WAKULIMA_NFT_ADDRESS, {
      value: ethers.utils.parseEther("1"),
    });
    await DAOContract.deployed();

    console.log("DAO DEPLOYED AT: => :", DAOContract.address);
  } catch (error) {
    console.log("main ERr: ", error);
  }
};

main();
