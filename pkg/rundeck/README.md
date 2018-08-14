# RunDeck

[Official website](http://rundeck.org/index.html)

### installation

1. Download from `http://dl.bintray.com/rundeck/rundeck-maven/rundeck-launcher-2.9.2.jar`, check with the latest version.
2. Install jar file by `java -jar rundeck-launcher-2.1.1.jar`
3. Start Rundeck by `sh  server/sbin/rundeckd restart`

### Back up

    五、備份project及jobs
    5.1 備份project
        cp -r /apps/rundeck/project 備份路徑
    5.2 備份jobs （比如備份apps項目）
        # /app/rundeck/tools/bin/rd-jobs list -f ~/backup/jobs.xml -p apps
    5.3 備份data/logs （需要先停止rundeck）
        [root@test02 rundeck]# sh  server/sbin/rundeckd stop
        [root@test02 ~]# cp -r  /apps/rundeck/server/data/ ~/backup
        [root@test02 ~]# cp -r  /apps/rundeck/var/logs/ ~/backup
        [root@test02 rundeck]# sh  server/sbin/rundeckd start
    六、還原jobs
        # /apps/rundeck/tools/bin/rd-jobs load -f ~/backup/jobs.xml -p apps


# Configuration

### server config
Default: http://localhost:44440 admin/admin

Property files

    vim /data/webupdate/etc/framework.properties  #把这个里面的localhost改成你的域名或者ip地址(用户名密码也在这里面)
    vim /data/webupdate/server/rundeck-config.properties# 这里面的grails url中localhost改成 你的域名或者ip 不然登陆后直接调整都localhost啦


### project node
at `/data/webupdate/projects/<project_name>/etc/resources.xml`

    <?xml version="1.0" encoding="UTF-8"?> 
    <project>
        <node name="puppet.dingmh.com" description="Rundeck server node" tags="" hostname="puppet.dingmh.com" osArch="amd64" osFamily="unix" osName="Linux" osVersion="2.6.32-220.el6.x86_64" username="root"/>
     
        <node name="172.168.10.12" description="Rundeck server node" tags="" hostname="172.168.10.12:57522" osArch="amd64" osFamily="unix" osName="Linux" osVersion="2.6.32-220.el6.x86_64" username="root"/>
    </project>
    多台主机的话，需要做SSHKEY信任

### User config
at `/data/webupdate/server/config`

    #
    # This file defines users passwords and roles for a HashUserRealm
    #
    # The format is
    #  <username>: <password>[,<rolename> ...]
    #
    # Passwords may be clear text, obfuscated or checksummed.  The class 
    # org.mortbay.util.Password should be used to generate obfuscated
    # passwords or password checksums
    #
    # This sets the temporary user accounts for the Rundeck app
    #
    admin:admin,user,admin
    user:user,webupdate,dingmh
    dmh324:dmh324,user,dingmh

### Account security 
at `/data/webupdate/etc/admin.aclpolicy`  可以新建一个组文件

    description: <description>
    context:
      project: 'dingmh' # all projects
    for:
      resource:
        + allow: '*' # allow read/create all kinds
      adhoc:
        + allow: '*' # allow read/running/killing adhoc jobs
      job:
        + allow: '*' # allow read/write/delete/run/kill of all jobs
      node:
        + allow: '*' # allow read/run for all nodes
    by:
      group: [dingmh]

    ------------------

    description: Admin, all access.
    context:
      application: 'rundeck'
    for:
      project:
        + allow: '*' # allow view/admin of all projects
    by:
      group: [dingmh]
