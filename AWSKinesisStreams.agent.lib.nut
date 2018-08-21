// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// This library lets your agent code to work with Amazon Kinesis Streams (https://aws.amazon.com/kinesis/streams/).
// It makes use of the Amazon Kinesis Streams REST API (http://docs.aws.amazon.com/kinesis/latest/APIReference/).
// The current version of the library supports the following functionality:
// - writing data records into an Amazon Kinesis stream
// - getting data records from an Amazon Kinesis stream's shard

// AWSKinesisStreams library operation error types
enum AWS_KINESIS_STREAMS_ERROR {
    // the library detects an error, e.g. the library is wrongly initialized or
    // a method is called with invalid argument(s). The error details can be
    // found in the error.details value
    LIBRARY_ERROR,
    // HTTP request to Amazon Kinesis Streams service failed. The error details can be found in
    // the error.httpStatus and error.httpResponse properties
    REQUEST_FAILED,
    // Unexpected response from Amazon Kinesis Streams  service. The error details can be found in
    // the error.details and error.httpResponse properties
    UNEXPECTED_RESPONSE
};

// Error details produced by the library
const AWS_KINESIS_STREAMS_REQUEST_FAILED = "AWS Kinesis request failed with status code";
const AWS_KINESIS_STREAMS_NON_EMPTY_ARG = "Non empty argument required";
const AWS_KINESIS_STREAMS_WRONG_ARG_TYPE = "Wrong type of argument";
const AWS_KINESIS_STREAMS_AWS_REQUEST_REQUIRED = "AWSRequestV4 library required";

// Internal library constants
const _AWS_KINESIS_STREAMS_SERVICE = "kinesis";
const _AWS_KINESIS_STREAMS_TARGET_PREFIX = "Kinesis_20131202";

class AWSKinesisStreams {
    static VERSION = "1.1.0";

    // Enables/disables the library debug output (including errors logging).
    // Disabled by default.
    //
    // Parameters:
    //     value : boolean             true to enable, false to disable
    function setDebug(value) {
        _utils._debug = value;
    }

