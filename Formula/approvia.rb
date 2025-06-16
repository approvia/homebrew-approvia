# frozen_string_literal: true

class Approvia < Formula
  desc "Approvia Local Agent provides remote execution capabilities for Approvia web applications"
  homepage "https://approvia.dev"

  # When updating, you only need to change this version number...
  version "0.0.1"

  # The main `url` is no longer used. Instead, we define a `resource` for each file.
  # The URLs and checksums below must be updated for each new release.
  resource "prod_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.1/approvia-prod.jar"
    sha256 "236d907afc043e12319d934112258b801ebe6a621ce9f43c9a08d1a0879aa288"
  end

  resource "dev_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.1/approvia-dev.jar"
    sha256 "1db0cce151cff9cc3353ff4b910c6c74a4207d9d8b24b870f6226e0715cc9f40"
  end

  resource "local_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.1/approvia-local.jar"
    sha256 "292362c379b27a8e03e06c69cd1ea656b1cc294556496a060f912bfe4894bf03"
  end

  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "openjdk@17"
  depends_on "curl"

  def install
    # Download and install each JAR from its respective resource block
    resource("prod_jar").stage { libexec.install "approvia-prod.jar" }
    resource("dev_jar").stage { libexec.install "approvia-dev.jar" }
    resource("local_jar").stage { libexec.install "approvia-local.jar" }

    # The rest of the logic for creating the wrapper scripts remains the same
    github_repo = "approvia/homebrew-approvia"

    environments = {
      "prod"  => "approvia-prod.jar",
      "dev"   => "approvia-dev.jar",
      "local" => "approvia-local.jar"
    }

    environments.each do |env, jar_name|
      command_name = (env == "prod") ? "localagent" : "localagent-#{env}"
      (bin/command_name).write <<~EOS
        #!/bin/bash
        CURRENT_VERSION="#{version}"
        REPO="#{github_repo}"
        LATEST_VERSION=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\\1/')
        if [[ -n "$LATEST_VERSION" && "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
          echo "Error: You are using an outdated version of Approvia Local Agent ($CURRENT_VERSION)." >&2
          echo "The latest version is $LATEST_VERSION." >&2
          echo "" >&2
          echo "Please update by running the following command:" >&2
          echo "  brew upgrade approvia" >&2
          exit 1
        fi
        exec "#{Formula["openjdk@17"].opt_bin}/java" -jar "#{libexec/jar_name}" "$@"
      EOS
    end
  end
end