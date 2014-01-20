Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = 'capitomcat'
  plugin.display_name = 'Capitomcat Plugin'
  plugin.version = '0.0.1'
  plugin.description = 'Capitomcat Plugin is the plugin that support Tomcat application deployment with Capitomcat which is Capistrano 3 Recipe for Tomcat deployment'
  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/Capitomcat+Plugin'
  plugin.developed_by 'sunggun', 'Sunggun Yu <sunggun.dev@gmail.com>'
  plugin.uses_repository :github => 'jenkinsci/capitomcat-plugin'
  plugin.depends_on 'ruby-runtime', '0.11'
end
