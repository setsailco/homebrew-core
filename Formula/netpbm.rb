class Netpbm < Formula
  desc "Image manipulation"
  homepage "https://netpbm.sourceforge.io/"
  # Maintainers: Look at https://sourceforge.net/p/netpbm/code/HEAD/tree/
  # for stable versions and matching revisions.
  url "https://svn.code.sf.net/p/netpbm/code/stable", revision: "4257"
  version "10.86.29"
  license "GPL-3.0-or-later"
  version_scheme 1
  head "https://svn.code.sf.net/p/netpbm/code/trunk"

  livecheck do
    url "https://sourceforge.net/p/netpbm/code/HEAD/tree/stable/"
    strategy :page_match
    regex(/Release v?(\d+(?:\.\d+)+)/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_monterey: "bea51d50007464a4714f5069ce65f3c33df685088b4e09f419235258136f6553"
    sha256 cellar: :any,                 arm64_big_sur:  "f5c059f2b1e5f2735da92ec409bbd40475e3b6ace0096facfbcdac6c51173712"
    sha256 cellar: :any,                 monterey:       "8b4277b722359c67a9ca7e00995740c67ee1b88e97658b890f4732aceedeb7f8"
    sha256 cellar: :any,                 big_sur:        "024f2f1a69c91d1b99a68cf65452efd89c398ec9c09fded80f251d40ccf13e83"
    sha256 cellar: :any,                 catalina:       "8a8e1290ac64149a3ca17bf6925847ab9244f95149a3591a665f6b20f779f329"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "775c1549b012e635f4e6746f640d752904a3bf291cf4cdc5c3fb03588e333b40"
  end

  depends_on "jasper"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"

  uses_from_macos "flex" => :build
  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  conflicts_with "jbigkit", because: "both install `pbm.5` and `pgm.5` files"

  def install
    # Fix file not found errors for /usr/lib/system/libsystem_symptoms.dylib and
    # /usr/lib/system/libsystem_darwin.dylib on 10.11 and 10.12, respectively
    ENV["SDKROOT"] = MacOS.sdk_path if MacOS.version <= :sierra

    cp "config.mk.in", "config.mk"

    inreplace "config.mk" do |s|
      s.remove_make_var! "CC"
      s.change_make_var! "TIFFLIB", "-ltiff"
      s.change_make_var! "JPEGLIB", "-ljpeg"
      s.change_make_var! "PNGLIB", "-lpng"
      s.change_make_var! "ZLIB", "-lz"
      s.change_make_var! "JASPERLIB", "-ljasper"
      s.change_make_var! "JASPERHDR_DIR", "#{Formula["jasper"].opt_include}/jasper"

      if OS.mac?
        s.change_make_var! "CFLAGS_SHLIB", "-fno-common"
        s.change_make_var! "NETPBMLIBTYPE", "dylib"
        s.change_make_var! "NETPBMLIBSUFFIX", "dylib"
        s.change_make_var! "LDSHLIB", "--shared -o $(SONAME)"
      else
        s.change_make_var! "CFLAGS_SHLIB", "-fPIC"
      end
    end

    ENV.deparallelize
    system "make"
    system "make", "package", "pkgdir=#{buildpath}/stage"

    cd "stage" do
      inreplace "pkgconfig_template" do |s|
        s.gsub! "@VERSION@", File.read("VERSION").sub("Netpbm ", "").chomp
        s.gsub! "@LINKDIR@", lib
        s.gsub! "@INCLUDEDIR@", include
      end

      prefix.install %w[bin include lib misc]
      lib.install Dir["staticlink/*.a"], Dir["sharedlink/#{shared_library("*")}"]
      (lib/"pkgconfig").install "pkgconfig_template" => "netpbm.pc"
    end
  end

  test do
    fwrite = shell_output("#{bin}/pngtopam #{test_fixtures("test.png")} -alphapam")
    (testpath/"test.pam").write fwrite
    system "#{bin}/pamdice", "test.pam", "-outstem", testpath/"testing"
    assert_predicate testpath/"testing_0_0.", :exist?
  end
end
