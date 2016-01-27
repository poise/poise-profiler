#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'poise'

# Monkey-patch this in for Chef pre-12.4.
class Chef::EventDispatch::Dispatcher
  attr_reader :subscribers
end

describe 'cheftie' do
  step_into(:ruby_block)
  let(:output) { [] }
  let(:events) { chef_runner.send(:client).events }
  let(:wrapped_chef_run) do
    # Force the complete/failed events to trigger because ChefSpec doesn't
    # normally run them.
    begin
      chef_run
    rescue Exception => ex
      events.run_failed(ex)
    else
      events.run_completed(chef_run.node)
    end
  end
  subject { wrapped_chef_run; output.join('') }
  before do
    # Divert log output for analysis.
    _output = output
    allow(events).to receive(:stream_output) {|tag, line| _output << line }
    # Clear the handler's internal state.
    PoiseProfiler::Handler.instance.reset!
  end

  context 'with a single resource' do
    recipe(subject: false) do
      ruby_block 'test' do
        block { }
      end
    end

    it do
      is_expected.to match(
%r{\APoise Profiler:
Time          Resource
------------  -------------
\s*([\d.]+)  ruby_block\[test\]

Time          Class
------------  -------------
\s*([\d.]+)  Chef::Resource::RubyBlock

Profiler JSON: \{.*?\}
\Z})
    end
  end # /context with a single resource

  context 'with a failed run' do
    recipe(subject: false) do
      ruby_block 'test' do
        block { raise RuntimeError }
      end
      ruby_block 'test2' do
        block { }
      end
    end
    before do
      # Suppress the normal formatter output for errors.
      events.subscribers.reject! {|s| (s.respond_to?(:is_formatter?) && s.is_formatter?) || s.is_a?(Chef::Formatters::Base) }
    end

    it do
      is_expected.to match(
%r{\APoise Profiler:
Time          Resource
------------  -------------
\s*([\d.]+)  ruby_block\[test\]

Time          Class
------------  -------------
\s*([\d.]+)  Chef::Resource::RubyBlock

Profiler JSON: \{.*?\}
\Z})
    end
  end # /context with a failed run

  context 'with two resources' do
    recipe(subject: false) do
      ruby_block 'test' do
        block { }
      end
      ruby_block 'test2' do
        block { sleep(0.1) }
      end
    end

    it do
      is_expected.to match(
%r{\APoise Profiler:
Time          Resource
------------  -------------
\s*([\d.]+)  ruby_block\[test2\]
\s*([\d.]+)  ruby_block\[test\]

Time          Class
------------  -------------
\s*([\d.]+)  Chef::Resource::RubyBlock

Profiler JSON: \{.*?\}
\Z})
      expect($1.to_f + $2.to_f).to eq $3.to_f
    end
  end # /context with two resources

  context 'with inner resources' do
    resource(:my_resource, unwrap_notifying_block: false)
    provider(:my_resource) do
      include Poise

      def action_run
        notifying_block do
          ruby_block 'test' do
            block { }
          end
        end
      end
    end
    recipe(subject: false) do
      my_resource 'test'
    end

    it do
      is_expected.to match(
%r{\APoise Profiler:
Time          Resource
------------  -------------
\s*([\d.]+)  my_resource\[test\]
\s*([\d.]+)  ruby_block\[test\]

Time          Class
------------  -------------
\s*([\d.]+)  Chef::Resource::MyResource
\s*([\d.]+)  Chef::Resource::RubyBlock

Profiler JSON: \{.*?\}
\Z})
      expect($1).to eq $3
      expect($2).to eq $4
    end
  end # /context with inner resources

  context 'with test resources' do
    resource(:poise_test, unwrap_notifying_block: false)
    provider(:poise_test) do
      include Poise

      def action_run
        notifying_block do
          ruby_block 'test' do
            block { }
          end
        end
      end
    end
    recipe(subject: false) do
      poise_test 'test'
    end

    it do
      is_expected.to match(
%r{\APoise Profiler:
Time          Resource
------------  -------------
\s*([\d.]+)  ruby_block\[test\]

Time          Test Resource
------------  -------------
\s*([\d.]+)  poise_test\[test\]

Time          Class
------------  -------------
\s*([\d.]+)  Chef::Resource::PoiseTest
\s*([\d.]+)  Chef::Resource::RubyBlock

Profiler JSON: \{.*?\}
\Z})
      expect($1).to eq $4
      expect($2).to eq $3
    end
  end # /context with test resources
end
