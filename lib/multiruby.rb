require 'fileutils'

##
# multiruby_setup is a script to help you manage multiruby.
#
# usage: multiruby_setup [-h|cmd|spec...]
#
#   cmds:
#
#     h, help         - show this help.
#     list            - print installed versions.
#     update          - update svn builds.
#     update:rubygems - update rubygems and nuke install dirs.
#     rm:$version     - remove a particular version.
#     clean           - clean scm build dirs and remove non-scm build dirs.
#
#   specs:
#
#     mri:svn:current        - alias for mri:svn:releases and mri:svn:branches.
#     mri:svn:releases       - alias for supported releases of mri ruby.
#     mri:svn:branches       - alias for active branches of mri ruby.
#     mri:svn:branch:$branch - install a specific $branch of mri from svn.
#     mri:svn:tag:$tag       - install a specific $tag of mri from svn.
#     mri:tar:$version       - install a specific $version of mri from tarball.
#
# NOTES:
#
# * you can add a symlink to your rubinius build into ~/.multiruby/install
# * I'll get to adding support for other implementations soon.
#
module Multiruby
  MRI_SVN = "http://svn.ruby-lang.org/repos/ruby"
  TAGS     = %w(    1_8_6 1_8_7 1_9  ).map { |v| "tag:#{v}" }
  BRANCHES = %w(1_8 1_8_6 1_8_7 trunk).map { |v| "branch:#{v}" }


  def self.help
    File.readlines(__FILE__).each do |line|
      next unless line =~ /^#( |$)/
      puts line.sub(/^# ?/, '')
    end
  end

  def self.list
    puts "Known versions:"
    in_install_dir do
      Dir["*"].sort.each do |d|
        puts "  #{d}"
      end
    end
  end

  def self.rm name
    Multiruby.in_root_dir do
      Fileutils.rm_rf Dir["*/#{name}"]
      File.unlink "versions/ruby-#{name}.tar.gz"
    end
  end

  def self.each_scm_build_dir
    Multiruby.in_build_dir do
      Dir["*"].each do |dir|
        next unless File.directory? dir
        Dir.chdir dir do
          if File.exist?(".svn") || File.exist?(".git") then
            scm = File.exist?(".svn") ? :svn : :git
            yield scm
          else
            yield :none
          end
        end
      end
    end
  end

  def self.clean
    self.each_scm_build_dir do |style|
      case style
      when :svn, :git then
        if File.exist? "Makefile" then
          system "make clean"
        elsif File.exist? "Rakefile" then
          system "rake clean"
        end
      else
        Fileutils.rm_rf Dir.pwd
      end
    end
  end

  def self.update
    # TODO:
    # update will look at the dir name and act accordingly rel_.* will
    # figure out latest tag on that name and svn sw to it trunk and
    # others will just svn update

    self.each_scm_build_dir do |style|
      case style
      when :svn then
        dir = File.basename(Dir.pwd)
        warn dir
        case dir
        when /mri_\d/ then
          system "svn cleanup" # just in case
          Fileutils.rm_rf "../install/#{dir}" if `svn up` =~ /^[ADUCG] /
        when /tag/
          warn "don't know how to update tags: #{dir}"
          # url = `svn info`[/^URL: (.*)/, 1]
        else
          warn "don't know how to update: #{dir}"
        end
      else
        warn "update in non-svn dir not supported yet: #{dir}"
      end
    end
  end

  def self.update_rubygems
    url = "http://files.rubyforge.rubyuser.de/rubygems/"
    html = URI.parse(url).read

    versions = html.scan(/href="rubygems-update-(\d+(?:\.\d+)+).gem/).flatten
    latest = versions.sort_by { |s| s.scan(/\d+/).map { |s| s.to_i } }.last

    Multiruby.in_versions_dir do
      File.unlink(*Dir["rubygems*"])
      file = "rubygems-#{latest}.tgz"
      File.open file, 'w' do |f|
        f.write URI.parse(url+file).read
      end
    end
  end

  def self.tags
    tags = nil
    Multiruby.in_tmp_dir do
      cache = "svn.tag.cache"
      File.unlink cache if Time.now - File.mtime(cache) > 86400 rescue nil

      File.open cache, "w" do |f|
        f.write `svn ls #{MRI_SVN}/tags/`
      end unless File.exist? cache

      tags = File.read(cache).split(/\n/).grep(/^v/).reject {|s| s =~ /preview/}
    end

    tags = tags.sort_by { |s| s.scan(/\d+/).map { |s| s.to_i } }
  end

  def self.run(cmd)
    puts "Running command: #{cmd}"
    raise "ERROR: Command failed with exit code #{$?}" unless system cmd
  end

  def self.root_dir
    root_dir = File.expand_path(ENV['MULTIRUBY'] ||
                                File.join(ENV['HOME'], ".multiruby"))

    unless test ?d, root_dir then
      puts "creating #{root_dir}"
      Dir.mkdir root_dir, 0700
    end

    root_dir
  end

  def self.in_root_dir
    Dir.chdir self.root_dir do
      yield
    end
  end

  def self.in_install_dir
    Dir.chdir File.join(self.root_dir, "install") do
      yield
    end
  end

  def self.in_build_dir
    Dir.chdir File.join(self.root_dir, "build") do
      yield
    end
  end

  def self.in_versions_dir
    Dir.chdir File.join(self.root_dir, "versions") do
      yield
    end
  end

  def self.in_tmp_dir
    Dir.chdir File.join(self.root_dir, "tmp") do
      yield
    end
  end

  def self.extract_latest_version url
    file = URI.parse(url).read
    versions = file.scan(/href="(ruby.*tar.gz)"/).flatten.reject { |s|
      s =~ /preview/
    }.sort_by { |s|
      s.split(/\D+/).map { |i| i.to_i }
    }.flatten.last
  end

  def self.fetch_tar v
    require 'open-uri'
    base_url = "http://ftp.ruby-lang.org/pub/ruby"

    in_versions_dir do
      warn "    Determining latest version for #{v}"
      base = extract_latest_version("#{base_url}/#{v}/")
      url = File.join base_url, v, base
      warn "    Fetching #{base} via HTTP... this might take a while."
      open(url) do |f|
        File.open base, 'w' do |out|
          out.write f.read
        end
      end
    end
  end

  def self.setup_dirs
    %w(build install versions tmp).each do |dir|
      unless test ?d, dir then
        puts "creating #{dir}"
        Dir.mkdir dir
        if dir == "versions" then
          warn "  Downloading initial ruby tarballs to ~/.multiruby/versions:"
          %w(1.8 1.9).each do |v|
            self.fetch_tar v
          end
          warn "  ...done"
          warn "  Put other ruby tarballs in ~/.multiruby/versions to use them."
        end
      end
    end
  end

  def self.build_and_install
    root_dir = self.root_dir
    versions = []

    Dir.chdir root_dir do
      self.setup_dirs

      rubygems = Dir["versions/rubygems*.tgz"]
      abort "You should delete all but one rubygem tarball" if rubygems.size > 1
      rubygem_tarball = File.expand_path rubygems.last rescue nil

      Dir.chdir "build" do
        Dir["../versions/*"].each do |tarball|
          next if tarball =~ /rubygems/

          build_dir = File.basename tarball, ".tar.gz"
          version = build_dir.sub(/^ruby-?/, '')
          versions << version
          inst_dir = "#{root_dir}/install/#{version}"

          unless test ?d, inst_dir then
            unless test ?d, build_dir then
              puts "creating #{inst_dir}"
              Dir.mkdir inst_dir
              run "tar zxf #{tarball}"
            end
            Dir.chdir build_dir do
              puts "building and installing #{version}"
              run "autoconf" unless test ?f, "configure"
              FileUtils.rm_r "ext/readline" if test ?d, "ext/readline"
              run "./configure --prefix #{inst_dir} &> log.configure" unless test ?f, "Makefile"
              run "nice make -j4 &> log.build"
              run "make install &> log.install"
              build_dir = Dir.pwd

              if rubygem_tarball and version !~ /1[._-]9|trunk/ then
                rubygems = File.basename rubygem_tarball, ".tgz"
                run "tar zxf #{rubygem_tarball}" unless test ?d, rubygems

                Dir.chdir rubygems do
                  run "../ruby ./setup.rb --no-rdoc --no-ri &> ../log.rubygems"
                end
              end
            end
          end
        end
      end

      # pick up rubinius - allows for simple symlinks to your build dir
      self.in_install_dir do
        versions.push(*Dir["rubinius*"])
      end
    end

    versions
  end

  def self.svn_co url, dir
    Multiruby.in_versions_dir do
      Multiruby.run "svn co #{url} #{dir}" unless File.directory? dir
      FileUtils.ln_s "../versions/#{dir}", "../build/#{dir}"
    end
  end
end
