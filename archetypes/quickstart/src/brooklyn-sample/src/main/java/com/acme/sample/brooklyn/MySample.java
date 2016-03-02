package com.acme.sample.brooklyn;

import org.apache.brooklyn.api.entity.Entity;
import org.apache.brooklyn.api.entity.ImplementedBy;
import org.apache.brooklyn.api.sensor.AttributeSensor;
import org.apache.brooklyn.config.ConfigKey;
import org.apache.brooklyn.core.annotation.Effector;
import org.apache.brooklyn.core.annotation.EffectorParam;
import org.apache.brooklyn.core.config.ConfigKeys;
import org.apache.brooklyn.core.entity.trait.Startable;
import org.apache.brooklyn.core.sensor.Sensors;

/**
 * A simple entity, which demonstrates some of the things that can be done in Java when
 * implementing an entity.
 * 
 * Note the {@link ImplementedBy} annotation, which points at the class to be instantiated
 * for this entity type.
 */
@ImplementedBy(MySampleImpl.class)
public interface MySample extends Entity, Startable {
    
    ConfigKey<String> MY_CONF = ConfigKeys.newStringConfigKey(
            "myConf", 
            "My example config key", 
            "defaultval");

    AttributeSensor<String> LAST_CALL = Sensors.newStringSensor(
            "lastCall", 
            "Example sensor, showing the last effector call");

    /**
     * Declares an effector. The annotation marks this as an effector, so the effector will
     * be automatically wired up to the method's implementation.
     */
    @Effector(description="My example effector")
    void myEffector(@EffectorParam(name="arg1") String arg1);
}
