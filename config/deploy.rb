$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
require "bundler/capistrano"

desc "Setup Development Settings"
task :development do
  set :rvm_ruby_string, '1.9.2'
  
  set :application, "voeis"
  set :use_sudo,    false
  
  set :scm, :git
  set :repository,  "git://github.com/yogo/VOEIS.git"
  set :shell, "/bin/bash"
  
  set :branch, "master"
  set :deploy_via, :remote_cache
  set :copy_exclude, [".git"]
  
  set  :user, "voeis-demo"
  role :web, "153.90.178.140"
  role :app, "153.90.178.140"
  set  :deploy_to, "/home/#{user}/voeis"
  
  default_run_options[:pty] = false
end



desc "Setup Production Settings"
task :production do
  set :rvm_ruby_string, '1.9.2'
  
  set :application, "voeis"
  set :use_sudo,    false
  
  set :scm, :git
  set :repository,  "git://github.com/yogo/VOEIS.git"
  set :shell, "/bin/bash"
  
  set :branch, "master"
  set :deploy_via, :remote_cache
  set :copy_exclude, [".git"]
  
  set  :user, "voeis-demo"
  role :web, "klank.msu.montana.edu"
  role :app, "klank.msu.montana.edu"
  set  :deploy_to, "/home/#{user}/voeis"

  default_run_options[:pty] = false
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

namespace :db do
  desc "Seed initial data"
  task :seed, :roles => :app do
    run "bash -c 'cd #{current_path} && RAILS_ENV=production rake db:seed'"
  end

  desc  "Clear out test data"
  task :clear, :roles => :app do
    run "bash -c 'cd #{current_path} && rake db:drop:all'"
  end

  task :symlink do
    run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
  end
  
  desc "Get the remote database and save it locally"
  task :get_remote_database do
    db.run_backup_task
    db.download_backup_files
  end
  
  task :download_backup_files do
    download("#{current_path}/db/backup/", "db/backup/", :recursive => true)
  end
  
  task :run_backup_task do
    run "cd #{current_path}; rake yogo:db:backup RAILS_ENV=production"
  end
  
  task :auto_upgrade do
    run "cd #{current_path}; bundle exec rake yogo:db:auto_upgrade RAILS_ENV=production"
  end
end

namespace :docs do
  task :generate do
    run "cd #{current_path}; bundle exec rake yard RAILS_ENV=production"
  end
  
  task :publish do
    run "ln -nfs #{release_path}/doc #{release_path}/public/doc"
  end
end

namespace :assets do
  task :setup do
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/files"
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/images"
    run "mkdir -p #{deploy_to}/#{shared_dir}/assets/temp_data"
  end

  task :symlink do
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/files #{release_path}/public/files"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/images #{release_path}/public/images"
    run "ln -nfs #{deploy_to}/#{shared_dir}/assets/temp_data #{release_path}/temp_data"
  end
end

namespace :jobs do
  desc "Start up worker jobs"
  task :start do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec rake jobs:work >> log/delayed_worker.log'"
  end
  
  desc "Stop the remote worker jobs"
  task :stop do
    run "bash -l -c 'cd #{current_release}; RAILS_ENV=production bundle exec rake jobs:stop'"
  end
end

# These are one time setup steps
#after "deploy:setup",       "db:setup"
after "deploy:setup",       "assets:setup"

# This happens every deploy
after "deploy:update_code", "db:symlink"
after "deploy:update_code", "assets:symlink"
#after "deploy:update_code", "docs:generate"
after "deploy:update_code", "docs:publish"
#after "deploy:update_code", "db:auto_upgrade"
#before "deploy:update_code", "jobs:stop"
#after  "deploy:symlink",     "jobs:start"
