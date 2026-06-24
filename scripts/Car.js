const fs = require("fs");
const path = require("path");
const { ethers } = require("ethers");

// --- Configuration ---
const RPC_URL = "http://localhost:8545";
const CONTRACT_ADDRESS = "0xDeployedRentalCarAddress";
const CAR_PRIVATE_KEY = "0xYourCarPrivateKey";

const RENTAL_CAR_ABI = [
  "function verifyAccess(uint[2] _pA, uint[2][2] _pB, uint[2] _pC) external view returns (bool)",
];

async function main() {
  const { pA, pB, pC } = JSON.parse(
    fs.readFileSync(path.join(__dirname, "proof.json"), "utf8")
  );

  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(CAR_PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, RENTAL_CAR_ABI, signer);

  const hasAccess = await contract.verifyAccess(pA, pB, pC);
  console.log("Access granted:", hasAccess);
}

main().catch(console.error);
