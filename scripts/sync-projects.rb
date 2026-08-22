#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "cgi"
require "date"
require "json"
require "net/http"
require "time"
require "uri"
require "yaml"

API_ROOT = "https://api.github.com"
PROJECT_PATH = ".github/project.yml"
INDEX_PATH = File.expand_path("../index.html", __dir__)
BEGIN_MARKER = "            <!-- BEGIN AUTO PROJECTS -->"
END_MARKER = "            <!-- END AUTO PROJECTS -->"

class GitHubClient
    def initialize(token:, authenticated_repo_listing:)
        @token = token
        @authenticated_repo_listing = authenticated_repo_listing
    end

    def repos(owner:)
        if @authenticated_repo_listing
            get_paginated("/user/repos", affiliation: "owner,collaborator,organization_member", per_page: 100, sort: "updated")
        else
            get_paginated("/users/#{owner}/repos", per_page: 100, sort: "updated")
        end
    end

    def project_file(full_name)
        response = request("/repos/#{full_name}/contents/#{PROJECT_PATH}")
        return nil if response.code.to_i == 404

        fail "GitHub API error for #{full_name}: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        payload = JSON.parse(response.body)
        Base64.decode64(payload.fetch("content"))
    end

    private

    def get_paginated(path, query = {})
        page = 1
        results = []

        loop do
            response = request(path, query.merge(page: page))
            fail "GitHub API error: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

            batch = JSON.parse(response.body)
            break if batch.empty?

            results.concat(batch)
            page += 1
        end

        results
    end

    def request(path, query = {})
        uri = URI("#{API_ROOT}#{path}")
        uri.query = URI.encode_www_form(query) unless query.empty?

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            request = Net::HTTP::Get.new(uri)
            request["Accept"] = "application/vnd.github+json"
            request["X-GitHub-Api-Version"] = "2022-11-28"
            request["User-Agent"] = "jurri-project-sync"
            request["Authorization"] = "Bearer #{@token}" if @token && !@token.empty?

            http.request(request)
        end
    end
end

def text(value, fallback = "")
    value.nil? ? fallback : value.to_s.strip
end

def present_env(name)
    value = ENV[name].to_s.strip
    value.empty? ? nil : value
end

def pick(project, *keys)
    keys.each do |key|
        value = project[key.to_s] || project[key.to_sym]
        return value unless value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    nil
end

def html(value)
    CGI.escapeHTML(text(value))
end

def project_visible?(project)
    return false if project["active"] == false || project[:active] == false
    return false if project["portfolio"] == false || project[:portfolio] == false

    true
end

def project_from(repo, raw_yaml)
    project = YAML.safe_load(raw_yaml, permitted_classes: [Date, Time], aliases: false) || {}
    fail "#{repo["full_name"]} #{PROJECT_PATH} must contain a YAML object" unless project.is_a?(Hash)

    return nil unless project_visible?(project)

    title = pick(project, :title, :name) || repo["name"]
    description = pick(project, :description, :summary) || repo["description"] || "Project details are synced from GitHub."
    status = pick(project, :status, :stage) || "In Progress"

    {
        "repo" => repo["full_name"],
        "repo_url" => repo["html_url"],
        "updated_at" => repo["pushed_at"] || repo["updated_at"],
        "order" => pick(project, :order, :priority).to_i,
        "title_en" => pick(project, :title_en, :name_en) || title,
        "title_de" => pick(project, :title_de, :name_de) || title,
        "description_en" => pick(project, :description_en, :summary_en) || description,
        "description_de" => pick(project, :description_de, :summary_de) || description,
        "status_en" => pick(project, :status_en, :stage_en) || status,
        "status_de" => pick(project, :status_de, :stage_de) || status,
        "tags" => Array(pick(project, :tags, :tech, :technologies)).map { |tag| text(tag) }.reject(&:empty?).first(8),
        "url" => pick(project, :url, :demo, :homepage) || repo["homepage"] || repo["html_url"]
    }
end

def render_tags(tags)
    return "" if tags.empty?

    lines = tags.map do |tag|
        %(                    <span class="tag">#{html(tag)}</span>)
    end

    <<~HTML.rstrip
                <div class="tech-tags">
    #{lines.join("\n")}
                </div>
    HTML
end

def render_project(project)
    tags = render_tags(project.fetch("tags"))
    tags = "\n#{tags}" unless tags.empty?

    <<~HTML.rstrip
            <div class="project-card">
                <div class="project-status">
                    <span class="dot"></span>
                    <span data-lang-en>#{html(project["status_en"])}</span>
                    <span data-lang-de>#{html(project["status_de"])}</span>
                </div>
                <h3>
                    <span data-lang-en>#{html(project["title_en"])}</span>
                    <span data-lang-de>#{html(project["title_de"])}</span>
                </h3>
                <p data-lang-en>#{html(project["description_en"])}</p>
                <p data-lang-de>#{html(project["description_de"])}</p>#{tags}
            </div>
    HTML
end

def render_fallback
    <<~HTML.rstrip
            <div class="project-card">
                <div class="project-status">
                    <span class="dot"></span>
                    <span data-lang-en>Coming soon</span>
                    <span data-lang-de>Demnächst</span>
                </div>
                <h3>
                    <span data-lang-en>Project Showcase</span>
                    <span data-lang-de>Projekt-Showcase</span>
                </h3>
                <p data-lang-en>Featured projects and case studies will be added here. Stay tuned for detailed breakdowns of architecture decisions and technical challenges.</p>
                <p data-lang-de>Ausgewählte Projekte und Case Studies werden hier ergänzt. Bald mit detaillierten Einblicken in Architektur-Entscheidungen und technische Herausforderungen.</p>
                <div class="tech-tags">
                    <span class="tag" style="--tag-bg: var(--green-dim); --tag-color: var(--green);">
                        <span data-lang-en>In Progress</span>
                        <span data-lang-de>In Arbeit</span>
                    </span>
                </div>
            </div>
    HTML
end

def replace_project_block(html, generated)
    pattern = /#{Regexp.escape(BEGIN_MARKER)}\n.*?\n#{Regexp.escape(END_MARKER)}/m
    replacement = "#{BEGIN_MARKER}\n#{generated}\n#{END_MARKER}"

    fail "Could not find project markers in #{INDEX_PATH}" unless html.match?(pattern)

    html.sub(pattern, replacement)
end

owner = ENV.fetch("GITHUB_OWNER", "jurri")
project_sync_token = present_env("PROJECT_SYNC_TOKEN") || present_env("GH_TOKEN")
token = project_sync_token || present_env("GITHUB_TOKEN")
client = GitHubClient.new(token: token, authenticated_repo_listing: !project_sync_token.nil?)

projects = client.repos(owner: owner)
                 .reject { |repo| repo["archived"] }
                 .filter_map do |repo|
    raw = client.project_file(repo.fetch("full_name"))
    raw ? project_from(repo, raw) : nil
rescue StandardError => error
    warn "Skipping #{repo["full_name"]}: #{error.message}"
    nil
end

projects = projects.sort_by do |project|
    [
        project.fetch("order"),
        -(Time.parse(project.fetch("updated_at") || Time.at(0).iso8601).to_i)
    ]
end

generated = projects.empty? ? render_fallback : projects.map { |project| render_project(project) }.join("\n\n")
index_html = File.read(INDEX_PATH)
updated_html = replace_project_block(index_html, generated)
File.write(INDEX_PATH, updated_html)

puts "Synced #{projects.length} project#{projects.length == 1 ? "" : "s"} into index.html."
