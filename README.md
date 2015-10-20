# hive-runner-android
Android module for Hive Runner

## Quick start
Install the hive-runner gem and set up your hive:

    gem install hive-runner
    hive_setup my_hive

When you are asked whether you want to add a module, press 1 and enter `android` as the module name. You will then be able to select the latest version from either Github or Rubygems.

Follow the configuration instructions and, in particular, ensure that the
`HIVE_CONFIG` variable is set.

Start the Hive daemon:

    hived start

Determine the status of the Hive:

    hived status

Stop the Hive:

    hived stop

## Configuration file

Example config file:

      android:
       name_stub: ANDROID_WORKER
       port_range_size: 10
