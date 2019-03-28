require File.expand_path('spec_helper', __dir__)

# rubocop:disable Metrics/LineLength

TEST_MESSAGES = {
  subject_pattern: 'This subject is an incorrect pattern',
  subject_cap: 'fix(scope): this subject needs a capital',
  subject_words: 'fix: Fixed',
  subject_length: 'fix: This is a really long subject line and should result in an error',
  subject_period: 'fix: This subject line ends in a period.',
  empty_line: "fix: This subject line is fine\nBut then I forgot the empty line separating the subject and the body.",
  all_errors: "this is a really long subject and it even ends in a period.\nNot to mention the missing empty line!",
  valid: "fix: This is a valid message\n\nYou can tell because it meets all the criteria and the linter does not complain."
}.freeze

BLANK_MESSAGE = {
  subject: '',
  empty_line: '',
  sha: ''
}.freeze

def report_counts(status_report)
  status_report.values.flatten.count
end

# rubocop:disable Metrics/ClassLength

module Danger
  class DangerAngularCommitLint
    describe 'DangerAngularCommitLint' do
      it 'should be a plugin' do
        expect(Danger::DangerAngularCommitLint.new(nil)).to be_a Danger::Plugin
      end
    end

    describe 'check without configuration' do
      let(:sha) { '1234567' }
      let(:commit) { double(:commit, message: message, sha: sha) }

      def message_with_sha(message)
        [message, sha].join "\n"
      end

      context 'with invalid messages' do
        it 'fails those checks' do
          checks = {
            subject_pattern: SubjectPatternCheck,
            subject_cap: SubjectCapCheck,
            subject_words: SubjectWordsCheck,
            subject_length: SubjectLengthCheck,
            subject_period: SubjectPeriodCheck,
            empty_line: EmptyLineCheck
          }

          for (check, warning_class) in checks
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            commit = double(:commit, message: TEST_MESSAGES[check], sha: sha)
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            angular_commit_lint.check

            status_report = angular_commit_lint.status_report

            expect(report_counts(status_report)).to eq(1), "No error for #{check}"
            expect(status_report[:errors]).to eq [
              message_with_sha(warning_class.new(BLANK_MESSAGE).message)
            ]
          end
        end
      end

      context 'with all errors' do
        let(:message) { TEST_MESSAGES[:all_errors] }

        it 'fails every check' do
          angular_commit_lint = testing_dangerfile.angular_commit_lint
          allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

          angular_commit_lint.check

          status_report = angular_commit_lint.status_report
          expect(report_counts(status_report)).to eq 5
          expect(status_report[:errors]).to eq [
            message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE).message),
            message_with_sha(SubjectCapCheck.new(BLANK_MESSAGE).message),
            message_with_sha(SubjectLengthCheck.new(BLANK_MESSAGE).message),
            message_with_sha(SubjectPeriodCheck.new(BLANK_MESSAGE).message),
            message_with_sha(EmptyLineCheck.new(BLANK_MESSAGE).message)
          ]
        end
      end

      context 'with valid messages' do
        let(:message) { TEST_MESSAGES[:valid] }

        it 'does nothing' do
          checks = {
            subject_length: SubjectLengthCheck,
            subject_period: SubjectPeriodCheck,
            empty_line: EmptyLineCheck
          }

          for _ in checks
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            angular_commit_lint.check

            status_report = angular_commit_lint.status_report
            expect(report_counts(status_report)).to eq 0
          end
        end
      end
    end

    describe 'pattern configuration' do
      let(:sha) { '1234567' }
      let(:commit) { double(:commit, message: message, sha: sha) }

      def message_with_sha(message)
        [message, sha].join "\n"
      end

      it 'requires scope' do
        angular_commit_lint = testing_dangerfile.angular_commit_lint
        commit = double(:commit, message: "fix: This is not fixed\n", sha: sha)
        allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

        config = { require_scope: true }
        angular_commit_lint.check config

        status_report = angular_commit_lint.status_report

        expect(report_counts(status_report)).to eq 1
        expect(status_report[:errors]).to eq [
          message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message)
        ]
      end

      it 'does not use scope' do
        angular_commit_lint = testing_dangerfile.angular_commit_lint
        commit = double(:commit, message: "fix(scope): This is not fixed\n", sha: sha)
        allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

        config = { use_scope: false }
        angular_commit_lint.check config

        status_report = angular_commit_lint.status_report

        expect(report_counts(status_report)).to eq 1
        expect(status_report[:errors]).to eq [
          message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message)
        ]
      end

      it 'has minimum length' do
        angular_commit_lint = testing_dangerfile.angular_commit_lint
        commit = double(:commit, message: "fix(scope): This is not fixed\n", sha: sha)
        allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

        config = {
          min_scope: 8,
          require_scope: true
        }
        angular_commit_lint.check config

        status_report = angular_commit_lint.status_report

        expect(report_counts(status_report)).to eq 1
        expect(status_report[:errors]).to eq [
          message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message)
        ]
      end

      it 'restricts types' do
        angular_commit_lint = testing_dangerfile.angular_commit_lint
        commit = double(:commit, message: "chore: This is not valid\n", sha: sha)
        allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

        config = { commit_types: ['fix'] }
        angular_commit_lint.check config

        status_report = angular_commit_lint.status_report

        expect(report_counts(status_report)).to eq 1
        expect(status_report[:errors]).to eq [
          message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message)
        ]
      end
    end

    describe 'disable configuration' do
      let(:sha) { '1234567' }
      let(:commit) { double(:commit, message: message, sha: sha) }

      def message_with_sha(message)
        [message, sha].join "\n"
      end

      context 'with individual checks' do
        context 'with invalid messages' do
          it 'does nothing' do
            checks = {
              subject_length: SubjectLengthCheck,
              subject_period: SubjectPeriodCheck,
              empty_line: EmptyLineCheck
            }

            for (check, _) in checks
              angular_commit_lint = testing_dangerfile.angular_commit_lint
              commit = double(:commit, message: TEST_MESSAGES[check], sha: sha)
              allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

              angular_commit_lint.check disable: [check]

              status_report = angular_commit_lint.status_report
              expect(report_counts(status_report)).to eq 0
            end
          end
        end
      end

      context 'with all checks, implicitly' do
        let(:message) { TEST_MESSAGES[:all_errors] }

        it 'warns that nothing was checked' do
          angular_commit_lint = testing_dangerfile.angular_commit_lint
          allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

          all_checks = %i[
            subject_pattern
            subject_cap
            subject_words
            subject_length
            subject_period
            empty_line
          ]
          angular_commit_lint.check disable: all_checks

          status_report = angular_commit_lint.status_report
          expect(report_counts(status_report)).to eq 1
          expect(status_report[:warnings]).to eq [NOOP_MESSAGE]
        end
      end

      context 'with all checks, explicitly' do
        let(:message) { TEST_MESSAGES[:all_errors] }

        it 'warns that nothing was checked' do
          angular_commit_lint = testing_dangerfile.angular_commit_lint
          allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

          angular_commit_lint.check disable: :all

          status_report = angular_commit_lint.status_report
          expect(report_counts(status_report)).to eq 1
          expect(status_report[:warnings]).to eq [NOOP_MESSAGE]
        end
      end
    end

    describe 'warn configuration' do
      let(:sha) { '1234567' }
      let(:commit) { double(:commit, message: message, sha: sha) }

      def message_with_sha(message)
        [message, sha].join "\n"
      end

      context 'with individual checks' do
        context 'with invalid messages' do
          it 'warns instead of failing' do
            checks = {
              subject_length: SubjectLengthCheck,
              subject_period: SubjectPeriodCheck,
              empty_line: EmptyLineCheck
            }

            for (check, warning_class) in checks
              angular_commit_lint = testing_dangerfile.angular_commit_lint
              commit = double(:commit, message: TEST_MESSAGES[check], sha: sha)
              allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

              config = { warn: [check] }
              angular_commit_lint.check config

              status_report = angular_commit_lint.status_report
              expect(report_counts(status_report)).to eq 1
              expect(status_report[:warnings]).to eq [
                message_with_sha(warning_class.new(BLANK_MESSAGE, warn: [check]).message)
              ]
            end
          end
        end

        context 'with valid messages' do
          let(:message) { TEST_MESSAGES[:valid] }

          it 'does nothing' do
            checks = {
              subject_length: SubjectLengthCheck,
              subject_period: SubjectPeriodCheck,
              empty_line: EmptyLineCheck
            }

            for (check, _) in checks
              angular_commit_lint = testing_dangerfile.angular_commit_lint
              allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

              angular_commit_lint.check warn: [check]

              status_report = angular_commit_lint.status_report
              expect(report_counts(status_report)).to eq 0
            end
          end
        end
      end

      context 'with all checks' do
        context 'with all errors' do
          let(:message) { TEST_MESSAGES[:all_errors] }

          it 'warns instead of failing' do
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            config = { warn: :all }
            angular_commit_lint.check config

            status_report = angular_commit_lint.status_report
            expect(report_counts(status_report)).to eq 5
            expect(status_report[:warnings]).to eq [
              message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectCapCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectLengthCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectPeriodCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(EmptyLineCheck.new(BLANK_MESSAGE, config).message)
            ]
          end
        end

        context 'with a valid message' do
          let(:message) { TEST_MESSAGES[:valid] }

          it 'does nothing' do
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            angular_commit_lint.check warn: :all

            status_report = angular_commit_lint.status_report
            expect(report_counts(status_report)).to eq 0
          end
        end
      end
    end

    describe 'fail configuration' do
      let(:sha) { '1234567' }
      let(:commit) { double(:commit, message: message, sha: sha) }

      def message_with_sha(message)
        [message, sha].join "\n"
      end

      context 'with individual checks' do
        context 'with invalid messages' do
          it 'fails those checks' do
            checks = {
              subject_length: SubjectLengthCheck,
              subject_period: SubjectPeriodCheck,
              empty_line: EmptyLineCheck
            }

            for (check, warning_class) in checks
              angular_commit_lint = testing_dangerfile.angular_commit_lint
              commit = double(:commit, message: TEST_MESSAGES[check], sha: sha)
              allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

              config = { fail: [check] }
              angular_commit_lint.check config

              status_report = angular_commit_lint.status_report
              expect(report_counts(status_report)).to eq 1
              expect(status_report[:errors]).to eq [
                message_with_sha(warning_class.new(BLANK_MESSAGE, config).message)
              ]
            end
          end
        end

        context 'with valid messages' do
          let(:message) { TEST_MESSAGES[:valid] }

          it 'does nothing' do
            checks = {
              subject_length: SubjectLengthCheck,
              subject_period: SubjectPeriodCheck,
              empty_line: EmptyLineCheck
            }

            for (check, _) in checks
              angular_commit_lint = testing_dangerfile.angular_commit_lint
              allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

              angular_commit_lint.check fail: [check]

              status_report = angular_commit_lint.status_report
              expect(report_counts(status_report)).to eq 0
            end
          end
        end
      end

      context 'with all checks' do
        context 'with all errors' do
          let(:message) { TEST_MESSAGES[:all_errors] }

          it 'fails those checks' do
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            config = { fail: :all }
            angular_commit_lint.check config

            status_report = angular_commit_lint.status_report
            expect(report_counts(status_report)).to eq 5
            expect(status_report[:errors]).to eq [
              message_with_sha(SubjectPatternCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectCapCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectLengthCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(SubjectPeriodCheck.new(BLANK_MESSAGE, config).message),
              message_with_sha(EmptyLineCheck.new(BLANK_MESSAGE, config).message)
            ]
          end
        end

        context 'with a valid message' do
          let(:message) { TEST_MESSAGES[:valid] }

          it 'does nothing' do
            angular_commit_lint = testing_dangerfile.angular_commit_lint
            allow(angular_commit_lint.git).to receive(:commits).and_return([commit])

            angular_commit_lint.check fail: :all

            status_report = angular_commit_lint.status_report
            expect(report_counts(status_report)).to eq 0
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/LineLength
# rubocop:enable Metrics/ClassLength
