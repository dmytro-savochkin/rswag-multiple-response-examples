# frozen_string_literal: true

Dir.glob(Rails.root.join('lib/extensions/**/*.rb')).each do |filename|
  require filename
end
