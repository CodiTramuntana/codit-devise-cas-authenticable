# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# require "decidim/cas_client/version"

Gem::Specification.new do |s|
  s.version = '0.0.6'
  s.authors = ['Marc Reniu']
  s.email = ['marc.rs@coditramuntana.com']
  s.license = 'AGPL-3.0'
  s.homepage = 'https://github.com/decidim/decidim'
  s.required_ruby_version = '>= 2.3.1'

  s.name = 'codit-devise-cas-authenticable'
  s.summary = 'A decidim CasClient module'
  s.description = 'CAS authentication module for Devise, routes namespaced'

  s.files = Dir['{app,config,lib}/**/*', 'LICENSE-AGPLv3.txt', 'Rakefile', 'README.md']

  s.add_dependency 'devise', '>= 1.2.0'
  s.add_dependency 'rubycas-client', '>= 2.2.1'
end
