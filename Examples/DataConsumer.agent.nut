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

#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSKinesisStreams.agent.lib.nut:1.0.0"

// AWSKinesisStreams.Consumer library sample. 
// Periodically reads new data records from all shards of the specified preconfigured
// AWS Kinesis Stream.
// Records are read every 15 seconds and printed to the log.

const READ_DATA_PERIOD_SEC = 15.0;
const RECORDS_LIMIT = 10;

class DataConsumer {
    _awsConsumer = null;
    _shardIterators = null;

    constructor(awsRegion, awsAccessKeyId, awsSecretAccessKey, awsKinesisStreamName) {
        _awsConsumer = AWSKinesisStreams.Consumer(
            awsRegion, awsAccessKeyId, awsSecretAccessKey, awsKinesisStreamName);
        _shardIterators = {};
    }

    // Periodically reads latest records from the specified shard
    function readRecords(shardId, options) {
        _awsConsumer.getRecords(
            options,
            function (error, records, millisBehindLatest, nextOptions) {
                if (error) {
                    server.error("Data reading failed: " + error.details);
                    readData(shardId);
                } else {
                    if (records.len() > 0) {
                        server.log("Data read successfully:");
                        foreach (record in records) {
                            server.log(format("data: %s, timestamp: %d",
                                http.jsonencode(record.data), record.timestamp));
                        }
                    }
                    if (nextOptions) {
                        _shardIterators[shardId] = nextOptions.shardIterator;
                        imp.wakeup(READ_DATA_PERIOD_SEC, function () {
                            readRecords(shardId, nextOptions);
                        }.bindenv(this));
                    } else {
                        // the current shard has been closed,
                        // shard iterators need to be reinitialized
                        _shardIterators[shardId] = null;
                        initShardIterators();
                    }
                }
            }.bindenv(this));
    }

    // Starts data reading from the specified shard
    function readData(shardId) {
        local shardIterator = _shardIterators[shardId];
        if (shardIterator) {
            readRecords(
                shardId,
                { "shardIterator" : shardIterator, "limit" : RECORDS_LIMIT });
        }
    }
    
    // Initializes shard iterator for the specified shard and starts data reading
    function initShardIterator(shardId) {
        _shardIterators[shardId] <- null;
        _awsConsumer.getShardIterator(
            shardId,
            AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST,
            null,
            function (error, shardIterator) {
                if (error) {
                    server.error("getShardIterator failed: " + error.details);
                } else {
                    _shardIterators[shardId] = shardIterator;
                    readData(shardId);
                }
            }.bindenv(this));
    }

    // Initializes shard iterators for all stream shards
    function initShardIterators() {
        _awsConsumer.getShards(function (error, shardIds) {
            if (error) {
                server.error("getShards failed: " + error.details);
            } else {
                foreach (id in shardIds) {
                    if (!(id in _shardIterators)) {
                        initShardIterator(id);
                    }
                }
            }
        }.bindenv(this));
    }

    // Starts the application:
    // - obtains the stream shards
    // - initializes shards iterators
    // - reads records from all the shards
    function start() {
        initShardIterators();
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------

// AWS KINESIS CONSTANTS
// ----------------------------------------------------------
const AWS_KINESIS_REGION = "<YOUR_AWS_REGION>";
const AWS_KINESIS_ACCESS_KEY_ID = "<YOUR_AWS_ACCESS_KEY_ID>";
const AWS_KINESIS_SECRET_ACCESS_KEY = "<YOUR_AWS_SECRET_ACCESS_KEY>";

const AWS_KINESIS_STREAM_NAME = "testStream";

// Start application
dataConsumer <- DataConsumer(
    AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);
dataConsumer.start();