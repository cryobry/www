# Ruby 3.2 removed Object#tainted?/#untaint (deprecated since 2.7), but
# liquid 4.0.3 (pinned by the github-pages gem) still calls them defensively.
# Restore harmless no-ops so the site builds on modern Ruby.
unless Object.method_defined?(:tainted?)
  module Ruby32TaintCompat
    def tainted?
      false
    end

    def untaint
      self
    end
  end

  Object.include(Ruby32TaintCompat)
end
