# AWSKinesisStreams Examples

This document describes the example applications provided with the [AWSKinesisStreams library](../README.md).

The following example applications are provided:
- [DataProducer](#dataproducer), it writes data records to AWS Kinesis Stream,
- [DataConsumer](#dataconsumer), it reads data records from AWS Kinesis Stream.

To see data reading you need to run **DataConsumer** example in parallel with **DataProducer** example. We recommend that you:
- run **DataProducer** on the agent of one IMP device,
- run **DataConsumer** on the agent of a second IMP device.

Each example is described below. If you wish to try one out, you'll find [setup instructions](#setup-and-run) further down the page.

## DataProducer

This example writes data records to the specified preconfigured AWS Kinesis Stream:

- Data records are written every 10 seconds.
- Data records are written using *putRecord()* or *putRecords()* method of AWSKinesisStreams.Producer, switching the method after every 10 seconds.
- Every data record contains:
  - `"value"` attribute - integer value, which starts at 1 and increases by 1 with every record written. It restarts from 1 everytime when the example is restarted.
  - `"origin"` attribute - contains name of method used to write the record (`"putRecord"` or `"putRecords"`).

![DataProducer example](../png/ProducerExample.png?raw=true)

## DataConsumer

This example reads new data records from all shards of the specified preconfigured AWS Kinesis Stream:

- Only new records, appeared in the Amazon Kinesis Streams after the example is started, are read.
- The first read occurs 15 seconds after the example is started.
- After that, data records are read every 15 seconds.
- Every received data record is printed to the log.

![DataConsumer example](../png/ConsumerExample.png?raw=true)

## Setup and Run

- Copy [DataProducer source code](./DataProducer.agent.nut) and paste it into Electric Imp IDE as IMP agent code of the device where you run **DataProducer** example. Note, before running the code you will need to set the configuration constants as described later in [IMP Agent Constants Setup](#imp-agent-constants-setup).
- Copy [DataConsumer source code](./DataConsumer.agent.nut) and paste it into Electric Imp IDE as IMP agent code of the device where you run **DataConsumer** example. Note, before running the code you will need to set the configuration constants as described later in [IMP Agent Constants Setup](#imp-agent-constants-setup).
- Perform [AWS Kinesis Streams Setup](#aws-kinesis-streams-setup) described below.
- Perform [IMP Agent Constants Setup](#imp-agent-constants-setup) described below.
- Build and Run **DataProducer** IMP agent code.
- Check from the logs in Electric Imp IDE that data writings are successful.
- Build and Run **DataConsumer** IMP agent code.
- Check from the logs in Electric Imp IDE that data readings are successful.

### AWS Kinesis Streams Setup

The setup assumes you have AWS account and signed in AWS in your web browser.

**IMPORTANT:** Before the setup check [Amazon Kinesis Streams Pricing](https://aws.amazon.com/kinesis/streams/pricing/).

#### Create AWS Kinesis Stream

- Open the [Amazon Kinesis console](https://console.aws.amazon.com/kinesis) in your web browser.
- Click **Go to the Streams console**.
![AWS Console](../png/CreateStream1.png?raw=true)
- Click **Create Kinesis stream**.
![AWS Streams](../png/CreateStream2.png?raw=true)
- Enter `testStream` into **Kinesis stream name** field.
- Enter `1` into **Number of shards** field.
- Click **Create Kinesis stream**.
![Create Stream](../png/CreateStream3.png?raw=true)
- You will be redirected to the Kinesis streams list page.
- Wait until the status of your Stream is changed to **ACTIVE**.
- Click to your Stream name.
![Stream list](../png/CreateStream4.png?raw=true)
- Copy and save somewhere **Stream ARN** of your Stream.
![Stream details](../png/CreateStream5.png?raw=true)
- The ARN format is `arn:aws:kinesis:region:account:stream/name`. Copy and save somewhere the region, e.g. `us-east-2`. It will be used as the value of *AWS_KINESIS_REGION* constant in the example code for IMP agent.

#### Create AWS IAM Policy and User

- Open the [AWS IAM console](https://console.aws.amazon.com/iam) in your web browser.
- Click **Policies** in the left menu.
![AWS IAM](../png/CreatePolicy1.png?raw=true)
- Click **Create policy**.
![IAM new policy](../png/CreatePolicy2.png?raw=true)
- Click **Select** next to **Policy Generator**.
![IAM Policy generator](../png/CreatePolicy3.png?raw=true)
- Choose **Amazon Kinesis** as the **AWS service**.
- Choose **All Actions** in the **Actions** field.
![IAM Policy](../png/CreatePolicy4.png?raw=true)
- Enter your **Stream ARN**, which you retrieved and saved early, in the **Amazon Resource Name (ARN)** field.
- Click **Add Statement**.
![IAM Policy Stream ARN](../png/CreatePolicy5.png?raw=true)
- Click **Next Step**.
![IAM Policy set permissions](../png/CreatePolicy6.png?raw=true)
- Change **Policy Name** to `testStreamPolicy`.
- Click **Create Policy**.  
![IAM Create Policy](../png/CreatePolicy7.png?raw=true)
- Click **Users** in the left menu.
- Click **Add user**.
![IAM add user](../png/CreateUser1.png?raw=true)
- Enter `testStreamUser` in the **User name** field.
- For **Access type** choose **Programmatic access**.
- Click **Next: Permissions**.
![IAM user details](../png/CreateUser2.png?raw=true)
- Click **Attach existing policies directly**.
![IAM user policy](../png/CreateUser3.png?raw=true)
- In the **Search** field enter `testStreamPolicy`.
- Select the box to the left of your policy name.
- Click **Next: Review**.
![IAM set policy](../png/CreateUser4.png?raw=true)
- Click **Create user**.
![IAM create user](../png/CreateUser5.png?raw=true)
- Copy and save somewhere the **Access key ID**. It will be used as the value of *AWS_KINESIS_ACCESS_KEY_ID* constant in the example code for IMP agent.
- Click **Show** under **Secret access key**. Copy and save somewhere the **Secret access key**. It will be used as the value of *AWS_KINESIS_SECRET_ACCESS_KEY* constant in the example code for IMP agent.
![IAM user access keys](../png/CreateUser6.png?raw=true)

### IMP Agent Constants Setup

- For *AWS_KINESIS_REGION*, *AWS_KINESIS_ACCESS_KEY_ID* and *AWS_KINESIS_SECRET_ACCESS_KEY* constants in the example code for IMP agent: set the values you retrieved and saved in the previous steps. Set the same values for the both examples - **DataProducer** and **DataConsumer**.
![Configuration Constants](../png/ConstSetup.png?raw=true)
