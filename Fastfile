# Fastlane Configuration for AFHAM iOS
# BrainSAIT Healthcare AI Platform

default_platform(:ios)

platform :ios do

  # Define custom lanes for AFHAM deployment

  desc "Run all tests"
  lane :test do
    scan(
      project: "AFHAM.xcodeproj",
      scheme: "AFHAM",
      device: "iPhone 15 Pro",
      code_coverage: true,
      output_directory: "./test_output",
      clean: true
    )
  end

  desc "Build for testing"
  lane :build_for_testing do
    gym(
      project: "AFHAM.xcodeproj",
      scheme: "AFHAM",
      configuration: "Debug",
      derived_data_path: "./derived_data",
      clean: true,
      skip_archive: true,
      skip_codesigning: true
    )
  end

  desc "Take screenshots for App Store"
  lane :screenshots do
    snapshot(
      project: "AFHAM.xcodeproj",
      scheme: "AFHAM",
      output_directory: "./screenshots",
      clear_previous_screenshots: true,
      languages: ["ar-SA", "en-US"],
      devices: [
        "iPhone 15 Pro Max",
        "iPhone 15 Pro",
        "iPad Pro (12.9-inch) (6th generation)"
      ]
    )
  end

  desc "Build and sign for TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "AFHAM.xcodeproj")

    # Build app
    gym(
      project: "AFHAM.xcodeproj",
      scheme: "AFHAM",
      configuration: "Release",
      export_method: "app-store",
      clean: true,
      output_directory: "./build",
      output_name: "AFHAM.ipa"
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      changelog: "Bug fixes and performance improvements"
    )

    # Notify team
    slack(
      message: "AFHAM build #{lane_context[SharedValues::BUILD_NUMBER]} uploaded to TestFlight!",
      success: true
    )
  end

  desc "Deploy to App Store"
  lane :release do
    # Ensure git is clean
    ensure_git_status_clean

    # Increment version
    version = prompt(text: "Enter version number: ")
    increment_version_number(version_number: version)
    increment_build_number(xcodeproj: "AFHAM.xcodeproj")

    # Run tests
    test

    # Take screenshots
    screenshots

    # Build app
    gym(
      project: "AFHAM.xcodeproj",
      scheme: "AFHAM",
      configuration: "Release",
      export_method: "app-store",
      clean: true,
      output_directory: "./build",
      output_name: "AFHAM.ipa"
    )

    # Upload to App Store Connect
    deliver(
      submit_for_review: false,
      force: true,
      metadata_path: "./fastlane/metadata",
      screenshots_path: "./screenshots"
    )

    # Create git tag
    add_git_tag(tag: "v#{version}")
    push_to_git_remote

    # Notify team
    slack(
      message: "AFHAM v#{version} uploaded to App Store Connect!",
      success: true
    )
  end

  desc "Run code linting"
  lane :lint do
    swiftlint(
      mode: :lint,
      config_file: ".swiftlint.yml",
      strict: true,
      raise_if_swiftlint_error: true
    )
  end

  desc "Generate code documentation"
  lane :docs do
    jazzy(
      config: ".jazzy.yaml"
    )
  end

  desc "Security scan"
  lane :security_scan do
    # Run security analysis
    sh("bundle exec brakeman -o security_report.html")

    # Check for vulnerabilities in dependencies
    sh("bundle exec bundle-audit check --update")
  end

  desc "Full CI pipeline"
  lane :ci do
    lint
    test
    security_scan
    build_for_testing
  end

  # Error handling
  error do |lane, exception|
    slack(
      message: "Error in #{lane}: #{exception.message}",
      success: false
    )
  end

end
