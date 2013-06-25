# encoding: UTF-8
require 'rake'
Gem::Specification.new do |spec|
  spec.name = 'incoming_mail'
  spec.authors = [ 'Morten Rønne' ]
  spec.add_runtime_dependency ('mail')
  spec.add_development_dependency('rspec')
  spec.summary = 'IMAP mail reader/processor'
  spec.description = <<-DESC
    incoming_mail is a script/library for processing mails retrieved through
    imap.
    Actual processing is done in IncomingMail class.
DESC
  spec.files = FileList['lib/**/*.rb', 'bin/*', '[A-Z]*', 'spec/**/*'].to_a
  spec.has_rdoc = false
  spec.license = 'GPL-2'
  spec.required_ruby_version = '>= 1.9.2'
  spec.requirements << 'Access to an IMAP mail server'
  spec.version = '1.0.4'
end
