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

require 'chef/config'
require 'chef/event_dispatch/base'
require 'chef/json_compat'
require 'chef/version'

begin
  require 'chef/chef_class'
rescue LoadError
  # ¯\_(ツ)_/¯ Chef < 12.3.
end

module PoiseProfiler
  # Base class for poise-provider event handlers.
  #
  # @api private
  # @since 1.1.0
  class Base < Chef::EventDispatch::Base
    include Singleton

    # Install this event handler in to Chef.
    #
    # @return [void]
    def self.install
      if Gem::Version.create(Chef::VERSION) <= Gem::Version.create('12.2.1')
        Chef::Log.debug("Registering poise-profiler handler #{self} using monkey patch")
        instance._monkey_patch_old_chef!
      elsif Chef.run_context && Chef.run_context.events
        # :nocov:
        Chef::Log.debug("Registering poise-profiler handler #{self} using events API")
        Chef.run_context.events.register(instance)
        # :nocov:
      else
        Chef::Log.debug("Registering poise-profiler handler #{self} using global config")
        Chef::Config[:event_handlers] << instance
      end
    end

    # Used in {#_monkey_patch_old_chef}
    #
    # @api private
    attr_writer :events, :monkey_patched

    # Hook to reset the handler for testing.
    #
    # @api private
    # @abstract
    # @return [void]
    def reset!
    end

    # Inject this instance for Chef < 12.3. Don't call this on newer Chef.
    #
    # @api private
    # @see Base.install
    # @return [void]
    def _monkey_patch_old_chef!
      return if @_monkey_patched
      require 'chef/event_dispatch/dispatcher'
      instance = self
      orig_method = Chef::EventDispatch::Dispatcher.instance_method(:library_file_loaded)
      Chef::EventDispatch::Dispatcher.send(:define_method, :library_file_loaded) do |filename|
        instance.events = self
        instance.monkey_patched = false
        @subscribers << instance
        Chef::EventDispatch::Dispatcher.send(:define_method, :library_file_loaded, orig_method)
        orig_method.bind(self).call(filename)
      end
      @_monkey_patched = true
    end

    private

    # Convenience helper to print a line of text out via the event handler.
    #
    # @api private
    # @param line [String] Line to display.
    # @return [void]
    def puts(line)
      events.stream_output(:profiler, line+"\n")
    end

    # Accessor for the current global event handler. The is either set via
    # {#_monkey_patch_old_chef} (<= 12.2.1) or retrieved via the global API (>=
    # 12.3).
    #
    # @api private
    # return [Chef::EventDispatch::Dispatcher]
    def events
      @events ||= Chef.run_context.events
    end

  end
end
