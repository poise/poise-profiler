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
require 'mixlib/shellout'

# Only run these tests on Travis because otherwise slow and annoying.
describe 'integration', if: ENV['TRAVIS_SECURE_ENV_VARS'] do
  subject do
    Mixlib::ShellOut.new('rake travis:integration', cwd: File.expand_path('../../..', __FILE__)).tap(&:run_command)
  end

  it do
    # Don't run this extra times.
    expect(subject.exitstatus).to eq 0
    expect(subject.stdout).to include 'Poise Profiler Timing:'
  end
end
