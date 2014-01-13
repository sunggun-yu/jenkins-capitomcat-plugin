require 'rake'
require 'capistrano/all'
require 'capistrano/setup'
require 'sshkit'

class CapitomcatBuilder

  def initialize(task, build, listener)
    @task = task
    @build = build
    @listener = listener
  end

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

    (@task.use_tomcat_user_cmd.to_s == 'true') ? _use_tomcat_user_cmd = true : _use_tomcat_user_cmd = false
    set :use_tomcat_user_cmd, _use_tomcat_user_cmd

    set :tomcat_war_file, @task.tomcat_war_file
    set :tomcat_context_path, @task.tomcat_context_path
    set :tomcat_context_file, @task.tomcat_context_file
    set :tomcat_work_dir, @task.tomcat_work_dir

    # Deploy setting section
    set :local_war_file, @task.local_war_file
    set :context_template_file, File.expand_path('../templates/context.xml.erb', __FILE__).to_s

    (@task.use_context_update.to_s == 'true') ? _use_context_update = true : _use_context_update = false
    set :use_context_update, _use_context_update

    (@task.use_parallel.to_s == 'true') ? _use_parallel = true : _use_parallel = false
    set :use_parallel, _use_parallel

    set :listener, @listener

    capitomcat_task_name = 'capitomcat_jenkins:deploy'

    require 'capistrano/deploy'
    require 'capitomcat'

    is_task_exist = false

    # check capitomcat task existing
    Rake.application.tasks.each do | t |
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
end