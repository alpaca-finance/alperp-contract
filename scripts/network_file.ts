import { ethers, network } from "hardhat";
import fs from "fs";
import * as readlineSync from "readline-sync";
import { HttpNetworkConfig } from "hardhat/types";

export async function generateNetworkFile(): Promise<void> {
  try {
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const name = network.name;
    const url = (network.config as HttpNetworkConfig).url;
    const rpc = url.split("/")[url.split("/").length - 1];
    const srcFileName =
      name === "mainnet"
        ? `${name}-unknown-${chainId}`
        : `.hidden/${name}-${rpc}-unknown-${chainId}`;
    const srcFile = `${__dirname}/../.openzeppelin/${srcFileName}.json`;
    const destFile = `${__dirname}/../.openzeppelin/unknown-${chainId}.json`;
    console.log("Generating a network file..");
    console.table({
      srcFile,
      destFile,
    });
    if (!fs.existsSync(srcFile)) return;
    if (!fs.existsSync(destFile)) {
      // Target file does not exist, create its parent directory and copy the contents of the old file into it
      const parentDir = destFile.split("/").slice(0, -1).join("/");
      fs.mkdirSync(parentDir, { recursive: true });
    }
    fs.renameSync(srcFile, destFile);
    console.log(`✅ successfully rename to a file ${destFile}`);
  } catch (err) {
    console.error(`❌ failed to rename to a file: ${err}`);
    throw err;
  }
}

export async function updateNetworkFile(): Promise<void> {
  try {
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const name = network.name;
    const url = (network.config as HttpNetworkConfig).url;
    const rpc = url.split("/")[url.split("/").length - 1];
    const srcFile = `${__dirname}/../.openzeppelin/unknown-${chainId}.json`;
    const destFileName =
      name === "mainnet"
        ? `${name}-unknown-${chainId}`
        : `.hidden/${name}-${rpc}-unknown-${chainId}`;
    const destFile = `${__dirname}/../.openzeppelin/${destFileName}.json`;
    console.log("Updating a network file..");
    console.table({
      srcFile,
      destFile,
    });
    if (!fs.existsSync(srcFile)) return;
    if (!fs.existsSync(destFile)) {
      // Target file does not exist, create its parent directory and copy the contents of the old file into it
      const parentDir = destFile.split("/").slice(0, -1).join("/");
      fs.mkdirSync(parentDir, { recursive: true });
    }
    fs.renameSync(srcFile, destFile);
    console.log(`✅ successfully rename back to a file ${destFile}`);
  } catch (err) {
    console.error(`❌ failed to rename back a file: ${err}`);
    throw err;
  }
}

export async function withNetworkFile(
  mainFn: () => Promise<void>
): Promise<void> {
  await generateNetworkFile();
  const isSuccess = await (async () => {
    try {
      await mainFn();
      return true;
    } catch (err) {
      console.error(`❌ failed to execute function: ${err}`);
      return false;
    }
  })();
  if (!isSuccess) {
    const confirm = readlineSync.question(
      "Should Update Network File? (y/n): "
    );
    switch (confirm.toLowerCase()) {
      case "y":
        break;
      case "n":
        console.log("Aborting");
        return;
      default:
        console.log("Invalid input");
        return;
    }
  }
  await updateNetworkFile();
}
