import { randomBytes } from "crypto";
import { writeFileSync } from "fs";
import { join } from "path";
import { buildPoseidon } from "circomlibjs";
import { ethers } from "ethers";
import { groth16 } from "snarkjs";
import RENTAL_CAR_ARTIFACT
    from "../artifacts/contracts/RentalCar.sol/RentalCar.json"
    with { type: "json" };
import { RENTAL_CAR_ADDRESS } from "./config.js";

const RPC_URL = "http://localhost:8545";
const CONTRACT_ADDRESS = RENTAL_CAR_ADDRESS;
const RENTER_PRIVATE_KEY = "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd";
const HOURS_TO_RENT = 2;

const WASM_PATH = join(import.meta.dirname, "../circuits/ProofValidKey_js/ProofValidKey.wasm");
const ZKEY_PATH = join(import.meta.dirname, "../circuits/rental.zkey");

const RENTAL_CAR_ABI = RENTAL_CAR_ARTIFACT.abi;

async function main() {
  const secretHex = randomBytes(32).toString("hex");
  const secret = BigInt("0x" + secretHex);

  const poseidon = await buildPoseidon();
  const commitment = poseidon.F.toObject(poseidon([secret]));

  console.log("Secret:", secretHex);
  console.log("Commitment:", commitment.toString());

  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(RENTER_PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, RENTAL_CAR_ABI, signer);

  const tx = await contract.rentCar(HOURS_TO_RENT, commitment, {value: ethers.parseEther("1")});
  await tx.wait();
  console.log("Booking stored on-chain. Tx:", tx.hash);

  const { proof, publicSignals } = await groth16.fullProve(
    { secret: secret.toString(), commitment: commitment.toString() },
    WASM_PATH,
    ZKEY_PATH
  );

  const calldata = await groth16.exportSolidityCallData(proof, publicSignals);
  const [pA, pB, pC] = JSON.parse("[" + calldata + "]");

  const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
    ["uint256[2]", "uint256[2][2]", "uint256[2]"],
    [pA, pB, pC]
  );
  const proofHash = ethers.keccak256(encoded);
  const signature = await signer.signMessage(ethers.getBytes(proofHash));
  console.log("Proof hash:", proofHash);
  console.log("Proof signature:", signature);

  writeFileSync(join(import.meta.dirname, "proof.json"), JSON.stringify({ pA, pB, pC, signature }));
  console.log("Proof saved to scripts/proof.json");
}

main().catch(console.error);
