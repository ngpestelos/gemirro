# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/source'
require 'gemirro/gem'
require 'gemirro/versions_file'
require 'gemirro/mirror_file'
require 'gemirro/gems_fetcher'

# GemsFetcher tests
module Gemirro
  describe 'GemsFetcher' do
    include FakeFS::SpecHelpers

    before(:each) do
      @source = Source.new('RubyGems', 'https://rubygems.org')
      @versions_file = VersionsFile.new(['0.0.1'])
      @fetcher = GemsFetcher.new(@source, @versions_file)
    end

    it 'should be initialized' do
      expect(@fetcher.source).to be(@source)
      expect(@fetcher.versions_file).to be(@versions_file)
    end

    it 'should return configuration' do
      expect(@fetcher.configuration).to be(Gemirro.configuration)
    end

    it 'should return logger' do
      expect(@fetcher.logger).to be(Gemirro.configuration.logger)
    end

    it 'should test if gem exists' do
      @fetcher.configuration.destination = './'
      expect(@fetcher.gem_exists?('test')).to be_falsy
      MirrorDirectory.new('./').add_directory('gems')
      MirrorFile.new('gems/test').write('content')
      expect(@fetcher.gem_exists?('test')).to be_truthy
    end

    it 'should ignore gem' do
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1')).to be_falsy
      @fetcher.configuration.ignore_gem('gemirro', '0.0.1')
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1')).to be_truthy
    end

    it 'should log error when fetch gem failed' do
      gem = Gem.new('gemirro')
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gem)
        .once.with('gemirro', version).and_raise(ArgumentError)
      allow(@fetcher.logger).to receive(:error)
        .once.with(/Failed to retrieve/)
      allow(@fetcher.logger).to receive(:debug)
        .once.with(/Adding (.*) to the list of ignored Gems/)

      expect(@fetcher.fetch_gem(gem, version)).to be_nil
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1')).to be_truthy
    end

    it 'should fetch gem' do
      gem = Gem.new('gemirro')
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gem)
        .once.with('gemirro', version).and_return('gemirro')

      expect(@fetcher.fetch_gem(gem, version)).to eq('gemirro')
    end

    it 'should retrieve versions for specific gem' do
      gem = Gem.new('gemirro', '0.0.2')
      allow(@versions_file).to receive(:versions_for)
        .once.with('gemirro').and_return(['0.0.1', '0.0.2'])
      expect(@fetcher.versions_for(gem)).to eq([::Gem::Version.new('0.0.2')])
    end

    it 'should fetch all gems and log debug if gem is not satisfied' do
      gem = Gem.new('gemirro', '0.0.1')
      allow(gem.requirement).to receive(:satisfied_by?)
        .once.with(nil).and_return(false)
      @fetcher.source.gems << gem
      allow(@fetcher.logger).to receive(:debug)
        .once.with('Skipping gemirro-0.0.1.gem')
      expect(@fetcher.fetch).to eq([gem])
    end

    it 'should fetch all gems' do
      gem = Gem.new('gemirro', '0.0.2')
      @fetcher.source.gems << gem
      allow(@fetcher).to receive(:versions_for).once.and_return(['0.0.2'])
      allow(gem.requirement).to receive(:satisfied_by?)
        .once.with('0.0.2').and_return(true)
      allow(@fetcher).to receive(:fetch_gem)
        .once.with(gem, '0.0.2').and_return('gemfile')
      allow(@fetcher.configuration).to receive(:ignore_gem)
        .once.with('gemirro', '0.0.2')
      allow(@fetcher.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.2.gem')
      allow(@fetcher.configuration.mirror_directory).to receive(:add_file)
        .once.with('gemirro-0.0.2.gem', 'gemfile')
      expect(@fetcher.fetch).to eq([gem])
    end
  end
end
