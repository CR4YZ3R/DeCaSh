import { readFileSync } from "fs";
import { join } from "path";
import { ethers } from "ethers";
import RENTAL_CAR_ARTIFACT
    from "../artifacts/contracts/RentalCar.sol/RentalCar.json"
    with { type: "json" };
import { RENTAL_CAR_ADDRESS } from "./config.js";

const RPC_URL = "http://localhost:8545";
const CONTRACT_ADDRESS = RENTAL_CAR_ADDRESS;
const CAR_PRIVATE_KEY = "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0";

const RENTAL_CAR_ABI = RENTAL_CAR_ARTIFACT.abi;

async function main() {
  const { pA, pB, pC, signature } = JSON.parse(
    readFileSync(join(import.meta.dirname, "proof.json"), "utf8")
  );

  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(CAR_PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, RENTAL_CAR_ABI, signer);

  const hasAccess = await contract.verifyAccess(pA, pB, pC, signature);
  console.log("Access granted:", hasAccess);
}

main().catch(console.error);
