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
package org.apache.brooklyn.core.dsl.external;

import static org.apache.brooklyn.KarafTestUtils.defaultOptionsWith;
import static org.apache.brooklyn.util.osgi.OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_SYMBOLIC_NAME_FULL;
import static org.apache.brooklyn.util.osgi.OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_VERSION;
import static org.ops4j.pax.exam.CoreOptions.streamBundle;
import static org.ops4j.pax.exam.CoreOptions.systemProperties;
import static org.ops4j.pax.exam.CoreOptions.systemProperty;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.editConfigurationFilePut;

import java.io.InputStream;

import javax.inject.Inject;

import org.apache.brooklyn.api.mgmt.ManagementContext;
import org.apache.brooklyn.core.config.ConfigKeys;
import org.apache.brooklyn.core.mgmt.internal.ManagementContextInternal;
import org.apache.brooklyn.util.core.osgi.Osgis;
import org.apache.brooklyn.util.guava.Maybe;
import org.apache.brooklyn.util.osgi.OsgiTestResources;
import org.apache.karaf.features.BootFinished;
import org.apache.karaf.features.FeaturesService;
import org.junit.Assert;
import org.junit.Assume;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerMethod;
import org.ops4j.pax.exam.util.Filter;
import org.osgi.framework.Bundle;
import org.osgi.service.cm.ConfigurationAdmin;

@RunWith(PaxExam.class)
@ExamReactorStrategy(PerMethod.class)
public class ExternalConfigBrooklynPropertiesOsgiTest {

    @Inject
    @Filter(timeout = 120000)
    protected FeaturesService featuresService;

    @Inject
    @Filter(timeout = 120000)
    protected ConfigurationAdmin configAdmin;

    @Inject
    @Filter(timeout = 120000)
    protected ManagementContext managementContext;

    /**
     * To make sure the tests run only when the boot features are fully
     * installed
     */
    @Inject
    @Filter(timeout = 120000)
    BootFinished bootFinished;

    @Configuration
    public static Option[] configuration() throws Exception {
        InputStream entityBundle = ExternalConfigBrooklynPropertiesOsgiTest.class.getResourceAsStream(OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_PATH);
        InputStream entityPrefixedBundle = ExternalConfigBrooklynPropertiesOsgiTest.class.getResourceAsStream(OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_COM_EXAMPLE_PATH);

        if (entityBundle == null || entityPrefixedBundle == null) {
            return defaultOptionsWith(
                    editConfigurationFilePut("etc/org.apache.brooklyn.osgilauncher.cfg", "globalBrooklynPropertiesFile", ""),
                    editConfigurationFilePut("etc/org.apache.brooklyn.osgilauncher.cfg", "localBrooklynPropertiesFile", "")
//                    // Uncomment this for remote debugging the tests on port 5005
//                    , KarafDistributionOption.debugConfiguration()
            );
        }

        Assume.assumeNotNull(entityBundle, entityPrefixedBundle);

        return defaultOptionsWith(
                editConfigurationFilePut("etc/org.apache.brooklyn.osgilauncher.cfg", "globalBrooklynPropertiesFile", ""),
                editConfigurationFilePut("etc/org.apache.brooklyn.osgilauncher.cfg", "localBrooklynPropertiesFile", ""),

                // The dummy providers simply return the key name as the value
                editConfigurationFilePut("etc/brooklyn.cfg", "brooklyn.external.unprefixedprovider", OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_UNPREFIXED_DUMMY_EXTERNAL_CONFIG_SUPPLIER),
                editConfigurationFilePut("etc/brooklyn.cfg", "unprefixedproperty", "$brooklyn:external(\"unprefixedprovider\", \"unprefixedvalue\")"),
                systemProperties(systemProperty("org.apache.brooklyn.classloader.fallback.bundles").value(BROOKLYN_TEST_OSGI_ENTITIES_SYMBOLIC_NAME_FULL + ":" + BROOKLYN_TEST_OSGI_ENTITIES_VERSION)),
                streamBundle(entityBundle),

                editConfigurationFilePut("etc/brooklyn.cfg", "brooklyn.external.prefixedprovider",
                        OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_COM_EXAMPLE_SYMBOLIC_NAME_FULL + ":" +
                        OsgiTestResources.BROOKLYN_TEST_OSGI_ENTITIES_PREFIXED_DUMMY_EXTERNAL_CONFIG_SUPPLIER),
                editConfigurationFilePut("etc/brooklyn.cfg", "myproperty", "$brooklyn:external(\"prefixedprovider\", \"myvalue\")"),
                streamBundle(entityPrefixedBundle)

//                // Uncomment this for remote debugging the tests on port 5005
//                , KarafDistributionOption.debugConfiguration()
        );
    }

    @Before
    public void beforeMethod() {
        Maybe<Bundle> bundle = Osgis.bundleFinder(((ManagementContextInternal)managementContext).getOsgiManager().get().getFramework())
                .symbolicName(BROOKLYN_TEST_OSGI_ENTITIES_SYMBOLIC_NAME_FULL)
                .find();

        Maybe<Bundle> prefixedBundle = Osgis.bundleFinder(((ManagementContextInternal)managementContext).getOsgiManager().get().getFramework())
                .symbolicName(BROOKLYN_TEST_OSGI_ENTITIES_SYMBOLIC_NAME_FULL)
                .find();

        Assume.assumeTrue(bundle.isPresent());
        Assume.assumeTrue(prefixedBundle.isPresent());
    }

    @Test
    public void testOSGIWithPrefix() throws Exception {
        Assert.assertEquals("unprefixedvalue", managementContext.getConfig().getConfig(ConfigKeys.newStringConfigKey("unprefixedproperty")));
        Assert.assertEquals("myvalue", managementContext.getConfig().getConfig(ConfigKeys.newStringConfigKey("myproperty")));
    }

}
