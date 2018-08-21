# Test Instructions

The tests in the current directory are intended to check the behavior of the AWSKinesisStreams library. The current set of tests check:
- data writing to AWS Kinesis Stream using AWSKinesisStreams.Producer putRecord and putRecords method
- data reading from AWS Kinesis Stream using different shard iterator types
- processing of wrong parameters passed into the library methods

The tests are written for and should be used with [impTest](https://github.com/electricimp/impTest). See *impTest* documentation for the details of how to configure and run the tests.

The tests for AWSKinesisStreams library require pre-setup described below.

## Create AWS Kinesis Stream

- Open the [Amazon Kinesis console](https://console.aws.amazon.com/kinesis) in your web browser.
- Click **Go to the Streams console**.
- Click **Create Kinesis stream**.
- Enter `imptestStream` into **Kinesis stream name** field.
- Enter `2` into **Number of shards** field.
- Click **Create Kinesis stream**.
- You will be redirected to the Kinesis streams list page.
- Wait until the status of your Stream is changed to **ACTIVE**.
- Click to your Stream name.
- Copy and save somewhere **Stream ARN** of your Stream.
- The ARN format is `arn:aws:kinesis:region:account:stream/name`. Copy and save somewhere the region, e.g. `us-east-2`. It will be used as the value of *AWS_KINESIS_REGION* environment variable.

## Create AWS IAM Policy and User

- Open the [AWS IAM console](https://console.aws.amazon.com/iam) in your web browser.
- Click **Policies** in the left menu.
- Click **Create policy**.
- Click **Select** next to **Policy Generator**.
- Choose **Kinesis** as the **Service**.
- Choose **All Kinesis Actions** in the **Actions** field.
- Click **Resources**.
- Click **Add ARN to restrict access**.
- Enter your **Stream ARN** in the **Specify ARN for stream** field.
- Click **Add**.
- Click **Review policy**.
- Change **Policy Name** to `imptestStreamPolicy`.
- Click **Create Policy**.  
- Click **Users** in the left menu.
- Click **Add user**.
- Enter `imptestStreamUser` in the **User name** field.
- For **Access type** choose **Programmatic access**.
- Click **Next: Permissions**.
- Click **Attach existing policies directly**.
- In the **Search** field enter `imptestStreamPolicy`.
- Select the box to the left of your policy name.
- Click **Next: Review**.
- Click **Create user**.
- Copy and save somewhere the **Access key ID**. It will be used as the value of *AWS_KINESIS_ACCESS_KEY_ID* environment variable.
- Click **Show** under **Secret access key**. Copy and save somewhere the **Secret access key**. It will be used as the value of *AWS_KINESIS_SECRET_ACCESS_KEY* environment variable.

## Environment Variables

Set *AWS_KINESIS_REGION*, *AWS_KINESIS_ACCESS_KEY_ID* and *AWS_KINESIS_SECRET_ACCESS_KEY* environment variables to the values you retrieved and saved in the previous steps.
