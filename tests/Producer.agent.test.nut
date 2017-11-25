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

// Test case for AWSKinesisStreams.Producer library methods.
class ProducerTestCase extends ImpTestCase {
    _awsProducer = null;
    _counter = 0;

    function setUp() {
        _awsProducer = AWSKinesisStreams.Producer(
            AWS_KINESIS_REGION,
            AWS_KINESIS_ACCESS_KEY_ID,
            AWS_KINESIS_SECRET_ACCESS_KEY,
            AWS_KINESIS_STREAM_NAME);
    }

    function testPutRecord() {
        return Promise.all([
            _testPutRecord(_getRecord("")),
            _testPutRecord(_getRecord(null)),
            _testPutRecord(_getRecord("abc")),
            _testPutRecord(_getRecord(12345)),
            _testPutRecord(_getRecord(true, "testPartitionKey")),
            _testPutRecord(_getRecord([])),
            _testPutRecord(_getRecord(["x1", "x2"])),
            _testPutRecord(_getRecord({})),
            _testPutRecord(_getRecord({ "x3" : "x4", "x5" : 123 }, "testPartitionKey"))
        ]);
    }

    function testPutBlobRecord() {
        local tstBlob = blob();
        tstBlob.writestring("testString");
        return Promise.all([
            _testPutRecord(_getRecord(blob())),
            _testPutRecord(_getRecord(tstBlob)),
        ]);
    }

    function testPutRecordWithExplicitHashKey() {
        return Promise.all([
            _testPutRecord(_getRecord("abc", null, "12345")),
            _testPutRecord(_getRecord(12345)),
            _testPutRecord(_getRecord({ "x3" : "x4", "x5" : 123 }, "testPartitionKey", "54321"))
        ]);
    }

    function testPutRecordWithPrevSequenceNumber() {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecord(
                _getRecord("x1"),
                function (error, putRecordResult1) {
                    if (error) {
                        return reject(error.details);
                    }
                    _awsProducer.putRecord(
                        _getRecord("x2", null, null, putRecordResult1.sequenceNumber),
                        function (error, putRecordResult2) {
                            if (error) {
                                return reject(error.details);
                            }
                            _awsProducer.putRecord(
                                _getRecord("x3", null, "12345", putRecordResult2.sequenceNumber),
                                function (error, putRecordResult3) {
                                    if (error) {
                                        return reject(error.details);
                                    }
                                    return resolve("");
                                }.bindenv(this));
                        }.bindenv(this));
                }.bindenv(this));
        }.bindenv(this));
    }
    
    function testPutRecords() {
        return Promise.all([
            _testPutRecords([_getRecord("")]),
            _testPutRecords([_getRecord(null), _getRecord(true, "testPartitionKey")]),
            _testPutRecords([_getRecord("abc"), _getRecord(12345)]),
            _testPutRecords([
                _getRecord([]),
                _getRecord(["x1", "x2"], "testPartitionKey"),
                _getRecord({}),
                _getRecord({ "x3" : "x4", "x5" : 123 })
            ])
        ]);
    }

    function testPutBlobRecords() {
        local tstBlob = blob();
        tstBlob.writestring("testString");
        return Promise.all([
            _testPutRecords([_getRecord(blob())]),
            _testPutRecords([_getRecord(tstBlob), _getRecord(blob(), "testPartitionKey")]),
        ]);
    }

    function testPutRecordsWithExplicitHashKey() {
        return Promise.all([
            _testPutRecords([_getRecord("abc", null, "12345"), _getRecord(12345)]),
            _testPutRecords([_getRecord({ "x3" : "x4", "x5" : 123 }, "testPartitionKey", "54321")])
        ]);
    }

    function _getRecord(data, partitionKey = null, explicitHashKey = null, prevSequenceNumber = null) {
        _counter++;
        if (!partitionKey) {
            partitionKey = "testPartitionKey" + _counter
        }
        if (explicitHashKey || prevSequenceNumber) {
            return AWSKinesisStreams.Record(data, partitionKey, explicitHashKey, prevSequenceNumber);
        } else {
            return AWSKinesisStreams.Record(data, partitionKey);
        }
    }

    function _testPutRecord(record) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecord(record, function (error, putRecordResult) {
                if (error) {
                    return reject(error.details);
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    function _testPutRecords(records) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecords(records, function (error, failedRecordCount, putRecordsResult) {
                if (error) {
                    return reject(error.details);
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }
}
