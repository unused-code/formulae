class Unused < Formula
  desc "Identify potentially unused code"
  homepage "https://unused.codes"
  url "https://github.com/unused-code/unused/archive/0.2.2.tar.gz"
  sha256 "e34fc6250dda368482a2b8ca54101cb313a200b4a51d5ebe074252d955a6ecdd"
  head "https://github.com/unused-code/unused.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "rust" => :build

  option "without-mimalloc", "Use Rust's default allocator (may reduce performance)"

  def install
    if build.with? "mimalloc"
      system "cargo", "install", "--locked", "--root", prefix, "--path", ".", "--features", "mimalloc"
    else
      system "cargo", "install", "--locked", "--root", prefix, "--path", "."
    end
  end

  test do
    shell_output("git init .")
    code = testpath/"awesome.rb"
    code.write <<~EOS
      class Awesome
        def once
          twice
        end

        def twice
          @twice || 2
        end
      end
    EOS

    tags = testpath/".git/tags"
    tags.write <<~EOS
      !_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;" to lines/
      !_TAG_FILE_SORTED	1	/0=unsorted, 1=sorted, 2=foldcase/
      !_TAG_OUTPUT_FILESEP	slash	/slash or backslash/
      !_TAG_OUTPUT_MODE	u-ctags	/u-ctags or e-ctags/
      !_TAG_PROGRAM_AUTHOR	Universal Ctags Team	//
      !_TAG_PROGRAM_NAME	Universal Ctags	/Derived from Exuberant Ctags/
      !_TAG_PROGRAM_URL	https://ctags.io/	/official site/
      !_TAG_PROGRAM_VERSION	0.0.0	/3f4203d/
      Awesome	../awesome.rb	/^class Awesome$/;"	c
      Awesome	../spec/awesome_spec.rb	/^describe Awesome do$/;"	d
      once	../awesome.rb	/^  def once$/;"	f	class:Awesome
      twice	../awesome.rb	/^  def twice$/;"	f	class:Awesome
    EOS

    spec = testpath/"spec/awesome_spec.rb"
    spec.write <<~EOS
      require "spec_helper"

      describe Awesome do
        it "uses twice" do
          expect(subject.twice).to eq subject.twice
        end
      end
    EOS

    output = shell_output("#{bin}/unused -a")

    assert_match /Awesome\n\s+Reason: Token has wide usage/, output
    assert_match /once\n\s+Reason: Only one occurrence exists/, output
    assert_match /twice\n\s+Reason: Token has wide usage/, output
    refute_match /thrice/, output

    true
  end
end
