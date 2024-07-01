
# `swift package add-dependency` command bug

## Sample Project for Swift Package Manager Issue [#7738](https://github.com/swiftlang/swift-package-manager/issues/7738) 

## Description

Unable to add a valid `.package(path:)` dependency to `Package.Swift` via `swift package add-dependency` command.

If the user passes a valid path (`AbsolutePath`)
The `add-dependency`command forces the user to add one of these options

When attempting to add a `.package(path:)` dependency to a `Package.swift` using the swift package `add-dependency` command, the command requires one of the following options:
- `--exact`
- `--branch`
- `--revision`
- `--from`
- `--up-to-next-minor-from`

This is fine while trying to add a `.package(url:from:)` or `.package(url:_:)` but not for `.package(path:)` because no additional arguments are required.

If the user passes a valid `AbsolutePath` it will add a `PackageDependency.SourceControl.Requirement` to the `.package(path:)` making it an invalid `Package.Dependency` declaration

---

### Original Swift-Evolution Proposal:
While investigating this bug I read through [SE-0301 "Package Editing Commands"](https://github.com/apple/swift-evolution/blob/main/proposals/0301-package-editing-commands.md) which includes the following information on this command:

`swift package add-dependency <dependency> [--exact <version>] [--revision <revision>] [--branch <branch>] [--from <version>] [--up-to-next-minor-from <version>]`

- dependency: This may be the URL of a remote package, the path to a local package, or the name of a package in one of the user's package collections.

#### The following options can be used to specify a package dependency requirement:
- --exact : Specifies a .exact(<version>) requirement in the manifest.
- --revision : Specifies a .revision(<revision>) requirement in the manifest.
- --branch : Specifies a .branch(<branch>) requirement in the manifest.
- --up-to-next-minor-from : Specifies a .upToNextMinor(<version>) requirement in the manifest.
- --from : Specifies a .upToNextMajor(<version>) requirement in the manifest when it appears alone. Optionally, --to may be added to specify a custom range requirement, or --through may be added to specify a custom closed range requirement.

If no requirement is specified, the command will default to a `.upToNextMajor` requirement on the latest version of the package.

---

### Possible Solutions:

I spent some time working on fixing this issue and came up with two options.

### Option 1:
Make the user decide what type of dependency they are creating: URL of a remote package, the path to a local package, or the name of a package in one of the user's package collections (implemented in the future for collections).

`swift package add-dependency [--url <url>] [--path <path>] [--exact <version>] [--revision <revision>] [--branch <branch>] [--from <version>] [--up-to-next-minor-from <version>]`

This allows for the user to be explicit with what type of dependency they want to add. This would make the command give better errors explaining why the user's intention is not possible:
- Throws an error if neither `--url` nor `--path` is passed into the command
  - Dependency must have a source
- Throws an error if both `--url` and `--path` are passed into the command
  - Dependency cannot have multiple sources
- Throws an error if `--url` is passed with an invalid URL
  - Remote URLs must be valid
- Throws an error if `--path` is passed with an invalid `AbsolutePath`
  - Local Paths must be valid


### Option 2:
Keep the command interface the same but only require additional options if the `<dependency>` is not a valid `AbsolutePath`

`swift package add-dependency <dependency> [--exact <version>] [--revision <revision>] [--branch <branch>] [--from <version>] [--up-to-next-minor-from <version>]`

This would allow for the command interface to remain as it currently is and requires fewer options to be passed into the command.


### Recommendation:

There are pros and cons to both solutions, but I find the verbosity of Option 1 to be superior even if the command interface needs to change slightly. By forcing the user to decide what type of dependency they want to add to the `Package.swift`, the command is able to parse the values more safely and throw dependency-specific errors such as invalid path or invalid URL.

If we went with Option 2, the user needs to understand that a path must be a `AbsolutePath` which always starts with a `/` character. It could be extremely confusing if the user is passing in a path but it's in a different format such as `../path` and they keep getting a `.package(url:_:)` with the path.

Thanks for reading and hope this helps!


---

## Expected behavior

Expected to be able to pass in a path without having to add extra options in the CLI

The swift code generated should be
```swift
    dependencies: [
        .package(path: "/ChildPackage"),
    ],
```
---

## Actual behavior

Forces user to selectiona additional options, then adds those options to the end of `.package(path:)`    

```swift
    dependencies: [
        .package(path: "/ChildPackage", exact: "1.0.0"),
    ],
```

this breaks the `Package.swift` file

---

### Steps to reproduce

clone the Xcode Project
```bash
git clone https://github.com/hi2gage/swift-package-manager-add-dependency-sample-project.git
```

Enter First Package Directory
```bash
cd swift-package-manager-add-dependency-sample-project/swift-package-manager-add-dependency-sample-project/LocalPackages/ParentPackage/
```


Now we want to add `ChildPackage` as a local package dependency to `ParentPackage` using the `.package(path:)` 
```bash
swift package add-dependency /ChildPackage
> error: must specify one of --exact, --branch, --revision, --from, or --up-to-next-minor-from
```

So we pass in one of the options and see what happens
```bash
swift package add-dependency /ChildPackage --exact 1.0.0
> Updating package manifest at Package.swift... done.
```

Open `Package.swift`
Find that `.package(path:exact:)` is not a valid symbol

```swift
    dependencies: [
        .package(path: "/ChildPackage", exact: "1.0.0"),
    ],
```

---

### Swift & OS version (output of `swift --version ; uname -a`)
```
swift-driver version: 1.110 Apple Swift version 6.0 (swiftlang-6.0.0.4.52 clang-1600.0.21.1.3)
Target: arm64-apple-macosx14.0
Darwin MBP-M2 23.5.0 Darwin Kernel Version 23.5.0: Wed May  1 20:14:38 PDT 2024; root:xnu-10063.121.3~5/RELEASE_ARM64_T6020 arm64
```
