brooklyn-sample
===

This is a Sample Brooklyn project, showing how to write a Java-based entity and 
build it as an OSGi bundle that can be used in a Brooklyn catalog.

This sample project is intended to be customized to suit your purposes: but
search for all lines containing the word "sample" or "acme" to make sure all the
references to this being a sample are removed!   

To easily find the bits you should customize, do a:

    grep -ri sample src/ *.*


### Building

To build an assembly, simply run:

    mvn clean install

This creates an OSGi bundle at:

    target/brooklyn-sample-0.1.0-SNAPSHOT.jar


### Opening in an IDE

To open this project in an IDE, you will need maven support enabled
(e.g. with the relevant plugin).  You should then be able to develop
it and run it as usual.  For more information on IDE support, visit:

    https://brooklyn.apache.org/v/latest/dev/env/ide/


### Brooklyn Catalog

The new blueprint can be added to the Brooklyn catalog using the `sample.bom` file.
located in `src/test/resources`. You will first have to copy the target jar to a suitable location,
and update the URL in `sample.bom` pointing at that jar.

The command below will use the REST api to add this to the catalog of a running Brooklyn instance:

    curl -u admin:pa55w0rd http://127.0.0.1:8081/v1/catalog --data-binary @src/test/resources/sample.bom

The YAML blueprint below shows an example usage of this blueprint:

    name: my sample
    services:
    - type: com.acme.sample.brooklyn.MySampleInCatalog:1.0


### Testing Entities

This project comes with unit tests that demonstrate how to test entities, both within Java and
also using YAML-based blueprints.

A strongly recommended way is to write a YAML test blueprint using the test framework, and making  
this available to anyone who will use your entity. This will allow users to easily run the test
blueprint in their own environment (simply by deploying it to their own Brooklyn server) to confirm 
that the entity is working as expected. An example is shown in `src/test/resources/sample-test.yaml`.


### More About Apache Brooklyn

Apache Brooklyn is a code library and framework for managing applications in a 
cloud-first dev-ops-y way.  It has been used to create this sample project 
which shows how to define an application and entities for Brooklyn.

For more information consider:

* Visiting the Apache Brooklyn home page at https://brooklyn.apache.org
* Finding us on IRC #brooklyncentral or email (click "Community" at the site above) 
* Forking the project at  http://github.com/apache/brooklyn/


### License

Please add your desired license to this project template.
