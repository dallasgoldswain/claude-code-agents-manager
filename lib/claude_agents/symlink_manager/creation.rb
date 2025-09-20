# frozen_string_literal: true

module ClaudeAgents
  class SymlinkManager
    # Symlink creation helpers with progress reporting and error aggregation.
    module Creation
      def create_symlink(source, destination, display_name = nil)
        SingleSymlink.new(self, source, destination, display_name).call
      end

      def create_symlinks(file_mappings, show_progress: true)
        Batch.new(self, file_mappings, show_progress).call
      end

      # Handles creation of a single symlink with safety checks.
      class SingleSymlink
        def initialize(manager, source, destination, display_name)
          @manager = manager
          @ui = manager.ui
          @source = source
          @destination = destination
          @display_name = display_name || File.basename(destination)
        end

        def call
          ensure_source_exists
          ensure_destination_directory
          return skip_existing_destination if destination_taken?

          create_link
        end

        private

        attr_reader :manager, :ui, :source, :destination, :display_name

        def ensure_source_exists
          return if File.exist?(absolute_source)

          raise SymlinkError, "Source file does not exist: #{source}"
        end

        def ensure_destination_directory
          FileUtils.mkdir_p(destination_directory) unless Dir.exist?(destination_directory)
        end

        def destination_taken?
          File.exist?(absolute_destination) || File.symlink?(absolute_destination)
        end

        def skip_existing_destination
          { status: :skipped, reason: 'already exists', display_name: display_name }
        end

        def create_link
          File.symlink(absolute_source, absolute_destination)
          ui.linked(display_name)
          { status: :created, display_name: display_name }
        rescue Errno::EEXIST
          skip_existing_destination
        rescue Errno::EACCES
          raise SymlinkError, "Permission denied creating symlink: #{absolute_destination}"
        rescue StandardError => e
          raise SymlinkError, "Failed to create symlink #{absolute_destination}: #{e.message}"
        end

        def absolute_source
          @absolute_source ||= File.expand_path(source)
        end

        def absolute_destination
          @absolute_destination ||= manager.validate_managed_path!(destination)
        end

        def destination_directory
          @destination_directory ||= File.dirname(absolute_destination)
        end
      end

      # Batch processor for symlink creation with optional progress output.
      class Batch
        def initialize(manager, file_mappings, show_progress)
          @manager = manager
          @ui = manager.ui
          @file_mappings = Array(file_mappings)
          @show_progress = show_progress
          @results = []
          @created = 0
          @skipped = 0
          @deferred_skips = []
          @progress = build_progress
        end

        def call
          return empty_result if file_mappings.empty?

          file_mappings.each { |mapping| process_mapping(mapping) }
          finalize
        end

        private

        attr_reader :manager, :ui, :file_mappings, :show_progress, :results,
                    :deferred_skips, :progress

        def build_progress
          return unless show_progress && file_mappings.length > 5

          ui.progress_bar('Creating symlinks', file_mappings.length)
        end

        def process_mapping(mapping)
          result = manager.create_symlink(mapping[:source], mapping[:destination], mapping[:display_name])
          results << result
          tally_result(result)
        rescue SymlinkError => e
          handle_error(mapping, e)
        ensure
          progress&.advance
        end

        def tally_result(result)
          case result[:status]
          when :created then @created += 1
          when :skipped then note_skip(result)
          end
        end

        def note_skip(result)
          @skipped += 1
          message = "#{result[:display_name]} (#{result[:reason]})"

          if progress
            deferred_skips << message
          else
            ui.skipped(message)
          end
        end

        def handle_error(mapping, error)
          ui.error("Failed to create symlink for #{mapping[:display_name]}: #{error.message}")
          results << { status: :error, display_name: mapping[:display_name], error: error.message }
        end

        def finalize
          progress&.finish
          deferred_skips.each { |message| ui.skipped(message) }

          {
            total_files: file_mappings.length,
            created_links: @created,
            skipped_files: @skipped,
            results: results
          }
        end

        def empty_result
          { total_files: 0, created_links: 0, skipped_files: 0, results: [] }
        end
      end

      private_constant :SingleSymlink, :Batch
    end
  end
end
