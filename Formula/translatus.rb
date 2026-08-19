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
  url "https://github.com/doka-software/translatus/archive/refs/tags/v1.1.4.tar.gz"
  # Filled by `packaging/homebrew/update-formula.sh` from the published tarball.
  sha256 "0aa1474b107f749d453e1f0e67e0876255963292fc2dba2832a898e08b209c5c"
  license "MIT"
  head "https://github.com/doka-software/translatus.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "apps/cli")
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
