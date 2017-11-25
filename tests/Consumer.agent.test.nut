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

@include "https://raw.githubusercontent.com/electricimp/AWSRequestV4/master/AWSRequestV4.class.nut"

const AWS_KINESIS_REGION = "@{AWS_KINESIS_REGION}";
const AWS_KINESIS_ACCESS_KEY_ID = "@{AWS_KINESIS_ACCESS_KEY_ID}";
const AWS_KINESIS_SECRET_ACCESS_KEY = "@{AWS_KINESIS_SECRET_ACCESS_KEY}";

const AWS_KINESIS_STREAM_NAME = "imptestStream";

const RECEIVE_DATA_PERIOD_SEC = 2.0;

// Test case for AWSKinesisStreams.Consumer library methods.
class ConsumerTestCase extends ImpTestCase {
    _awsProducer = null;
    _awsConsumer = null;
    _recordsCount = null;
    _recordsReceived = null;

    _counter = null;
    _getShardRecordsCounter = null;
    _counterStart = null;
    _shardIds = null;

    function setUp() {
        _awsProducer = AWSKinesisStreams.Producer(
            AWS_KINESIS_REGION,
            AWS_KINESIS_ACCESS_KEY_ID,
            AWS_KINESIS_SECRET_ACCESS_KEY,
            AWS_KINESIS_STREAM_NAME);
        _awsConsumer = AWSKinesisStreams.Consumer(
            AWS_KINESIS_REGION,
            AWS_KINESIS_ACCESS_KEY_ID,
            AWS_KINESIS_SECRET_ACCESS_KEY,
            AWS_KINESIS_STREAM_NAME);

        _counter = time();

        return _initShardIds();
    }

