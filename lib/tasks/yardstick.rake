require 'yardstick'
require 'yardstick/rake/measurement'
require 'yardstick/rake/verify'

namespace :yardstick do
  Yardstick::Rake::Measurement.new(:measure) do |measurement|
    measurement.path = ['lib/**/*.rb', 'app/**/*.rb']
    measurement.output = File.join('doc', 'yardstick', 'index.html')
  end

  Yardstick::Rake::Verify.new(:verify) do |verify|
    verify.threshold = 100
  end
end
