# Homebrew formula for the Translatus CLI.
#
# Builds from source rather than shipping a prebuilt bottle. Homebrew supplies
# and caches the Rust toolchain, the build takes well under a minute, and it
# keeps the formula to a single platform-agnostic block — no per-target URL and
# checksum matrix to keep in step with every release.
class Translatus < Formula
  desc "Translate and annotate whole books with your own LLM, locally"
  homepage "https://doka.software/translatus"
  url "https://github.com/doka-software/translatus/archive/refs/tags/v1.0.0.tar.gz"
  # Filled by `packaging/homebrew/update-formula.sh` from the published tarball.
  sha256 "c707fa7f2808dff7e7c56cfd6aed54c6790e011c29fc58f3de2e7254ab7b122b"
  license "MIT"
  head "https://github.com/doka-software/translatus.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "apps/cli")
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
