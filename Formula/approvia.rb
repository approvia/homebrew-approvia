# frozen_string_literal: true

class Approvia < Formula
  desc "Approvia Local Agent provides remote execution capabilities for Approvia web applications"
  homepage "https://approvia.dev"

  # When updating, you only need to change this version number...
  version "0.0.1"

  url "https://github.com/approvia/homebrew-approvia/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "ca30cbd9c231ce05ad21506d56582a1f05e63d6ff66d5b8bb6d67c167a1aaa01"

  # The main `url` is no longer used. Instead, we define a `resource` for each file.
  # The URLs and checksums below must be updated for each new release.
  resource "prod_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.2/approvia-prod.jar"
    sha256 "2d114c9fa854c0a9a3189fd1c59137350d8806abfd28bd7dd6f7d08f1b2f8eab"
  end

  resource "dev_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.2/approvia-dev.jar"
    sha256 "d54db9fc6bf3408d5b33c3c2eba2db284b6b86b7a528da86b910a541518c2e3d"
  end

  resource "local_jar" do
    url "https://github.com/approvia/homebrew-approvia/releases/download/v0.0.2/approvia-local.jar"
    sha256 "78890afe416a7a41d9bca73791f6b26088002cd0c7f673b850c43a162e735b40"
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