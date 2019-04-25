# AWSKinesisStreams #

This library allows your agent code to work with [Amazon Web Services’ Kinesis Streams](https://aws.amazon.com/kinesis/streams/). It makes use of the [Kinesis Streams REST API](http://docs.aws.amazon.com/kinesis/latest/APIReference/).

This version of the library supports the following functionality:

- Writing data records into an Amazon Kinesis stream.
- Getting data records from an Amazon Kinesis stream’s shard.

The AWSKinesisStreams library utilizes the [AWSRequestV4](https://github.com/electricimp/AWSRequestV4/) library.

**To add this library to your project, add the following lines to the top of your agent code:**

```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.1.0"
```

## Example ## 

A complete, step-by-step recipe can be found in the [Examples](./Examples) folder.

## Library Usage ##

The library consists of two essentially independent parts for, respectively, [reading](#reading-data) and [writing](#writing-data) data. You can instantiate and use any of these parts in your agent code as required by your application.  The library includes some [common components](#common-components) which are used by the both of the main parts.

### Prerequisites ###

Before using the library you need to have:

- The Region Code of Amazon EC2 (see the  [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)).
- The Access Key ID of an AWS IAM user (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)).
- The Secret Access Key of an AWS IAM user (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)).

You also need to understand all the main Amazon Kinesis Streams concepts and terms, like stream, shard, record, etc., and the name of the Kinesis stream which your application is going to work with.

### Callbacks ###

All requests that are made to the AWSKinesisStreams library occur asynchronously. Every method that sends a request has a parameter which takes a callback function that will be called when the operation is completed, whether successfully or not. The callback’s parameters are listed in the corresponding method documentation, but every callback has at least one parameter, *error*. If *error* is `null`, the operation has been executed successfully. Otherwise, *error* is an instance of the [AWSKinesisStreams.Error](#awskinesisstreamserror-class) class and contains the details of the error.

# Common Components #

## AWSKinesisStreams.Error Class ##

This class represents an error returned by the library. As such it will be generated for you. It has the following public properties:

- *type* &mdash; The error type, which is one of the following *AWS_KINESIS_STREAMS_ERROR* enum values:
    - *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR* &mdash; The library is wrongly initialized, or a method is called with invalid argument(s), or an internal error. The error details can be found in the *details* property. Usually it indicates an issue during an application development which should be fixed during debugging and therefore should not occur after the application has been deployed.
    - *AWS_KINESIS_STREAMS_ERROR.REQUEST_FAILED* &mdash; HTTP request to Amazon Kinesis Streams fails. The error details can be found in the *details*, *httpStatus* and *httpResponse* properties. This error may occur during the normal execution of an application. The application logic should process this error.
    - *AWS_KINESIS_STREAMS_ERROR.UNEXPECTED_RESPONSE* &mdash; An unexpected response from Amazon Kinesis Streams. The error details can be found in the *details* and *httpResponse* properties.
- *details* &mdash; A string with human readable details of the error.
- *httpStatus* &mdash; An integer indicating the HTTP status code, or `null` if *type* is *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR*.
- *httpResponse* &mdash; A table of key-value strings holding the response body of the failed request, or `null` if *type* is *AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR*.

## AWSKinesisStreams Class ##

This is the parent class for [AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class-usage) and [AWSKinesisStreams.Consumer](#awskinesisstreamsconsumer-class-usage). You will not work with this class but with instances of its child classes, all of which respond to the following method:

### setDebug(*value*) ###

This method enables (*value* is `true`) or disables (*value* is `false`) the library debug output (including error logging). It is disabled by default. The method returns nothing.

## AWSKinesisStreams.Record Class ##

This class represents an AWS Kinesis Streams record: a combination of data attributes. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *data* | Blob or [JSON-compatible type](#json-compatible-type) | The record data |
| *partitionKey* | String | Identifies which shard in the stream the data record is assigned to (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-PartitionKey)) |
| *sequenceNumber* | String | The unique identifier of the record within its shard (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-SequenceNumber)) |
| *timestamp* | Integer | The approximate time that the record was inserted into the stream. In number of seconds since Unix epoch (midnight, 1 Jan 1970) |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record |

### Constructor: AWSKinesisStreams.Record(*data, partitionKey[, explicitHashKey][, prevSequenceNumber][, encoder]*) ###

This method creates and returns an AWSKinesisStreams.Record object that can be written into an Amazon Kinesis stream using [AWSKinesisStreams.Producer](#awskinesisstreamsproducer-class) methods.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *data* | Blob or [JSON-compatible type](#json-compatible-type) | Yes | The record data |
| *partitionKey* | String | Yes | Identifies which shard in the stream the data record is assigned to (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-PartitionKey)) |
| *explicitHashKey* | String | No | The hash value used to explicitly determine the shard the data record is assigned to by overriding the partition key hash (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-ExplicitHashKey)) |
| *prevSequenceNumber* | String | No | See the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-SequenceNumberForOrdering) |
| *encoder* | Function | No | A custom JSON encoder function for encoding the provided data (eg. [*JSONEncoder.encode()*](https://github.com/electricimp/JSONEncoder)) |

## AWS_KINESIS_STREAMS_ENCRYPTION_TYPE Enum ##

The encryption type used on a record. It has the following values:

- *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE* &mdash; Record is not encrypted.
- *AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.KMS* &mdash; Record is encrypted on server side using a customer-managed KMS key.

For more information, please see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-EncryptionType).

# Writing Data #

## AWSKinesisStreams.Producer Class Usage ##

This class allows the agent to write data records to a specific AWS Kinesis stream. One instance of this class writes data to one stream. The stream’s name as well as the region and the user identification are specified in the class constructor.

### Constructor: AWSKinesisStreams.Producer(*region, accessKeyId, secretAccessKey, streamName*) ###

Creates and returns an AWSKinesisStreams.Producer object. The constructor’s parameters are as follows:

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *region* | String | Yes | The Region code of Amazon EC2 (see the [Amazon EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).) |
| *accessKeyId* | String | Yes | The access key ID of an AWS IAM user. See the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)) |
| *secretAccessKey* | String | Yes | The secret access key of an AWS IAM user (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)) |
| *streamName* | String | Yes | The name of the Amazon Kinesis stream |

