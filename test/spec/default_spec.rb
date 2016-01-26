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

describe 'cheftie' do
  step_into(:ruby_block)
  subject { [] }
  let(:client) { chef_run.send(:client) }
  before do
    output = subject
    allow(Chef::Log).to receive(:info) {|line| output << line }
    begin
      run_chef
    rescue Exception => ex
      if client.run_status
        client.run_status.stop_clock
        client.run_status.exception = ex
      end
      client.run_failed
    else
      client.run_completed_successfully
    end
  end
  recipe(subject: false) do
    ruby_block 'test' do
      block { }
    end
  end

  it { is_expected.to eq 1 }
end
