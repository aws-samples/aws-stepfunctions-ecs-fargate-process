package com.example;

import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.util.StringUtils;
import com.example.Utils.ConfigReader;
import com.example.Utils.DataProcessor;
import com.google.gson.Gson;

import java.io.IOException;

/*
 * SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 *
 * SPDX-License-Identifier: MIT-0
 */
public class S3ForwardHandler implements RequestHandler<ScheduledEvent, Object> {

    String clientRegion = "";
    String bucketName = "";
    String kinesisStream = "";
    DataProcessor dataProcessor;

    public S3ForwardHandler() {
        this.clientRegion = System.getenv("REGION");
        this.bucketName = System.getenv("S3_BUCKET");
        this.kinesisStream = System.getenv("STREAM_NAME");
        if(StringUtils.isNullOrEmpty(this.clientRegion)){
            this.clientRegion = ConfigReader.getPropertyValue("REGION");
            this.bucketName = ConfigReader.getPropertyValue("S3_BUCKET");
            this.kinesisStream = ConfigReader.getPropertyValue("STREAM_NAME");
            System.out.println(String.format("Default Constructor ConfigReader - Client Region: %s, Bucket Name: %s, Stream Name: %s", this.clientRegion, this.bucketName, this.kinesisStream));
        }
        dataProcessor = new DataProcessor(this.clientRegion);
        System.out.println(String.format("Default Constructor - Client Region: %s, Bucket Name: %s, Stream Name: %s", this.clientRegion, this.bucketName, this.kinesisStream));
    }

    public S3ForwardHandler(String clientRegion, String bucketName, String kinesisStream, AmazonS3 s3Client, AmazonKinesis kinesisClient, Gson gson) {
        this.clientRegion = clientRegion;
        this.bucketName = bucketName;
        this.kinesisStream = kinesisStream;
        if(StringUtils.isNullOrEmpty(this.clientRegion)){
            this.clientRegion = ConfigReader.getPropertyValue("REGION");
            this.bucketName = ConfigReader.getPropertyValue("S3_BUCKET");
            this.kinesisStream = ConfigReader.getPropertyValue("STREAM_NAME");
            System.out.println(String.format("Default Constructor ConfigReader - Client Region: %s, Bucket Name: %s, Stream Name: %s", this.clientRegion, this.bucketName, this.kinesisStream));
        }
        dataProcessor = new DataProcessor(s3Client, kinesisClient, gson);
        System.out.println(String.format("Test Constructor - Client Region: %s, Bucket Name: %s, Stream Name: %s", this.clientRegion, this.bucketName, this.kinesisStream));
    }

    @Override
    public Object handleRequest(ScheduledEvent input, Context context) {

        String success_response = "Processing S3 Forward Handler ";
        System.out.println(success_response);

        try {
            dataProcessor.sendS3ContentsToKinesis(clientRegion, bucketName, kinesisStream);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;

    }

    public static void main(String[] args) {
        new S3ForwardHandler().handleRequest(new ScheduledEvent(), null);
    }
}