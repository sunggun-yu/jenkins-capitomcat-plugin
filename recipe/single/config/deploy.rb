# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# set :deploy_to, '/var/www/my_app'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

# set :linked_files, %w{config/database.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

# Capitomcat
require 'capitomcat'

set :format, :pretty
set :log_level, :info
set :pty, true
set :use_sudo, true

load 'config/config.rb'

namespace :deploy do
  desc 'Starting Deployment'
  task :startRelease do

    on roles(:app), in: get_parallelism, wait: 5 do |hosts|
      info "Upload WAR file"
      uploadWarFile fetch(:user),
                    fetch(:local_war_file),
                    fetch(:remote_docBase),
                    fetch(:tomcat_user),
                    fetch(:tomcat_user_group)

      info "Stop Tomcat"
      stopTomcat fetch(:remote_tomcat_cmd)
  
      if fetch(:isUpdateContext) == true
        info "Update Context"
        template = getContextTemplate(fetch(:context_template_file), fetch(:context_name), fetch(:remote_docBase))
        uploadContext fetch(:user), template, fetch(:remote_context_file), fetch(:tomcat_user), fetch(:tomcat_user_group)
      end

      info "Clean Work directory"
      cleanWorkDir fetch(:remote_tomcat_work_dir), fetch(:tomcat_user)

      info "Start Tomcat"
      startTomcat fetch(:remote_tomcat_cmd)
    end
  end
end