    // Internal utility methods used by different parts of the library
    static _utils = {
        _debug = false,

        // Logs an error occurred during the library methods execution
        function _logError(message) {
            if (_debug) {
                server.error("[AWSKinesisStreams] " + message);
            }
        }

        // Logs an debug messages occurred during the library methods execution
        function _logDebug(message) {
            if (_debug) {
                server.log("[AWSKinesisStreams] " + message);
            }
        }

        function _getHeaders(methodName) {
            return {
                "X-Amz-Target" : format("%s.%s", _AWS_KINESIS_STREAMS_TARGET_PREFIX, methodName),
                "Content-Type" : "application/x-amz-json-1.1"
            };
        }

        function _processResponse(response, callback) {
            _logDebug(format("Response status: %d, body: %s", response.statuscode, response.body));
            local errType = null;
            local errDetails = null;
            local httpStatus = response.statuscode;
            if (httpStatus < 200 || httpStatus >= 300) {
                errType = AWS_KINESIS_STREAMS_ERROR.REQUEST_FAILED;
                errDetails = format("%s: %i", AWS_KINESIS_STREAMS_REQUEST_FAILED, httpStatus);
            }
            try {
                response.body = (response.body == "") ? {} : http.jsondecode(response.body);
            } catch (e) {
                if (!errType) {
                    errType = AWS_KINESIS_STREAMS_ERROR.UNEXPECTED_RESPONSE;
                    errDetails = e;
                }
            }
            
            local error = errType ? AWSKinesisStreams.Error(errType, errDetails, httpStatus, response.body) : null;
            imp.wakeup(0, function () {
                callback(error, response.body);
            });
        }

        function _processRequest(awsRequest, methodName, body, callback) {
            _logDebug(format("Doing the POST request to '%s' target, body: %s", methodName, http.jsonencode(body)));
            awsRequest.post(
                "/",
                AWSKinesisStreams._utils._getHeaders(methodName),
                http.jsonencode(body),
                function (response) {
                    AWSKinesisStreams._utils._processResponse(response, callback);
                }.bindenv(this));
        }

        function _getEncryptionType(encryptionTypeName) {
            switch (encryptionTypeName) {
                case "NONE":
                    return AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE;
                case "KMS":
                    return AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.KMS;
                default:
                    return null;
            }
        }

        // Validates the argument is not empty. Returns PUB_SUB_ERROR.LIBRARY_ERROR if the check failed.
        function _validateNonEmpty(param, paramName, isResponse = false, response = null) {
            if (param == null || typeof param == "string" && param.len() == 0) {
                local errDetails = format("%s: %s", AWS_KINESIS_STREAMS_NON_EMPTY_ARG, paramName);
                if (isResponse) {
                    return AWSKinesisStreams.Error(
                        AWS_KINESIS_STREAMS_ERROR.UNEXPECTED_RESPONSE,
                        errDetails,
                        null,
                        response);
                } else {
                    return AWSKinesisStreams.Error(
                        AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR,
                        errDetails);
                }
            }
            return null;
        }

        function _validateRecordType(record, paramName, isMultiple) {
            if (!(!isMultiple && record instanceof AWSKinesisStreams.Record || 
                  isMultiple && typeof record == "array")) {
                return AWSKinesisStreams.Error(
                    AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR,
                    format("%s: %s", AWS_KINESIS_STREAMS_WRONG_ARG_TYPE, paramName));
            }
            if (isMultiple) {
                local error = null;
                if (record.len() == 0) {
                    error = AWSKinesisStreams.Error(
                        AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR,
                        format("%s: %s", AWS_KINESIS_STREAMS_NON_EMPTY_ARG, paramName));
                }
                if (!error) {
                    foreach (rec in record) {
                        error = error || _validateRecordType(rec, paramName, false);
                    }
                }
                return error;
            }
            return null;
        }

        function _getInitError(region, accessKeyId, secretAccessKey, streamName) {
            local error = null;
            if (!("AWSRequestV4" in getroottable())) {
                error = AWSKinesisStreams.Error(
                    AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR,
                    AWS_KINESIS_STREAMS_AWS_REQUEST_REQUIRED);
            }
            error = error || 
                AWSKinesisStreams._utils._validateNonEmpty(region, "region") ||
                AWSKinesisStreams._utils._validateNonEmpty(accessKeyId, "accessKeyId") ||
                AWSKinesisStreams._utils._validateNonEmpty(secretAccessKey, "secretAccessKey") ||
                AWSKinesisStreams._utils._validateNonEmpty(streamName, "streamName");
            return error;
        }

        // Returns value of specified table key, if exists or defaultValue
        function _getTableValue(table, key, defaultValue) {
            return (table && key in table) ? table[key] : defaultValue;
        }
    };
}

// Auxiliary class, represents error returned by the library.
class AWSKinesisStreams.Error {
    // error type, one of the AWS_KINESIS_STREAMS_ERROR enum values
    type = null;

    // human readable details of the error (string)
    details = null;

    // HTTP status code (integer),
    // null if type is AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR
    httpStatus = null;

    // Response body of the failed request (table),
    // null if type is AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR
    httpResponse = null;

    constructor(type, details, httpStatus = null, httpResponse = null) {
        this.type = type;
        this.details = details;
        this.httpStatus = httpStatus;
        this.httpResponse = httpResponse;

        AWSKinesisStreams._utils._logError(details);
    }
}

// This class allows to write data records to a specific AWS Kinesis stream.
// One instance of this class writes data to one stream.
class AWSKinesisStreams.Producer {
    _awsRequest = null;
    _streamName = null;
    _initError = null;

