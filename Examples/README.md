# AWSKinesisStreams Examples #

This document describes the example applications provided with the [AWSKinesisStreams library](../README.md):

- [*DataProducer*](#dataproducer), which writes data records to an AWS Kinesis Stream.
- [*DataConsumer*](#dataconsumer), which reads data records from an AWS Kinesis Stream.

To read data you need to run *DataConsumer* in parallel with *DataProducer*. We recommend that you run *DataProducer* as the agent of one imp and run *DataConsumer* as the agent of a second imp.

Each example is described below. If you wish to try one out, you will find [setup instructions](#using-the-examples) further down the page.

**IMPORTANT** Before proceeding, please review [Amazon Kinesis Streams Pricing](https://aws.amazon.com/kinesis/streams/pricing/). Running these examples may not be free of charge.

## DataProducer ##

This example writes data records to the specified preconfigured AWS Kinesis Stream:.

- Data records are written every ten seconds.
- Data records are written using the *putRecord()* and *putRecords()* methods of AWSKinesisStreams.Producer, switching the method every ten seconds.
- Every data record contains:
    - A `"value"` attribute. This is an integer value which starts at 1 and increases by 1 with every record written. It restarts from 1 every time the example is restarted.
    - An `"origin"` attribute. This contains the name of the method used to write the record, ie. `"putRecord"` or `"putRecords"`.

![DataProducer example](../png/ProducerExample.png?raw=true)

## DataConsumer ##

This example reads new data records from all shards of the specified preconfigured AWS Kinesis Stream.

- Only new records, appeared in the AWS Kinesis Streams after the example is started, are read.
- The first read occurs 15 seconds after the example is started.
- After that, data records are read every 15 seconds.
- Every received data record is printed to the log.

![DataConsumer example](../png/ConsumerExample.png?raw=true)

## Using the Examples ##

1. In the [Electric Imp IDE](https://ide.electricim.com/) create two new models, one for imp A and the other for imp B.
1. Copy the [*DataProducer* source code](./DataProducer.agent.nut) and paste it into the IDE as agent code for imp A.
1. Copy the [*DataConsumer* source code](./DataConsumer.agent.nut) and paste it into the IDE as agent code for imp B.
1. Perform [AWS Kinesis Streams Setup](#aws-kinesis-streams-setup) as described below.
1. Perform [Agent Constants Setup](#agent-constants-setup) as described below.
1. Build and Run *DataProducer*.
1. Check from the logs in the IDE that data is being written successfully.
1. Build and Run *DataConsumer*.
1. Check from the logs in the IDE that data is being read successfully.

## AWS Kinesis Streams Setup ##

This process assumes you have an AWS account and are signed in to AWS in your web browser.

**IMPORTANT** Before proceeding, please review [Amazon Kinesis Streams Pricing](https://aws.amazon.com/kinesis/streams/pricing/). Running these examples may not be free of charge.

### Create an AWS Kinesis Stream ###

1. Open the [Amazon Kinesis console](https://console.aws.amazon.com/kinesis) in your web browser.
1. Click **Go to the Streams console**:
![AWS Console](../png/CreateStream1.png?raw=true)
1. Click **Create Kinesis stream**:
![AWS Streams](../png/CreateStream2.png?raw=true)
1. Enter `testStream` into the **Kinesis stream name** field.
1. Enter `1` into the **Number of shards** field.
1. Click **Create Kinesis stream**:
![Create Stream](../png/CreateStream3.png?raw=true)
1. You will be redirected to the Kinesis streams list page.
1. Wait until the status of your Stream is changed to **ACTIVE**.
1. Click to your Stream name:
![Stream list](../png/CreateStream4.png?raw=true)
1. Copy the **Stream ARN** of your Stream and paste it into a text document or equivalent for use later:
![Stream details](../png/CreateStream5.png?raw=true)
1. The ARN format is `arn:aws:kinesis:region:account:stream/name`. Copy the region, eg. `us-east-2` and paste it into a text document or equivalent. It will be used as the value of the *AWS_KINESIS_REGION* constant in the agent code.

### Create an AWS IAM Policy and User ###

1. Open the [AWS IAM console](https://console.aws.amazon.com/iam) in your web browser.
1. Click **Policies** in the left-hand menu:
![AWS IAM](../png/CreatePolicy1.png?raw=true)
1. Click **Create policy**:
![IAM new policy](../png/CreatePolicy2.png?raw=true)
1. Under **Policy Generator**, click **Select**:
![IAM Policy generator](../png/CreatePolicy3.png?raw=true)
1. Choose **Amazon Kinesis** as the **AWS service**.
1. Choose **All Actions** in the **Actions** field:
![IAM Policy](../png/CreatePolicy4.png?raw=true)
1. Enter your **Stream ARN**, which you retrieved above, in the **Amazon Resource Name (ARN)** field.
1. Click **Add Statement**:
![IAM Policy Stream ARN](../png/CreatePolicy5.png?raw=true)
1. Click **Next Step**:
![IAM Policy set permissions](../png/CreatePolicy6.png?raw=true)
1. Change **Policy Name** to `testStreamPolicy`.
1. Click **Create Policy**:  
![IAM Create Policy](../png/CreatePolicy7.png?raw=true)
1. Click **Users** in the left-hand menu.
1. Click **Add user**:
![IAM add user](../png/CreateUser1.png?raw=true)
1. Enter `testStreamUser` in the **User name** field.
1. For **Access type** choose **Programmatic access**.
1. Click **Next: Permissions**:
![IAM user details](../png/CreateUser2.png?raw=true)
1. Click **Attach existing policies directly**:
![IAM user policy](../png/CreateUser3.png?raw=true)
1. In the **Search** field enter `testStreamPolicy`.
1. Check the box to the left of your policy name.
1. Click **Next: Review**:
![IAM set policy](../png/CreateUser4.png?raw=true)
1. Click **Create user**:
![IAM create user](../png/CreateUser5.png?raw=true)
1. Copy the **Access key ID** and paste it onto a text document or equivalent. It will be used as the value of the *AWS_KINESIS_ACCESS_KEY_ID* constant in the agent code.
1. Click **Show** under **Secret access key**. Copy the **Secret access key** and paste it onto a text document or equivalent. It will be used as the value of the *AWS_KINESIS_SECRET_ACCESS_KEY* constant in the agent code:
![IAM user access keys](../png/CreateUser6.png?raw=true)

### Agent Constants Setup ###

1. For the *AWS_KINESIS_REGION*, *AWS_KINESIS_ACCESS_KEY_ID* and *AWS_KINESIS_SECRET_ACCESS_KEY* constants, set the values you retrieved in the previous steps. Set the same values for both *DataProducer* and *DataConsumer*:
![Configuration Constants](../png/ConstSetup.png?raw=true)
