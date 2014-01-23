require 'jenkins/tasks/build_step_proxy'

require_relative 'publisher'

module Capitomcat

  class PublisherProxy < Java.hudson.tasks.Publisher
    include Jenkins::Tasks::BuildStepProxy
    proxy_for Capitomcat::Publisher

    def auth_method
      @object.auth_method
    end

    def use_context_update
      eval(@object.use_context_update.to_s)
    end

    def value_use_context_update(key)
      use_context_update[key] if use_context_update != nil
    end
  end
end