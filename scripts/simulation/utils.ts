import MainnetConfig from "../../contracts.json";
import TenderlyConfig from "../../contracts.tenderly.json";

import { HardhatRuntimeEnvironment } from "hardhat/types";

import AWS from "aws-sdk";
import { ManagedUpload } from "aws-sdk/clients/s3";
import { IConfig, IS3Service } from "./interfaces";

export function getConfig(hre: HardhatRuntimeEnvironment): IConfig {
  const network = hre.network;
  if (network.name === "mainnet") {
    return MainnetConfig;
  }
  if (network.name === "tenderly") {
    return TenderlyConfig;
  }
  throw new Error("not found config");
}

export class S3Service implements IS3Service {
  private s3Bucket: AWS.S3;
  constructor(accessKey: string, secretAccessKey: string) {
    if (!accessKey || !secretAccessKey)
      throw new Error(
        "S3Service::constructor: accessKey or secretAccessKey is not defined"
      );

    this.s3Bucket = new AWS.S3({
      accessKeyId: accessKey,
      secretAccessKey: secretAccessKey,
    });
  }

  async upload<T>(
    content: T,
    bucketName: string,
    fileName: string
  ): Promise<string> {
    const buf = Buffer.from(JSON.stringify(content));
    const data = {
      Bucket: bucketName,
      Key: fileName,
      Body: buf,
      ContentEncoding: "base64",
      ContentType: "application/json",
    };

    return new Promise((resolve, reject) => {
      this.s3Bucket.upload(
        data,
        function (err: Error, data: ManagedUpload.SendData) {
          if (err) {
            console.error(
              `[S3Service/upload] unable to put file to s3 bucket: ${err}`
            );
            return reject(err);
          }
          return resolve(data.Location);
        }
      );
    });
  }
}
