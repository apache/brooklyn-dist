package com.acme.sample.brooklyn;

import static org.testng.Assert.assertEquals;

import org.apache.brooklyn.api.entity.EntitySpec;
import org.apache.brooklyn.api.location.Location;
import org.apache.brooklyn.core.entity.Attributes;
import org.apache.brooklyn.core.entity.EntityAsserts;
import org.apache.brooklyn.core.entity.lifecycle.Lifecycle;
import org.apache.brooklyn.core.test.BrooklynAppUnitTestSupport;
import org.testng.annotations.Test;

import com.acme.sample.brooklyn.MySample;
import com.google.common.collect.ImmutableList;

public class MySampleTest extends BrooklynAppUnitTestSupport {

    @Test
    public void testEntity() throws Exception {
        MySample entity = app.createAndManageChild(EntitySpec.create(MySample.class)
                .configure(MySample.MY_CONF, "myConfVal"));
        
        app.start(ImmutableList.<Location>of());
        assertEquals(entity.sensors().get(MySample.LAST_CALL), "start");
        EntityAsserts.assertAttributeEqualsEventually(entity, Attributes.SERVICE_UP, true);
        EntityAsserts.assertAttributeEqualsEventually(entity, Attributes.SERVICE_STATE_ACTUAL, Lifecycle.RUNNING);
        
        entity.myEffector("myArgVal");
        assertEquals(entity.sensors().get(MySample.LAST_CALL), "myEffector(myArgVal)");
        
        app.stop();
        assertEquals(entity.sensors().get(MySample.LAST_CALL), "stop");
        EntityAsserts.assertAttributeEqualsEventually(entity, Attributes.SERVICE_UP, false);
        EntityAsserts.assertAttributeEqualsEventually(entity, Attributes.SERVICE_STATE_ACTUAL, Lifecycle.STOPPED);
    }
}
