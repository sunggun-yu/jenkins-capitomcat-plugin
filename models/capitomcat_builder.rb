require 'rake'
require 'capistrano/all'
require 'capistrano/setup'
require 'sshkit'
require_relative 'jenkins_sshkit_formatter'
require_relative 'jenkins_output'

class CapitomcatBuilder

  def initialize(task, build, listener)
    @task = task
    @build = build
    @listener = listener
    configure()
  end

  def configure
    config_global_ssh()
    config_out_formatter() if @task.log_verbose.to_bool
  end

  def execute
    do_deploy
  end

  private

  def do_deploy

    set :stage, :dev

    set :format, :pretty
    set :log_level, :info
    set :pty, true
    set :use_sudo, true

    # Server definition section
    role :app, @task.remote_hosts.split(',')

    # Remote Tomcat server setting section
    set :tomcat_user, @task.tomcat_user
    set :tomcat_user_group, @task.tomcat_user_group
    set :tomcat_port, @task.tomcat_port
    set :tomcat_cmd, @task.tomcat_cmd
    set :use_tomcat_user_cmd, @task.use_tomcat_user_cmd.to_bool

    set :tomcat_war_file, @task.tomcat_war_file
    set :tomcat_context_path, @task.tomcat_context_path
    set :tomcat_context_file, @task.tomcat_context_file
    set :tomcat_work_dir, @task.tomcat_work_dir

    # Deploy setting section
    set :local_war_file, @task.local_war_file
    set :context_template_file, File.expand_path('../templates/context.xml.erb', __FILE__).to_s
    set :use_context_update, @task.use_context_update.to_bool
    set :use_parallel, @task.use_parallel.to_bool
    set :listener, @listener

    capitomcat_task_name = 'capitomcat_jenkins:deploy'

    require 'capistrano/deploy'
    require 'capitomcat'

    is_task_exist = false

    # check capitomcat task existing
    Rake.application.tasks.each do |t|
      if t.name == capitomcat_task_name
        t.reenable
        is_task_exist = true
        puts "[#{capitomcat_task_name}] re-enabled"
      end
    end

    capistrano = Capistrano::Application.new
    # adding import for capitomcat recipe
    if is_task_exist == false
      cap_file = File.expand_path('../tasks/capitomcat.cap', __FILE__).to_s
      capistrano.add_import(cap_file)
      capistrano.load_imports
      puts "[#{capitomcat_task_name}] added"
    end
    capistrano.invoke(capitomcat_task_name)
  end

  def config_global_ssh
    SSHKit::Backend::Netssh.configure do |ssh|
      ssh.connection_timeout = 30
      ssh.pty = true
      ssh.ssh_options= {}.tap do |sho|
        sho[:keys] = [@task.ssh_key_file] if @task.use_ssh_key_file && @task.ssh_key_file.length > 0
        sho[:auth_methods] = %w(publickey)
      end
    end
  end

  def config_out_formatter
    SSHKit.config.output = JenkinsSSHKitFormatter.new(@native)
  end
end

class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.empty? || self =~ (/^(false|f|no|n|0)$/i)
    return false
  end
end

class Fixnum
  def to_bool
    return true if self == 1
    return false if self == 0
    return false
  end
end

class TrueClass
  def to_i;
    1;
  end

  def to_bool;
    self;
  end
end

class FalseClass
  def to_i;
    0;
  end

  def to_bool;
    self;
  end
end

class NilClass
  def to_bool;
    false;
  end
end