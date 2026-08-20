# Homebrew formula for the Translatus CLI.
#
# NOT YET PUBLISHED. This file is the finished article, held in the private
# container repo until two gates clear (see packaging/homebrew/README.md):
# the carrier repo going public, and the maintainer identity swap.
#
# Builds from source rather than shipping a prebuilt bottle. Homebrew supplies
# and caches the Rust toolchain, the build takes well under a minute, and it
# keeps the formula to a single platform-agnostic block — no per-target URL and
# checksum matrix to keep in step with every release.
class Translatus < Formula
  desc "Translate and annotate whole books with your own LLM, locally"
  homepage "https://doka.software/translatus"
  url "https://github.com/doka-software/translatus/archive/refs/tags/v1.2.1.tar.gz"
  # Filled by `packaging/homebrew/update-formula.sh` from the published tarball.
  sha256 "dcaffb235066f2edc4b13614c540a4cc00d8f643b6bc79386b9af004e766322c"
  license "MIT"
  head "https://github.com/doka-software/translatus.git", branch: "main"

  depends_on "rust" => :build
  # The subscription sidecar is a Node service the CLI starts on demand; the
  # binary alone cannot reach a Codex/Claude plan without it. Shipping only the
  # binary left the documented first install path unable to use the documented
  # first model source.
  depends_on "node"

  def install
    system "cargo", "install", *std_cargo_args(path: "apps/cli")

    # The CLI looks for the kit next to the binary and then under libexec, so
    # this is the layout `--provider subscription` resolves without any
    # configuration. Dependencies are installed here rather than on first run
    # so the first translation does not stall on npm.
    libexec.install "apps/subscription-kit" => "subscription-kit"
    cd libexec/"subscription-kit" do
      system "npm", "install", "--omit=dev", "--no-audit", "--no-fund"
    end
  end

  # Deliberately a caveat and not a post_install hook: registering the MCP
  # server writes into Claude Code's and Codex's configuration, and `brew
  # install` is non-interactive, so a hook could only do that without asking.
  # The command below is one line, and the interactive session offers to run it
  # for you the first time you open it.
  def caveats
    <<~EOS
      To use Translatus from an AI agent (Claude Code, Codex):
        translatus mcp install

      It registers through each agent's own CLI and can be undone with
      `translatus mcp uninstall`.
    EOS
  end

  test do
    # Exercises the real pipeline end to end without a network call or an API
    # key: the mock provider parses, segments, translates, and rewrites the
    # file. A formula test that only ran `--version` would pass on a binary
    # that cannot open a book.
    (testpath/"book.txt").write <<~TEXT
      Chapter 1

      The ferry left before the light did.
    TEXT

    system bin/"translatus", "translate", testpath/"book.txt",
           "--to", "English", "--provider", "mock", "--model", "mock",
           "--output", testpath/"out.txt"

    assert_path_exists testpath/"out.txt"
    assert_match "translatus", shell_output("#{bin}/translatus --version")
  end
end
