package com.acme.sample.brooklyn;

import static org.testng.Assert.assertEquals;

import org.apache.brooklyn.api.entity.Entity;
import org.apache.brooklyn.camp.brooklyn.AbstractYamlTest;
import org.apache.brooklyn.core.entity.Attributes;
import org.apache.brooklyn.core.entity.Entities;
import org.apache.brooklyn.core.entity.EntityAsserts;
import org.apache.brooklyn.util.core.ResourceUtils;
import org.testng.annotations.Test;

import com.google.common.base.Joiner;
import com.google.common.collect.Iterables;

public class MySampleYamlTest extends AbstractYamlTest {

    @Test
    public void testEntity() throws Exception {
        String yaml = Joiner.on("\n").join(
            "name: my test",
            "services:",
            "- type: com.acme.sample.brooklyn.MySample",
            "  brooklyn.config:",
            "    myConf: myConfVal");
        
        Entity app = createAndStartApplication(yaml);
        waitForApplicationTasks(app);

        Entities.dumpInfo(app);

        MySample entity = (MySample) Iterables.getOnlyElement(app.getChildren());
        assertEquals(entity.config().get(MySample.MY_CONF), "myConfVal");
    }
    
    @Test
    public void testUsingTestFramework() throws Exception {
    	String yaml = ResourceUtils.create().getResourceAsString("classpath://sample-test.yaml");
        
        Entity app = createAndStartApplication(yaml);
        waitForApplicationTasks(app);

        Entities.dumpInfo(app);

        EntityAsserts.assertAttributeEqualsEventually(app, Attributes.SERVICE_UP, true);
    }
    
    /**
     * For this to pass, the sample.bom's library URL needs to be updated, to point at
     * the jar built using {@code mvn clean install} on this project.
     * 
     * The group "WIP" (short for "work in progress") disables this test when run by maven.
     */
    @Test(groups="WIP")
    public void testViaCatalog() throws Exception {
    	String catalogYaml = ResourceUtils.create().getResourceAsString("classpath://sample.bom");
        
    	addCatalogItems(catalogYaml);
    	
        String blueprintYaml = Joiner.on("\n").join(
                "name: my test",
                "services:",
                "- type: com.acme.sample.brooklyn.MySampleInCatalog:1.0");
        
        Entity app = createAndStartApplication(blueprintYaml);
        waitForApplicationTasks(app);

        Entities.dumpInfo(app);

        MySample entity = (MySample) Iterables.getOnlyElement(app.getChildren());
        EntityAsserts.assertAttributeEqualsEventually(entity, Attributes.SERVICE_UP, true);
    }
}
