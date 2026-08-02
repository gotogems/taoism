require 'minitest/test_task'

task :parser do
  sh 'racc lib/taoism/parser.y -o lib/taoism/parser.rb'
end

Minitest::TestTask.create(:test) do |t|
  t.libs << 'lib'
  t.test_globs = ['test/**/*_test.rb']
end

task :default => :test
