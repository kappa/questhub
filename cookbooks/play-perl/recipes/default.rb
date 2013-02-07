execute "apt-get-update" do
  command "apt-get update"
  ignore_failure true
end

include_recipe "perl"

# for development
package 'vim'
package 'git'
package 'screen'
package 'perl-doc'
package 'libssl-dev' # used by Net::Twitter

# There is a mongodb cookbook, but it's too generic and tries to do too many things to be portable.
# I think the stock mongodb deb package will suffice for now.
package 'mongodb'

package 'make' # for compiling MongoDB

# forcing Net-HTTP=6.03 until https://rt.cpan.org/Ticket/Display.html?id=81237 is fixed
execute "install-Net-HTTP" do
  environment "HOME" => "/root"
  path [ "/usr/local/bin", "/usr/bin", "/bin" ]
  cwd "/root"
  not_if "perl -mNet::HTTP -e 'exit 1 unless Net::HTTP->VERSION eq \"6.03\"'"
  command "cpanm --reinstall --notest GAAS/Net-HTTP-6.03.tar.gz"
end
cpan_module 'Dancer'
cpan_module 'YAML'
cpan_module 'Module::Install' # needed by MongoDB due to packaging issues - see https://github.com/berekuk/play-perl/issues/70
cpan_module 'MongoDB'
cpan_module 'JSON'
cpan_module 'Params::Validate'
cpan_module 'Moo'
cpan_module 'Test::Deep'
cpan_module 'Test::Class'
cpan_module 'Import::Into'
cpan_module 'Carp::Always'
cpan_module 'Starman'
cpan_module 'Text::Markdown'

# auto_reload for development
cpan_module 'Module::Refresh'
cpan_module 'Clone'

cpan_module 'Dancer::Serializer::JSON'
cpan_module 'Dancer::Session::MongoDB'
cpan_module 'Dancer::Plugin::Auth::Twitter'

directory '/data' # logs

# dancer services
include_recipe "ubic"
cpan_module 'Ubic::Service::Plack'
directory "/data/dancer"
ubic_service "dancer" do
  action [:install, :start]
end
if node['dev']
  directory "/data/dancer-dev"
  ubic_service "dancer-dev" do
    action [:install, :start]
  end
end

# nginx
package 'nginx'

file '/etc/nginx/sites-enabled/default' do
  action :delete
end

template "/etc/nginx/sites-enabled/play-perl.org" do
  source "nginx-site.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables({
    :port => 80,
    :dancer_port => 3000
  })
  notifies :restart, "service[nginx]"
end

if node['dev']
  template "/etc/nginx/sites-enabled/play-perl-dev.org" do
    source "nginx-site.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables({
      :port => 81,
      :dancer_port => 3001
    })
    notifies :restart, "service[nginx]"
  end
end

service "nginx"
