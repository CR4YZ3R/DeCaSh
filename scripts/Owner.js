const { ethers } = require("ethers");

// --- Configuration ---
// Get VERIFIER_ADDRESS by running: snarkjs zkey export solidityverifier rental.zkey ../contracts/Verifier.sol
// then deploying Verifier.sol via Remix. Paste the deployed address here.
const RPC_URL = "http://localhost:8545";
const OWNER_PRIVATE_KEY = "0xYourOwnerPrivateKey";
const VERIFIER_ADDRESS = "0xDeployedVerifierAddress";

// Paste ABI + bytecode from Remix after compiling RentalCar.sol
const RENTAL_CAR_ABI = ["constructor(address verifierAddress)"];
const RENTAL_CAR_BYTECODE = "0xYourByteCode";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(OWNER_PRIVATE_KEY, provider);

  const factory = new ethers.ContractFactory(RENTAL_CAR_ABI, RENTAL_CAR_BYTECODE, signer);
  const contract = await factory.deploy(VERIFIER_ADDRESS);
  await contract.waitForDeployment();

  console.log("RentalCar deployed at:", await contract.getAddress());
}

main().catch(console.error);
