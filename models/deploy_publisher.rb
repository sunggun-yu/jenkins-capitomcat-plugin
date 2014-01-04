require 'fileutils'
require 'erb'

class DeployPublisher < Jenkins::Tasks::Publisher

  attr_accessor :hosts
  attr_accessor :isParallel
  attr_accessor :user, :password, :tomcat_user, :tomcat_user_group, :tomcat_cmd_user
  attr_accessor :local_war_file, :tomcat_port, :remote_docBase, :remote_tomcat_cmd, :remote_tomcat_work_dir
  attr_accessor :context_name, :remote_context_file

  display_name "Deploy via Capitomcat"
  # Invoked with the form parameters when this extension point
  # is created from a configuration screen.
  def initialize(attrs = {})
    @remote_hosts = attrs["remote_hosts"]
    @isParallel = attrs["isParallel"]
    @tomcat_user = attrs["tomcat_user"]
    @tomcat_user_group = attrs["tomcat_user_group"]
    @tomcat_port = attrs["tomcat_port"]
    @local_war_file = attrs["local_war_file"]
    @remote_docBase = attrs["remote_docBase"]
    @remote_tomcat_cmd = attrs["remote_tomcat_cmd"]
    @remote_tomcat_work_dir = attrs["remote_tomcat_work_dir"]
    @context_name = attrs["context_name"]
    @remote_context_file = attrs["remote_context_file"]
  end

  ##
  # Runs before the build begins
  #
  # @param [Jenkins::Model::Build] build the build which will begin
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def prebuild(build, listener)
    # do any setup that needs to be done before this build runs.
  end

  ##
  # Runs the step over the given build and reports the progress to the listener.
  #
  # @param [Jenkins::Model::Build] build on which to run this step
  # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
  # @param [Jenkins::Model::Listener] listener the listener for this build.
  def perform(build, launcher, listener)
    # actually perform the build step

    workspace = build.send(:native).workspace.to_s

    # Copy recipe into workspace
    recipe_dir = File.expand_path("../template/recipe/single", __FILE__)
    FileUtils.cp_r recipe_dir, Pathname.new(workspace)

    remote_hosts = "#{@remote_hosts}"
    isParallel = "#{@isParallel}"
    tomcat_user = "#{@tomcat_user}"
    tomcat_user_group = "#{@tomcat_user_group}"
    tomcat_port = "#{@tomcat_port}"
    local_war_file = "#{@local_war_file}"
    remote_docBase = "#{@remote_docBase}"
    remote_tomcat_cmd = "#{@remote_tomcat_cmd}"
    remote_tomcat_work_dir = "#{@remote_tomcat_work_dir}"
    context_name = "#{@context_name}"
    remote_context_file = "#{@remote_context_file}"
    isUpdateContext = true

    # Create config.rb from template file
    template_file = File.read(File.expand_path("../template/template/config.rb.erb", __FILE__))
    context_name = context_name
    remote_docBase = remote_docBase

    config_dir = Pathname.new( workspace + '/single/config')
    file = config_dir.join('config.rb')

    File.open(file, 'w+') do |f|
      f.write(ERB.new(template_file).result(binding))
    end
# 
    launcher.execute("bash", "-c", "cd #{workspace}/single; cap single deploy:startRelease", { :out => listener })
  end
end