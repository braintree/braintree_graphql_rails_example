# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'sdoc'
require 'rdoc/task'

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks


RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options << '--format=sdoc'
  rdoc.template = 'rails'
end
