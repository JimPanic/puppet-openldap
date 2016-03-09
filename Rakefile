require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = ["spec/**/*.pp", "pkg/**/*.pp", "vendor/**/*.pp"]
  config.disable_checks = ['80chars']
  config.fail_on_warnings = true
end

PuppetSyntax.exclude_paths = ["spec/fixtures/**/*.pp", "vendor/**/*"]

# Publishing tasks
unless RUBY_VERSION =~ /^1\./
  require 'puppet_blacksmith'
  require 'puppet_blacksmith/rake_tasks'
end

require 'parallel_tests/cli'

desc "Parallel spec tests"
task :parallel_spec do
  Rake::Task[:spec_prep].invoke
  ParallelTests::CLI.new.run('--type test
                    -t rspec spec/classes spec/defines spec/unit'.split)
  Rake::Task[:spec_clean].invoke
end
