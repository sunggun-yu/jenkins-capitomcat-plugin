require 'jenkins/model'
require 'jenkins/model/describable'
require 'jenkins/tasks/build_step'
require 'json'
require_relative 'capitomcat_action'
require_relative 'publisher_descriptor'

module Capitomcat
  class Publisher
    include Jenkins::Model
    include Jenkins::Model::Describable
    include Jenkins::Tasks::BuildStep

    describe_as Java.hudson.tasks.Publisher, :with => Capitomcat::PublisherDescriptor

    attr_accessor :local_war_file,
                  :remote_hosts,
                  :use_parallel,
                  :log_verbose,
                  :use_ssh_key_file,
                  :ssh_key_file,
                  :use_context_update,
                  :tomcat_context_name,
                  :tomcat_context_path,
                  :tomcat_doc_base,
                  :tomcat_home,
                  :tomcat_user,
                  :tomcat_user_group,
                  :tomcat_cmd,
                  :use_tomcat_user_cmd,
                  :tomcat_engine,
                  :tomcat_vhost,
                  :tomcat_app_base,
                  :tomcat_port,
                  :user_account,
                  :auth_method,
                  :user_pw

    display_name 'Deploy WAR file to Tomcat via Capitomcat'

    def initialize(attrs = {})
      attrs.each { |k, v| instance_variable_set "@#{k}", v }
    end

    def perform(build, launcher, listener)
      begin
        listener.info 'Starting Capitomcat Tomcat deploy'
        capi_builder = CapitomcatAction.new self, build, listener
        capi_builder.execute
        build.native.setResult(Java.hudson.model.Result::SUCCESS)
        listener.info 'Capitomcat deploy has finished successfully'
      rescue => e
        listener.error [e.message, e.backtrace] * "\n"
        raise 'Capitomcat deploy has failed'
      end
    end

    def self.get_use_context_update
      return use_context_update
    end
  end
end