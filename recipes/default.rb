# https://gist.github.com/820703
# For me apparently vagrant won't let me use forwarded ssh keys to chef-solo
# (although it works when doing vagrant ssh). Doing this enables the forward 
# to be used by chef-solo, for all users.

class Chef::Resource
  include FileHelpers
end

ruby_block "Allow forwarding" do
  block do
    file_replace("/etc/sudoers", /^Defaults(.*)$/, "Defaults    env_keep=SSH_AUTH_SOCK")
  end
end

# http://stackoverflow.com/questions/7211287/use-ssh-keys-with-passphrase-on-a-vagrantchef-setup
# As you noted, updating sudoers during the initial run is too late to be beneficial
# to that run as chef is already running under sudo by that point.
#
# Instead I wrote a hacky recipe that finds the appropriate ssh socket to use and 
# updates the SSH_AUTH_SOCK environment to suit. It also disables strict host key 
# checking so the initial outbound connection is automatically approved.
#
# Save this as a recipe that's executed anytime prior to the first ssh connection 
# (tested with Ubuntu but should work with other distributions)

Directory "/root/.ssh" do
  action :create
  mode 0700
end

File "/root/.ssh/config" do
  action :create
  content "Host *\nStrictHostKeyChecking no"
  mode 0600
end

ruby_block "Give root access to the forwarded ssh agent" do
  block do
    # find a parent process' ssh agent socket
    agents = {}
    ppid = Process.ppid
    Dir.glob('/tmp/ssh*/agent*').each do |fn|
      agents[fn.match(/agent\.(\d+)$/)[1]] = fn
    end
    while ppid != '1'
      if (agent = agents[ppid])
        ENV['SSH_AUTH_SOCK'] = agent
        break
      end
      File.open("/proc/#{ppid}/status", "r") do |file|
        ppid = file.read().match(/PPid:\s+(\d+)/)[1]
      end
    end
    # Uncomment to require that an ssh-agent be available
    fail "Could not find running ssh agent - Is config.ssh.forward_agent enabled in Vagrantfile?" unless ENV['SSH_AUTH_SOCK']
  end
  action :create
end
