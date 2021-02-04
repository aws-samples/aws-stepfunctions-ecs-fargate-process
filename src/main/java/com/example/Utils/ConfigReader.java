package com.example.Utils;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/*
 * SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 *
 * SPDX-License-Identifier: MIT-0
 */
public class ConfigReader {
    private static Properties prop;

    static{
        InputStream inputStream = null;
        try {
            prop = new Properties();
            inputStream = ClassLoader.class.getResourceAsStream("/application.properties");
            prop.load(inputStream);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static String getPropertyValue(String key){
        return prop.getProperty(key);
    }
}
