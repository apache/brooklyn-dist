/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.brooklyn.security;

import static org.apache.brooklyn.KarafTestUtils.defaultOptionsWith;
import static org.junit.Assert.assertEquals;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.editConfigurationFilePut;

import java.io.IOException;
import java.util.concurrent.Callable;

import javax.inject.Inject;

import org.apache.brooklyn.api.mgmt.ManagementContext;
import org.apache.brooklyn.core.internal.BrooklynProperties;
import org.apache.brooklyn.rest.BrooklynWebConfig;
import org.apache.brooklyn.rest.security.provider.ExplicitUsersSecurityProvider;
import org.apache.brooklyn.test.Asserts;
import org.apache.brooklyn.test.IntegrationTest;
import org.apache.http.HttpStatus;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.karaf.features.BootFinished;
import org.junit.Before;
import org.junit.Test;
import org.junit.experimental.categories.Category;
import org.junit.runner.RunWith;
import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.Filter;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
@Category(IntegrationTest.class)
public class StockSecurityProviderTest {

    private static final String USER = "admin";
    private static final String PASSWORD = "password";

    /**
     * To make sure the tests run only when the boot features are fully
     * installed
     */
    @Inject
    @Filter(timeout = 120000)
    BootFinished bootFinished;
    
    @Inject
    @Filter(timeout = 120000)
    ManagementContext managementContext;

    @Configuration
    public static Option[] configuration() throws Exception {
        return defaultOptionsWith(
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_CLASSNAME.getName(), ExplicitUsersSecurityProvider.class.getCanonicalName()),
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_CLASSNAME.getName()+".users", USER),
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_CLASSNAME.getName()+".user."+USER, PASSWORD)

            // Uncomment this for remote debugging the tests on port 5005
            // KarafDistributionOption.debugConfiguration()
        );
    }

    @Before
    public void setUp() {
        //Works only before initializing the security provider (i.e. before first use)
        addUser(USER, PASSWORD);
    }

    @Test
    public void checkRestSecurityFails() throws IOException {
        checkSecurity(null, null, HttpStatus.SC_UNAUTHORIZED);
    }

    @Test
    public void checkRestSecuritySucceeds() throws IOException {
        checkSecurity(USER, PASSWORD, HttpStatus.SC_OK);
    }

    static void checkSecurity(String username, String password, final int code) throws IOException {
        CredentialsProvider credentialsProvider = new BasicCredentialsProvider();
        if (username != null && password != null) {
            credentialsProvider.setCredentials(AuthScope.ANY, new UsernamePasswordCredentials(username, password));
        }
        try(CloseableHttpClient client =
            HttpClientBuilder.create().setDefaultCredentialsProvider(credentialsProvider).build()) {
            Asserts.succeedsEventually(new Callable<Void>() {
                @Override
                public Void call() throws Exception {
                    assertResponseEquals(urlBase()+"/v1/server/ha/state", client, code);
                    assertResponseEquals(urlBase()+"/", client, code);
                    assertResponseEquals(urlBase()+"/brooklyn-ui-catalog", client, code);
                    return null;
                }
            });
        }
    }

    // TODO get this dynamically (from CXF service?)
    // TODO port is static, should make it dynamic
    private static String urlBase() { return "http://localhost:8081"; }
    
    private static void assertResponseEquals(String url, CloseableHttpClient httpclient, int code) throws IOException, ClientProtocolException {
        HttpGet httpGet = new HttpGet(url);
        try (CloseableHttpResponse response = httpclient.execute(httpGet)) {
            assertEquals(code, response.getStatusLine().getStatusCode());
        }
    }
    

    private void addUser(String username, String password) {
        // TODO Dirty hack to inject the needed properties. Improve once managementContext is configurable.
        // Alternatively re-register a test managementContext service (how?)
        BrooklynProperties brooklynProperties = (BrooklynProperties)managementContext.getConfig();
        brooklynProperties.put(BrooklynWebConfig.SECURITY_PROVIDER_CLASSNAME.getName(), ExplicitUsersSecurityProvider.class.getCanonicalName());
        brooklynProperties.put(BrooklynWebConfig.USERS.getName(), username);
        brooklynProperties.put(BrooklynWebConfig.PASSWORD_FOR_USER(username), password);
    }

}
