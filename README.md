
# `swift package add-dependency` command bug


## Description

Unable to add a valid `.package(path:)` dependency to `Package.Swift` via `swift package add-dependency` command.

If the user passes a valid path (`AbsolutePath`)
The `add-dependency`command forces the user to add one of these options
- `--exact`
- `--branch`
- `--revision`
- `--from`
- `--up-to-next-minor-from`

which is fine but we are trying to add a ` .package(url:from:)` or ` .package(url:_:)`

If the user passes a valid `AbsolutePath` it will add a `PackageDependency.SourceControl.Requirement` to the `.package(path:)` making it an invalid `Package.Dependency` declaration

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
