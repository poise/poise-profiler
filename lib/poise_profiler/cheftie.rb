#
# Copyright 2016, Noah Kantrowitz
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

require 'chef/chef_class'
require 'chef/config'
require 'poise_profiler/handler'

# Install the handler.
if Chef.run_context && Chef.run_context.events
  Chef::Log.debug('Registering poise-profiler using events api')
  Chef.run_context.events.register(PoiseProfiler::Handler.instance)
else
  Chef::Log.debug('Registering poise-profiler using global config')
  Chef::Config[:event_handlers] << PoiseProfiler::Handler.instance
end
