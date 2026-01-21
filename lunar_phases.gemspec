# frozen_string_literal: true

require_relative "lib/lunar_phases/version"

Gem::Specification.new do |spec|
  spec.name = "lunar_phases"
  spec.version = LunarPhases::VERSION
  spec.authors = ["John. Hampson"]
  spec.email = ["john@insatri.com"]

  spec.summary = "Moon phase lookup for any date between 2000-2050"
  spec.description = "Provides timezone-aware moon phase lookups using pre-computed astronomical data. " \
                     "Returns the nearest primary phase (New Moon, 1st Quarter, Full Moon, 3rd Quarter) " \
                     "with day offset for any date in the supported range."
  spec.homepage = "https://github.com/insatri/lunar_phases"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE.txt", "README.md"]
  end

  spec.require_paths = ["lib"]

  # Optional: for standalone use without Rails
  spec.add_dependency "tzinfo", "~> 2.0"
end
