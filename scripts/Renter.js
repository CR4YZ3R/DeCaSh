const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { buildPoseidon } = require("circomlibjs");
const { ethers } = require("ethers");
const { groth16 } = require("snarkjs");

// --- Configuration ---
const RPC_URL = "http://localhost:8545";
const CONTRACT_ADDRESS = "0xDeployedRentalCarAddress";
const RENTER_PRIVATE_KEY = "0xYourRenterPrivateKey";
const HOURS_TO_RENT = 2;

const WASM_PATH = path.join(__dirname, "../circuits/ProofValidKey_js/ProofValidKey.wasm");
const ZKEY_PATH = path.join(__dirname, "../circuits/rental.zkey");

const RENTAL_CAR_ABI = [
  "function rentCar(uint8 hoursToRent, uint256 commitment) external payable",
];

async function main() {
  // 1. Generate secret and compute its Poseidon commitment
  const secretHex = crypto.randomBytes(32).toString("hex");
  const secret = BigInt("0x" + secretHex);

  const poseidon = await buildPoseidon();
  const commitment = poseidon.F.toObject(poseidon([secret]));

  console.log("Secret:", secretHex);
  console.log("Commitment:", commitment.toString());

  // 2. Store commitment on-chain (renter books the car)
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(RENTER_PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, RENTAL_CAR_ABI, signer);

  const tx = await contract.rentCar(HOURS_TO_RENT, commitment);
  await tx.wait();
  console.log("Booking stored on-chain. Tx:", tx.hash);

  // 3. Generate ZK proof that we know the secret behind the commitment
  const { proof, publicSignals } = await groth16.fullProve(
    { secret: secret.toString(), commitment: commitment.toString() },
    WASM_PATH,
    ZKEY_PATH
  );

  // 4. Parse proof into the components the contract expects: pA, pB, pC
  const calldata = await groth16.exportSolidityCallData(proof, publicSignals);
  const [pA, pB, pC] = JSON.parse("[" + calldata + "]");

  fs.writeFileSync(path.join(__dirname, "proof.json"), JSON.stringify({ pA, pB, pC }));
  console.log("Proof saved to scripts/proof.json");
}

main().catch(console.error);
