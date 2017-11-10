# AWSKinesisStreams

This library lets your agent code to work with [Amazon Kinesis Streams](https://aws.amazon.com/kinesis/streams/). It makes use of the [Amazon Kinesis Streams REST API](http://docs.aws.amazon.com/kinesis/latest/APIReference/).

This version of the library supports the following functionality:

- writing data records into an Amazon Kinesis stream
- getting data records from an Amazon Kinesis stream's shard

**To add this library to your project, add** `#require "AWSKinesisStreams.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## Prerequisites

Before using the library you need to have:

- *region* &mdash; **The Region code** of Amazon EC2. See [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
- *accessKeyId* &mdash; **Access key ID** of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html).
- *secretAccessKey* &mdash; **Secret access key** of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html).

Also, you need to understand all the main Amazon Kinesis Streams concepts and terms, like stream, shard, record, etc. and know a name of Amazon Kinesis stream which is your application going to work with.

## Library Usage

The library consists of two main and independent parts &mdash; [Data Writing](#data-writing) and [Data Reading](#data-reading). You can instantiate and use any of these parts in your agent code as required by your application. Also, the library includes [Common Components](#common-components) which are used by the both main parts.

### Common Components

#### Callbacks

All requests that are made to the Amazon Kinesis Streams library occur asynchronously. Every method that sends a request has an optional parameter which takes a callback function that will be called when the operation is completed, successfully or not. The callbacks’ parameters are listed in the corresponding method documentation, but every callback has at least one parameter, *error*. If *error* is `null`, the operation has been executed successfully. Otherwise, *error* is an instance of the [AWSKinesisStreams.Error](#awskinesisstreamserror-class) class and contains the details of the error.

#### AWSKinesisStreams.Error Class

Represents an error returned by the library and has the following public properties:

- *type* &mdash; The error type, which is one of the following *AWS_KINESIS_STREAMS_ERROR* enum values:

  - *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR* &mdash; The library is wrongly initialized, or a method is called with invalid argument(s), or an internal error. The error details can be found in the *details* property. Usually it indicates an issue during an application development which should be fixed during debugging and therefore should not occur after the application has been deployed.
  
  - *AWS_KINESIS_STREAMS_ERROR.REQUEST_FAILED* &mdash; HTTP request to Amazon Kinesis Streams fails. The error details can be found in the *details*, *httpStatus* and *httpResponse* properties. This error may occur during the normal execution of an application. The application logic should process this error.
  
  - *AWS_KINESIS_STREAMS_ERROR.UNEXPECTED_RESPONSE* &mdash; An unexpected response from Amazon Kinesis Streams. The error details can be found in the *details* and *httpResponse* properties.
  
- *details* &mdash; A string with human readable details of the error.

- *httpStatus* &mdash; An integer indicating the HTTP status code, or `null` if *type* is *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR*

- *httpResponse* &mdash; A table of key-value strings holding the response body of the failed request, or `null` if *type* is *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR*.

#### AWSKinesisStreams Class

##### setDebug(*value*)

This method enables (*value* = `true`) or disables (*value* = `false`) the library debug output (including error logging). It is disabled by default. The method returns nothing.

#### AWS_KINESIS_STREAMS_ENCRYPTION_TYPE Enum

The encryption type used on a record. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-EncryptionType). Has the following values:
  - *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE* &mdash; Record is not encrypted.
  - *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.KMS* &mdash; Record is encrypted on server side using a customer-managed KMS key.

#### AWSKinesisStreams.Record Class

Represents an Amazon Kinesis Streams record: a combination of data attributes. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *data* | Blob or any JSON-compatible type | The record data |
| *partitionKey* | String | Identifies which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-PartitionKey) |
| *sequenceNumber* | String | The unique identifier of the record within its shard. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-SequenceNumber) |
| *timestamp* | Integer | The approximate time that the record was inserted into the stream. In number of seconds since Unix epoch (midnight, 1 Jan 1970). |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record |

##### Constructor: AWSKinesisStreams.Record(*data, partitionKey[, explicitHashKey][, prevSequenceNumber]*)

Creates and returns AWSKinesisStreams.Record object that can be written into an Amazon Kinesis stream using [AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) methods.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | blob or any JSON-compatible type | Yes | The record data |
| *partitionKey* | string | Yes | Determines which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-PartitionKey) |
| *explicitHashKey* | string | Optional | The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-ExplicitHashKey) |
| *prevSequenceNumber* | string | Optional | Guarantees strictly increasing sequence numbers, for puts from the same client and to the same partition key. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-SequenceNumberForOrdering) |

### Data Writing

[AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) class allows the agent to write data records to a specific AWS Kinesis stream. One instance of this class writes data to one stream. The stream's name as well as the region and the user identificators are specified in the class constructor. The class has two methods - to write one data record and to write an array of data records.

Auxiliary [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) class represents information from AWS Kinesis Streams about the written data record.

#### AWSKinesisStreams.Producer Class

Allows your code to write data records to a specific AWS Kinesis stream.

##### Constructor: AWSKinesisStreams.Producer(*region, accessKeyId, secretAccessKey, streamName*)

Creates and returns AWSKinesisStreams.Producer object.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *region* | string | Yes | The Region code of Amazon EC2. See [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) |
| *accessKeyId* | string | Yes | Access key ID of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html) |
| *secretAccessKey* | string | Yes | Secret access key of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html) |
| *streamName* | string | Yes | The name of Amazon Kinesis stream |

##### putRecord(*record[, callback]*)

Writes a single data record into the Amazon Kinesis stream.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *record* | [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | Yes | The record to be written |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds |
| *putRecordResult* | [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | The information from AWS Kinesis Streams about the written data record, or `null` if the operation fails |

##### putRecords(*records[, callback]*)

Writes multiple data records into the Amazon Kinesis stream in a single request. Every record is processed by Amazon Kinesis Streams individually. Some of the records may be written successfully but some may fail.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *records* | Array of [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | Yes | The records to be written |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds or partially succeeds |
| *failedRecordCount* | Integer | The number of unsuccessfully written records |
| *putRecordResults* | Array of [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | Array with the information from AWS Kinesis Streams about every processed data record, whether it is written successfully or not. Each record in the array directly correlates with a record in the *records* array using natural ordering, from the top to the bottom of the *records* and *putRecordResults*. If *error* is `null` then *putRecordResults* is empty, otherwise the *putRecordResults* array includes the same number of records as the *records* array. |

#### AWSKinesisStreams.PutRecordResult Class

Represents information from AWS Kinesis Streams about a written data record. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *errorCode* | String | The error code for the data record, or `null` if the record is written successfully. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorCode) |
| *errorMessage* | String | The error message for the data record, or `null` if the record is written successfully. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorMessage) |
| *shardId* | String | The ID of the shard where the data record has been written, or `null` if the record writing fails |
| *sequenceNumber* | String | The unique identifier of the record within its shard, or `null` if the record writing fails |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record, or `null` if the record writing fails |

#### Data Writing Example

**TBD**

### Data Reading

#### AWSKinesisStreams.Consumer Class

#### Data Reading Example

**TBD**

## Examples

Working examples are provided in the [Examples](./Examples) directory and described [here](./Examples/README.md).

## License

The Amazon Kinesis Streams library is licensed under the [MIT License](./LICENSE)
