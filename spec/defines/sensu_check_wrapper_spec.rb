require 'spec_helper'
describe 'sensu_check_wrapper', :type => :define do
  let(:facts) { { 
    :osfamily  => 'RedHat',
    :ipaddress => '127.0.0.1'
  } }
  let(:pre_condition) { %q{
    include sensu
  } }

  context 'without whitespace in name' do
    let(:title) { 'mycheck' }

    context 'with default values for all parameters' do
      let(:params) { { 
        :command => '/etc/sensu/somecommand.rb',
        :runbook => 'https://your-wiki/runbook_check-name'
      } }
      it do 
        should contain_sensu_check_wrapper('mycheck').with(
          :command     => '/etc/sensu/somecommand.rb',
          :runbook     => 'https://your-wiki/runbook_check-name',
          :check_every => '1m'
        ) 
        should contain_sensu_check('mycheck').with(
          :command     => '/etc/sensu/somecommand.rb',
          :interval    => 60
        ) 
      end
    end

  end

end
