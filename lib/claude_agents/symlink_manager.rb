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

    # Remove symlink with validation
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

    # Batch create symlinks with progress tracking
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
          ui.skipped("#{result[:display_name]} (#{result[:reason]})")
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

    # Batch remove symlinks
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
          # Don't count as error, just skip
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

    def remove_wshobson_agent_symlinks
      pattern = File.join(Config.agents_dir, "wshobson-*")
      remove_symlinks_by_pattern(pattern, "wshobson agent symlinks")
    end

    def remove_wshobson_command_symlinks
      results = { removed_count: 0, error_count: 0, results: [] }

      # Remove from tools directory
      if Dir.exist?(Config.tools_dir)
        tools_result = remove_symlinks_by_pattern(
          File.join(Config.tools_dir, "*"),
          "wshobson tools"
        )
        merge_results!(results, tools_result)
      end

      # Remove from workflows directory
      if Dir.exist?(Config.workflows_dir)
        workflows_result = remove_symlinks_by_pattern(
          File.join(Config.workflows_dir, "*"),
          "wshobson workflows"
        )
        merge_results!(results, workflows_result)
      end

      # Remove wshobson-prefixed files from commands root
      commands_result = remove_symlinks_by_pattern(
        File.join(Config.commands_dir, "wshobson-*"),
        "wshobson commands"
      )
      merge_results!(results, commands_result)

      # Clean up empty directories
      cleanup_empty_directories

      results
    end

    def remove_awesome_agent_symlinks
      # Find all files that have category prefixes (contain hyphen but not dLabs- or wshobson-)
      all_agent_files = Dir.glob(File.join(Config.agents_dir, "*-*"))

      awesome_files = all_agent_files.reject do |path|
        basename = File.basename(path)
        basename.start_with?("dLabs-", "wshobson-")
      end

      if awesome_files.empty?
        ui.info("No awesome-claude-code-subagents symlinks found to remove")
        return { removed_count: 0, error_count: 0, results: [] }
      end

      ui.subsection("awesome-claude-code-subagents symlinks")

      results = []
      removed_count = 0
      error_count = 0

      awesome_files.each do |file_path|
        result = remove_symlink(file_path)
        results << result

        removed_count += 1 if result[:status] == :removed
      rescue SymlinkError => e
        ui.error("Failed to remove #{File.basename(file_path)}: #{e.message}")
        results << { status: :error, display_name: File.basename(file_path), error: e.message }
        error_count += 1
      end

      {
        removed_count: removed_count,
        error_count: error_count,
        results: results
      }
    end

    private

    def merge_results!(target, source)
      target[:removed_count] += source[:removed_count]
      target[:error_count] += source[:error_count]
      target[:results].concat(source[:results])
    end

    def cleanup_empty_directories
      [Config.tools_dir, Config.workflows_dir].each do |dir|
        next unless Dir.exist?(dir)
        next unless Dir.empty?(dir)

        begin
          Dir.rmdir(dir)
          ui.removed("empty #{File.basename(dir)} directory")
        rescue SystemCallError => e
          ui.warn("Could not remove empty directory #{dir}: #{e.message}")
        end
      end

      # Remove commands directory if empty
      return unless Dir.exist?(Config.commands_dir) && Dir.empty?(Config.commands_dir)

      begin
        Dir.rmdir(Config.commands_dir)
        ui.removed("empty commands directory")
      rescue SystemCallError => e
        ui.warn("Could not remove empty commands directory: #{e.message}")
      end
    end
  end
end
