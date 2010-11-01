# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: yogo.rake
#
#
namespace :yogo do
  desc "ensure that yogo project is properly setup"
  task :setup => ['yogo:db:config']
  namespace :db do
    file "config/database.yml" => "config/database.yml.start" do |t|
      cp t.prerequisites.first, t.name
    end

    desc "setup a default database.yml config"
    task :config => "config/database.yml"
  end

  desc "Update the changelog with git log"
  task :update_changelog => :environment do
    sh "git log --quiet --format=medium #{VOEIS_COMMIT} HEAD > #{Rails.root}/app/views/pages/changelog.txt"
  end
end