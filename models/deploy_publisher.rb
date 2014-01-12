require 'fileutils'
require 'rake'
require 'capistrano/all'
require 'capistrano/setup'
require 'capistrano/deploy'

class DeployPublisher < Jenkins::Tasks::Publisher

  attr_accessor :remote_hosts,
                :tomcat_user,
                :tomcat_user_group,
                :tomcat_port,
                :tomcat_cmd,
                :use_tomcat_user_cmd,
                :tomcat_war_file,
                :tomcat_context_path,
                :tomcat_context_file,
                :tomcat_work_dir
  attr_accessor :local_war_file,
                :use_parallel,
                :use_context_update

  display_name 'Deploy via Capitomcat'
  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    @remote_hosts = attrs['remote_hosts']
    @tomcat_user = attrs['tomcat_user']
    @tomcat_user_group = attrs['tomcat_user_group']
    @tomcat_port = attrs['tomcat_port']
    @tomcat_cmd = attrs['tomcat_cmd']
    @use_tomcat_user_cmd = attrs['use_tomcat_user_cmd']
    @tomcat_war_file = attrs['tomcat_war_file']
    @tomcat_context_path = attrs['tomcat_context_path']
    @tomcat_context_file = attrs['tomcat_context_file']
    @tomcat_work_dir = attrs['tomcat_work_dir']

    @local_war_file = attrs['local_war_file']

    @use_parallel = attrs['use_parallel']
    @use_context_update = attrs['use_context_update']
  end

  ##
  # Runs before the build begins
  #
  # @param [Jenkins::Model::Build] build the build which will begin
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def prebuild(build, listener)
    # Generate and save config template
    #save_config_template(workspace)
  end

  ##
  # Runs the step over the given build and reports the progress to the listener.
  #
  # @param [Jenkins::Model::Build] build on which to run this step
  # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def perform(build, launcher, listener)
    # actually perform the build step

    # Execute the Capistrano script
    #launch_cap(launcher, listener)
    do_capitomcat(launcher, listener)
  end

  def do_capitomcat(launcher, listener)
    set :stage, :dev

    set :format, :pretty
    set :log_level, :info
    set :pty, true
    set :use_sudo, true

    # Server definition section
    role :app, @remote_hosts.split(',')

    # Remote Tomcat server setting section
    set :tomcat_user, @tomcat_user
    set :tomcat_user_group, @tomcat_user_group
    set :tomcat_port, @tomcat_port
    set :tomcat_cmd, @tomcat_cmd
    set :use_tomcat_user_cmd, @use_tomcat_user_cmd
    set :tomcat_war_file, @tomcat_war_file
    set :tomcat_context_path, @tomcat_context_path
    set :tomcat_context_file, @tomcat_context_file
    set :tomcat_work_dir, @tomcat_work_dir

    # Deploy setting section
    set :local_war_file, @local_war_file
    set :context_template_file, File.expand_path('../templates/context.xml.erb', __FILE__).to_s
    set :use_parallel, @use_parallel
    set :use_context_update, @use_context_update
    set :listener, listener

    begin
      cap_file = File.expand_path('../tasks/capitomcat.cap', __FILE__).to_s
      capistrano = Capistrano::Application.new
      capistrano.add_import(cap_file)
      capistrano.load_imports

      listener.info 'Starting Capitomcat Tomcat deploy'
      capistrano.invoke('capitomcat_jenkins:deploy')
    rescue
      listener.error 'Capitomcat deploy failed'
    end
    listener.info 'Capitomcat deploy has finished successfully'
  end
end