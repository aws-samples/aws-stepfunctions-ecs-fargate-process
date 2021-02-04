package com.example.Model;

/*
 * SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 *
 * SPDX-License-Identifier: MIT-0
 */
public class Product
{
    public String productId;
    public String productName;
    public String productVersion;

    public String getProductId(){
        return productId;
    }

    public String getProductName(){
        return productName;
    }
    public String getProductVersion(){
        return productVersion;
    }

    public void setProductId(String productId){
        this.productId = productId;
    }

    public void setProductName(String productName){
        this.productName = productName;
    }
    public void setProductVersion(String productVersion){
        this.productVersion = productVersion;
    }
}