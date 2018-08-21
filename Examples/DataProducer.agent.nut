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
#require "AWSKinesisStreams.agent.lib.nut:1.1.0"

// AWSKinesisStreams.Producer library sample. 
// Periodically writes data records to the specified preconfigured AWS Kinesis Stream
// using both putRecord() and putRecords() library methods.
// Data are written every 10 seconds, they consist of integer increasing value and 
// origin attribute which contains the method used to write data (putRecord/putRecords).

const WRITE_DATA_PERIOD_SEC = 10.0;

class DataProducer {
    _counter = 0;
    _awsProducer = null;
    _writeSingleRecord = null;

    constructor(awsRegion, awsAccessKeyId, awsSecretAccessKey, awsKinesisStreamName) {
        _awsProducer = AWSKinesisStreams.Producer(
            awsRegion, awsAccessKeyId, awsSecretAccessKey, awsKinesisStreamName);
        _writeSingleRecord = true;
    }

    // Returns AWSKinesisStreams.Record instance to be written
    function getData(isMultiple) {
        _counter++;
        local body = {
            "value" : _counter,
            "origin" : isMultiple ? "putRecords" : "putRecord"
        };
        return AWSKinesisStreams.Record(body, "testPartitionKey");
    }

    // Writes single record to the AWS Kinesis Stream using AWSKinesisStreams.Producer putRecord() library method
    function writeRecord() {
        local record = getData(false);
        _awsProducer.putRecord(
            record,
            function (error, putResult) {
                if (error) {
                    server.error("Data writing failed: " + error.details);
                } else {
                    server.log("Data written successfully:");
                    server.log(http.jsonencode(record.data));
                }
            }.bindenv(this));
    }

    // Writes multiple records to the AWS Kinesis Stream using AWSKinesisStreams.Producer putRecords() library method
    function writeMultipleRecords() {
        local records = [getData(true), getData(true)];
        _awsProducer.putRecords(
            records,
            function (error, failedRecordCount, putResults) {
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
                    server.log("Data written successfully:");
                    foreach (record in records) {
                        server.log(http.jsonencode(record.data));
                    }
                }
            }.bindenv(this));
    }

    // Periodically writes data records to the AWS Kinesis Stream
    function writeData() {
        if (_writeSingleRecord) {
            writeRecord();
        } else {
            writeMultipleRecords();
        }
        _writeSingleRecord = !_writeSingleRecord;

        imp.wakeup(WRITE_DATA_PERIOD_SEC, writeData.bindenv(this));
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
dataProducer <- DataProducer(
    AWS_KINESIS_REGION, AWS_KINESIS_ACCESS_KEY_ID, AWS_KINESIS_SECRET_ACCESS_KEY, AWS_KINESIS_STREAM_NAME);
dataProducer.writeData();
