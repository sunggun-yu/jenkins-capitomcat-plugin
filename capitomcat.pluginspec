require_relative 'models/capitomcat'

Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = 'capitomcat'
  plugin.display_name = 'Capitomcat Plugin'
  plugin.version = CapitomcatPlugin::VERSION
  plugin.description = 'This plugin deploy the WAR file to multiple remote Tomcat servers by using Capistrano 3'
  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Capitomcat+Plugin'
  plugin.developed_by 'sunggun', 'Sunggun Yu <sunggun.dev@gmail.com>'
  plugin.uses_repository :github => 'jenkinsci/capitomcat-plugin'
  plugin.depends_on 'ruby-runtime', '0.11'
end