    // AWSKinesisStreams.Producer constructor.
    //
    // Parameters:
    //     region : string             The Region code of Amazon EC2.
    //                                 See http://docs.aws.amazon.com/AWSEC2/latest/
    //     accessKeyId : string        Access key ID of an AWS IAM user.
    //                                 See http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html
    //     secretAccessKey : string    Secret access key of an AWS IAM user.
    //                                 See http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html
    //     streamName : string         The name of Amazon Kinesis stream.
    //
    // Returns:                        AWSKinesisStreams.Producer instance created
    constructor(region, accessKeyId, secretAccessKey, streamName) {
        _initError = AWSKinesisStreams._utils._getInitError(
            region, accessKeyId, secretAccessKey, streamName);
        if (!_initError) {
            _awsRequest = AWSRequestV4(_AWS_KINESIS_STREAMS_SERVICE, region, accessKeyId, secretAccessKey);
            _streamName = streamName;
        }
    }

    // Writes a single data record into the Amazon Kinesis stream.
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html
    //
    // Parameters:
    //   record :                      The record to be written.
    //     AWSKinesisStreams.Record
    //   callback : function           Optional callback function to be executed once the operation
    //     (optional)                  is completed.
    //                                 The callback signature:
    //                                 callback(error, putRecordResult), where
    //                                   error :                    Error details,
    //                                     AWSKinesisStreams.Error  null if the operation succeeds.
    //                                   putRecordResult :
    //                                     AWSKinesisStreams.PutRecordResult
    //                                                              The information from AWS Kinesis Streams
    //                                                              about the written data record,
    //                                                              or null if the operation fails
    //
    // Returns:                        Nothing
    function putRecord(record, callback = null) {
        local error = _initError ||
            AWSKinesisStreams._utils._validateRecordType(record, "record", false);
        local body;
        if (!error) {
            body = record._toJson(false);
            error = record._getError();
        }
        if (error) {
            _invokePutCallback(callback, error, false);
            return;
        }

        body.StreamName <- _streamName;
        AWSKinesisStreams._utils._processRequest(_awsRequest, "PutRecord", body, function (error, response) {
            local putRecordResult = null;
            if (!error) {
                putRecordResult = AWSKinesisStreams.PutRecordResult();
                putRecordResult._fromJson(response);
                error = putRecordResult._getError();
            }
            _invokePutCallback(callback, error, false, putRecordResult);
        }.bindenv(this));
    }

