module Danger
  # Run each commit in the PR through a message linting.
  #
  #  Commit lint will check each commit in the PR to ensure the following is
  #  true:
  #
  #  * Commit subject begins with a capital letter (`subject_cap`)
  #  * Commit subject is more than one word (`subject_word`)
  #  * Commit subject is no longer than 50 characters (`subject_length`)
  #  * Commit subject does not end in a period (`subject_period`)
  #  * Commit subject and body are separated by an empty line (`empty_line`)
  #
  #  By default, Commit Lint fails, but you can configure this behavior.
  #
  #
  # @example Lint all commits using defaults
  #
  #          angular_commit_lint.check
  #
  # @example Warn instead of fail
  #
  #          angular_commit_lint.check warn: :all
  #
  # @example Disable a particular check
  #
  #          angular_commit_lint.check disable: [:subject_period]
  #
  # @see danger/danger
  # @tags commit linting
  #
  class DangerAngularCommitLint < Plugin
    NOOP_MESSAGE = 'All checks were disabled, nothing to do.'.freeze

    # Checks the commits with whatever config the user passes.
    #
    # Passing in a hash which contain the following keys:
    #
    #  * `disable` - array of checks to skip
    #  * `fail` - array of checks to fail on
    #  * `warn` - array of checks to warn on
    #
    #  The current check types are:
    #
    #  * `subject_cap`
    #  * `subject_word`
    #  * `subject_length`
    #  * `subject_period`
    #  * `empty_line`
    #
    #  Note: you can pass :all instead of an array to target all checks.
    #
    # @param [Hash] config
    #
    # @return [void]
    #
    def check(config = {})
      @config = config

      if all_checks_disabled?
        messaging.warn NOOP_MESSAGE
      else
        check_messages
      end
    end

    private

    def check_messages
      for message in messages
        check_warnings message
        check_fails message
      end
    end

    def check_warnings(message)
      for klass in warning_checkers
        klass_instance = klass.new(message, @config)
        if klass_instance.fail?
          issue_warning(klass_instance.message, message[:sha])
        end
      end
    end

    def check_fails(message)
      for klass in failing_checkers
        klass_instance = klass.new(message, @config)
        if klass_instance.fail?
          issue_failure(klass_instance.message, message[:sha])
        end
      end
    end

    def checkers
      [
        SubjectPatternCheck,
        SubjectCapCheck,
        SubjectWordsCheck,
        SubjectLengthCheck,
        SubjectPeriodCheck,
        EmptyLineCheck
      ]
    end

    def checks
      checkers.map(&:type)
    end

    def enabled_checkers
      checkers.reject { |klass| disabled_checks.include? klass.type }
    end

    def warning_checkers
      enabled_checkers.select { |klass| warning_checks.include? klass.type }
    end

    def failing_checkers
      enabled_checkers - warning_checkers
    end

    def all_checks_disabled?
      @config[:disable] == :all || disabled_checks.count == checkers.count
    end

    def disabled_checks
      @config[:disable] || []
    end

    def warning_checks
      return checks if @config[:warn] == :all

      @config[:warn] || []
    end

    def messages
      git.commits.map do |commit|
        (subject, empty_line) = commit.message.split("\n")
        {
          subject: subject,
          empty_line: empty_line,
          sha: commit.sha
        }
      end
    end

    def issue_warning(message, sha)
      messaging.warn [message, sha].join("\n")
    end

    def issue_failure(message, sha)
      messaging.fail [message, sha].join("\n")
    end
  end
end
