# AWSKinesisStreams

This library lets your agent code to work with [Amazon Kinesis Streams](https://aws.amazon.com/kinesis/streams/). It makes use of the [Amazon Kinesis Streams REST API](http://docs.aws.amazon.com/kinesis/latest/APIReference/).

This version of the library supports the following functionality:

- writing data records into an Amazon Kinesis stream,
- getting data records from an Amazon Kinesis stream's shard.

AWSKinesisStreams library utilizes [AWSRequestV4](https://github.com/electricimp/AWSRequestV4/) library. **To add AWSKinesisStreams library to your project, add the following lines to the top of your agent code:**
```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.0.0"
```

## Prerequisites

Before using the library you need to have:

- *region* &mdash; **The Region code** of Amazon EC2. See [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
- *accessKeyId* &mdash; **Access key ID** of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html).
- *secretAccessKey* &mdash; **Secret access key** of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html).

Also, you need to understand all the main Amazon Kinesis Streams concepts and terms, like stream, shard, record, etc. and know a name of Amazon Kinesis stream which your application is going to work with.

## Library Usage

The library consists of two main and independent parts &mdash; [Data Writing](#data-writing) and [Data Reading](#data-reading). You can instantiate and use any of these parts in your agent code as required by your application. Also, the library includes [Common Components](#common-components) which are used by the both main parts.

### Common Components

#### Callbacks

All requests that are made to the Amazon Kinesis Streams library occur asynchronously. Every method that sends a request has a parameter which takes a callback function that will be called when the operation is completed, successfully or not. The callback's parameters are listed in the corresponding method documentation, but every callback has at least one parameter, *error*. If *error* is `null`, the operation has been executed successfully. Otherwise, *error* is an instance of the [AWSKinesisStreams.Error](#awskinesisstreamserror-class) class and contains the details of the error.

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

#### JSON-Compatible Type

A type of Squirrel data which can be encoded/decoded into/from JSON. For example: table, array, string, boolean, integer, float. See more details in the [http.jsonencode()](https://electricimp.com/docs/api/http/jsonencode/) and [http.jsondecode()](https://electricimp.com/docs/api/http/jsondecode/) method descriptions.

#### AWSKinesisStreams.Record Class

Represents an Amazon Kinesis Streams record: a combination of data attributes. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *data* | Blob or [JSON-compatible type](#json-compatible-type) | The record data. |
| *partitionKey* | String | Identifies which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-PartitionKey). |
| *sequenceNumber* | String | The unique identifier of the record within its shard. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-SequenceNumber). |
| *timestamp* | Integer | The approximate time that the record was inserted into the stream. In number of seconds since Unix epoch (midnight, 1 Jan 1970). |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record. |

##### Constructor: AWSKinesisStreams.Record(*data, partitionKey[, explicitHashKey][, prevSequenceNumber]*)

Creates and returns AWSKinesisStreams.Record object that can be written into an Amazon Kinesis stream using [AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) methods.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | Blob or [JSON-compatible type](#json-compatible-type) | Yes | The record data. |
| *partitionKey* | String | Yes | Specifies which shard in the stream the data record is assigned to. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-PartitionKey). |
| *explicitHashKey* | String | Optional | The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-ExplicitHashKey). |
| *prevSequenceNumber* | String | Optional | See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-SequenceNumberForOrdering). |

### Data Writing

[AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) class allows the agent to write data records to a specific AWS Kinesis stream. One instance of this class writes data to one stream. The stream's name as well as the region and the user identification are specified in the class constructor. The class has two methods - to write one data record and to write an array of data records.

Auxiliary [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) class represents information from AWS Kinesis Streams about the written data record.

#### AWSKinesisStreams.Producer Class

Allows your code to write data records to a specific AWS Kinesis stream.

##### Constructor: AWSKinesisStreams.Producer(*region, accessKeyId, secretAccessKey, streamName*)

Creates and returns AWSKinesisStreams.Producer object.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *region* | String | Yes | The Region code of Amazon EC2. See [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). |
| *accessKeyId* | String | Yes | Access key ID of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html). |
| *secretAccessKey* | String | Yes | Secret access key of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html). |
| *streamName* | String | Yes | The name of Amazon Kinesis stream. |

