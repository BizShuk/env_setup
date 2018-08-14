# Jenkins with Gitlab


### Installation

1. install JDK, make sure there is a dir for JAVA_HOME
2. get Apache Tomcat 
3. get Jenkins war file and put it in tomcat/webapps
4. start Tomcat
5. access Jenkins in hostname:8080/jeknins
6. enter the initAdminPassword, usually in ~/.jenkins/secrets/initAdmin......

### Configuration for Maven project
1. choose suggested plugin

2. install git plugin, Maven Integration plugin, gitlab plugin. You should be able to create Maven project in jenkins right now.

3. Configure in Manage Jenkin -> Global tools by adding JDK, Git, and Maven.

4. Configure Gitlab in Manage Jenkins -> Config System by adding Gitlab domain name and Gitlab access token. (Let jenkins know the particular server)

5. create project and select trigger build with gitlab ??????

6. At the settings of project in Gitlab, create a webhook indicated by Jenkins
for example?

7. Testing connection by tap the button of the webhook you just configured.

8. Done

### Don't work for this time
- trigger by webhook plugin, gitlab test connection shows http status 403 which is not sufficient content.
- Jenkins CI with Gitlab. I didn't any triggering log.

