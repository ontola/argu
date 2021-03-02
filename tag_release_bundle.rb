#!/usr/bin/env ruby
# frozen_string_literal: true

require 'docker-api'
require_relative './services'

$stdout.sync = true

SOURCE_TAG = ENV['SOURCE_TAG'] || 'latest'
TARGET_TAG = ENV['CI_COMMIT_TAG']
warn "Tagging images with #{TARGET_TAG}"
Docker.authenticate!(
  username: ENV['CI_REGISTRY_USER'],
  password: ENV['CI_REGISTRY_PASSWORD'],
  serveraddress: ENV['CI_REGISTRY']
)

def image_source_tag(infra_name)
  ENV["SOURCE_TAG_#{infra_name.upcase}"] || SOURCE_TAG
end

def tag_version(desc)
  repo = desc[:image]
  latest = "#{repo}:#{image_source_tag(desc[:infra_name])}"
  image =
    if Docker::Image.exist?(latest)
      Docker::Image.get(latest)
    else
      warn "Pulling #{latest}"
      Docker::Image.create(fromImage: repo, tag: image_source_tag(repo))
    end
  throw "Image #{latest} not found" unless image

  ref = "#{repo}:#{TARGET_TAG}"
  warn "Tagging #{latest} as #{ref}"
  image.tag(repo: repo, tag: TARGET_TAG)
  [image, ref]
end

SERVICES
  .map { |_, desc| tag_version(desc) }
  .each do |image, ref|
    warn "Pushing #{ref}"
    image.push(repo_tag: ref)
  end

versions = SERVICES.map do |_, desc|
  image = Docker::Image.get("#{desc[:image]}:#{TARGET_TAG}")
  commit = image.info['Config']['Env'].find { |c| c.start_with?('CI_COMMIT_SHA=') }&.split('=')&.pop
  commit_link = commit.presence && "[#{commit}](https://gitlab.com/ontola/libro/-/commit/#{commit})"
  "| #{desc[:infra_name]} | #{image.id} | #{commit_link || '-'} |"
end

message = "Created image bundle #{TARGET_TAG}:\\n\\n" \
          "| Name | Image SHA | Commit |\\n" \
          "|-|-|-|\\n" \
          "#{versions.join('\\n')}\\n"

warn message.gsub('\\n', '\n')
puts message
