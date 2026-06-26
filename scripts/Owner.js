import { writeFileSync } from "fs";
import { join } from "path";
import { ethers } from "ethers";
import VERIFIER_ARTIFACT
    from "../artifacts/contracts/Verifier.sol/Groth16Verifier.json"
    with { type: "json" };

import RENTAL_CAR_ARTIFACT
    from "../artifacts/contracts/RentalCar.sol/RentalCar.json"
    with { type: "json" };
const RPC_URL = "http://localhost:8545";
const OWNER_PRIVATE_KEY = "0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e";
let verifierAddress = "";

const VERIFIER_ABI = VERIFIER_ARTIFACT.abi;
const VERIFIER_BYTECODE = VERIFIER_ARTIFACT.bytecode;

const RENTAL_CAR_ABI = RENTAL_CAR_ARTIFACT.abi;
const RENTAL_CAR_BYTECODE = RENTAL_CAR_ARTIFACT.bytecode;
let rentalCarAddress = "";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(OWNER_PRIVATE_KEY, provider);

  console.log("Deploying contracts...");

  const verifierFactory = new ethers.ContractFactory(VERIFIER_ABI, VERIFIER_BYTECODE, signer);
  const verifierContract = await verifierFactory.deploy();
  await verifierContract.waitForDeployment();
  verifierAddress = await verifierContract.getAddress();
  console.log("Verifier deployed at:", verifierAddress);
  
  const rentalCarFactory = new ethers.ContractFactory(RENTAL_CAR_ABI, RENTAL_CAR_BYTECODE, signer);
  const nonce = await provider.getTransactionCount(signer.address, "latest");
  const rentalCarContract = await rentalCarFactory.deploy(verifierAddress, { nonce });
  await rentalCarContract.waitForDeployment();
  rentalCarAddress = await rentalCarContract.getAddress();
  console.log("RentalCar deployed at:", rentalCarAddress);

  writeFileSync(
    join(import.meta.dirname, "config.js"),
    `export const VERIFIER_ADDRESS = "${verifierAddress}";\nexport const RENTAL_CAR_ADDRESS = "${rentalCarAddress}";\n`
  );
  console.log("Addresses exported to scripts/config.js");
}

main().catch(console.error);