    function testGetBlobRecordsLatest() {
        local awsBlobConsumer = AWSKinesisStreams.Consumer(
            AWS_KINESIS_REGION,
            AWS_KINESIS_ACCESS_KEY_ID,
            AWS_KINESIS_SECRET_ACCESS_KEY,
            AWS_KINESIS_STREAM_NAME,
            true);
        local shardIterators = {};
        return Promise.all(_shardIds.map(function (shardId) {
                return _initShardIterator(
                    awsBlobConsumer, shardIterators, shardId, AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST);
            }.bindenv(this))).
        then(function (value) {
                _recordsCount = 0;
                _counterStart = _counter;
                return _putRecordsToAllShards({});
            }.bindenv(this)).
        then(function (value) {
                return _getRecords(awsBlobConsumer, true, shardIterators, 2);
            }.bindenv(this)).
        fail(function(reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function testGetRecordsAtSequenceNumber() {
        local shardIterators = {};
        local sequenceNumber;
        _recordsCount = 5;
        _counterStart = _counter;
        return _putRecord(_getRecordData(false, "testPartitionKey")).
        then(function(value) {
                sequenceNumber = value.sequenceNumber;
                return _initShardIterator(
                    _awsConsumer, shardIterators, value.shardId, 
                    AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER,
                    { "startingSequenceNumber" : sequenceNumber });
            }.bindenv(this)).
        then(function (val) {
                local records = [];
                records.push(_getRecordData(false, "testPartitionKey", null, sequenceNumber));
                local i;
                for (i = 2; i < _recordsCount; i++) {
                    records.push(_getRecordData(false, "testPartitionKey"));
                }
                return _putRecords(records);
            }.bindenv(this)).
        then(function (value) {
               return _getRecords(_awsConsumer, false, shardIterators, 3);
            }.bindenv(this)).
        fail(function(reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function testGetRecordsAfterSequenceNumber() {
        local shardIterators = {};
        return _putRecord(_getRecordData(false, "testPartitionKey", "12345")).
        then(function(value) {
                return _initShardIterator(
                    _awsConsumer, shardIterators, value.shardId, 
                    AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER,
                    { "startingSequenceNumber" : value.sequenceNumber });
            }.bindenv(this)).
        then(function (val) {
                _recordsCount = 5;
                _counterStart = _counter;
                local records = [];
                local i;
                for (i = 0; i < _recordsCount; i++) {
                    records.push(_getRecordData(false, "testPartitionKey", "12345"));
                }
                return _putRecords(records);
            }.bindenv(this)).
        then(function (value) {
            return _getRecords(_awsConsumer, false, shardIterators, 4);
            }.bindenv(this)).
        fail(function(reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function testGetRecordsAtTimestamp() {
        local shardIterators = {};
        local time = time();
        return Promise.all(_shardIds.map(function (shardId) {
                return _initShardIterator(
                    _awsConsumer, shardIterators, shardId, 
                    AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP,
                    { "timestamp" : time });
            }.bindenv(this))).
        then(function (val) {
                _recordsCount = 0;
                _counterStart = _counter;
                return _putRecordsToAllShards({});
            }.bindenv(this)).
        then(function (value) {
               return _getRecords(_awsConsumer, false, shardIterators, 10);
            }.bindenv(this)).
        fail(function(reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function testGetRecordsTrimHorizon() {
        local shardIterators = {};
        _recordsCount = 1;
        _counterStart = null;
        return _putRecord(_getRecordData(false, "testPartitionKey")).
        then(function(value) {
                return _initShardIterator(
                    _awsConsumer, shardIterators, value.shardId, 
                    AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.TRIM_HORIZON);
            }.bindenv(this)).
        then(function (value) {
               return _getRecords(_awsConsumer, false, shardIterators, 10);
            }.bindenv(this)).
        fail(function(reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function _putRecordsToAllShards(usedShards) {
        local count = 10;
        _recordsCount += count;
        local records = [];
        local i;
        for (i = 0; i < count; i++) {
            records.push(_getRecordData(true));
        }
        return _putRecords(records).then(
            function (putResults) {
                foreach (putRecord in putResults) {
                    usedShards[putRecord.shardId] <- true;
                }
                if (usedShards.len() < _shardIds.len()) {
                    return _putRecordsToAllShards(usedShards);
                }
            }.bindenv(this));
    }

    function _putRecords(records) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecords(records, function (error, failedRecordCount, response) {
                if (error) {
                    return reject(error.details);
                } else if (failedRecordCount > 0) {
                    return reject("putRecords failed");
                } else {
                    return resolve(response);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function _putRecord(record) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecord(record, function (error, response) {
                if (error) {
                    return reject(error.details);
                } else {
                    return resolve(response);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function _getRecords(awsConsumer, isBlob, shardIterators, limit) {
        _recordsReceived = 0;
        _getShardRecordsCounter = 0;
        return Promise(function (resolve, reject) {
            foreach (shardIter in shardIterators) {
                _getShardRecords(awsConsumer, isBlob, { "shardIterator" : shardIter, "limit" : limit }, resolve, reject);
            }
        }.bindenv(this));
    }

    function _getShardRecords(awsConsumer, isBlob, options, resolve, reject) {
        imp.wakeup(RECEIVE_DATA_PERIOD_SEC, function () {
            _getShardRecordsCounter++;
            if (_getShardRecordsCounter > 2 * _recordsCount) {
                return reject("Records receiving failed");
            }
            awsConsumer.getRecords(
                options,
                function (error, records, millisBehindLatest, nextOptions) {
                    if (error) {
                        return reject(error.details);
                    } else {
                        foreach (record in records) {
                            local data = record.data;
                            if (isBlob) {
                                if (typeof record.data != "blob") {
                                    return reject("Wrong record type");
                                }
                                try {
                                    data = http.jsondecode(record.data.tostring());
                                }
                                catch (e) { 
                                    return reject("Wrong record body");
                                }
                            }
                            if (_counterStart == null || data.value >= _counterStart && data.value < _counterStart + _recordsCount) {
                                _recordsReceived++;
                            }
                        }
                        if (_recordsReceived >= _recordsCount) {
                            return resolve("");
                        }
                        if (millisBehindLatest > 0 && nextOptions) {
                            _getShardRecords(awsConsumer, isBlob, nextOptions, resolve, reject);
                        }
                    }
                }.bindenv(this));
        }.bindenv(this));
    }

    function _getRecordData(isBlob = false, partitionKey = null, explicitHashKey = null, prevSequenceNumber = null) {
        local body = {
            "value" : _counter,
        };
        if (!partitionKey) {
            partitionKey = "testPartitionKey" + _counter;
        }
        _counter++;
        if (isBlob) {
            local blobBody = blob();
            blobBody.writestring(http.jsonencode(body));
            body = blobBody;
        }
        return AWSKinesisStreams.Record(body, partitionKey, explicitHashKey, prevSequenceNumber);
    }

    function _initShardIterator(awsConsumer, shardIterators, shardId, type, typeOptions = null) {
        return Promise(function (resolve, reject) {
            awsConsumer.getShardIterator(
                shardId,
                type,
                typeOptions,
                function (error, shardIterator) {
                    if (error) {
                        return reject("getShardIterator failed: " + error.details);
                    } else {
                        shardIterators[shardId] <- shardIterator;
                        return resolve("");
                    }
                }.bindenv(this));
        }.bindenv(this));
    }

    function _initShardIds() {
        return Promise(function (resolve, reject) {
            _awsConsumer.getShards(function (error, shardIds) {
                if (error) {
                    return reject(error.details);
                }
                _shardIds = shardIds;
                return resolve("");
            }.bindenv(this))
        }.bindenv(this));
    }
}
