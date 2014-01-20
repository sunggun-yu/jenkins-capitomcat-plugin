require 'jenkins/tasks/build_step'
require_relative 'capitomcat_publisher'

class CapitomcatPublisherProxy < Java.hudson.tasks.Publisher
  include Jenkins::Tasks::BuildStepProxy
  proxy_for CapitomcatPublisher
end