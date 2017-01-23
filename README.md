# sensu_check_wrapper

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with sensu_check_wrapper](#setup)
    * [Dependencies](#dependencies)
    * [Beginning with sensu_check_wrapper](#beginning-with-sensu_check_wrapper)
1. [Contributing - Guide for contributing to the module](#contributing)

## Description

`sensu_check_wrapper` is a puppet module to create Sensu checks.

It is forked from [Yelp/puppet-monitoring_check](https://github.com/Yelp/puppet-monitoring_check).
While Yelp/puppet-monitoring_check can only be used with Yelp's `sensu_handlers`, this fork works with standard sensu handlers.

It wraps `sensu::check` and adds for convenience:
- hiera lookups for params
- human-readable time format
- required runbook

## Setup

### Dependencies

- puppetlabs/stdlib
- sensu/sensu

See `metadata.json` for details.

### Beginning with sensu_check_wrapper

```
sensu_check_wrapper { 'cron':
  check_every => '1m',
  alert       => true,
  runbook     => 'http://lmgtfy.com/?q=cron',
  command     => "/usr/lib/nagios/plugins/check_procs -C crond -c 1:30 -t 30 ",
}
```

## Contributing

Open an [issue](https://github.com/ttarczynski/sensu_check_wrapper/issues) or 
[fork](https://github.com/ttarczynski/sensu_check_wrapper/fork) and open a 
[Pull Request](https://github.com/ttarczynski/sensu_check_wrapper/pulls)

