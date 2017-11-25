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

// Test case for wrong parameters of AWSKinesisStreams.Producer library methods.
class WrongParamsProducerTestCase extends ImpTestCase {
    _awsProducer = null;

    function setUp() {
        _awsProducer = AWSKinesisStreams.Producer(
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

    function testWrongTypeRecord() {
        return Promise.all([
            _testWrongTypeRecord(null),
            _testWrongTypeRecord("abc"),
            _testWrongTypeRecord(123),
            _testWrongTypeRecord({ "val" : "123" }),
            _testWrongTypeRecord(AWSKinesisStreams.PutRecordResult())
        ]);
    }

    function testWrongTypeRecords() {
        return Promise.all([
            _testWrongTypeRecords(null),
            _testWrongTypeRecords("abc"),
            _testWrongTypeRecords(123),
            _testWrongTypeRecords({ "val" : "123" }),
            _testWrongTypeRecords([]),
            _testWrongTypeRecords(["abc", "def"]),
            _testWrongTypeRecords([{ "val" : "123" }]),
            _testWrongTypeRecords([AWSKinesisStreams.PutRecordResult()])
        ]);
    }

    function _testWrongInitialParams(region, accessKeyId, secretAccessKey, streamName) {
        local awsProducer = AWSKinesisStreams.Producer(
            region, accessKeyId, secretAccessKey, streamName);
        return Promise(function (resolve, reject) {
            awsProducer.putRecord(AWSKinesisStreams.Record({}, "testPartitionKey"), function (error, putRecordResult) {
                if (!_isLibraryError(error)) {
                    return reject("Wrong initial param accepted in in putRecord");
                }
                awsProducer.putRecords(
                    [AWSKinesisStreams.Record({}, "testPartitionKey")],
                    function (error, failedRecordCount, putRecordsResult) {
                        if (!_isLibraryError(error)) {
                            return reject("Wrong initial param accepted in putRecords");
                        }
                        return resolve("");
                    }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _testWrongTypeRecord(record) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecord({ "val" : "123" }, function (error, putRecordResult) {
                if (!_isLibraryError(error)) {
                    return reject("Wrong record in putRecord accepted: '" + http.jsonencode(record) + "'");
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    function _testWrongTypeRecords(records) {
        return Promise(function (resolve, reject) {
            _awsProducer.putRecords(records, function (error, failedRecordCount, putRecordsResult) {
                if (!_isLibraryError(error)) {
                    return reject("Wrong records in putRecords accepted: '" + http.jsonencode(records) + "'");
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == AWS_KINESIS_STREAMS_ERROR.LIBRARY_ERROR;
    }
}
