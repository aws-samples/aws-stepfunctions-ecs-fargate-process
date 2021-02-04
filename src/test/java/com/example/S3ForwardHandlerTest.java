package com.example;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.internal.verification.VerificationModeFactory.times;
import static org.powermock.api.mockito.PowerMockito.doReturn;
import static org.powermock.api.mockito.PowerMockito.mockStatic;
import static org.powermock.api.mockito.PowerMockito.when;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3Client;
import com.amazonaws.services.s3.model.ListObjectsV2Result;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.S3ObjectSummary;
import org.junit.Before;
import org.junit.Test;


import com.example.Model.Product;
import com.example.Utils.DataProcessor;
import com.google.gson.Gson;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;

/*
 * SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 *
 * SPDX-License-Identifier: MIT-0
 */
@RunWith(PowerMockRunner.class)
public class S3ForwardHandlerTest {
    AmazonS3 s3Client = Mockito.mock(AmazonS3.class);

    AmazonKinesis kinesisClient = Mockito.mock(AmazonKinesis.class);

    Gson gson;

    private Product inputProduct;
    private String TEST_OUTPUT = "{\"productId\":\"1\",\"productName\":\"iphone\",\"productVersion\":\"10R\"}";
    private List<Product> products = new ArrayList<>();

    S3ForwardHandler s3ForwardHandler;

    @Before
    public void setup() throws Exception{
        gson = new Gson();

        inputProduct = new Product();
        inputProduct.setProductId("1");

        Product product = new Product();
        product.setProductId("1");
        product.setProductName("iphone");
        product.setProductVersion("10R");
        products.add(product);

        ListObjectsV2Result results = new ListObjectsV2Result();
        List<S3ObjectSummary> objectSummaries = new ArrayList();
        S3ObjectSummary s3ObjectSummary = new S3ObjectSummary();
        s3ObjectSummary.setKey("sample.txt");
        objectSummaries.add(s3ObjectSummary);
        S3Object object = new S3Object();
        String initialString = "text";
        InputStream inputStream = new ByteArrayInputStream(initialString.getBytes());
        //object.setObjectContent(inputStream);
        PowerMockito.when(s3Client.listObjectsV2(anyString())).thenReturn(results);
        PowerMockito.when(s3Client.getObject(anyString(), anyString())).thenReturn(object);
        s3ForwardHandler = new S3ForwardHandler("test-region", "test-bucket", "test-stream", s3Client, kinesisClient, gson);
    }

    @Test
    public void saveS3_validRequest_Success() throws IOException {

        s3ForwardHandler.handleRequest(null, null);
        verify(s3Client, times(0)).listObjectsV2(any(), any());
        verify(s3Client, times(0)).getObject(anyString(), anyString());

    }


}