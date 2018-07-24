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
  Regexp['^[\w\.-]+$'] $_name = $name,
  String $command,
  Regexp['^https?://'] $runbook,
  Enum['present', 'absent'] $ensure = 'present',
  Optional[Regexp['^[\w\.-]+$']] $group = undef,
  String $check_every = pick(
    hiera("sensu_check_wrapper::check_every::${title}", undef),
    hiera("sensu_check_wrapper::check_every::group::${group}", undef),
    hiera('sensu_check_wrapper::check_every', undef),
    '1m'
  ),
  Array $handlers = pick(
    hiera("sensu_check_wrapper::handlers::${title}", undef),
    hiera("sensu_check_wrapper::handlers::group::${group}", undef),
    hiera('sensu_check_wrapper::handlers', undef),
    []
  ),
  Integer $occurrences = pick(
    hiera("sensu_check_wrapper::occurrences::${title}", undef),
    hiera("sensu_check_wrapper::occurrences::group::${group}", undef),
    hiera('sensu_check_wrapper::occurrences', undef),
    1
  ),
  Variant[Hash, Enum['absent']] $subdue = pick(
    hiera("sensu_check_wrapper::subdue::${title}", undef),
    hiera("sensu_check_wrapper::subdue::group::${group}", undef),
    hiera('sensu_check_wrapper::subdue', undef),
    'absent'
  ),
  String $refresh_every = pick(
    hiera("sensu_check_wrapper::refresh_every::${title}", undef),
    hiera("sensu_check_wrapper::refresh_every::group::${group}", undef),
    hiera('sensu_check_wrapper::refresh_every', undef),
    '30m'
  ),
  Boolean $alert = pick(
    hiera("sensu_check_wrapper::alert::${title}", undef),
    hiera("sensu_check_wrapper::alert::group::${group}", undef),
    hiera('sensu_check_wrapper::alert', undef),
    true
  ),
  Boolean $aggregate = pick(
    hiera("sensu_check_wrapper::aggregate::${title}", undef),
    hiera("sensu_check_wrapper::aggregate::group::${group}", undef),
    hiera('sensu_check_wrapper::aggregate', undef),
    false
  ),
  Boolean $handle = pick(
    hiera("sensu_check_wrapper::handle::${title}", undef),
    hiera("sensu_check_wrapper::handle::group::${group}", undef),
    hiera('sensu_check_wrapper::handle', undef),
    true
  ),
  Optional[Regexp['^https?://']] $uchiwa_prefix = hiera('sensu_check_wrapper::uchiwa_prefix', undef),
) {
# lint:endignore

  $interval_s = human_time_to_seconds($check_every)
  $refresh_s = human_time_to_seconds($refresh_every)

  $uchiwa = "${uchiwa_prefix}${::fqdn}?check=${_name}"

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

  # quotes around $_name are needed to ensure its value comes from sensu_check_wrapper
  create_resources('::sensu::check', { "${_name}" => $sensu_check_params })

}
