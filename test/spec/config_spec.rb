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

describe PoiseProfiler::Config do
  subject { described_class.new }
  around do |ex|
    old_env = ENV.to_h
    ENV.delete_if {|key, value| key.downcase.start_with?('poise') }
    begin
      ex.run
    ensure
      ENV.clear
      ENV.update(old_env)
    end
  end
  before do
    if defined?(Chef.node)
      Chef.set_node(chef_run.node)
    end
  end

  context 'with $POISE_PROFILER_OPTION' do
    before { ENV['POISE_PROFILER_OPTION'] = 'value' }
    its([:option]) { is_expected.to eq 'value' }
  end # /context with $POISE_PROFILER_OPTION

  context 'with $POISE_PROFILER_OPTION=true' do
    before { ENV['POISE_PROFILER_OPTION'] = 'true' }
    its([:option]) { is_expected.to be true }
  end # /context with $POISE_PROFILER_OPTION=true

  context 'with $POISE_PROFILER_OPTION=1' do
    before { ENV['POISE_PROFILER_OPTION'] = '1' }
    its([:option]) { is_expected.to eq 1 }
  end # /context with $POISE_PROFILER_OPTION=1

  # Attribute config is only supported when the global node is available.
  if defined?(Chef.node)
    context 'with node attributes' do
      let(:default_attributes) do
        {'poise-profiler' => {'option' => 'value'}}
      end
      its([:option]) { is_expected.to eq 'value' }
    end # /context with node attributes
  end
end
