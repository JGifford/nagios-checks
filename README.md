# nagios-checks

## Synopsis

**nagios-checks** is my compilation of home-grown check scripts for use with the Nagios monitoring platform.

## Code Example

### check_flexlm_expire
    ./check_flexlm_expire -s PORT@HOSTNAME -w WARN_DAYS -c CRIT_DAYS -f FEATURE
Checks the FlexLM license server (answering at `PORT@HOSTNAME`) for the licensed `FEATURE` and reports back if it is within `WARN_DAYS` or `CRIT_DAYS` of expiring.

Note: You'll need to update the `LMUTIL` variable (toward the top of the script) to point to your local installation (path) of FlexLM's `lmutil` utility.
This does not need to run on the same host as the FlexLM license server/daemon. It should be possible to use the `PORT@HOSTNAME` to query remote license servers.
If you are running on the same host as your license server/daemon, you can swap out `PORT@HOSTNAME` for the path to the license file.

Note: This was tested on CentOS 6.5 and should work on OSX if you swap out the commented `epoch_*` pairs of lines (search script for "OSX").

### check_flexlm_feature
    ./check_flexlm_feature.sh -s PORT@HOSTNAME -w WARN_LIC -c CRIT_LIC -f FEATURE
Checks the FlexLM license server (answering at `PORT@HOSTNAME`) for the licensed `FEATURE` and reports back if the number of licenses in use is outside `WARN_LIC` or `CRIT_LIC`.
Provides Nagios' perfdata as well (FEATURE=ISSUED;IN_USE).

Note: You'll need to update the `LMUTIL` variable (toward the top of the script) to point to your local installation (path) of FlexLM's `lmutil` utility.
This does not need to run on the same host as the FlexLM license server/daemon. It should be possible to use the `PORT@HOSTNAME` to query remote license servers.
If you are running on the same host as your license server/daemon, you can swap out `PORT@HOSTNAME` for the path to the license file.

Note: This was tested on CentOS 6.5

### check_hpc_queues

### check_mem

### check_sw_vpn_tunnels

## Motivation

I have developed these scripts largely in response to not having something I needed. 

In essense, they are my attempts to scratch very particular itches that I've encountered.

## Installation

Temporary hint: Copy `check_*` scripts into your Nagios `libexec` directory and ensure that they are all executable (chmod 755). You may also need to update certain variables inside to match your local situation.

## API Reference

Depending on the size of the project, if it is small and simple enough the reference docs can be added to the README. For medium size to larger projects it is important to at least provide a link to where the API reference docs live.

## Tests

Describe and show how to run the tests with code examples.

## Contributors

Let people know how they can dive into the project, include important links to things like issue trackers, irc, twitter accounts if applicable.

## License

A short snippet describing the license (MIT, Apache, etc.)



