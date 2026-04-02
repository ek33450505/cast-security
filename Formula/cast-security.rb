class CastSecurity < Formula
  desc "Security hooks and audit trail for Claude Code"
  homepage "https://github.com/ek33450505/cast-security"
  url "https://github.com/ek33450505/cast-security/archive/refs/heads/main.tar.gz"
  version "0.1.0"
  sha256 "PLACEHOLDER"  # will be updated after repo is published
  license "MIT"

  depends_on "python3" => :required

  def install
    libexec.install Dir["scripts/*"]
    libexec.install Dir["config/*"]
    libexec.install "settings.json"
    (libexec/"VERSION").write(File.read("VERSION"))
    prefix.install "VERSION"

    inreplace "bin/cast-security",
              'SECURITY_SCRIPTS_DIR=""',
              "SECURITY_SCRIPTS_DIR=\"#{libexec}\""

    inreplace "bin/cast-security",
              /CS_VERSION="\$\(cat.*\|\| echo "unknown"\)"/,
              "CS_VERSION=\"#{version}\""

    bin.install "bin/cast-security"
  end

  def caveats
    <<~EOS
      Run one-time setup to wire hooks into Claude Code:
        cast-security install

      Then start a Claude Code session and run:
        cast-security status
    EOS
  end

  test do
    system "#{bin}/cast-security", "--version"
  end
end