## AWSKinesisStreams.Producer Class Methods ##

### putRecord(*record[, callback]*) ###

This method writes a single data record into the AWS Kinesis stream. For more information, please see the corresponding [Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html).

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *record* | [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | Yes | The record to be written |
| *callback* | Function | No | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeded |
| *putRecordResult* | [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | The information from AWS Kinesis Streams about the written data record, or `null` if the operation failed |

### putRecords(*records[, callback]*) ###

This method writes multiple data records into the AWS Kinesis stream in a single request. Every record is processed by AWS individually. Some of the records may be written successfully but some may fail. For more information, please see the corresponding [Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html).

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *records* | Array of [AWSKinesisStreams.Records](#awskinesisstreamsrecord-class) | Yes | The records to be written |
| *callback* | Function | No | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeds or partially succeeds |
| *failedRecordCount* | Integer | The number of unsuccessfully written records |
| *putRecordResults* | Array of [AWSKinesisStreams.PutRecordResult](#awskinesisstreamsputrecordresult-class) | Array with the information from AWS Kinesis Streams about every processed data record, whether it is written successfully or not. Each record in the array directly correlates with a record in the *records* array using natural ordering, from the top to the bottom of the *records* and *putRecordResults*. If *error* is not `null` then *putRecordResults* is empty, otherwise the *putRecordResults* array includes the same number of records as the *records* array |

## AWSKinesisStreams.PutRecordResult Class ##

This class represents information from AWS Kinesis Streams about a written data record. It has the following public properties:

| Property | Data Type | Description |
| --- | --- | --- |
| *errorCode* | String | The error code for the data record, or `null` if the record is written successfully (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorCode)) |
| *errorMessage* | String | The error message for the data record, or `null` if the record is written successfully (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorMessage)) |
| *shardId* | String | The ID of the shard where the data record has been written, or `null` if the write failed |
| *sequenceNumber* | String | The unique identifier of the record within its shard, or `null` if the write failed |
| *encryptionType* | [AWS_KINESIS_STREAMS_ENCRYPTION_TYPE](#aws_kinesis_streams_encryption_type-enum) | The encryption type used on the record, or `null` if the write failed |

# Reading Data #

## AWSKinesisStreams.Consumer Class Usage ##

This class allows your code to read data records from a specific AWS Kinesis Stream.

### Constructor: AWSKinesisStreams.Consumer(*region, accessKeyId, secretAccessKey, streamName[, isBlob]*) ###

This method creates and returns an AWSKinesisStreams.Consumer object. The constructor’s parameters are as follows:

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *region* | String | Yes | The Region code of Amazon EC2 (see the [EC2 documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)) |
| *accessKeyId* | String | Yes | The access key ID of an AWS IAM user (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)) |
| *secretAccessKey* | String | Yes | The secret access key of an AWS IAM user (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html)) |
| *streamName* | String | Yes | The name of an AWS Kinesis stream |
| *isBlob* | Boolean | No | If `true`, the AWSKinesisStreams.Consumer object will consider every received data record as a Squirrel blob. If `false` or not specified, the AWSKinesisStreams.Consumer object will consider every received data record as a JSON data and parse it into an appropriate [JSON-compatible type](#json-compatible-type) |

Before creating an AWSKinesisStreams.Consumer instance your code should know which type of data it is going to receive: binary data (a Squirrel blob) or a [JSON-compatible type](#json-compatible-type). This choice is specified in the AWSKinesisStreams.Consumer constructor and cannot be changed after that. In a complex case, your application can specify the data as a blob and parse it to a specific or custom type by itself.

## AWSKinesisStreams.Consumer Class Methods ##

### getShards(*callback*) ###

This method retrieves a list of the IDs of all the shards in the AWS Kinesis stream, including closed shards. Closed shards may still contain records your application may need to read.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeded |
| *shardIds* | Array of strings | The IDs of the stream’s shards. The array is empty if the operation failed |

### getShardIterator(*shardId, type, typeOptions, callback*) ###

This method allows your code to specify a start position from which the reading should be started and to obtain the corresponding shard iterator to initiate the reading process from the shard. For more information, please see the corresponding [Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html).

**Note** Every shard iterator returned by *getShardIterator()* or *getRecords()* expires five minutes after it is returned. Your application should call *getRecords()* with the iterator before it expires, otherwise the call will fail and your code will need to obtain a new iterator using *getShardIterator()*.

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *shardId* | String | Yes | The shard ID. |
| *type* | [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE](#aws_kinesis_streams_shard_iterator_type-enum) | Yes | The shard iterator type. Determines how the shard iterator is used to start reading data records from the shard. Some of the types require the corresponding *typeOptions* to be specified |
| *typeOptions* | Table | Yes | Additional options required for some of the shard iterator types specified by the *type* parameter (see below). Pass `null` if the additional options are not required for the specified iterator type |
| *callback* | Function | Yes | Executed once the operation is completed |

| *typeOptions* Key | Data Type | Description |
| --- | --- | --- |
| *startingSequenceNumber* | String | The sequence number of the data record in the shard from which to start reading. Must be specified if the *type* parameter is [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER](#aws_kinesis_streams_shard_iterator_type-enum) or [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER](#aws_kinesis_streams_shard_iterator_type-enum) |
| *timestamp* | Integer | The timestamp of the data record from which to start reading. In number of seconds since Unix epoch (midnight, 1 Jan 1970). Must be specified if the *type* parameter is [AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP](#aws_kinesis_streams_shard_iterator_type-enum) (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Streams-GetShardIterator-request-Timestamp) for the behavior details) |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeded |
| *shardIterator* | String | The shard iterator, or `null` if the operation failed |

### getRecords(*options, callback*) ###

This method allows your code to read a portion of data records using the specified shard iterator and returns the next shard iterator which can be used to read the next portion of data records by calling *getRecords()* again. Reading is always going to prefer older records over the latest. For more information, please see the corresponding [Kinesis Streams REST API action](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html).

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *options* | Table | Yes | Options for the operation (see below) |
| *callback* | Function | Yes | Executed once the operation is completed |

| *options* key | Data Type | Required | Description |
| --- | --- | --- | --- |
| *shardIterator* | String | Yes | The shard iterator that specifies the position in the shard from which the reading should be started |
| *limit* | Integer | Optional | The maximum number of data records to read. If not specified, the number of returned records is AWS Kinesis Streams specific (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-request-Limit)) |

The method returns nothing. The result of the operation may be obtained via the *callback* function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | [AWSKinesisStreams.Error](#awskinesisstreamserror-class) | Error details, or `null` if the operation succeeded |
| *records* | Array of [AWSKinesisStreams.Record](#awskinesisstreamsrecord-class) | The data records retrieved from the shard. The array is empty if the operation failed or there are no new records in the shard for the specified shard iterator |
| *millisBehindLatest* | Integer | The number of milliseconds the response is from the tip of the stream. Zero if there are no new records in the shard for the specified shard iterator (see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-response-MillisBehindLatest)) |
| *nextOptions* | Table | Options which can be used as the *options* parameter in the next *getRecords()* call. *nextOptions* is `null` if the operation failed, or the shard has been closed and the specified shard iterator has reached the last record in the shard and will not return any more data |

| *nextOptions* key | Data Type | Description |
| --- | --- | --- |
| *shardIterator* | String | The new shard iterator returned by AWS Kinesis Streams. Can be used as the shard iterator in the next *getRecords()* call |
| *limit* | Integer | The maximum number of data records to read. The same value as in the *options* table. Will not be present if it was not included in the *options* table |

If your application needs to read all records from the stream it should read them from all the shards in the stream. The library allows you to obtain shard iterators for different shards of the same stream and process the reading from the shards in parallel. The list of shards is changed when the shards are merged or split. The application can get the latest list of shards by calling *getShards()* periodically, but it should be sufficient to make this check only when *getRecords()* returns a *nextOptions* of `null` for any shard. A shard ID never disappears from the list, but new IDs may appear.

**Note** Every shard iterator returned by *getShardIterator()* or *getRecords()* expires five minutes after it is returned. Your application should call *getRecords()* with the iterator before it expires, otherwise the call will fail and your code will need to obtain a new iterator using *getShardIterator()*.

## AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE Enum ##

The shard iterator type. It determines how the shard iterator is used to start reading data records from the shard. It has the following values:

- *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER* &mdash; Start reading from the position denoted by a specific record sequence number.
- *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER* &mdash; Start reading right after the position denoted by a specific record sequence number.
- *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP* &mdash; Start reading from the position denoted by a specific timestamp.
- *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.TRIM_HORIZON* &mdash; Start reading at the last untrimmed record in the shard in the system, which is the oldest data record in the shard.
- *AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST* &mdash; Start reading just after the most recent record in the shard, so that you always read the most recent data in the shard.

For more information, please see the [Kinesis Streams documentation](http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Streams-GetShardIterator-request-ShardIteratorType).

### JSON-Compatible Type ###

A type of Squirrel data which can be encoded/decoded into/from JSON, eg. table, array, string, boolean, integer, float. For more details, please see the [**http.jsonencode()**](https://developer.electricimp.com/api/http/jsonencode/) and [**http.jsondecode()**](https://developer.electricimp.com/api/http/jsondecode/) method descriptions.

## Examples ##

### Writing Data ###

```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.1.0"
#require "JSONEncoder.class.nut:2.0.0"

// This class can be used to hold numbers larger than Squirrel can natively support (ie. anything larger than 32-bit)
// and then be encoded as a number (rather than a string) when encoded with 'JSONEncoder.encode()'.
class JSONLiteralString {
  _string = null;

  constructor (string) {
    _string = string.tostring();
  }

  function _serializeRaw() {
    return _string;
  }

  function toString() {
    return _string;
  }
}

// Substitute with real values
const AWS_KINESIS_REGION = "<YOUR_AWS_REGION>";
const AWS_KINESIS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>";
const AWS_KINESIS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>";
const AWS_KINESIS_STREAM_NAME = "<YOUR_KINESIS_STREAM_NAME>";

// Instantiation of AWS Kinesis Streams producer
producer <- AWSKinesisStreams.Producer(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);

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
  AWSKinesisStreams.Record({ "temperature" : 21, "humidity" : 60 }, "partitionKey3"),
  
  // Write record using custom encoder
  AWSKinesisStreams.Record({ "a" : JSONLiteralString("123456789123456789") }, "partitionKey4", null, null, JSONEncoder.encode.bindenv(JSONEncoder)) 
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

### Reading Data ###

```squirrel
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.1.0"

// Substitute with real values
const AWS_KINESIS_REGION = "<YOUR_AWS_REGION>";
const AWS_KINESIS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>";
const AWS_KINESIS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>";
const AWS_KINESIS_STREAM_NAME = "<YOUR_KINESIS_STREAM_NAME>";

// Instantiation of AWS Kinesis Streams consumer
consumer <- AWSKinesisStreams.Consumer(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);

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
    }
  );
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
    }
  );
}
```

Working examples are also provided in the [Examples](./Examples) directory and described [here](./Examples/README.md).

## License ##

This library is licensed under the [MIT License](./LICENSE).
