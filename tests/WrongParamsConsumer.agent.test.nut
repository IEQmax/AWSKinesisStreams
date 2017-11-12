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

// Test case for wrong parameters of AWSKinesisStreams.Consumer library methods.
class WrongParamsConsumerTestCase extends ImpTestCase {
    _awsConsumer = null;

    function setUp() {
        _awsConsumer = AWSKinesisStreams.Consumer(
            AWS_KINESIS_REGION,
            AWS_KINESIS_ACCESS_KEY_ID,
            AWS_KINESIS_SECRET_ACCESS_KEY,
            AWS_KINESIS_STREAM_NAME);
    }

    function testWrongRegion() {
        return Promise.all([
            _testWrongInitialParams(null, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME),
            _testWrongInitialParams("", AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME)
        ]);
    }

    function testWrongAccessKeyId() {
        return Promise.all([
            _testWrongInitialParams(AWS_KINESIS_REGION, null, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME),
            _testWrongInitialParams(AWS_KINESIS_REGION, "", AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME)
        ]);
    }

    function testWrongSecretAccessKey() {
        return Promise.all([
            _testWrongInitialParams(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, null, AWS_KINESIS_STREAM_NAME),
            _testWrongInitialParams(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, "", AWS_KINESIS_STREAM_NAME)
        ]);
    }

    function testWrongStreamName() {
        return Promise.all([
            _testWrongInitialParams(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, null),
            _testWrongInitialParams(AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, "")
        ]);
    }

    function testWrongShardId() {
        return Promise.all([
            _testWrongGetShardIterator(null, AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST, null),
            _testWrongGetShardIterator("", AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST, null)
        ]);
    }

    function testWrongShardIteratorType() {
        return Promise.all([
            _testWrongGetShardIterator("testShardId", null, null),
            _testWrongGetShardIterator("testShardId", "", null),
            _testWrongGetShardIterator("testShardId", "abc", null),
            _testWrongGetShardIterator("testShardId", { "test" : "test" }, null)
        ]);
    }

    function testWrongShardIteratorOptions() {
        return Promise.all([
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER, null),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER, {}),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_SEQUENCE_NUMBER, { "timestamp" : "1459799926.480" }),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER, null),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER, {}),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AFTER_SEQUENCE_NUMBER, { "timestamp" : "1459799926.480" }),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP, null),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP, {}),
            _testWrongGetShardIterator("testShardId",
                AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.AT_TIMESTAMP, { "startingSequenceNumber" : "12345" })
        ]);
    }

    function testWrongGetRecordsOptions() {
        return Promise.all([
            _testWrongGetRecords(null),
            _testWrongGetRecords({}),
            _testWrongGetRecords({ "limit" : 10 }),
            _testWrongGetRecords({ "shardIterator" : null }),
            _testWrongGetRecords({ "shardIterator" : "" })
        ]);
    }

    function _testWrongInitialParams(region, accessKeyId, secretAccessKey, streamName) {
        local awsConsumer = AWSKinesisStreams.Consumer(
            region, accessKeyId, secretAccessKey, streamName);
        return Promise(function (resolve, reject) {
            awsConsumer.getShards(function (error, shardIds) {
                if (!_isLibraryError(error)) {
                    return reject("Wrong initial param accepted in getShards");
                }
                awsConsumer.getShardIterator(
                    "testShardId",
                    AWS_KINESIS_STREAMS_SHARD_ITERATOR_TYPE.LATEST,
                    null,
                    function (error, shardIterator) {
                        if (!_isLibraryError(error)) {
                            return reject("Wrong initial param accepted in getShardIterator");
                        }
                        awsConsumer.getRecords(
                            { "shardIterator" : "testShardIterator" },
                            function (error, records, millisBehindLatest, nextOptions) {
                                if (!_isLibraryError(error)) {
                                    return reject("Wrong initial param accepted in getRecords");
                                }
                                return resolve("");
                            }.bindenv(this));
                    }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _testWrongGetShardIterator(shardId, type, typeOptions) {
        return Promise(function (resolve, reject) {
            _awsConsumer.getShardIterator(
                shardId,
                type,
                typeOptions,
                function (error, shardIterator) {
                    if (!_isLibraryError(error)) {
                        return reject("Wrong param accepted in getShardIterator");
                    }
                    return resolve("");
                }.bindenv(this));
        }.bindenv(this));
    }

    function _testWrongGetRecords(options) {
        return Promise(function (resolve, reject) {
            _awsConsumer.getRecords(
                options,
                function (error, records, millisBehindLatest, nextOptions) {
                    if (!_isLibraryError(error)) {
                        return reject("Wrong options accepted in getRecords");
                    }
                    return resolve("");
                }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR;
    }
}