##### putRecord(*record[, callback]*)

Writes a single data record into the Amazon Kinesis stream. See the corresponding [Amazon Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *record* | [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | Yes | The record to be written. |
| *callback* | Function | Optional | Executed once the operation is completed. |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds. |
| *putRecordResult* | [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | The information from AWS Kinesis Streams about the written data record, or `null` if the operation fails. |

##### putRecords(*records[, callback]*)

Writes multiple data records into the Amazon Kinesis stream in a single request. Every record is processed by Amazon Kinesis Streams individually. Some of the records may be written successfully but some may fail. See the corresponding [Amazon Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *records* | Array of [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | Yes | The records to be written. |
| *callback* | Function | Optional | Executed once the operation is completed. |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds or partially succeeds. |
| *failedRecordCount* | Integer | The number of unsuccessfully written records. |
| *putRecordResults* | Array of [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | Array with the information from AWS Kinesis Streams about every processed data record, whether it is written successfully or not. Each record in the array directly correlates with a record in the *records* array using natural ordering, from the top to the bottom of the *records* and *putRecordResults*. If *error* is not `null` then *putRecordResults* is empty, otherwise the *putRecordResults* array includes the same number of records as the *records* array. |

#### AWSKinesisStreams.PutRecordResult Class

Represents information from AWS Kinesis Streams about a written data record. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *errorCode* | String | The error code for the data record, or `null` if the record is written successfully. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorCode). |
| *errorMessage* | String | The error message for the data record, or `null` if the record is written successfully. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorMessage). |
| *shardId* | String | The ID of the shard where the data record has been written, or `null` if the record writing fails. |
| *sequenceNumber* | String | The unique identifier of the record within its shard, or `null` if the record writing fails. |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record, or `null` if the record writing fails. |

#### Data Writing Example

```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.0.0"

// Substitute with real values
const AWS_KINESIS_REGION = "<YOUR_AWS_REGION>";
const AWS_KINESIS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>";
const AWS_KINESIS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>";

const AWS_KINESIS_STREAM_NAME = "<YOUR_KINESIS_STREAM_NAME>";

// Instantiation of AWS Kinesis Streams producer
producer <- AWSKinesisStreams.Producer(
    AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);

// Writes single data record
producer.putRecord(AWSKinesisStreams.Record("Hello!", "partitionKey"), function (error, putResult) {
    if (error) {
        server.error("Data writing failed: " + error.details);
    } else {
        // Record written successfully
    }
});

// Writes multiple records with different data structures
records <- [
    AWSKinesisStreams.Record("test", "partitionKey1"),
    AWSKinesisStreams.Record(12345, "partitionKey2"),
    AWSKinesisStreams.Record({ "temperature" : 21, "humidity" : 60 }, "partitionKey3")
];
producer.putRecords(records, function (error, failedRecordCount, putResults) {
    if (error) {
        server.error("Data writing failed: " + error.details);
    } else if (failedRecordCount > 0) {
        server.log("Data writing partially failed:");
        foreach (res in putResults) {
            if (res.errorCode) {
                server.log(format("%s: %s", res.errorCode, res.errorMessage));
            }
        }
    } else {
        // Records written successfully
    }
});
```

### Data Reading

[AWSKinesisStreams.Consumer](#awskinesisstreamsconsumer-class) class allows the agent to read data records from a specific AWS Kinesis stream. One instance of this class reads data from one stream. The stream's name as well as the region and the user identification are specified in the class constructor.

AWS Kinesis Streams do not provide a functionality to read data records just from a stream, but rather from the shards which exist in the stream. To use AWSKinesisStreams.Consumer class you need to well understand the concept of shards, see [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference).

AWSKinesisStreams.Consumer class has three methods.

*getShards()* method allows your code to get the list of IDs of all shards of the stream, including the closed shards. Note, the closed shards may still contain the records your application may need to read.

*getShardIterator()* method allows your code to specify a start position from which the reading should be started and obtain the corresponding shard iterator to initiate the reading process from the shard.

*getRecords()* method allows your code to read a portion of data records using the specified shard iterator and returns the next shard iterator which can be used to read the next portion of data records by calling *getRecords()* method the next time. Data reading is always going in the direction from older records to the latest.

Note, every shard iterator, returned by *getShardIterator()* or *getRecords()* method, expires five minutes after it is returned. Your application should call the next *getRecords()* method with the iterator before it expires, otherwise the call will fail and your code should obtain a new iterator using *getShardIterator()* method.

If your application needs to read all records from the stream it should read them from all the shards of the stream. The library allows to obtain shard iterators for different shards of the same stream and process the reading from the shards in parallel. The list of shards is changed when the shards are merged or split. The application may check the latest list of the shards by calling *getShards()* method periodically, but it should be enough to make this check only when *getRecords()* method returns `null` as *nextOptions* for any of the shards. Note, a shard ID never disappears from the list, only new IDs may appear.

Before creating an AWSKinesisStreams.Consumer instance your code should know which type of data it is going to receive - binary data (a Squirrel blob) or a [JSON-compatible type](#json-compatible-type) of data. This choice is specified in the AWSKinesisStreams.Consumer constructor and can not be changed after that. In a complex case your application can specify the data as a blob and parse it to a specific or custom type by itself.

#### AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE Enum

The shard iterator type. Determines how the shard iterator is used to start reading data records from the shard. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Streams-GetShardIterator-request-ShardIteratorType). Has the following values:
  - *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER* &mdash; Start reading from the position denoted by a specific record sequence number.
  - *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER* &mdash; Start reading right after the position denoted by a specific record sequence number.
  - *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP* &mdash; Start reading from the position denoted by a specific timestamp.
  - *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.TRIM_HORIZON* &mdash; Start reading at the last untrimmed record in the shard in the system, which is the oldest data record in the shard.
  - *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST* &mdash; Start reading just after the most recent record in the shard, so that you always read the most recent data in the shard. 

#### AWSKinesisStreams.Consumer Class

Allows your code to read data records from a specific Amazon Kinesis stream.

##### Constructor: AWSKinesisStreams.Consumer(*region, accessKeyId, secretAccessKey, streamName[, isBlob]*)

Creates and returns AWSKinesisStreams.Consumer object.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *region* | String | Yes | The Region code of Amazon EC2. See [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). |
| *accessKeyId* | String | Yes | Access key ID of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html). |
| *secretAccessKey* | String | Yes | Secret access key of an AWS IAM user. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html). |
| *streamName* | String | Yes | The name of Amazon Kinesis stream. |
| *isBlob* | Boolean | Optional | If `true`, the AWSKinesisStreams.Consumer object will consider every received data record as a Squirrel blob. If `false` or not specified, the AWSKinesisStreams.Consumer object will consider every received data record as a JSON data and parse it into appropriate [JSON-compatible type](#json-compatible-type). |

##### getShards(*callback*)

Get the list of IDs of all shards of the Amazon Kinesis stream, including the closed shards.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | Executed once the operation is completed. |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds. |
| *shardIds* | Array of strings | The IDs of the stream's shards. The array is empty if the operation fails. |

##### getShardIterator(*shardId, type, typeOptions, callback*)

Get the Amazon Kinesis stream's shard iterator which corresponds to the specified start position for the reading. See the corresponding [Amazon Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *shardId* | String | Yes | The shard ID. |
| *type* | [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE](#aws_kinesis_streams_shard_iterator_type-enum) | Yes | The shard iterator type. Determines how the shard iterator is used to start reading data records from the shard. Some of the types require the corresponding *typeOptions* to be specified. |
| *typeOptions* | Table | Yes | Additional options required for some of the shard iterator types specified by the *type* parameter. Pass `null` if the additional options are not required for the specified iterator type. Key-value table, see below. |
| *callback* | Function | Yes | Executed once the operation is completed. |

| *typeOptions* key | Data Type | Description |
| --- | --- | --- |
| *startingSequenceNumber* | String | The sequence number of the data record in the shard from which to start reading. Must be specified if the *type* parameter is [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER](#aws_kinesis_streams_shard_iterator_type-enum) or [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER](#aws_kinesis_streams_shard_iterator_type-enum). |
| *timestamp* | Integer | The timestamp of the data record from which to start reading. In number of seconds since Unix epoch (midnight, 1 Jan 1970). Must be specified if the *type* parameter is [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP](#aws_kinesis_streams_shard_iterator_type-enum). See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Streams-GetShardIterator-request-Timestamp) for the behavior details. |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds. |
| *shardIterator* | String | The shard iterator, or `null` if the operation fails. |

##### getRecords(*options, callback*)

Reads data records from the Amazon Kinesis stream's shard using the specified shard iterator. See the corresponding [Amazon Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table | Yes | Options for the operation. Key-value table, see below. |
| *callback* | Function | Yes | Executed once the operation is completed. |

| *options* key | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *shardIterator* | String | Yes | The shard iterator that specifies the position in the shard from which the reading should be started. |
| *limit* | Integer | Optional | The maximum number of data records to read. If not specified, the number of returned records is Amazon Kinesis Streams specific. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-request-Limit). |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds. |
| *records* | Array of [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | The data records retrieved from the shard. The array is empty if the operation fails or there are no new records in the shard for the specified shard iterator. |
| *millisBehindLatest* | Integer | The number of milliseconds the response is from the tip of the stream. Zero if there are no new records in the shard for the specified shard iterator. See [Amazon Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-response-MillisBehindLatest). |
| *nextOptions* | Table | Options which can be used as the *options* parameter in the next *getRecords()* call. Key-value table, identical to the *options* table, see below. *nextOptions* is `null` if the operation fails or the shard has been closed and the specified shard iterator has reached the last record in the shard and will not return any more data. |

| *nextOptions* key | Data Type | Description |
| --- | --- | --- |
| *shardIterator* | String | The new shard iterator returned by Amazon Kinesis Streams. Can be used as the shard iterator in the next *getRecords()* call. |
| *limit* | Integer | The maximum number of data records to read. The same value as in the *options* table. Is missed if was missed in the *options* table. |

#### Data Reading Example

```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.0.0"

// Substitute with real values
const AWS_KINESIS_REGION = "<YOUR_AWS_REGION>";
const AWS_KINESIS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>";
const AWS_KINESIS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>";

const AWS_KINESIS_STREAM_NAME = "<YOUR_KINESIS_STREAM_NAME>";

// Instantiation of AWS Kinesis Streams consumer
consumer <- AWSKinesisStreams.Consumer(
    AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);

// Obtains the stream shards
consumer.getShards(function (error, shardIds) {
    if (error) {
        server.error("getShards failed: " + error.details);
    } else {
        foreach (shardId in shardIds) {
            getShardIterator(shardId);
        }
    }
});

// Obtains shard iterator for the specified shard and starts reading records
function getShardIterator(shardId) {
    consumer.getShardIterator(
        shardId,
        AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.TRIM_HORIZON,
        null,
        function (error, shardIterator) {
            if (error) {
                server.error("getShardIterator failed: " + error.details);
            } else {
                // shard iterator obtained successfully
                readRecords({ "shardIterator" : shardIterator, "limit" : 10 });
            }
        });
}

// Recursively reads records from the specified shard
function readRecords(options) {
    consumer.getRecords(
        options,
        function (error, records, millisBehindLatest, nextOptions) {
            if (error) {
                server.error("Data reading failed: " + error.details);
            } else {
                if (records.len() == 0) {
                    // No new records
                } else {
                    foreach (record in records) {
                        // Process records individually
                    }
                }

                if (nextOptions) {
                    // Read next portion of records
                    imp.wakeup(10.0, function () {
                        readRecords(nextOptions);
                    });
                }
            }
        });
}
```

## Examples

Working examples are provided in the [Examples](./Examples) directory and described [here](./Examples/README.md).

## License

The Amazon Kinesis Streams library is licensed under the [MIT License](./LICENSE)
