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
import static org.ops4j.pax.exam.CoreOptions.streamBundle;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.editConfigurationFilePut;

import java.io.IOException;

import javax.inject.Inject;

import org.apache.brooklyn.api.mgmt.ManagementContext;
import org.apache.brooklyn.rest.BrooklynWebConfig;
import org.apache.brooklyn.test.IntegrationTest;
import org.apache.brooklyn.util.text.Identifiers;
import org.apache.http.HttpStatus;
import org.apache.karaf.features.BootFinished;
import org.junit.Test;
import org.junit.experimental.categories.Category;
import org.junit.runner.RunWith;
import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.Filter;
import org.ops4j.pax.tinybundles.core.TinyBundles;
import org.osgi.framework.Constants;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
@Category(IntegrationTest.class)
public class CustomSecurityProviderTest {
    
    private static final String NEW_SECURITY_TEST_BUNDLE = "org.apache.brooklyn.test.security";
    private static final String NEW_SECURITY_TEST_BUNDLE_VERSION = "1.0.0";

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
            streamBundle(TinyBundles.bundle()
                .add(CustomSecurityProvider.class)
                .set(Constants.BUNDLE_MANIFESTVERSION, "2") // defaults to 1 which doesn't work
                .set(Constants.BUNDLE_SYMBOLICNAME, NEW_SECURITY_TEST_BUNDLE)
                .set(Constants.BUNDLE_VERSION, NEW_SECURITY_TEST_BUNDLE_VERSION)
                .set(Constants.DYNAMICIMPORT_PACKAGE, "*")
                .set(Constants.EXPORT_PACKAGE, CustomSecurityProvider.class.getPackage().getName())
                .build()),
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_CLASSNAME.getName(), CustomSecurityProvider.class.getCanonicalName()),
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_BUNDLE.getName(), NEW_SECURITY_TEST_BUNDLE),
            editConfigurationFilePut("etc/brooklyn.cfg", 
                BrooklynWebConfig.SECURITY_PROVIDER_BUNDLE_VERSION.getName(), NEW_SECURITY_TEST_BUNDLE_VERSION)
            // Uncomment this for remote debugging the tests on port 5005
            // ,KarafDistributionOption.debugConfiguration()
        );
    }

    @Test
    public void checkRestSecurityNoUserFails() throws IOException {
        StockSecurityProviderTest.checkSecurity(null, null, HttpStatus.SC_UNAUTHORIZED);
    }

    @Test
    public void checkRestSecurityWrongUserFails() throws IOException {
        StockSecurityProviderTest.checkSecurity("admin", "password", HttpStatus.SC_UNAUTHORIZED);
    }

    @Test
    public void checkRestSecuritySucceeds() throws IOException {
        StockSecurityProviderTest.checkSecurity(CustomSecurityProvider.USER, "any-password-"+Identifiers.makeRandomId(2), HttpStatus.SC_OK);
    }

}
