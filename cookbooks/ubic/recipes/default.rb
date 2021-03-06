apt_repository 'ubic' do
  uri          'ppa:berekuk/ubic'
  distribution node['lsb']['codename']
end

execute "ubic apt-get update" do
    command "apt-get update"
    not_if "apt-cache policy ubic | grep Candidate"
end

package "ubic"

#execute "setup ubic" do
#    command "ubic-admin setup --batch-mode"
#    not_if "test -f /etc/ubic.cfg"
#end
