Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = "capitomcat"
  plugin.display_name = "Capitomcat Jenkins Plugin"
  plugin.version = '0.0.1'
  plugin.description = 'Capitomcat Jenkins Plugin is the plugin that using Capistrano Tomcat Recipe for Capitomcat'

  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Capitomcat+Plugin'

  plugin.developed_by "sunggun", "Sunggun Yu <sunggun.dev@gmail.com>"

  plugin.uses_repository :github => "sunggun-yu/jenkins-capitomcat-plugin"

  # This is a required dependency for every ruby plugin.
  plugin.depends_on 'ruby-runtime', '0.12'
end
