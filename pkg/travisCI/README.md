travis_CI_note.md

### Lifecycle
1. install : install any dependencies
2. script : run the build script

從GitHub下載專案(clone)。
進入資料夾。
Checkout到特定的版本。
執行before_install。
執行install。
執行before_script。
執行script。
執行after_success或after_failure。
執行after_script。



.travis.yml
- `before_install`
- `install`
- `before_script`
- `script`
- `after_success or after_failure`  , could access `$TRAVIS_TEST_RESULT` env variable
- `after_script`

# optional
`before_deploy`
# optional
`deploy`
# optional
`after_deploy`

branches:
    only:
        - master
    except:
        - ex_branch
        - /^deploy-.*$/         # with regex , supported by [Ruby regex](http://www.ruby-doc.org/core-1.9.3/Regexp.html)
notifications:
    email:
        - <通知人 Email 1>
        - <通知人 Email 2>

services:
  - mongodb
  - riak      # start riak
  - rabbitmq  # start rabbitmq-server
  - memcached # start memcached

env:
  - LAIKA_OPTIONS="-t 5000"
env:
  - DB=sqlite
  - DB=mysql
  - DB=postgres

before_script:
  - sh -c "if [ '$DB' = 'pgsql' ]; then psql -c 'DROP DATABASE IF EXISTS doctrine_tests;' -U postgres; fi"
  - sh -c "if [ '$DB' = 'pgsql' ]; then psql -c 'DROP DATABASE IF EXISTS doctrine_tests_tmp;' -U postgres; fi"
  - sh -c "if [ '$DB' = 'pgsql' ]; then psql -c 'create database doctrine_tests;' -U postgres; fi"
  - sh -c "if [ '$DB' = 'pgsql' ]; then psql -c 'create database doctrine_tests_tmp;' -U postgres; fi"
  - sh -c "if [ '$DB' = 'mysql' ]; then mysql -e 'create database IF NOT EXISTS doctrine_tests_tmp;create database IF NOT EXISTS doctrine_tests;'; fi"



# for multi-configure

```
# should be  7 x 4 x 2
rvm:
  - 1.8.7
  - 1.9.2
  - 1.9.3
  - rbx-2
  - jruby
  - ruby-head
  - ree
gemfile:
  - gemfiles/Gemfile.rails-2.3.x
  - gemfiles/Gemfile.rails-3.0.x
  - gemfiles/Gemfile.rails-3.1.x
  - gemfiles/Gemfile.rails-edge
env:
  - ISOLATED=true
  - ISOLATED=false

# exception
matrix:
  exclude:
    - rvm: 1.8.7
      gemfile: gemfiles/Gemfile.rails-2.3.x
      env: ISOLATED=true
    - rvm: jruby
      gemfile: gemfiles/Gemfile.rails-2.3.x
      env: ISOLATED=true

# first equivalent  seconde
matrix:
    exclude:
    - rvm: 2.0.0
        gemfile: Gemfile
        env: DB=mongodb
    - rvm: 2.0.0
        gemfile: Gemfile
        env: DB=redis
    - rvm: 2.0.0
        gemfile: Gemfile
        env: DB=mysql

matrix:
    exclude:
    - rvm: 2.0.0
        gemfile: Gemfile

matrix:
  include:
    - rvm: ruby-head
      gemfile: gemfiles/Gemfile.rails-3.2.x
      env: ISOLATED=false

matrix:
  allow_failures:
    - rvm: 1.9.3
  fast_finish: true

addons:
  hosts:
    - travis.dev
    - joshkalderimis.com

# automatically initialize and update submodule
git:
  submodules: false
```

[customizing environment setting](http://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps)


##### # example
    nodejs
        default
                install: npm install
                script: npm test


### # Build Timeouts

Because it is very common for test suites or build scripts to hang, Travis CI has specific time limits for each job. If a script or test suite takes longer than 50 minutes (or 120 minutes on travis-ci.com), or if there is not log output for 10 minutes, it is terminated, and a message is written to the build log.

Some common reasons why builds might hang:

Waiting for keyboard input or other kind of human interaction
Concurrency issues (deadlocks, livelocks and so on)
Installation of native extensions that take very long time to compile
There is no timeout for a build; a build will run as long as all the jobs do as long as each job does not timeout.