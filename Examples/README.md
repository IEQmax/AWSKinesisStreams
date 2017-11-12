# AWSKinesisStreams Examples

This document describes the example applications provided with the [AWSKinesisStreams library](../README.md).

The following example applications are provided:
- **DataProducer**, it writes data records to AWS Kinesis Stream
- **DataConsumer**, it reads data records from AWS Kinesis Stream

To see data reading you need to run **DataConsumer** example in parallel with **DataProducer** example. We recommend that you:
- run **DataProducer** on the agent of one IMP device
- run **DataConsumer** on the agent of a second IMP device

Each example is described below. If you wish to try one out, you'll find [setup instructions](#examples-setup-and-run) further down the page.

## DataProducer

This example writes data records to the specified preconfigured AWS Kinesis Stream:

- Data records are written every 10 seconds.
- Data records are written using both putRecord and putRecords methods of AWSKinesisStreams.Producer.
- Every data record contains:
  - `"value"` attribute - integer value, which starts at 1 and increases by 1 with every record written. It restarts from 1 everytime when the example is restarted.
  - `"origin"` attribute - contains name of method used to write the record (`"putRecord"` or `"putRecords"`).

![DataProducer example](https://imgur.com/A7DHifN.png)

## DataConsumer

This example reads new data records from all shards of the specified preconfigured AWS Kinesis Stream:

- Data are read every 15 seconds.
- Every received data record is printed to the log.

![DataConsumer example](https://imgur.com/Yb6pGHi.png)

## Examples Setup and Run

- Copy [DataProducer source code](./DataProducer.agent.nut) and paste it into Electric Imp IDE as IMP agent code of the device where you run **DataProducer** example. Note, before running the code you will need to set the configuration constants as described in the [examples setup](#examples-setup) below.
- Copy [DataConsumer source code](./DataConsumer.agent.nut) and paste it into Electric Imp IDE as IMP agent code of the device where you run **DataConsumer** example. Note, before running the code you will need to set the configuration constants as described in the [examples setup](#examples-setup) below.
- Perform the [examples setup](#examples-setup).
- Build and Run **DataProducer** IMP agent code.
- Check from the logs in Electric Imp IDE that data writings are successful.
- Build and Run **DataConsumer** IMP agent code.
- Check from the logs in Electric Imp IDE that data readings are successful.

### Examples Setup

#### Create AWS Kinesis Stream

- Open the [Amazon Kinesis console](https://console.aws.amazon.com/kinesis) in your web browser.
- Click **Go to the Streams console**.
![AWS Console](https://imgur.com/mp4wdlg.png)
- Click **Create Kinesis stream**.
![AWS Streams](https://imgur.com/0qDSeoX.png)
- Enter `testStream` into **Kinesis stream name** field.
- Enter `1` into **Number of shards** field.
- Click **Create Kinesis stream**.
![Create Stream](https://imgur.com/9BzfifO.png)
- You will be redirected to the Kinesis streams list page.
- Wait until the status of your Stream is changed to **ACTIVE**.
- Click to your Stream name.
![Stream list](https://imgur.com/89ggWDP.png)
- Copy and save somewhere **Stream ARN** of your Stream.
![Stream details](https://imgur.com/LvNgM1X.png)
- The ARN format is `arn:aws:kinesis:region:account:stream/name`. Copy and save somewhere the region, e.g. `us-east-2`. It will be used as the value of *AWS_KINESIS_REGION* constant in the example code for IMP agent.

#### Create AWS IAM Policy and User

- Open the [AWS IAM console](https://console.aws.amazon.com/iam) in your web browser.
- Click **Policies** in the left menu.
![AWS IAM](https://imgur.com/z8F0Krl.png)
- Click **Create policy**.
![IAM new policy](https://imgur.com/TYkKvGD.png)
- Click **Select** next to **Policy Generator**.
![IAM Policy generator](https://imgur.com/DiJ6O9Z.png)
- Choose **Amazon Kinesis** as the **AWS service**.
- Choose **All Actions** in the **Actions** field.
![IAM Policy](https://imgur.com/yX2L0jN.png)
- Enter your **Stream ARN** in the **Amazon Resource Name (ARN)** field.
- Click **Add Statement**.
![IAM Policy Stream ARN](https://imgur.com/10rzsNJ.png)
- Click **Next Step**.
![IAM Policy set permissions](https://imgur.com/7tAuK8L.png)
- Change **Policy Name** to `testStreamPolicy`.
- Click **Create Policy**.  
![IAM Create Policy](https://imgur.com/PTj2fIQ.png)
- Click **Users** in the left menu.
- Click **Add user**.
![IAM add user](https://imgur.com/84fMiQw.png)
- Enter `testStreamUser` in the **User name** field.
- For **Access type** choose **Programmatic access**.
- Click **Next: Permissions**.
![IAM user details](https://imgur.com/S3GJMRd.png)
- Click **Attach existing policies directly**.
![IAM user policy](https://imgur.com/WCHjnrV.png)
- In the **Search** field enter `testStreamPolicy`.
- Select the box to the left of your policy name.
- Click **Next: Review**.
![IAM set policy](https://imgur.com/ZdHV3US.png)
- Click **Create user**.
![IAM create user](https://imgur.com/VUI0FLk.png)
- Copy and save somewhere the **Access key ID**. It will be used as the value of *AWS_KINESIS_ACCESS_KEY_ID* constant in the example code for IMP agent.
![IAM user access keys](https://imgur.com/4MzqRyJ.png)
- Click **Show** under **Secret access key**. Copy and save somewhere the **Secret access key**. It will be used as the value of *AWS_KINESIS_SECRET_ACCESS_KEY* constant in the example code for IMP agent.

#### IMP Agent Constants Setup

- For *AWS_KINESIS_REGION*, *AWS_KINESIS_ACCESS_KEY_ID* and *AWS_KINESIS_SECRET_ACCESS_KEY* constants in the example code for IMP agent: set the values you retrieved and saved in the previous steps. Set the same values for the both examples - **DataProducer** and **DataConsumer**.
![Configuration Constants](https://imgur.com/Er5JKmF.png)
