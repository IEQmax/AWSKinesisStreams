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

const AWS_KINESIS_REGION = "@{AWS_KINESIS_REGION}";
const AWS_KINESIS_ACCESS_KEY_ID = "@{AWS_KINESIS_ACCESS_KEY_ID}";
const AWS_KINESIS_SECRET_ACCESS_KEY = "@{AWS_KINESIS_SECRET_ACCESS_KEY}";

const AWS_KINESIS_STREAM_NAME = "imptestStream";

// Test case for required AWSRequestV4 library check
class RequiredLibTestCase extends ImpTestCase {
    function testProducer() {
        local awsProducer = AWSKinesisStreams.Producer(
            AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);
        return Promise(function (resolve, reject) {
            awsProducer.putRecord(AWSKinesisStreams.Record({}, "testPartitionKey"), function (error, putRecordResult) {
                if (!_isLibraryError(error)) {
                    return reject("Required library AWSRequestV4 check failed in putRecord");
                }
                awsProducer.putRecords(
                    [AWSKinesisStreams.Record({}, "testPartitionKey")],
                    function (error, failedRecordCount, putRecordsResult) {
                        if (!_isLibraryError(error)) {
                            return reject("Required library AWSRequestV4 check failed in putRecords");
                        }
                        return resolve("");
                    }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function testConsumer() {
        local awsConsumer = AWSKinesisStreams.Consumer(
            AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);
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

    function _isLibraryError(error) {
        return error && error.type == AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR;
    }
}
