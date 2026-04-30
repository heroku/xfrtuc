# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

-

### Changed

-

## [1.0.0] - 2026-04-30

### Added

- `Xfrtuc::HTTP::Error` exception hierarchy. See: lib/xfrtuc/errors.rb
- Support for testing against multiple Ruby versions in GitHub Actions.
- SimpleCov for code coverage reporting.

### Changed

- Replaced `sham_rack` / `FakeTransferatu` test fake with WebMock stubs.
- Updated rspec configuration.
- Switched from CircleCI to GitHub Actions for CI.

### Removed

- **Breaking Change:** Replace `RestClient` with stdlib `Net::HTTP` - Gem-specific errors are raised rather than Excon-specific errors. See: lib/xfrtuc/errors.rb
- Dropped support for Ruby < 3.2.

## [0.0.13] - 2021-03-04

### Added

- CircleCI configuration for running specs and linting.

### Fixed

- Deprecation warning for obsolete `URI.escape` usage.

### Changed

- Updated to Ruby 3 compatibility.
- Updated to Ruby 2.7.

## [0.0.12] - 2020-05-29

### Changed

- Upgraded rest-client dependency to ~> 2.0.

## [0.0.11] - 2017-12-12

### Removed

- Bastion support.

### Changed

- Updated Ruby version and all gem dependencies.

## [0.0.10] - 2017-03-14

### Added

- Bastion support for connecting through a bastion host.

## [0.0.9] - 2016-02-04

### Added

- `num` parameter support for transfer scheduling.

## [0.0.8] - 2015-08-07

### Added

- `delete_transfer` method for removing transfers.
- `transfer_action` method for performing actions on transfers.

## [0.0.7] - 2015-06-15

### Changed

- Updated transfer and group listing to use verbose output.

## [0.0.6] - 2015-04-15

### Added

- `schedule` and `schedule_list` methods for managing transfer schedules.

## [0.0.5] - 2015-04-02

### Added

- Transfer group support with `group_list` and `group_create` methods.

## [0.0.4] - 2015-02-05

### Added

- Public URL support in transfer creation.

## [0.0.3] - 2015-02-05

### Added

- Transfer log retrieval via `transfer_log` method.

## [0.0.2] - 2014-09-04

### Added

- Transfer listing and creation via Transferatu API.

## [0.0.1] - 2014-09-03

### Added

- Initial release with basic Transferatu client structure.

[Unreleased]: https://github.com/heroku/xfrtuc/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heroku/xfrtuc/compare/v0.0.13...v1.0.0
[0.0.13]: https://github.com/heroku/xfrtuc/compare/v0.0.12...v0.0.13
[0.0.12]: https://github.com/heroku/xfrtuc/compare/v0.0.11...v0.0.12
[0.0.11]: https://github.com/heroku/xfrtuc/compare/v0.0.10...v0.0.11
[0.0.10]: https://github.com/heroku/xfrtuc/compare/v0.0.9...v0.0.10
[0.0.9]: https://github.com/heroku/xfrtuc/compare/v0.0.8...v0.0.9
[0.0.8]: https://github.com/heroku/xfrtuc/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/heroku/xfrtuc/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/heroku/xfrtuc/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/heroku/xfrtuc/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/heroku/xfrtuc/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/heroku/xfrtuc/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/heroku/xfrtuc/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/heroku/xfrtuc/releases/tag/v0.0.1
