package com.example.Utils;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.SdkClientException;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder;
import com.amazonaws.services.kinesis.model.PutRecordsRequest;
import com.amazonaws.services.kinesis.model.PutRecordsRequestEntry;
import com.amazonaws.services.kinesis.model.PutRecordsResult;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;

import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.ListObjectsV2Result;
import com.amazonaws.services.s3.model.S3ObjectSummary;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;

import java.io.*;
import java.nio.ByteBuffer;
import java.util.List;
import java.util.ArrayList;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import com.example.Model.Product;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/*
 * SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 *
 * SPDX-License-Identifier: MIT-0
 */
public class DataProcessor
{
    AmazonS3 s3Client;
    AmazonKinesis kinesisClient;
    Gson gson;

    public DataProcessor(String clientRegion){
        s3Client = AmazonS3ClientBuilder.standard()
                                        .withRegion(clientRegion)
                                        .build();
        AmazonKinesisClientBuilder clientBuilder = AmazonKinesisClientBuilder.standard();
        clientBuilder.setRegion(clientRegion);
        kinesisClient = clientBuilder.build();
        gson = new GsonBuilder().create();
    }
    public DataProcessor(AmazonS3 s3Client, AmazonKinesis kinesisClient, Gson gson){
        this.s3Client = s3Client;
        this.kinesisClient = kinesisClient;
        this.gson = gson;
    }

    public Void sendS3ContentsToKinesis(String clientRegion, String bucketName, String streamName)  throws IOException  {

        String key = "";
        if(clientRegion != null) {
            System.out.println("Fetching S3 file content.");
            ListObjectsV2Result result = s3Client.listObjectsV2(bucketName);
            List<S3ObjectSummary> objects = result.getObjectSummaries();

            for (S3ObjectSummary os : objects) {
                key = os.getKey();
                if (key.endsWith(".txt")) {
                    Product product = new Product();
                    System.out.println("S3 Object Key" + key);

                    S3Object object = s3Client.getObject(bucketName, key);
                    BufferedInputStream input = new BufferedInputStream(object.getObjectContent());
                    ByteArrayOutputStream output = new ByteArrayOutputStream();

                    byte[] b = new byte[1000 * 1024];
                    int len;
                    while ((len = input.read(b)) != -1) {
                        output.write(b, 0, len);
                    }
                    byte[] bytes = output.toByteArray();
                    String fileContent = new String(bytes, StandardCharsets.UTF_8);
                    Product savedProduct = gson.fromJson(fileContent, Product.class);
                    if(savedProduct != null && Integer.parseInt(savedProduct.getProductId()) > 0 ) {
                        System.out.println("Processing Product ID - " + savedProduct.getProductId());
                        sendToKinesis(clientRegion, streamName, fileContent);
                    }
                }
            }
        }
        return null;
    }

    private void sendToKinesis(String clientRegion, String streamName, String contents){
        if(clientRegion != null) {
            System.out.println("Sending to Kinesis.");
            PutRecordsRequest putRecordsRequest  = new PutRecordsRequest();
            putRecordsRequest.setStreamName(streamName);
            List <PutRecordsRequestEntry> putRecordsRequestEntryList  = new ArrayList<>();
            PutRecordsRequestEntry putRecordsRequestEntry  = new PutRecordsRequestEntry();
            putRecordsRequestEntry.setData(ByteBuffer.wrap(contents.getBytes()));
            UUID uuid = UUID.randomUUID();
            putRecordsRequestEntry.setPartitionKey(uuid.toString());
            putRecordsRequestEntryList.add(putRecordsRequestEntry);

            putRecordsRequest.setRecords(putRecordsRequestEntryList);
            PutRecordsResult putRecordsResult  = kinesisClient.putRecords(putRecordsRequest);
            System.out.println("Put Result" + putRecordsResult);
        }
    }
}