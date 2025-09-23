# frozen_string_literal: true

module ClaudeAgents
  # Symlink management with safety checks and detailed reporting
  class SymlinkManager
    attr_reader :ui

    def initialize(ui)
      @ui = ui
    end

    # Create symlink with validation and error handling
    def create_symlink(source, destination, display_name = nil)
      display_name ||= File.basename(destination)

      # Validate source exists
      raise SymlinkError, "Source file does not exist: #{source}" unless File.exist?(source)

      # Ensure destination directory exists
      dest_dir = File.dirname(destination)
      FileUtils.mkdir_p(dest_dir)

      # Check if destination already exists
      if File.exist?(destination) || File.symlink?(destination)
        return { status: :skipped, reason: "already exists", display_name: display_name }
      end

      # Create the symlink
      begin
        # Convert to absolute path for source
        absolute_source = File.expand_path(source)
        File.symlink(absolute_source, destination)

        ui.linked(display_name)
        { status: :created, display_name: display_name }
      rescue Errno::EEXIST
        { status: :skipped, reason: "file exists", display_name: display_name }
      rescue Errno::EACCES
        raise SymlinkError, "Permission denied creating symlink: #{destination}"
      rescue StandardError => e
        raise SymlinkError, "Failed to create symlink #{destination}: #{e.message}"
      end
    end

    # Batch remove symlinks (generic utility retained for dLabs-only mode)
    def remove_symlinks_by_pattern(pattern, description = nil)
      ui.subsection(description) if description

      symlinks = Dir.glob(pattern).select { |path| File.symlink?(path) || File.file?(path) }

      if symlinks.empty?
        ui.info("No #{description&.downcase || 'symlinks'} found to remove")
        return { removed_count: 0, error_count: 0, results: [] }
      end

      results = []
      removed_count = 0
      error_count = 0

      symlinks.each do |symlink_path|
        result = remove_symlink(symlink_path)
        results << result

        case result[:status]
        when :removed
          removed_count += 1
        when :not_found
          # skip
        end
      rescue SymlinkError => e
        ui.error("Failed to remove #{File.basename(symlink_path)}: #{e.message}")
        results << { status: :error, display_name: File.basename(symlink_path), error: e.message }
        error_count += 1
      end

      {
        removed_count: removed_count,
        error_count: error_count,
        results: results
      }
    end

    # Component-specific removal methods
    def remove_dlabs_symlinks
      pattern = File.join(Config.agents_dir, "dLabs-*")
      remove_symlinks_by_pattern(pattern, "dLabs agent symlinks")
    end

    # Non-dLabs removal helpers removed.

    # Remove single symlink (needed by tests and batch removal)
    def remove_symlink(path, display_name = nil)
      display_name ||= File.basename(path)

      unless File.exist?(path) || File.symlink?(path)
        return { status: :not_found, display_name: display_name }
      end

      if File.symlink?(path)
        begin
          File.unlink(path)
          ui.removed(display_name)
          { status: :removed, display_name: display_name }
        rescue Errno::EACCES
          raise SymlinkError, "Permission denied removing symlink: #{path}"
        rescue StandardError => e
          raise SymlinkError, "Failed to remove symlink #{path}: #{e.message}"
        end
      elsif File.file?(path)
        ui.skipped("#{display_name} (not a symlink)")
        { status: :skipped, reason: "not a symlink", display_name: display_name }
      else
        ui.skipped("#{display_name} (directory)")
        { status: :skipped, reason: "is directory", display_name: display_name }
      end
    end

    # Batch create symlinks (re-added for test coverage)
    def create_symlinks(file_mappings, show_progress: true)
      if file_mappings.empty?
        return { total_files: 0, created_links: 0, skipped_files: 0,
                 results: [] }
      end

      results = []
      created_count = 0
      skipped_count = 0

      progress_bar = if show_progress && file_mappings.length > 5
                       ui.progress_bar("Creating symlinks", file_mappings.length)
                     end

      file_mappings.each do |mapping|
        result = create_symlink(mapping[:source], mapping[:destination], mapping[:display_name])
        results << result
        case result[:status]
        when :created
          created_count += 1
        when :skipped
          skipped_count += 1
          ui.skipped("#{result[:display_name]} (#{result[:reason]})") if result[:reason]
        end
        progress_bar&.advance
      rescue SymlinkError => e
        ui.error("Failed to create symlink for #{mapping[:display_name]}: #{e.message}")
        results << { status: :error, display_name: mapping[:display_name], error: e.message }
      end

      progress_bar&.finish

      {
        total_files: file_mappings.length,
        created_links: created_count,
        skipped_files: skipped_count,
        results: results
      }
    end

    private

    def cleanup_empty_directories
      # Only relevant if commands structure existed; retained for compatibility (noop currently)
      []
    end
  end
end
