# AWSKinesisStreams

This library lets your agent code to work with [Amazon Kinesis Streams](https://aws.amazon.com/kinesis/streams/). It makes use of the [Amazon Kinesis Streams REST API](http://docs.aws.amazon.com/kinesis/latest/APIReference/).

This version of the library supports the following functionality:

- writing data records into an Amazon Kinesis stream
- getting data records from an Amazon Kinesis stream's shard

**To add this library to your project, add** `#require "AWSKinesisStreams.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## Prerequisites

Before using the library you need to have:

- *region* &mdash; **TBD**
- *accessKeyId* &mdash; **TBD**
- *secretAccessKey* &mdash; **TBD**

Also, you need to understand all the main Amazon Kinesis Streams concepts and terms, like stream, shard, record, etc.

## Library Usage

The library consists of two main and independent parts &mdash; [Data Writing](#data-wariting) and [Data Getting](#data-getting). You can instantiate and use any of these parts in your agent code as required by your application. Also, the library includes [Common Components](#common-components) which are used by the both main parts.

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

#### AWSKinesisStreams.Record Class

Represents an Amazon Kinesis Streams record: a combination of data attributes. It has the following public properties:

- *data* &mdash; The record data (blob or any JSON-compatible type).
- *partitionKey* &mdash; Identifies which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-PartitionKey).
- *sequenceNumber* &mdash; The unique identifier of the record within its shard. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-SequenceNumber).
- *timestamp* &mdash; The approximate time that the record was inserted into the stream. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-ApproximateArrivalTimestamp).
- *encryptionType* &mdash; The encryption type used on the record. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-EncryptionType). This property can be one of the following values:
  - *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE* &mdash; Record is not encrypted.
  - *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.KMS* &mdash; Record is encrypted on server side using a customer-managed KMS key.

##### Constructor: AWSKinesisStreams.Record(*data, partitionKey[, explicitHashKey][, prevSequenceNumber]*)

Creates and returns AWSKinesisStreams.Record object that can be written into an Amazon Kinesis stream using [AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) methods.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | blob or any JSON-compatible type | Yes | The record data |
| *partitionKey* | string | Yes | Determines which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-PartitionKey) |
| *explicitHashKey* | string | Optional | The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-ExplicitHashKey) |
| *prevSequenceNumber* | string | Optional | Guarantees strictly increasing sequence numbers, for puts from the same client and to the same partition key. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-SequenceNumberForOrdering) |

### Data Writing

#### AWSKinesisStreams.Producer Class

*streamName* - a name of Amazon Kinesis stream - unique across all streams in one AWS account in one region

#### AWSKinesisStreams.PutRecordResult Class

### Data Getting

#### AWSKinesisStreams.Consumer Class

## Examples

Working examples are provided in the [Examples](./Examples) directory and described [here](./Examples/README.md).

## License

The Amazon Kinesis Streams library is licensed under the [MIT License](./LICENSE)
