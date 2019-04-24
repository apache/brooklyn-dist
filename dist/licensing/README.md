
We use a special maven plugin and scripts to automatically create the LICENSE and NOTICE
files, including all notices, based on metadata in `license-*` files.

First install  https://github.com/ahgittin/license-audit-maven-plugin


# Quick Usage - Update LICENSE and NOTICE Files

Ensure all projects are at the right version and built.
Then in the `brooklyn-dist/dist/licensing` folder execute:

    ./generate-all.sh

This will generate updated LICENSE and NOTICE files everywhere that is needed. 
Compare the differences across all projects just to be sure and commit them.

For non-Java project changes there are extra steps.  Go, JS, jpegs, fonts, etc may require
special attention.  Some automation is available (particularly for modern JS code) in:

    ./update-brooklyn-license-metadata.sh


# Detailed Usage

If dependencies change, it may be necessary to supply new metadata.
First it is useful to know how these routines work.

It builds for various modes depending where the item is being used:

* The projects and JARs strictly speaking only require any 3rd party items
  included therein.  There usually aren't any (one exception is JS has been checked out
  locally).  Where these are required, they should be in a `license-inclusions-source-*` file.
  This mode is called `binary-omitted`. (For projects where there are no such inclusions,
  the build adds a stock Apache LICENSE and Apache Brooklyn NOTICE.)
  
* Because people will usually build these and need the resulting information, and
  because attribution is good, we include details of runtime dependencies in some places
  (e.g. the root of projects) in a separate section in the NOTICE. These dependencies can 
  be specified in files matching `license-inclusions-binary-*` (this is not needed for `mvn` 
  deps which are inferred automatically). This mode is called `binary-additional`.

* The TGZ includes third-party dependencies and so needs LICENSE and NOTICE updates
  for everything that is bundled, including all `license-inclusions-{source,binary}-*`. 
  This mode is called `binary-primary`.

The generation then proceeds by collecting the relevant `license-inclusions-*` under the project
directory, giving a list of project `id` fields, and collecting `license-metadata-*` files containing 
entries with the same `id` and other metadata. (The `license-metadata-*` allows metadata to be shared
across `id`s used in `license-inclusions` for many projects. The `license-metadata` files are usually 
in this directory, but if there is reasons they may be project-specific or even supplied in the
`license-inclusions` files.)

The generation invokes the `license-audit-maven-plugin:notices` mojo to generate YAML
for the dependencies. These are combined with text files (in `parts/`) to create the NOTICE file.
The NOTICE file is scanned for licenses and text pulled from `license-text/` to create the LICENSE file.

## Adding New Dependencies

Add the dependencies to the relevant `license-inclusions` file, and
add metadata to the relevant `license-metadata` file.  That's it.

Note that many of the dependencies are detected automatically, but their metadata might
not be perfectly inferred.  You can add/edit the corresponding items in `license-metadata`
to override the data that is detected automatically.

## Giving Attribution

Note that _most_ licenses require attribution. This is done through a `notice` block in the metadata.
When adding new dependencies, check whether the specific license includes a copyright notice.

## Adding New Licenses

If a new license is required, simply create a file named with the license name in `license-text/` 
containing the text of the license.  The license name can be set with a `license: { name: "..." }`
block in the corresponding `id` in `license-metadata`.

Note that most projects use one of a small number of licenses, but with custom attribution,
either a "Copyright" line in the license or an accompanying NOTICE file. In such cases you
should use the shared license (so it is easier for people to see that the sub-license is
acceptable to them), and put the attribution/notice in a `notice` block in the `license-metadata`,
as described above.

## New Source Projects

If creating a new project, check whether it requires special NOTICE / LICENSE files.
If so:

1. Create `license-inclusions-*` files as needed, usually in that project at `src/main/license/`
2. Add instructions to that project's POM to include `src/main/license/files/*`
3. Add the reference to the project in `generate-all.sh` 


## Other Tools

The command `mvn project-info-reports:dependencies` is a different tool for checking mvn dependencies;
compare the output at `target/site/dependencies.html` with the previous.

Similarly the `org.apache:apache-jar-resource-bundle` resource bundle computes and reports mvn dependencies
in a `META-INF/DEPENDENCIES` file placed into JARs.  This is not complete (but it is elegant how it works!). 


# Appendix - POM Setup

The usual process where a project has custom `NOTICE` and `LICENSE` for its _source_
is to write it to the root of that project, and where it is desired in the JAR or a build,
to use a POM config such as the following (note you must declare _all_ resources):

        <resources>
            <resource>
                <directory>${project.basedir}/src/main/resources</directory>
            </resource>
            <resource>
                <targetPath>META-INF</targetPath>
                <directory>${project.basedir}</directory>
                <includes>
                  <include>NOTICE</include>
                  <include>LICENSE</include>
                </includes>
            </resource>
        </resources>

This is necessary where there are embedded depenencies in the resulting JAR or built items.
It is not necessary, and typically not done, where there are no embedded dependencies, as the
`org.apache:apache-jar-resource-bundle` mojo will take the standard ASF files which are sufficient.

If a build needs a different set of files than the source for some artifact (e.g. because it is bundling
dependencies within it) they will usually be created to a separate folder, e.g. `src/main/license/files/MODE/`
and used by the build to add it with a variant of the POM fragment above.

A section such as the following will suppress the installation of default `NOTICE` and `LICENSE` files
(and `DEPENDENCIES`).  However it is not needed as the build installs our resources _after_, and it is
useful to keep because it means `-test-` resources get these files.

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-remote-resources-plugin</artifactId>
                <executions>
                    <execution>
                        <goals>
                            <goal>process</goal>
                        </goals>
                        <configuration>
                            <skip>true</skip>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
