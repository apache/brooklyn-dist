package com.acme.sample.brooklyn;

import java.util.Collection;

import org.apache.brooklyn.api.location.Location;
import org.apache.brooklyn.core.entity.AbstractEntity;
import org.apache.brooklyn.core.entity.lifecycle.Lifecycle;
import org.apache.brooklyn.core.entity.lifecycle.ServiceStateLogic;
import org.apache.brooklyn.core.entity.lifecycle.ServiceStateLogic.ServiceNotUpLogic;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The entity's implementation. It is normal to extend one of the pre-existing superclasses
 * such as the most basic {@link AbstractEntity} or (for a software process being installed)
 * a {@link org.apache.brooklyn.entity.software.base.SoftwareProcessImpl}. However, for the 
 * latter it is strongly encouraged to instead consider using YAML-based blueprints.
 * 
 * The service.isUp and service.state sensors are populated by using the {@link ServiceNotUpLogic}
 * and {@link ServiceStateLogic} utilities. A simpler (less powerful) way is to directly set
 * the sensors {@link org.apache.brooklyn.core.entity.Attributes#SERVICE_UP} and
 * {@link org.apache.brooklyn.core.entity.Attributes#SERVICE_STATE_ACTUAL}. The advantage
 * of the {@link ServiceNotUpLogic} is that multiple indicators can be used, all of which
 * must be satisfied for the service to be considered healthy. For example, it might be required
 * that a web-app's URL is reachable and also that the app-server's management API reports 
 * healthy.
 */
public class MySampleImpl extends AbstractEntity implements MySample {

    private static final Logger LOG = LoggerFactory.getLogger(MySampleImpl.class);
    
    @Override
    public void init() {
        super.init();
        LOG.info("MySampleImpl.init() with config {}", config().get(MY_CONF));
        ServiceNotUpLogic.updateNotUpIndicator(this, "started", "not started");
    }
    
    @Override
    protected void initEnrichers() {
    	super.initEnrichers();
    }
    
    @Override
    public void start(Collection<? extends Location> locs) {
        LOG.info("MySampleImpl.start({})", locs);
        sensors().set(LAST_CALL, "start");
        ServiceNotUpLogic.clearNotUpIndicator(this, "started");
        ServiceStateLogic.setExpectedState(this, Lifecycle.RUNNING);
    }
    
    @Override
    public void stop() {
        LOG.info("MySampleImpl.stop()");
        sensors().set(LAST_CALL, "stop");
        ServiceStateLogic.setExpectedState(this, Lifecycle.STOPPED);
        ServiceNotUpLogic.updateNotUpIndicator(this, "started", "stopped");
    }
    
    @Override
    public void restart() {
        LOG.info("MySampleImpl.restart()");
        sensors().set(LAST_CALL, "restart");
        ServiceStateLogic.setExpectedState(this, Lifecycle.STOPPED);
        ServiceStateLogic.setExpectedState(this, Lifecycle.RUNNING);
    }
    
    @Override
    public void myEffector(String arg1) {
        LOG.info("MySampleImpl.myEffector({})", arg1);
        sensors().set(LAST_CALL, "myEffector("+arg1+")");
    }
    
}
