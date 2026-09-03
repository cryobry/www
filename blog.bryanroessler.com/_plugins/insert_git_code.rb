require 'open-uri'

module Jekyll
    class InsertGitCode < Liquid::Tag

        def initialize(tag_name, url, tokens)
            super
            url = url.strip()
            @filename = File.basename(url)
            # URI.encode/decode were removed in Ruby 3.0; URI::DEFAULT_PARSER.escape is the direct replacement.
            encoded_url = URI::DEFAULT_PARSER.escape(url)
            @file = URI.parse(encoded_url).read
        end

        def render(_context)
            @file
        end

    end
end

Liquid::Template.register_tag('insert_git_code', Jekyll::InsertGitCode)
