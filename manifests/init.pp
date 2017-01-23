# == Define: sensu_check_wrapper
#
# A define for managing sensu checks - wraps sensu::check
# Based on https://github.com/Yelp/puppet-monitoring_check/blob/master/manifests/init.pp
#
# === Parameters
#
# [*command*]
#   String. The check command to run.
#   Required parameter.
#
# [*runbook*]
#   The URI to the Confluence runbook for this check
#   Should be of the form: "https://your-wiki/runbook_check-name".
#   This is required.
#
# [*ensure*]
#   String. Whether the check should be present or not
#   Default: present
#   Valid values: 'present', 'absent'
#
# [*check_every*]
#   How often to run this check. Can be an integer number of seconds, or an
#   abbreviation such as '2m' for 120 seconds, or '2h' for 7200 seconds.
#   Defaults to 1m.
#
# [*handlers*]
#   Array of Strings.  Handlers to use for this check
#   Default: []
#
# [*occurrences*]
#   Integer.  The number of event occurrences before the handler should take action.
#   Default: 1
#
# [*subdue*]
#   Hash.  Check subdue configuration
#   Default: {}
#
# [*refresh_every*]
#   Integer.  How often sensu-plugin-aware handlers should wait before taking second action.
#   Can be an integer number of seconds, or an abbreviation such as '2m' for 120 seconds, or '2h' for 7200 seconds.
#   Valid suffixes: s, m, h, d, w
#   Default: 30m
#
# [*alert*]
#  Boolean. When false, sensu handlers will not alert.
#  Reference: https://github.com/sensu-plugins/sensu-plugin/blob/v1.4.2/lib/sensu-handler.rb#L147-L151
#  Default: true
#
# [*aggregate*]
#  Create a named aggregate for the check. Check result data will be aggregated and exposed via the Sensu Aggregates API.
#  Set to false to disable aggregation of a given check.
#  Reference: https://sensuapp.org/docs/0.26/reference/aggregates.html#aggregate-check-attributes
#  Default: false
#
# [*handle*]
#  Boolean. When false, events created by the check won't be handled.
#  To be used with aggregated checks.
#  Reference: https://sensuapp.org/docs/0.26/reference/aggregates.html#aggregate-check-attributes
#  Default: true


# lint:ignore:undef_in_function
define sensu_check_wrapper (
  $command,
  $runbook,
  $ensure        = 'present',
  $group         = undef,
  $check_every   = pick(
    hiera("sensu_check_wrapper::check_every::${title}", undef),
    hiera("sensu_check_wrapper::check_every::group::${group}", undef),
    hiera('sensu_check_wrapper::check_every', undef),
    '1m'
  ),
  $handlers      = pick(
    hiera("sensu_check_wrapper::handlers::${title}", undef),
    hiera("sensu_check_wrapper::handlers::group::${group}", undef),
    hiera('sensu_check_wrapper::handlers', undef),
    []
  ),
  $occurrences   = pick(
    hiera("sensu_check_wrapper::occurrences::${title}", undef),
    hiera("sensu_check_wrapper::occurrences::group::${group}", undef),
    hiera('sensu_check_wrapper::occurrences', undef),
    1
  ),
  $subdue        = pick(
    hiera("sensu_check_wrapper::subdue::${title}", undef),
    hiera("sensu_check_wrapper::subdue::group::${group}", undef),
    hiera('sensu_check_wrapper::subdue', undef),
    'absent'
  ),
  $refresh_every = pick(
    hiera("sensu_check_wrapper::refresh_every::${title}", undef),
    hiera("sensu_check_wrapper::refresh_every::group::${group}", undef),
    hiera('sensu_check_wrapper::refresh_every', undef),
    '30m'
  ),
  $alert         = pick(
    hiera("sensu_check_wrapper::alert::${title}", undef),
    hiera("sensu_check_wrapper::alert::group::${group}", undef),
    hiera('sensu_check_wrapper::alert', undef),
    true
  ),
  $aggregate     = pick(
    hiera("sensu_check_wrapper::aggregate::${title}", undef),
    hiera("sensu_check_wrapper::aggregate::group::${group}", undef),
    hiera('sensu_check_wrapper::aggregate', undef),
    false
  ),
  $handle     = pick(
    hiera("sensu_check_wrapper::handle::${title}", undef),
    hiera("sensu_check_wrapper::handle::group::${group}", undef),
    hiera('sensu_check_wrapper::handle', undef),
    true
  ),
  $uchiwa_prefix = hiera('sensu_check_wrapper::uchiwa_prefix', undef),
) {
# lint:endignore

  # Catch RE errors before they stop sensu:
  validate_re($name, '^[\w\.-]+$', "Your sensu check name has special chars sensu won't like: ${name}")
  validate_re($ensure, '^present$|^absent$', "Ensure can only be 'present' or 'absent'. You've used: '${ensure}'")
  validate_re($runbook, '^https?://')
  if $uchiwa_prefix != undef {
    validate_re($uchiwa_prefix, '^https?://')
  }

  validate_string($command)
  validate_array($handlers)
  validate_integer($occurrences)
  validate_bool($alert)
  validate_bool($handle)
  if $aggregate {
    validate_string($aggregate)
  }
  if $subdue != undef and $subdue != 'absent' {
    validate_hash($subdue)
  }
  if $group != undef {
    validate_re($group, '^[\w\.-]+$', "Your check group name has forbiden special chars: ${group}")
  }

  $interval_s = human_time_to_seconds($check_every)
  $refresh_s = human_time_to_seconds($refresh_every)
  validate_re($interval_s, '^\d+$')
  validate_re($refresh_s, '^\d+$')

  $uchiwa = "${uchiwa_prefix}${::fqdn}?check=${name}"

  $_aggregate = $aggregate ? {
    false   => undef,
    default => $aggregate,
  }

  $_handle = $handle ? {
    true    => undef,
    default => $handle,
  }

  $custom = delete_undef_values(
    {
      alert   => $alert,
      group   => $group,
      runbook => $runbook,
      uchiwa  => $uchiwa,
    }
  )

  $sensu_check_params = {
    command     => $command,
    ensure      => $ensure,
    interval    => $interval_s,
    handlers    => $handlers,
    occurrences => $occurrences,
    subdue      => $subdue,
    refresh     => $refresh_s,
    aggregate   => $_aggregate,
    handle      => $_handle,
    custom      => $custom,
  }

  # quotes around $name are needed to ensure its value comes from sensu_check_wrapper
  create_resources('::sensu::check', { "${name}" => $sensu_check_params })

}