    // Writes multiple data records into the Amazon Kinesis stream in a single request.
    // Every record is processed by Amazon Kinesis Streams individually.
    // Some of the records may be written successfully but some may fail.
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html
    //
    // Parameters:
    //   records : array of            The records to be written.
    //     AWSKinesisStreams.Record
    //   callback : function           Optional callback function to be executed once the operation
    //     (optional)                  is completed.
    //                                 The callback signature:
    //                                 callback(error, failedRecordCount, putRecordResults), where
    //                                   error :                    Error details,
    //                                     AWSKinesisStreams.Error  null if the operation succeeds.
    //                                   failedRecordCount :        The number of unsuccessfully
    //                                     integer                  written records.
    //                                   putRecordResults : array of   
    //                                     AWSKinesisStreams.PutRecordResult
    //                                                              Array with the information from
    //                                                              AWS Kinesis Streams about every
    //                                                              processed data record, whether
    //                                                              it is written successfully or not.
    //                                                              Has the same order as records array.
    //                                                              Empty array if the operation fails.
    //
    // Returns:                        Nothing
    function putRecords(records, callback = null) {
        local error = _initError ||
            AWSKinesisStreams._utils._validateRecordType(records, "records", true);
        local recordCount = (typeof records == "array") ? records.len() : 0;
        local body = null;
        if (!error) {
            body = {
                "Records" : records.map(function (record) {
                    local jsonRecord = record._toJson(true);
                    error = error || record._getError();
                    return jsonRecord;
                }.bindenv(this)),
                "StreamName" : _streamName
            };
        }
        if (error) {
            _invokePutCallback(callback, error, true, null, recordCount);
            return;
        }

        AWSKinesisStreams._utils._processRequest(_awsRequest, "PutRecords", body, function (error, response) {
            local putRecordResults = null;
            local failedRecordCount = AWSKinesisStreams._utils._getTableValue(response, "FailedRecordCount", null);
            error = error || AWSKinesisStreams._utils._validateNonEmpty(failedRecordCount, "FailedRecordCount", true, response);
            if (!error) {
                local encryptionType = AWSKinesisStreams._utils._getTableValue(response, "EncryptionType", null);
                putRecordResults = AWSKinesisStreams._utils._getTableValue(response, "Records", []).map(
                    function (value) {
                        local result = AWSKinesisStreams.PutRecordResult();
                        value.EncryptionType <- encryptionType;
                        result._fromJson(value);
                        error = error || result._getError();
                        return result;
                    }.bindenv(this));
            }
            _invokePutCallback(callback, error, true, putRecordResults, recordCount, failedRecordCount);
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _invokePutCallback(callback, error, isMultiple = false, result = null, recordCount = 0, failedRecordCount = 0) {
        if (callback) {
            if (error) {
                failedRecordCount = recordCount;
                result = isMultiple ? [] : null;
            }
            imp.wakeup(0, function () {
                if (isMultiple) {
                    callback(error, failedRecordCount, result);
                } else {
                    callback(error, result);
                }
            });
        }
    }
}

// Shard iterator type.
// Determines how the shard iterator is used to start reading data records from the shard.
// See http://docs.aws.amazon.com/kinesis/latest/APIReference/
enum AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE {
    // Start reading from the position denoted by a specific record sequence number
    AT_SEQUENCE_NUMBER,
    // Start reading right after the position denoted by a specific record sequence number
    AFTER_SEQUENCE_NUMBER,
    // Start reading from the position denoted by a specific timestamp
    AT_TIMESTAMP,
    // Start reading at the last untrimmed record in the shard in the system,
    // which is the oldest data record in the shard
    TRIM_HORIZON,
    // Start reading just after the most recent record in the shard,
    // so that you always read the most recent data in the shard
    LATEST
};

// This class allows your code to read data records from a specific Amazon Kinesis stream.
class AWSKinesisStreams.Consumer {
    _awsRequest = null;
    _streamName = null;
    _isBlob = null;
    _initError = null;

    // AWSKinesisStreams.Consumer constructor.
    //
    // Parameters:
    //     region : string             The Region code of Amazon EC2.
    //                                 See http://docs.aws.amazon.com/AWSEC2/latest/
    //     accessKeyId : string        Access key ID of an AWS IAM user.
    //                                 See http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html
    //     secretAccessKey : string    Secret access key of an AWS IAM user.
    //                                 See http://docs.aws.amazon.com/streams/latest/dev/learning-kinesis-module-one-iam.html
    //     streamName : string         The name of Amazon Kinesis stream
    //     isBlob : boolean            If true, the AWSKinesisStreams.Consumer object will consider
    //         (optional)              every received data record as a Squirrel blob.
    //                                 If false or not specified, the AWSKinesisStreams.Consumer
    //                                 object will consider every received data record as a JSON data
    //                                 and parse it using http.jsondecode method.
    //
    // Returns:                        AWSKinesisStreams.Consumer instance created
    constructor(region, accessKeyId, secretAccessKey, streamName, isBlob = false) {
        _initError = AWSKinesisStreams._utils._getInitError(
            region, accessKeyId, secretAccessKey, streamName);
        if (!_initError) {
            _awsRequest = AWSRequestV4(_AWS_KINESIS_STREAMS_SERVICE, region, accessKeyId, secretAccessKey);
            _streamName = streamName;
            _isBlob = isBlob;
        }
    }

    // Get the list of IDs of all shards of the Amazon Kinesis stream, including the closed shards.
    //
    // Parameters:
    //   callback : function           Callback function to be executed once the operation is
    //                                 completed.
    //                                 The callback signature:
    //                                 callback(error, shardIds), where
    //                                   error :                     Error details,
    //                                     AWSKinesisStreams.Error   null if the operation succeeds.
    //                                   shardIds : array of         The IDs of the stream's shards.
    //                                     strings                   The array is empty if the operation fails.
    //
    // Returns:                        Nothing
    function getShards(callback) {
        if (_initError) {
            _invokeGetShardsCallback(callback, _initError);
            return;
        }
        _getShards([], null, callback);
    }

    // Get the Amazon Kinesis stream's shard iterator which corresponds to the specified start position
    // for the reading. See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html
    //
    // Parameters:
    //   shardId : string              The shard ID.
    //   type :                    
    //     AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE
    //                                 The shard iterator type. Determines how the shard iterator is used
    //                                 to start reading data records from the shard. Some of the types
    //                                 require the corresponding typeOptions to be specified.
    //   typeOptions: table            Additional options required for some of the shard iterator types
    //                                 specified by the type parameter. Pass null if the additional options
    //                                 are not required for the specified iterator type.
    //                                 The valid keys are:
    //                                   startingSequenceNumber :   The sequence number of the data record
    //                                     string (optional)        in the shard from which to start reading.
    //                                                              Must be specified if the type parameter is
    //                                                              AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER and
    //                                                              AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER.
    //                                   timestamp :                The timestamp of the data record from which
    //                                     integer (optional)       to start reading. Used with shard iterator type
    //                                                              AT_TIMESTAMP. In number of seconds since 
    //                                                              Unix epoch (midnight, 1 Jan 1970).
    //                                                              If a record with this exact timestamp does not
    //                                                              exist, the iterator returned is for the next (later)
    //                                                              record.
    //                                                              Must be specified if the type parameter is 
    //                                                              AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP.
    //                                                              For the behavior details see 
    //                                                              http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Streams-GetShardIterator-request-Timestamp
    //   callback : function           Callback function to be executed once the operation is completed.
    //                                 The callback signature:
    //                                 callback(error, shardIterator), where
    //                                   error :                    Error details,
    //                                     AWSKinesisStreams.Error  null if the operation succeeds.
    //                                   shardIterator : string     The shard iterator, or null if the operation fails.
    //
    // Returns:                        Nothing
    function getShardIterator(shardId, type, typeOptions, callback) {
        local error = _initError ||
            AWSKinesisStreams._utils._validateNonEmpty(shardId, "shardId");
        local shardIteratorTypeName = _getShardIteratorTypeName(type);
        if (!shardIteratorTypeName) {
            error = error || AWSKinesisStreams.Error(
                AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR,
                format("%s: %s", AWS_KINESIS_STREAMS_WRONG_ARG_TYPE, "type"));
        }
        local body = {
            "StreamName" : _streamName,
            "ShardId" : shardId,
            "ShardIteratorType" : shardIteratorTypeName
        };
        local startingSequenceNumber = AWSKinesisStreams._utils._getTableValue(typeOptions, "startingSequenceNumber", null);
        if (type == AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER ||
            type == AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER) {
            body.StartingSequenceNumber <- startingSequenceNumber;
            error = error || AWSKinesisStreams._utils._validateNonEmpty(startingSequenceNumber, "typeOptions.startingSequenceNumber");
        }
        local timestamp = AWSKinesisStreams._utils._getTableValue(typeOptions, "timestamp", null);
        if (type == AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP) {
            body.Timestamp <- timestamp;
            error = error || AWSKinesisStreams._utils._validateNonEmpty(timestamp, "typeOptions.timestamp");
        }
        if (error) {
            _invokeGetShardIteratorCallback(callback, error);
            return;
        }
        AWSKinesisStreams._utils._processRequest(_awsRequest, "GetShardIterator", body, function (error, response) {
            local shardIterator = null;
            if (!error) {
                shardIterator = AWSKinesisStreams._utils._getTableValue(response, "ShardIterator", null);
                error = AWSKinesisStreams._utils._validateNonEmpty(shardIterator, "ShardIterator", true, response);
            }
            _invokeGetShardIteratorCallback(callback, error, shardIterator);
        }.bindenv(this));
    }

    // Reads data records from the Amazon Kinesis stream's shard using the specified shard iterator.
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html
    //
    // Parameters:
    //   options : table               Key/Value options for the operation.
    //                                 The valid keys are:
    //                                   shardIterator : string      The shard iterator that specifies the position
    //                                                               in the shard from which the reading should be started.
    //                                   limit : integer             The maximum number of data records to read.
    //                                     (optional)                If not specified, the number of returned records
    //                                                               is Amazon Kinesis Streams specific.
    //                                                               See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-request-Limit
    //   callback : function           Optional callback function to be executed once the operation is
    //                                 completed.
    //                                 The callback signature:
    //                                 callback(error, records, millisBehindLatest, nextOptions), where
    //                                   error :                     Error details,
    //                                     AWSKinesisStreams.Error   null if the operation succeeds.
    //                                   records : array of          The data records retrieved from the shard.
    //                                     AWSKinesisStreams.Record  The array is empty if the operation fails or
    //                                                               there are no new records in the shard for the
    //                                                               specified shard iterator.
    //                                   millisBehindLatest :        The number of milliseconds the response is 
    //                                     integer                   from the tip of the stream.
    //                                                               Zero if there are no new records in the shard
    //                                                               for the specified shard iterator.
    //                                                               See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html#Streams-GetRecords-response-MillisBehindLatest
    //                                   nextOptions : table         Options which can be used as the options
    //                                                               parameter in the next getRecords() call.
    //                                                               Key-value table, identical to the options table,
    //                                                               see above. 
    //                                                               nextOptions is null if
    //                                                               - the operation fails 
    //                                                               - the shard has been closed and the specified
    //                                                                 shard iterator has reached the last record in the
    //                                                                 shard and will not return any more data.
    //
    // Returns:                        Nothing
    function getRecords(options, callback) {
        local shardIterator = AWSKinesisStreams._utils._getTableValue(options, "shardIterator", null);
        local error = _initError ||
            AWSKinesisStreams._utils._validateNonEmpty(shardIterator, "shardIterator");
        if (error) {
            _invokeGetRecordsCallback(callback, error);
            return;
        }

        local body = {
            "ShardIterator" : shardIterator
        };
        local limit = AWSKinesisStreams._utils._getTableValue(options, "limit", null);
        if (limit) {
            body.Limit <- limit;
        }
        AWSKinesisStreams._utils._processRequest(_awsRequest, "GetRecords", body, function (error, response) {
            local millisBehindLatest = AWSKinesisStreams._utils._getTableValue(response, "MillisBehindLatest", 0);
            local records = null;
            local nextOptions = null;
            if (!error) {
                records = AWSKinesisStreams._utils._getTableValue(response, "Records", []).map(
                    function (value) {
                        local result = AWSKinesisStreams.Record(null, null);
                        result._fromJson(value, _isBlob);
                        error = error || result._getError();
                        return result;
                    }.bindenv(this));
                local nextShardIterator = AWSKinesisStreams._utils._getTableValue(response, "NextShardIterator", null);
                if (nextShardIterator) {
                    nextOptions = clone(options);
                    nextOptions["shardIterator"] = nextShardIterator;
                }
            }
            _invokeGetRecordsCallback(callback, error, records, millisBehindLatest, nextOptions);
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _getShards(shardIds, startShardId, callback) {
        local body = {
            "StreamName" : _streamName
        };
        if (startShardId) {
            body.ExclusiveStartShardId <- startShardId;
        }
        AWSKinesisStreams._utils._processRequest(_awsRequest, "DescribeStream", body, function (error, response) {
            local streamDescr = AWSKinesisStreams._utils._getTableValue(response, "StreamDescription", null);
            local ids = [];
            if (!error) {
                foreach (shard in AWSKinesisStreams._utils._getTableValue(streamDescr, "Shards", [])) {
                    local shardId = AWSKinesisStreams._utils._getTableValue(shard, "ShardId", null);
                    ids.push(shardId);
                    error = error || AWSKinesisStreams._utils._validateNonEmpty(shardId, "ShardId", true, response);
                }
                shardIds.extend(ids);
            }
            if (!error && ids.len() > 0 &&
                AWSKinesisStreams._utils._getTableValue(streamDescr, "HasMoreShards", false)) {
                _getShards(shardIds, ids.top(), callback);
                return;
            }
            _invokeGetShardsCallback(callback, error, shardIds);
        }.bindenv(this));
    }

    function _invokeGetShardsCallback(callback, error, shardIds = null) {
        if (callback) {
            imp.wakeup(0, function () {
                callback(error, error ? [] : shardIds);
            });
        }
    }

    function _invokeGetShardIteratorCallback(callback, error, shardIterator = null) {
        if (callback) {
            imp.wakeup(0, function () {
                callback(error, error ? null : shardIterator);
            });
        }
    }

    function _invokeGetRecordsCallback(callback, error, records = null, millisBehindLatest = 0, nextOptions = null) {
        if (callback) {
            imp.wakeup(0, function () {
                if (error) {
                    records = [];
                    millisBehindLatest = 0;
                    nextOptions = null;
                }
                callback(error, records, millisBehindLatest, nextOptions);
            });
        }
    }

    function _getShardIteratorTypeName(type) {
        switch (type) {
            case AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER:
                return "AT_SEQUENCE_NUMBER";
            case AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER:
                return "AFTER_SEQUENCE_NUMBER";
            case AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP:
                return "AT_TIMESTAMP";
            case AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.TRIM_HORIZON:
                return "TRIM_HORIZON";
            case AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST:
                return "LATEST";
            default:
                return null;
        }
    }
}

// The encryption type used on a record. See http://docs.aws.amazon.com/kinesis/latest/
enum AWS_KINESIS_STREAMS_ENCRYPTION_TYPE {
    // record is not encrypted
    NONE,
    // record is encrypted on server side using a customer-managed KMS key
    KMS
};

// Represents an Amazon Kinesis Streams record: a combination of data attributes.
class AWSKinesisStreams.Record {
    // The record data (blob or any JSON-compatible type)
    data = null;

    // Determines which shard in the stream the data record is assigned to (string).
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-PartitionKey
    partitionKey = null;

    // The unique identifier of the record within its shard (string).
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_Record.html#Streams-Type-Record-SequenceNumber
    sequenceNumber = null;

    // The encryption type used on the record (AWS_KINESIS_STREAMS_ENCRYPTION_TYPE)
    encryptionType = null;

    // The approximate time that the record was inserted into the stream (integer).
    // In number of seconds since Unix epoch (midnight, 1 Jan 1970).
    timestamp = null;

    // -------------------- PRIVATE PROPERTIES ----------------- //

    _error = null;
    _explicitHashKey = null;
    _prevSequenceNumber = null;
    _encoder = null;

    // Creates and returns AWSKinesisStreams.Record object that can be written into an
    // Amazon Kinesis stream using AWSKinesisStreams.Producer methods.
    //
    // Parameters:
    //   data : blob or              The record data.
    //     any JSON-compatible type
    //   partitionKey : string       Determines which shard in the stream the data record
    //                               is assigned to.
    //                               See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-PartitionKey
    //   explicitHashKey : string    The hash value used to explicitly determine the shard
    //     (optional)                the data record is assigned to by overriding the partition key hash.
    //                               See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-ExplicitHashKey
    //   prevSequenceNumber :        See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html#Streams-PutRecord-request-SequenceNumberForOrdering
    //     string (optional)
    //
    //   encoder :                   a custom JSON encoder function for encoding the provided data (e.g. [JSONEncoder.encode](https://github.com/electricimp/JSONEncoder))
    //     function (otpional)
    //
    // Returns:                      AWSKinesisStreams.Record object that can be 
    //                               written into the Amazon Kinesis stream using
    //                               AWSKinesisStreams.Producer putRecord/putRecords
    //                               methods.
    constructor(data, partitionKey, explicitHashKey = null, prevSequenceNumber = null, encoder = null) {
        this.data = data;
        this.partitionKey = partitionKey;
        _explicitHashKey = explicitHashKey;
        _prevSequenceNumber = prevSequenceNumber;
        _encoder = encoder == null ? http.jsonencode.bindenv(http) : encoder;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _toJson(isMultiple) {
        _error = AWSKinesisStreams._utils._validateNonEmpty(partitionKey, "partitionKey");
        if (!_error) {
            local result = {
                "Data" : http.base64encode(typeof data == "blob" ? data.tostring() : _encoder(data)),
                "PartitionKey" : partitionKey,
            };
            if (_explicitHashKey) {
                result.ExplicitHashKey <- _explicitHashKey;
            }
            if (!isMultiple && _prevSequenceNumber) {
                result.SequenceNumberForOrdering <- _prevSequenceNumber;
            }
            return result;
        }
        return null;
    }

    function _fromJson(jsonRecord, isBlob) {
        local recordData = AWSKinesisStreams._utils._getTableValue(jsonRecord, "Data", null);
        if (recordData) {
            try {
                recordData = http.base64decode(recordData);
                data = isBlob ? recordData : http.jsondecode(recordData.tostring());
            }
            catch (e) {
                _error = AWSKinesisStreams.Error(
                    AWS_KINESIS_STREAMS_ERROR.UNEXPECTED_RESPONSE, e, null, jsonRecord);
            }
        }
        partitionKey = AWSKinesisStreams._utils._getTableValue(jsonRecord, "PartitionKey", null)
        sequenceNumber = AWSKinesisStreams._utils._getTableValue(jsonRecord, "SequenceNumber", null);
        encryptionType = AWSKinesisStreams._utils._getEncryptionType(
            AWSKinesisStreams._utils._getTableValue(jsonRecord, "EncryptionType", null));
        if (!encryptionType) {
            encryptionType = AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE;
        }
        timestamp = AWSKinesisStreams._utils._getTableValue(jsonRecord, "ApproximateArrivalTimestamp", null);
        if (timestamp != null) {
            timestamp = timestamp.tointeger();
        }

        _error = _error || 
            AWSKinesisStreams._utils._validateNonEmpty(partitionKey, "PartitionKey", true, jsonRecord) ||
            AWSKinesisStreams._utils._validateNonEmpty(partitionKey, "PartitionKey", true, jsonRecord) ||
            AWSKinesisStreams._utils._validateNonEmpty(timestamp, "ApproximateArrivalTimestamp", true, jsonRecord);
    }

    function _getError() {
        return _error;
    }
}

// Represents information from AWS Kinesis Streams about a written data record.
class AWSKinesisStreams.PutRecordResult {
    // The encryption type used on the record (AWS_KINESIS_STREAMS_ENCRYPTION_TYPE),
    // or null if the record writing fails.
    encryptionType = null;

    // The unique identifier of the record within its shard (string),
    // or null if the record writing fails.
    sequenceNumber = null;

    // The ID of the shard where the data record has been written (string),
    // or null if the record writing fails.
    shardId = null;

    // The error code for the data record (string),
    // or null if the record is written successfully.
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorCode
    errorCode = null;

    // The error message for the data record (string),
    // or null if the record is written successfully.
    // See http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsResultEntry.html#Streams-Type-PutRecordsResultEntry-ErrorMessage
    errorMessage = null;

    // ------------- PRIVATE PROPERTIES AND METHODS ------------ //

    _error = null;

    function _fromJson(json) {
        shardId = AWSKinesisStreams._utils._getTableValue(json, "ShardId", null);
        sequenceNumber = AWSKinesisStreams._utils._getTableValue(json, "SequenceNumber", null);
        encryptionType = AWSKinesisStreams._utils._getEncryptionType(
            AWSKinesisStreams._utils._getTableValue(json, "EncryptionType", null));
        if (!encryptionType) {
            encryptionType = AWS_KINESIS_STREAMS_ENCRYPTION_TYPE.NONE;
        }
        errorCode = AWSKinesisStreams._utils._getTableValue(json, "ErrorCode", null);
        errorMessage = AWSKinesisStreams._utils._getTableValue(json, "ErrorMessage", null);

        if (!errorCode) {
            _error = AWSKinesisStreams._utils._validateNonEmpty(shardId, "ShardId", true, json) ||
                AWSKinesisStreams._utils._validateNonEmpty(sequenceNumber, "SequenceNumber", true, json);
        }
    }

    function _getError() {
        return _error;
    }
}
